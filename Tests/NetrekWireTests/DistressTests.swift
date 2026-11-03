//
//  DistressTests.swift
//  NetrekWireTests
//
//  RCD distress calls against golden data from the COW client itself.
//
//  The goldens in CowDistressGoldens.swift were made by
//  Tests/RCDHarness/make-goldens.sh: it compiles Tests/RCDHarness/harness.c
//  with COW's own distress.c and senddist.c (and the tables of its data.c)
//  from https://github.com/quozl/netrek-client-cow at f680bd3. For each case
//  the harness sets up a ship and what the mouse points at, calls COW's
//  emergency() so that loaddistress() and Dist2Mesg() build the call, keeps
//  the 80 bytes COW would put in the CP_MESSAGE, relays them as the vanilla
//  netrek-server does (address in front, cut at byte 69, flags | MVALID),
//  and reads them back with COW's HandleGenDistr() and makedistress() and
//  COW's default macros. The galaxy below is the one the harness uses.
//
//  COW notices. This file holds lines expanded from the COW client's
//  default RCD texts and its type names, which carry these notices
//  (copyright.h and copyright2.h at COW commit f680bd3):
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

import XCTest
import NetrekWire

/// One case made by the COW harness.
struct CowGolden {
    let name: String
    // The sender's ship in game units, as given to COW's loaddistress().
    let ship: Int, damage: Int, shield: Int, fuel: Int, weaponTemp: Int, engineTemp: Int, armies: Int, flags: UInt32
    let maxDamage: Int, maxShield: Int, maxFuel: Int, maxWeaponTemp: Int, maxEngineTemp: Int
    // COW's struct distress as sent.
    let type: UInt8, macroFlag: Bool, fuelPercent: Int, damagePercent: Int, shieldPercent: Int
    let engineTempPercent: Int, weaponTempPercent: Int, armyCount: Int, status: UInt8
    let nearestPlanet: Int, nearestEnemy: Int, targetPlanet: Int, targetEnemy: Int
    let targetPlayer: Int, nearestPlayer: Int, targetFriend: Int, nearestFriend: Int
    let ccList: [Int], terminator: UInt8
    let text: String
    let decodedText: String
    let sender: Int, group: UInt8, recipient: UInt8, relayedFlags: UInt8
    // What COW sent and what the server relayed, trailing zeros left out.
    let message: [UInt8]
    let relayed: [UInt8]
    // What COW showed.
    let expanded: String
    // What COW sends instead to a server without RC_DISTRESS.
    let plainGroup: UInt8
    let plainText: String

    var paddedMessage: [UInt8] { message + [UInt8](repeating: 0, count: MSG_LEN - message.count) }
    var paddedRelayed: [UInt8] { relayed + [UInt8](repeating: 0, count: MSG_LEN - relayed.count) }

    /// The same call as a Swift value, with the text as sent.
    var distress: Distress {
        var call = Distress(type: DistressType(rawValue: type)!, sender: sender,
                            damage: damagePercent, shields: shieldPercent, fuel: fuelPercent,
                            engineTemp: engineTempPercent, weaponTemp: weaponTempPercent,
                            armies: armyCount, status: DistressStatus(rawValue: status),
                            nearestPlanet: nearestPlanet, nearestEnemy: nearestEnemy,
                            nearestFriend: nearestFriend, nearestPlayer: nearestPlayer,
                            targetPlanet: targetPlanet, targetEnemy: targetEnemy,
                            targetFriend: targetFriend, targetPlayer: targetPlayer,
                            ccList: ccList,
                            textPosition: Distress.TextPosition(rawValue: terminator)!,
                            text: text, isMacro: macroFlag)
        call.sender = sender
        return call
    }
}

/// The galaxy of Tests/RCDHarness/harness.c.
enum HarnessGalaxy {
    static let fed: UInt8 = 1, rom: UInt8 = 2, kli: UInt8 = 4, ori: UInt8 = 8

