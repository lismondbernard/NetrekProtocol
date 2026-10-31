//
//  ServerPacketInitTests.swift
//  NetrekWireTests
//

import XCTest
import NetrekWire

/// Each SP_* struct has a fixed type byte and an `init()` that zeroes
/// every other field, so a sender can't put the wrong type on the wire.
final class ServerPacketInitTests: XCTestCase {

    func bytes<T>(_ packet: T) -> [UInt8] {
        var copy = packet
        return withUnsafeBytes(of: &copy) { Array($0) }
    }

    func check<T>(_ packet: T, type: UInt8, file: StaticString = #filePath, line: UInt = #line) {
        let data = bytes(packet)
        XCTAssertEqual(data.count, MemoryLayout<T>.size, file: file, line: line)
        XCTAssertEqual(data.first, type, "type byte of \(T.self)", file: file, line: line)
        XCTAssertTrue(data.dropFirst().allSatisfy { $0 == 0 }, "\(T.self) is not zero after the type byte", file: file, line: line)
    }

    func testInitSetsTheTypeAndZeroesTheRest() {
        check(SP_MESSAGE(), type: 1)
        check(SP_PLAYER_INFO(), type: 2)
        check(SP_KILLS(), type: 3)
        check(SP_PLAYER(), type: 4)
        check(SP_TORP_INFO(), type: 5)
        check(SP_TORP(), type: 6)
        check(SP_LASER(), type: 7)
        check(SP_PLASMA_INFO(), type: 8)
        check(SP_PLASMA(), type: 9)
        check(SP_MOTD(), type: 11)
        check(SP_YOU(), type: 12)
        check(SP_QUEUE(), type: 13)
        check(SP_PLANET(), type: 15)
        check(SP_PICKOK(), type: 16)
        check(SP_LOGIN(), type: 17)
        check(SP_FLAGS(), type: 18)
        check(SP_MASK(), type: 19)
        check(SP_PLAYER_STATUS(), type: 20)
        check(SP_HOSTILE(), type: 22)
        check(SP_STATS(), type: 23)
        check(SP_PL_LOGIN(), type: 24)
        check(SP_PLANET_LOC(), type: 26)
        check(SP_SHIP_CAP(), type: 39)
    }
}
