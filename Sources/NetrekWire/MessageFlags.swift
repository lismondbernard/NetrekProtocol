//
//  MessageFlags.swift
//  NetrekWire
//
//  The message flag and group values of the classic protocol: the `group`
//  byte of CP_MESSAGE and the `m_flags` byte of SP_MESSAGE. Values from the
//  COW client's struct.h (lines 429-488) and the vanilla netrek-server's
//  include/struct.h (lines 655-707), which agree on every value below.
//

/// Message flags and groups (MVALID, MINDIV, MTEAM, ... in classic
/// struct.h).
///
/// The low five bits say who a message is for (`whoMask`). The top three
/// bits say what it is about (`whatMask`), and their meaning depends on the
/// group bit that is set: 0x20 is `take` with `team` but `genocide` with
/// `all`. That is why these are plain values rather than an `OptionSet`.
public enum MessageFlag {

    // MARK: Who the message is for (low five bits)

    /// MVALID 0x01. The server sets it on every message it sends
    /// (vanilla ntserv/smessage.c:206).
    public static let valid: UInt8 = 0x01
    /// MINDIV 0x02. To one player; CP_MESSAGE `indiv` is the slot.
    public static let individual: UInt8 = 0x02
    /// MTEAM 0x04. To one team; CP_MESSAGE `indiv` is the team bit.
    public static let team: UInt8 = 0x04
    /// MALL 0x08. To everybody.
    public static let all: UInt8 = 0x08
    /// MGOD 0x10. To the server god.
    public static let god: UInt8 = 0x10
    /// MMOO 0x12. COW client only: its pmessage() handles it locally and
    /// never sends it (COW smessage.c:343-347).
    public static let moo: UInt8 = 0x12
    /// MTOOLS 0x14. COW client only, under its TOOLS option: sent as a
    /// tools command, not as a message (COW smessage.c:337-340).
    public static let tools: UInt8 = 0x14

    // MARK: What it is about, with `individual`

    /// MDBG 0x20, under the STDBG option.
    public static let debug: UInt8 = 0x20
    /// MCONFIG 0x40. Client configuration messages, such as the client
    /// version COW sends with MINDIV | MCONFIG (COW dmessage.c:282).
    public static let config: UInt8 = 0x40
    /// MDIST 0x60. Defined in both trees ("flag distress type messages
    /// properly"), but neither the COW client nor the vanilla server sends
    /// or tests it.
    public static let individualDistress: UInt8 = 0x60
    /// 0x80 from a client: a multi-line macro. COW calls it MMACRO
    /// (struct.h:458), the vanilla server FMMACRO (include/struct.h:706);
    /// the server's own MMACRO is 0x100 and never goes on the wire.
    public static let multilineMacro: UInt8 = 0x80

    // MARK: What it is about, with `team`

    /// MTAKE 0x20: a planet was taken.
    public static let take: UInt8 = 0x20
    /// MDEST 0x40: a planet was destroyed.
    public static let destroy: UInt8 = 0x40
    /// MBOMB 0x60: a planet is being bombed.
    public static let bomb: UInt8 = 0x60
    /// MCOUP1 0x80.
    public static let coup1: UInt8 = 0x80
    /// MCOUP2 0xA0.
    public static let coup2: UInt8 = 0xA0
    /// MDISTR 0xC0: an RCD distress call, in its binary form.
    public static let distress: UInt8 = 0xC0

    // MARK: What it is about, with `all`

    /// MGENO 0x20: genocide.
    public static let genocide: UInt8 = 0x20
    /// MCONQ 0x20: conquest. Same value as `genocide`; classic struct.h
    /// notes there are not enough bits to tell them apart.
    public static let conquer: UInt8 = 0x20
    /// MKILLA 0x40.
    public static let killA: UInt8 = 0x40
    /// MKILLP 0x60.
    public static let killP: UInt8 = 0x60
    /// MKILL 0x80.
    public static let kill: UInt8 = 0x80
    /// MLEAVE 0xA0: a player left.
    public static let leave: UInt8 = 0xA0
    /// MJOIN 0xC0: a player joined.
    public static let join: UInt8 = 0xC0
    /// MGHOST 0xE0: a player ghostbusted.
    public static let ghost: UInt8 = 0xE0

    // MARK: Masks

    /// MWHOMSK 0x1f: the "who" bits.
    public static let whoMask: UInt8 = 0x1f
    /// MWHATMSK 0xe0: the "what" bits.
    public static let whatMask: UInt8 = 0xe0

    // MARK: Combinations used for RCD calls

    /// The CP_MESSAGE group a client sends an RCD call with:
    /// MTEAM | MDISTR (COW senddist.c:99, 108; vanilla ntserv/socket.c:1501).
    public static let teamDistress: UInt8 = team | distress
    /// The SP_MESSAGE flags of an RCD call the server relays in binary:
    /// MTEAM | MDISTR | MVALID. This exact value is the only thing COW tests
    /// (COW dmessage.c:71) and the server tests (ntserv/genspkt.c:1017).
    public static let relayedTeamDistress: UInt8 = team | distress | valid
}
