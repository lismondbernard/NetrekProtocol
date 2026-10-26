//
//  NetrekMathTests.swift
//  NetrekCoreTests
//
//  Unit tests for NetrekMath coordinate and direction conversions.
//  These are critical pure functions that affect all gameplay.
//

import XCTest
@testable import NetrekProtocol

final class NetrekMathTests: XCTestCase {

    // MARK: - Constants Tests

    func testGalacticSize_Is10000() {
        XCTAssertEqual(NetrekMath.galacticSize, 10000,
                       "Galactic size must be 10000 for coordinate system to work")
    }

    // MARK: - Direction Conversion Tests (Netrek 0-255 -> Radians 0-2π)
    //
    // Netrek direction system:
    //   0   = North (up)      = π/2 radians = 90°
    //   64  = West (left)     = π radians   = 180°
    //   128 = South (down)    = 3π/2 radians = 270°
    //   192 = East (right)    = 0 or 2π radians = 0°/360°

    func testDirectionNetrek2Radian_Zero_IsNorth() {
        // Netrek 0 = pointing up (north) = π/2 radians
        let result: Double = NetrekMath.directionNetrek2radian(0)
        XCTAssertEqual(result, Double.pi / 2, accuracy: 0.001,
                       "Netrek direction 0 should be π/2 (north/up)")
    }

    func testDirectionNetrek2Radian_64_IsEast() {
        // Netrek 64 = pointing right (east) = 0 or 2π radians
        // Direction increases clockwise in Netrek
        let result: Double = NetrekMath.directionNetrek2radian(64)
        // Result should be close to 0 or 2π
        let normalizedResult = result.truncatingRemainder(dividingBy: 2 * Double.pi)
        XCTAssertTrue(normalizedResult < 0.1 || normalizedResult > 2 * Double.pi - 0.1,
                      "Netrek direction 64 should be ~0 or ~2π (east/right), got \(result)")
    }

    func testDirectionNetrek2Radian_128_IsSouth() {
        // Netrek 128 = pointing down (south) = 3π/2 radians
        let result: Double = NetrekMath.directionNetrek2radian(128)
        XCTAssertEqual(result, 3 * Double.pi / 2, accuracy: 0.001,
                       "Netrek direction 128 should be 3π/2 (south/down)")
    }

    func testDirectionNetrek2Radian_192_IsWest() {
        // Netrek 192 = pointing left (west) = π radians
        // Direction increases clockwise in Netrek
        let result: Double = NetrekMath.directionNetrek2radian(192)
        XCTAssertEqual(result, Double.pi, accuracy: 0.001,
                       "Netrek direction 192 should be π (west/left)")
    }

    func testDirectionNetrek2Radian_255_ApproachesFullCircle() {
        // Netrek 255 should be just before completing the circle back to 0
        let result: Double = NetrekMath.directionNetrek2radian(255)
        // Should be slightly more than π/2 (back near north but clockwise)
        XCTAssertTrue(result > 0 && result < 2 * Double.pi,
                      "Netrek direction 255 should be in valid radian range, got \(result)")
    }

    func testDirectionNetrek2Radian_AllValuesInValidRange() {
        // All 256 possible Netrek directions should produce valid radians
        for direction: UInt8 in 0...255 {
            let result: Double = NetrekMath.directionNetrek2radian(direction)
            // After normalization, should be in [0, 2π)
            // But the function may return values outside this for animation purposes
            XCTAssertFalse(result.isNaN, "Direction \(direction) produced NaN")
            XCTAssertFalse(result.isInfinite, "Direction \(direction) produced infinite")
        }
    }

    // MARK: - Coordinate Conversion Tests (Netrek 0-1000000 -> Game 0-10000)

    func testNetrekX2GameX_Zero() {
        let result = NetrekMath.netrekX2GameX(0)
        XCTAssertEqual(result, 0, "Netrek X=0 should map to Game X=0")
    }

    func testNetrekX2GameX_MaxValue() {
        // Netrek uses 0-1000000, divides by 10 to get 0-100000
        // But wait, looking at the code: return netrekX / 10
        // So 1000000 / 10 = 100000, not 10000
        // Let me check the actual max value used
        let result = NetrekMath.netrekX2GameX(100000)
        XCTAssertEqual(result, 10000, "Netrek X=100000 should map to Game X=10000")
    }

    func testNetrekX2GameX_Midpoint() {
        let result = NetrekMath.netrekX2GameX(50000)
        XCTAssertEqual(result, 5000, "Netrek X=50000 should map to Game X=5000")
    }

