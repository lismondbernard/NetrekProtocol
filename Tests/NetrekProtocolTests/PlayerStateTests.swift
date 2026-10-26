//
//  PlayerStateTests.swift
//  NetrekCoreTests
//
//  Tests for Player model state updates.
//  These tests verify that Player objects correctly update from packet data.
//

import XCTest
@testable import NetrekProtocol

final class PlayerStateTests: XCTestCase {

    var player: Player!

    override func setUp() {
        super.setUp()
        player = Player(playerId: 5)
    }

    override func tearDown() {
        player = nil
        super.tearDown()
    }

    // MARK: - Position Update Tests (from SP_PLAYER packet type 4)

    func testPlayerUpdate_PositionUpdates() {
        let expectation = XCTestExpectation(description: "Position update")
        player.update(directionNetrek: 0, speed: 5, positionX: 3000, positionY: 7000)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.positionX, 3000, "Position X should update")
            XCTAssertEqual(self.player.positionY, 7000, "Position Y should update")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlayerUpdate_SpeedUpdates() {
        player.update(directionNetrek: 64, speed: 9, positionX: 5000, positionY: 5000)

        XCTAssertEqual(player.speed, 9, "Speed should update to 9")
    }

    func testPlayerUpdate_DirectionUpdates() {
        player.update(directionNetrek: 128, speed: 5, positionX: 5000, positionY: 5000)

        // Direction wrapping logic: starting from 0, direction 128 gets wrapped
        // Netrek 128 = South = 3π/2 radians normally
        // But with wrapping from oldDirection 0: 3π/2 - 2π = -π/2
        let expectedDirection = -Double.pi / 2.0
        XCTAssertEqual(player.direction, expectedDirection, accuracy: 0.01,
                       "Direction should wrap to -π/2 when transitioning from 0")
    }

    // MARK: - Direction Wrapping Tests (Critical for smooth animation)

    func testPlayerUpdate_DirectionWrapping_359To1() {
        // This is the critical bug: going from 359° to 1° should not spin backwards
        // Set initial direction near 360° (6.28 radians ~= 359.8°)
        player.update(directionNetrek: 255, speed: 5, positionX: 5000, positionY: 5000)
        let oldDirection = player.direction

        // Update to direction near 0° (0.1 radians ~= 5.7°)
        player.update(directionNetrek: 1, speed: 5, positionX: 5000, positionY: 5000)
        let newDirection = player.direction

        // The new direction should be adjusted by +2π to avoid backwards spin
        // So it should be > oldDirection (e.g., 6.28 → 6.38 instead of 6.28 → 0.1)
        let diff = abs(newDirection - oldDirection)
        XCTAssertLessThan(diff, Double.pi,
                         "Direction change should be < π radians to avoid backwards spin. Old: \(oldDirection), New: \(newDirection), Diff: \(diff)")
    }

    func testPlayerUpdate_DirectionWrapping_1To359() {
        // Going from 1° to 359° should not spin forward through 360°
        player.update(directionNetrek: 1, speed: 5, positionX: 5000, positionY: 5000)
        let oldDirection = player.direction

        player.update(directionNetrek: 255, speed: 5, positionX: 5000, positionY: 5000)
        let newDirection = player.direction

        // The new direction should be adjusted by -2π
        let diff = abs(newDirection - oldDirection)
        XCTAssertLessThan(diff, Double.pi,
                         "Direction change should be < π radians")
    }

    func testPlayerUpdate_DirectionNoWrapping_90To180() {
        // Normal direction changes should not be affected
        player.update(directionNetrek: 64, speed: 5, positionX: 5000, positionY: 5000)
        let oldDirection = player.direction

        player.update(directionNetrek: 128, speed: 5, positionX: 5000, positionY: 5000)
        let newDirection = player.direction

        // Should be a normal π/2 change
        let diff = abs(newDirection - oldDirection)
        XCTAssertLessThan(diff, Double.pi,
                         "Normal direction changes should work correctly")
    }

    // MARK: - Flags Update Tests (from SP_FLAGS packet type 18)

    func testPlayerFlagsUpdate_Shields() {
        let expectation = XCTestExpectation(description: "Flags update")
        player.update(tractor: 0, flags: 0x0001)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.player.shieldsUp, "Shields should be up when flag 0x0001 is set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlayerFlagsUpdate_Cloak() {
        let expectation = XCTestExpectation(description: "Flags update")
        player.update(tractor: 0, flags: 0x0010)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.player.cloak, "Cloak should be active when flag 0x0010 is set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlayerFlagsUpdate_ShieldsDown() {
        let expectation = XCTestExpectation(description: "Flags update")
        // First set shields up
        player.update(tractor: 0, flags: 0x0001)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.player.shieldsUp)

