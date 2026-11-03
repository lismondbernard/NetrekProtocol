//
//  DistressPacketTests.swift
//  NetrekProtocolTests
//
//  RCD distress calls end to end: MakePacket.cpDistress builds the
//  CP_MESSAGE, a relay written like the vanilla netrek-server's turns it
//  into the SP_MESSAGE other clients get, and PacketAnalyzer hands it to the
//  new distress path while chat keeps going to Universe.gotMessage.
//
//  COW notices. This file holds lines expanded from the COW client's
//  default RCD texts, which carry these notices (copyright.h and
//  copyright2.h at COW commit f680bd3):
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
@testable import NetrekProtocol

final class MessageRecordingDelegate: UniverseEventDelegate {
    var messages: [ReceivedMessage] = []
    var distressCalls: [(Distress, ReceivedMessage)] = []

    func universe(_ universe: Universe, receivedMessage message: ReceivedMessage) {
        messages.append(message)
    }
    func universe(_ universe: Universe, receivedDistress distress: Distress, message: ReceivedMessage) {
        distressCalls.append((distress, message))
    }
}

final class DistressPacketTests: XCTestCase {

    var universe: Universe!
    var analyzerDelegate: RecordingAnalyzerDelegate!
    var events: MessageRecordingDelegate!
    var analyzer: PacketAnalyzer!

    override func setUp() {
        super.setUp()
        universe = Universe()
        analyzerDelegate = RecordingAnalyzerDelegate()
        events = MessageRecordingDelegate()
        universe.eventDelegate = events
        analyzer = PacketAnalyzer(delegate: analyzerDelegate, universe: universe)
        setUpGalaxy()
    }

    override func tearDown() {
        analyzer = nil
        events = nil
        analyzerDelegate = nil
        universe = nil
        super.tearDown()
    }

    private func drainMainQueue() {
        let expectation = XCTestExpectation(description: "main queue")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
    }

    /// F1 "Twinky" in a CA, F9 and Fc team mates, R6 and R7 enemies.
    /// Cassiopia (31) with 5 armies scouted by FED, Rigel (1) not scouted.
    private func setUpGalaxy() {
        universe.updatePlayer(playerId: 1, shipType: ShipType.cruiser.rawValue, team: Team.federation.rawValue)
        universe.updatePlayer(playerId: 1, rank: 0, name: "Twinky", login: "twinky")
        universe.updatePlayer(playerId: 9, shipType: ShipType.assault.rawValue, team: Team.federation.rawValue)
        universe.updatePlayer(playerId: 12, shipType: ShipType.destroyer.rawValue, team: Team.federation.rawValue)
        universe.updatePlayer(playerId: 6, shipType: ShipType.cruiser.rawValue, team: Team.roman.rawValue)
        universe.updatePlayer(playerId: 7, shipType: ShipType.battleship.rawValue, team: Team.roman.rawValue)
        universe.createPlanet(planetId: 31, positionX: 0, positionY: 0, name: "Cassiopia")
        universe.planets[31].update(owner: Team.orion.rawValue, info: Team.federation.rawValue, flags: 0, armies: 5)
        universe.createPlanet(planetId: 1, positionX: 0, positionY: 0, name: "Rigel")
        universe.planets[1].update(owner: Team.federation.rawValue, info: Team.roman.rawValue, flags: 0, armies: 9)
        universe.createPlanet(planetId: 3, positionX: 0, positionY: 0, name: "Beta Crucis")
        universe.planets[3].update(owner: Team.federation.rawValue, info: Team.federation.rawValue, flags: 0, armies: 12)
        drainMainQueue()
    }

    // MARK: - CP_MESSAGE bytes, unchanged

    private func expectedMessage(group: UInt8, indiv: UInt8, text: String) -> Data {
        var bytes: [UInt8] = [1, group, indiv, 0]
        let textBytes = Array(text.utf8.prefix(79))
        bytes += textBytes + [UInt8](repeating: 0, count: 80 - textBytes.count)
        return Data(bytes)
    }

