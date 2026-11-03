/*
 * harness.c
 *
 * Golden data generator for the NetrekWire RCD (receiver-configurable
 * distress) tests. It is compiled together with the COW client's own
 * distress.c and senddist.c (https://github.com/quozl/netrek-client-cow),
 * which make-goldens.sh fetches at a fixed commit. No COW code lives in this
 * repository; this file only provides the globals those two files expect,
 * stubs the screen and network calls, and prints what COW produces as a
 * Swift source file.
 *
 * For each case it:
 *   1. sets up the sender's ship and what the "mouse" points at,
 *   2. calls COW's emergency() with gen_distress on, so loaddistress() and
 *      Dist2Mesg() build the call and pmessage() hands it over (captured
 *      here, copied into an 80 byte CP_MESSAGE body the way COW's
 *      sendMessage() does with STRNCPY, socket.c:2284-2311),
 *   3. relays it the way the vanilla netrek-server does
 *      (ntserv/socket.c:1485-1486, 1501-1505, 1713-1714;
 *      ntserv/smessage.c:188-206; ntserv/genspkt.c:1005-1010),
 *   4. reads it back the way COW's dmessage() does (dmessage.c:71-74):
 *      HandleGenDistr() and makedistress() with COW's dist_defaults,
 *   5. calls emergency() again with gen_distress off, to keep the plain team
 *      message COW sends to a server without RC_DISTRESS (senddist.c:110-128).
 *
 * COW's licence (copyright.h, copyright2.h in that repository) allows use,
 * copying, modification and distribution with the copyright notice kept.
 * getaddr2() and the shipnos table below follow COW's smessage.c and data.c,
 * so here are COW's notices (copyright.h and copyright2.h at f680bd3):
 */

/* Copyright (c) 1986   Chris Guthrie
 * 
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose and without fee is hereby granted, provided
 * that the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation.  No representations are made about the suitability of this
 * software for any purpose.  It is provided "as is" without express or
 * implied warranty.
 * 
 * ----------------------------------------------------------- Copyright 1989
 * Kevin P. Smith Scott Silvey
 * 
 * ditto.
 * 
 * ----------------------------------------------------------- Copyright 1993
 * 
 * As above.  Use at your own risk.
 * 
 * COW (BRM) authors (including but not limitted to: Kevin Powell Nick Trown
 * Jeff Nelson Kurt Siegl)
 * ----------------------------------------------------------- Copyright 1994
 * 
 * As above.
 * 
 * Hockey Lines added to COW by Nathan Doss Michael Kantner */

/*
   Copyright 1989               Kevin P. Smith
   Scott Silvey

   Permission to use, copy, modify, and distribute this
   software and its documentation for any purpose and without
   fee is hereby granted, provided that the above copyright
   notice appear in all copies.
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "Wlib.h"
#include "defs.h"
#include "struct.h"
#include "data.h"
#include "packets.h"

/* ------------------------------------------------------------------ */
/* Globals distress.c and senddist.c read. Tables come from COW data.c. */

#include "cowdata.inc"   /* dist_defaults, classes, teamlet, teamshort */

struct dmacro_list *distmacro = dist_defaults;
char   *shipnos = "0123456789abcdefghijklmnopqrstuvwxyz";   /* data.c:118 */
int     gen_distress = 1;
int     UseNewMacro = 1;
char    lastMessage[80];
int     ping_tloss_sc, ping_tloss_cs, ping_av, ping_sd;
char   *whydeadmess[] = { "" };
struct macro_list macro[MAX_MACRO];
int     multiline_enabled;
struct key_list macroKeys[MAX_KEY];
unsigned char keys[MAX_KEY] = "";

static struct player player_table[MAXPLAYER];
static struct planet planet_table[MAXPLANETS];
struct player *players = player_table;
struct planet *planets = planet_table;
struct player *me;

void warning(char *text) { (void) text; }

