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

/// Extended protocol with connection state notifications
/// Used by managers that need to track connection lifecycle
public protocol NetworkDelegateExtended: NetworkDelegate {
    func connectionStateChanged(connected: Bool)
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
