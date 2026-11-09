//
//  ServerStream.swift
//  NetrekProtocolTests
//
//  A classic server's stream to one client, from the first bytes after
//  CP_SOCKET to a few frames of play, built packet by packet at the sizes
//  of the classic include/packets.h. The order follows what a classic
//  server sends: the MOTD and feature replies, SP_YOU with the slot, the
//  galaxy (SP_PLANET_LOC and SP_PLANET for all 40 planets), the other
//  players, the ship caps, SP_LOGIN, SP_MASK, SP_PICKOK, then play.
//
//  It is not a capture from a live server. It holds each packet type a
//  classic server sends to a client in a login and a few frames of play,
//  when the client has asked for no short packets, so a framing mistake for
//  any of them shows up.
//

import Foundation
@testable import NetrekProtocol

/// One server packet, written field by field. Multi-byte fields are big
/// endian, as on the wire.
struct WirePacket {
    private(set) var bytes: [UInt8]

    /// A packet of `size` bytes, all zero but the type. `size` defaults to
    /// this package's size for the type, so give it for a type the table
    /// does not size, or sizes differently from the classic server.
    init(type: UInt8, size: Int? = nil) {
        let length = size ?? PACKET_SIZES[Int(type)]
        precondition(length > 0, "type \(type) needs a size")
        bytes = [UInt8](repeating: 0, count: length)
        bytes[0] = type
    }

    /// Each setter returns the packet with that field set, so they chain.
    func u8(_ offset: Int, _ value: UInt8) -> WirePacket {
        var copy = self
        copy.bytes[offset] = value
        return copy
    }

    func u16(_ offset: Int, _ value: UInt16) -> WirePacket {
        u8(offset, UInt8(value >> 8)).u8(offset + 1, UInt8(value & 0xff))
    }

    func u32(_ offset: Int, _ value: UInt32) -> WirePacket {
        u16(offset, UInt16(value >> 16)).u16(offset + 2, UInt16(value & 0xffff))
    }

    func i32(_ offset: Int, _ value: Int32) -> WirePacket {
        u32(offset, UInt32(bitPattern: value))
    }

    /// A C string in a field of `length` bytes, NUL padded.
    func text(_ offset: Int, _ value: String, length: Int) -> WirePacket {
        var copy = self
        for (index, byte) in value.utf8.prefix(length - 1).enumerated() {
            copy.bytes[offset + index] = byte
        }
        return copy
    }

    var data: Data { Data(bytes) }
}

enum ServerStream {

    /// The classic planet names, in planet number order.
    static let planetNames = [
        "Earth", "Rigel", "Canopus", "Beta Crucis", "Organia", "Deneb", "Ceti Alpha V",
        "Altair", "Vega", "Alpha Centauri", "Romulus", "Eridani", "Aldebaran", "Regulus",
        "Capella", "Tauri", "Draconis", "Sirius", "Indi", "Hydrae", "Klingus", "Pliedes V",
        "Andromeda", "Lalande", "Pollux", "Lyrae", "Scorpii", "Mira", "Cygni", "Achernar",
        "Orion", "Cassiopia", "El Nath", "Spica", "Procyon", "Polaris", "Arcturus",
        "Ursae Majoris", "Herculis", "Antares",
    ]

    /// The slot the server gives this client.
    static let mySlot: UInt8 = 3

    static func motd(_ line: String) -> Data {
        let packet = WirePacket(type: 11)
        return packet.text(4, line, length: 80).data
    }

    static func warning(_ line: String) -> Data {
        let packet = WirePacket(type: 10)
        return packet.text(4, line, length: 80).data
    }

    /// SP_FEATURE: type, 'S', arg1, arg2, value, 80 bytes of name.
    static func feature(_ name: String, value: Int32) -> Data {
        let packet = WirePacket(type: 60)
        return packet.u8(1, UInt8(ascii: "S")).i32(4, value).text(8, name, length: 80).data
    }

    /// SP_QUEUE: type, pad, the place in the wait queue.
    static func queue(position: UInt16) -> Data {
        let packet = WirePacket(type: 13)
        return packet.u16(2, position).data
    }