char *itoapad(int val, char *result, int pad, int prec)
{
  (void) pad; (void) prec;
  sprintf(result, "%d", val);      /* only reached for RCM, not used here */
  return result;
}

/* COW smessage.c:450-462, the MALL and MTEAM cases, which are all
 * emergency() asks for. */
char *getaddr2(int flags, int recip)
{
  static char addrmesg[ADDRLEN];

  sprintf(addrmesg, " %c%c->", teamlet[me->p_team], shipnos[me->p_no]);
  if (flags == MALL)
    sprintf(&addrmesg[5], "ALL");
  else
    sprintf(&addrmesg[5], "%s", teamshort[recip]);
  return addrmesg;
}

int getgroup(char addr, int *recip)
{
  (void) addr; (void) recip;
  return 0;
}

/* ------------------------------------------------------------------ */
/* What the "mouse" and the sender's surroundings point at. -1 means no
 * such object, and then gettarget2() answers with the sender, as COW's
 * util.c:112-120 does. */

static int near_planet, near_enemy, near_friend, near_player;
static int targ_planet, targ_enemy, targ_friend, targ_player;
static struct obtype found;

static struct obtype *answer(int num)
{
  found.o_type = PLAYERTYPE;
  found.o_num = (num < 0) ? me->p_no : num;
  return &found;
}

struct obtype *gettarget2(int x, int y, int targtype)
{
  (void) x; (void) y;
  if (targtype & TARG_PLANET) return answer(near_planet);
  if (targtype & TARG_ENEMY)  return answer(near_enemy);
  if (targtype & TARG_FRIEND) return answer(near_friend);
  return answer(near_player);
}

struct obtype *gettarget(W_Window ww, int x, int y, int targtype)
{
  (void) ww; (void) x; (void) y;
  if (targtype & TARG_PLANET) return answer(targ_planet);
  if (targtype & TARG_ENEMY)  return answer(targ_enemy);
  if (targtype & TARG_FRIEND) return answer(targ_friend);
  return answer(targ_player);
}

/* pmessage(): keep what COW would put into the CP_MESSAGE. */
static unsigned char sent_mesg[MSG_LEN];
static int sent_group, sent_recip, sent_count;

void pmessage(char *str, int recip, int group)
{
  memset(sent_mesg, 0, sizeof(sent_mesg));     /* bzero in sendMessage */
  STRNCPY((char *) sent_mesg, str, MSG_LEN);   /* socket.c:2309 */
  sent_group = group;
  sent_recip = recip;
  sent_count++;
}

/* The two COW files under test, compiled into this unit so that the
 * static loaddistress() can be reached for the cc list and text cases. */
#include "distress.c"
#include "senddist.c"

/* ------------------------------------------------------------------ */
/* The galaxy used by every case. */

static const char *planet_names[MAXPLANETS] = {
  "Earth", "Rigel", "Canopus", "Beta Crucis", "Organia", "Deneb",
  "Ceti Alpha V", "Altair", "Vega", "Alpha Centauri",
  "Romulus", "Eridani", "Aldeberan", "Regulus", "Capella", "Tauceti",
  "Draconis", "Sirius", "Indi", "Hydrae",
  "Klingus", "Pliedes V", "Andromeda", "Lalande", "Pollux", "Lyrae",
  "Scorpii", "Mira", "Cygni", "Achernar",
  "Orion", "Cassiopia", "El Nath", "Spica", "Procyon", "Polaris",
  "Arcturus", "Ursae Majoris", "Herculis", "Antares"
};

/* Ship limits for the test, near the classic ones. Only the percentages
 * they give matter, and the Swift tests read those from the output. */
struct ship_max { int damage, shield, fuel, wtemp, etemp; };

