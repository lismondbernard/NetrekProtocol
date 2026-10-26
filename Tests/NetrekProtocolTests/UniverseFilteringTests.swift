//
//  UniverseFilteringTests.swift
//  NetrekCoreTests
//
//  Tests for Universe filtering and visibility calculations.
//  These tests verify what the player sees on screen.
//

import XCTest
@testable import NetrekProtocol

final class UniverseFilteringTests: XCTestCase {

    var universe: Universe!

    override func setUp() {
        super.setUp()
        universe = Universe.universe

        // Set up a test player as "me"
        universe.me = 0
        let myPlayer = universe.players[0]
        myPlayer.update(team: 1)  // Federation
        myPlayer.update(sp_pstatus: 2)  // Alive
        myPlayer.update(directionNetrek: 0, speed: 5, positionX: 5000, positionY: 5000)

        // Set visual width to standard test value
        universe.visualWidth = 3000
    }

    override func tearDown() {
        // Clean up test data
        for i in 1..<universe.players.count {
            universe.players[i].update(sp_pstatus: 0)  // Set to free
        }
        universe = nil
        super.tearDown()
    }

    // MARK: - Visible Players Tests

    func testVisiblePlayers_InRange_Included() {
        let expectation = XCTestExpectation(description: "Player update")
        // Player within visual range (3000/2 = 1500)
        let player1 = universe.players[1]
        player1.update(sp_pstatus: 2)  // Alive
        player1.update(directionNetrek: 0, speed: 5, positionX: 5500, positionY: 5500)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let visible = self.universe.visiblePlayers
            XCTAssertTrue(visible.contains(where: { $0.playerId == 1 }),
                          "Player within range should be visible")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testVisiblePlayers_OutOfRange_Excluded() {
        // Player outside visual range
        let player2 = universe.players[2]
        player2.update(sp_pstatus: 2)  // Alive
        player2.update(directionNetrek: 0, speed: 5, positionX: 8000, positionY: 8000)

        let visible = universe.visiblePlayers

        XCTAssertFalse(visible.contains(where: { $0.playerId == 2 }),
                       "Player outside range should not be visible")
    }

    func testVisiblePlayers_OnBoundary_Included() {
        // Player exactly at boundary (1500 units away)
        let player3 = universe.players[3]
        player3.update(sp_pstatus: 2)  // Alive
        player3.update(directionNetrek: 0, speed: 5, positionX: 6500, positionY: 5000)

        let visible = universe.visiblePlayers

        // Boundary condition - depends on < vs <= in filter
        // Current implementation uses <, so boundary should not be included
        XCTAssertFalse(visible.contains(where: { $0.playerId == 3 }),
                       "Player exactly at boundary should not be visible (< not <=)")
    }

    func testVisiblePlayers_DeadPlayersExcluded() {
        let player4 = universe.players[4]
        player4.update(sp_pstatus: 4)  // Dead
        player4.update(directionNetrek: 0, speed: 5, positionX: 5100, positionY: 5100)

        let visible = universe.visiblePlayers

        XCTAssertFalse(visible.contains(where: { $0.playerId == 4 }),
                       "Dead players should not be visible")
    }

    // MARK: - Team Filtering Tests

    func testFederationPlayers_CountsCorrectly() {
        let expectation = XCTestExpectation(description: "Team update")
        let player5 = universe.players[5]
        player5.update(team: 1)  // Federation
        player5.update(sp_pstatus: 2)  // Alive

        let player6 = universe.players[6]
        player6.update(team: 2)  // Roman
        player6.update(sp_pstatus: 2)  // Alive

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let fedCount = self.universe.federationPlayers
            XCTAssertEqual(fedCount, 2, "Should count 2 Federation players (including me)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testRomanPlayers_CountsCorrectly() {
        let expectation = XCTestExpectation(description: "Team update")
        let player7 = universe.players[7]
        player7.update(team: 2)  // Roman
        player7.update(sp_pstatus: 2)  // Alive

        let player8 = universe.players[8]
        player8.update(team: 2)  // Roman
        player8.update(sp_pstatus: 2)  // Alive

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let romanCount = self.universe.romanPlayers
            XCTAssertEqual(romanCount, 2, "Should count 2 Roman players")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testKazariPlayers_CountsCorrectly() {
        let expectation = XCTestExpectation(description: "Team update")
        let player9 = universe.players[9]
        player9.update(team: 4)  // Kazari
        player9.update(sp_pstatus: 2)  // Alive

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let kazariCount = self.universe.kazariPlayers
            XCTAssertEqual(kazariCount, 1, "Should count 1 Kazari player")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testOrionPlayers_CountsCorrectly() {
        let expectation = XCTestExpectation(description: "Team update")
        let player10 = universe.players[10]
        player10.update(team: 8)  // Orion
        player10.update(sp_pstatus: 2)  // Alive

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let orionCount = self.universe.orionPlayers
            XCTAssertEqual(orionCount, 1, "Should count 1 Orion player")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTeamCounts_ExcludeFreePlayers() {
        let player11 = universe.players[11]
        player11.update(team: 1)  // Federation
        player11.update(sp_pstatus: 0)  // Free (not in game)

        let fedCount = universe.federationPlayers

        // Should only count me (player 0), not the free slot
        XCTAssertEqual(fedCount, 1, "Free players should not be counted")
    }

    // MARK: - Alive/Exploding Filters

    func testAlivePlayers_OnlyAlive() {
        let expectation = XCTestExpectation(description: "Status update")
        let player12 = universe.players[12]
        player12.update(sp_pstatus: 2)  // Alive

        let player13 = universe.players[13]
        player13.update(sp_pstatus: 3)  // Exploding

        let player14 = universe.players[14]
        player14.update(sp_pstatus: 4)  // Dead

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let alive = self.universe.alivePlayers
            XCTAssertTrue(alive.contains(where: { $0.playerId == 12 }), "Alive player should be in list")
            XCTAssertFalse(alive.contains(where: { $0.playerId == 13 }), "Exploding player should not be in alive list")
            XCTAssertFalse(alive.contains(where: { $0.playerId == 14 }), "Dead player should not be in alive list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testExplodingPlayers_OnlyExploding() {
        let expectation = XCTestExpectation(description: "Status update")
        let player15 = universe.players[15]
        player15.update(sp_pstatus: 2)  // Alive

        let player16 = universe.players[16]
        player16.update(sp_pstatus: 3)  // Exploding

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let exploding = self.universe.explodingPlayers
            XCTAssertFalse(exploding.contains(where: { $0.playerId == 15 }), "Alive player should not be in exploding list")
            XCTAssertTrue(exploding.contains(where: { $0.playerId == 16 }), "Exploding player should be in list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Visible Torpedoes Tests

    func testVisibleTorpedoes_Active_InRange_Included() {
        let expectation = XCTestExpectation(description: "Torpedo update")
        let torpedo = universe.torpedoes[0]
        torpedo.update(war: 0x01, status: 1)  // Active

        // Wait for status update to complete before updating position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            torpedo.update(directionNetrek: 64, positionX: 5200, positionY: 5200)

            // Wait again for position update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let visibleTorps = self.universe.visibleTorpedoes
                XCTAssertTrue(visibleTorps.contains(where: { $0.torpedoId == 0 }),
                              "Active torpedo in range should be visible")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.5)
    }

    func testVisibleTorpedoes_Inactive_Excluded() {
        let torpedo = universe.torpedoes[1]
        torpedo.update(war: 0x01, status: 0)  // Inactive
        torpedo.update(directionNetrek: 64, positionX: 5200, positionY: 5200)

        let visibleTorps = universe.visibleTorpedoes

        XCTAssertFalse(visibleTorps.contains(where: { $0.torpedoId == 1 }),
                       "Inactive torpedo should not be visible")
    }

    func testVisibleTorpedoes_OutOfRange_Excluded() {
        let torpedo = universe.torpedoes[2]
        torpedo.update(war: 0x01, status: 1)  // Active
        torpedo.update(directionNetrek: 64, positionX: 9000, positionY: 9000)

        let visibleTorps = universe.visibleTorpedoes

        XCTAssertFalse(visibleTorps.contains(where: { $0.torpedoId == 2 }),
                       "Torpedo out of range should not be visible")
    }

    // MARK: - Visible Planets Tests

    func testVisiblePlanets_InRange_Included() {
        let expectation = XCTestExpectation(description: "Planet update")
        let planet = universe.planets[0]
        planet.update(name: "Earth", positionX: 5500, positionY: 5500)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let visiblePlanets = self.universe.visiblePlanets
            XCTAssertTrue(visiblePlanets.contains(where: { $0.planetId == 0 }),
                          "Planet in range should be visible")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testVisiblePlanets_OutOfRange_Excluded() {
        let planet = universe.planets[1]
        planet.update(name: "Mars", positionX: 9000, positionY: 9000)

        let visiblePlanets = universe.visiblePlanets

        XCTAssertFalse(visiblePlanets.contains(where: { $0.planetId == 1 }),
                       "Planet out of range should not be visible")
    }

    // MARK: - Friendly vs Enemy Player Filtering

    func testVisibleFriendlyPlayers_OnlyTeammates() {
        let expectation = XCTestExpectation(description: "Player update")
        // My team is Federation (1)
        let player17 = universe.players[17]
        player17.update(team: 1)  // Federation (friendly)
        player17.update(sp_pstatus: 2)  // Alive
        player17.update(directionNetrek: 0, speed: 5, positionX: 5300, positionY: 5300)

        let player18 = universe.players[18]
        player18.update(team: 2)  // Roman (enemy)
        player18.update(sp_pstatus: 2)  // Alive
        player18.update(directionNetrek: 0, speed: 5, positionX: 5400, positionY: 5400)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let friendlyPlayers = self.universe.visibleFriendlyPlayers
            XCTAssertTrue(friendlyPlayers.contains(where: { $0.playerId == 17 }),
                          "Friendly player should be in friendly list")
            XCTAssertFalse(friendlyPlayers.contains(where: { $0.playerId == 18 }),
                           "Enemy player should not be in friendly list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testVisibleEnemyPlayers_OnlyEnemies() {
        let expectation = XCTestExpectation(description: "Player update")
        // My team is Federation (1)
        let player19 = universe.players[19]
        player19.update(team: 1)  // Federation (friendly)
        player19.update(sp_pstatus: 2)  // Alive
        player19.update(directionNetrek: 0, speed: 5, positionX: 5300, positionY: 5300)

        let player20 = universe.players[20]
        player20.update(team: 4)  // Kazari (enemy)
        player20.update(sp_pstatus: 2)  // Alive
        player20.update(directionNetrek: 0, speed: 5, positionX: 5400, positionY: 5400)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let enemyPlayers = self.universe.visibleEnemyPlayers
            XCTAssertFalse(enemyPlayers.contains(where: { $0.playerId == 19 }),
                           "Friendly player should not be in enemy list")
            XCTAssertTrue(enemyPlayers.contains(where: { $0.playerId == 20 }),
                          "Enemy player should be in enemy list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Active Weapons Filtering

    func testActiveTorpedoes_OnlyStatus1() {
        let expectation = XCTestExpectation(description: "Torpedo update")
        let torp1 = universe.torpedoes[10]
        torp1.update(war: 0x01, status: 0)  // Inactive

        let torp2 = universe.torpedoes[11]
        torp2.update(war: 0x01, status: 1)  // Active

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            let activeTorps = self.universe.activeTorpedoes
            XCTAssertFalse(activeTorps.contains(where: { $0.torpedoId == 10 }),
                           "Inactive torpedo should not be in active list")
            XCTAssertTrue(activeTorps.contains(where: { $0.torpedoId == 11 }),
                          "Active torpedo should be in active list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testActiveLasers_NonZeroStatus() {
        let laser1 = universe.lasers[0]
        laser1.update(laserId: 0, status: 0, directionNetrek: 0, positionX: 5000, positionY: 5000, target: 0)

        let laser2 = universe.lasers[1]
        laser2.update(laserId: 1, status: 1, directionNetrek: 64, positionX: 5000, positionY: 5000, target: 5)

        // Wait for async updates
        let expectation = XCTestExpectation(description: "Laser update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let activeLasers = self.universe.activeLasers

            XCTAssertFalse(activeLasers.contains(where: { $0.laserId == 0 }),
                           "Inactive laser should not be in active list")
            XCTAssertTrue(activeLasers.contains(where: { $0.laserId == 1 }),
                          "Active laser should be in active list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testActivePlasmas_NonZeroStatus() {
        let plasma1 = universe.plasmas[0]
        plasma1.update(plasmaId: 0, war: 0x01, status: 0)  // Inactive

        let plasma2 = universe.plasmas[1]
        plasma2.update(plasmaId: 1, war: 0x01, status: 1)  // Active

        let expectation = XCTestExpectation(description: "Plasma update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let activePlasmas = self.universe.activePlasmas

            XCTAssertFalse(activePlasmas.contains(where: { $0.plasmaId == 0 }),
                           "Inactive plasma should not be in active list")
            XCTAssertTrue(activePlasmas.contains(where: { $0.plasmaId == 1 }),
                          "Active plasma should be in active list")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
