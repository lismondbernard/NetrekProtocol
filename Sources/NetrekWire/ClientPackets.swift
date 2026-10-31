//
//  ClientPackets.swift
//  NetrekWire
//
//  Created by Darrell Root on 3/3/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//
//  The client-to-server (CP_*) packets. Each struct is laid out in memory
//  exactly as the packet goes on the wire, so a sender can copy it out
//  byte for byte. Multi-byte fields hold network byte order.
//

// could not get to align on byte boundaries ok
// had to import from C packets.h
/*struct CP_LOGIN {
 let type: UInt8 = 8
 let query: UInt8 = 1 // 0 means something
 let pad: UInt8 = 0
 let pad2: UInt8 = 0
 var name: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  // 16 UInt8 = NAME_LEN
 var password: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  // 16 UInt8
 var login: [UInt8] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]  // 16 UInt8

 //var name = Data(count: NAME_LEN)
 //var password = Data(count: NAME_LEN)
 //var login = Data(count: NAME_LEN)
 var size: Int {
 return 52
 }
 }*/

public struct CP_MESSAGE {
    public let type: UInt8 = 1
    public var group: UInt8 = 0
    public var indiv: UInt8 = 0
    public let pad1: UInt8 = 0
    public var mesg: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
        UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
        UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
        UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
        UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
        (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
         0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
         0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
         0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
         0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    public init(group: UInt8 = 0, indiv: UInt8 = 0,
                mesg: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
                    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.group = group
        self.indiv = indiv
        self.mesg = mesg
    }

    public var size: Int {
        return 4 + MSG_LEN
    }
}

public struct CP_SPEED {
    public let type: UInt8 = 2
    public var speed: UInt8 = 0
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0

    public init(speed: UInt8 = 0, pad1: UInt8 = 0, pad2: UInt8 = 0) {
        self.speed = speed
        self.pad1 = pad1
        self.pad2 = pad2
    }

    public var size: Int {
        return 4
    }
}

public struct CP_DIRECTION {
    public let type: UInt8 = 3
    public var direction: UInt8 = 0
    public var pad1: UInt8 = 0
    public var pad2: UInt8 = 0

    public init(direction: UInt8 = 0, pad1: UInt8 = 0, pad2: UInt8 = 0) {
        self.direction = direction
        self.pad1 = pad1
        self.pad2 = pad2
    }

    public var size: Int {
        return 4
    }
}

public struct CP_LASER {
    public let type: UInt8 = 4
    public var netrekDirection: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(netrekDirection: UInt8 = 0) {
        self.netrekDirection = netrekDirection
    }

    public var size: Int {
        return 4
    }
}

public struct CP_PLASMA {
    public let type: UInt8 = 5
    public var netrekDirection: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(netrekDirection: UInt8 = 0) {
        self.netrekDirection = netrekDirection
    }

    public var size: Int {
        return 4
    }
}
public struct CP_TORP {
    public let type: UInt8 = 6
    public var netrekDirection: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(netrekDirection: UInt8 = 0) {
        self.netrekDirection = netrekDirection
    }

    public var size: Int {
        return 4
    }
}

public struct CP_QUIT {
    public let type: UInt8 = 7
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0

    public init() {}

    public var size: Int {
        return 4
    }
}

// CP_LOGIN 8 is in packets.h due to array
public struct CP_LOGIN {
    public let type: UInt8 = 8
    public var query: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0
    public var name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var password: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    public var login: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    public init(query: UInt8 = 0,
                name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
                password: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0),
                login: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.query = query
        self.name = name
        self.password = password
        self.login = login
    }

    public var size: Int {
        return 52
    }
}

public struct CP_OUTFIT {
    public let type: UInt8 = 9
    public var team: UInt8 = 0
    public var ship: UInt8 = 0
    public let pad1: UInt8 = 0

    public init(team: UInt8 = 0, ship: UInt8 = 0) {
        self.team = team
        self.ship = ship
    }

    public var size: Int {
        get {
            return 4
        }
    }
}

// CP_WAR 10 not implemented

public struct CP_PRACTR {
    public let type: UInt8 = 11
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0

    public init() {}

    public var size: Int {
        get {
            return 4
        }
    }
}