static const struct ship_max ship_max[NUM_TYPES] = {
  /* SC */ {  75,  75,  5000, 1000, 1200 },
  /* DD */ {  85,  85,  7000, 1000, 1000 },
  /* CA */ { 100, 100, 10000, 1000, 1000 },
  /* BB */ { 130, 130, 14000, 1000, 1000 },
  /* AS */ { 200,  80,  6000, 1000, 1200 },
  /* SB */ { 600, 500, 60000, 1300, 1000 },
  /* GA */ { 100, 100, 10000, 1000, 1000 },
  /* AT */ { 9999, 30000, 60000, 1000, 1000 },
};

static void setup_player(int slot, int team, const char *name, int ship)
{
  struct player *p = &players[slot];
  memset(p, 0, sizeof(*p));
  p->p_no = slot;
  p->p_status = PALIVE;
  p->p_team = team;
  p->p_mapchars[0] = teamlet[team];
  p->p_mapchars[1] = shipnos[slot];
  strncpy(p->p_name, name, sizeof(p->p_name) - 1);
  p->p_ship.s_type = ship;
}

static void setup_galaxy(void)
{
  int i;

  for (i = 0; i < MAXPLAYER; i++)
    setup_player(i, NOBODY, "", CRUISER);

  setup_player(1, FED, "Twinky", CRUISER);    /* the sender, F1 */
  setup_player(6, ROM, "Raboof", CRUISER);    /* an enemy, R6 */
  setup_player(12, FED, "Geebzy", DESTROYER); /* a team mate, Fc */
  setup_player(3, KLI, "Klunk", SCOUT);       /* another enemy, K3 */
  setup_player(7, ROM, "Romy", BATTLESHIP);   /* R7 */
  setup_player(9, FED, "Fedora", ASSAULT);    /* F9 */
  setup_player(14, KLI, "Kaboom", DESTROYER); /* Ke */

  for (i = 0; i < MAXPLANETS; i++)
    {
      memset(&planets[i], 0, sizeof(planets[i]));
      planets[i].pl_no = i;
      strncpy(planets[i].pl_name, planet_names[i], sizeof(planets[i].pl_name) - 1);
      planets[i].pl_owner = (i < 10) ? FED : (i < 20) ? ROM : (i < 30) ? KLI : ORI;
      planets[i].pl_armies = 0;
      planets[i].pl_info = 0;
    }
  planets[31].pl_armies = 5;   planets[31].pl_info = FED;        /* Cassiopia */
  planets[3].pl_armies = 12;   planets[3].pl_info = FED;         /* Beta Crucis */
  planets[13].pl_armies = 4;   planets[13].pl_info = FED | ROM;  /* Regulus */
  planets[1].pl_armies = 9;    planets[1].pl_info = ROM;         /* Rigel, FED has no info */
}

/* The sender's ship state, in game units. */
struct state
  {
    int ship, damage, shield, fuel, wtemp, etemp, armies;
    unsigned int flags;
  };

static void apply_state(const struct state *s)
{
  me = &players[1];
  me->p_ship.s_type = s->ship;
  me->p_ship.s_maxdamage = ship_max[s->ship].damage;
  me->p_ship.s_maxshield = ship_max[s->ship].shield;
  me->p_ship.s_maxfuel = ship_max[s->ship].fuel;
  me->p_ship.s_maxwpntemp = ship_max[s->ship].wtemp;
  me->p_ship.s_maxegntemp = ship_max[s->ship].etemp;
  me->p_damage = s->damage;
  me->p_shield = s->shield;
  me->p_fuel = s->fuel;
  me->p_wtemp = s->wtemp;
  me->p_etemp = s->etemp;
  me->p_armies = s->armies;
  me->p_flags = s->flags;
}

static void set_targets(int np, int ne, int nf, int nj, int tp, int te, int tf, int tj)
{
  near_planet = np; near_enemy = ne; near_friend = nf; near_player = nj;
  targ_planet = tp; targ_enemy = te; targ_friend = tf; targ_player = tj;
}

/* ------------------------------------------------------------------ */
/* Output. */

