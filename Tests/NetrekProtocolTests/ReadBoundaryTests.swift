//
//  ReadBoundaryTests.swift
//  NetrekProtocolTests
//
//  TCP hands the client bytes in whatever pieces it likes: a receive can
//  end anywhere, inside a packet or inside its header. COW 3.3.4 fixed two
//  bugs of this kind (netrek-client-cow 4de23bd): the rest of a split
//  packet written past the end of its buffer, and the header of a variable
//  size packet read before all of it had arrived. These tests check that
//  PacketAnalyzer gives the same packets however the stream is cut, and
//  that a variable size packet ends reading with a reason wherever the
//  receive ends inside it.
//

import XCTest
@testable import NetrekProtocol

/// A PacketAnalyzer that keeps every packet it frames.
final class RecordingAnalyzer: PacketAnalyzer {
    private(set) var packets: [Data] = []

    override func analyzeOnePacket(data: Data) {
        packets.append(data)
        super.analyzeOnePacket(data: data)
    }
}

/// Records everything the analyzer tells its delegate.
final class StreamDelegate: PacketAnalyzerDelegate {
    var gameState: GameState = .serverConnected
    var serverFeatures: [String] = []
    var states: [GameState] = []
    var receiveRequests = 0
    var unreadable: [UnreadablePacket] = []
    var masks: [UInt8] = []
    var outfitRefusals = 0

    func newGameState(_ state: GameState) {
        states.append(state)
        gameState = state
    }
    func triggerReceive() { receiveRequests += 1 }
    func updateTeamEligibility(mask: UInt8) { masks.append(mask) }
    func outfitRefused() { outfitRefusals += 1 }
    func packetStreamUnreadable(_ packet: UnreadablePacket) { unreadable.append(packet) }
}

/// One run of the analyzer over a stream, cut into receives.
struct StreamRun {
    let universe: Universe
    let delegate = StreamDelegate()
    let analyzer: RecordingAnalyzer

    /// A run with its own analyzer. Give it a universe to share when only
    /// the framing is checked: making thousands of universes is slow.
    init(universe: Universe = Universe()) {
        self.universe = universe
        analyzer = RecordingAnalyzer(delegate: delegate, universe: universe)
    }

    func feed<Chunks: Sequence>(_ chunks: Chunks) where Chunks.Element == Data {
        for chunk in chunks { analyzer.analyze(incomingData: chunk) }
    }

    /// What the stream did to the model, without timestamps.
    var model: [String] {
        var lines = ["me \(universe.me) queue \(universe.waitQueue)"]
        for player in universe.players {
            lines.append([
                "player \(player.playerId) \(player.name) \(player.login) \(player.monitor)",
                "\(player.team) \(String(describing: player.ship)) \(player.rank) \(player.slotStatus)",
                "at \(player.positionX),\(player.positionY) speed \(player.speed) dir \(player.direction)",
                "flags \(player.flags) tractor \(player.tractor) kills \(player.kills)",
                "fuel \(player.fuel) damage \(player.damage) armies \(player.armies)",
                "stats \(player.overallKills) \(player.tournamentKills) \(player.tournamentTicks)",
                "war \(player.war.sorted { $0.key.rawValue < $1.key.rawValue }.map { "\($0.key)\($0.value)" })",
            ].joined(separator: " "))
        }
        for planet in universe.planets {
            lines.append("planet \(planet.planetId) \(planet.name) at \(planet.positionX),\(planet.positionY) "
                         + "\(planet.owner) armies \(planet.armies) flags \(planet.flags)")
        }
        for torpedo in universe.torpedoes where torpedo.status != 0 || torpedo.positionX != 0 {
            lines.append("torp \(torpedo.torpedoId) \(torpedo.status) at \(torpedo.positionX),\(torpedo.positionY)")
        }
        for laser in universe.lasers where laser.status != 0 || laser.positionX != 0 {
            lines.append("laser \(laser.laserId) \(laser.status) at \(laser.positionX),\(laser.positionY) "
                         + "target \(laser.target)")
        }
        for plasma in universe.plasmas where plasma.status != 0 || plasma.positionX != 0 {
            lines.append("plasma \(plasma.plasmaId) \(plasma.status) at \(plasma.positionX),\(plasma.positionY)")
        }
        lines.append("ships \(universe.shipInfo.keys.map(\.rawValue).sorted())")
        lines += universe.messages.map { "message \($0)" }
        lines.append("states \(delegate.states) masks \(delegate.masks) refusals \(delegate.outfitRefusals)")
        lines.append("features \(delegate.serverFeatures) "
                     + "\(analyzer.serverFeatureValues.sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" })")
        lines.append("notice \(analyzer.lastServerNotice?.text ?? "none")")
        return lines
    }
}

