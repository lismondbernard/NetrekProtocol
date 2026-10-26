//
//  WeaponStateTests.swift
//  NetrekCoreTests
//
//  Tests for Torpedo, Laser, and Plasma model state updates.
//  These tests verify weapon lifecycle and color determination.
//

import XCTest
@testable import NetrekProtocol

final class WeaponStateTests: XCTestCase {

    // MARK: - Torpedo Tests

    func testTorpedo_InitialState() {
        let torpedo = Torpedo(torpedoId: 50)

        XCTAssertEqual(torpedo.torpedoId, 50, "Torpedo ID should be set")
        XCTAssertEqual(torpedo.status, 0, "Initial status should be 0 (inactive)")
        XCTAssertEqual(torpedo.positionX, 0, "Initial position X should be 0")
        XCTAssertEqual(torpedo.positionY, 0, "Initial position Y should be 0")
    }

    func testTorpedo_StatusInactive() {
        let torpedo = Torpedo(torpedoId: 10)
        torpedo.update(war: 0x01, status: 0)

        XCTAssertEqual(torpedo.status, 0, "Status should be 0 (inactive)")
    }

    func testTorpedo_StatusActive() {
        let expectation = XCTestExpectation(description: "Status update")
        let torpedo = Torpedo(torpedoId: 10)
        torpedo.update(war: 0x01, status: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(torpedo.status, 1, "Status should be 1 (active)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTorpedo_StatusExploding() {
        let expectation = XCTestExpectation(description: "Status update")
        let torpedo = Torpedo(torpedoId: 10)
        torpedo.update(war: 0x01, status: 2)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(torpedo.status, 2, "Status should be 2 (exploding)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTorpedo_WarDeterminesColor_Hostile() {
        // Initialize Universe with a player
        let player = Universe.universe.players[0]
        player.update(team: 1)  // Federation
        Universe.universe.me = 0

        let torpedo = Torpedo(torpedoId: 20)
        // War mask 0x01 = hostile to Federation
        torpedo.update(war: 0x01, status: 1)

        // Wait for async update
        let expectation = XCTestExpectation(description: "Color update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Hostile to my team (Parallax draws it red)
            XCTAssertEqual(torpedo.war[.federation], true, "Torpedo should be hostile to Federation")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTorpedo_WarDeterminesColor_Friendly() {
        let player = Universe.universe.players[0]
        player.update(team: 1)  // Federation
        Universe.universe.me = 0

        let torpedo = Torpedo(torpedoId: 21)
        // War mask 0x02 = hostile to Roman (not Federation)
        torpedo.update(war: 0x02, status: 1)

        let expectation = XCTestExpectation(description: "Color update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Friendly to my team (Parallax draws it green)
            XCTAssertEqual(torpedo.war[.federation], false, "Torpedo should not be hostile to Federation")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTorpedo_PositionUpdate() {
        let torpedo = Torpedo(torpedoId: 15)
        let expectation = XCTestExpectation(description: "Position update")

        // First set status to active
        torpedo.update(war: 0x01, status: 1)

        // Wait for status update to complete, then update position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            torpedo.update(directionNetrek: 64, positionX: 3000, positionY: 7000)

            // Wait again for position update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertEqual(torpedo.positionX, 3000, "Position X should update")
                XCTAssertEqual(torpedo.positionY, 7000, "Position Y should update")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testTorpedo_PositionDoesNotUpdateWhenInactive() {
        let torpedo = Torpedo(torpedoId: 16)
        torpedo.update(war: 0x01, status: 0)  // Inactive
        torpedo.update(directionNetrek: 64, positionX: 3000, positionY: 7000)

        // Position should remain at default (0,0) when inactive
        XCTAssertEqual(torpedo.positionX, 0, "Position should not update when inactive")
        XCTAssertEqual(torpedo.positionY, 0, "Position should not update when inactive")
    }

    func testTorpedo_Reset() {
        let torpedo = Torpedo(torpedoId: 17)
        torpedo.update(war: 0x01, status: 1)
        torpedo.update(directionNetrek: 64, positionX: 3000, positionY: 7000)

        torpedo.reset()

        XCTAssertEqual(torpedo.status, 0, "Status should reset to 0")
        XCTAssertEqual(torpedo.positionX, 0, "Position X should reset to 0")
        XCTAssertEqual(torpedo.positionY, 0, "Position Y should reset to 0")
    }

    // MARK: - Laser Tests

    func testLaser_InitialState() {
        let laser = Laser(laserId: 5)

        XCTAssertEqual(laser.laserId, 5, "Laser ID should be set")
        XCTAssertEqual(laser.status, 0, "Initial status should be 0 (inactive)")
        XCTAssertEqual(laser.positionX, 0, "Initial position X should be 0")
        XCTAssertEqual(laser.positionY, 0, "Initial position Y should be 0")
    }

    func testLaser_StatusInactive() {
        let laser = Laser(laserId: 3)
        laser.update(laserId: 3, status: 0, directionNetrek: 0, positionX: 5000, positionY: 5000, target: 0)

        let expectation = XCTestExpectation(description: "Status update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(laser.status, 0, "Status should be 0 (inactive)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLaser_StatusHit() {
        let laser = Laser(laserId: 2)
        laser.update(laserId: 2, status: 1, directionNetrek: 64, positionX: 5000, positionY: 5000, target: 5)

        let expectation = XCTestExpectation(description: "Status update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(laser.status, 1, "Status should be 1 (hit)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLaser_StatusMiss() {
        let laser = Laser(laserId: 4)
        laser.update(laserId: 4, status: 2, directionNetrek: 128, positionX: 5000, positionY: 5000, target: 0)

        let expectation = XCTestExpectation(description: "Status update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(laser.status, 2, "Status should be 2 (miss)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLaser_StatusHitPlasma() {
        let laser = Laser(laserId: 6)
        laser.update(laserId: 6, status: 4, directionNetrek: 0, positionX: 5000, positionY: 5000, target: 10)

        let expectation = XCTestExpectation(description: "Status update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(laser.status, 4, "Status should be 4 (hit plasma)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLaser_DirectionUpdate() {
        let laser = Laser(laserId: 7)
        laser.update(laserId: 7, status: 2, directionNetrek: 192, positionX: 5000, positionY: 5000, target: 0)

        let expectation = XCTestExpectation(description: "Direction update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(laser.directionNetrek, 192, "Direction should update")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testLaser_Reset() {
        let laser = Laser(laserId: 8)
        laser.update(laserId: 8, status: 1, directionNetrek: 64, positionX: 3000, positionY: 7000, target: 5)

        laser.reset()

        XCTAssertEqual(laser.status, 0, "Status should reset to 0")
        XCTAssertEqual(laser.positionX, 0, "Position X should reset to 0")
        XCTAssertEqual(laser.positionY, 0, "Position Y should reset to 0")
    }

    // MARK: - Plasma Tests

    func testPlasma_InitialState() {
        let plasma = Plasma(plasmaId: 30)

        XCTAssertEqual(plasma.plasmaId, 30, "Plasma ID should be set")
        XCTAssertEqual(plasma.status, 0, "Initial status should be 0 (inactive)")
        XCTAssertEqual(plasma.positionX, 0, "Initial position X should be 0")
        XCTAssertEqual(plasma.positionY, 0, "Initial position Y should be 0")
    }

    func testPlasma_StatusActive() {
        let plasma = Plasma(plasmaId: 25)
        plasma.update(plasmaId: 25, war: 0x01, status: 1)

        let expectation = XCTestExpectation(description: "Status update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(plasma.status, 1, "Status should be 1 (active)")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlasma_WarDeterminesColor_Hostile() {
        let player = Universe.universe.players[0]
        player.update(team: 2)  // Roman
        Universe.universe.me = 0

        let plasma = Plasma(plasmaId: 26)
        // War mask 0x02 = hostile to Roman
        plasma.update(plasmaId: 26, war: 0x02, status: 1)

        let expectation = XCTestExpectation(description: "Color update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(plasma.war[.roman], true, "Plasma should be hostile to Roman")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlasma_WarDeterminesColor_Friendly() {
        let player = Universe.universe.players[0]
        player.update(team: 1)  // Federation
        Universe.universe.me = 0

        let plasma = Plasma(plasmaId: 27)
        // War mask 0x04 = hostile to Kazari (not Federation)
        plasma.update(plasmaId: 27, war: 0x04, status: 1)

        let expectation = XCTestExpectation(description: "Color update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(plasma.war[.federation], false, "Plasma should not be hostile to Federation")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlasma_PositionUpdate() {
        let plasma = Plasma(plasmaId: 28)
        plasma.update(plasmaId: 28, war: 0x01, status: 1)
        plasma.update(positionX: 4000, positionY: 6000)

        let expectation = XCTestExpectation(description: "Position update")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(plasma.positionX, 4000, "Position X should update")
            XCTAssertEqual(plasma.positionY, 6000, "Position Y should update")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlasma_Reset() {
        let plasma = Plasma(plasmaId: 29)
        plasma.update(plasmaId: 29, war: 0x01, status: 1)
        plasma.update(positionX: 4000, positionY: 6000)

        plasma.reset()

        XCTAssertEqual(plasma.status, 0, "Status should reset to 0")
        XCTAssertEqual(plasma.positionX, 0, "Position X should reset to 0")
        XCTAssertEqual(plasma.positionY, 0, "Position Y should reset to 0")
    }
}