    /// SP_RESERVED: type, three pads, 16 bytes the client is to answer
    /// (ntserv/reserved.c).
    static func reserved() -> Data {
        var packet = WirePacket(type: 25)
        for index in 0..<16 { packet = packet.u8(4 + index, UInt8(0xa0 + index)) }
        return packet.data
    }

    static func you(slot: UInt8, flags: UInt32, fuel: UInt32, damage: UInt32 = 0, armies: UInt8 = 0) -> Data {
        let packet = WirePacket(type: 12)
        return packet.u8(1, slot).u8(2, 0x0e).u8(3, 0x0e).u8(4, armies)
            .u32(8, flags).u32(12, damage).u32(16, 100).u32(20, fuel)
            .u16(24, 120).u16(26, 40).data
    }

    static func planetLoc(_ planet: Int) -> Data {
        let packet = WirePacket(type: 26)
        return packet.u8(1, UInt8(planet))
            .i32(4, Int32(10000 + (planet % 8) * 10000))
            .i32(8, Int32(10000 + (planet / 8) * 18000))
            .text(12, planetNames[planet], length: 16).data
    }

    static func planet(_ planet: Int, owner: UInt8, armies: UInt32, flags: UInt16 = 0x0070) -> Data {
        let packet = WirePacket(type: 15)
        return packet.u8(1, UInt8(planet)).u8(2, owner).u8(3, 0x0f)
            .u16(4, flags).u32(8, armies).data
    }

    static func plLogin(slot: UInt8, rank: UInt8, name: String, login: String, monitor: String) -> Data {
        let packet = WirePacket(type: 24)
        return packet.u8(1, slot).u8(2, rank)
            .text(4, name, length: 16).text(20, monitor, length: 16).text(36, login, length: 16).data
    }

    static func playerInfo(slot: UInt8, ship: UInt8, team: UInt8) -> Data {
        let packet = WirePacket(type: 2)
        return packet.u8(1, slot).u8(2, ship).u8(3, team).data
    }

    static func kills(slot: UInt8, hundredths: UInt32) -> Data {
        let packet = WirePacket(type: 3)
        return packet.u8(1, slot).u32(4, hundredths).data
    }

    static func hostile(slot: UInt8, war: UInt8, hostile: UInt8) -> Data {
        let packet = WirePacket(type: 22)
        return packet.u8(1, slot).u8(2, war).u8(3, hostile).data
    }

    static func pstatus(slot: UInt8, status: UInt8) -> Data {
        let packet = WirePacket(type: 20)
        return packet.u8(1, slot).u8(2, status).data
    }

    static func flags(slot: UInt8, tractor: UInt8, flags: UInt32) -> Data {
        let packet = WirePacket(type: 18)
        return packet.u8(1, slot).u8(2, tractor).u32(4, flags).data
    }

    static func stats(slot: UInt8, kills: UInt32) -> Data {
        var packet = WirePacket(type: 23).u8(1, slot)
        for (index, value) in [kills, 3, kills * 2, 7, 3600, 2, 11, 1, 0, 4, 1, 450, 0].enumerated() {
            packet = packet.u32(4 + 4 * index, UInt32(value))
        }
        return packet.data
    }

    static func shipCap(ship: UInt16, letter: Character, name: String) -> Data {
        let packet = WirePacket(type: 39)
        return packet.u16(2, ship).u16(4, 12).u16(6, 100)
            .u32(8, 9).u32(12, 10000).u32(16, 100).u32(20, 100)
            .i32(24, 1000).i32(28, 1000).u16(32, 20).u16(34, 20).u16(36, 6)
            .u8(38, UInt8(ascii: letter.unicodeScalars.first!)).text(40, name, length: 16)
            .u8(56, UInt8(ascii: letter.unicodeScalars.first!)).u8(57, UInt8(ascii: "A")).data
    }

    static func login(accept: UInt8) -> Data {
        var packet = WirePacket(type: 17).u8(1, accept).u32(4, 0x0001)
        for index in 0..<96 { packet = packet.u8(8 + index, UInt8(0x20 + index % 0x5f)) }
        return packet.data
    }

    static func mask(_ teams: UInt8) -> Data {
        let packet = WirePacket(type: 19)
        return packet.u8(1, teams).data
    }