static int last_nonzero(const unsigned char *buf, int len)
{
  while (len > 0 && buf[len - 1] == 0)
    len--;
  return len;
}

static void print_bytes(const char *label, const unsigned char *buf, int len)
{
  int i, n = last_nonzero(buf, len);

  printf("        %s: [", label);
  for (i = 0; i < n; i++)
    printf("%s0x%02x", i ? ", " : "", buf[i]);
  printf("],\n");
}

/* Prints `label: "s"`, then a comma unless it is the last argument (Swift
 * 6.0 does not accept a trailing comma in an argument list). */
static void print_swift_string(const char *label, const char *s, int last)
{
  printf("        %s: \"", label);
  for (; *s; s++)
    {
      unsigned char c = (unsigned char) *s;
      if (c == '"' || c == '\\')
        printf("\\%c", c);
      else if (c < 0x20 || c >= 0x7f)
        printf("\\u{%x}", c);
      else
        putchar(c);
    }
  printf(last ? "\"\n" : "\",\n");
}

/* What COW sends instead when the server does not offer RC_DISTRESS: the
 * call expanded with the sender's own macros, as an ordinary team message
 * without its own address (senddist.c:110-128). */
static char plain_text[MSG_LEN + 1];
static int plain_group;

static void capture_plain(enum dist_type type)
{
  W_Event event;

  memset(&event, 0, sizeof(event));
  gen_distress = 0;
  sent_count = 0;
  emergency(type, &event);
  gen_distress = 1;
  memset(plain_text, 0, sizeof(plain_text));
  plain_group = 0;
  if (sent_count == 1)
    {
      memcpy(plain_text, sent_mesg, MSG_LEN);
      plain_group = sent_group;
    }
}

/* Relay the captured CP_MESSAGE the way the vanilla server does, then read
 * it back the way COW does. */
static void relay_and_read(const char *name, const struct state *s,
                           struct distress *sent)
{
  struct mesg_cpacket packet;
  char    addrbuf[9];
  char    m_data[MSG_LEN];
  unsigned char relayed[MSG_LEN];
  unsigned char flags;
  struct distress got;
  char    cry[MSG_LEN * 2];
  int     len, i;

  memset(&packet, 0, sizeof(packet));
  packet.group = sent_group;
  packet.indiv = sent_recip;
  memcpy(packet.mesg, sent_mesg, MSG_LEN);

  /* ntserv/socket.c:1485-1486, 1505 */
  packet.mesg[MSG_LEN - 11] = '\0';
  sprintf(addrbuf, " %c%c->", teamlet[me->p_team], shipnos[me->p_no]);
  sprintf(addrbuf + 5, "%s", teamshort[(unsigned char) packet.indiv]);

  /* ntserv/smessage.c:186-196 */
  memset(m_data, 0, sizeof(m_data));
  snprintf(m_data, sizeof(m_data), "%-9s ", addrbuf);
  snprintf(m_data + 10, sizeof(m_data) - 10, "%s", packet.mesg);
  /* ntserv/socket.c:1713 and smessage.c:206 */
  flags = (unsigned char) (packet.group | MVALID);

  /* ntserv/genspkt.c:1006-1007 */
  memset(relayed, 0, sizeof(relayed));
  strncpy((char *) relayed, m_data, MSG_LEN);
  relayed[MSG_LEN - 1] = '\0';

  /* COW dmessage.c:71-74 */
  if (flags != (MTEAM | MDISTR | MVALID))
    {
      fprintf(stderr, "%s: unexpected flags 0x%02x\n", name, flags);
      exit(1);
    }
  memset(&got, 0, sizeof(got));
  HandleGenDistr((char *) relayed, (unsigned char) me->p_no,
                 (unsigned char) packet.indiv, &got);
  memset(cry, 0, sizeof(cry));
  len = makedistress(&got, cry, distmacro[got.distype].macro);
  if (len <= 0)
    cry[0] = '\0';

