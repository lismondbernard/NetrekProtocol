//
//  ClientPacketLayoutTests.swift
//  NetrekWireTests
//
//  Senders copy each CP_* struct straight out of memory, so the
//  struct's in-memory size has to equal the size the server reads for
//  that packet type. These tests pin both.
//

import XCTest
import NetrekWire

final class ClientPacketLayoutTests: XCTestCase {

    // MARK: - Struct size matches the wire size

    func testStructSizesMatchWireSizes() {
        XCTAssertEqual(MemoryLayout<CP_MESSAGE>.size, 84)
        XCTAssertEqual(MemoryLayout<CP_SPEED>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_DIRECTION>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_LASER>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_PLASMA>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_TORP>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_QUIT>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_LOGIN>.size, 52)
        XCTAssertEqual(MemoryLayout<CP_OUTFIT>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_PRACTR>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_SHIELD>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_REPAIR>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_ORBIT>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_PLANLOCK>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_PLAYLOCK>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_BOMB>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_BEAM>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_CLOAK>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_DET_TORPS>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_DET_MYTORP>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_REFIT>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_TRACTOR>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_REPRESS>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_COUP>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_SOCKET>.size, 8)
        XCTAssertEqual(MemoryLayout<CP_BYE>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_DOCKPERM>.size, 4)
        XCTAssertEqual(MemoryLayout<CP_UPDATES>.size, 8)
        XCTAssertEqual(MemoryLayout<CP_FEATURE>.size, 88)
    }

    func testDeclaredSizesMatchStructSizes() {
        XCTAssertEqual(CP_MESSAGE().size, MemoryLayout<CP_MESSAGE>.size)
        XCTAssertEqual(CP_LASER().size, MemoryLayout<CP_LASER>.size)
        XCTAssertEqual(CP_LOGIN().size, MemoryLayout<CP_LOGIN>.size)
        XCTAssertEqual(CP_SOCKET().size, MemoryLayout<CP_SOCKET>.size)
        XCTAssertEqual(CP_UPDATES(usecs: 0).size, MemoryLayout<CP_UPDATES>.size)
        XCTAssertEqual(CP_FEATURE().size, MemoryLayout<CP_FEATURE>.size)
    }

    // MARK: - Field offsets the server reads

    func testCpMessageOffsets() {
        XCTAssertEqual(MemoryLayout<CP_MESSAGE>.offset(of: \.group), 1)
        XCTAssertEqual(MemoryLayout<CP_MESSAGE>.offset(of: \.indiv), 2)
        XCTAssertEqual(MemoryLayout<CP_MESSAGE>.offset(of: \.mesg), 4)
    }

    func testCpLaserOffsets() {
        XCTAssertEqual(MemoryLayout<CP_LASER>.offset(of: \.netrekDirection), 1)
        XCTAssertEqual(MemoryLayout<CP_LASER>.offset(of: \.pad1), 2)
        XCTAssertEqual(MemoryLayout<CP_LASER>.offset(of: \.pad2), 3)
    }

    func testCpLoginOffsets() {
        XCTAssertEqual(MemoryLayout<CP_LOGIN>.offset(of: \.query), 1)
        XCTAssertEqual(MemoryLayout<CP_LOGIN>.offset(of: \.name), 4)
        XCTAssertEqual(MemoryLayout<CP_LOGIN>.offset(of: \.password), 20)
        XCTAssertEqual(MemoryLayout<CP_LOGIN>.offset(of: \.login), 36)
    }

    func testCpOutfitOffsets() {
        XCTAssertEqual(MemoryLayout<CP_OUTFIT>.offset(of: \.team), 1)
        XCTAssertEqual(MemoryLayout<CP_OUTFIT>.offset(of: \.ship), 2)
    }

    func testCpTractorOffsets() {
        XCTAssertEqual(MemoryLayout<CP_TRACTOR>.offset(of: \.state), 1)
        XCTAssertEqual(MemoryLayout<CP_TRACTOR>.offset(of: \.playerID), 2)
        XCTAssertEqual(MemoryLayout<CP_REPRESS>.offset(of: \.state), 1)
        XCTAssertEqual(MemoryLayout<CP_REPRESS>.offset(of: \.playerID), 2)
    }

    func testCpDetMyTorpOffsets() {
        XCTAssertEqual(MemoryLayout<CP_DET_MYTORP>.offset(of: \.tNumByte1), 2)
        XCTAssertEqual(MemoryLayout<CP_DET_MYTORP>.offset(of: \.tNumByte2), 3)
    }

    func testCpSocketOffsets() {
        XCTAssertEqual(MemoryLayout<CP_SOCKET>.offset(of: \.version), 1)
        XCTAssertEqual(MemoryLayout<CP_SOCKET>.offset(of: \.udp_version), 2)
        XCTAssertEqual(MemoryLayout<CP_SOCKET>.offset(of: \.port), 4)
    }

    func testCpUpdatesOffsets() {
        XCTAssertEqual(MemoryLayout<CP_UPDATES>.offset(of: \.usecs), 4)
    }

    func testCpFeatureOffsets() {
        XCTAssertEqual(MemoryLayout<CP_FEATURE>.offset(of: \.feature_type), 1)
        XCTAssertEqual(MemoryLayout<CP_FEATURE>.offset(of: \.arg1), 2)
        XCTAssertEqual(MemoryLayout<CP_FEATURE>.offset(of: \.arg2), 3)
        XCTAssertEqual(MemoryLayout<CP_FEATURE>.offset(of: \.value), 4)
        XCTAssertEqual(MemoryLayout<CP_FEATURE>.offset(of: \.name), 8)
    }
}
