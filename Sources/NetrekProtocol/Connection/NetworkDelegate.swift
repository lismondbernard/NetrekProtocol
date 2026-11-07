//
//  NetworkDelegate.swift
//  Netrek
//
//  Created by Darrell Root on 3/1/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

/// Receives the bytes a `TcpReader` reads from the server.
public protocol NetworkDelegate {
    func gotData(data: Data, from: String, port: Int)
}

/// Why a `TcpReader` stopped reading for good.
public enum ConnectionEnd: Equatable, Sendable {
    /// The server closed the connection, for example after a ghostbust or
    /// an SP_BADVERSION.
    case serverClosed
    /// A receive failed. The text is the system's description of the error.
    case receiveFailed(String)
}

/// Extended protocol with connection state notifications
/// Used by managers that need to track connection lifecycle
public protocol NetworkDelegateExtended: NetworkDelegate {
    func connectionStateChanged(connected: Bool)
    /// The reader stopped reading, and says why. It cancels the connection
    /// next, and does not call `connectionStateChanged(connected: false)`
    /// for that, so this is the only report of the end.
    func connectionEnded(_ end: ConnectionEnd)
}

extension NetworkDelegateExtended {
    /// Reports the end as a disconnect, for delegates that don't need the reason.
    public func connectionEnded(_ end: ConnectionEnd) {
        connectionStateChanged(connected: false)
    }
}

/// Anything that can send packets to the game server: a `TcpReader`, or an
/// app object that forwards to one.
public protocol NetworkSending: AnyObject {
    func send(content: Data)
}

/// Tells package code which `GameState` the client is in.
public protocol GameStateSource: AnyObject {
    var gameState: GameState { get }
}
