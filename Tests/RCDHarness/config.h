/*
 * config.h
 *
 * A minimal stand-in for COW's generated config.h, just enough to compile
 * COW's distress.c and senddist.c on Linux for the RCD golden harness.
 * The switches that touch those two files are set as in COW's
 * config.h.in (NBT, RCD, RCM, SPEEDUP, TOOLS, MULTILINE_MACROS).
 */
#ifndef rcd_harness_config_h
#define rcd_harness_config_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>

#define INC_STDLIB      <stdlib.h>
#define INC_SYS_TIME    <sys/time.h>
#define INC_STRINGS     <strings.h>
#define LONG            long
#define NBT
#define RCD
#define RCM
#define SPEEDUP
#define TOOLS
#define MULTILINE_MACROS
#define MAXPLAYER       36
#define MCMP(x,y,z)     memcmp(x,y,z)
#define MCOPY(b1,b2,l)  memcpy(b2,b1,l)
#define MZERO(b1,l)     memset(b1,0,l)
#define INDEX(s,c)      strchr(s,c)
#define RINDEX(s,c)     strrchr(s,c)
#define STRNCPY(x,y,z)  memccpy(x,y,'\0',z)

#endif
