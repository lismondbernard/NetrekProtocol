//
//  ClientPacketInits.swift
//  NetrekProtocol
//
//  Initialisers for NetrekWire's CP_* structs that need the client's own
//  types or settings. The CP_OUTFIT one is Darrell Root's, from his
//  packets.swift (2019).
//

import Foundation
import NetrekWire

extension CP_OUTFIT {
    init(team: Team, ship: ShipType) {
        // menu option for independent and ogg does not exist.  Server only accepts 0-3, but it is inconsistent which team you get
        let teamByte: UInt8
        switch team {
            
        case .independent:
            teamByte = 255
        case .federation:
            teamByte = 0
        case .roman:
            teamByte = 1
        case .kazari:
            teamByte = 2
        case .orion:
            teamByte = 3
        case .ogg:
            teamByte = 255
        }
        //self.team = UInt8(team.rawValue)
        self.init(team: teamByte, ship: UInt8(ship.rawValue))
        debugPrint("CP_OUTFIT \(self.type) \(self.team) \(self.ship) \(self.pad1)")
    }
}

extension CP_UPDATES {
    /// Asks for UPDATE_RATE updates a second.
    init() {
        self.init(usecs: UInt32(1000000 / UPDATE_RATE).bigEndian)
    }
}
