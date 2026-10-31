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
    public var type: UInt8 = 1
    public var flags: UInt8
    public var recpt: UInt8 = 0 // not sure what this does
    public var from: UInt8
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

    public init(type: UInt8 = 1,
                flags: UInt8,
                recpt: UInt8 = 0,
                from: UInt8,
                message: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
                    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.type = type
        self.flags = flags
        self.recpt = recpt
        self.from = from
        self.message = message
    }

    public var size: Int {
        return 84
    }
}

// SP_PLAYER_INFO 2
public struct SP_PLAYER_INFO {
    public var type: UInt8 = 2
    public var playerNum: UInt8
    public var shipType: UInt8
    public var team: UInt8

    public init(type: UInt8 = 2,
                playerNum: UInt8,
                shipType: UInt8,
                team: UInt8) {
        self.type = type
        self.playerNum = playerNum
        self.shipType = shipType
        self.team = team
    }

    public var size: Int {
        return 4
    }
}

// SP_KILLS 3
public struct SP_KILLS {
    public var type: UInt8 = 3
    public var playerNum: UInt8
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var kills: UInt32

    public init(type: UInt8 = 3,
                playerNum: UInt8,
                pad1: UInt8 = 0,
                pad2: UInt8 = 0,
                kills: UInt32) {
        self.type = type
        self.playerNum = playerNum
        self.pad1 = pad1
        self.pad2 = pad2
        self.kills = kills
    }

    public var size: Int {
        return 8
    }
}

// SP_PLAYER 4
public struct SP_PLAYER {
    public var type: UInt8 = 4
    public var playerNum: UInt8
    public var directionNetrek: UInt8
    public var speed: UInt8
    public var positionX: Int32
    public var positionY: Int32

    public init(type: UInt8 = 4,
                playerNum: UInt8,
                directionNetrek: UInt8,
                speed: UInt8,
                positionX: Int32,
                positionY: Int32) {
        self.type = type
        self.playerNum = playerNum
        self.directionNetrek = directionNetrek
        self.speed = speed
        self.positionX = positionX
        self.positionY = positionY
    }

    public var size: Int {
        return 12
    }
}

// SP_TORP_INFO 5
public struct SP_TORP_INFO {
    public var type: UInt8 = 5
    public var war: UInt8 //mask of teams torp is hostile to
    public var status: UInt8 // new status of torp, TFREE, TDET, etc
    public var pad1: UInt8 = 0
    public var torpedoNumber: UInt16
    public var pad2: UInt16 = 0

    public init(type: UInt8 = 5,
                war: UInt8,
                status: UInt8,
                pad1: UInt8 = 0,
                torpedoNumber: UInt16,
                pad2: UInt16 = 0) {
        self.type = type
        self.war = war
        self.status = status
        self.pad1 = pad1
        self.torpedoNumber = torpedoNumber
        self.pad2 = pad2
    }

    public var size: Int {
        return 8
    }
}

// SP_TORP 6
public struct SP_TORP {
    public var type: UInt8 = 6
    public var direction: UInt8
    public var torpedoNum: UInt16
    public var positionX: UInt32
    public var positionY: UInt32

    public init(type: UInt8 = 6,
                direction: UInt8,
                torpedoNum: UInt16,
                positionX: UInt32,
                positionY: UInt32) {
        self.type = type
        self.direction = direction
        self.torpedoNum = torpedoNum
        self.positionX = positionX
        self.positionY = positionY
    }

    public var size: Int {
        return 12
    }
}

// SP_PHASER 7
public struct SP_LASER {
    public var type: UInt8 = 7
    public var laserID: UInt8
    public var status: UInt8 // hit, miss?
    public var direction: UInt8
    public var positionX: UInt32
    public var positionY: UInt32
    public var target: UInt32

    public init(type: UInt8 = 7,
                laserID: UInt8,
                status: UInt8,
                direction: UInt8,
                positionX: UInt32,
                positionY: UInt32,
                target: UInt32) {
        self.type = type
        self.laserID = laserID
        self.status = status
        self.direction = direction
        self.positionX = positionX
        self.positionY = positionY
        self.target = target
    }

    public var size: Int {
        return 16
    }
}