    func testCpMessage_BytesForAllTeamAndIndividual() {
        XCTAssertEqual(MakePacket.cpMessage(message: "hi all", team: .independent, individual: 5),
                       expectedMessage(group: 8, indiv: 0, text: "hi all"))
        XCTAssertEqual(MakePacket.cpMessage(message: "hi all", team: .ogg, individual: 5),
                       expectedMessage(group: 8, indiv: 0, text: "hi all"))
        XCTAssertEqual(MakePacket.cpMessage(message: "fed", team: .federation, individual: 5),
                       expectedMessage(group: 4, indiv: 1, text: "fed"))
        XCTAssertEqual(MakePacket.cpMessage(message: "rom", team: .roman, individual: 0),
                       expectedMessage(group: 4, indiv: 2, text: "rom"))
        XCTAssertEqual(MakePacket.cpMessage(message: "kli", team: .kazari, individual: 0),
                       expectedMessage(group: 4, indiv: 4, text: "kli"))
        XCTAssertEqual(MakePacket.cpMessage(message: "ori", team: .orion, individual: 0),
                       expectedMessage(group: 4, indiv: 8, text: "ori"))
        XCTAssertEqual(MakePacket.cpMessage(message: "psst", team: nil, individual: 12),
                       expectedMessage(group: 2, indiv: 12, text: "psst"))
        let long = String(repeating: "x", count: 100)
        XCTAssertEqual(MakePacket.cpMessage(message: long, team: .federation, individual: 0),
                       expectedMessage(group: 4, indiv: 1, text: long))
        XCTAssertEqual(MakePacket.cpMessage(message: "", team: nil, individual: 3),
                       expectedMessage(group: 2, indiv: 3, text: ""))
    }

    func testCpMessage_GroupsAreTheNamedFlags() {
        XCTAssertEqual(MakePacket.cpMessage(message: "a", team: .independent, individual: 0)[1], MessageFlag.all)
        XCTAssertEqual(MakePacket.cpMessage(message: "a", team: .orion, individual: 0)[1], MessageFlag.team)
        XCTAssertEqual(MakePacket.cpMessage(message: "a", team: nil, individual: 0)[1], MessageFlag.individual)
    }

    // MARK: - CP_MESSAGE for a distress call

    func testCpDistress_TypeGroupRecipientAndSize() {
        let call = Distress(type: .carrying, sender: 1, armies: 3)
        for team in [Team.federation, .roman, .kazari, .orion] {
            let data = MakePacket.cpDistress(call, team: team)
            XCTAssertEqual(data.count, 84)
            XCTAssertEqual(data.count, CLIENT_PACKET_SIZES[Int(ClientPacketType.message.rawValue)])
            XCTAssertEqual(data[0], ClientPacketType.message.rawValue)
            XCTAssertEqual(data[1], 0xC4, "MTEAM | MDISTR")
            XCTAssertEqual(data[1], Distress.group)
            XCTAssertEqual(data[2], UInt8(team.rawValue))
            XCTAssertEqual(data[3], 0)
            XCTAssertEqual(Array(data[4...]), call.encode())
        }
    }

    func testCpDistress_MatchesTheCowGoldenForCarrying() {
        // CowDistressGoldens "carrying": F1, 3 armies, CA, shields up.
        let call = Distress(type: .carrying, sender: 1, damage: 40, shields: 60, fuel: 63,
                            engineTemp: 12, weaponTemp: 25, armies: 3, status: .shields,
                            nearestPlanet: 3, nearestEnemy: 6, nearestFriend: 12, nearestPlayer: 12,
                            targetPlanet: 31, targetEnemy: 6, targetFriend: 12, targetPlayer: 12)
        let data = MakePacket.cpDistress(call, team: .federation)
        let cow: [UInt8] = [0x16, 0xbf, 0xa8, 0xbc, 0x8c, 0x99, 0x83, 0x81, 0x83, 0x86,
                            0x9f, 0x86, 0x8c, 0x8c, 0x8c, 0x8c, 0x80]
        XCTAssertEqual(Array(data.prefix(4)), [1, 0xC4, 1, 0])
        XCTAssertEqual(Array(data[4...]), cow + [UInt8](repeating: 0, count: 80 - cow.count))
    }

    // MARK: - End to end, the calls Parallax sends first

