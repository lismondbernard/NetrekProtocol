//
//  StreamFailureTests.swift
//  NetrekProtocolTests
//
//  The client must never stop reading the server without saying so. Before
//  this, a packet type the analyzer could not size, the server closing the
//  connection, and a failed receive all ended reading in silence: the game
//  froze on the last frame and nothing changed state.
//

import XCTest
@testable import NetrekProtocol

/// Records what the analyzer reports, including an unreadable stream.
private final class FailureRecordingDelegate: PacketAnalyzerDelegate {
    var gameState: GameState = .gameActive
    var serverFeatures: [String] = []
    var receiveRequests = 0
    var unreadable: [UnreadablePacket] = []

    func newGameState(_ state: GameState) { gameState = state }
    func triggerReceive() { receiveRequests += 1 }
    func updateTeamEligibility(mask: UInt8) {}
    func outfitRefused() {}
    func packetStreamUnreadable(_ packet: UnreadablePacket) { unreadable.append(packet) }
}

/// Implements only what the protocol required before, so it relies on the
/// default `packetStreamUnreadable`.
private final class OlderAnalyzerDelegate: PacketAnalyzerDelegate {
    var gameState: GameState = .gameActive
    var serverFeatures: [String] = []
    var receiveRequests = 0
    var states: [GameState] = []
    func newGameState(_ state: GameState) { states.append(state) }
    func triggerReceive() { receiveRequests += 1 }
    func updateTeamEligibility(mask: UInt8) {}
    func outfitRefused() {}
}

final class StreamFailureTests: XCTestCase {

    private var universe: Universe!
    private var delegate: FailureRecordingDelegate!
    private var analyzer: PacketAnalyzer!

    override func setUp() {
        super.setUp()
        universe = Universe()
        delegate = FailureRecordingDelegate()
        analyzer = PacketAnalyzer(delegate: delegate, universe: universe)
    }

    override func tearDown() {
        analyzer = nil
        delegate = nil
        universe = nil
        super.tearDown()
    }

    // MARK: - Types the analyzer cannot size

    func testUnknownType_IsReportedWithWhereItWas() {
        var bytes = PacketBuilder.spPstatus(playerId: 1, status: 2)   // 4 bytes, type 20
        bytes.append(contentsOf: [200, 1, 2, 3, 4])

        analyzer.analyze(incomingData: bytes)

        XCTAssertEqual(delegate.unreadable.count, 1, "an unknown type must be reported, not dropped")
        let packet = try! XCTUnwrap(delegate.unreadable.first)
        XCTAssertEqual(packet.packetType, 200)
        XCTAssertEqual(packet.reason, .unknownType)
        XCTAssertEqual(packet.streamOffset, 4, "the four bytes of SP_PSTATUS came first")
        XCTAssertEqual(packet.previousPacketType, 20)
        XCTAssertEqual(packet.leadingBytes, [200, 1, 2, 3, 4])
        XCTAssertEqual(analyzer.unreadable, packet)
    }

    func testUnusedType_SizeZero_IsReported() {
        XCTAssertEqual(PACKET_SIZES[33], 0, "the test needs a type the table marks unused")

        analyzer.analyze(incomingData: Data([33, 0, 0, 0, 0, 0, 0, 0]))

        XCTAssertEqual(delegate.unreadable.map(\.reason), [.unusedType])
        XCTAssertEqual(delegate.unreadable.first?.packetType, 33)
        XCTAssertEqual(delegate.unreadable.first?.streamOffset, 0)
        XCTAssertNil(delegate.unreadable.first?.previousPacketType)
    }

    func testVariableLengthType_SizeMinusOne_IsReported() {
        XCTAssertEqual(PACKET_SIZES[47], -1, "the test needs a short packet (SP_S_TORP)")

        analyzer.analyze(incomingData: Data([47, 9, 9, 9]))

        XCTAssertEqual(delegate.unreadable.map(\.reason), [.variableLength])
        XCTAssertEqual(delegate.unreadable.first?.packetType, 47)
    }

    func testTypeZero_IsReportedAsUnused() {
        analyzer.analyze(incomingData: Data([0, 0, 0, 0]))
        XCTAssertEqual(delegate.unreadable.map(\.reason), [.unusedType])
    }

    func testLeadingBytes_AreCappedAtSixteen() {
        analyzer.analyze(incomingData: Data([200] + [UInt8](repeating: 7, count: 40)))
        XCTAssertEqual(delegate.unreadable.first?.leadingBytes.count, UnreadablePacket.leadingByteLimit)
        XCTAssertEqual(UnreadablePacket.leadingByteLimit, 16)
    }