// SP_PLASMA_INFO 8
public struct SP_PLASMA_INFO {
    public var type: UInt8 = 8
    public var war: UInt8 //mask of teams plasma is hostile to
    public var status: UInt8 // new status of plasma, TFREE, TDET, etc
    public var pad1: UInt8 = 0
    public var plasmaNumber: UInt16
    public var pad2: UInt16 = 0

    public init(type: UInt8 = 8,
                war: UInt8,
                status: UInt8,
                pad1: UInt8 = 0,
                plasmaNumber: UInt16,
                pad2: UInt16 = 0) {
        self.type = type
        self.war = war
        self.status = status
        self.pad1 = pad1
        self.plasmaNumber = plasmaNumber
        self.pad2 = pad2
    }

    public var size: Int {
        return 8
    }
}

// SP_PLASMA 9
public struct SP_PLASMA {
    public var type: UInt8 = 9
    public var direction: UInt8
    public var plasmaNum: UInt16
    public var positionX: UInt32
    public var positionY: UInt32

    public init(type: UInt8 = 9,
                direction: UInt8,
                plasmaNum: UInt16,
                positionX: UInt32,
                positionY: UInt32) {
        self.type = type
        self.direction = direction
        self.plasmaNum = plasmaNum
        self.positionX = positionX
        self.positionY = positionY
    }

    public var size: Int {
        return 12
    }
}

// SP_MOTD 11
public struct SP_MOTD {
    public var type: UInt8 = 11
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

    public init(type: UInt8 = 11,
                pad1: UInt8 = 0,
                pad2: UInt8 = 0,
                pad3: UInt8 = 0,
                motd: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
                    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.type = type
        self.pad1 = pad1
        self.pad2 = pad2
        self.pad3 = pad3
        self.motd = motd
    }

    public var size: Int {
        return 84
    }
}

//SP_YOU 12
public struct SP_YOU {
    public var type: UInt8 = 12
    public var playerNum: UInt8
    public var hostile: UInt8
    public var war: UInt8
    public var armies: UInt8
    public var tractor: UInt8
    public var pad2: UInt8 = 0
    public var pad3: UInt8 = 0
    public var flags: UInt32
    public var damage: UInt32
    public var shield: UInt32
    public var fuel: UInt32
    public var etmp: UInt16
    public var wtmp: UInt16
    public var whydead: UInt16
    public var whodead: UInt16

    public init(type: UInt8 = 12,
                playerNum: UInt8,
                hostile: UInt8,
                war: UInt8,
                armies: UInt8,
                tractor: UInt8,
                pad2: UInt8 = 0,
                pad3: UInt8 = 0,
                flags: UInt32,
                damage: UInt32,
                shield: UInt32,
                fuel: UInt32,
                etmp: UInt16,
                wtmp: UInt16,
                whydead: UInt16,
                whodead: UInt16) {
        self.type = type
        self.playerNum = playerNum
        self.hostile = hostile
        self.war = war
        self.armies = armies
        self.tractor = tractor
        self.pad2 = pad2
        self.pad3 = pad3
        self.flags = flags
        self.damage = damage
        self.shield = shield
        self.fuel = fuel
        self.etmp = etmp
        self.wtmp = wtmp
        self.whydead = whydead
        self.whodead = whodead
    }

    public var size: Int {
        return 32
    }
}

//SP_QUEUE 13
public struct SP_QUEUE {
    public var type: UInt8 = 13
    public var pad1: UInt8 = 0
    public var position: UInt16

    public init(type: UInt8 = 13,
                pad1: UInt8 = 0,
                position: UInt16) {
        self.type = type
        self.pad1 = pad1
        self.position = position
    }

    public var size: Int {
        return 4
    }
}

//SP_PLANET 15
public struct SP_PLANET {
    public var type: UInt8 = 15
    public var planetNum: UInt8
    public var owner: UInt8
    public var info: UInt8 = 0
    public var flags: UInt16
    public var pad2: UInt16 = 0
    public var armies: UInt32

    public init(type: UInt8 = 15,
                planetNum: UInt8,
                owner: UInt8,
                info: UInt8 = 0,
                flags: UInt16,
                pad2: UInt16 = 0,
                armies: UInt32) {
        self.type = type
        self.planetNum = planetNum
        self.owner = owner
        self.info = info
        self.flags = flags
        self.pad2 = pad2
        self.armies = armies
    }

    public var size: Int {
        return 12
    }
}

