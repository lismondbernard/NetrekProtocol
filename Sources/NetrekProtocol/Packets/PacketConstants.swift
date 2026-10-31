//
//  PacketConstants.swift
//  NetrekProtocol
//
//  Protocol constants. The packet type numbers and the packet sizes now
//  live in NetrekWire; these names keep the client's API as it was. The
//  version numbers come from Darrell Root's Globals.swift (2019).
//

import Foundation
// Re-exported so a client that imports only NetrekProtocol, including one
// built with member import visibility (SE-0444), sees PacketType's cases.
@_exported import NetrekWire

/// Updates per second the client asks for in CP_UPDATES.
let UPDATE_RATE = 20

/// Socket protocol version the client sends in CP_SOCKET.
let SOCKVERSION: UInt8 = 4

/// UDP protocol version the client sends in CP_SOCKET.
let UDPVERSION: UInt8 = 10

/// Port the client puts in CP_SOCKET.
let SOCKET_PORT: UInt32 = 32800

/// Netrek network packet type identifiers (the server-to-client types).
public typealias PacketType = ServerPacketType

/// Size in bytes of each server-to-client (SP_*) packet, indexed by packet
/// type. 0 means unknown or unused, -1 means variable length (not supported
/// by `PacketAnalyzer`).
public let PACKET_SIZES: [Int] = SERVER_PACKET_SIZES
