//
//  Laser.swift
//  Netrek
//
//  Created by Darrell Root on 3/5/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/// One laser (phaser) slot, one per player. Updated from SP_PHASER.
public class Laser: ObservableObject {

    /// The universe this laser belongs to (set by `Universe`).
    public internal(set) weak var universe: Universe?
    private var world: Universe { universe ?? Universe.universe }

    public private(set) var laserId: Int
    @Published public private(set) var status = 0
    @Published public private(set) var directionNetrek: UInt8 = 0 // 256= full circle
    public private(set) var direction = 0.0 //radians
    @Published public private(set) var positionX = 0
    @Published public private(set) var positionY = 0
    @Published public private(set) var targetPositionX = 0
    @Published public private(set) var targetPositionY = 0
    public private(set) var target = 0
    public let laserRange = 600.0 // game units
    public var fireTime: Date = Date()
    
    public init(laserId: Int) {
        self.laserId = laserId
    }
    
    public func reset() {
        self.positionX = 0
        self.positionY = 0
        self.targetPositionX = 0
        self.targetPositionY = 0
        self.fireTime = Date()
        self.status = 0
    }
    
    public func update(laserId: Int, status: Int, directionNetrek: UInt8, positionX: Int, positionY: Int, target: Int) {
        DispatchQueue.main.async {
            self.laserId = laserId
            self.status = status
            self.directionNetrek = directionNetrek
            self.direction = 2.0 * Double.pi * Double(directionNetrek) / 256.0
            self.positionX = self.world.players[laserId].positionX
            self.positionY = self.world.players[laserId].positionY
            self.target = target
            if self.status != 0 {
                self.fireTime = Date()
                self.displayLaser()
            }
        }
    }
    public func displayLaser() {
        let world = self.world
        guard let source = world.players[safe: self.laserId] else { return }
        let me = world.me
        let taxiDistance = abs(world.players[me].positionX - source.positionX) + abs(world.players[me].positionY - source.positionY)
        guard taxiDistance < NetrekMath.displayDistance / 2 else { return }
        world.eventDelegate?.universe(world, laserFired: self, distance: taxiDistance)
        switch self.status{
            
        case 1: // hit
            guard let target = world.players[safe: target] else {
                return
            }
            //let sourcePoint = CGPoint(x: source.positionX, y: source.positionY)
            self.targetPositionX = target.positionX
            self.targetPositionY = target.positionY
        case 2: // miss
            self.direction = NetrekMath.directionNetrek2radian(self.directionNetrek)
            self.targetPositionX = Int(Double(source.positionX) + cos(self.direction) * laserRange)
            self.targetPositionY = Int(Double(source.positionY) + sin(self.direction) * laserRange)
        case 4: // hit plasma TODO
            guard let target = world.plasmas[safe: target] else {
                return
            }
            //let sourcePoint = CGPoint(x: source.positionX, y: source.positionY)
            self.targetPositionX = target.positionX
            self.targetPositionY = target.positionY
            break

        default: // should not get here
            debugPrint("Laser.displayLaser invalid status \(status)")
        }
    }
    
}