//SP_PICKOK 16
public struct SP_PICKOK {
    public var type: UInt8 = 16
    public var state: UInt8  // 0=no, 1=yes
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0

    public init(type: UInt8 = 16,
                state: UInt8,
                pad1: UInt8 = 0,
                pad2: UInt8 = 0) {
        self.type = type
        self.state = state
        self.pad1 = pad1
        self.pad2 = pad2
    }

    public var size: Int {
        return 4
    }
}

//SP_LOGIN 17
public struct SP_LOGIN {
    public var type: UInt8 = 17
    public var accept: UInt8
    public var paradise1: UInt8 = 0
    public var paradise2: UInt8 = 0
    public var flags: UInt32 = 0

    // KEYMAP_LEN is 96 in classic defs.h, which makes the packet 104 bytes
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

    public init(type: UInt8 = 17,
                accept: UInt8,
                paradise1: UInt8 = 0,
                paradise2: UInt8 = 0,
                flags: UInt32 = 0,
                keymap: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
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
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.type = type
        self.accept = accept
        self.paradise1 = paradise1
        self.paradise2 = paradise2
        self.flags = flags
        self.keymap = keymap
    }

    public var size: Int {
        return 104
    }
}

//SP_FLAGS 18
public struct SP_FLAGS {
    public var type: UInt8 = 18
    public var playerID: UInt8
    public var tractor: UInt8
    public var pad1: UInt8 = 0
    public var flags: UInt32

    public init(type: UInt8 = 18,
                playerID: UInt8,
                tractor: UInt8,
                pad1: UInt8 = 0,
                flags: UInt32) {
        self.type = type
        self.playerID = playerID
        self.tractor = tractor
        self.pad1 = pad1
        self.flags = flags
    }

    public var size: Int {
        return 8
    }
}

//SP_MASK 19
public struct SP_MASK {
    public var type: UInt8 = 19
    public var mask: UInt8
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0

    public init(type: UInt8 = 19,
                mask: UInt8,
                pad1: UInt8 = 0,
                pad2: UInt8 = 0) {
        self.type = type
        self.mask = mask
        self.pad1 = pad1
        self.pad2 = pad2
    }

    public var size: Int {
        return 4
    }
}

//SP_PSTATUS 20
public struct SP_PLAYER_STATUS {
    public var type: UInt8 = 20
    public var playerNum: UInt8
    public var status: UInt8
    public var pad1: UInt8 = 0

    public init(type: UInt8 = 20,
                playerNum: UInt8,
                status: UInt8,
                pad1: UInt8 = 0) {
        self.type = type
        self.playerNum = playerNum
        self.status = status
        self.pad1 = pad1
    }

    public var size: Int {
        return 4
    }
}

//SP_HOSTILE 22
public struct SP_HOSTILE {
    public var type: UInt8 = 22
    public var playerID: UInt8
    public var war: UInt8
    public var hostile: UInt8

    public init(type: UInt8 = 22,
                playerID: UInt8,
                war: UInt8,
                hostile: UInt8) {
        self.type = type
        self.playerID = playerID
        self.war = war
        self.hostile = hostile
    }

    public var size: Int {
        return 4
    }
}

//SP_STATS 23
public struct SP_STATS {
    public var type: UInt8 = 23
    public var playerID: UInt8
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var tournamentKills: UInt32
    public var tournamentLosses: UInt32
    public var overallKills: UInt32
    public var overallLosses: UInt32
    public var tournamentTicks: UInt32
    public var tournamentPlanets: UInt32
    public var tournamentArmies: UInt32
    public var starbaseKills: UInt32
    public var starbaseLosses: UInt32
    public var intramuralArmies: UInt32
    public var intramuralPlanets: UInt32
    public var maxKills100: UInt32
    public var starbaseMaxKills100: UInt32

