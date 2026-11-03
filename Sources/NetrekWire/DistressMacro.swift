//
//  DistressMacro.swift
//  NetrekWire
//
//  The default RCD texts and the macro language that turns a decoded call
//  into the line a classic client shows. Both are the COW client's, by the
//  COW (BRM) authors: the templates are `dist_defaults` (COW data.c:436-490,
//  the same texts as the vanilla server's `distmacro`, ntserv/data.c:305-333)
//  and the expansion is a port of makedistress() and its helpers (COW
//  distress.c:211-932).
//
//  COW notices. The default RCD texts in this file are copied from the COW
//  client's data.c (dist_defaults), and the macro expansion is ported from
//  its distress.c (makedistress and its helpers), with its name tables
//  from data.c. COW carries these notices (copyright.h and copyright2.h at
//  COW commit f680bd3):
//
//  /* Copyright (c) 1986   Chris Guthrie
//   *
//   * Permission to use, copy, modify, and distribute this software and its
//   * documentation for any purpose and without fee is hereby granted, provided
//   * that the above copyright notice appear in all copies and that both that
//   * copyright notice and this permission notice appear in supporting
//   * documentation.  No representations are made about the suitability of this
//   * software for any purpose.  It is provided "as is" without express or
//   * implied warranty.
//   *
//   * ----------------------------------------------------------- Copyright 1989
//   * Kevin P. Smith Scott Silvey
//   *
//   * ditto.
//   *
//   * ----------------------------------------------------------- Copyright 1993
//   *
//   * As above.  Use at your own risk.
//   *
//   * COW (BRM) authors (including but not limitted to: Kevin Powell Nick Trown
//   * Jeff Nelson Kurt Siegl)
//   * ----------------------------------------------------------- Copyright 1994
//   *
//   * As above.
//   *
//   * Hockey Lines added to COW by Nathan Doss Michael Kantner */
//
//  /*
//     Copyright 1989               Kevin P. Smith
//     Scott Silvey
//
//     Permission to use, copy, modify, and distribute this
//     software and its documentation for any purpose and without
//     fee is hereby granted, provided that the above copyright
//     notice appear in all copies.
//   */
//

/// Who sent a call, as the receiving client knows them.
public struct DistressSender: Hashable, Sendable {
    /// Team bit: 1 FED, 2 ROM, 4 KLI, 8 ORI. Used by %T, %o, %O and %n.
    public var team: UInt8
    /// Player name, for %i and %I.
    public var name: String
    /// Ship type number, 0 SC to 7 AT, for %S. `nil` shows nothing.
    public var shipType: Int?

    public init(team: UInt8, name: String, shipType: Int?) {
        self.team = team
        self.name = name
        self.shipType = shipType
    }
}

/// What the receiving client knows about planets and players, for the
/// template codes that name them. Every lookup may answer `nil`.
public struct DistressLookup {
    /// Planet name by number, for %l, %L, %b, %B and %N.
    public var planetName: (Int) -> String?
    /// Planet owner's team bit by number, for %z, %Z and %t.
    public var planetOwner: (Int) -> UInt8?
    /// Armies on a planet, if the given team (the sender's) has scouted it;
    /// `nil` otherwise. For %n, which shows -1 then, as COW does with
    /// `pl_info` (COW distress.c:345-347).
    public var planetArmies: (_ planet: Int, _ team: UInt8) -> Int?
    /// Player's team bit by slot, for %r.
    public var playerTeam: (Int) -> UInt8?

    public init(planetName: @escaping (Int) -> String? = { _ in nil },
                planetOwner: @escaping (Int) -> UInt8? = { _ in nil },
                planetArmies: @escaping (_ planet: Int, _ team: UInt8) -> Int? = { _, _ in nil },
                playerTeam: @escaping (Int) -> UInt8? = { _ in nil }) {
        self.planetName = planetName
        self.planetOwner = planetOwner
        self.planetArmies = planetArmies
        self.playerTeam = playerTeam
    }
}

