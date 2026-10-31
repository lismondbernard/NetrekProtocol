//
//  ServerPackets.swift
//  NetrekWire
//
//  Created by Darrell Root on 6/19/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//
//  The server-to-client (SP_*) packets. Each struct is laid out in memory
//  exactly as the packet goes on the wire, so a sender can copy it out
//  byte for byte. Multi-byte fields hold network byte order.
//

// SP_MESSAGE 1
public struct SP_MESSAGE {
    public let type: UInt8 = 1
    public var flags: UInt8 = 0
    public var recpt: UInt8 = 0 // not sure what this does
    public var from: UInt8 = 0
    public var message: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4 + MSG_LEN
    }
}

// SP_PLAYER_INFO 2
public struct SP_PLAYER_INFO {
    public let type: UInt8 = 2
    public var playerNum: UInt8 = 0
    public var shipType: UInt8 = 0
    public var team: UInt8 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4
    }
}

// SP_KILLS 3
public struct SP_KILLS {
    public let type: UInt8 = 3
    public var playerNum: UInt8 = 0
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var kills: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 8
    }
}

// SP_PLAYER 4
public struct SP_PLAYER {
    public let type: UInt8 = 4
    public var playerNum: UInt8 = 0
    public var directionNetrek: UInt8 = 0
    public var speed: UInt8 = 0
    public var positionX: Int32 = 0
    public var positionY: Int32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 12
    }
}

// SP_TORP_INFO 5
public struct SP_TORP_INFO {
    public let type: UInt8 = 5
    public var war: UInt8 = 0 //mask of teams torp is hostile to
    public var status: UInt8 = 0 // new status of torp, TFREE, TDET, etc
    public var pad1: UInt8 = 0
    public var torpedoNumber: UInt16 = 0
    public var pad2: UInt16 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 8
    }
}

// SP_TORP 6
public struct SP_TORP {
    public let type: UInt8 = 6
    public var direction: UInt8 = 0
    public var torpedoNum: UInt16 = 0
    public var positionX: UInt32 = 0
    public var positionY: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 12
    }
}

// SP_PHASER 7
public struct SP_LASER {
    public let type: UInt8 = 7
    public var laserID: UInt8 = 0
    public var status: UInt8 = 0 // hit, miss?
    public var direction: UInt8 = 0
    public var positionX: UInt32 = 0
    public var positionY: UInt32 = 0
    public var target: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 16
    }
}

// SP_PLASMA_INFO 8
public struct SP_PLASMA_INFO {
    public let type: UInt8 = 8
    public var war: UInt8 = 0 //mask of teams plasma is hostile to
    public var status: UInt8 = 0 // new status of plasma, TFREE, TDET, etc
    public var pad1: UInt8 = 0
    public var plasmaNumber: UInt16 = 0
    public var pad2: UInt16 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 8
    }
}

// SP_PLASMA 9
public struct SP_PLASMA {
    public let type: UInt8 = 9
    public var direction: UInt8 = 0
    public var plasmaNum: UInt16 = 0
    public var positionX: UInt32 = 0
    public var positionY: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 12
    }
}

// SP_MOTD 11
public struct SP_MOTD {
    public let type: UInt8 = 11
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var pad3: UInt8 = 0
    public var motd: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4 + MSG_LEN
    }
}

//SP_YOU 12
public struct SP_YOU {
    public let type: UInt8 = 12
    public var playerNum: UInt8 = 0
    public var hostile: UInt8 = 0
    public var war: UInt8 = 0
    public var armies: UInt8 = 0
    public var tractor: UInt8 = 0
    public var pad2: UInt8 = 0
    public var pad3: UInt8 = 0
    public var flags: UInt32 = 0
    public var damage: UInt32 = 0
    public var shield: UInt32 = 0
    public var fuel: UInt32 = 0
    public var etmp: UInt16 = 0
    public var wtmp: UInt16 = 0
    public var whydead: UInt16 = 0
    public var whodead: UInt16 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 32
    }
}

//SP_QUEUE 13
public struct SP_QUEUE {
    public let type: UInt8 = 13
    public var pad1: UInt8 = 0
    public var position: UInt16 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4
    }
}