    static func pickok(_ state: UInt8) -> Data {
        let packet = WirePacket(type: 16)
        return packet.u8(1, state).data
    }

    /// SP_GENERIC_32 version 'b' (generic_32_spacket_b, packed).
    static func generic32(repairTime: UInt16, orbit: Int8) -> Data {
        let packet = WirePacket(type: 32)
        return packet.u8(1, 0x62).u16(2, repairTime).u8(4, UInt8(bitPattern: orbit))
            .u16(5, 0x0003).u8(7, 0x05).u8(8, 12).u8(9, UInt8(ascii: "m"))
            .u8(10, 40).u8(11, UInt8(ascii: "m")).u8(12, 0).u8(13, 0).data
    }

    static func player(slot: UInt8, direction: UInt8, speed: UInt8, x: Int32, y: Int32) -> Data {
        let packet = WirePacket(type: 4)
        return packet.u8(1, slot).u8(2, direction).u8(3, speed).i32(4, x).i32(8, y).data
    }

    static func torpInfo(_ torp: UInt16, war: UInt8, status: UInt8) -> Data {
        let packet = WirePacket(type: 5)
        return packet.u8(1, war).u8(2, status).u16(4, torp).data
    }

    static func torp(_ torp: UInt16, direction: UInt8, x: Int32, y: Int32) -> Data {
        let packet = WirePacket(type: 6)
        return packet.u8(1, direction).u16(2, torp).i32(4, x).i32(8, y).data
    }

    static func phaser(slot: UInt8, status: UInt8, direction: UInt8, x: Int32, y: Int32, target: Int32) -> Data {
        let packet = WirePacket(type: 7)
        return packet.u8(1, slot).u8(2, status).u8(3, direction).i32(4, x).i32(8, y).i32(12, target).data
    }

    static func plasmaInfo(_ plasma: UInt16, war: UInt8, status: UInt8) -> Data {
        let packet = WirePacket(type: 8)
        return packet.u8(1, war).u8(2, status).u16(4, plasma).data
    }

    static func plasma(_ plasma: UInt16, x: Int32, y: Int32) -> Data {
        let packet = WirePacket(type: 9)
        return packet.u16(2, plasma).i32(4, x).i32(8, y).data
    }

    static func message(flags: UInt8, recipient: UInt8, from: UInt8, body: [UInt8]) -> Data {
        var packet = WirePacket(type: 1).u8(1, flags).u8(2, recipient).u8(3, from)
        for (index, byte) in body.prefix(79).enumerated() { packet = packet.u8(4 + index, byte) }
        return packet.data
    }

    static func message(flags: UInt8, recipient: UInt8, from: UInt8, text: String) -> Data {
        message(flags: flags, recipient: recipient, from: from, body: Array(text.utf8))
    }

    /// An RCD call as the server relays it to the sender's team: the
    /// address, then the client's binary body (see DistressPacketTests).
    static func distress(from slot: UInt8) -> Data {
        let call = Distress(type: .carrying, sender: Int(slot), damage: 20, shields: 80, fuel: 70,
                            armies: 4, nearestPlanet: 0)
        let address = Array(" F\(slot)->FED  ".utf8.prefix(10))
        let body = address + Array(MakePacket.cpDistress(call, team: .federation)[4...].prefix(69))
        return message(flags: MessageFlag.relayedTeamDistress, recipient: 1,
                       from: slot, body: body)
    }

    static func status(tourn: UInt8) -> Data {
        let packet = WirePacket(type: 14)
        return packet.u8(1, tourn).u32(4, 120).u32(8, 33).u32(12, 400).u32(16, 380)
            .u32(20, 98765).i32(24, 4321).data
    }