    public init(type: UInt8 = 23,
                playerID: UInt8,
                pad1: UInt8 = 0,
                pad2: UInt8 = 0,
                tournamentKills: UInt32,
                tournamentLosses: UInt32,
                overallKills: UInt32,
                overallLosses: UInt32,
                tournamentTicks: UInt32,
                tournamentPlanets: UInt32,
                tournamentArmies: UInt32,
                starbaseKills: UInt32,
                starbaseLosses: UInt32,
                intramuralArmies: UInt32,
                intramuralPlanets: UInt32,
                maxKills100: UInt32,
                starbaseMaxKills100: UInt32) {
        self.type = type
        self.playerID = playerID
        self.pad1 = pad1
        self.pad2 = pad2
        self.tournamentKills = tournamentKills
        self.tournamentLosses = tournamentLosses
        self.overallKills = overallKills
        self.overallLosses = overallLosses
        self.tournamentTicks = tournamentTicks
        self.tournamentPlanets = tournamentPlanets
        self.tournamentArmies = tournamentArmies
        self.starbaseKills = starbaseKills
        self.starbaseLosses = starbaseLosses
        self.intramuralArmies = intramuralArmies
        self.intramuralPlanets = intramuralPlanets
        self.maxKills100 = maxKills100
        self.starbaseMaxKills100 = starbaseMaxKills100
    }

    public var size: Int {
        return 56
    }
}

//SP_PL_LOGIN 24
public struct SP_PL_LOGIN {
    public var type: UInt8 = 24
    public var playerNum: UInt8
    public var rank: UInt8
    public let pad1: UInt8 = 0
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var monitor: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var login: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    public init(type: UInt8 = 24,
                playerNum: UInt8,
                rank: UInt8,
                name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
                monitor: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
                login: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.type = type
        self.playerNum = playerNum
        self.rank = rank
        self.name = name
        self.monitor = monitor
        self.login = login
    }

    public var size: Int {
        return 52
    }
}

// SP_PLANET_LOC 26
public struct SP_PLANET_LOC {
    public var type: UInt8 = 26
    public var planetID: UInt8
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0
    public var positionX: Int32
    public var positionY: Int32
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    public init(type: UInt8 = 26,
                planetID: UInt8,
                pad1: UInt8 = 0,
                pad2: UInt8 = 0,
                positionX: Int32,
                positionY: Int32,
                name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.type = type
        self.planetID = planetID
        self.pad1 = pad1
        self.pad2 = pad2
        self.positionX = positionX
        self.positionY = positionY
        self.name = name
    }

    public var size: Int {
        return 28
    }
}

// SP_SHIP_CAP 39: a ship class's limits, for clients that asked for
// the SHIP_CAP feature. Same layout as struct ship_cap_spacket in the
// classic server's packets.h.
public struct SP_SHIP_CAP {
    public var type: UInt8 = 39
    public var operation: UInt8 = 0 // 0 = add or change a ship, 1 = remove it
    public var shipType: UInt16
    public var torpSpeed: UInt16
    public var phaserRange: UInt16
    public var maxSpeed: Int32
    public var maxFuel: Int32
    public var maxShield: Int32
    public var maxDamage: Int32
    public var maxWeaponTemp: Int32
    public var maxEngineTemp: Int32
    public var width: UInt16
    public var height: UInt16
    public var maxArmies: UInt16
    public var letter: UInt8
    public var pad2: UInt8 = 0
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var designation1: UInt8
    public var designation2: UInt8
    public var bitmap: UInt16

    public init(type: UInt8 = 39,
                operation: UInt8 = 0,
                shipType: UInt16,
                torpSpeed: UInt16,
                phaserRange: UInt16,
                maxSpeed: Int32,
                maxFuel: Int32,
                maxShield: Int32,
                maxDamage: Int32,
                maxWeaponTemp: Int32,
                maxEngineTemp: Int32,
                width: UInt16,
                height: UInt16,
                maxArmies: UInt16,
                letter: UInt8,
                pad2: UInt8 = 0,
                name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
                designation1: UInt8,
                designation2: UInt8,
                bitmap: UInt16) {
        self.type = type
        self.operation = operation
        self.shipType = shipType
        self.torpSpeed = torpSpeed
        self.phaserRange = phaserRange
        self.maxSpeed = maxSpeed
        self.maxFuel = maxFuel
        self.maxShield = maxShield
        self.maxDamage = maxDamage
        self.maxWeaponTemp = maxWeaponTemp
        self.maxEngineTemp = maxEngineTemp
        self.width = width
        self.height = height
        self.maxArmies = maxArmies
        self.letter = letter
        self.pad2 = pad2
        self.name = name
        self.designation1 = designation1
        self.designation2 = designation2
        self.bitmap = bitmap
    }

    public var size: Int {
        return 60
    }
}