//SP_PLANET 15
public struct SP_PLANET {
    public let type: UInt8 = 15
    public var planetNum: UInt8 = 0
    public var owner: UInt8 = 0
    public var info: UInt8 = 0
    public var flags: UInt16 = 0
    public var pad2: UInt16 = 0
    public var armies: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 12
    }
}

//SP_PICKOK 16
public struct SP_PICKOK {
    public let type: UInt8 = 16
    public var state: UInt8 = 0  // 0=no, 1=yes
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4
    }
}

//SP_LOGIN 17
public struct SP_LOGIN {
    public let type: UInt8 = 17
    public var accept: UInt8 = 0
    public var paradise1: UInt8 = 0
    public var paradise2: UInt8 = 0
    public var flags: UInt32 = 0

    // KEYMAP_LEN (96 in classic defs.h) bytes, which makes the packet 104 bytes
    public var keymap: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 8 + KEYMAP_LEN
    }
}

//SP_FLAGS 18
public struct SP_FLAGS {
    public let type: UInt8 = 18
    public var playerID: UInt8 = 0
    public var tractor: UInt8 = 0
    public var pad1: UInt8 = 0
    public var flags: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 8
    }
}

//SP_MASK 19
public struct SP_MASK {
    public let type: UInt8 = 19
    public var mask: UInt8 = 0
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4
    }
}

//SP_PSTATUS 20
public struct SP_PLAYER_STATUS {
    public let type: UInt8 = 20
    public var playerNum: UInt8 = 0
    public var status: UInt8 = 0
    public var pad1: UInt8 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4
    }
}

//SP_HOSTILE 22
public struct SP_HOSTILE {
    public let type: UInt8 = 22
    public var playerID: UInt8 = 0
    public var war: UInt8 = 0
    public var hostile: UInt8 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 4
    }
}

//SP_STATS 23
public struct SP_STATS {
    public let type: UInt8 = 23
    public var playerID: UInt8 = 0
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var tournamentKills: UInt32 = 0
    public var tournamentLosses: UInt32 = 0
    public var overallKills: UInt32 = 0
    public var overallLosses: UInt32 = 0
    public var tournamentTicks: UInt32 = 0
    public var tournamentPlanets: UInt32 = 0
    public var tournamentArmies: UInt32 = 0
    public var starbaseKills: UInt32 = 0
    public var starbaseLosses: UInt32 = 0
    public var intramuralArmies: UInt32 = 0
    public var intramuralPlanets: UInt32 = 0
    public var maxKills100: UInt32 = 0
    public var starbaseMaxKills100: UInt32 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 56
    }
}

//SP_PL_LOGIN 24
public struct SP_PL_LOGIN {
    public let type: UInt8 = 24
    public var playerNum: UInt8 = 0
    public var rank: UInt8 = 0
    public let pad1: UInt8 = 0
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var monitor: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var login: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 52
    }
}

// SP_PLANET_LOC 26
public struct SP_PLANET_LOC {
    public let type: UInt8 = 26
    public var planetID: UInt8 = 0
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var positionX: Int32 = 0
    public var positionY: Int32 = 0
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 28
    }
}

// SP_SHIP_CAP 39: a ship class's limits, for clients that asked for
// the SHIP_CAP feature. Same layout as struct ship_cap_spacket in the
// classic server's packets.h.
public struct SP_SHIP_CAP {
    public let type: UInt8 = 39
    public var operation: UInt8 = 0 // 0 = add or change a ship, 1 = remove it
    public var shipType: UInt16 = 0
    public var torpSpeed: UInt16 = 0
    public var phaserRange: UInt16 = 0
    public var maxSpeed: Int32 = 0
    public var maxFuel: Int32 = 0
    public var maxShield: Int32 = 0
    public var maxDamage: Int32 = 0
    public var maxWeaponTemp: Int32 = 0
    public var maxEngineTemp: Int32 = 0
    public var width: UInt16 = 0
    public var height: UInt16 = 0
    public var maxArmies: UInt16 = 0
    public var letter: UInt8 = 0
    public var pad2: UInt8 = 0
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var designation1: UInt8 = 0
    public var designation2: UInt8 = 0
    public var bitmap: UInt16 = 0

    /// Every field zero except `type`; set the fields you need.
    public init() {}

    public var size: Int {
        return 60
    }
}