    static let planetNames = [
        "Earth", "Rigel", "Canopus", "Beta Crucis", "Organia", "Deneb",
        "Ceti Alpha V", "Altair", "Vega", "Alpha Centauri",
        "Romulus", "Eridani", "Aldeberan", "Regulus", "Capella", "Tauceti",
        "Draconis", "Sirius", "Indi", "Hydrae",
        "Klingus", "Pliedes V", "Andromeda", "Lalande", "Pollux", "Lyrae",
        "Scorpii", "Mira", "Cygni", "Achernar",
        "Orion", "Cassiopia", "El Nath", "Spica", "Procyon", "Polaris",
        "Arcturus", "Ursae Majoris", "Herculis", "Antares",
    ]
    /// planet: (armies, teams with information)
    static let scouted: [Int: (armies: Int, info: UInt8)] = [
        31: (5, fed), 3: (12, fed), 13: (4, fed | rom), 1: (9, rom),
    ]
    static let players: [Int: (team: UInt8, name: String)] = [
        1: (fed, "Twinky"), 6: (rom, "Raboof"), 12: (fed, "Geebzy"), 3: (kli, "Klunk"),
        7: (rom, "Romy"), 9: (fed, "Fedora"), 14: (kli, "Kaboom"),
    ]

    static let lookup = DistressLookup(
        planetName: { planet in planet >= 0 && planet < planetNames.count ? planetNames[planet] : nil },
        planetOwner: { planet in planet < 10 ? fed : planet < 20 ? rom : planet < 30 ? kli : ori },
        planetArmies: { planet, team in
            guard let known = scouted[planet], known.info & team != 0 else { return nil }
            return known.armies
        },
        playerTeam: { slot in players[slot]?.team ?? 0 })

    static func sender(_ golden: CowGolden) -> DistressSender {
        let player = players[golden.sender]!
        return DistressSender(team: player.team, name: player.name, shipType: golden.ship)
    }
}

final class DistressTests: XCTestCase {

    // MARK: - Golden data from COW

    func testGoldens_CoverTheCallsParallaxSendsFirst() {
        let names = Set(cowGoldens.map(\.name))
        for name in ["carrying", "help", "escorting", "ogging", "take", "baseOgg",
                     "bombing", "controlling", "help1"] {
            XCTAssertTrue(names.contains(name), name)
        }
        let types = Set(cowGoldens.map(\.type))
        XCTAssertEqual(types, Set(DistressType.sendable), "a golden for every type COW sends")
    }

    func testEncode_MatchesCowByteForByte() {
        for golden in cowGoldens {
            XCTAssertEqual(golden.distress.encode(), golden.paddedMessage, golden.name)
        }
    }

    func testEncode_GroupAndRecipientMatchCow() {
        for golden in cowGoldens {
            XCTAssertEqual(Distress.group, golden.group, golden.name)
            XCTAssertEqual(golden.recipient, HarnessGalaxy.fed, golden.name)
        }
        XCTAssertEqual(Distress.group, 0xC4)
    }

    func testClientPacket_IsTheWholeCpMessage() {
        let golden = cowGoldens.first { $0.name == "carrying" }!
        let packet = golden.distress.clientPacket(team: golden.recipient)
        XCTAssertEqual(packet.count, CLIENT_PACKET_SIZES[Int(ClientPacketType.message.rawValue)])
        XCTAssertEqual(Array(packet.prefix(4)), [1, golden.group, golden.recipient, 0])
        XCTAssertEqual(Array(packet.dropFirst(4)), golden.paddedMessage)
    }

    func testFromShip_FillsTheShipStateLikeLoaddistress() {
        for golden in cowGoldens {
            var call = Distress.fromShip(
                type: DistressType(rawValue: golden.type)!, sender: golden.sender,
                damage: golden.damage, maxDamage: golden.maxDamage,
                shield: golden.shield, maxShield: golden.maxShield,
                fuel: golden.fuel, maxFuel: golden.maxFuel,
                weaponTemp: golden.weaponTemp, maxWeaponTemp: golden.maxWeaponTemp,
                engineTemp: golden.engineTemp, maxEngineTemp: golden.maxEngineTemp,
                armies: golden.armies, flags: golden.flags)
            XCTAssertEqual(call.damage, golden.damagePercent, golden.name)
            XCTAssertEqual(call.shields, golden.shieldPercent, golden.name)
            XCTAssertEqual(call.fuel, golden.fuelPercent, golden.name)
            XCTAssertEqual(call.engineTemp, golden.engineTempPercent, golden.name)
            XCTAssertEqual(call.weaponTemp, golden.weaponTempPercent, golden.name)
            XCTAssertEqual(call.armies, golden.armyCount, golden.name)
            XCTAssertEqual(call.status.rawValue, golden.status, golden.name)

            call.nearestPlanet = golden.nearestPlanet
            call.nearestEnemy = golden.nearestEnemy
            call.nearestFriend = golden.nearestFriend
            call.nearestPlayer = golden.nearestPlayer
            call.targetPlanet = golden.targetPlanet
            call.targetEnemy = golden.targetEnemy
            call.targetFriend = golden.targetFriend
            call.targetPlayer = golden.targetPlayer
            if golden.ccList.isEmpty && golden.text.isEmpty && !golden.macroFlag && golden.terminator == 0x80 {
                XCTAssertEqual(call.encode(), golden.paddedMessage, golden.name)
            }
        }
    }

