//
//  ReaderEnds.swift
//  NetrekProtocol
//
//  Who reports the end of a TcpReader's connection, and how, as a rule
//  with no network in it so every order of events can be tested.
//

import Foundation

/// Decides what a `TcpReader` tells its delegate when the connection ends.
/// The connection's callbacks run on a concurrent queue, so the state
/// events and the last receive race; this is the one place they meet.
///
/// - The end is reported once, by whichever event comes first.
/// - A failure always carries its reason, whichever path reports it.
/// - After `clientClosed()` (the client's own `resetConnection()`),
///   nothing is reported at all: the client already knows.
final class ReaderEnds: @unchecked Sendable {
    enum Event: Equatable {
        /// The connection's state became `.failed`.
        case failed(String)
        /// The connection's state became `.cancelled`.
        case cancelled
        /// A receive ended reading (`ReceiveStep.end`).
        case receiveEnded(ConnectionEnd)
    }

    enum Report: Equatable {
        /// Call `connectionEnded(_:)`.
        case ended(ConnectionEnd)
        /// Call `connectionStateChanged(connected: false)`: the connection
        /// was cancelled with no reason given.
        case disconnected
    }

    private let lock = NSLock()
    private var reported = false
    private var closedByClient = false
    private var complete = false

    /// True once reading is over: no more receives are started.
    var isComplete: Bool {
        lock.lock()
        defer { lock.unlock() }
        return complete
    }

    /// The client closed the connection. Nothing after this is reported.
    func clientClosed() {
        lock.lock()
        closedByClient = true
        complete = true
        lock.unlock()
    }

    /// What to tell the delegate for this event, or nil for nothing.
    func report(_ event: Event) -> Report? {
        lock.lock()
        defer { lock.unlock() }
        complete = true
        guard !closedByClient, !reported else { return nil }
        reported = true
        switch event {
        case .failed(let error): return .ended(.connectionFailed(error))
        case .cancelled: return .disconnected
        case .receiveEnded(let end): return .ended(end)
        }
    }
}
