//
//  PacketConstants.swift
//  NetrekProtocol
//
//  Protocol constants. The packet type numbers, the packet sizes and the
//  version numbers now live in NetrekWire; these names keep the client's
//  API as it was.
//

import Foundation
import NetrekWire

/// Updates per second the client asks for in CP_UPDATES.
let UPDATE_RATE = 20

/// Netrek network packet type identifiers (the server-to-client types).
public typealias PacketType = ServerPacketType

/// Size in bytes of each server-to-client (SP_*) packet, indexed by packet
/// type. 0 means unknown or unused, -1 means variable length (not supported
/// by `PacketAnalyzer`).
public let PACKET_SIZES: [Int] = SERVER_PACKET_SIZES