    /// The packets, in order. Their bytes joined are `bytes`.
    static let packets: [Data] = {
        var out: [Data] = []
        for line in ["Welcome to a classic Netrek server.", "", "Rules: be nice.",
                     "Newbie server: robots will join to fill the teams.",
                     "Clue games every Saturday.", "Report bugs to the server god.",
                     "---", "Have fun!"] {
            out.append(motd(line))
        }
        out.append(feature("FEATURE_PACKETS", value: 1))
        out.append(feature("RC_DISTRESS", value: 1))
        out.append(feature("SHIP_CAP", value: 1))
        out.append(feature("SP_GENERIC_32", value: 2))
        out.append(queue(position: 2))
        out.append(reserved())
        out.append(you(slot: mySlot, flags: 0, fuel: 10000))
        for planet in 0..<40 { out.append(planetLoc(planet)) }
        let owners: [UInt8] = [1, 2, 4, 8]
        for planet in 0..<40 {
            out.append(ServerStream.planet(planet, owner: owners[planet / 10], armies: UInt32(planet % 7 + 1)))
        }
        let people: [(UInt8, String, String, UInt8, UInt8)] = [
            (0, "Kirk", "jtk", 2, 1), (1, "Spock", "spock", 1, 1), (2, "Kor", "kor", 3, 4),
            (3, "guest", "guest", 2, 1), (4, "Mot", "mot", 4, 2), (7, "Tal", "tal", 0, 8),
        ]
        for (slot, name, login, ship, team) in people {
            out.append(plLogin(slot: slot, rank: slot % 5, name: name, login: login, monitor: "host\(slot).example"))
            out.append(playerInfo(slot: slot, ship: ship, team: team))
            out.append(kills(slot: slot, hundredths: UInt32(slot) * 150))
            out.append(hostile(slot: slot, war: 0x0e & ~team, hostile: 0x0e & ~team))
            out.append(pstatus(slot: slot, status: slot == mySlot ? 1 : 2))
            out.append(flags(slot: slot, tractor: 0, flags: 0x0001))
            out.append(stats(slot: slot, kills: UInt32(slot) * 10))
        }
        for (ship, letter, name) in [(0, "S", "SCOUT"), (1, "D", "DESTROYER"), (2, "C", "CRUISER"),
                                     (3, "B", "BATTLESHIP"), (4, "A", "ASSAULT"), (5, "S", "STARBASE"),
                                     (6, "G", "GALAXY")] as [(UInt16, Character, String)] {
            out.append(shipCap(ship: ship, letter: letter, name: name))
        }
        out.append(login(accept: 1))
        out.append(mask(0x0f))
        out.append(pickok(1))
        out.append(pstatus(slot: mySlot, status: 2))
        out.append(generic32(repairTime: 0, orbit: -1))
        for frame in 0..<4 {
            let step = Int32(frame * 300)
            out.append(you(slot: mySlot, flags: 0x0001 | (frame > 1 ? 0x0002 : 0), fuel: UInt32(10000 - frame * 50),
                           damage: UInt32(frame * 5)))
            for (slot, _, _, _, _) in people {
                out.append(player(slot: slot, direction: UInt8(frame * 16 + Int(slot)), speed: 4,
                                  x: 30000 + Int32(slot) * 2000 + step, y: 40000 - step))
            }
            out.append(flags(slot: 2, tractor: frame == 2 ? 0x43 : 0, flags: 0x0001 | 0x4000))
            for torp in UInt16(16)..<UInt16(18) {
                out.append(torpInfo(torp + UInt16(frame), war: 0x01, status: 1))
                out.append(ServerStream.torp(torp + UInt16(frame), direction: 64, x: 34000 + step, y: 40000))
            }
            out.append(phaser(slot: 2, status: frame == 3 ? 1 : 0, direction: 192, x: 34000, y: 40000, target: 3))
            out.append(plasmaInfo(4, war: 0x01, status: frame == 0 ? 1 : 2))
            out.append(plasma(4, x: 36000 - step, y: 40000))
            out.append(planet(frame, owner: 1, armies: UInt32(frame + 3)))
            out.append(message(flags: MessageFlag.team | MessageFlag.valid, recipient: 1, from: 1,
                               text: " F1->FED   frame \(frame), escort the carrier"))
            out.append(warning(frame == 1 ? "Tractor beam activated" : "Weapons overheated"))
            out.append(kills(slot: 2, hundredths: UInt32(100 + frame * 25)))
        }
        out.append(distress(from: 1))
        out.append(status(tourn: 1))
        out.append(generic32(repairTime: 0, orbit: 5))
        out.append(pstatus(slot: 7, status: 3))
        return out
    }()

    static let bytes: Data = packets.reduce(into: Data()) { $0.append($1) }
}
