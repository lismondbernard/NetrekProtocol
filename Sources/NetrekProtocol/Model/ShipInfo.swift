//
//  Ship.swift
//  Netrek
//
//  Created by Darrell Root on 3/9/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

/// A ship class's limits, from SP_SHIP_CAP.
public class ShipInfo {
    public var shipType: ShipType
    public var torpSpeed: Int
    public var phaserRange: Int
    public var phaserRecharge: Double {
        switch self.shipType {
        case .battleship:
            return 0.5
        default:
            return 1.0
        }
    }
    public var maxSpeed: Int
    public var maxFuel: Int
    public var maxShield: Int
    public var maxDamage: Int
    public var maxWpnTmp: Int
    public var maxEngTmp: Int
    public var width: Int
    public var height: Int
    public var maxArmies: Int
    //var letter: String
    //var shipName: String
    //var designator: String
    //var bitmap: Int
    
    public init(shipType: ShipType, torpSpeed: Int, phaserRange: Int, maxSpeed: Int, maxFuel: Int, maxShield: Int, maxDamage: Int, maxWpnTmp: Int, maxEngTmp: Int, width: Int, height: Int, maxArmies: Int) {
        self.shipType = shipType
        self.torpSpeed = torpSpeed
        self.phaserRange = phaserRange
        self.maxSpeed = maxSpeed
        self.maxFuel = maxFuel
        self.maxShield = maxShield
        self.maxDamage = maxDamage
        self.maxWpnTmp = maxWpnTmp
        self.maxEngTmp = maxEngTmp
        self.width = width
        self.height = height
        self.maxArmies = maxArmies
        
    }
}
