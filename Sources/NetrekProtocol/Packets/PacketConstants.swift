//
//  PacketConstants.swift
//  NetrekProtocol
//
//  Protocol constants. PACKET_SIZES and the version numbers come from
//  Darrell Root's Globals.swift (2019).
//

import Foundation

let NAME_LEN = 16
let SOCKVERSION: UInt8 = 4
let UDPVERSION: UInt8 = 10

/// Updates per second the client asks for in CP_UPDATES.
let UPDATE_RATE = 20

/// Netrek network packet type identifiers
public enum PacketType: UInt8 {
    case null = 0
    case message = 1           // SP_MESSAGE
    case playerInfo = 2        // SP_PLAYER_INFO
    case kills = 3             // SP_KILLS
    case player = 4            // SP_PLAYER
    case torpedoInfo = 5       // SP_TORP_INFO
    case torpedo = 6           // SP_TORP
    case phaser = 7            // SP_PHASER
    case plasmaInfo = 8        // SP_PLASMA_INFO
    case plasma = 9            // SP_PLASMA
    case warning = 10          // SP_WARNING
    case motd = 11             // SP_MOTD
    case you = 12              // SP_YOU
    case queue = 13            // SP_QUEUE
    case status = 14           // SP_STATUS
    case planet = 15           // SP_PLANET
    case pickOk = 16           // SP_PICKOK
    case login = 17            // SP_LOGIN
    case flags = 18            // SP_FLAGS
    case mask = 19             // SP_MASK
    case pStatus = 20          // SP_PSTATUS
    case badVersion = 21       // SP_BADVERSION
    case hostile = 22          // SP_HOSTILE
    case stats = 23            // SP_STATS
    case plLogin = 24          // SP_PL_LOGIN
    case reserved = 25         // SP_RESERVED
    case planetLoc = 26        // SP_PLANET_LOC
    case scan = 27             // SP_SCAN
    case udpReply = 28         // SP_UDP_REPLY
    case sequence = 29         // SP_SEQUENCE
    case scSequence = 30       // SP_SC_SEQUENCE
    case rsaKey = 31           // SP_RSA_KEY
    case motdPic = 32          // SP_MOTD_PIC / SP_GENERIC_32
    case shipCap = 39          // SP_SHIP_CAP
    case sReply = 40           // SP_S_REPLY
    case sMessage = 41         // SP_S_MESSAGE
    case sWarning = 42         // SP_S_WARNING
    case sYou = 43             // SP_S_YOU
    case sYouSS = 44           // SP_S_YOU_SS
    case sPlayer = 45          // SP_S_PLAYER
    case ping = 46             // SP_PING
    case sTorpedo = 47         // SP_S_TORP
    case sTorpedoInfo = 48     // SP_S_TORP_INFO
    case s8Torpedo = 49        // SP_S_8_TORP
    case sPlanet = 50          // SP_S_PLANET
    case sSequence = 56        // SP_S_SEQUENCE
    case sPhaser = 57          // SP_S_PHASER
    case sKills = 58           // SP_S_KILLS
    case sStats = 59           // SP_S_STATS
    case feature = 60          // SP_FEATURE
    case bitmap = 61           // SP_BITMAP
}

/// Size in bytes of each server-to-client (SP_*) packet, indexed by packet
/// type. 0 means unknown or unused, -1 means variable length (not supported
/// by `PacketAnalyzer`).
public let PACKET_SIZES: [Int] = [
    0,        // NULL
    84,        // SP_MESSAGE
    4,        // SP_PLAYER_INFO
    8,        // SP_KILLS
    12,        // SP_PLAYER
    8,        // SP_TORP_INFO
    12,        // SP_TORP
    16,        // SP_PHASER
    8,        // SP_PLASMA_INFO
    12,        // SP_PLASMA
    84,        // SP_WARNING
    84,        // SP_MOTD
    32,        // SP_YOU
    4,        // SP_QUEUE
    28,        // SP_STATUS
    12,        // SP_PLANET
    4,        // SP_PICKOK
    104,        // SP_LOGIN
    8,        // SP_FLAGS
    4,        // SP_MASK
    4,        // SP_PSTATUS
    4,        // SP_BADVERSION
    4,        // SP_HOSTILE
    56,        // SP_STATS
    52,        // SP_PL_LOGIN
    20,        // SP_RESERVED
    28,        // SP_PLANET_LOC
    0,        // SP_SCAN
    8,        // SP_UDP_REPLY
    4,        // SP_SEQUENCE
    4,        // SP_SC_SEQUENCE
    36,        // SP_RSA_KEY
    32,        // SP_MOTD_PIC  // error is SP_GENERIC_32
    0,        // 33
    0,        // 34
    0,        // 35
    0,        // 36
    0,        // 37
    0,        // 38
    60,        // SP_SHIP_CAP
    8,        // SP_S_REPLY
    -1,        // SP_S_MESSAGE
    -1,        // SP_S_WARNING
    12,        // SP_S_YOU
    12,        // SP_S_YOU_SS
    -1,        // SP_S_PLAYER
    8,        // SP_PING
    -1,        // SP_S_TORP
    -1,        // SP_S_TORP_INFO
    20,        // SP_S_8_TORP
    -1,        // SP_S_PLANET
    0,        // 51
    0,        // 52
    0,        // 53
    0,        // 54
    0,        // 55
    0,        // SP_S_SEQUENCE
    -1,        // SP_S_PHASER
    -1,        // SP_S_KILLS
    36,        // SP_S_STATS
    88,        // SP_FEATURE
    524        // SP_BITMAP
]