final class ReadBoundaryTests: XCTestCase {

    private var stream: Data { ServerStream.bytes }

    private func drainMainQueue() {
        let expectation = XCTestExpectation(description: "main queue")
        DispatchQueue.main.async { expectation.fulfill() }
        wait(for: [expectation], timeout: 5.0)
    }

    /// The stream fed in one receive: the packets and model every other
    /// way of cutting it must give.
    private lazy var whole: StreamRun = {
        let run = StreamRun()
        run.feed([stream])
        drainMainQueue()
        return run
    }()

    // MARK: - The stream itself

    func testStream_IsReadWholeWithNothingLeftOver() {
        XCTAssertEqual(whole.analyzer.packets, ServerStream.packets, "every packet framed at its own bytes")
        XCTAssertEqual(whole.analyzer.bytesRead, stream.count)
        XCTAssertNil(whole.analyzer.leftOverData)
        XCTAssertTrue(whole.delegate.unreadable.isEmpty)
        XCTAssertEqual(whole.delegate.receiveRequests, 1)
        XCTAssertEqual(whole.delegate.states, [.serverSlotFound, .loginAccepted, .gameActive])
        XCTAssertEqual(Set(ServerStream.packets.map { $0[0] }),
                       [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
                        22, 23, 24, 25, 26, 32, 39, 60],
                       "every fixed size type a classic server sends in a login and play")
    }

    // MARK: - One cut, at every byte

    func testStream_CutAtEveryByte_GivesTheSamePackets() {
        let stream = self.stream
        let shared = Universe()
        for cut in 0...stream.count {
            let run = StreamRun(universe: shared)
            run.feed([stream.prefix(cut), stream.suffix(from: cut)])

            XCTAssertEqual(run.analyzer.packets.count, ServerStream.packets.count, "cut at \(cut)")
            XCTAssertEqual(run.analyzer.packets, ServerStream.packets, "cut at \(cut)")
            XCTAssertEqual(run.analyzer.bytesRead, stream.count, "cut at \(cut)")
            XCTAssertNil(run.analyzer.leftOverData, "cut at \(cut)")
            XCTAssertTrue(run.delegate.unreadable.isEmpty, "cut at \(cut)")
            XCTAssertEqual(run.delegate.receiveRequests, 2, "each receive asks for the next, cut at \(cut)")
            XCTAssertEqual(run.delegate.states, whole.delegate.states, "cut at \(cut)")
        }
    }

    func testStream_CutAtEveryByte_GivesTheSameModel() {
        let expected = whole.model
        // Every byte of the first 600 (the MOTD, features, SP_YOU and the
        // start of the galaxy), then every 7th byte: the model check
        // drains the main queue, which is slow to do thousands of times.
        let cuts = Array(0...600) + Array(stride(from: 601, through: stream.count, by: 7)) + [stream.count]
        for cut in cuts {
            let run = StreamRun()
            run.feed([stream.prefix(cut), stream.suffix(from: cut)])
            drainMainQueue()
            XCTAssertEqual(run.model, expected, "cut at \(cut)")
        }
    }

    // MARK: - Many cuts

    func testStream_OneByteAtATime() {
        let run = StreamRun()
        run.feed(stream.indices.map { stream[$0...$0] })
        drainMainQueue()

        XCTAssertEqual(run.analyzer.packets, ServerStream.packets)
        XCTAssertEqual(run.analyzer.bytesRead, stream.count)
        XCTAssertNil(run.analyzer.leftOverData)
        XCTAssertTrue(run.delegate.unreadable.isEmpty)
        XCTAssertEqual(run.delegate.receiveRequests, stream.count)
        XCTAssertEqual(run.model, whole.model)
    }

