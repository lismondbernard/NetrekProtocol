//
//  PacketAnalyzerTests.swift
//  NetrekProtocolTests
//
//  Bytes in, universe out: PacketAnalyzer feeding its own Universe, and
//  reporting login progress to its delegate.
//

import XCTest
@testable import NetrekProtocol

final class RecordingAnalyzerDelegate: PacketAnalyzerDelegate {
    var gameState: GameState = .serverConnected
    var serverFeatures: [String] = []
    var states: [GameState] = []
    var receiveRequests = 0
    var outfitRefusals = 0
    var teamMasks: [UInt8] = []

    func newGameState(_ state: GameState) {
        states.append(state)
        gameState = state
    }
    func triggerReceive() { receiveRequests += 1 }
    func updateTeamEligibility(mask: UInt8) { teamMasks.append(mask) }
    func outfitRefused() { outfitRefusals += 1 }
}

final class PacketAnalyzerTests: XCTestCase {

    var universe: Universe!
    var delegate: RecordingAnalyzerDelegate!
    var analyzer: PacketAnalyzer!

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

    func testAnalyzer_UsesTheUniverseItWasGiven() {
        XCTAssertTrue(analyzer.universe === universe)
        XCTAssertFalse(analyzer.universe === Universe.universe)
    }

    func testSpYou_SetsMeAndReportsSlotFound() {
        analyzer.analyze(incomingData: PacketBuilder.spYou(playerId: 7))
        drainMainQueue()

        XCTAssertEqual(universe.me, 7)
        XCTAssertEqual(delegate.states, [.serverSlotFound])
        XCTAssertGreaterThan(delegate.receiveRequests, 0, "Should ask for more bytes")
    }

    func testSpPickok_AcceptedAndRefused() {
        analyzer.analyze(incomingData: PacketBuilder.spPickok(state: 1))
        analyzer.analyze(incomingData: PacketBuilder.spPickok(state: 0))

        XCTAssertEqual(delegate.states, [.gameActive])
        XCTAssertEqual(delegate.outfitRefusals, 1)
    }

    func testSpPlayer_MovesThePlayerInGameCoordinates() {
        analyzer.analyze(incomingData: PacketBuilder.spPlayer(playerId: 3, speed: 6, positionX: 25000, positionY: 75000))
        drainMainQueue()

        let player = universe.players[3]
        XCTAssertEqual(player.positionX, 2500)
        XCTAssertEqual(player.positionY, 2500, "Netrek y points down, game y points up")
        XCTAssertEqual(player.speed, 6)
    }

    func testSplitPacket_IsKeptUntilTheRestArrives() {
        let packet = PacketBuilder.spPlayer(playerId: 2, positionX: 10000, positionY: 90000)
        analyzer.analyze(incomingData: packet.prefix(5))
        analyzer.analyze(incomingData: packet.suffix(from: 5))
        drainMainQueue()

        XCTAssertEqual(universe.players[2].positionX, 1000)
        XCTAssertEqual(universe.players[2].positionY, 1000)
    }

    func testMessage_GoesThroughTheTextFilter() {
        analyzer.analyze(incomingData: PacketBuilder.spMessage(message: "Romulus fired a phaser"))
        drainMainQueue()
        XCTAssertEqual(universe.lastMessage, "Rome fired a laser")
    }

    func testMessage_IdentityFilterKeepsClassicNames() {
        analyzer = PacketAnalyzer(delegate: delegate, universe: universe, textFilter: { $0 })
        analyzer.analyze(incomingData: PacketBuilder.spMessage(message: "Romulus fired a phaser"))
        drainMainQueue()
        XCTAssertEqual(universe.lastMessage, "Romulus fired a phaser")
    }

    func testSpMask_ReportsTeamEligibility() {
        var data = Data(count: 4)
        data[0] = 19
        data[1] = 0x05
        analyzer.analyze(incomingData: data)
        drainMainQueue()
        XCTAssertEqual(delegate.teamMasks, [0x05])
    }
}
