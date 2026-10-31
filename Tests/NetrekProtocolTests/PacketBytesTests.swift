//
//  PacketBytesTests.swift
//  NetrekProtocolTests
//
//  The bytes MakePacket sends. The struct sizes and offsets behind them
//  are pinned in NetrekWireTests.
//

import XCTest
@testable import NetrekProtocol

final class PacketBytesTests: XCTestCase {

    // MARK: - Bytes on the wire

    func testCpLaserPadsAreZero() {
        let data = MakePacket.cpLaser(netrekDirection: 200)
        XCTAssertEqual(Array(data), [4, 200, 0, 0])
    }

    func testCpSocketBytes() {
        // SOCKVERSION 4, UDPVERSION 10, pad, then port 32800 big-endian.
        let data = MakePacket.cpSocket()
        XCTAssertEqual(Array(data), [27, 4, 10, 0, 0x00, 0x00, 0x80, 0x20])
    }

    func testCpUpdatesBytes() {
        // 1,000,000 / UPDATE_RATE (20) = 50,000 microseconds, big-endian.
        let data = MakePacket.cpUpdates()
        XCTAssertEqual(Array(data), [31, 0, 0, 0, 0x00, 0x00, 0xC3, 0x50])
    }
}