public struct CP_SHIELD {
    public let type: UInt8 = 12
    public var state: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_REPAIR {
    public let type: UInt8 = 13
    public var state: UInt8 = 0  // on/off
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_ORBIT {
    public let type: UInt8 = 14
    public var state: UInt8 = 0  // on/off
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_PLANLOCK {
    public let type: UInt8 = 15
    public var planetID: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(planetID: UInt8 = 0) {
        self.planetID = planetID
    }

    public var size: Int {
        return 4
    }
}

public struct CP_PLAYLOCK {
    public let type: UInt8 = 16
    public var playerID: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(playerID: UInt8 = 0) {
        self.playerID = playerID
    }

    public var size: Int {
        return 4
    }
}

public struct CP_BOMB {
    public let type: UInt8 = 17
    public var state: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_BEAM {
    public let type: UInt8 = 18
    public var state: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_CLOAK {
    public let type: UInt8 = 19
    public var state: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_DET_TORPS {
    public let type: UInt8 = 20
    public var pad1: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0

    public init(pad1: UInt8 = 0) {
        self.pad1 = pad1
    }

    public var size: Int {
        return 4
    }
}

public struct CP_DET_MYTORP {
    public let type: UInt8 = 21
    public var pad1: UInt8 = 0
    public var tNumByte1: UInt8 = 0
    public var tNumByte2: UInt8 = 0

    public init(pad1: UInt8 = 0, tNumByte1: UInt8 = 0, tNumByte2: UInt8 = 0) {
        self.pad1 = pad1
        self.tNumByte1 = tNumByte1
        self.tNumByte2 = tNumByte2
    }

    public var size: Int {
        return 4
    }
}

// 22 copilot not implemented

public struct CP_REFIT {
    public let type: UInt8 = 23
    public var ship: UInt8 = 0
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0

    public init(ship: UInt8 = 0) {
        self.ship = ship
    }

    public var size: Int {
        return 4
    }
}

public struct CP_TRACTOR {
    public let type: UInt8 = 24
    public var state: UInt8 = 0
    public var playerID: UInt8 = 0
    public var pad: UInt8 = 0

    public init(state: UInt8 = 0, playerID: UInt8 = 0, pad: UInt8 = 0) {
        self.state = state
        self.playerID = playerID
        self.pad = pad
    }

    public var size: Int {
        return 4
    }
}
public struct CP_REPRESS {
    public let type: UInt8 = 25
    public var state: UInt8 = 0
    public var playerID: UInt8 = 0
    public var pad: UInt8 = 0

    public init(state: UInt8 = 0, playerID: UInt8 = 0, pad: UInt8 = 0) {
        self.state = state
        self.playerID = playerID
        self.pad = pad
    }

    public var size: Int {
        return 4
    }
}

public struct CP_COUP {
    public let type: UInt8 = 26
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0

    public init() {}

    public var size: Int {
        return 4
    }
}
public struct CP_SOCKET {
    public let type: UInt8 = 27
    public let version: UInt8
    public let udp_version: UInt8
    public let pad: UInt8 = 0
    //TODO: presumably we have to do something with this port
    /// The client's port, in network byte order.
    public let port: UInt32

    /// `port` must already be in network byte order.
    public init(version: UInt8, udpVersion: UInt8, port: UInt32) {
        self.version = version
        self.udp_version = udpVersion
        self.port = port
    }

    public var size: Int {
        return 8
    }
}

// 28 CP_OPTIONS not implamented

public struct CP_BYE {
    public let type: UInt8 = 29
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0

    public init() {}

    public var size: Int {
        return 4
    }
}

public struct CP_DOCKPERM {
    public let type: UInt8 = 30
    public var state: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0

    public init(state: UInt8 = 0) {
        self.state = state
    }

    public var size: Int {
        return 4
    }
}

public struct CP_UPDATES {
    public let type: UInt8 = 31
    public let pad1: UInt8 = 0
    public let pad2: UInt8 = 0
    public let pad3: UInt8 = 0
    /// Microseconds between updates, in network byte order.
    public let usecs: UInt32

    public init(usecs: UInt32) {
        self.usecs = usecs
    }

    public var size: Int {
        return 8
    }
}

public struct CP_FEATURE {
    public let type: UInt8 = 60
    public var feature_type: UInt8 = 0
    public var arg1: UInt8 = 0
    public var arg2: UInt8 = 0
    public var value: UInt32 = 0
    public var name:(UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)

    public init(feature_type: UInt8 = 0, arg1: UInt8 = 0, arg2: UInt8 = 0, value: UInt32 = 0,
                name: (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                    UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8) =
                    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
                     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)) {
        self.feature_type = feature_type
        self.arg1 = arg1
        self.arg2 = arg2
        self.value = value
        self.name = name
    }

    public var size: Int {
        return 88
    }
}

/* does not work but valiant attempt
struct CP_FEATURE {
    let type: UInt8 = 60
    let featureType: UInt8 = UInt8(ascii: "C")
    let arg1: UInt8 = 0
    let arg2: UInt8 = 0
    let value: UInt32
    var data = Data(count: 80)
    var size: Int {
        return 88
    }
    init(features: [String]) {
        debugPrint("data size \(MemoryLayout.size(ofValue:data))")
        debugPrint("data stride \(MemoryLayout.stride(ofValue:data))")
        debugPrint("data alignment \(MemoryLayout.alignment(ofValue:data))")

        value = UInt32(features.count).bigEndian
        var count = 0
        for feature in features {
            //do we have enough space remaining
            //for next feature
            if count + feature.count + 1 >= 80 {
                debugPrint("CP_FEATURE.init: Warning: Feature packet size exceeded")
                for _ in count..<80 {
                    data[count] = 0
                    count = count + 1
                }
                return
            }
            let feature = feature.utf8
            for char in feature {
                data[count] = char
                count = count + 1
            }
            data[count] = 0
            count = count + 1
        }
        // all features successfully added and null terminated.  now pad to 80
        for _ in count..<80 {
            data[count] = 0
            count = count + 1
        }
        return
    }
 }
 */
