//
//  PacketSizeTableTests.swift
//  NetrekWireTests
//
//  The structs and the size tables now sit side by side, so check that
//  they agree: each struct's size is the size its reader expects.
//

import XCTest
import Foundation
import NetrekWire

final class PacketSizeTableTests: XCTestCase {

    func testServerStructSizesMatchSizeTable() {
        let structs: [(type: Int, size: Int, name: String)] = [
            (1, MemoryLayout<SP_MESSAGE>.size, "SP_MESSAGE"),
            (2, MemoryLayout<SP_PLAYER_INFO>.size, "SP_PLAYER_INFO"),
            (3, MemoryLayout<SP_KILLS>.size, "SP_KILLS"),
            (4, MemoryLayout<SP_PLAYER>.size, "SP_PLAYER"),
            (5, MemoryLayout<SP_TORP_INFO>.size, "SP_TORP_INFO"),
            (6, MemoryLayout<SP_TORP>.size, "SP_TORP"),
            (7, MemoryLayout<SP_LASER>.size, "SP_LASER"),
            (8, MemoryLayout<SP_PLASMA_INFO>.size, "SP_PLASMA_INFO"),
            (9, MemoryLayout<SP_PLASMA>.size, "SP_PLASMA"),
            (11, MemoryLayout<SP_MOTD>.size, "SP_MOTD"),
            (12, MemoryLayout<SP_YOU>.size, "SP_YOU"),
            (13, MemoryLayout<SP_QUEUE>.size, "SP_QUEUE"),
            (15, MemoryLayout<SP_PLANET>.size, "SP_PLANET"),
            (16, MemoryLayout<SP_PICKOK>.size, "SP_PICKOK"),
            (17, MemoryLayout<SP_LOGIN>.size, "SP_LOGIN"),
            (18, MemoryLayout<SP_FLAGS>.size, "SP_FLAGS"),
            (19, MemoryLayout<SP_MASK>.size, "SP_MASK"),
            (20, MemoryLayout<SP_PLAYER_STATUS>.size, "SP_PLAYER_STATUS"),
            (22, MemoryLayout<SP_HOSTILE>.size, "SP_HOSTILE"),
            (23, MemoryLayout<SP_STATS>.size, "SP_STATS"),
            (24, MemoryLayout<SP_PL_LOGIN>.size, "SP_PL_LOGIN"),
            (26, MemoryLayout<SP_PLANET_LOC>.size, "SP_PLANET_LOC"),
            (39, MemoryLayout<SP_SHIP_CAP>.size, "SP_SHIP_CAP"),
        ]
        for entry in structs {
            XCTAssertEqual(entry.size, SERVER_PACKET_SIZES[entry.type], entry.name)
        }
    }

    func testClientStructSizesMatchSizeTable() {
        let structs: [(type: Int, size: Int, name: String)] = [
            (1, MemoryLayout<CP_MESSAGE>.size, "CP_MESSAGE"),
            (2, MemoryLayout<CP_SPEED>.size, "CP_SPEED"),
            (3, MemoryLayout<CP_DIRECTION>.size, "CP_DIRECTION"),
            (4, MemoryLayout<CP_LASER>.size, "CP_LASER"),
            (5, MemoryLayout<CP_PLASMA>.size, "CP_PLASMA"),
            (6, MemoryLayout<CP_TORP>.size, "CP_TORP"),
            (7, MemoryLayout<CP_QUIT>.size, "CP_QUIT"),
            (8, MemoryLayout<CP_LOGIN>.size, "CP_LOGIN"),
            (9, MemoryLayout<CP_OUTFIT>.size, "CP_OUTFIT"),
            (11, MemoryLayout<CP_PRACTR>.size, "CP_PRACTR"),
            (12, MemoryLayout<CP_SHIELD>.size, "CP_SHIELD"),
            (13, MemoryLayout<CP_REPAIR>.size, "CP_REPAIR"),
            (14, MemoryLayout<CP_ORBIT>.size, "CP_ORBIT"),
            (15, MemoryLayout<CP_PLANLOCK>.size, "CP_PLANLOCK"),
            (16, MemoryLayout<CP_PLAYLOCK>.size, "CP_PLAYLOCK"),
            (17, MemoryLayout<CP_BOMB>.size, "CP_BOMB"),
            (18, MemoryLayout<CP_BEAM>.size, "CP_BEAM"),
            (19, MemoryLayout<CP_CLOAK>.size, "CP_CLOAK"),
            (20, MemoryLayout<CP_DET_TORPS>.size, "CP_DET_TORPS"),
            (21, MemoryLayout<CP_DET_MYTORP>.size, "CP_DET_MYTORP"),
            (23, MemoryLayout<CP_REFIT>.size, "CP_REFIT"),
            (24, MemoryLayout<CP_TRACTOR>.size, "CP_TRACTOR"),
            (25, MemoryLayout<CP_REPRESS>.size, "CP_REPRESS"),
            (26, MemoryLayout<CP_COUP>.size, "CP_COUP"),
            (27, MemoryLayout<CP_SOCKET>.size, "CP_SOCKET"),
            (29, MemoryLayout<CP_BYE>.size, "CP_BYE"),
            (30, MemoryLayout<CP_DOCKPERM>.size, "CP_DOCKPERM"),
            (31, MemoryLayout<CP_UPDATES>.size, "CP_UPDATES"),
            (60, MemoryLayout<CP_FEATURE>.size, "CP_FEATURE"),
        ]
        for entry in structs {
            XCTAssertEqual(entry.size, CLIENT_PACKET_SIZES[entry.type], entry.name)
        }
    }

