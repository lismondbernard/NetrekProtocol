//
//  ReaderEndsTests.swift
//  NetrekProtocolTests
//
//  How a TcpReader reports the end of its connection (SSS-311). Its
//  callbacks run on a concurrent queue, so the state events and the last
//  receive can come in any order. Whatever the order, the end is reported
//  once, a reason is never lost, and an end the client asked for is not
//  reported at all.
//

import XCTest
@testable import NetrekProtocol

final class ReaderEndsTests: XCTestCase {

    // MARK: - Ends the client asked for

    func testAfterResetConnection_TheCancelledStateIsNotReported() {
        let ends = ReaderEnds()
        ends.clientClosed()
        XCTAssertNil(ends.report(.cancelled),
                     "a disconnect the client made is not news; reporting it ran the client's leave twice")
    }

    func testAfterResetConnection_TheWaitingReceiveIsNotReported() {
        let ends = ReaderEnds()
        ends.clientClosed()
        XCTAssertNil(ends.report(.receiveEnded(.receiveFailed("POSIX 89"))))
        XCTAssertNil(ends.report(.cancelled))
    }

    func testAfterResetConnection_AFailureIsNotReported() {
        let ends = ReaderEnds()
        ends.clientClosed()
        XCTAssertNil(ends.report(.failed("POSIX 54")))
    }

    // MARK: - The race between a failed state and the failing receive

    func testFailedStateFirst_StillGivesTheReason() {
        let ends = ReaderEnds()
        XCTAssertEqual(ends.report(.failed("POSIX 54")), .ended(.connectionFailed("POSIX 54")))
        XCTAssertNil(ends.report(.receiveEnded(.receiveFailed("POSIX 54"))), "once only")
        XCTAssertNil(ends.report(.cancelled))
    }

    func testFailingReceiveFirst_GivesItsReason() {
        let ends = ReaderEnds()
        XCTAssertEqual(ends.report(.receiveEnded(.receiveFailed("POSIX 54"))),
                       .ended(.receiveFailed("POSIX 54")))
        XCTAssertNil(ends.report(.failed("POSIX 54")), "once only")
    }

    func testServerClose_ThenOurCancel_ReportsTheCloseOnly() {
        let ends = ReaderEnds()
        XCTAssertEqual(ends.report(.receiveEnded(.serverClosed)), .ended(.serverClosed))
        XCTAssertNil(ends.report(.cancelled))
    }

    func testCancelledWithNoReasonGiven_IsADisconnect() {
        // Someone else cancelled the public connection.
        let ends = ReaderEnds()
        XCTAssertEqual(ends.report(.cancelled), .disconnected)
        XCTAssertNil(ends.report(.cancelled))
    }

    func testRacingReports_OnlyOneWins() {
        let ends = ReaderEnds()
        let lock = NSLock()
        var reports: [ReaderEnds.Report] = []
        DispatchQueue.concurrentPerform(iterations: 200) { index in
            let event: ReaderEnds.Event = index.isMultiple(of: 2)
                ? .failed("e\(index)") : .receiveEnded(.receiveFailed("e\(index)"))
            if let report = ends.report(event) {
                lock.lock(); reports.append(report); lock.unlock()
            }
        }
        XCTAssertEqual(reports.count, 1)
        if case .ended = reports.first {} else { XCTFail("the winner carries a reason: \(reports)") }
    }

    // MARK: - complete, read from main and written on the connection's queue

    func testComplete_StartsFalseAndSticks() {
        let ends = ReaderEnds()
        XCTAssertFalse(ends.isComplete)
        _ = ends.report(.receiveEnded(.serverClosed))
        XCTAssertTrue(ends.isComplete)
    }

    func testComplete_IsSetEvenWhenTheEndIsNotReported() {
        let ends = ReaderEnds()
        ends.clientClosed()
        _ = ends.report(.receiveEnded(.receiveFailed("POSIX 89")))
        XCTAssertTrue(ends.isComplete, "no more receives after the last one ended")
    }

    func testComplete_ReadAndWrittenFromManyThreads() {
        // Run under the thread sanitizer this would flag an unguarded flag.
        let ends = ReaderEnds()
        DispatchQueue.concurrentPerform(iterations: 100) { index in
            if index == 50 { _ = ends.report(.receiveEnded(.serverClosed)) }
            _ = ends.isComplete
        }
        XCTAssertTrue(ends.isComplete)
    }
}