    func testStreamOffset_CountsEveryEarlierReceive() {
        analyzer.analyze(incomingData: PacketBuilder.spPstatus(playerId: 1, status: 2))
        analyzer.analyze(incomingData: PacketBuilder.spPickok(state: 1))
        analyzer.analyze(incomingData: Data([200, 0, 0, 0]))

        XCTAssertEqual(delegate.unreadable.first?.streamOffset, 8)
        XCTAssertEqual(delegate.unreadable.first?.previousPacketType, 16)
    }

    func testPacketsBeforeTheBadOne_AreStillApplied() {
        var bytes = PacketBuilder.spPstatus(playerId: 3, status: 2)
        bytes.append(contentsOf: [200, 0, 0, 0])

        analyzer.analyze(incomingData: bytes)

        XCTAssertEqual(analyzer.bytesRead, 4)
        XCTAssertEqual(delegate.unreadable.count, 1)
    }

    func testAfterAFailure_TheAnalyzerReadsNoMore() {
        analyzer.analyze(incomingData: Data([200, 0, 0, 0]))
        let requestsAtFailure = delegate.receiveRequests

        analyzer.analyze(incomingData: PacketBuilder.spPstatus(playerId: 1, status: 2))

        XCTAssertEqual(delegate.unreadable.count, 1, "reported once")
        XCTAssertEqual(delegate.receiveRequests, requestsAtFailure,
                       "bytes after a lost place in the stream are garbage, so don't ask for more")
        XCTAssertEqual(analyzer.bytesRead, 0)
    }

    func testDescription_NamesTypeOffsetAndBytes() {
        let packet = UnreadablePacket(packetType: 47, reason: .variableLength, streamOffset: 1234,
                                      previousPacketType: 4, leadingBytes: [0x2f, 0x01, 0xff])
        XCTAssertEqual(packet.description,
                       "unreadable packet type 47 (variable length) at stream offset 1234, after type 4, bytes: 2f 01 ff")
    }

    func testDefaultImplementation_LeavesTheServer() {
        // A delegate written before packetStreamUnreadable must not freeze
        // in silence: the default ends the session the way a client does.
        let older = OlderAnalyzerDelegate()
        let analyzer = PacketAnalyzer(delegate: older, universe: universe)

        analyzer.analyze(incomingData: Data([200, 0, 0, 0]))

        XCTAssertNotNil(analyzer.unreadable, "the analyzer still records it")
        XCTAssertEqual(older.receiveRequests, 0)
        XCTAssertEqual(older.states, [.noServerSelected])
    }

    // MARK: - A local server: drop the batch and keep reading

    func testDropBatchPolicy_DropsTheRestAndReadsTheNextBatch() {
        analyzer.unreadablePolicy = .dropBatch
        var bad = PacketBuilder.spPstatus(playerId: 1, status: 2)
        bad.append(contentsOf: [200, 1, 2, 3])
        bad.append(PacketBuilder.spPstatus(playerId: 2, status: 2))

        analyzer.analyze(incomingData: bad)

        XCTAssertNil(analyzer.unreadable, "the stream is still readable")
        XCTAssertTrue(delegate.unreadable.isEmpty, "nothing to leave: the next batch starts on a packet")
        XCTAssertEqual(analyzer.droppedBatches, 1)
        XCTAssertEqual(analyzer.bytesRead, 4, "the packet before the bad one was read; the rest was dropped")
        XCTAssertEqual(delegate.receiveRequests, 1, "it asks for more")

        analyzer.analyze(incomingData: PacketBuilder.spPstatus(playerId: 3, status: 2))

        XCTAssertEqual(analyzer.bytesRead, 8, "the next batch is read as normal")
        XCTAssertEqual(delegate.receiveRequests, 2)
    }

    func testDropBatchPolicy_ForgetsAPartialPacket() {
        analyzer.unreadablePolicy = .dropBatch
        analyzer.analyze(incomingData: Data([200]))
        analyzer.analyze(incomingData: PacketBuilder.spPstatus(playerId: 1, status: 2))
        XCTAssertEqual(analyzer.bytesRead, 4)
        XCTAssertEqual(analyzer.droppedBatches, 1)
    }

    func testDefaultPolicy_StopsReading() {
        XCTAssertEqual(PacketAnalyzer(delegate: delegate, universe: universe).unreadablePolicy, .stopReading)
    }

    // MARK: - The server's last words

    func testWarning_IsKeptAsTheLastServerNotice() {
        XCTAssertNil(analyzer.lastServerNotice)
        let before = Date()

        analyzer.analyze(incomingData: Self.spWarning("Server is shutting down"))

        XCTAssertEqual(analyzer.lastServerNotice?.text, "Server is shutting down")
        XCTAssertGreaterThanOrEqual(analyzer.lastServerNotice?.receivedAt ?? .distantPast, before)
    }

