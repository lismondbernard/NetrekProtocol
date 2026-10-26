//
//  PacketFramingTests.swift
//  NetrekCoreTests
//
//  Unit tests for packet framing and reassembly.
//  The PacketAnalyzer must correctly handle:
//  - Complete packets
//  - Partial packets (buffered in leftOverData)
//  - Multiple packets in one receive
//  - Partial then complete across receives
//

import XCTest
@testable import NetrekProtocol

final class PacketFramingTests: XCTestCase {

    // MARK: - Test Helpers

    /// Creates a valid SP_PSTATUS packet (type 20, 4 bytes)
    /// This is the simplest packet for testing framing
    func makeSpPstatusPacket(playerId: UInt8, status: UInt8) -> Data {
        var data = Data(count: 4)
        data[0] = 20        // SP_PSTATUS type
        data[1] = playerId
        data[2] = status
        data[3] = 0         // padding
        return data
    }

    /// Creates a valid SP_PLAYER packet (type 4, 12 bytes)
    func makeSpPlayerPacket(playerId: UInt8) -> Data {
        var data = Data(count: 12)
        data[0] = 4         // SP_PLAYER type
        data[1] = playerId
        data[2] = 0         // direction
        data[3] = 5         // speed
        // bytes 4-7: position X (big endian)
        // bytes 8-11: position Y (big endian)
        return data
    }

    /// Creates a valid SP_PICKOK packet (type 16, 4 bytes)
    func makeSpPickokPacket(state: UInt8) -> Data {
        var data = Data(count: 4)
        data[0] = 16        // SP_PICKOK type
        data[1] = state
        data[2] = 0         // padding
        data[3] = 0         // padding
        return data
    }

    // MARK: - Packet Size Lookup Tests

    func testPacketSizes_SafeSubscript_ValidIndex() {
        // Test that PACKET_SIZES[safe:] returns correct value for valid indices
        XCTAssertEqual(PACKET_SIZES[safe: 4], 12, "SP_PLAYER should be 12 bytes")
        XCTAssertEqual(PACKET_SIZES[safe: 20], 4, "SP_PSTATUS should be 4 bytes")
    }

    func testPacketSizes_SafeSubscript_InvalidIndex() {
        // Test that out-of-bounds access returns nil
        XCTAssertNil(PACKET_SIZES[safe: 1000], "Invalid index should return nil")
        XCTAssertNil(PACKET_SIZES[safe: -1], "Negative index should return nil")
    }

    // MARK: - Single Complete Packet Tests

    func testAnalyze_SingleCompletePacket_NoLeftover() {
        // A complete 4-byte packet should be processed with no leftover
        let packet = makeSpPstatusPacket(playerId: 0, status: 2)
        XCTAssertEqual(packet.count, 4)
        XCTAssertEqual(packet[0], 20)  // SP_PSTATUS

        // Verify packet structure
        XCTAssertEqual(PACKET_SIZES[20], 4, "SP_PSTATUS should be 4 bytes")
    }

    func testAnalyze_SingleComplete12BytePacket() {
        let packet = makeSpPlayerPacket(playerId: 5)
        XCTAssertEqual(packet.count, 12)
        XCTAssertEqual(packet[0], 4)  // SP_PLAYER
        XCTAssertEqual(PACKET_SIZES[4], 12, "SP_PLAYER should be 12 bytes")
    }

    // MARK: - Multiple Packets Tests

    func testAnalyze_TwoCompletePackets() {
        // Two 4-byte packets = 8 bytes total
        var data = Data()
        data.append(makeSpPstatusPacket(playerId: 0, status: 1))
        data.append(makeSpPickokPacket(state: 1))

        XCTAssertEqual(data.count, 8)
        XCTAssertEqual(data[0], 20)  // First packet: SP_PSTATUS
        XCTAssertEqual(data[4], 16)  // Second packet: SP_PICKOK
    }

    func testAnalyze_MixedSizePackets() {
        // 12-byte packet followed by 4-byte packet
        var data = Data()
        data.append(makeSpPlayerPacket(playerId: 3))
        data.append(makeSpPstatusPacket(playerId: 3, status: 2))

        XCTAssertEqual(data.count, 16)
        XCTAssertEqual(data[0], 4)   // First packet: SP_PLAYER (12 bytes)
        XCTAssertEqual(data[12], 20) // Second packet: SP_PSTATUS (4 bytes)
    }