    func testDecode_ReadsWhatTheServerRelaysLikeHandleGenDistr() {
        for golden in cowGoldens {
            var expected = golden.distress
            expected.text = golden.decodedText
            let decoded = Distress.decode(golden.paddedRelayed, from: golden.sender, flags: golden.relayedFlags)
            XCTAssertEqual(decoded, expected, golden.name)
        }
    }

    func testDecode_ReadsWhatTheClientSends() {
        for golden in cowGoldens {
            var expected = golden.distress
            expected.text = String(golden.text.prefix(Distress.maxTextLength - golden.ccList.count))
            let decoded = Distress.decode(clientMessage: golden.paddedMessage, from: golden.sender,
                                          group: golden.group)
            XCTAssertEqual(decoded, expected, golden.name)
        }
    }

    func testDefaultText_MatchesWhatCowShows() {
        for golden in cowGoldens {
            let decoded = Distress.decode(golden.paddedRelayed, from: golden.sender)!
            let text = decoded.defaultText(sender: HarnessGalaxy.sender(golden), lookup: HarnessGalaxy.lookup)
            XCTAssertEqual(text, golden.expanded, golden.name)
        }
    }

    func testPlainText_MatchesWhatCowSendsWithoutRcDistress() {
        for golden in cowGoldens {
            XCTAssertEqual(golden.plainGroup, MessageFlag.team, golden.name)
            let text = golden.distress.plainText(sender: HarnessGalaxy.sender(golden), lookup: HarnessGalaxy.lookup)
            XCTAssertEqual(text, golden.plainText, golden.name)
        }
    }

    func testDefaultText_ForTheCallsParallaxSendsFirst() {
        let expected = [
            "carrying": " F1->FED Carrying 3 armies.",
            "help": " F1->FED Help(CA)! 60% shd, 40% dmg, 63% fuel, 3 armies!",
            "escorting": " F1->FED ESCORTING c (40%D 60%S 63%F)",
            "ogging": " F1->FED Ogging 6",
            "take": " F1->FED (CA) Carrying 3 to cas @ 5",
            "baseOgg": " F1->FED Sync with --]> c <[-- OGG ogg OGG base!!",
            "bombing": " F1->FED Bombing cas @ 5",
            "controlling": " F1->FED Controlling at reg",
        ]
        for (name, line) in expected {
            let golden = cowGoldens.first { $0.name == name }!
            XCTAssertEqual(golden.expanded, line, name)
            XCTAssertEqual(golden.distress.defaultText(sender: HarnessGalaxy.sender(golden),
                                                       lookup: HarnessGalaxy.lookup), line, name)
        }
    }

    // MARK: - Round trip

    func testRoundTrip_EveryTypeOverTheFieldRanges() {
        var generator = SplitMix64(seed: 289)
        for type in DistressType.allCases where type != .rcm {
            for percent in [0, 1, 50, 99, 100, 101, 126, 127] {
                for armies in [0, 1, 2, 17, 30, 31] {
                    let sender = Int(generator.next() % 32)
                    let call = Distress(
                        type: type, sender: sender,
                        damage: percent, shields: 127 - percent,
                        fuel: Int(generator.next() % 128),
                        engineTemp: Int(generator.next() % 128),
                        weaponTemp: Int(generator.next() % 128),
                        armies: armies,
                        status: DistressStatus(rawValue: UInt8(generator.next() % 128)),
                        nearestPlanet: Int(generator.next() % 40),
                        nearestEnemy: Int(generator.next() % 32),
                        nearestFriend: Int(generator.next() % 32),
                        nearestPlayer: Int(generator.next() % 32),
                        targetPlanet: Int(generator.next() % 40),
                        targetEnemy: Int(generator.next() % 32),
                        targetFriend: Int(generator.next() % 32),
                        targetPlayer: Int(generator.next() % 32),
                        isMacro: generator.next() % 2 == 0)
                    let bytes = call.encode()
                    XCTAssertEqual(bytes.count, MSG_LEN)
                    XCTAssertEqual(Distress.decode(clientMessage: bytes, from: sender), call, "\(type)")
                    XCTAssertEqual(Distress.decode(relay(bytes), from: sender,
                                                   flags: MessageFlag.relayedTeamDistress), call, "\(type)")
                }
            }
        }
    }