    /// The SP_MESSAGE the vanilla server sends to RC_DISTRESS clients for a
    /// CP_MESSAGE: address " F1->FED  " in front, client text cut at byte 69
    /// and copied as a C string, flags | MVALID (ntserv/socket.c:1485-1505,
    /// 1713; smessage.c:186-206; genspkt.c:1005-1010).
    private func relay(_ packet: Data, from slot: Int) -> Data {
        let teamshort: [UInt8: String] = [1: "FED", 2: "ROM", 4: "KLI", 8: "ORI"]
        let teamlet: [UInt8: String] = [1: "F", 2: "R", 4: "K", 8: "O"]
        let shipnos = Array("0123456789abcdefghijklmnopqrstuvwxyz")
        let senderTeam = UInt8(universe.players[slot].team.rawValue)
        let address = " \(teamlet[senderTeam]!)\(shipnos[slot])->\(teamshort[packet[2]]!)"
        var body = Array(address.utf8)
        body += [UInt8](repeating: 0x20, count: 9 - body.count) + [0x20]
        body += Array(packet[4...].prefix(69)).prefix { $0 != 0 }
        body += [UInt8](repeating: 0, count: 80 - body.count)
        return Data([1, packet[1] | MessageFlag.valid, packet[2], UInt8(slot)] + body)
    }

    private struct Call {
        let name: String
        let distress: Distress
        let line: String
    }

    private var firstCalls: [Call] {
        let base = Distress(type: .generic, sender: 1, damage: 40, shields: 60, fuel: 63,
                            engineTemp: 12, weaponTemp: 25, armies: 3, status: .shields,
                            nearestPlanet: 3, nearestEnemy: 6, nearestFriend: 9, nearestPlayer: 9)
        func call(_ name: String, _ type: DistressType, _ line: String,
                  _ change: (inout Distress) -> Void) -> Call {
            var distress = base
            distress.type = type
            change(&distress)
            return Call(name: name, distress: distress, line: line)
        }
        return [
            call("carrying", .carrying, " F1->FED Carrying 3 armies.") { _ in },
            call("carrying none", .carrying, " F1->FED Carrying NO armies.") { $0.armies = 0 },
            call("help", .generic, " F1->FED Help(CA)! 60% shd, 40% dmg, 63% fuel, 3 armies!") { _ in },
            call("help overheated", .generic,
                 " F1->FED Help(CA)! 60% shd, 40% dmg, 63% fuel, ETEMP! WTEMP! 3 armies!") {
                $0.weaponsOverheated = true
                $0.enginesOverheated = true
            },
            call("help me", .help1, " F1->FED Help me! 40% dam, 60% shd, 63% fuel 3 armies.") { _ in },
            call("escorting", .escorting, " F1->FED ESCORTING c (40%D 60%S 63%F)") { $0.targetFriend = 12 },
            call("ogging", .ogging, " F1->FED Ogging 7") { $0.targetEnemy = 7 },
            call("ogg", .ogg, " F1->FED Help Ogg 6 at cas") {
                $0.targetPlayer = 6
                $0.targetPlanet = 31
            },
            call("take", .take, " F1->FED (CA) Carrying 3 to cas @ 5") { $0.targetPlanet = 31 },
            call("take unscouted", .take, " F1->FED (CA) Carrying 3 to rig") { $0.targetPlanet = 1 },
            call("base ogg", .baseOgg, " F1->FED Sync with --]> c <[-- OGG ogg OGG base!!") { $0.targetFriend = 12 },
            call("going to bomb", .bombing, " F1->FED Bombing cas @ 5") { $0.targetPlanet = 31 },
            call("going to control", .controlling, " F1->FED Controlling at bet") { $0.targetPlanet = 3 },
        ]
    }

    func testFirstCalls_RoundTripThroughServerAndAnalyzer() {
        for call in firstCalls {
            events.messages = []
            events.distressCalls = []
            let packet = MakePacket.cpDistress(call.distress, team: .federation)
            analyzer.analyze(incomingData: relay(packet, from: 1))
            drainMainQueue()

            XCTAssertEqual(events.distressCalls.count, 1, call.name)
            XCTAssertEqual(events.distressCalls.first?.0, call.distress, call.name)
            XCTAssertEqual(events.distressCalls.first?.1.flags, 0xC5, call.name)
            XCTAssertEqual(events.distressCalls.first?.1.sender, 1, call.name)
            XCTAssertEqual(events.distressCalls.first?.1.recipient, 1, call.name)
            XCTAssertEqual(events.messages.count, 1, call.name)
            XCTAssertEqual(events.messages.first?.distress, call.distress, call.name)

            XCTAssertEqual(universe.defaultText(for: call.distress), call.line, call.name)
        }
    }