extension DistressType {
    /// COW's default text for the type (`dist_defaults`, COW data.c:436-490).
    /// `nil` for `rcm`, which has its own list of server message texts.
    public var defaultMacro: String? {
        switch self {
        case .take: return " %T%c->%O (%S) Carrying %a to %l%?%n>-1%{ @ %n%}"
        case .ogg: return " %T%c->%O Help Ogg %p at %l"
        case .bomb: return " %T%c->%O %?%n>4%{bomb %l @ %n%!bomb %l%}"
        case .spaceControl: return " %T%c->%O Help Control at %L"
        case .savePlanet: return " %T%c->%O Emergency at %L!!!!"
        case .baseOgg: return " %T%c->%O Sync with --]> %g <[-- OGG ogg OGG base!!"
        case .help1: return " %T%c->%O Help me! %d%% dam, %s%% shd, %f%% fuel %a armies."
        case .help2: return " %T%c->%O Help me! %d%% dam, %s%% shd, %f%% fuel %a armies."
        case .escorting: return " %T%c->%O ESCORTING %g (%d%%D %s%%S %f%%F)"
        case .ogging: return " %T%c->%O Ogging %h"
        case .bombing: return " %T%c->%O Bombing %l @ %n"
        case .controlling: return " %T%c->%O Controlling at %l"
        case .asw: return " %T%c->%O Anti-bombing %p near %b."
        case .asbomb: return " %T%c->%O DON'T BOMB %l. Let me bomb it (%S)"
        case .doing1: return " %T%c->%O (%i)%?%a>0%{ has %a arm%?%a=1%{y%!ies%}%} at %l.  (%d%% dam, %s%% shd, %f%% fuel)"
        case .doing2: return " %T%c->%O (%i)%?%a>0%{ has %a arm%?%a=1%{y%!ies%}%} at %l.  (%d%% dam, %s%% shd, %f%% fuel)"
        case .freeBeer: return " %T%c->%O %p is free beer"
        case .noGas: return " %T%c->%O %p @ %l has no gas"
        case .crippled: return " %T%c->%O %p @ %l crippled"
        case .pickup: return " %T%c->%O %p++ @ %l"
        case .pop: return " %T%c->%O %l%?%n>-1%{ @ %n%}!"
        case .carrying: return " %T%c->%O %?%S=SB%{Your Starbase is c%!C%}arrying %?%a>0%{%a%!NO%} arm%?%a=1%{y%!ies%}."
        case .other1: return " %T%c->%O (%i)%?%a>0%{ has %a arm%?%a=1%{y%!ies%}%} at %l. (%d%%D, %s%%S, %f%%F)"
        case .other2: return " %T%c->%O (%i)%?%a>0%{ has %a arm%?%a=1%{y%!ies%}%} at %l. (%d%%D, %s%%S, %f%%F)"
        case .generic: return " %T%c->%O Help(%S)! %s%% shd, %d%% dmg, %f%% fuel,%?%S=SB%{ %w%% wtmp,%!%}%E%{ ETEMP!%}%W%{ WTEMP!%} %a armies!"
        case .rcm: return nil
        }
    }
}

extension Distress {
    /// The line a classic client shows for this call with COW's default
    /// texts, such as " F1->FED Carrying 3 armies.". It starts with the
    /// sender's address, like any relayed message. `nil` when the text comes
    /// out empty (COW then shows nothing, dmessage.c:81-82).
    public func defaultText(sender: DistressSender, lookup: DistressLookup) -> String? {
        guard let macro = type.defaultMacro else { return nil }
        return DistressMacro.expand(macro, distress: self, sender: sender, lookup: lookup)
    }