            // Then turn them off
            self.player.update(tractor: 0, flags: 0x0000)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertFalse(self.player.shieldsUp, "Shields should be down when flag is cleared")
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlayerFlagsUpdate_Tractor() {
        // Note: update(tractor:flags:) sets tractor value synchronously
        // but tractorFlag is only set in updateMe(), not in update(tractor:flags:)
        player.update(tractor: 50, flags: 0x400000)

        XCTAssertEqual(player.tractor, 50, "Tractor value should update synchronously")
        // The tractor flag (0x400000) is set in updateMe(), not update(tractor:flags:)
        // So we test that flags are stored
        XCTAssertEqual(player.flags, 0x400000, "Flags should be stored")
    }

    // MARK: - Slot Status Update Tests (from SP_PSTATUS packet type 20)

    func testSlotStatus_Free() {
        let expectation = XCTestExpectation(description: "Status update")
        player.update(sp_pstatus: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.slotStatus, .free, "Status should be free")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSlotStatus_Outfit() {
        let expectation = XCTestExpectation(description: "Status update")
        player.update(sp_pstatus: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.slotStatus, .outfit, "Status should be outfit")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSlotStatus_Alive() {
        let expectation = XCTestExpectation(description: "Status update")
        player.update(sp_pstatus: 2)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.slotStatus, .alive, "Status should be alive")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSlotStatus_Explode() {
        let expectation = XCTestExpectation(description: "Status update")
        player.update(sp_pstatus: 3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.slotStatus, .explode, "Status should be explode")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSlotStatus_Dead() {
        let expectation = XCTestExpectation(description: "Status update")
        player.update(sp_pstatus: 4)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.slotStatus, .dead, "Status should be dead")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testSlotStatus_Observe() {
        let expectation = XCTestExpectation(description: "Status update")
        player.update(sp_pstatus: 5)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.player.slotStatus, .observe, "Status should be observe")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Team Update Tests

    func testPlayerUpdate_TeamFederation() {
        player.update(team: 1)

        XCTAssertEqual(player.team, .federation, "Team should be Federation")
    }

    func testPlayerUpdate_TeamRoman() {
        player.update(team: 2)

        XCTAssertEqual(player.team, .roman, "Team should be Roman")
    }

    func testPlayerUpdate_TeamKazari() {
        player.update(team: 4)

        XCTAssertEqual(player.team, .kazari, "Team should be Kazari")
    }

    func testPlayerUpdate_TeamOrion() {
        player.update(team: 8)

        XCTAssertEqual(player.team, .orion, "Team should be Orion")
    }

    // MARK: - Ship Type Update Tests

    func testPlayerUpdate_ShipScout() {
        player.update(shipType: 0)

        XCTAssertEqual(player.ship, .scout, "Ship should be Scout")
    }

    func testPlayerUpdate_ShipDestroyer() {
        player.update(shipType: 1)

        XCTAssertEqual(player.ship, .destroyer, "Ship should be Destroyer")
    }

    func testPlayerUpdate_ShipCruiser() {
        player.update(shipType: 2)

        XCTAssertEqual(player.ship, .cruiser, "Ship should be Cruiser")
    }

    func testPlayerUpdate_ShipBattleship() {
        player.update(shipType: 3)

        XCTAssertEqual(player.ship, .battleship, "Ship should be Battleship")
    }

    // MARK: - War/Hostile Bitmask Tests

    func testPlayerUpdate_WarBitmask() {
        // War with Federation (1) and Roman (2) = 0x03
        player.update(war: 0x03, hostile: 0x00)

        XCTAssertTrue(player.war[.federation] ?? false, "Should be at war with Federation")
        XCTAssertTrue(player.war[.roman] ?? false, "Should be at war with Roman")
        XCTAssertFalse(player.war[.kazari] ?? true, "Should not be at war with Kazari")
        XCTAssertFalse(player.war[.orion] ?? true, "Should not be at war with Orion")
    }

    func testPlayerUpdate_HostileBitmask() {
        // Hostile to Kazari (4) and Orion (8) = 0x0C
        player.update(war: 0x00, hostile: 0x0C)

        XCTAssertFalse(player.hostile[.federation] ?? true, "Should not be hostile to Federation")
        XCTAssertFalse(player.hostile[.roman] ?? true, "Should not be hostile to Roman")
        XCTAssertTrue(player.hostile[.kazari] ?? false, "Should be hostile to Kazari")
        XCTAssertTrue(player.hostile[.orion] ?? false, "Should be hostile to Orion")
    }

    // MARK: - Player Info Tests

    func testPlayerUpdate_NameAndRank() {
        player.update(rank: 3, name: "Kirk", login: "jkirk")

        XCTAssertEqual(player.name, "Kirk", "Name should update")
        XCTAssertEqual(player.login, "jkirk", "Login should update")
        // Rank 3 is actually Commander, not Captain
        // Looking at Rank enum: 0=ensign, 1=lieutenant, 2=ltcmdr, 3=commander, 4=captain
        XCTAssertEqual(player.rank, .commander, "Rank should be Commander (3)")
    }

    func testPlayerUpdate_Kills() {
        player.update(kills: 12.5)

        XCTAssertEqual(player.kills, 12.5, "Kills should update")
    }
}