    func testFirstCalls_ShownAsTextWhenTheAnalyzerExpandsThem() {
        analyzer = PacketAnalyzer(delegate: analyzerDelegate, universe: universe, textFilter: { $0 })
        analyzer.expandsDistressCalls = true
        for call in firstCalls {
            analyzer.analyze(incomingData: relay(MakePacket.cpDistress(call.distress, team: .federation), from: 1))
            drainMainQueue()
            XCTAssertEqual(universe.lastMessage, call.line, call.name)
        }
    }

    func testExpandedDistress_GoesThroughTheTextFilter() {
        analyzer.expandsDistressCalls = true
        let call = Distress(type: .bombing, sender: 1, targetPlanet: 31)
        analyzer.analyze(incomingData: relay(MakePacket.cpDistress(call, team: .federation), from: 1))
        drainMainQueue()
        XCTAssertEqual(universe.lastMessage, NetrekMath.sanitizeString(" F1->FED Bombing cas @ 5"))
    }

    // MARK: - PacketAnalyzer keeps the chat path as it was

    /// What PacketAnalyzer put into gotMessage before this change.
    private func legacyText(_ packet: Data, filter: (String) -> String = NetrekMath.sanitizeString) -> String? {
        guard let text = String(data: packet.subdata(in: 4..<84), encoding: .ascii) else { return nil }
        return filter(String(text.prefix { $0 != "\0" }))
    }

    func testChat_StillReachesGotMessageAndNotTheDistressPath() {
        let packet = PacketBuilder.spMessage(flags: MessageFlag.team | MessageFlag.valid, recipient: 1, from: 1,
                                             message: " F1->FED  Romulus needs help")
        analyzer.analyze(incomingData: packet)
        drainMainQueue()

        XCTAssertEqual(universe.lastMessage, " F1->FED  Rome needs help")
        XCTAssertEqual(universe.messages.count, 1)
        XCTAssertTrue(events.distressCalls.isEmpty)
        XCTAssertEqual(events.messages.count, 1)
        XCTAssertEqual(events.messages.first?.flags, 0x05)
        XCTAssertEqual(events.messages.first?.sender, 1)
        XCTAssertNil(events.messages.first?.distress)
        XCTAssertFalse(events.messages.first!.isDistress)
    }

    func testChat_WithTheDistressFlagsButTextIsNotADistressCall() {
        let packet = PacketBuilder.spMessage(flags: MessageFlag.relayedTeamDistress, recipient: 1, from: 1,
                                             message: " F1->FED  Help me!")
        analyzer.analyze(incomingData: packet)
        drainMainQueue()
        XCTAssertEqual(universe.lastMessage, " F1->FED  Help me!")
        XCTAssertTrue(events.distressCalls.isEmpty)
    }

    func testServerMessages_StillReachGotMessage() {
        analyzer.analyze(incomingData: PacketBuilder.spMessage(flags: MessageFlag.all | MessageFlag.kill | MessageFlag.valid,
                                                               message: "GOD->ALL R6 was kill 1.00 for F1"))
        drainMainQueue()
        XCTAssertEqual(universe.lastMessage, "GOD->ALL R6 was kill 1.00 for F1")
        XCTAssertTrue(events.distressCalls.isEmpty)
        XCTAssertEqual(events.messages.first?.sender, 255)
    }

    func testDistress_GotMessageIsAsBeforeByDefault() {
        let packet = relay(MakePacket.cpDistress(Distress(type: .carrying, sender: 1, armies: 3), team: .federation),
                           from: 1)
        analyzer.analyze(incomingData: packet)
        drainMainQueue()
        XCTAssertEqual(events.distressCalls.count, 1)
        if let legacy = legacyText(packet) {
            XCTAssertEqual(universe.lastMessage, legacy)
            XCTAssertEqual(universe.messages.count, 1)
        } else {
            XCTAssertTrue(universe.messages.isEmpty, "the old path dropped bytes it could not read as ASCII")
        }
    }

    func testReceivedMessage_CarriesTheRawBody() {
        let packet = relay(MakePacket.cpDistress(Distress(type: .ogging, sender: 1, targetEnemy: 6), team: .federation),
                           from: 1)
        analyzer.analyze(incomingData: packet)
        drainMainQueue()
        let message = events.messages.first!
        XCTAssertEqual(message.body, Array(packet[4..<84]))
        XCTAssertEqual(message.body.count, 80)
        XCTAssertTrue(message.isDistress)
    }

