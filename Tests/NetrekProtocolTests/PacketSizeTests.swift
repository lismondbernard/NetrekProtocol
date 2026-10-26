//
//  PacketSizeTests.swift
//  NetrekCoreTests
//
//  Unit tests for PACKET_SIZES array verification.
//  These sizes are critical for binary protocol parsing.
//  Any mismatch will cause packet framing errors.
//

import XCTest
@testable import NetrekProtocol

final class PacketSizeTests: XCTestCase {

    // MARK: - Critical Incoming Packet Sizes

    func testPacketSize_SP_MESSAGE_Is84() {
        // Type 1: Chat messages
        XCTAssertEqual(PACKET_SIZES[1], 84, "SP_MESSAGE must be 84 bytes")
    }

    func testPacketSize_SP_PLAYER_INFO_Is4() {
        // Type 2: Player ship/team info
        XCTAssertEqual(PACKET_SIZES[2], 4, "SP_PLAYER_INFO must be 4 bytes")
    }

    func testPacketSize_SP_KILLS_Is8() {
        // Type 3: Kill count
        XCTAssertEqual(PACKET_SIZES[3], 8, "SP_KILLS must be 8 bytes")
    }

    func testPacketSize_SP_PLAYER_Is12() {
        // Type 4: Player position/direction/speed - most frequent packet
        XCTAssertEqual(PACKET_SIZES[4], 12, "SP_PLAYER must be 12 bytes")
    }

    func testPacketSize_SP_TORP_INFO_Is8() {
        // Type 5: Torpedo status
        XCTAssertEqual(PACKET_SIZES[5], 8, "SP_TORP_INFO must be 8 bytes")
    }

    func testPacketSize_SP_TORP_Is12() {
        // Type 6: Torpedo position
        XCTAssertEqual(PACKET_SIZES[6], 12, "SP_TORP must be 12 bytes")
    }

    func testPacketSize_SP_PHASER_Is16() {
        // Type 7: Laser/Phaser
        XCTAssertEqual(PACKET_SIZES[7], 16, "SP_PHASER (laser) must be 16 bytes")
    }

    func testPacketSize_SP_PLASMA_INFO_Is8() {
        // Type 8: Plasma status
        XCTAssertEqual(PACKET_SIZES[8], 8, "SP_PLASMA_INFO must be 8 bytes")
    }

    func testPacketSize_SP_PLASMA_Is12() {
        // Type 9: Plasma position
        XCTAssertEqual(PACKET_SIZES[9], 12, "SP_PLASMA must be 12 bytes")
    }

    func testPacketSize_SP_WARNING_Is84() {
        // Type 10: Warning messages
        XCTAssertEqual(PACKET_SIZES[10], 84, "SP_WARNING must be 84 bytes")
    }

    func testPacketSize_SP_MOTD_Is84() {
        // Type 11: Message of the day
        XCTAssertEqual(PACKET_SIZES[11], 84, "SP_MOTD must be 84 bytes")
    }

    func testPacketSize_SP_YOU_Is32() {
        // Type 12: Own ship status - critical for game state transitions
        XCTAssertEqual(PACKET_SIZES[12], 32, "SP_YOU must be 32 bytes")
    }

    func testPacketSize_SP_QUEUE_Is4() {
        // Type 13: Queue position
        XCTAssertEqual(PACKET_SIZES[13], 4, "SP_QUEUE must be 4 bytes")
    }

    func testPacketSize_SP_STATUS_Is28() {
        // Type 14: Server status
        XCTAssertEqual(PACKET_SIZES[14], 28, "SP_STATUS must be 28 bytes")
    }

    func testPacketSize_SP_PLANET_Is12() {
        // Type 15: Planet state (old format)
        XCTAssertEqual(PACKET_SIZES[15], 12, "SP_PLANET must be 12 bytes")
    }

    func testPacketSize_SP_PICKOK_Is4() {
        // Type 16: Outfit accepted - triggers gameActive state
        XCTAssertEqual(PACKET_SIZES[16], 4, "SP_PICKOK must be 4 bytes")
    }

    func testPacketSize_SP_LOGIN_Is104() {
        // Type 17: Login response - triggers loginAccepted state
        XCTAssertEqual(PACKET_SIZES[17], 104, "SP_LOGIN must be 104 bytes")
    }

    func testPacketSize_SP_FLAGS_Is8() {
        // Type 18: Player flags (shields, cloak, etc.)
        XCTAssertEqual(PACKET_SIZES[18], 8, "SP_FLAGS must be 8 bytes")
    }

    func testPacketSize_SP_MASK_Is4() {
        // Type 19: Team mask
        XCTAssertEqual(PACKET_SIZES[19], 4, "SP_MASK must be 4 bytes")
    }