    /// Every server packet size in the classic server's own table
    /// (ntserv/genspkt.c sizes[], built with RSA and LTD_STATS on a 64-bit
    /// machine, so LONG is 4 bytes), with this package's choices where it
    /// differs on purpose:
    /// - 27 SP_SCAN and 33 SP_FLAGS_ALL are 0 here: no classic server sends
    ///   SP_SCAN, and SP_FLAGS_ALL only goes to a client that asks for it.
    ///   A 0 ends reading with a reason instead of reading a packet the
    ///   client has no use for.
    /// - 42 SP_S_WARNING is -1 here, as in COW: its size comes from its
    ///   header when it carries text.
    static let classicServerSizes: [Int] = [
        0, 84, 4, 8, 12, 8, 12, 16, 8, 12,          // 0-9
        84, 84, 32, 4, 28, 12, 4, 104, 8, 4,        // 10-19
        4, 4, 4, 56, 52, 20, 28, 0, 8, 4,           // 20-29: 27 SP_SCAN
        4, 36, 32, 0, 0, 0, 0, 0, 0, 60,            // 30-39: 33 SP_FLAGS_ALL
        8, -1, -1, 12, 12, -1, 8, -1, -1, 20,       // 40-49
        -1, 0, 0, 0, 0, 0, 0, -1, -1, 36,           // 50-59
        88, 40, 324,                                // 60 SP_FEATURE, 61 SP_RANK, 62 SP_LTD
    ]

    func testServerSizesMatchTheClassicServer() {
        XCTAssertEqual(SERVER_PACKET_SIZES.count, Self.classicServerSizes.count)
        for (type, size) in Self.classicServerSizes.enumerated() where type < SERVER_PACKET_SIZES.count {
            XCTAssertEqual(SERVER_PACKET_SIZES[type], size, "type \(type)")
        }
    }

    func testNoServerPacketIsBiggerThanSpLtd() {
        // SP_LTD (324 bytes) is the biggest classic packet; COW 3.3.4 sizes
        // its read buffer's slack by it. Anything bigger is no real packet.
        XCTAssertEqual(SERVER_PACKET_SIZES.max(), 324)
        XCTAssertEqual(SERVER_PACKET_SIZES.firstIndex(of: 324), Int(ServerPacketType.ltd.rawValue))
    }

    func testRankAndLtdTypes() {
        XCTAssertEqual(ServerPacketType.rank.rawValue, 61)
        XCTAssertEqual(ServerPacketType.ltd.rawValue, 62)
        XCTAssertEqual(SERVER_PACKET_SIZES[Int(ServerPacketType.rank.rawValue)], 40)
    }

    func testEveryServerPacketTypeHasATableEntry() {
        XCTAssertEqual(SERVER_PACKET_SIZES.count, 63)
        // Types whose size is 0 on purpose today. A 0 makes PacketAnalyzer
        // stop reading the buffer instead of guessing a length.
        let zeroOnPurpose: Set<ServerPacketType> = [
            // Type 0 is not a packet; a 0 byte here means the stream is lost.
            .null,
            // SP_SCAN is the ATM scanner reply. The classic server's reply
            // code is commented out (ntserv/socket.c handleScan), and COW
            // also gives it size 0 unless built with HANDLE_SCAN.
            .scan,
            // SP_S_SEQUENCE is the short-packets sequence. COW gives it size
            // 0 too ("not yet implemented"), and this package never asks
            // for short packets.
            .sSequence,
        ]
        for type in ServerPacketType.allCases {
            XCTAssertLessThan(Int(type.rawValue), SERVER_PACKET_SIZES.count, "\(type)")
            guard Int(type.rawValue) < SERVER_PACKET_SIZES.count else { continue }
            let size = SERVER_PACKET_SIZES[Int(type.rawValue)]
            if zeroOnPurpose.contains(type) {
                XCTAssertEqual(size, 0, "\(type) has a size now; take it off the list")
            } else {
                XCTAssertNotEqual(size, 0, "\(type) has no size")
            }
        }
    }

    func testCpPlanetSize() {
        // Classic packets.h:886, struct planet_cpacket: char type, pnum,
        // owner, info; short flags; int armies. That is 12 bytes.
        XCTAssertEqual(CLIENT_PACKET_SIZES[Int(ClientPacketType.planet.rawValue)], 12)
    }

    func testClientPacketTypesMatchSizeTable() {
        XCTAssertEqual(Set(ClientPacketType.allCases.map { Int($0.rawValue) }), Set(CLIENT_PACKET_SIZES.keys))
    }
}

final class ReadmeWireExampleTests: XCTestCase {

    /// The NetrekWire example in README.md.
    func testReadmeExample() {
        var packet = CP_SPEED(speed: 4)
        let data = Data(bytes: &packet, count: packet.size)
        XCTAssertEqual(Array(data), [2, 4, 0, 0])
    }
}
