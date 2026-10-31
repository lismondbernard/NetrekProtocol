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
}