    func testPacketSize_SP_PSTATUS_Is4() {
        // Type 20: Player slot status
        XCTAssertEqual(PACKET_SIZES[20], 4, "SP_PSTATUS must be 4 bytes")
    }

    func testPacketSize_SP_BADVERSION_Is4() {
        // Type 21: Bad version error
        XCTAssertEqual(PACKET_SIZES[21], 4, "SP_BADVERSION must be 4 bytes")
    }

    func testPacketSize_SP_HOSTILE_Is4() {
        // Type 22: Hostile/war status
        XCTAssertEqual(PACKET_SIZES[22], 4, "SP_HOSTILE must be 4 bytes")
    }

    func testPacketSize_SP_STATS_Is56() {
        // Type 23: Player statistics
        XCTAssertEqual(PACKET_SIZES[23], 56, "SP_STATS must be 56 bytes")
    }

    func testPacketSize_SP_PL_LOGIN_Is52() {
        // Type 24: Player login notification
        XCTAssertEqual(PACKET_SIZES[24], 52, "SP_PL_LOGIN must be 52 bytes")
    }

    func testPacketSize_SP_PLANET_LOC_Is28() {
        // Type 26: Planet location and name
        XCTAssertEqual(PACKET_SIZES[26], 28, "SP_PLANET_LOC must be 28 bytes")
    }

    func testPacketSize_SP_SHIP_CAP_Is60() {
        // Type 39: Ship capabilities
        XCTAssertEqual(PACKET_SIZES[39], 60, "SP_SHIP_CAP must be 60 bytes")
    }

    func testPacketSize_SP_FEATURE_Is88() {
        // Type 60: Server feature flags
        XCTAssertEqual(PACKET_SIZES[60], 88, "SP_FEATURE must be 88 bytes")
    }

    // MARK: - Packet Size Array Integrity

    func testPacketSizes_HasMinimumEntries() {
        // Array must have at least 61 entries (0-60)
        XCTAssertGreaterThanOrEqual(PACKET_SIZES.count, 61,
            "PACKET_SIZES must have at least 61 entries for all known packet types")
    }

    func testPacketSizes_NullPacket_IsZero() {
        // Type 0 is null/invalid
        XCTAssertEqual(PACKET_SIZES[0], 0, "Null packet type 0 must have size 0")
    }

    func testPacketSizes_NoNegativeExceptVariable() {
        // Negative sizes indicate variable-length packets
        // Verify we understand which ones are variable
        let variableLengthPackets = [41, 42, 45, 47, 48, 50, 57, 58]

        for (index, size) in PACKET_SIZES.enumerated() {
            if size < 0 {
                XCTAssertTrue(variableLengthPackets.contains(index),
                    "Unexpected variable-length packet at index \(index)")
            }
        }
    }

    func testPacketSizes_FixedPackets_ArePositive() {
        // Fixed-length packets must have positive sizes
        let fixedPacketTypes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
                                16, 17, 18, 19, 20, 21, 22, 23, 24, 26, 39, 60]

        for type in fixedPacketTypes {
            XCTAssertGreaterThan(PACKET_SIZES[type], 0,
                "Fixed packet type \(type) must have positive size, got \(PACKET_SIZES[type])")
        }
    }

    // MARK: - Critical Packets for State Machine

    func testPacketSizes_StateMachinePackets() {
        // These packets trigger game state transitions
        // If sizes are wrong, state machine will break

        // SP_YOU (12) triggers serverSlotFound
        XCTAssertEqual(PACKET_SIZES[12], 32, "SP_YOU size critical for state machine")

        // SP_LOGIN (17) triggers loginAccepted
        XCTAssertEqual(PACKET_SIZES[17], 104, "SP_LOGIN size critical for state machine")

        // SP_PICKOK (16) triggers gameActive
        XCTAssertEqual(PACKET_SIZES[16], 4, "SP_PICKOK size critical for state machine")

        // SP_PSTATUS (20) triggers slot status changes
        XCTAssertEqual(PACKET_SIZES[20], 4, "SP_PSTATUS size critical for state machine")
    }

    // MARK: - High-Frequency Packets

    func testPacketSizes_HighFrequencyPackets() {
        // These packets are received many times per second
        // Wrong sizes = immediate game breakage

        // SP_PLAYER (4) - position updates at 10Hz per player
        XCTAssertEqual(PACKET_SIZES[4], 12, "SP_PLAYER size critical for position updates")

        // SP_TORP (6) - torpedo positions
        XCTAssertEqual(PACKET_SIZES[6], 12, "SP_TORP size critical for weapon display")

        // SP_PHASER (7) - laser display
        XCTAssertEqual(PACKET_SIZES[7], 16, "SP_PHASER size critical for weapon display")
    }
}