    func testRoundTrip_CcListsAndText() {
        let texts = ["", "x", "on my way", String(repeating: "a", count: Distress.maxRelayedTextLength - 5)]
        for count in 0...Distress.maxCcCount {
            for text in texts {
                for position in [Distress.TextPosition.prepend, .append] {
                    let call = Distress(type: .carrying, sender: 4, armies: 6,
                                        ccList: Array([0, 31, 7, 12, 3].prefix(count)),
                                        textPosition: position, text: text)
                    let bytes = call.encode()
                    XCTAssertEqual(Distress.decode(clientMessage: bytes, from: 4), call)
                    XCTAssertEqual(Distress.decode(relay(bytes), from: 4), call)
                }
            }
        }
    }

    func testRoundTrip_NoNearbyPlayersAreTheSenderAsInCow() {
        let call = Distress(type: .ogging, sender: 9, nearestPlanet: 2, targetPlanet: 5)
        XCTAssertEqual(call.nearestEnemy, 9)
        XCTAssertEqual(call.targetEnemy, 9)
        XCTAssertEqual(call.targetFriend, 9)
        XCTAssertEqual(Distress.decode(relay(call.encode()), from: 9), call)
    }

    // MARK: - Clamping and the RCM type

    func testEncode_ClampsToWhatReceiversRead() {
        let call = Distress(type: .generic, sender: 1, damage: 250, shields: -5, fuel: 128,
                            engineTemp: 1000, weaponTemp: 300, armies: 40,
                            nearestPlanet: 200, targetPlanet: -1, ccList: [40, -2])
        let decoded = Distress.decode(clientMessage: call.encode(), from: 1)!
        XCTAssertEqual(decoded.damage, 127)
        XCTAssertEqual(decoded.shields, 0)
        XCTAssertEqual(decoded.fuel, 127)
        XCTAssertEqual(decoded.engineTemp, 127)
        XCTAssertEqual(decoded.weaponTemp, 127)
        XCTAssertEqual(decoded.armies, 31)
        XCTAssertEqual(decoded.nearestPlanet, 127)
        XCTAssertEqual(decoded.targetPlanet, 0)
        XCTAssertEqual(decoded.ccList, [31, 0])
    }

    func testEncode_KeepsAtMostFiveCcAndTextUpToByte79() {
        let call = Distress(type: .generic, sender: 1, ccList: [1, 2, 3, 4, 5, 6, 7],
                            text: String(repeating: "z", count: 100))
        let bytes = call.encode()
        XCTAssertEqual(bytes.count, MSG_LEN)
        XCTAssertEqual(Array(bytes[16..<21]), [0xC1, 0xC2, 0xC3, 0xC4, 0xC5])
        XCTAssertEqual(bytes[21], 0x80)
        XCTAssertEqual(bytes[79], 0, "COW ends the message at byte 79")
        XCTAssertEqual(bytes[22..<79].count, Distress.maxTextLength - 5)
        XCTAssertTrue(bytes[22..<79].allSatisfy { $0 == UInt8(ascii: "z") })
    }

    func testEncode_StopsTheTextAtANul() {
        let call = Distress(type: .generic, sender: 1, text: "ab\u{0}cd")
        XCTAssertEqual(Array(call.encode()[17..<20]), [0x61, 0x62, 0x00])
    }

    func testEncode_RcmIsSentAsGenericLikeCow() {
        let call = Distress(type: .rcm, sender: 1)
        XCTAssertEqual(call.encode()[0], DistressType.generic.rawValue)
        XCTAssertEqual(Distress.decode(clientMessage: call.encode(), from: 1)?.type, .generic)
    }

    func testFromShip_CapsWeaponTempAndHandlesZeroMaximum() {
        let call = Distress.fromShip(type: .generic, sender: 0, damage: 50, maxDamage: 0,
                                     shield: 10, maxShield: 100, fuel: 1, maxFuel: 3,
                                     weaponTemp: 5000, maxWeaponTemp: 1000,
                                     engineTemp: 999, maxEngineTemp: 1000,
                                     armies: 2, flags: 0xFFFF_FF90)
        XCTAssertEqual(call.damage, 0)
        XCTAssertEqual(call.fuel, 33)
        XCTAssertEqual(call.weaponTemp, 127)
        XCTAssertEqual(call.engineTemp, 99)
        XCTAssertEqual(call.status.rawValue, 0x10, "low byte of p_flags without its top bit")
        XCTAssertTrue(call.isCloaked)
    }