    /// What COW sends instead of the binary call when the server does not
    /// offer the RC_DISTRESS feature: the default text as an ordinary team
    /// message (CP_MESSAGE group MTEAM, to the sender's team), without the
    /// sender's own " F1->FED " address, which the server puts back
    /// (COW senddist.c:110-128, smessage.c:450-462). `nil` when the text
    /// comes out empty.
    public func plainText(sender: DistressSender, lookup: DistressLookup) -> String? {
        guard let text = defaultText(sender: sender, lookup: lookup) else { return nil }
        var address: [UInt8] = [UInt8(ascii: " ")]
        address.append(Int(sender.team) < DistressMacro.teamlet.count
                       ? DistressMacro.teamlet[Int(sender.team)] : UInt8(ascii: "X"))
        address.append(self.sender >= 0 && self.sender < DistressMacro.shipnos.count
                       ? DistressMacro.shipnos[self.sender] : UInt8(ascii: "?"))
        address += Array("->".utf8)
        address += Array((Int(sender.team) < DistressMacro.teamshort.count
                          ? DistressMacro.teamshort[Int(sender.team)] : "X").utf8)
        let bytes = Array(text.utf8)
        guard bytes.starts(with: address.prefix(8)) else { return text }
        return String(decoding: bytes.dropFirst(9), as: UTF8.self)
    }
}

/// COW's RCD macro language.
///
/// Codes supported, as in COW distress.c:258-548:
/// `%a %d %s %f %w %e` (armies and percentages), `%p %g %h` (target player,
/// friend, enemy), `%P %G %H` (nearest player, friend, enemy), `%c` (sender),
/// `%l %L %b %B %N` (target planet, nearest planet, full target planet
/// name), `%n` (armies on the target planet), `%z %Z %t` (target planet's
/// team), `%T %o %O` (sender's team), `%r` (target player's team), `%i %I`
/// (sender's name), `%S` (ship type), `%E %W` (overheat flags), `%%` and
/// `% `, and the tests and conditions `%?`, `%{`, `%!`, `%}` and `%*`.
///
/// Left out, and skipped like an unknown code:
/// - `%u %U %K %k`: COW and the vanilla server read different players for
///   them (COW distress.c:422-458 uses `tclose_j`, the server's
///   ntserv/distress.c:400-430 uses `tclose_en`), and `%k %K` need kill
///   counts. No default text uses them.
/// - `%m %M %v %V %y`: the receiver's own last message and ping figures,
///   not part of the call; the server shows nothing or 0 for them.
/// - `%>`: COW's tab stop; the vanilla server does not have it.
public enum DistressMacro {

    /// COW's longest expanded macro, MAXMACLEN (COW defs.h:386).
    static let maxMacroLength = 85
    static let bufferLength = 10 * maxMacroLength

    /// COW data.c:118.
    static let shipnos = Array("0123456789abcdefghijklmnopqrstuvwxyz".utf8)
    /// COW data.c:346-348.
    static let teamlet = Array("IFRXKXXXOXXXXXXA".utf8)
    /// COW data.c:349-351.
    static let teamshort = ["IND", "FED", "ROM", "X", "KLI", "X", "X", "X",
                            "ORI", "X", "X", "X", "X", "X", "X", "ALL"]
    /// COW data.c:344-345.
    static let classes = ["SC", "DD", "CA", "BB", "AS", "SB", "GA", "AT"]

    /// Expands `macro` for `distress`. `nil` when the result is empty.
    public static func expand(_ macro: String, distress: Distress,
                              sender: DistressSender, lookup: DistressLookup) -> String? {
        let pattern = Array(macro.utf8)
        guard !pattern.isEmpty else { return nil }

        // Pass 1: substitute the codes (COW distress.c:257-557).
        let buf1 = substitute(pattern, distress: distress, sender: sender, lookup: lookup)

        // Pass 2: evaluate the tests (COW distress.c:559-567).
        var index = 0
        var buf2: [UInt8] = []
        testmacro(buf1, &buf2, &index)
        guard !buf2.isEmpty else { return nil }

        // Pass 3: keep the text the conditions allow (COW distress.c:569-585).
        index = 0
        var buf3: [UInt8] = []
        condmacro(buf2, &buf3, &index, true)
        guard !buf3.isEmpty else { return nil }

        return String(decoding: buf3.prefix(MSG_LEN - 1), as: UTF8.self)
    }

