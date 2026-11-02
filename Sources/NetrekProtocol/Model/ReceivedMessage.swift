//
//  ReceivedMessage.swift
//  NetrekProtocol
//
//  An SP_MESSAGE as it came off the wire, before any text conversion, so a
//  client can tell an RCD distress call from chat by its flags.
//

import Foundation

/// One SP_MESSAGE as the server sent it.
public struct ReceivedMessage: Hashable, Sendable {
    /// `m_flags`: see `MessageFlag`. An RCD call in binary form has
    /// `MessageFlag.relayedTeamDistress` (0xC5).
    public let flags: UInt8
    /// `m_recpt`: the slot or team bit the message is for.
    public let recipient: Int
    /// `m_from`: the sender's slot, or 255 for the server.
    public let sender: Int
    /// The 80 `mesg` bytes, NULs included. For player messages they start
    /// with the server's 10 byte address, such as " F1->FED  ".
    public let body: [UInt8]

    public init(flags: UInt8, recipient: Int, sender: Int, body: [UInt8]) {
        self.flags = flags
        self.recipient = recipient
        self.sender = sender
        self.body = body
    }

    /// The RCD distress call in this message, or `nil` for chat and
    /// everything else.
    public var distress: Distress? {
        return Distress.decode(body, from: sender, flags: flags)
    }

    /// Whether this message is an RCD distress call.
    public var isDistress: Bool {
        return distress != nil
    }
}