    // MARK: - RC_DISTRESS feature and the plain text fallback

    private func spFeature(_ name: String, value: Int32) -> Data {
        var bytes: [UInt8] = [60, UInt8(ascii: "S"), 0, 0]
        let raw = UInt32(bitPattern: value)
        bytes += [UInt8(raw >> 24), UInt8((raw >> 16) & 0xff), UInt8((raw >> 8) & 0xff), UInt8(raw & 0xff)]
        let nameBytes = Array(name.utf8)
        bytes += nameBytes + [UInt8](repeating: 0, count: 80 - nameBytes.count)
        return Data(bytes)
    }

    func testServerFeatureValues_RecordRcDistress() {
        XCTAssertFalse(analyzer.serverOffersRCDistress)
        analyzer.analyze(incomingData: spFeature("RC_DISTRESS", value: -1))
        XCTAssertEqual(analyzer.serverFeatureValues["RC_DISTRESS"], -1)
        XCTAssertFalse(analyzer.serverOffersRCDistress)
        analyzer.analyze(incomingData: spFeature("RC_DISTRESS", value: 1))
        XCTAssertEqual(analyzer.serverFeatureValues["RC_DISTRESS"], 1)
        XCTAssertTrue(analyzer.serverOffersRCDistress)
        XCTAssertEqual(analyzerDelegate.serverFeatures, ["RC_DISTRESS", "RC_DISTRESS"], "names as before")
    }

    func testPlainText_IsTheDefaultTextWithoutMyAddress() {
        let call = Distress(type: .carrying, sender: 1, armies: 3)
        XCTAssertEqual(universe.defaultText(for: call), " F1->FED Carrying 3 armies.")
        XCTAssertEqual(universe.plainText(for: call), "Carrying 3 armies.")
        let data = MakePacket.cpMessage(message: universe.plainText(for: call)!, team: .federation, individual: 0)
        XCTAssertEqual(Array(data.prefix(4)), [1, MessageFlag.team, 1, 0])
    }

    // MARK: - Filling a call from the universe

    func testMakeDistress_FillsTheShipStateFromMe() {
        universe.shipinfo(shipType: .cruiser, torpSpeed: 12, phaserRange: 100, maxSpeed: 9, maxFuel: 10000,
                          maxShield: 100, maxDamage: 100, maxWpnTmp: 1000, maxEngTmp: 1000, width: 20,
                          height: 20, maxArmies: 10)
        universe.updateMe(myPlayerId: 1, hostile: 0, war: 0, armies: 3, tractor: 0, flags: 0x61,
                          damage: 40, shieldStrength: 60, fuel: 6300, engineTemp: 120, weaponsTemp: 1500,
                          whyDead: 0, whoDead: 0)
        drainMainQueue()

        let call = universe.makeDistress(.take, nearestPlanet: 3, targetPlanet: 31)
        XCTAssertEqual(call, Distress(type: .take, sender: 1, damage: 40, shields: 60, fuel: 63,
                                      engineTemp: 12, weaponTemp: 127, armies: 3,
                                      status: [.shields, .weaponsOverheated, .enginesOverheated],
                                      nearestPlanet: 3, targetPlanet: 31))
    }

    func testMakeDistress_NeedsTheShipInfo() {
        XCTAssertNil(universe.makeDistress(.carrying))
    }

    func testDistressSenderAndLookup_FromTheUniverse() {
        let sender = universe.distressSender(slot: 1)
        XCTAssertEqual(sender, DistressSender(team: 1, name: "Twinky", shipType: 2))
        let lookup = universe.distressLookup
        XCTAssertEqual(lookup.planetName(31), "Cassiopia")
        XCTAssertEqual(lookup.planetOwner(31), 8)
        XCTAssertEqual(lookup.planetArmies(31, 1), 5)
        XCTAssertNil(lookup.planetArmies(1, 1), "FED has not scouted Rigel")
        XCTAssertEqual(lookup.planetArmies(1, 2), 9)
        XCTAssertEqual(lookup.playerTeam(7), 2)
        XCTAssertNil(lookup.planetName(99))
        XCTAssertNil(lookup.playerTeam(-1))
    }
}
