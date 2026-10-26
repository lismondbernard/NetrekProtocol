//
//  PlayerFlagTests.swift
//  NetrekCoreTests
//
//  Unit tests for Player flag decoding.
//  Flags are a 32-bit field with 23+ individual bits.
//  Wrong decoding = broken shields, cloak, alerts, etc.
//

import XCTest
@testable import NetrekProtocol

final class PlayerFlagTests: XCTestCase {

    // MARK: - Flag Constants Verification

    func testPlayerFlag_Shield_Is0x0001() {
        XCTAssertEqual(Player.SHIELDFLAG, 0x0001)
        XCTAssertEqual(PlayerStatus.shield.rawValue, 0x0001)
    }

    func testPlayerFlag_Repair_Is0x0002() {
        XCTAssertEqual(Player.REPAIRFLAG, 0x0002)
        XCTAssertEqual(PlayerStatus.repair.rawValue, 0x0002)
    }

    func testPlayerFlag_Bomb_Is0x0004() {
        XCTAssertEqual(Player.BOMBFLAG, 0x0004)
        XCTAssertEqual(PlayerStatus.bomb.rawValue, 0x0004)
    }

    func testPlayerFlag_Orbit_Is0x0008() {
        XCTAssertEqual(Player.ORBITFLAG, 0x0008)
        XCTAssertEqual(PlayerStatus.orbit.rawValue, 0x0008)
    }

    func testPlayerFlag_Cloak_Is0x0010() {
        XCTAssertEqual(Player.CLOAKFLAG, 0x0010)
        XCTAssertEqual(PlayerStatus.cloak.rawValue, 0x0010)
    }

    func testPlayerFlag_WeaponTemp_Is0x0020() {
        XCTAssertEqual(Player.WEPFLAG, 0x0020)
        XCTAssertEqual(PlayerStatus.weaponTemp.rawValue, 0x0020)
    }

    func testPlayerFlag_EngineTemp_Is0x0040() {
        XCTAssertEqual(Player.ENGFLAG, 0x0040)
        XCTAssertEqual(PlayerStatus.engineTemp.rawValue, 0x0040)
    }

    func testPlayerFlag_BeamUp_Is0x0100() {
        XCTAssertEqual(Player.BEAMUPFLAG, 0x0100)
        XCTAssertEqual(PlayerStatus.beamup.rawValue, 0x0100)
    }

    func testPlayerFlag_BeamDown_Is0x0200() {
        XCTAssertEqual(Player.BEAMDOWNFLAG, 0x0200)
        XCTAssertEqual(PlayerStatus.beamdown.rawValue, 0x0200)
    }

    func testPlayerFlag_SelfDestruct_Is0x0400() {
        XCTAssertEqual(Player.SELFDESTRUCTFLAG, 0x0400)
        XCTAssertEqual(PlayerStatus.selfDestruct.rawValue, 0x0400)
    }

    func testPlayerFlag_GreenAlert_Is0x0800() {
        XCTAssertEqual(Player.GREENFLAG, 0x0800)
        XCTAssertEqual(PlayerStatus.greenAlert.rawValue, 0x0800)
    }

    func testPlayerFlag_YellowAlert_Is0x1000() {
        XCTAssertEqual(Player.YELLOWFLAG, 0x1000)
        XCTAssertEqual(PlayerStatus.yellowAlert.rawValue, 0x1000)
    }

    func testPlayerFlag_RedAlert_Is0x2000() {
        XCTAssertEqual(Player.REDFLAG, 0x2000)
        XCTAssertEqual(PlayerStatus.redAlert.rawValue, 0x2000)
    }

    func testPlayerFlag_PlayerLock_Is0x4000() {
        XCTAssertEqual(Player.PLAYERLOCKFLAG, 0x4000)
        XCTAssertEqual(PlayerStatus.playerLock.rawValue, 0x4000)
    }

    func testPlayerFlag_PlanetLock_Is0x8000() {
        XCTAssertEqual(Player.PLANETLOCKFLAG, 0x8000)
        XCTAssertEqual(PlayerStatus.planetLock.rawValue, 0x8000)
    }

    func testPlayerFlag_WarSet_Is0x10000() {
        XCTAssertEqual(Player.WARSETFLAG, 0x10000)
    }

    func testPlayerFlag_Dock_Is0x80000() {
        XCTAssertEqual(Player.DOCKFLAG, 0x80000)
        XCTAssertEqual(PlayerStatus.dock.rawValue, 0x80000)
    }

    func testPlayerFlag_Refit_Is0x100000() {
        XCTAssertEqual(Player.REFITFLAG, 0x100000)
        XCTAssertEqual(PlayerStatus.refit.rawValue, 0x100000)
    }

    func testPlayerFlag_Refitting_Is0x200000() {
        XCTAssertEqual(Player.REFITTINGFLAG, 0x200000)
        XCTAssertEqual(PlayerStatus.refitting.rawValue, 0x200000)
    }