    // MARK: - Pass 1

    private static func substitute(_ pattern: [UInt8], distress: Distress,
                                   sender: DistressSender, lookup: DistressLookup) -> [UInt8] {
        var out: [UInt8] = []
        var pm = 0

        func append(_ text: String, capitalised: Bool = false) {
            for byte in text.utf8 {
                out.append(capitalised ? upper(byte) : byte)
            }
        }
        func appendInt(_ value: Int) { append(String(value)) }
        func mapChar(_ slot: Int) -> UInt8 {
            return slot >= 0 && slot < shipnos.count ? shipnos[slot] : UInt8(ascii: "?")
        }
        func teamLetter(_ team: UInt8?) -> UInt8 {
            guard let team = team, Int(team) < teamlet.count else { return UInt8(ascii: "X") }
            return teamlet[Int(team)]
        }
        func teamName(_ team: UInt8?) -> String {
            guard let team = team, Int(team) < teamshort.count else { return "X" }
            return teamshort[Int(team)]
        }
        // COW lower-cases the first letter by arithmetic, keeps three bytes
        // and stops at the first NUL (distress.c:352-357), so an empty name
        // comes out as one space.
        func shortPlanet(_ planet: Int) -> String {
            var name = Array((lookup.planetName(planet) ?? "").utf8.prefix(3))
            while name.count < 3 { name.append(0) }
            name[0] = name[0] &- UInt8(ascii: "A") &+ UInt8(ascii: "a")
            let end = name.firstIndex(of: 0) ?? name.count
            return String(decoding: name[..<end], as: UTF8.self)
        }

        while pm < pattern.count {
            guard pattern[pm] == UInt8(ascii: "%") else {
                out.append(pattern[pm])
                pm += 1
                continue
            }
            pm += 1
            guard pm < pattern.count else { break }
            let code = pattern[pm]
            pm += 1

            switch Character(Unicode.Scalar(code)) {
            case " ": out.append(UInt8(ascii: " "))
            case "O", "o":
                if sender.team != 0x0f {
                    append(teamName(sender.team), capitalised: code == UInt8(ascii: "O"))
                }
            case "a": appendInt(distress.armies)
            case "d": appendInt(distress.damage)
            case "s": appendInt(distress.shields)
            case "f": appendInt(distress.fuel)
            case "w": appendInt(distress.weaponTemp)
            case "e": appendInt(distress.engineTemp)
            case "p": out.append(mapChar(distress.targetPlayer))
            case "g": out.append(mapChar(distress.targetFriend))
            case "h": out.append(mapChar(distress.targetEnemy))
            case "P": out.append(mapChar(distress.nearestPlayer))
            case "G": out.append(mapChar(distress.nearestFriend))
            case "H": out.append(mapChar(distress.nearestEnemy))
            case "n": appendInt(lookup.planetArmies(distress.targetPlanet, sender.team) ?? -1)
            case "B", "b": append(shortPlanet(distress.nearestPlanet), capitalised: code == UInt8(ascii: "B"))
            case "L", "l": append(shortPlanet(distress.targetPlanet), capitalised: code == UInt8(ascii: "L"))
            case "N": append(lookup.planetName(distress.targetPlanet) ?? "")
            case "Z", "z": append(teamName(lookup.planetOwner(distress.targetPlanet)),
                                  capitalised: code == UInt8(ascii: "Z"))
            case "t": out.append(teamLetter(lookup.planetOwner(distress.targetPlanet)))
            case "T": out.append(teamLetter(sender.team))
            case "r": out.append(teamLetter(lookup.playerTeam(distress.targetPlayer)))
            case "c": out.append(mapChar(distress.sender))
            case "W": out.append(UInt8(ascii: distress.weaponsOverheated ? "1" : "0"))
            case "E": out.append(UInt8(ascii: distress.enginesOverheated ? "1" : "0"))
            case "I", "i": append(sender.name, capitalised: code == UInt8(ascii: "I"))
            case "S":
                if let ship = sender.shipType, ship >= 0, ship < classes.count {
                    append(classes[ship])
                }
            case "*", "}", "{", "!", "?", "%":
                out.append(UInt8(ascii: "%"))
                out.append(code)
            default:
                // Unknown or left-out code: skipped, as COW does
                // (distress.c:541-547).
                break
            }
        }
        return out
    }