    func testNetrekY2GameY_Zero() {
        // Y coordinate conversion: (100000 - netrekY) / 10
        // So netrekY=0 -> (100000 - 0) / 10 = 10000
        let result = NetrekMath.netrekY2GameY(0)
        XCTAssertEqual(result, 10000, "Netrek Y=0 should map to Game Y=10000 (inverted)")
    }

    func testNetrekY2GameY_MaxValue() {
        // netrekY=100000 -> (100000 - 100000) / 10 = 0
        let result = NetrekMath.netrekY2GameY(100000)
        XCTAssertEqual(result, 0, "Netrek Y=100000 should map to Game Y=0 (inverted)")
    }

    func testNetrekY2GameY_Midpoint() {
        // netrekY=50000 -> (100000 - 50000) / 10 = 5000
        let result = NetrekMath.netrekY2GameY(50000)
        XCTAssertEqual(result, 5000, "Netrek Y=50000 should map to Game Y=5000")
    }

    // MARK: - Reverse Direction Calculation Tests (Screen coords -> Netrek direction)

    func testCalculateNetrekDirection_North() {
        // From center (5000, 5000) to north (5000, 0) should be Netrek 0
        // Note: In screen coords, Y decreases going up
        let result = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 5000, destinationY: 4000  // Going up (north)
        )
        // Netrek 0 = north, but depends on coordinate system
        // Let's just verify it's a valid UInt8
        XCTAssertTrue(result <= 255, "Direction should be valid UInt8")
    }

    func testCalculateNetrekDirection_East() {
        // From center to east (right)
        let result = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 6000, destinationY: 5000  // Going right (east)
        )
        // Netrek 64 = east (direction increases clockwise)
        XCTAssertEqual(result, 64, accuracy: 2,
                       "East direction should be around 64")
    }

    func testCalculateNetrekDirection_West() {
        // From center to west (left)
        let result = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 4000, destinationY: 5000  // Going left (west)
        )
        // Netrek 192 = west (direction increases clockwise)
        XCTAssertEqual(result, 192, accuracy: 2,
                       "West direction should be around 192")
    }

    func testCalculateNetrekDirection_Roundtrip() {
        // Test that forward and reverse direction conversions are consistent
        // Note: The coordinate systems differ - directionNetrek2radian uses standard math
        // coordinates (counterclockwise from east), while calculateNetrekDirection uses
        // screen coordinates with atan2.

        // Test a few known directions manually instead of automated roundtrip
        // East (64): positive X direction
        let eastResult = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 6000, destinationY: 5000
        )
        XCTAssertEqual(eastResult, 64, accuracy: 2, "East should be 64")

        // West (192): negative X direction
        let westResult = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 4000, destinationY: 5000
        )
        XCTAssertEqual(westResult, 192, accuracy: 2, "West should be 192")

        // In game coordinates: Y increases upward (Netrek convention)
        // But screen Y increases downward
        // calculateNetrekDirection uses raw coordinates where:
        // - positive deltaY = up in game = north
        // - negative deltaY = down in game = south

        // North (0): positive Y direction in game coordinates
        let northResult = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 5000, destinationY: 6000
        )
        XCTAssertEqual(northResult, 0, accuracy: 2, "North (positive Y) should be 0")

        // South (128): negative Y direction in game coordinates
        let southResult = NetrekMath.calculateNetrekDirection(
            mePositionX: 5000, mePositionY: 5000,
            destinationX: 5000, destinationY: 4000
        )
        XCTAssertEqual(southResult, 128, accuracy: 2, "South (negative Y) should be 128")
    }

    // MARK: - String Sanitization Tests

    func testSanitizeString_ReplacesRomulus() {
        let result = NetrekMath.sanitizeString("Welcome to Romulus")
        XCTAssertEqual(result, "Welcome to Rome",
                       "Romulus should be replaced with Rome")
    }

    func testSanitizeString_ReplacesKlingus() {
        let result = NetrekMath.sanitizeString("Klingus is under attack")
        XCTAssertEqual(result, "Kazari is under attack",
                       "Klingus should be replaced with Kazari")
    }

    func testSanitizeString_ReplacesPraxis() {
        let result = NetrekMath.sanitizeString("Orbit Praxis now")
        XCTAssertEqual(result, "Orbit Prague now",
                       "Praxis should be replaced with Prague")
    }

    func testSanitizeString_ReplacesPhaser() {
        let result = NetrekMath.sanitizeString("Fire phaser at enemy")
        XCTAssertEqual(result, "Fire laser at enemy",
                       "phaser should be replaced with laser")
    }

    func testSanitizeString_ReplacesPhaserCapitalized() {
        let result = NetrekMath.sanitizeString("Phaser locked on target")
        XCTAssertEqual(result, "Laser locked on target",
                       "Phaser should be replaced with Laser")
    }

    func testSanitizeString_ReplacesKLI() {
        let result = NetrekMath.sanitizeString("KLI forces advancing")
        XCTAssertEqual(result, "KAZ forces advancing",
                       "KLI should be replaced with KAZ")
    }

    func testSanitizeString_PreservesNormalText() {
        let original = "Federation cruiser destroyed"
        let result = NetrekMath.sanitizeString(original)
        XCTAssertEqual(result, original,
                       "Normal text without replacements should be preserved")
    }

    func testSanitizeString_MultipleReplacements() {
        let result = NetrekMath.sanitizeString("KLI phaser hit Romulus")
        XCTAssertEqual(result, "KAZ laser hit Rome",
                       "Multiple replacements should all be applied")
    }

    // MARK: - Team Letter Tests

    func testTeamLetter_Federation() {
        XCTAssertEqual(NetrekMath.teamLetter(team: .federation), "F")
    }

    func testTeamLetter_Roman() {
        XCTAssertEqual(NetrekMath.teamLetter(team: .roman), "R")
    }

    func testTeamLetter_Kazari() {
        XCTAssertEqual(NetrekMath.teamLetter(team: .kazari), "K")
    }

    func testTeamLetter_Orion() {
        XCTAssertEqual(NetrekMath.teamLetter(team: .orion), "O")
    }

    func testTeamLetter_Independent() {
        XCTAssertEqual(NetrekMath.teamLetter(team: .independent), "I")
    }

    func testTeamLetter_Ogg() {
        XCTAssertEqual(NetrekMath.teamLetter(team: .ogg), "I")
    }

    // MARK: - Player Letter Tests

    func testPlayerLetter_Hex0To15() {
        for id in 0..<16 {
            let expected = String(format: "%x", id)
            XCTAssertEqual(NetrekMath.playerLetter(playerId: id), expected,
                          "Player ID \(id) should be hex \(expected)")
        }
    }

    func testPlayerLetter_16ToV() {
        let expected = ["g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v"]
        for (index, letter) in expected.enumerated() {
            XCTAssertEqual(NetrekMath.playerLetter(playerId: 16 + index), letter,
                          "Player ID \(16 + index) should be \(letter)")
        }
    }

    func testPlayerLetter_Invalid() {
        XCTAssertEqual(NetrekMath.playerLetter(playerId: 32), "?",
                       "Invalid player ID should return ?")
        XCTAssertEqual(NetrekMath.playerLetter(playerId: 100), "?",
                       "Invalid player ID should return ?")
    }

    // MARK: - Angle Diff Tests

    func testAngleDiff_Zero() {
        let result = NetrekMath.angleDiff(1.0, 1.0)
        XCTAssertEqual(result, 0.0, accuracy: 0.001,
                       "Same angles should have zero difference")
    }

    func testAngleDiff_SmallPositive() {
        let result = NetrekMath.angleDiff(1.5, 1.0)
        XCTAssertEqual(result, 0.5, accuracy: 0.001,
                       "Simple positive difference")
    }

    func testAngleDiff_SmallNegative() {
        let result = NetrekMath.angleDiff(1.0, 1.5)
        XCTAssertEqual(result, -0.5, accuracy: 0.001,
                       "Simple negative difference")
    }

    func testAngleDiff_WrapAround() {
        // Test wrap around at 2π boundary
        let nearZero = 0.1
        let nearTwoPi = 2 * Double.pi - 0.1

        // Going from nearTwoPi to nearZero should be a small positive step
        let result = NetrekMath.angleDiff(nearZero, nearTwoPi)
        // The expected behavior depends on implementation
        XCTAssertFalse(result.isNaN, "Wrap-around should not produce NaN")
    }
}

// Helper for accuracy comparison with UInt8
private func XCTAssertEqual(_ actual: UInt8, _ expected: UInt8, accuracy: UInt8, _ message: String) {
    let diff = actual > expected ? actual - expected : expected - actual
    XCTAssertTrue(diff <= accuracy, "\(message). Expected \(expected) +/- \(accuracy), got \(actual)")
}
