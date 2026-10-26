//
//  UniverseEventTests.swift
//  NetrekProtocolTests
//
//  The events a Universe reports through UniverseEventDelegate.
//

import XCTest
@testable import NetrekProtocol

final class RecordingEventDelegate: UniverseEventDelegate {
    var readyForOutfit = 0
    var destroyed = 0
    var explosions: [(Int, Int)] = []
    var torpedoes: [(Int, Int)] = []
    var plasmas: [(Int, Int)] = []
    var lasers: [(Int, Int)] = []

    func universeServerReadyForOutfit(_ universe: Universe) { readyForOutfit += 1 }
    func universeMyShipDestroyed(_ universe: Universe) { destroyed += 1 }
    func universe(_ universe: Universe, playerExploded player: Player, distance: Int) {
        explosions.append((player.playerId, distance))
    }
    func universe(_ universe: Universe, torpedoNearby torpedo: Torpedo, distance: Int) {
        torpedoes.append((torpedo.torpedoId, distance))
    }
    func universe(_ universe: Universe, plasmaNearby plasma: Plasma, distance: Int) {
        plasmas.append((plasma.plasmaId, distance))
    }
    func universe(_ universe: Universe, laserFired laser: Laser, distance: Int) {
        lasers.append((laser.laserId, distance))
    }
}

final class UniverseEventTests: XCTestCase {

    var universe: Universe!
    var events: RecordingEventDelegate!

    override func setUp() {
        super.setUp()
        universe = Universe()
        events = RecordingEventDelegate()
        universe.eventDelegate = events
    }

    override func tearDown() {
        universe = nil
        events = nil
        super.tearDown()
    }

    private func drainMainQueue() {
        // Two hops: some updates queue a second main-queue block.
        for _ in 0..<2 {
            let expectation = XCTestExpectation(description: "main queue")
            DispatchQueue.main.async { expectation.fulfill() }
            wait(for: [expectation], timeout: 1.0)
        }
    }

    /// Makes player `id` me, alive, at game position (x, y).
    private func makeMe(_ id: Int, x: Int, y: Int) {
        universe.updateMe(myPlayerId: id, hostile: 0, war: 0, armies: 0, tractor: 0, flags: 0, damage: 0,
                          shieldStrength: 100, fuel: 10000, engineTemp: 0, weaponsTemp: 0, whyDead: 0, whoDead: 0)
        universe.players[id].update(sp_pstatus: 2)
        drainMainQueue()
        universe.players[id].update(directionNetrek: 0, speed: 0, positionX: x, positionY: y)
        drainMainQueue()
    }

    func testEntities_PointBackToTheirUniverse() {
        XCTAssertTrue(universe.players[0].universe === universe)
        XCTAssertTrue(universe.planets[0].universe === universe)
        XCTAssertTrue(universe.torpedoes[0].universe === universe)
        XCTAssertTrue(universe.lasers[0].universe === universe)
        XCTAssertTrue(universe.plasmas[0].universe === universe)
    }

    func testOutfit_ReportsServerReady() {
        makeMe(4, x: 5000, y: 5000)
        universe.players[4].update(sp_pstatus: 1)
        drainMainQueue()
        XCTAssertEqual(events.readyForOutfit, 1)
    }

    func testMyShipExploding_ReportsDestroyed() {
        makeMe(4, x: 5000, y: 5000)
        universe.players[4].update(sp_pstatus: 3)
        drainMainQueue()
        XCTAssertEqual(events.destroyed, 1)
    }

    func testOtherShipExploding_ReportsDistanceFromMe() {
        makeMe(0, x: 5000, y: 5000)
        let other = universe.players[1]
        other.update(sp_pstatus: 2)
        drainMainQueue()
        other.update(directionNetrek: 0, speed: 0, positionX: 5300, positionY: 5100)
        drainMainQueue()
        other.update(sp_pstatus: 3)
        drainMainQueue()

        XCTAssertEqual(events.explosions.count, 1)
        XCTAssertEqual(events.explosions.first?.0, 1)
        XCTAssertEqual(events.explosions.first?.1, 400)
    }

    func testTorpedoNearby_ReportedOncePerLaunch() {
        makeMe(0, x: 5000, y: 5000)
        let torpedo = universe.torpedoes[10]
        torpedo.update(war: 0, status: 1)
        drainMainQueue()
        torpedo.update(directionNetrek: 0, positionX: 5010, positionY: 5000)
        drainMainQueue()
        torpedo.update(directionNetrek: 0, positionX: 5020, positionY: 5000)
        drainMainQueue()

        XCTAssertEqual(events.torpedoes.count, 1)
        XCTAssertEqual(events.torpedoes.first?.0, 10)
    }

    func testTorpedoFarAway_NotReported() {
        makeMe(0, x: 1000, y: 1000)
        let torpedo = universe.torpedoes[11]
        torpedo.update(war: 0, status: 1)
        drainMainQueue()
        torpedo.update(directionNetrek: 0, positionX: 9000, positionY: 9000)
        drainMainQueue()
        torpedo.update(directionNetrek: 0, positionX: 9000, positionY: 9000)
        drainMainQueue()

        XCTAssertTrue(events.torpedoes.isEmpty)
    }

    func testLaserFiredNearby_Reported() {
        makeMe(0, x: 5000, y: 5000)
        universe.updateLaser(laserId: 0, status: 2, directionNetrek: 64, positionX: 0, positionY: 0, target: 0)
        drainMainQueue()

        XCTAssertEqual(events.lasers.count, 1)
        XCTAssertEqual(events.lasers.first?.1, 0, "My own laser is at distance 0")
    }

    func testNoDelegate_IsFine() {
        universe.eventDelegate = nil
        makeMe(0, x: 5000, y: 5000)
        universe.updateLaser(laserId: 0, status: 2, directionNetrek: 64, positionX: 0, positionY: 0, target: 0)
        drainMainQueue()
        XCTAssertTrue(events.lasers.isEmpty)
    }
}
