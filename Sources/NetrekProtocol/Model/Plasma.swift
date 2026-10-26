//
//  Plasma.swift
//  Netrek
//
//  Created by Darrell Root on 3/5/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/// One plasma slot (1 per player). Updated from SP_PLASMA_INFO and SP_PLASMA.
public class Plasma: ObservableObject {

    /// The universe this plasma belongs to (set by `Universe`).
    public internal(set) weak var universe: Universe?

    public private(set) var plasmaId: Int
    @Published public private(set) var status = 0
    public private(set) var war: [Team:Bool] = [:]
    public private(set) var directionNetrek = 0
    public private(set) var direction = 0.0
    @Published public private(set) var positionX = 0
    @Published public private(set) var positionY = 0
    // Interpolation state
    public var prevPositionX: Int = 0
    public var prevPositionY: Int = 0
    public var lastUpdateTime: Date = Date()
    public var updateTime: Date = Date()
    public var explodeTime: Date?

    /// Set once this launch has been reported as nearby.
    private var nearbyReported = false

    public init(plasmaId: Int) {
        self.plasmaId = plasmaId
    }
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

    //from SP_PLASMA_INFO 8
    public func update(plasmaId: Int, war: UInt8, status: Int) {
        DispatchQueue.main.async {
            self.plasmaId = plasmaId
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
    // from SP_PLASMA 9
    public func update(positionX: Int, positionY: Int) {
        self.prevPositionX = self.positionX
        self.prevPositionY = self.positionY
        self.lastUpdateTime = self.updateTime
        self.updateTime = Date()
        DispatchQueue.main.async {
            self.positionX = positionX
            self.positionY = positionY
            if self.nearbyReported == false {
                let world = self.universe ?? Universe.universe
                let me = world.me
                let taxiDistance = abs(world.players[me].positionX - self.positionX) + abs(world.players[me].positionY - self.positionY)
                if taxiDistance < NetrekMath.displayDistance / 3 {
                    world.eventDelegate?.universe(world, plasmaNearby: self, distance: taxiDistance)
                    self.nearbyReported = true
                }
            }
        }
    }
}