    private static func upper(_ byte: UInt8) -> UInt8 {
        return (byte >= UInt8(ascii: "a") && byte <= UInt8(ascii: "z")) ? byte - 32 : byte
    }

    // MARK: - Pass 2, COW distress.c:588-752

    private static func at(_ buf: [UInt8], _ index: Int) -> UInt8 {
        return index >= 0 && index < buf.count ? buf[index] : 0
    }

    private static func testmacro(_ a: [UInt8], _ b: inout [UInt8], _ ia: inout Int) {
        var state = false
        while at(a, ia) != 0 && b.count < bufferLength {
            if state {
                let c = at(a, ia)
                ia += 1
                switch c {
                case UInt8(ascii: "*"), UInt8(ascii: "%"), UInt8(ascii: "{"),
                     UInt8(ascii: "}"), UInt8(ascii: "!"), UInt8(ascii: ">"):
                    guard b.count < bufferLength - 2 else { return }
                    b.append(UInt8(ascii: "%"))
                    b.append(c)
                    if c == UInt8(ascii: ">") {
                        b.append(at(a, ia))
                        ia += 1
                    }
                case UInt8(ascii: "?"):
                    b.append(UInt8(ascii: "0") + (solvetest(a, &ia) ? 1 : 0))
                default:
                    break
                }
                state = false
                continue
            }
            if at(a, ia) == UInt8(ascii: "%") {
                state = true
                ia += 1
                continue
            }
            b.append(at(a, ia))
            ia += 1
        }
    }

    private static func solvetest(_ a: [UInt8], _ ia: inout Int) -> Bool {
        var head: [UInt8] = []
        var tail: [UInt8] = []
        var state = false

        while at(a, ia) != 0, at(a, ia) != UInt8(ascii: "<"),
              at(a, ia) != UInt8(ascii: ">"), at(a, ia) != UInt8(ascii: "=") {
            head.append(at(a, ia))
            ia += 1
        }
        let operation = at(a, ia)
        ia += 1

        while at(a, ia) != 0,
              !(state && (at(a, ia) == UInt8(ascii: "?") || at(a, ia) == UInt8(ascii: "{"))) {
            let c = at(a, ia)
            if state && (c == UInt8(ascii: "%") || c == UInt8(ascii: "!") || c == UInt8(ascii: "}")) {
                tail.append(UInt8(ascii: "%"))
            } else if c == UInt8(ascii: "%") {
                state = true
                ia += 1
                continue
            }
            state = false
            tail.append(c)
            ia += 1
        }
        if at(a, ia) != 0 {
            ia -= 1
        }

        switch operation {
        case 0: return true
        case UInt8(ascii: "="): return head == tail
        case UInt8(ascii: "<"): return atoi(head) < atoi(tail)
        case UInt8(ascii: ">"): return atoi(head) > atoi(tail)
        default: return true
        }
    }

    /// C's atoi(): optional white space and sign, then digits.
    private static func atoi(_ bytes: [UInt8]) -> Int {
        var index = 0
        while index < bytes.count, [9, 10, 11, 12, 13, 32].contains(bytes[index]) {
            index += 1
        }
        var negative = false
        if index < bytes.count, bytes[index] == UInt8(ascii: "-") || bytes[index] == UInt8(ascii: "+") {
            negative = bytes[index] == UInt8(ascii: "-")
            index += 1
        }
        var value = 0
        while index < bytes.count, bytes[index] >= UInt8(ascii: "0"), bytes[index] <= UInt8(ascii: "9") {
            value = value &* 10 &+ Int(bytes[index] - UInt8(ascii: "0"))
            index += 1
        }
        return negative ? -value : value
    }

