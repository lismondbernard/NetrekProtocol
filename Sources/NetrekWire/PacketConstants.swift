//
//  PacketConstants.swift
//  NetrekWire
//
//  Wire constants, packet type numbers and packet sizes for both
//  directions. SERVER_PACKET_SIZES and the version numbers come from
//  Darrell Root's Globals.swift (2019) in his Netrek-SwiftUI client;
//  CLIENT_PACKET_SIZES comes from his netrek-server-swift (2020).
//

/// Length of a name, password or login field (NAME_LEN in classic defs.h).
public let NAME_LEN = 16

/// Length of the keymap in SP_LOGIN (KEYMAP_LEN in classic defs.h).
public let KEYMAP_LEN = 96

/// Length of the text in SP_MESSAGE, SP_MOTD and CP_MESSAGE
/// (MSG_LEN in classic defs.h).
public let MSG_LEN = 80

/// Socket protocol version the client sends in CP_SOCKET.
public let SOCKVERSION: UInt8 = 4

/// UDP protocol version the client sends in CP_SOCKET.
public let UDPVERSION: UInt8 = 10

/// Netrek server-to-client packet type identifiers
public enum ServerPacketType: UInt8 {
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

/// Netrek client-to-server packet type identifiers: every type that has
/// a size in `CLIENT_PACKET_SIZES`.
public enum ClientPacketType: UInt8, CaseIterable {
    case null = 0
    case message = 1           // CP_MESSAGE
    case speed = 2             // CP_SPEED
    case direction = 3         // CP_DIRECTION
    case phaser = 4            // CP_PHASER (CP_LASER here)
    case plasma = 5            // CP_PLASMA
    case torpedo = 6           // CP_TORP
    case quit = 7              // CP_QUIT
    case login = 8             // CP_LOGIN
    case outfit = 9            // CP_OUTFIT
    case war = 10              // CP_WAR
    case practiceRobot = 11    // CP_PRACTR
    case shield = 12           // CP_SHIELD
    case repair = 13           // CP_REPAIR
    case orbit = 14            // CP_ORBIT
    case planetLock = 15       // CP_PLANLOCK
    case playerLock = 16       // CP_PLAYLOCK
    case bomb = 17             // CP_BOMB
    case beam = 18             // CP_BEAM
    case cloak = 19            // CP_CLOAK
    case detTorpedoes = 20     // CP_DET_TORPS
    case detMyTorpedo = 21     // CP_DET_MYTORP
    case copilot = 22          // CP_COPILOT
    case refit = 23            // CP_REFIT
    case tractor = 24          // CP_TRACTOR
    case repress = 25          // CP_REPRESS
    case coup = 26             // CP_COUP
    case socket = 27           // CP_SOCKET
    case options = 28          // CP_OPTIONS
    case bye = 29              // CP_BYE
    case dockPermission = 30   // CP_DOCKPERM
    case updates = 31          // CP_UPDATES
    case resetStats = 32       // CP_RESETSTATS
    case reserved = 33         // CP_RESERVED
    case scan = 34             // CP_SCAN
    case udpRequest = 35       // CP_UDP_REQ
    case sequence = 36         // CP_SEQUENCE
    case rsaKey = 37           // CP_RSA_KEY
    case planet = 38           // CP_PLANET
    case ping = 42             // CP_PING_RESPONSE
    case sRequest = 43         // CP_S_REQ
    case shortThreshold = 44   // CP_S_THRS
    case feature = 60          // CP_FEATURE
}

/// Size in bytes of each server-to-client (SP_*) packet, indexed by packet
/// type. 0 means unknown or unused, -1 means variable length.
public let SERVER_PACKET_SIZES: [Int] = [
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

/// Size in bytes of each client-to-server (CP_*) packet, keyed by packet
/// type. A type with no entry is unknown.
public let CLIENT_PACKET_SIZES: [Int: Int] =
    [0:0, // NULL
    1:84, // CP_MESSAGE 1
2:4, // CP_SPEED 2
3:4, // CP_DIRECTION 3
4:4, // CP_LASER 4
5:4, // CP_PLASMA 5
6:4, // CP_TORP 6
7:4, // CP_QUIT 7
8:52, // CP_LOGIN 8
9:4, // CP_OUTFIT 9
10:4, // CP_WAR 10
11:4, // CP_PRACTR 11
12:4, // CP_SHIELD 12
13:4, // CP_REPAIR 13
14:4, // CP_ORBIT 14
15:4, // CP_PLANLOCK 15
16:4, // CP_PLAYLOCK 16
17:4, // CP_BOMB 17
18:4, // CP_BEAM 18
19:4, // CP_CLOAK 19
20:4, // CP_DET_TORPS 20
21:4, // CP_DET_MYTORP 21
22:4, // CP_COPILOT 22
23:4, // CP_REFIT 23
24:4, // CP_TRACTOR 24
25:4, // CP_REPRESS 25
26:4, // CP_COUP 26
27:8, // CP_SOCKET 27
28:104, // CP_OPTIONS 28
29:4, // CP_BYE 29
30:4, // CP_DOCKPERM 30
31:8, // CP_UPDATES 31
32:4, // CP_RESETSTATS 32
33:36, // CP_RESERVED 33
34:4, // CP_SCAN 34
35:8, // CP_UDP_REQ 35
36:4, // CP_SEQUENCE 36
37:100, // CP_RSA_KEY 37
38:10, //CP_PLANET 38
42:12, //CP_PING 42
43:4, //CP_S_REQ 43
44:4, //CP_SHORT_THRESHOLD
60:88, //CP_FEATURE
]
