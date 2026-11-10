//
//  MalformedPacketTests.swift
//  NetrekProtocolTests
//
//  What a server, or anything between it and the client, can send that a
//  well-behaved server never would: short packets (SP_S_*) the client never
//  asked for, counts and slots past the end of the model, type bytes the
//  table doesn't size, and fixed size packets full of hostile bytes. COW
//  3.3.4 fixed crashes of this kind in short.c (netrek-client-cow fb322e7,
//  CVE-2026-121968 and CVE-2026-121969). Nothing here may crash, read past
//  a packet, or move the reader off the packet boundaries; anything the
//  analyzer can't size ends reading with a reason (packetStreamUnreadable).
//

import XCTest
@testable import NetrekProtocol

final class MalformedPacketTests: XCTestCase {

    private func drainMainQueue() {
        let expectation = XCTestExpectation(description: "main queue")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 30.0)
    }

    /// Nothing a test queued for the model is left for the next test.
    override func tearDown() {
        drainMainQueue()
        super.tearDown()
    }

    /// A packet the tests put after a bad one: if it is read as itself,
    /// the reader is still on the packet boundaries.
    private var marker: Data { ServerStream.pstatus(slot: 9, status: 2) }

    /// The classic sizes (include/packets.h) of the short packet types that
    /// have a fixed size.
    private static let fixedShortPackets: [(name: String, type: UInt8, size: Int)] = [
        ("SP_S_REPLY", 40, 8), ("SP_S_YOU", 43, 12), ("SP_S_YOU_SS", 44, 12),
        ("SP_PING", 46, 8), ("SP_S_8_TORP", 49, 20), ("SP_S_STATS", 59, 36),
    ]

    // MARK: - Short packets the client never asked for

    func testFixedSizeShortPackets_AreReadAtTheirClassicSizeAndIgnored() {
        for short in Self.fixedShortPackets {
            XCTAssertEqual(PACKET_SIZES[Int(short.type)], short.size, short.name)
            for fill: UInt8 in [0x00, 0xff, 0x80] {
                var bytes = [UInt8](repeating: fill, count: short.size)
                bytes[0] = short.type
                let run = StreamRun()
                run.feed([marker + Data(bytes) + marker])
                drainMainQueue()

                XCTAssertEqual(run.analyzer.packets, [marker, Data(bytes), marker], "\(short.name) fill \(fill)")
                XCTAssertTrue(run.delegate.unreadable.isEmpty, short.name)
                XCTAssertEqual(run.universe.me, 0, "an unasked SP_S_YOU sets nothing, \(short.name)")
                XCTAssertEqual(run.universe.players.count, run.universe.maxPlayers, short.name)
            }
        }
    }

    func testShortPacketMidGame_EndsReadingAfterTheGoodPackets() {
        for short in ReadBoundaryTests.shortPackets {
            let run = StreamRun()
            let burst = PacketBuilder.gameplayBurst()
            run.feed([burst + Data(short.bytes) + PacketBuilder.spPlayer(playerId: 1, positionX: 1000)])
            drainMainQueue()

            XCTAssertEqual(run.analyzer.bytesRead, burst.count, short.name)
            XCTAssertEqual(run.delegate.unreadable.map(\.packetType), [short.bytes[0]], short.name)
            XCTAssertEqual(run.delegate.unreadable.first?.previousPacketType, 6, "after SP_TORP, \(short.name)")
            XCTAssertNotEqual(run.universe.players[1].positionX, NetrekMath.netrekX2GameX(1000),
                              "nothing after the short packet is applied, \(short.name)")
        }
    }

    func testShortPacketsWithHostileCounts_AreNeverFollowed() {
        // Counts and slots set as high as a byte goes: SP_S_PLAYER with 63
        // players and the extended header bits, SP_S_TORP and SP_S_TORP_INFO
        // with all eight torpedoes, SP_S_PLANET with 255 planets, SP_S_KILLS
        // with 255 players, SP_S_PHASER with an unknown status, SP_S_WARNING
        // with the text and a length of 0 and 255, and SP_S_MESSAGE to slot
        // 255 (COW's fb322e7 fixed a read of players[255] for that) with a
        // length of 0 and 255. None of them is parsed: each ends reading.
        let hostile: [[UInt8]] = [
            [45, 0xff, 0xff, 0xff], [45, 0x7f, 0xff, 0xff], [45, 0x3f, 0xff],
            [47, 0xff, 0xff, 0xff], [48, 0xff, 0xff, 0xff], [50, 0xff], [58, 0xff],
            [57, 0x0f, 0xff, 0xff], [57, 0xff],
            [42, 0x29, 0, 0], [42, 0x29, 0, 255], [42, 0x2a, 0xff, 0xff],
            [41, MessageFlag.individual | MessageFlag.valid, 255, 255, 0],
            [41, MessageFlag.individual | MessageFlag.valid, 255, 255, 255] + [UInt8](repeating: 0x41, count: 40),
            [41, MessageFlag.relayedTeamDistress, 255, 255, 5, 0xff],
        ]
        for bytes in hostile {
            let run = StreamRun()
            run.feed([marker + Data(bytes)])
            drainMainQueue()

            XCTAssertEqual(run.delegate.unreadable.map(\.reason), [.variableLength], "\(bytes.prefix(6))")
            XCTAssertEqual(run.analyzer.bytesRead, marker.count)
            XCTAssertEqual(run.analyzer.packets, [marker])
            XCTAssertNil(run.analyzer.leftOverData)
            XCTAssertTrue(run.universe.messages.isEmpty, "no text is taken from it")
        }
    }

    func testShortSequence_IsUnused() {
        // SP_S_SEQUENCE: COW and the server give it no size either.
        let run = StreamRun()
        run.feed([marker + Data([56, 0, 0, 1])])
        XCTAssertEqual(run.delegate.unreadable.map(\.reason), [.unusedType])
    }

    // MARK: - Type bytes

    func testEveryTypeByte_WaitsForItsSizeOrEndsReadingWithAReason() {
        for type in 0...255 {
            let run = StreamRun()
            run.feed([Data([UInt8(type)])])
            let size = PACKET_SIZES[safe: type]
            if let size, size > 0 {
                XCTAssertTrue(run.delegate.unreadable.isEmpty, "type \(type)")
                XCTAssertEqual(run.analyzer.leftOverData?.count, 1, "type \(type) waits for the rest")
                XCTAssertEqual(run.delegate.receiveRequests, 1, "type \(type)")
            } else {
                let expected: UnreadablePacket.Reason = size == nil ? .unknownType
                    : size == 0 ? .unusedType : .variableLength
                XCTAssertEqual(run.delegate.unreadable.map(\.reason), [expected], "type \(type)")
                XCTAssertEqual(run.delegate.receiveRequests, 0, "type \(type)")
                XCTAssertNil(run.analyzer.leftOverData, "type \(type)")
            }
        }
    }

    func testTypesPastTheTable_AreUnknown() {
        XCTAssertEqual(PACKET_SIZES.count, 63, "SP_LTD, type 62, is the last classic type")
        for type in 63...255 {
            let run = StreamRun()
            run.feed([marker + Data([UInt8(type), 1, 2, 3])])
            XCTAssertEqual(run.delegate.unreadable.map(\.reason), [.unknownType], "type \(type)")
            XCTAssertEqual(run.delegate.unreadable.first?.streamOffset, 4)
            XCTAssertEqual(run.analyzer.packets, [marker])
        }
    }

    // MARK: - SP_RANK and SP_LTD, the last classic types

    func testRank_IsReadAtItsClassicSize() {
        // struct rank_spacket: type, rnum, rmax, pad, name[16], hours,
        // ratings, offense, cname[8]: 40 bytes. The table had 524 here (an
        // SP_BITMAP that is no classic packet), so the reader took the next
        // 484 bytes of other packets as part of this one and lost its place
        // without a word. A server sends SP_RANK to a client that asks.
        let rank = WirePacket(type: 61, size: 40).u8(1, 3).u8(2, 9).text(4, "Commander", length: 16)
            .u32(20, 800).u32(24, 300).u32(28, 200)
            .text(32, "Cdr", length: 8)
        let after = Array(ServerStream.packets.suffix(60))
        XCTAssertGreaterThan(after.reduce(0) { $0 + $1.count }, 524 - 40)

        let run = StreamRun()
        run.feed([rank.data + after.reduce(Data(), +)])

        XCTAssertEqual(run.analyzer.packets, [rank.data] + after)
        XCTAssertTrue(run.delegate.unreadable.isEmpty)
        XCTAssertNil(run.analyzer.leftOverData)
    }

    func testLtd_IsReadAtItsClassicSize() {
        // struct ltd_spacket: 324 bytes, the biggest classic packet. It
        // was past the end of the table, so it ended reading as unknown.
        var ltd = WirePacket(type: 62, size: 324).u8(1, UInt8(ascii: "a"))
        for offset in stride(from: 4, to: 324, by: 4) { ltd = ltd.u32(offset, UInt32(offset)) }

        let run = StreamRun()
        run.feed([ltd.data + marker])

        XCTAssertEqual(run.analyzer.packets, [ltd.data, marker])
        XCTAssertTrue(run.delegate.unreadable.isEmpty)
    }

    func testRankAndLtd_AreIgnoredWithoutTheDefaultCaseDump() {
        // Both are read and ignored on purpose, so they get a case of their
        // own. The default case dumps every byte of the packet to the log,
        // in release builds too (debugPrint), and calls it unhandled.
        let rank = WirePacket(type: 61, size: 40).data
        let ltd = WirePacket(type: 62, size: 324).data
        let reserved = WirePacket(type: 25, size: 20).data  // SP_RESERVED, has no case

        let run = StreamRun()
        run.feed([rank + ltd + reserved + marker])

        XCTAssertEqual(run.analyzer.packets, [rank, ltd, reserved, marker])
        XCTAssertFalse(run.analyzer.unhandledPacketTypes.contains(61), "SP_RANK")
        XCTAssertFalse(run.analyzer.unhandledPacketTypes.contains(62), "SP_LTD")
        XCTAssertTrue(run.analyzer.unhandledPacketTypes.contains(25), "the default case is still recorded")
    }

    func testTheBiggestPacket_BoundsWhatIsHeldBetweenReceives() {
        XCTAssertEqual(PACKET_SIZES.max(), 324, "SP_LTD")
        let ltd = WirePacket(type: 62, size: 324).data
        let run = StreamRun()
        run.feed([ltd.prefix(323)])
        XCTAssertEqual(run.analyzer.leftOverData?.count, 323)
        run.feed([ltd.suffix(1) + marker])
        XCTAssertEqual(run.analyzer.packets, [ltd, marker])
    }

    // MARK: - Fixed size packets with hostile bytes

    func testEveryFixedType_WithHostileBytes_NeitherCrashesNorLosesItsPlace() {
        var random = SeededRandom(seed: 121_968)
        for type in 0..<PACKET_SIZES.count where PACKET_SIZES[type] > 0 {
            let size = PACKET_SIZES[type]
            var bodies: [[UInt8]] = [0x00, 0xff, 0x80, 0x7f, 0x01].map { [UInt8](repeating: $0, count: size) }
            for _ in 0..<24 { bodies.append((0..<size).map { _ in random.byte() }) }
            // Each field at its highest with the rest zero.
            for spot in 1..<size {
                var body = [UInt8](repeating: 0, count: size)
                body[spot] = 0xff
                bodies.append(body)
            }
            for expands in [false, true] {
                let run = StreamRun()
                run.analyzer.expandsDistressCalls = expands
                run.delegate.gameState = .serverConnected
                var stream = Data()
                for var body in bodies {
                    body[0] = UInt8(type)
                    stream += Data(body) + marker
                }
                run.feed([stream])
                drainMainQueue()

                XCTAssertEqual(run.analyzer.packets.count, bodies.count * 2, "type \(type)")
                XCTAssertEqual(run.analyzer.bytesRead, stream.count, "type \(type)")
                XCTAssertTrue(run.delegate.unreadable.isEmpty, "type \(type)")
                XCTAssertEqual(run.universe.players.count, run.universe.maxPlayers, "type \(type)")
                XCTAssertEqual(run.universe.planets.count, run.universe.maxPlanets, "type \(type)")
            }
        }
    }

    func testStats_ForASlotPastTheLastPlayer_IsIgnored() {
        // SP_STATS was the one player packet without a slot check:
        // Universe.updatePlayer(playerID:...) stored a new Player at
        // players[slot], which is out of range from slot 32 on.
        for slot: UInt8 in [32, 99, 255] {
            let run = StreamRun()
            run.feed([ServerStream.stats(slot: slot, kills: 5) + marker])
            drainMainQueue()

            XCTAssertEqual(run.analyzer.packets.count, 2, "slot \(slot)")
            XCTAssertEqual(run.universe.players.count, run.universe.maxPlayers, "slot \(slot)")
            XCTAssertTrue(run.universe.players.allSatisfy { $0.overallKills == 0 }, "slot \(slot)")
        }
    }

    func testStats_ForARealSlot_StillCounts() {
        let run = StreamRun()
        run.feed([ServerStream.stats(slot: 31, kills: 5)])
        XCTAssertEqual(run.universe.players[31].overallKills, 10)
    }

    func testGeneric32_NotOrbitingWithALongRepair_DoesNotCrash() {
        // generic_32_spacket_b: pl_orbit is byte 4, a signed char that is
        // -1 when not orbiting. The analyzer read it from byte 3, the low
        // byte of repair_time, with Int8(_:), which traps from 128 up: a
        // repair time of 128 to 255 seconds (or 384 to 511, and so on)
        // crashed the client. A server sends SP_GENERIC_32 to a client
        // that asks for it.
        for (repair, orbit) in [(200, -1), (128, 0), (0x01ff, -1), (0, -128), (0xffff, 127)] as [(UInt16, Int8)] {
            let run = StreamRun()
            run.feed([ServerStream.generic32(repairTime: repair, orbit: orbit) + marker])
            XCTAssertEqual(run.analyzer.packets.count, 2, "repair \(repair) orbit \(orbit)")
        }
    }

    func testMessage_ToAndFromSlotsPastTheLastPlayer() {
        // SP_MESSAGE's own m_recpt and m_from, the fixed size twin of
        // COW's SP_S_MESSAGE crash: an individual message to slot 255, and
        // an RCD call from slot 255 with every body byte at 255.
        let messages = [
            ServerStream.message(flags: MessageFlag.individual | MessageFlag.valid, recipient: 255, from: 254,
                                 text: "to nobody"),
            ServerStream.message(flags: MessageFlag.relayedTeamDistress, recipient: 255, from: 255,
                                 body: [UInt8](repeating: 0x20, count: 10) + [UInt8](repeating: 0xff, count: 69)),
            ServerStream.message(flags: MessageFlag.relayedTeamDistress, recipient: 1, from: 200,
                                 body: Array(ServerStream.distress(from: 1)[4...])),
        ]
        for expands in [false, true] {
            let run = StreamRun()
            run.analyzer.expandsDistressCalls = expands
            run.feed([messages.reduce(Data(), +) + marker])
            drainMainQueue()
            XCTAssertEqual(run.analyzer.packets, messages + [marker], "expands \(expands)")
        }
    }

    // MARK: - analyzeOnePacket called on its own

    func testAnalyzeOnePacket_IgnoresAnythingNotOneWholePacket() {
        let run = StreamRun()
        let pstatus = ServerStream.pstatus(slot: 1, status: 2)
        for data in [Data(), pstatus.prefix(3), pstatus + Data([0]), Data([200, 1, 2, 3]),
                     Data([41, 5, 1, 2, 0]), Data([0, 0, 0, 0])] {
            run.analyzer.analyzeOnePacket(data: data)
        }
        drainMainQueue()
        XCTAssertEqual(run.universe.players[1].slotStatus, .free, "none of them was applied")

        run.analyzer.analyzeOnePacket(data: pstatus)
        drainMainQueue()
        XCTAssertEqual(run.universe.players[1].slotStatus, .alive, "a whole packet is")
    }
}