    // MARK: - Pass 3, COW distress.c:754-932

    /// `b` stands for COW's output buffer and its length together: COW
    /// moves the length back and forth over bytes it has written, so this
    /// keeps the bytes and a separate length.
    private struct Output {
        var bytes = [UInt8](repeating: 0, count: DistressMacro.bufferLength + 1)
        var count = 0
    }

    private static func condmacro(_ a: [UInt8], _ result: inout [UInt8], _ ia: inout Int, _ flag: Bool) {
        var out = Output()
        condmacro(a, &out, &ia, flag)
        result = Array(out.bytes[0..<out.count])
    }

    private static func condmacro(_ a: [UInt8], _ b: inout Output, _ ia: inout Int, _ flag: Bool) {
        guard b.count < maxMacroLength else { return }
        var include = flag
        var state = false

        while at(a, ia) != 0 && b.count < maxMacroLength {
            if state {
                let c = at(a, ia)
                ia += 1
                switch c {
                case UInt8(ascii: "}"):
                    return
                case UInt8(ascii: "{"):
                    var newFlag = true
                    if b.count > 0 {
                        b.count -= 1
                        newFlag = b.bytes[b.count] != UInt8(ascii: "0")
                    }
                    if include {
                        condmacro(a, &b, &ia, newFlag)
                    } else {
                        b.count += 1
                        ia = skipmacro(a, ia)
                    }
                    state = false
                    continue
                case UInt8(ascii: "!"):
                    include = !flag
                    state = false
                    continue
                case UInt8(ascii: "*"):
                    if include {
                        b.count = 0
                        return
                    }
                    state = false
                    continue
                case UInt8(ascii: "%"):
                    if include {
                        guard b.count < maxMacroLength else { return }
                        b.bytes[b.count] = UInt8(ascii: "%")
                        b.count += 1
                    }
                    state = false
                    continue
                case UInt8(ascii: ">"):
                    if include {
                        let stop = Int(at(a, ia))
                        ia += 1
                        while b.count < stop && b.count < maxMacroLength {
                            b.bytes[b.count] = UInt8(ascii: " ")
                            b.count += 1
                        }
                    }
                    state = false
                    continue
                default:
                    // COW warns and goes on with `state` still set
                    // (distress.c:849-853).
                    break
                }
            }

            if at(a, ia) == UInt8(ascii: "%") {
                state = true
                ia += 1
                continue
            }
            state = false
            if include {
                guard b.count < maxMacroLength else { return }
                b.bytes[b.count] = at(a, ia)
                b.count += 1
                ia += 1
            } else {
                ia += 1
            }
        }
    }

    private static func skipmacro(_ buf: [UInt8], _ start: Int) -> Int {
        var index = start == 0 ? 1 : start
        var state = false
        var end = false

        while at(buf, index) != 0 && !end {
            if state {
                let c = at(buf, index)
                index += 1
                switch c {
                case UInt8(ascii: "{"):
                    // COW keeps `state` set here (distress.c:897-900).
                    index = skipmacro(buf, index)
                    continue
                case UInt8(ascii: "}"):
                    end = true
                    continue
                case UInt8(ascii: ">"):
                    index += 1
                    state = false
                    continue
                case UInt8(ascii: "!"), UInt8(ascii: "%"), UInt8(ascii: "*"):
                    state = false
                    continue
                default:
                    break
                }
            }
            if at(buf, index) == UInt8(ascii: "%") {
                state = true
                index += 1
                continue
            }
            state = false
            index += 1
        }
        return index
    }
}