    func testPlayerFlag_Tractor_Is0x400000() {
        XCTAssertEqual(Player.TRACTORFLAG, 0x400000)
        XCTAssertEqual(PlayerStatus.tractor.rawValue, 0x400000)
    }

    func testPlayerFlag_Pressor_Is0x800000() {
        XCTAssertEqual(Player.PRESSORFLAG, 0x800000)
        XCTAssertEqual(PlayerStatus.pressor.rawValue, 0x800000)
    }

    func testPlayerFlag_DockOk_Is0x1000000() {
        XCTAssertEqual(Player.DOCKOKFLAG, 0x1000000)
        XCTAssertEqual(PlayerStatus.dockOk.rawValue, 0x1000000)
    }

    // MARK: - Flag Decoding Tests

    func testFlagDecoding_ShieldOnly() {
        let flags: UInt32 = 0x0001
        XCTAssertTrue(flags & PlayerStatus.shield.rawValue != 0, "Shield bit should be set")
        XCTAssertFalse(flags & PlayerStatus.cloak.rawValue != 0, "Cloak bit should not be set")
    }

    func testFlagDecoding_ShieldAndCloak() {
        let flags: UInt32 = 0x0011  // Shield (0x0001) + Cloak (0x0010)
        XCTAssertTrue(flags & PlayerStatus.shield.rawValue != 0, "Shield bit should be set")
        XCTAssertTrue(flags & PlayerStatus.cloak.rawValue != 0, "Cloak bit should be set")
        XCTAssertFalse(flags & PlayerStatus.repair.rawValue != 0, "Repair bit should not be set")
    }

    func testFlagDecoding_AlertConditions_Green() {
        let flags: UInt32 = 0x0800  // Green alert
        XCTAssertTrue(flags & PlayerStatus.greenAlert.rawValue != 0, "Green alert should be set")
        XCTAssertFalse(flags & PlayerStatus.yellowAlert.rawValue != 0, "Yellow alert should not be set")
        XCTAssertFalse(flags & PlayerStatus.redAlert.rawValue != 0, "Red alert should not be set")
    }

    func testFlagDecoding_AlertConditions_Yellow() {
        let flags: UInt32 = 0x1000  // Yellow alert
        XCTAssertFalse(flags & PlayerStatus.greenAlert.rawValue != 0, "Green alert should not be set")
        XCTAssertTrue(flags & PlayerStatus.yellowAlert.rawValue != 0, "Yellow alert should be set")
        XCTAssertFalse(flags & PlayerStatus.redAlert.rawValue != 0, "Red alert should not be set")
    }

    func testFlagDecoding_AlertConditions_Red() {
        let flags: UInt32 = 0x2000  // Red alert
        XCTAssertFalse(flags & PlayerStatus.greenAlert.rawValue != 0, "Green alert should not be set")
        XCTAssertFalse(flags & PlayerStatus.yellowAlert.rawValue != 0, "Yellow alert should not be set")
        XCTAssertTrue(flags & PlayerStatus.redAlert.rawValue != 0, "Red alert should be set")
    }

    func testFlagDecoding_ComplexCombination() {
        // Shields up, in orbit, player locked, green alert
        let flags: UInt32 = 0x0001 | 0x0008 | 0x4000 | 0x0800
        XCTAssertTrue(flags & PlayerStatus.shield.rawValue != 0, "Shield should be set")
        XCTAssertTrue(flags & PlayerStatus.orbit.rawValue != 0, "Orbit should be set")
        XCTAssertTrue(flags & PlayerStatus.playerLock.rawValue != 0, "PlayerLock should be set")
        XCTAssertTrue(flags & PlayerStatus.greenAlert.rawValue != 0, "Green alert should be set")
        XCTAssertFalse(flags & PlayerStatus.cloak.rawValue != 0, "Cloak should not be set")
        XCTAssertFalse(flags & PlayerStatus.bomb.rawValue != 0, "Bomb should not be set")
    }

    func testFlagDecoding_AllFlagsZero() {
        let flags: UInt32 = 0
        for status in [PlayerStatus.shield, .repair, .bomb, .orbit, .cloak] {
            XCTAssertFalse(flags & status.rawValue != 0,
                          "\(status) should not be set when flags are 0")
        }
    }

    func testFlagDecoding_TractorPressor() {
        // Tractor and pressor are mutually exclusive in practice
        // but we should decode them independently

        let tractorFlags: UInt32 = 0x400000
        XCTAssertTrue(tractorFlags & PlayerStatus.tractor.rawValue != 0, "Tractor should be set")
        XCTAssertFalse(tractorFlags & PlayerStatus.pressor.rawValue != 0, "Pressor should not be set")

        let pressorFlags: UInt32 = 0x800000
        XCTAssertFalse(pressorFlags & PlayerStatus.tractor.rawValue != 0, "Tractor should not be set")
        XCTAssertTrue(pressorFlags & PlayerStatus.pressor.rawValue != 0, "Pressor should be set")
    }

    // MARK: - Slot Status Tests

    func testSlotStatus_Free() {
        XCTAssertEqual(SlotStatus.free.rawValue, 0)
    }

