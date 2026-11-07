//
//  UnreadablePacket.swift
//  NetrekProtocol
//
//  Where and why PacketAnalyzer lost its place in the server's stream.
//

import Foundation

/// A packet `PacketAnalyzer` could not size, so it could not find where the
/// next packet starts. TCP gives no packet boundaries: every packet's length
/// comes from its type, so after this nothing more can be read on the
/// connection. A wrong length for any one packet makes the next "type" byte
/// garbage, which usually ends up here; `previousPacketType` points at it.
public struct UnreadablePacket: Equatable, Sendable, CustomStringConvertible {
    public enum Reason: Equatable, Sendable {
        /// The type is past the end of `PACKET_SIZES`.
        case unknownType
        /// `PACKET_SIZES` marks the type unused (0).
        case unusedType
        /// A variable length packet (-1): the SP_S_* short packets, which a
        /// client only gets after asking for them with CP_S_REQ.
        case variableLength
    }

    /// The most bytes `leadingBytes` keeps.
    public static let leadingByteLimit = 16

    /// The type byte that could not be read.
    public let packetType: UInt8
    public let reason: Reason
    /// Bytes of the stream read before this packet, counting every receive.
    public let streamOffset: Int
    /// The type of the last packet read, the one whose length may be wrong.
    /// Nil when this was the first.
    public let previousPacketType: UInt8?
    /// The first bytes from the type byte on, at most `leadingByteLimit`.
    public let leadingBytes: [UInt8]

    public init(packetType: UInt8, reason: Reason, streamOffset: Int,
                previousPacketType: UInt8?, leadingBytes: [UInt8]) {
        self.packetType = packetType
        self.reason = reason
        self.streamOffset = streamOffset
        self.previousPacketType = previousPacketType
        self.leadingBytes = Array(leadingBytes.prefix(Self.leadingByteLimit))
    }

    /// How `PACKET_SIZES` classes a type, or nil when the type can be read.
    static func reason(forType type: UInt8) -> Reason? {
        guard let size = PACKET_SIZES[safe: Int(type)] else { return .unknownType }
        if size == 0 { return .unusedType }
        if size < 0 { return .variableLength }
        return nil
    }

    public var description: String {
        let reasonText: String
        switch reason {
        case .unknownType: reasonText = "unknown type"
        case .unusedType: reasonText = "unused type"
        case .variableLength: reasonText = "variable length"
        }
        let after = previousPacketType.map { ", after type \($0)" } ?? ", first packet"
        let bytes = leadingBytes.map { String(format: "%02x", $0) }.joined(separator: " ")
        return "unreadable packet type \(packetType) (\(reasonText)) at stream offset \(streamOffset)\(after), bytes: \(bytes)"
    }
}