    func testStream_CutIntoRandomPieces() {
        var random = SeededRandom(seed: 315)
        for round in 0..<200 {
            var chunks: [Data] = []
            var start = 0
            while start < stream.count {
                let length = min(stream.count - start, random.next(upTo: round % 2 == 0 ? 40 : 700) + 1)
                // Rebased copies, as a receive hands them over, unlike the
                // slices of the other tests.
                chunks.append(Data(stream[start..<start + length]))
                start += length
            }
            let run = StreamRun()
            run.feed(chunks)

            XCTAssertEqual(run.analyzer.packets, ServerStream.packets, "round \(round)")
            XCTAssertTrue(run.delegate.unreadable.isEmpty, "round \(round)")
            XCTAssertEqual(run.delegate.receiveRequests, chunks.count, "round \(round)")
            if round % 20 == 0 {
                drainMainQueue()
                XCTAssertEqual(run.model, whole.model, "round \(round)")
            }
        }
    }

    func testStream_EmptyReceivesBetweenPieces_ChangeNothing() {
        let run = StreamRun()
        let cut = 100   // inside the second SP_MOTD
        run.feed([Data(), stream.prefix(cut), Data(), Data(), stream.suffix(from: cut), Data()])
        XCTAssertEqual(run.analyzer.packets, ServerStream.packets)
        XCTAssertEqual(run.delegate.receiveRequests, 6, "an empty receive still asks for more")
    }

    // MARK: - A receive that ends inside a fixed size packet

    func testEndingInsideAPacket_HoldsItAndAsksForTheRest() {
        // The biggest fixed packets: SP_LOGIN (104), SP_FEATURE (88) and
        // SP_MOTD (84). COW wrote the rest of one past its 1024 byte buffer.
        for packet in [ServerStream.login(accept: 1), ServerStream.feature("RC_DISTRESS", value: 1),
                       ServerStream.motd("hello")] {
            for held in 1..<packet.count {
                let run = StreamRun()
                run.feed([packet.prefix(held)])
                XCTAssertEqual(run.analyzer.leftOverData?.count, held)
                XCTAssertTrue(run.analyzer.packets.isEmpty)
                XCTAssertEqual(run.delegate.receiveRequests, 1, "it asks for the rest")
                XCTAssertTrue(run.delegate.unreadable.isEmpty)

                run.feed([packet.suffix(from: held)])
                XCTAssertEqual(run.analyzer.packets, [packet], "type \(packet[0]) held \(held)")
                XCTAssertNil(run.analyzer.leftOverData)
            }
        }
    }

    func testEndingInsideAPacket_WhenTheServerCloses_LeavesItUnread() {
        // A server that closes partway through a packet: the analyzer holds
        // the part and never reads it as a packet. TcpReader reports the
        // close itself (ConnectionEnd.serverClosed).
        let run = StreamRun()
        run.feed([stream.prefix(stream.count - 3)])
        XCTAssertEqual(run.analyzer.packets, Array(ServerStream.packets.dropLast()))
        XCTAssertEqual(run.analyzer.leftOverData?.count, 1)
        XCTAssertTrue(run.delegate.unreadable.isEmpty)
    }

    // MARK: - A receive that ends inside a variable size packet's header

    /// Each SP_S_* type sized -1, with a header a server might send. Their
    /// lengths come from header bytes (COW getvpsize): SP_S_MESSAGE byte 4,
    /// SP_S_WARNING byte 3, SP_S_PLAYER bytes 1 and 2, SP_S_TORP and
    /// SP_S_TORP_INFO bytes 1 and 3, SP_S_PLANET, SP_S_PHASER and
    /// SP_S_KILLS byte 1.
    static let shortPackets: [(name: String, bytes: [UInt8])] = [
        ("SP_S_MESSAGE", [41, 0x05, 1, 2, 24] + Array("F2->FED hello there".utf8)),
        ("SP_S_WARNING", [42, 0x29, 0, 9] + Array("hello".utf8)),
        ("SP_S_PLAYER", [45, 0x42, 1, 0, 3, 0x10, 0x20, 0x30, 0x40, 0x50, 0x60, 0x70]),
        ("SP_S_TORP", [47, 0x03, 2, 0, 0x11, 0x22, 0x33, 0x44, 0x55]),
        ("SP_S_TORP_INFO", [48, 0x01, 1, 0x01, 0x11, 0x22, 0x33, 0x44]),
        ("SP_S_PLANET", [50, 2, 0, 1, 0x0f, 3, 0, 0, 1, 2, 0x0f, 4, 0, 0]),
        ("SP_S_PHASER", [57, 0x01, 4, 0]),
        ("SP_S_KILLS", [58, 2, 0x01, 0x10, 0x02, 0x20]),
    ]