    func testWarning_GoesThroughTheTextFilter() {
        analyzer.textFilter = { $0.uppercased() }
        analyzer.analyze(incomingData: Self.spWarning("ghostbusted"))
        XCTAssertEqual(analyzer.lastServerNotice?.text, "GHOSTBUSTED")
    }

    func testBadVersion_ReadsWhyFromTheSecondByte() {
        // struct badversion_spacket { char type; char why; char pad2, pad3; }
        analyzer.analyze(incomingData: Data([21, 0, 9, 9]))
        XCTAssertEqual(analyzer.lastServerNotice?.text, "The server does not accept this client version.")

        analyzer.analyze(incomingData: Data([21, 1, 0, 0]))
        XCTAssertEqual(analyzer.lastServerNotice?.text, "The server is not taking players now. Try again later.")
    }

    func testLaterWarning_ReplacesTheEarlierOne() {
        analyzer.analyze(incomingData: Self.spWarning("one") + Self.spWarning("two"))
        XCTAssertEqual(analyzer.lastServerNotice?.text, "two")
    }

    /// SP_WARNING: type 10, three pad bytes, 80 bytes of text.
    private static func spWarning(_ text: String) -> Data {
        var data = Data([10, 0, 0, 0])
        var body = Data(text.utf8.prefix(79))
        body.append(Data(repeating: 0, count: 80 - body.count))
        data.append(body)
        return data
    }

    // MARK: - Reading continues where it should

    func testSplitPacket_KeepsReading() {
        let whole = PacketBuilder.spPstatus(playerId: 2, status: 2)

        analyzer.analyze(incomingData: whole.prefix(2))
        XCTAssertEqual(delegate.receiveRequests, 1, "half a packet asks for the rest")
        XCTAssertTrue(delegate.unreadable.isEmpty)

        analyzer.analyze(incomingData: whole.suffix(2))
        XCTAssertEqual(delegate.receiveRequests, 2, "the finished packet asks for the next")
        XCTAssertTrue(delegate.unreadable.isEmpty)
        XCTAssertEqual(analyzer.bytesRead, 4)
    }

    func testSplitHeaderOfAnUnknownType_IsReportedWhenItArrives() {
        analyzer.analyze(incomingData: PacketBuilder.spPstatus(playerId: 2, status: 2).prefix(3))
        analyzer.analyze(incomingData: Data([0, 200, 1]))

        XCTAssertEqual(delegate.unreadable.first?.packetType, 200)
        XCTAssertEqual(delegate.unreadable.first?.streamOffset, 4)
    }

    func testEveryReadableBatch_AsksForMore() {
        analyzer.analyze(incomingData: PacketBuilder.gameplayBurst())
        XCTAssertEqual(delegate.receiveRequests, 1)
        XCTAssertTrue(delegate.unreadable.isEmpty)
    }

    func testEmptyReceive_AsksForMore() {
        analyzer.analyze(incomingData: Data())
        XCTAssertEqual(delegate.receiveRequests, 1)
    }
}

// MARK: - The reader's decision after each receive

final class ReceiveStepTests: XCTestCase {

    func testBytes_AreHandedOnAndTheAnalyzerAsksForMore() {
        XCTAssertEqual(ReceiveStep.after(byteCount: 120, isComplete: false, errorDescription: nil), .handedOn)
    }

    func testNothingAtAll_ReceivesAgain() {
        XCTAssertEqual(ReceiveStep.after(byteCount: 0, isComplete: false, errorDescription: nil), .receiveAgain)
    }

    func testComplete_MeansTheServerClosed() {
        XCTAssertEqual(ReceiveStep.after(byteCount: 0, isComplete: true, errorDescription: nil), .end(.serverClosed))
        XCTAssertEqual(ReceiveStep.after(byteCount: 84, isComplete: true, errorDescription: nil), .end(.serverClosed),
                       "last bytes and the close can come together; the bytes still go first")
    }

    func testError_EndsWithItsDescription() {
        XCTAssertEqual(ReceiveStep.after(byteCount: 0, isComplete: false, errorDescription: "POSIX 54"),
                       .end(.receiveFailed("POSIX 54")))
    }

    func testError_WinsOverComplete() {
        XCTAssertEqual(ReceiveStep.after(byteCount: 0, isComplete: true, errorDescription: "POSIX 54"),
                       .end(.receiveFailed("POSIX 54")))
    }
}

// MARK: - The default for delegates written before connectionEnded

final class ConnectionEndedDefaultTests: XCTestCase {

    private final class OlderNetworkDelegate: NetworkDelegateExtended {
        var states: [Bool] = []
        func gotData(data: Data, from: String, port: Int) {}
        func connectionStateChanged(connected: Bool) { states.append(connected) }
    }

    func testDefault_ReportsADisconnect() {
        let delegate = OlderNetworkDelegate()
        delegate.connectionEnded(.serverClosed)
        XCTAssertEqual(delegate.states, [false])
    }
}
