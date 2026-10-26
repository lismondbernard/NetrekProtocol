//
//  Torpedo.swift
//  Netrek
//
//  Created by Darrell Root on 3/5/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/// One torpedo slot (8 per player). Updated from SP_TORP_INFO and SP_TORP.
public class Torpedo: ObservableObject {

    /// The universe this torpedo belongs to (set by `Universe`).
    public internal(set) weak var universe: Universe?

    public var torpedoId: Int = 0
    @Published public var status: UInt8 = 0
    //0 = inactive, 1=active, 2 = exploding?
    
    //public var displayed: Bool = false
    /// The teams this torpedo is hostile to.
    public private(set) var war: [Team:Bool] = [:]
    public var directionNetrek: Int = 0  // netrek format direction for now
    public var direction: Double = 0.0 // in radians
    @Published public var positionX: Int = 0
    @Published public var positionY: Int = 0
    // Interpolation state
    public var prevPositionX: Int = 0
    public var prevPositionY: Int = 0
    public var lastUpdateTime: Date = Date()
    public var updateTime: Date = Date()
    public var explodeTime: Date?

    public func reset() {
        self.positionX = 0
        self.positionY = 0
        self.prevPositionX = 0
        self.prevPositionY = 0
        self.lastUpdateTime = Date()
        self.updateTime = Date()
        self.explodeTime = nil
        self.status = 0
    }

    /// Set once this launch has been reported as nearby.
    private var nearbyReported = false
    /*var torpedoNode = SKSpriteNode(color: .red,
                                   size: CGSize(width: NetrekMath.torpedoSize, height: NetrekMath.torpedoSize))*/

    public init(torpedoId: Int) {
        self.torpedoId = torpedoId
    }
    public func update(war: UInt8, status: UInt8) {
        DispatchQueue.main.async {
            for team in Team.allCases {
                if UInt8(team.rawValue) & war != 0 {
                    self.war[team] = true
                } else {
                    self.war[team] = false
                }
            }
            //DispatchQueue.main.async {
                if (status == 2 || status == 3) && self.status == 1 {
                    self.explodeTime = Date()
                } else if status == 0 {
                    self.explodeTime = nil
                }
                self.status = status
            //}
            if status == 1 {
                self.nearbyReported = false
            }
        }
    }
    public func update(directionNetrek: Int, positionX: Int, positionY: Int) {
        if self.status == 0 {
            return
        }
        self.prevPositionX = self.positionX
        self.prevPositionY = self.positionY
        self.lastUpdateTime = self.updateTime
        self.updateTime = Date()
        DispatchQueue.main.async {
            self.positionX = positionX
            self.positionY = positionY
        }
        if nearbyReported == false {
            let world = universe ?? Universe.universe
            let me = world.players[world.me]
            let taxiDistance = abs(me.positionX - self.positionX) + abs(me.positionY - self.positionY)
            if taxiDistance < NetrekMath.displayDistance / 4 {
                world.eventDelegate?.universe(world, torpedoNearby: self, distance: taxiDistance)
                nearbyReported = true
            }
        }
    }
}