  /* The numeric fields must come back as they went out. */
  if (got.distype != sent->distype || got.macroflag != sent->macroflag ||
      got.fuelp != sent->fuelp || got.dam != sent->dam ||
      got.shld != sent->shld || got.etmp != sent->etmp ||
      got.wtmp != sent->wtmp || got.arms != sent->arms ||
      got.sts != (sent->sts & 0x7f) ||
      got.close_pl != sent->close_pl || got.close_en != sent->close_en ||
      got.tclose_pl != sent->tclose_pl || got.tclose_en != sent->tclose_en ||
      got.tclose_j != sent->tclose_j || got.close_j != sent->close_j ||
      got.tclose_fr != sent->tclose_fr || got.close_fr != sent->close_fr)
    {
      fprintf(stderr, "%s: fields did not survive the round trip\n", name);
      exit(1);
    }

  printf("    CowGolden(\n");
  print_swift_string("name", name, 0);
  printf("        ship: %d, damage: %d, shield: %d, fuel: %d, weaponTemp: %d, engineTemp: %d, armies: %d, flags: 0x%x,\n",
         s->ship, s->damage, s->shield, s->fuel, s->wtemp, s->etemp, s->armies, s->flags);
  printf("        maxDamage: %d, maxShield: %d, maxFuel: %d, maxWeaponTemp: %d, maxEngineTemp: %d,\n",
         ship_max[s->ship].damage, ship_max[s->ship].shield, ship_max[s->ship].fuel,
         ship_max[s->ship].wtemp, ship_max[s->ship].etemp);
  printf("        type: %d, macroFlag: %s, fuelPercent: %d, damagePercent: %d, shieldPercent: %d, engineTempPercent: %d, weaponTempPercent: %d, armyCount: %d, status: 0x%02x,\n",
         sent->distype, sent->macroflag ? "true" : "false", sent->fuelp, sent->dam,
         sent->shld, sent->etmp, sent->wtmp, sent->arms, sent->sts & 0x7f);
  printf("        nearestPlanet: %d, nearestEnemy: %d, targetPlanet: %d, targetEnemy: %d, targetPlayer: %d, nearestPlayer: %d, targetFriend: %d, nearestFriend: %d,\n",
         sent->close_pl, sent->close_en, sent->tclose_pl, sent->tclose_en,
         sent->tclose_j, sent->close_j, sent->tclose_fr, sent->close_fr);
  printf("        ccList: [");
  for (i = 0; (sent->cclist[i] & 0xc0) == 0xc0; i++)
    printf("%s%d", i ? ", " : "", sent->cclist[i] & 0x1f);
  printf("], terminator: 0x%02x,\n", sent->cclist[i]);
  print_swift_string("text", sent->preappend, 0);
  print_swift_string("decodedText", got.preappend, 0);
  printf("        sender: %d, group: 0x%02x, recipient: %d, relayedFlags: 0x%02x,\n",
         me->p_no, sent_group, sent_recip, flags);
  print_bytes("message", sent_mesg, MSG_LEN);
  print_bytes("relayed", relayed, MSG_LEN);
  print_swift_string("expanded", cry, 0);
  printf("        plainGroup: 0x%02x,\n", plain_group);
  print_swift_string("plainText", plain_text, 1);
  printf("    ),\n");
}

/* A call made the way COW's keys make one: emergency() -> loaddistress()
 * -> Dist2Mesg() -> pmessage(). */
