//
//  PlayerLoginTests.swift
//  NetrekProtocolTests
//
//  SP_PL_LOGIN (type 24): a player's name, host and login reach the
//  player, in the order servers send them, and don't outlive the server.
//

import XCTest
@testable import NetrekProtocol

final class PlayerLoginTests: XCTestCase {

    var universe: Universe!
    var analyzer: PacketAnalyzer!
    var delegate: RecordingAnalyzerDelegate!

    override func setUp() {
        super.setUp()
        universe = Universe()
        delegate = RecordingAnalyzerDelegate()
        analyzer = PacketAnalyzer(delegate: delegate, universe: universe)
    }

    override func tearDown() {
        analyzer = nil
        delegate = nil
        universe = nil
        super.tearDown()
    }

    private func drainMainQueue() {
        let expectation = XCTestExpectation(description: "main queue")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlLogin_SetsNameHostAndLogin() {
        analyzer.analyze(incomingData: PacketBuilder.spPlLogin(playerId: 3, rank: 5, name: "chicksDigRank",
                                                               monitor: "172.16.0.9", login: "jimv"))
        let player = universe.players[3]
        XCTAssertEqual(player.name, "chicksDigRank")
        XCTAssertEqual(player.monitor, "172.16.0.9")
        XCTAssertEqual(player.login, "jimv")
        XCTAssertEqual(player.rank, .fleetCapt)
    }

    func testPlLogin_BeforeTheSlotIsInUse_IsKept() {
        // Vanilla servers send each slot's SP_PL_LOGIN, then its SP_PSTATUS.
        var burst = Data()
        burst += PacketBuilder.spPlLogin(playerId: 0, name: "Eradicator", monitor: "10.0.0.1", login: "Pre_T_Robot!")
        burst += PacketBuilder.spPstatus(playerId: 0, status: 2)
        burst += PacketBuilder.spPlLogin(playerId: 31, name: "Kathy", monitor: "Nowhere", login: "Robot")
        burst += PacketBuilder.spPstatus(playerId: 31, status: 1)
        analyzer.analyze(incomingData: burst)
        drainMainQueue()

        XCTAssertEqual(universe.players[0].name, "Eradicator")
        XCTAssertEqual(universe.players[0].slotStatus, .alive)
        XCTAssertEqual(universe.players[31].name, "Kathy")
        XCTAssertEqual(universe.players[31].login, "Robot")
    }

    func testPlLogin_AfterTheSlotIsInUse_IsKept() {
        analyzer.analyze(incomingData: PacketBuilder.spPstatus(playerId: 4, status: 2))
        drainMainQueue()
        analyzer.analyze(incomingData: PacketBuilder.spPlLogin(playerId: 4, name: "Smasher", login: "Pre_T_Robot!"))
        XCTAssertEqual(universe.players[4].name, "Smasher")
    }

    func testPlLogin_SplitAcrossReads_IsKept() {
        let packet = PacketBuilder.spPlLogin(playerId: 2, name: "Demoralizer", login: "Pre_T_Robot!")
        analyzer.analyze(incomingData: packet.prefix(10))
        analyzer.analyze(incomingData: packet.suffix(from: 10))
        XCTAssertEqual(universe.players[2].name, "Demoralizer")
    }

    func testPlLogin_IgnoresBytesAfterTheEndOfEachName() {
        // C servers copy fixed 16-byte fields, so a shorter name can be
        // followed by leftovers of an older, longer one.
        var packet = PacketBuilder.spPlLogin(playerId: 5, name: "Bob", monitor: "host", login: "bob")
        packet[4 + 4] = 0xFF
        packet[4 + 5] = 0xFE
        packet[20 + 5] = 0xC3
        packet[36 + 4] = 0x80
        analyzer.analyze(incomingData: packet)
        XCTAssertEqual(universe.players[5].name, "Bob")
        XCTAssertEqual(universe.players[5].monitor, "host")
        XCTAssertEqual(universe.players[5].login, "bob")
    }

    func testPlLogin_AnEmptySlot_HasAnEmptyName() {
        analyzer.analyze(incomingData: PacketBuilder.spPlLogin(playerId: 9, name: "", monitor: "", login: ""))
        XCTAssertEqual(universe.players[9].name, "")
        XCTAssertEqual(universe.players[9].login, "")
    }

    func testReset_ForgetsTheLastServersNames() {
        analyzer.analyze(incomingData: PacketBuilder.spPlLogin(playerId: 1, name: "Decimator", monitor: "10.0.0.1",
                                                               login: "Pre_T_Robot!"))
        universe.reset()
        XCTAssertEqual(universe.players[1].name, "nobody")
        XCTAssertEqual(universe.players[1].login, "unknown")
        XCTAssertEqual(universe.players[1].monitor, "")
    }

    func testOlderUpdateCall_StillWorks() {
        universe.updatePlayer(playerId: 6, rank: 0, name: "Razer", login: "Pre_T_Robot!")
        XCTAssertEqual(universe.players[6].name, "Razer")
        XCTAssertEqual(universe.players[6].monitor, "")
    }
}