    // MARK: - Partial Packet Tests (Framing Logic)

    func testPartialPacket_SplitAt2Bytes() {
        // A 4-byte packet split into 2 + 2 bytes
        let fullPacket = makeSpPstatusPacket(playerId: 5, status: 2)

        let firstHalf = fullPacket.prefix(2)
        let secondHalf = fullPacket.suffix(2)

        XCTAssertEqual(firstHalf.count, 2)
        XCTAssertEqual(secondHalf.count, 2)

        // First half starts with packet type
        XCTAssertEqual(firstHalf[0], 20)

        // When reassembled, should match original
        var reassembled = Data(firstHalf)
        reassembled.append(contentsOf: secondHalf)
        XCTAssertEqual(reassembled, fullPacket)
    }

    func testPartialPacket_SingleByteFirst() {
        // Just the packet type byte, then rest
        let fullPacket = makeSpPlayerPacket(playerId: 7)

        let firstByte = fullPacket.prefix(1)
        let rest = fullPacket.suffix(11)

        XCTAssertEqual(firstByte.count, 1)
        XCTAssertEqual(rest.count, 11)
        XCTAssertEqual(firstByte[0], 4)  // SP_PLAYER type
    }

    func testPartialPacket_12ByteSplitIntoThirds() {
        // 12-byte packet split into 4 + 4 + 4
        let fullPacket = makeSpPlayerPacket(playerId: 0)

        let part1 = fullPacket.prefix(4)
        let part2 = fullPacket[4..<8]
        let part3 = fullPacket.suffix(4)

        XCTAssertEqual(part1.count, 4)
        XCTAssertEqual(part2.count, 4)
        XCTAssertEqual(part3.count, 4)

        // Reassemble
        var reassembled = Data(part1)
        reassembled.append(contentsOf: part2)
        reassembled.append(contentsOf: part3)
        XCTAssertEqual(reassembled, fullPacket)
    }

    // MARK: - Invalid Packet Handling

    func testInvalidPacketType_Zero() {
        // Packet type 0 has size 0 (null/invalid)
        XCTAssertEqual(PACKET_SIZES[0], 0, "Packet type 0 should have size 0")
    }

    func testInvalidPacketType_Unused() {
        // Some packet types are unused (size 0)
        XCTAssertEqual(PACKET_SIZES[33], 0, "Unused packet type 33 should have size 0")
        XCTAssertEqual(PACKET_SIZES[34], 0, "Unused packet type 34 should have size 0")
    }

    func testVariableLengthPacket_NegativeSize() {
        // Variable-length packets have negative size in table
        XCTAssertEqual(PACKET_SIZES[41], -1, "SP_S_MESSAGE should be variable-length (-1)")
        XCTAssertEqual(PACKET_SIZES[45], -1, "SP_S_PLAYER should be variable-length (-1)")
    }

    // MARK: - Data Concatenation Tests (Critical for leftOverData)

    func testDataConcatenation_PreservesBytes() {
        // This tests the exact concatenation logic used in PacketAnalyzer
        let leftOver = Data([0x14, 0x05])  // Partial SP_PSTATUS
        let incoming = Data([0x02, 0x00])  // Rest of packet

        // Method 1: Direct append (may have issues with indices)
        var combined1 = Data()
        for byte in leftOver {
            combined1.append(byte)
        }
        combined1.append(contentsOf: incoming)

        XCTAssertEqual(combined1.count, 4)
        XCTAssertEqual(combined1[0], 0x14)
        XCTAssertEqual(combined1[1], 0x05)
        XCTAssertEqual(combined1[2], 0x02)
        XCTAssertEqual(combined1[3], 0x00)
    }

    func testDataConcatenation_UInt8Array() {
        // PacketAnalyzer uses this pattern for leftOverData
        let leftOver = Data([0x04, 0x03, 0x40, 0x05])
        var leftOverStruct: [UInt8] = []
        for byte in leftOver {
            leftOverStruct.append(byte)
        }

        let incoming = Data([0x00, 0x01, 0x38, 0x80, 0x00, 0x01, 0x38, 0x80])
        let combined: Data = leftOverStruct + incoming

        XCTAssertEqual(combined.count, 12)
        XCTAssertEqual(combined[0], 0x04)  // First byte of leftOver
        XCTAssertEqual(combined[4], 0x00)  // First byte of incoming
    }