    func testStatusShortcuts() {
        var call = Distress(type: .generic, sender: 0)
        call.isCloaked = true
        call.weaponsOverheated = true
        call.enginesOverheated = true
        XCTAssertEqual(call.status.rawValue, 0x70)
        call.isCloaked = false
        XCTAssertEqual(call.status, [.weaponsOverheated, .enginesOverheated])
        XCTAssertEqual(call.encode()[7], 0xE0)
    }

    // MARK: - Decoding rejects what is not a distress call

    func testDecode_RejectsChat() {
        for line in ["Help me! 40% dam, 60% shd", "carrying 3", "F", "E",
                     String(repeating: "x", count: 69), "\u{16}\u{3f}\u{28}"] {
            let body = address() + Array(line.utf8)
            XCTAssertNil(Distress.decode(pad(body), from: 1), line)
            XCTAssertNil(Distress.decode(pad(body), from: 1, flags: MessageFlag.relayedTeamDistress), line)
            XCTAssertNil(Distress.decode(clientMessage: pad(Array(line.utf8)), from: 1), line)
        }
    }

    func testDecode_RejectsEmptyShortAndTruncatedMessages() {
        let good = relay(Distress(type: .carrying, sender: 1, armies: 3).encode())
        XCTAssertNotNil(Distress.decode(good, from: 1))

        XCTAssertNil(Distress.decode([UInt8](), from: 1))
        XCTAssertNil(Distress.decode([UInt8](repeating: 0, count: MSG_LEN), from: 1))
        XCTAssertNil(Distress.decode(address(), from: 1))
        for length in 0..<(Distress.addressLength + Distress.headerLength) {
            XCTAssertNil(Distress.decode(good.prefix(length), from: 1), "\(length) bytes")
        }
        XCTAssertNotNil(Distress.decode(good.prefix(Distress.addressLength + Distress.headerLength), from: 1))

        // Cut inside the binary part by a NUL.
        var cut = good
        cut[Distress.addressLength + 9] = 0
        XCTAssertNil(Distress.decode(cut, from: 1))
    }

    func testDecode_RejectsBadTypesMarksAndTerminators() {
        let good = Distress(type: .carrying, sender: 1, armies: 3).encode()
        for type: UInt8 in [0, 26, 27, 31, 0x20] {
            var bytes = good
            bytes[0] = type
            XCTAssertNil(Distress.decode(clientMessage: bytes, from: 1), "type \(type)")
        }
        for offset in 1...15 {
            var bytes = good
            bytes[offset] &= 0x7f
            XCTAssertNil(Distress.decode(clientMessage: bytes, from: 1), "mark at \(offset)")
        }
        for terminator: UInt8 in [0x00, 0x41, 0x81, 0x20] {
            var bytes = good
            bytes[16] = terminator
            XCTAssertNil(Distress.decode(clientMessage: bytes, from: 1), "terminator \(terminator)")
        }
    }

    func testDecode_RejectsOtherFlagsAndGroups() {
        let bytes = Distress(type: .carrying, sender: 1, armies: 3).encode()
        let relayed = relay(bytes)
        for flags: UInt8 in [MessageFlag.team | MessageFlag.valid, MessageFlag.all | MessageFlag.valid,
                             MessageFlag.individual | MessageFlag.valid, MessageFlag.teamDistress,
                             MessageFlag.all | MessageFlag.join | MessageFlag.valid] {
            XCTAssertNil(Distress.decode(relayed, from: 1, flags: flags), "flags \(flags)")
        }
        XCTAssertNil(Distress.decode(clientMessage: bytes, from: 1, group: MessageFlag.team))
        XCTAssertNotNil(Distress.decode(clientMessage: bytes, from: 1, group: Distress.group))
    }

    // MARK: - Constants

