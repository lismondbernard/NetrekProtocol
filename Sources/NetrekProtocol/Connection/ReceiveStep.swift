//
//  ReceiveStep.swift
//  NetrekProtocol
//
//  What TcpReader does after each receive, as a rule with no network in it,
//  so it can be tested (and read) on its own.
//

import Foundation

/// What a `TcpReader` does once a receive finishes.
enum ReceiveStep: Equatable {
    /// Bytes went to the delegate; whoever reads them asks for more
    /// (`PacketAnalyzerDelegate.triggerReceive()`).
    case handedOn
    /// Nothing arrived and nothing ended: ask again, or reading stops.
    case receiveAgain
    /// Reading is over. Any bytes that came with it are handed on first.
    case end(ConnectionEnd)

    /// An error ends reading even when the receive also says complete, since
    /// the error says more. A complete receive means the server closed its
    /// side, so no more bytes will ever come.
    static func after(byteCount: Int, isComplete: Bool, errorDescription: String?) -> ReceiveStep {
        if let errorDescription { return .end(.receiveFailed(errorDescription)) }
        if isComplete { return .end(.serverClosed) }
        return byteCount > 0 ? .handedOn : .receiveAgain
    }
}