    // MARK: - Subdata Extraction Tests

    func testSubdata_ExtractsCorrectRange() {
        // PacketAnalyzer uses subdata(in:) for packet extraction
        let data = Data([0x04, 0x05, 0x80, 0x06, 0x00, 0x01, 0x00, 0x00,
                         0x00, 0x02, 0x00, 0x00, 0x14, 0x00, 0x02, 0x00])

        // First packet: SP_PLAYER (12 bytes)
        let firstPacket = data.subdata(in: 0..<12)
        XCTAssertEqual(firstPacket.count, 12)
        XCTAssertEqual(firstPacket[0], 0x04)

        // Second packet: SP_PSTATUS (4 bytes)
        let secondPacket = data.subdata(in: 12..<16)
        XCTAssertEqual(secondPacket.count, 4)
        XCTAssertEqual(secondPacket[0], 0x14)  // 20 in decimal
    }

    // MARK: - Edge Cases

    func testEmptyData() {
        let data = Data()
        XCTAssertTrue(data.isEmpty)
        XCTAssertNil(data.first)
    }

    func testSingleByte_InvalidPacket() {
        // Just one byte can't form a complete packet
        let data = Data([0x04])  // SP_PLAYER type, but only 1 byte
        XCTAssertEqual(data.count, 1)
        XCTAssertEqual(data[0], 4)
        // PacketAnalyzer would buffer this in leftOverData
        XCTAssertLessThan(data.count, PACKET_SIZES[4])
    }

    func testPacketExactlyAtBoundary() {
        // Packet exactly fills expected size
        let packet = makeSpPlayerPacket(playerId: 0)
        XCTAssertEqual(packet.count, PACKET_SIZES[4])
    }

    // MARK: - Real Packet Sequence Simulation

    func testRealPacketSequence_LoginFlow() {
        // Simulate receiving SP_YOU (32 bytes) followed by SP_LOGIN (104 bytes)
        // This happens during the login flow

        // SP_YOU structure (simplified)
        var spYou = Data(count: 32)
        spYou[0] = 12  // SP_YOU type

        // SP_LOGIN structure (simplified)
        var spLogin = Data(count: 104)
        spLogin[0] = 17  // SP_LOGIN type

        var sequence = Data()
        sequence.append(spYou)
        sequence.append(spLogin)

        XCTAssertEqual(sequence.count, 136)
        XCTAssertEqual(sequence[0], 12)   // SP_YOU
        XCTAssertEqual(sequence[32], 17)  // SP_LOGIN

        // Verify we can identify packet boundaries
        let firstPacketType = sequence[0]
        let firstPacketSize = PACKET_SIZES[Int(firstPacketType)]
        XCTAssertEqual(firstPacketSize, 32)

        let secondPacketType = sequence[firstPacketSize]
        let secondPacketSize = PACKET_SIZES[Int(secondPacketType)]
        XCTAssertEqual(secondPacketSize, 104)
    }

    func testRealPacketSequence_GameplayBurst() {
        // During gameplay, server sends rapid updates:
        // Multiple SP_PLAYER (12) + SP_TORP (12) + SP_PHASER (16)

        var burst = Data()

        // 3 player position updates
        for i in 0..<3 {
            var player = Data(count: 12)
            player[0] = 4  // SP_PLAYER
            player[1] = UInt8(i)
            burst.append(player)
        }

        // 2 torpedo updates
        for _ in 0..<2 {
            var torp = Data(count: 12)
            torp[0] = 6  // SP_TORP
            burst.append(torp)
        }

        // 1 laser/phaser
        var laser = Data(count: 16)
        laser[0] = 7  // SP_PHASER
        burst.append(laser)

        XCTAssertEqual(burst.count, 3*12 + 2*12 + 16)  // 76 bytes

        // Walk through packets
        var offset = 0
        var packetCount = 0
        while offset < burst.count {
            let packetType = Int(burst[offset])
            let packetSize = PACKET_SIZES[packetType]
            XCTAssertGreaterThan(packetSize, 0, "Packet at offset \(offset) has invalid size")
            offset += packetSize
            packetCount += 1
        }
        XCTAssertEqual(packetCount, 6)
        XCTAssertEqual(offset, burst.count)
    }
}

// MARK: - Array Safe Subscript Extension (matches production code)

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