static void call(const char *name, enum dist_type type, const struct state *s)
{
  W_Event event;
  struct distress *dist;

  memset(&event, 0, sizeof(event));
  apply_state(s);
  sent_count = 0;
  emergency(type, &event);
  if (sent_count != 1 || sent_group != (MTEAM | MDISTR))
    {
      fprintf(stderr, "%s: emergency() did not send one MDISTR message\n", name);
      exit(1);
    }
  /* Rebuild the same struct to print what was sent. */
  dist = loaddistress(type, &event);
  {
    unsigned char rcd[MSG_LEN];
    int group = sent_group, recip = sent_recip;

    memcpy(rcd, sent_mesg, MSG_LEN);
    capture_plain(type);
    memcpy(sent_mesg, rcd, MSG_LEN);
    sent_group = group;
    sent_recip = recip;
  }
  relay_and_read(name, s, dist);
  free(dist);
}

/* A call with a cc list, appended text or the macro flag, which COW's keys
 * never send but the format carries: loaddistress(), then the extra fields,
 * then Dist2Mesg() as emergency() does it (senddist.c:107-108). */
static void call_extra(const char *name, enum dist_type type, const struct state *s,
                       const int *cc, int ncc, unsigned char terminator,
                       const char *text, int macroflag)
{
  W_Event event;
  struct distress *dist;
  char    ebuf[200];
  int     i;

  memset(&event, 0, sizeof(event));
  apply_state(s);
  capture_plain(type);
  dist = loaddistress(type, &event);
  for (i = 0; i < ncc; i++)
    dist->cclist[i] = 0xc0 | cc[i];
  dist->cclist[ncc] = terminator;
  strncpy(dist->preappend, text, sizeof(dist->preappend) - 1);
  dist->macroflag = macroflag;
  memset(ebuf, 0, sizeof(ebuf));
  Dist2Mesg(dist, ebuf);
  sent_count = 0;
  pmessage(ebuf, me->p_team, MTEAM | MDISTR);
  relay_and_read(name, s, dist);
  free(dist);
}