    func testSlotStatus_Outfit() {
        XCTAssertEqual(SlotStatus.outfit.rawValue, 1)
    }

    func testSlotStatus_Alive() {
        XCTAssertEqual(SlotStatus.alive.rawValue, 2)
    }

    func testSlotStatus_Explode() {
        XCTAssertEqual(SlotStatus.explode.rawValue, 3)
    }

    func testSlotStatus_Dead() {
        XCTAssertEqual(SlotStatus.dead.rawValue, 4)
    }

    func testSlotStatus_Observe() {
        XCTAssertEqual(SlotStatus.observe.rawValue, 5)
    }

    // MARK: - Team Raw Values (for war/hostile bit masks)

    func testTeam_Independent_Is0() {
        XCTAssertEqual(Team.independent.rawValue, 0)
    }

    func testTeam_Federation_Is1() {
        XCTAssertEqual(Team.federation.rawValue, 1)
    }

    func testTeam_Roman_Is2() {
        XCTAssertEqual(Team.roman.rawValue, 2)
    }

    func testTeam_Kazari_Is4() {
        XCTAssertEqual(Team.kazari.rawValue, 4)
    }

    func testTeam_Orion_Is8() {
        XCTAssertEqual(Team.orion.rawValue, 8)
    }

    func testTeam_Ogg_Is15() {
        XCTAssertEqual(Team.ogg.rawValue, 15)
    }

    // MARK: - War/Hostile Mask Decoding

    func testWarMask_Federation() {
        let warMask: UInt32 = 1  // Federation
        XCTAssertTrue(UInt32(Team.federation.rawValue) & warMask != 0)
        XCTAssertFalse(UInt32(Team.roman.rawValue) & warMask != 0)
    }

    func testWarMask_Roman() {
        let warMask: UInt32 = 2  // Roman
        XCTAssertFalse(UInt32(Team.federation.rawValue) & warMask != 0)
        XCTAssertTrue(UInt32(Team.roman.rawValue) & warMask != 0)
    }

    func testWarMask_MultipleTeams() {
        let warMask: UInt32 = 1 | 4  // Federation + Kazari
        XCTAssertTrue(UInt32(Team.federation.rawValue) & warMask != 0)
        XCTAssertFalse(UInt32(Team.roman.rawValue) & warMask != 0)
        XCTAssertTrue(UInt32(Team.kazari.rawValue) & warMask != 0)
        XCTAssertFalse(UInt32(Team.orion.rawValue) & warMask != 0)
    }

    func testWarMask_AllTeams() {
        let warMask: UInt32 = 1 | 2 | 4 | 8  // All playable teams
        XCTAssertTrue(UInt32(Team.federation.rawValue) & warMask != 0)
        XCTAssertTrue(UInt32(Team.roman.rawValue) & warMask != 0)
        XCTAssertTrue(UInt32(Team.kazari.rawValue) & warMask != 0)
        XCTAssertTrue(UInt32(Team.orion.rawValue) & warMask != 0)
    }

    // MARK: - Direction Wrapping Tests
    //
    // Critical: When direction crosses 0/2π boundary, animation should be smooth
    // The bug: If old=359° and new=1°, naive subtraction gives -358° instead of +2°

    func testDirectionWrapping_Logic() {
        // Test the wrapping logic used in Player.update()
        let oldDirection = 6.0  // Just below 2π (~344°)
        var newDirection = 0.2  // Just above 0 (~11°)

        // Apply the wrapping logic from Player.update()
        while oldDirection > newDirection + Double.pi {
            newDirection += 2 * Double.pi
        }
        while oldDirection < newDirection - Double.pi {
            newDirection -= 2 * Double.pi
        }

        // Now the difference should be small (crossing 0/2π boundary)
        let diff = abs(newDirection - oldDirection)
        XCTAssertLessThan(diff, Double.pi,
            "Direction wrapping should keep difference < π, got \(diff)")
    }

    func testDirectionWrapping_OtherDirection() {
        // Test wrapping in the other direction
        let oldDirection = 0.2  // Just above 0 (~11°)
        var newDirection = 6.0  // Just below 2π (~344°)

        // Apply the wrapping logic
        while oldDirection > newDirection + Double.pi {
            newDirection += 2 * Double.pi
        }
        while oldDirection < newDirection - Double.pi {
            newDirection -= 2 * Double.pi
        }

        let diff = abs(newDirection - oldDirection)
        XCTAssertLessThan(diff, Double.pi,
            "Direction wrapping should keep difference < π, got \(diff)")
    }

    func testDirectionWrapping_NoWrapNeeded() {
        // When directions are close, no wrapping should occur
        let oldDirection = 1.5
        var newDirection = 1.7

        let originalNew = newDirection

        while oldDirection > newDirection + Double.pi {
            newDirection += 2 * Double.pi
        }
        while oldDirection < newDirection - Double.pi {
            newDirection -= 2 * Double.pi
        }

        XCTAssertEqual(newDirection, originalNew, accuracy: 0.001,
            "Close directions should not be wrapped")
    }
}