    func testDistressTypeNumbersMatchCow() {
        let expected: [(DistressType, UInt8, String)] = [
            (.take, 1, "taking"), (.ogg, 2, "ogg"), (.bomb, 3, "bomb"),
            (.spaceControl, 4, "space_control"), (.savePlanet, 5, "save_planet"),
            (.baseOgg, 6, "base_ogg"), (.help1, 7, "help1"), (.help2, 8, "help2"),
            (.escorting, 9, "escorting"), (.ogging, 10, "ogging"), (.bombing, 11, "bombing"),
            (.controlling, 12, "controlling"), (.asw, 13, "asw"), (.asbomb, 14, "asbomb"),
            (.doing1, 15, "doing1"), (.doing2, 16, "doing2"), (.freeBeer, 17, "free_beer"),
            (.noGas, 18, "no_gas"), (.crippled, 19, "crippled"), (.pickup, 20, "pickup"),
            (.pop, 21, "pop"), (.carrying, 22, "carrying"), (.other1, 23, "other1"),
            (.other2, 24, "other2"), (.generic, 25, "help"), (.rcm, 26, "rcm"),
        ]
        XCTAssertEqual(DistressType.allCases.count, expected.count)
        for (type, number, name) in expected {
            XCTAssertEqual(type.rawValue, number)
            XCTAssertEqual(type.classicName, name)
        }
        XCTAssertEqual(DistressType.sendable, 1...25)
        XCTAssertNil(DistressType.rcm.defaultMacro)
        for type in DistressType.allCases where type != .rcm {
            XCTAssertNotNil(type.defaultMacro, "\(type)")
        }
    }

    func testMessageFlagsMatchClassicValues() {
        XCTAssertEqual(MessageFlag.valid, 0x01)
        XCTAssertEqual(MessageFlag.individual, 0x02)
        XCTAssertEqual(MessageFlag.team, 0x04)
        XCTAssertEqual(MessageFlag.all, 0x08)
        XCTAssertEqual(MessageFlag.god, 0x10)
        XCTAssertEqual(MessageFlag.moo, 0x12)
        XCTAssertEqual(MessageFlag.tools, 0x14)
        XCTAssertEqual(MessageFlag.debug, 0x20)
        XCTAssertEqual(MessageFlag.config, 0x40)
        XCTAssertEqual(MessageFlag.individualDistress, 0x60)
        XCTAssertEqual(MessageFlag.multilineMacro, 0x80)
        XCTAssertEqual(MessageFlag.take, 0x20)
        XCTAssertEqual(MessageFlag.destroy, 0x40)
        XCTAssertEqual(MessageFlag.bomb, 0x60)
        XCTAssertEqual(MessageFlag.coup1, 0x80)
        XCTAssertEqual(MessageFlag.coup2, 0xA0)
        XCTAssertEqual(MessageFlag.distress, 0xC0)
        XCTAssertEqual(MessageFlag.genocide, 0x20)
        XCTAssertEqual(MessageFlag.conquer, 0x20)
        XCTAssertEqual(MessageFlag.killA, 0x40)
        XCTAssertEqual(MessageFlag.killP, 0x60)
        XCTAssertEqual(MessageFlag.kill, 0x80)
        XCTAssertEqual(MessageFlag.leave, 0xA0)
        XCTAssertEqual(MessageFlag.join, 0xC0)
        XCTAssertEqual(MessageFlag.ghost, 0xE0)
        XCTAssertEqual(MessageFlag.whoMask, 0x1f)
        XCTAssertEqual(MessageFlag.whatMask, 0xe0)
        XCTAssertEqual(MessageFlag.teamDistress, 0xC4)
        XCTAssertEqual(MessageFlag.relayedTeamDistress, 0xC5)
    }

    func testLengths() {
        XCTAssertEqual(Distress.addressLength, 10)
        XCTAssertEqual(Distress.headerLength, 17)
        XCTAssertEqual(Distress.maxTextLength, 62)
        XCTAssertEqual(Distress.maxRelayedTextLength, 52)
    }

    // MARK: - Helpers

    /// " F1->FED  ", the address the vanilla server writes for F1 to FED.
    private func address() -> [UInt8] {
        return Array(" F1->FED  ".utf8)
    }

    private func pad(_ bytes: [UInt8]) -> [UInt8] {
        return Array((bytes + [UInt8](repeating: 0, count: MSG_LEN)).prefix(MSG_LEN))
    }

    /// The vanilla server's relay: client bytes cut at 69, address in front,
    /// copied as a C string (ntserv/socket.c:1485, smessage.c:195-196).
    private func relay(_ clientBytes: [UInt8]) -> [UInt8] {
        let text = clientBytes.prefix(MSG_LEN - 11).prefix { $0 != 0 }
        return pad(address() + text)
    }
}

/// A small fixed-seed generator so the round trip covers the same values on
/// every run.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