int main(void)
{
  /* CA, 40% damage, 60% shields, 63% fuel, 3 armies, shields up. */
  struct state ca = { CRUISER, 40, 60, 6300, 250, 120, 3, PFSHIELD };
  struct state s;
  int i;
  static const char *type_names[] = {
    "", "take", "ogg", "bomb", "spaceControl", "savePlanet", "baseOgg",
    "help1", "help2", "escorting", "ogging", "bombing", "controlling",
    "asw", "asbomb", "doing1", "doing2", "freeBeer", "noGas", "crippled",
    "pickup", "pop", "carrying", "other1", "other2", "generic"
  };

  setup_galaxy();

  printf("// Generated by Tests/RCDHarness/make-goldens.sh from the COW client's\n");
  printf("// distress.c, senddist.c and data.c. Do not edit by hand.\n\n");
  printf("let cowGoldens: [CowGolden] = [\n");

  /* Near Beta Crucis (3), Raboof (6) the nearest enemy, Geebzy (12) the
   * nearest friend and player; mouse on Cassiopia (31), Raboof, Geebzy. */
  set_targets(3, 6, 12, 12, 31, 6, 12, 12);

  /* The calls Parallax sends first. */
  call("carrying", carrying, &ca);
  s = ca; s.armies = 0;  call("carryingNone", carrying, &s);
  s = ca; s.armies = 1;  call("carryingOne", carrying, &s);
  s = ca; s.ship = STARBASE; s.damage = 120; s.shield = 400; s.fuel = 45000;
  s.wtemp = 650; s.armies = 25;
  call("carryingStarbase", carrying, &s);

  call("help", generic, &ca);
  call("help1", help1, &ca);

  set_targets(3, 6, 12, 12, 3, 6, 12, 12);
  call("escorting", escorting, &ca);
  call("ogging", ogging, &ca);
  call("baseOgg", base_ogg, &ca);

  set_targets(3, 6, 12, 6, 31, 6, 12, 6);
  call("take", take, &ca);
  set_targets(3, 6, 12, 6, 1, 6, 12, 6);
  call("takeNoArmyInfo", take, &ca);

  set_targets(3, 6, 12, 6, 31, 6, 12, 6);
  call("bombing", bombing, &ca);
  set_targets(3, 6, 12, 6, 13, 6, 12, 6);
  call("controlling", controlling, &ca);

  /* Edge cases. */
  set_targets(3, 6, 12, 12, 31, 6, 12, 12);
  s = ca; s.armies = 0; s.damage = 0; s.shield = 100; s.fuel = 10000;
  s.wtemp = 0; s.etemp = 0; s.flags = 0;
  call("helpFreshShip", generic, &s);
  s = ca; s.armies = 31; call("helpMaxArmies", generic, &s);
  s = ca; s.flags = PFCLOAK; call("helpCloaked", generic, &s);
  s = ca; s.wtemp = 1500; s.etemp = 1050; s.flags = PFSHIELD | PFWEP | PFENG;
  call("helpOverheated", generic, &s);
  s = ca; s.ship = STARBASE; s.damage = 300; s.shield = 100; s.fuel = 30000;
  s.wtemp = 975; s.armies = 0;
  call("helpStarbase", generic, &s);
  s = ca; s.damage = 100; s.shield = 0; s.fuel = 0; s.flags = 0xff;
  call("helpAllStatusBits", generic, &s);

  set_targets(3, -1, 12, 12, 31, -1, 12, 12);
  call("helpNoEnemyNear", generic, &ca);
  set_targets(3, -1, -1, -1, 31, -1, -1, -1);
  call("oggingNobodyAround", ogging, &ca);

  set_targets(3, 6, 12, 12, 31, 6, 12, 12);
  call_extra("helpWithText", generic, &ca, NULL, 0, 0x80, "on my way to Cas", 0);
  call_extra("helpWithLongText", generic, &ca, NULL, 0, 0x80,
             "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ+-*/", 0);
  {
    int cc[2] = { 6, 12 };
    call_extra("helpWithCcList", generic, &ca, cc, 2, 0x80, "", 0);
    call_extra("helpWithCcListAndAppend", generic, &ca, cc, 2, 0x40, "cc", 0);
  }
  call_extra("helpMacroFlag", generic, &ca, NULL, 0, 0x80, "", 1);

  /* The other branches of the default texts' conditions. */
  set_targets(3, 6, 12, 6, 31, 6, 12, 6);
  s = ca; s.armies = 0; call("doing1NoArmies", doing1, &s);
  s = ca; s.armies = 1; call("doing1OneArmy", doing1, &s);
  s = ca; s.armies = 0; call("other1NoArmies", other1, &s);
  s = ca; s.ship = STARBASE; s.damage = 0; s.shield = 500; s.fuel = 60000;
  s.wtemp = 0; s.armies = 1;
  call("carryingStarbaseOne", carrying, &s);
  call("bombFewArmies", bomb, &ca);            /* Cassiopia has 5 */
  set_targets(3, 6, 12, 6, 13, 6, 12, 6);
  call("bombFourArmies", bomb, &ca);           /* Regulus has 4 */
  set_targets(3, 6, 12, 6, 1, 6, 12, 6);
  call("bombNoArmyInfo", bomb, &ca);           /* FED knows nothing of Rigel */
  call("popNoArmyInfo", pop, &ca);
  set_targets(3, 6, 12, 6, 3, 6, 12, 6);
  call("popKnown", pop, &ca);                  /* Beta Crucis has 12 */

  /* Every type COW sends, with the same state, for the default texts. All
   * eight location fields differ, so each byte and each code is pinned:
   * nearest planet Beta Crucis (3), enemy K3, friend F9, player Ke (14);
   * target planet Cassiopia (31), enemy R6, friend Fc (12), player R7. */
  for (i = take; i <= generic; i++)
    {
      char name[40];
      sprintf(name, "type_%s", type_names[i]);
      set_targets(3, 3, 9, 14, 31, 6, 12, 7);
      call(name, (enum dist_type) i, &ca);
    }

  printf("]\n");
  return 0;
}