    func testShortPacketTypes_AreTheVariableSizeOnes() {
        let variable = (0..<PACKET_SIZES.count).filter { PACKET_SIZES[$0] < 0 }
        XCTAssertEqual(Self.shortPackets.map { Int($0.bytes[0]) }, variable,
                       "every variable size type is tested below")
    }

    func testShortPacketSplitAtEveryHeaderByte_EndsReadingWithAReason() {
        let before = ServerStream.packets.prefix(20).reduce(Data(), +)
        let after = PacketBuilder.gameplayBurst()
        for short in Self.shortPackets {
            // 0: the short packet starts the next receive. 1 to 5: the
            // receive ends inside its header (COW's bug: the length was
            // read from byte 4 before it had arrived).
            for cut in 0...min(5, short.bytes.count) {
                let run = StreamRun()
                let first = before + Data(short.bytes.prefix(cut))
                let second = Data(short.bytes.dropFirst(cut)) + after
                run.feed([first])
                let requestsAfterFirst = run.delegate.receiveRequests
                run.feed([second])

                let label = "\(short.name) cut \(cut)"
                XCTAssertEqual(run.delegate.unreadable.count, 1, label)
                guard let report = run.delegate.unreadable.first else { continue }
                XCTAssertEqual(report.packetType, short.bytes[0], label)
                XCTAssertEqual(report.reason, .variableLength, label)
                XCTAssertEqual(report.streamOffset, before.count, label)
                XCTAssertEqual(report.previousPacketType, ServerStream.packets[19][0], label)
                let seen = cut == 0 ? short.bytes.count + after.count : cut
                XCTAssertEqual(report.leadingBytes,
                               Array((Data(short.bytes) + after).prefix(min(seen, UnreadablePacket.leadingByteLimit))),
                               "the report shows what had arrived, \(label)")
                XCTAssertEqual(run.analyzer.packets, Array(ServerStream.packets.prefix(20)),
                               "packets before it are read, none after, \(label)")
                XCTAssertEqual(run.analyzer.bytesRead, before.count, label)
                if cut > 0 {
                    XCTAssertEqual(requestsAfterFirst, 0, "a stopped reader asks for nothing, \(label)")
                }
                XCTAssertEqual(run.delegate.receiveRequests, cut > 0 ? 0 : 1,
                               "nothing is asked for once reading stops, \(label)")
                XCTAssertEqual(run.analyzer.unreadable, report, label)
            }
        }
    }

    func testShortPacketHeader_ItsLengthIsNeverTrusted() {
        // SP_S_MESSAGE's length byte (byte 4): zero, smaller than the
        // header, the header itself, longer than what came, and longer
        // than any real packet. None of them is used: the type alone ends
        // reading, so no length can move the reader or make it read past
        // what arrived. COW reported "Bad short-packet size value (0)" and
        // lost its place.
        for length: UInt8 in [0, 1, 3, 4, 5, 6, 84, 200, 255] {
            for arrived in 1...6 {
                let packet: [UInt8] = [41, 0x05, 1, 2, length, 0x41]
                let run = StreamRun()
                run.feed([ServerStream.pstatus(slot: 1, status: 2) + Data(packet.prefix(arrived))])
                XCTAssertEqual(run.delegate.unreadable.map(\.reason), [.variableLength],
                               "length \(length) arrived \(arrived)")
                XCTAssertEqual(run.delegate.unreadable.first?.leadingBytes, Array(packet.prefix(arrived)))
                XCTAssertEqual(run.analyzer.bytesRead, 4)
                XCTAssertEqual(run.delegate.receiveRequests, 0)
                XCTAssertNil(run.analyzer.leftOverData, "nothing is held for a length that may never come")
            }
        }
    }
}

/// SplitMix64, so the random pieces are the same on every run and machine.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        return z ^ (z >> 31)
    }

    /// 0 to `bound` - 1.
    mutating func next(upTo bound: Int) -> Int { Int(next() % UInt64(bound)) }

    mutating func byte() -> UInt8 { UInt8(truncatingIfNeeded: next()) }
}
