//
//  Player.swift
//  Netrek
//
//  Created by Darrell Root on 3/2/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/// One player slot (0-31). Updated from SP_PLAYER_INFO, SP_PLAYER, SP_YOU,
/// SP_FLAGS, SP_PSTATUS, SP_HOSTILE, SP_STATS, SP_PL_LOGIN and SP_KILLS.
public class Player: CustomStringConvertible, ObservableObject {
    //static let shieldFactory = ShieldFactory()
    
    public static let SHIELDFLAG: UInt32 = 0x0001
    public static let REPAIRFLAG: UInt32 = 0x0002
    public static let BOMBFLAG: UInt32 = 0x0004
    public static let ORBITFLAG: UInt32 = 0x0008
    public static let CLOAKFLAG: UInt32 = 0x0010
    public static let WEPFLAG: UInt32 = 0x0020
    public static let ENGFLAG: UInt32 = 0x0040
    public static let BEAMUPFLAG: UInt32 = 0x0100
    public static let BEAMDOWNFLAG: UInt32 = 0x0200
    public static let SELFDESTRUCTFLAG: UInt32 = 0x0400
    public static let GREENFLAG: UInt32 = 0x0800
    public static let YELLOWFLAG: UInt32 = 0x1000
    public static let REDFLAG: UInt32 = 0x2000
    public static let PLAYERLOCKFLAG: UInt32 = 0x4000
    public static let PLANETLOCKFLAG: UInt32 = 0x8000
    public static let WARSETFLAG: UInt32 = 0x10000
    public static let DOCKFLAG: UInt32 = 0x80000
    public static let REFITFLAG: UInt32 = 0x100000
    public static let REFITTINGFLAG: UInt32 = 0x200000
    public static let TRACTORFLAG: UInt32 = 0x400000
    public static let PRESSORFLAG: UInt32 = 0x800000
    public static let DOCKOKFLAG: UInt32 = 0x1000000

    /// The universe this player belongs to (set by `Universe`).
    public internal(set) weak var universe: Universe?
    /// `universe`, or the shared one for a player made on its own.
    private var world: Universe { universe ?? Universe.universe }

    public var detonated = false //set to true when blowing up
    public var explodeTime: Date?

    public private(set) var playerId: Int = 0

    //private(set) var hostile = 0
    public private(set) var hostile: [Team:Bool] = [:]
    public private(set) var war: [Team:Bool] = [:]
    public private(set) var armies = 0
    public private(set) var tractor = 0
    public private(set) var flags: UInt32 = 0
    public private(set) var damage = 0
    public private(set) var shieldStrength = 100
    public private(set) var fuel = 10000
    public private(set) var engineTemp = 0
    public private(set) var weaponsTemp = 0
    public private(set) var whyDead: Int?
    public private(set) var whoDead: Int?
    
    //stats mostly from SP_STATS 23
    public private(set) var tournamentKills: Int = 0
    public private(set) var tournamentLosses: Int = 0
    public private(set) var overallKills: Int = 0
    public private(set) var overallLosses: Int = 0
    public private(set) var tournamentTicks: Int = 0
    public private(set) var tournamentPlanets: Int = 0
    public private(set) var tournamentArmies: Int = 0
    public private(set) var starbaseKills: Int = 0
    public private(set) var starbaseLosses: Int = 0
    public private(set) var practiceArmies: Int = 0
    public private(set) var practicePlanets: Int = 0
    public private(set) var maxKills: Double = 0.0
    public private(set) var sbMaxKills: Double = 0.0
    
    public private(set) var playing = false
    @Published public private(set) var team: Team = .independent
    @Published public private(set) var ship: ShipType?
    @Published public var throttle: Int = 0 { // used for "me" by tacticalView
        didSet {
            if throttle > 12 { throttle = 12 }
            if throttle < 0 { throttle = 0 }
        }
    }
    @Published public private(set) var positionX: Int = NetrekMath.galacticSize / 2
    @Published public private(set) var positionY: Int = NetrekMath.galacticSize / 2
    public private(set) var me: Bool = false
    public private(set) var name: String = "nobody"
    //
    public private(set) var lastAlivePositionX: Int = 0
    public private(set) var lastAlivePositionY: Int = 0
    public private(set) var lastUpdateTime = Date()
    public private(set) var updateTime = Date()
    // Interpolation: previous server position (non-Published, read at draw time)
    public var prevPositionX: Int = NetrekMath.galacticSize / 2
    public var prevPositionY: Int = NetrekMath.galacticSize / 2
    public var prevDirection: Double = 0.0
    // from flags
    @Published public private(set) var shieldsUp = false
    //
    // from packet type 24
    public private(set) var rank: Rank = .ensign
    public private(set) var login = "unknown"
    // from packet type 3
    public private(set) var kills = 0.0
    public private(set) var slotStatus: SlotStatus = .free {
        didSet {
            let world = self.world
            let myShip = world.players[world.me]
            if slotStatus == .explode && (myShip.slotStatus == .alive || myShip.slotStatus == .explode) {
                self.throttle = 0
                let xDistance = abs(myShip.lastAlivePositionX - self.positionX)
                let yDistance = abs(myShip.lastAlivePositionY - self.positionY)
                let taxiDistance = xDistance + yDistance
                world.eventDelegate?.universe(world, playerExploded: self, distance: taxiDistance)
            }
        }
    } //free=0 outfit=1 alive=2 explode=3 dead=4 observe=5
    // from packet type 4
    public private(set) var lastSlotStatus: SlotStatus = .free //free=0 outfit=1 alive=2 explode=3 dead=4 observe=5
    // flags from packet type 12
    public private(set) var repair = false
    public private(set) var bomb = false
    //private let cloakAction = SKAction.fadeOut(withDuration: 0.7)
    //private let unCloakAction = SKAction.fadeIn(withDuration: 0.7)
    //private let playerCloakAction = SKAction.fadeAlpha(to: 0.2, duration: 0.7)
    public private(set) var orbit = false {
        didSet {
            if orbit {
                self.throttle = 1
            }
        }
    }
    public private(set) var cloak = false /* {
        didSet {
            if oldValue == false && cloak == true {
                if me == true {
                    playerTacticalNode.run(playerCloakAction)
                } else {
                    playerTacticalNode.run(cloakAction)
                }
            }
            if oldValue == true && cloak == false {
                playerTacticalNode.run(unCloakAction)
            }
        }
    }*/
    public private(set) var weaponsOverheated = false
    public private(set) var enginesOverheated = false
    public private(set) var beamUp = false
    public private(set) var beamDown = false
    public private(set) var selfDestruct = false
    public private(set) var alertCondition: AlertCondition = .green
    public private(set) var playerLock = false
    public private(set) var planetLock = false
    public private(set) var settingWar = false
    public private(set) var docked = false
    public private(set) var tractorFlag = false
    public private(set) var pressor = false
    public private(set) var dockok = false
    

    public private(set) var direction: Double = 0.0 // 2 * Double.pi = 360 degrees
    public private(set) var speed = 0
    //var playerTacticalNode = SKSpriteNode()
    //let playerInfoAction = SKAction.sequence([SKAction.fadeOut(withDuration: 3.0),SKAction.removeFromParent()])
    
    public init(playerId: Int) {
        self.playerId = playerId
        self.remakeNode()
        
        //initializing hostile dictionary to minimize runtime errors later
        for team in Team.allCases {
            self.hostile[team] = false
            self.war[team] = false
        }
    }
    
    deinit {
        debugPrint("player ID \(playerId) deinit")
    }
    public func reset() {
        /*if playerTacticalNode.parent != nil {
            playerTacticalNode.removeAllActions()
            playerTacticalNode.removeFromParent()
        }*/
    }

    public var description: String {
        get {
            return "Player \(String(describing: playerId)) name \(name) armies \(armies) damage \(damage) shield \(shieldStrength) fuel \(fuel) eTmp \(engineTemp) ship \(String(describing: ship)) team \(String(describing: team)) wTmp \(weaponsTemp) playing \(playing) positionX \(positionX) positionY \(positionY) login \(login) rank \(rank)"
        }
    }
    public func showInfo() {
        if self.cloak == true { return }
        let infoString: String = "\(self.name) \(self.ship?.description ?? "??") \(self.kills) kills"
        let playerLetter = NetrekMath.playerLetter(playerId: self.playerId)
        world.gotMessage("\(self.team.letter)\(playerLetter) \(infoString)")
    }

    public var playerStrategicText: String {
        if self.cloak == true {
            return "??"
        } else {
            let playerLetter = NetrekMath.playerLetter(playerId: self.playerId)
            let teamLetter = NetrekMath.teamLetter(team: self.team)
            return teamLetter + playerLetter
        }
    }

    public func remakeNode() {
        self.updateNode()
    }
    private func updateNode() {
        //    private(set) var status = 0  //free=0 outfit=1 alive=2 explode=3 dead=4 observe=5
        
        if self.slotStatus != self.lastSlotStatus {
            
        switch self.slotStatus {
            case .free:
                break
            case .outfit:
                if me {
                    DispatchQueue.main.async {
                        let world = self.world
                        world.eventDelegate?.universeServerReadyForOutfit(world)
                    }
                }
            case .alive:
                break
            case .explode:
                if me && self.lastSlotStatus == .alive {
                    DispatchQueue.main.async {
                        let world = self.world
                        world.eventDelegate?.universeMyShipDestroyed(world)
                    }
            }
            case .dead:
                if me && self.lastSlotStatus == .alive {
                    DispatchQueue.main.async {
                        let world = self.world
                        world.eventDelegate?.universeMyShipDestroyed(world)
                    }
            }
            case .observe:
                //self.playerTacticalNode.isHidden = true
                break
            }
            self.lastSlotStatus = self.slotStatus
        }
        /*if shieldsUp {
            self.shieldNode.isHidden = false
        } else {
            self.shieldNode.isHidden = true
        }*/
        if self.slotStatus == .alive && self.positionX > 0 && self.positionX < NetrekMath.galacticSize && self.positionY > 0 && self.positionY < NetrekMath.galacticSize {
            //self.playerTacticalNode.position = CGPoint(x: positionX, y: positionY)
            //self.playerTacticalNode.zRotation = self.direction
            /*let deltaX = self.positionX - self.lastPositionX
            let deltaY = self.positionY - self.lastPositionY
            let deltaTime = self.updateTime.timeIntervalSince(self.lastUpdateTime)
            if deltaX < NetrekMath.actionThreshold && deltaY < NetrekMath.actionThreshold && deltaTime < 2.0 && deltaTime > 0.04 {
                let action = SKAction.moveBy(x: CGFloat(deltaX), y: CGFloat(deltaY), duration: deltaTime)
                DispatchQueue.main.async {
                    self.playerTacticalNode.removeAllActions()
                    self.playerTacticalNode.run(action)
                }
                debugPrint("running action player \(playerID) deltaX \(deltaX) deltaY \(deltaY) deltaTime \(deltaTime)")
            } else {
                debugPrint("Player.update.noAction playerID \(String(describing: playerID)) deltaX \(deltaX) deltaY \(deltaY) deltaT \(deltaTime)")
            }*/
            if self.me {
                /*if self.shieldStrength < 20 {
                    self.shieldNode.alpha = 0.2
                } else if shieldStrength > 100 {
                    self.shieldNode.alpha = 1.0
                } else {
                    self.shieldNode.alpha = CGFloat(self.shieldStrength) / 100.0
                }*/
            }
        }
    }
    
    // swiftlint:disable:next function_parameter_count - one parameter per packet field
    public func updateMe(myPlayerId: Int, hostile: UInt32, war: UInt32, armies: Int, tractor: Int, flags: UInt32, damage: Int, shieldStrength: Int, fuel: Int, engineTemp: Int, weaponsTemp: Int, whyDead: Int, whoDead: Int) {
        
        // try to call this in the main queue
        // or we get intermittent crashes
        
        if self.playerId != myPlayerId {
            debugPrint("Player.updateMe: ERROR: inconsistent player ID \(myPlayerId) versus \(String(describing: self.playerId))")
        }
        self.me = true
        //self.hostile = hostile //TODO break this up
        for team in Team.allCases {
            if UInt32(team.rawValue) & hostile != 0 {
                self.hostile[team] = true
            } else {
                self.hostile[team] = false
            }
        }
        //self.war = war // TODO break this up
        for team in Team.allCases {
            if UInt32(team.rawValue) & war != 0 {
                self.war[team] = true
            } else {
                self.war[team] = false
            }
        }
        self.armies = armies
        //if tractor is between 64 and 95, tractor target is tractor - 40
        self.tractor = tractor
        self.damage = damage
        self.shieldStrength = shieldStrength
        self.fuel = fuel
        self.engineTemp = engineTemp
        self.weaponsTemp = weaponsTemp
        self.whyDead = whyDead
        self.whoDead = whoDead
        if flags & PlayerStatus.shield.rawValue != 0 {
            self.shieldsUp = true
        } else {
            self.shieldsUp = false
        }
        if flags & PlayerStatus.repair.rawValue != 0 {
            self.repair = true
        } else {
            self.repair = false
        }
        if flags & PlayerStatus.bomb.rawValue != 0 {
            self.bomb = true
        } else {
            self.bomb = false
        }
        if flags & PlayerStatus.weaponTemp.rawValue != 0 {
            self.weaponsOverheated = true
        } else {
            self.weaponsOverheated = false
        }
        if flags & PlayerStatus.engineTemp.rawValue != 0 {
            self.enginesOverheated = true
        } else {
            self.enginesOverheated = false
        }

        if flags & PlayerStatus.tractor.rawValue != 0 {
            self.tractorFlag = true
        } else {
            self.tractorFlag = false
        }
        if flags & PlayerStatus.pressor.rawValue != 0 {
            self.pressor = true
        } else {
            self.pressor = false
        }
        //self.flags = flags

        //if flags & UInt32(0x0002) != 0 { repair = true } else { repair = false }
        //if flags & UInt32(0x0004) != 0 { bomb = true } else { bomb = false }
        if flags & UInt32(0x0008) != 0 { orbit = true } else { orbit = false }
        if flags & UInt32(0x0010) != 0 { cloak = true } else { cloak = false }
        //if flags & UInt32(0x0020) != 0 { weaponsOverheated = true } else { weaponsOverheated = false }
        //if flags & UInt32(0x0040) != 0 { enginesOverheated = true } else { enginesOverheated = false }
        if flags & UInt32(0x0100) != 0 { beamUp = true } else { beamUp = false }
        if flags & UInt32(0x0200) != 0 { beamDown = true } else { beamDown = false }
        if flags & UInt32(0x0400) != 0 { selfDestruct = true } else { selfDestruct = false }
        if flags & UInt32(0x0800) != 0 { alertCondition = .green }
        if flags & UInt32(0x1000) != 0 { alertCondition = .yellow }
        if flags & UInt32(0x2000) != 0 { alertCondition = .red }
        if flags & UInt32(0x4000) != 0 { playerLock = true } else { playerLock = false }
        if flags & UInt32(0x8000) != 0 { planetLock = true } else { planetLock = false }
        if flags & UInt32(0x10000) != 0 { settingWar = true } else { settingWar = false }
        if flags & UInt32(0x80000) != 0 { docked = true } else { docked = false }

        if flags & UInt32(0x400000) != 0 { tractorFlag = true } else { tractorFlag = false }
        
        if flags & UInt32(0x800000) != 0 { pressor = true } else { pressor = false }
        if flags & UInt32(0x1000000) != 0 { dockok = true } else { dockok = false }
        self.updateNode()
    }
    public func update(shipType: Int) {
        for shipCase in ShipType.allCases {
            if shipCase.rawValue == shipType {
                if shipCase != self.ship {
                    self.ship = shipCase
                    self.remakeNode()
                }
                return
            }
        }
        debugPrint("Player.update invalid shipType \(shipType)")
    }
    public func update(team: Int) {
        for teamCase in Team.allCases {
            if teamCase.rawValue == team {
                if self.team != teamCase {
                    self.team = teamCase
                    self.remakeNode()
                }
                return
            }
        }
        debugPrint("Player.update invalid team \(team)")
    }
    public func update(kills: Double) {
        self.kills = kills
    }
    // from SP_PLAYER 4
    public func update(directionNetrek: UInt8, speed: Int, positionX: Int, positionY: Int) {
        // To support animations, if direction change is > 270 degrees, adjust by 2 * pi
        let oldDirection = self.direction
        
        //var newDirection = Double.pi * ((Double(directionNetrek) / -128.0) + 0.5)
        var newDirection: Double = NetrekMath.directionNetrek2radian(UInt8(directionNetrek))
        
        while oldDirection > newDirection + Double.pi {
            newDirection += 2 * Double.pi
        }
        while oldDirection < newDirection - Double.pi {
            newDirection -= 2 * Double.pi
        }
        /*if me {
            debugPrint("oldDirection \(oldDirection) newDirection \(newDirection)")
        }*/
        self.direction = newDirection
        //self.direction = NetrekMath.directionNetrek2radian(UInt8(directionNetrek))
        self.speed = speed
        if self.slotStatus == .alive {
            self.lastAlivePositionX = positionX
            self.lastAlivePositionY = positionY
        }
        self.prevPositionX = self.positionX
        self.prevPositionY = self.positionY
        self.prevDirection = self.direction
        self.lastUpdateTime = self.updateTime
        self.updateTime = Date()
        DispatchQueue.main.async {
            self.positionX = positionX
            self.positionY = positionY
        }
        self.updateNode()
        /* for debugging only
         if me && self.direction < CGFloat.pi {
            // do nothing
            debugPrint("self.direction \(self.direction)")
        }*/
    }
    // from SP_FLAGS_18
    public func update(tractor: Int, flags: UInt32) {
        self.tractor = tractor
        self.flags = flags
        DispatchQueue.main.async {
            if flags & PlayerStatus.shield.rawValue != 0 {
                self.shieldsUp = true
            } else {
                self.shieldsUp = false
            }
            if flags & PlayerStatus.cloak.rawValue != 0 {
                self.cloak = true
            } else {
                self.cloak = false
            }
        }
    }
    // from SP_PSTATUS_20
    public func update(sp_pstatus: Int) {
        DispatchQueue.main.async {
            switch sp_pstatus {
            case 0:
                self.slotStatus = .free
            case 1:
                self.slotStatus = .outfit
                self.updateNode()
            case 2:
                self.slotStatus = .alive
                self.detonated = false
                self.explodeTime = nil
                self.updateNode()
            case 3:
                if self.slotStatus != .explode {
                    self.explodeTime = Date()
                }
                self.slotStatus = .explode
                self.updateNode()
            case 4:
                self.slotStatus = .dead
            case 5:
                self.slotStatus = .observe
            default:
                debugPrint("Player.update.SP_PSTATUS invalid slot status \(sp_pstatus)")
            }
        }
    }

    // from SP_HOSTILE_22
    public func update(war: UInt32, hostile: UInt32) {
        for team in Team.allCases {
            if UInt32(team.rawValue) & hostile != 0 {
                self.hostile[team] = true
            } else {
                self.hostile[team] = false
            }
        }
        //self.war = war // TODO break this up
        for team in Team.allCases {
            if UInt32(team.rawValue) & war != 0 {
                self.war[team] = true
            } else {
                self.war[team] = false
            }
        }
        /*for team in Team.allCases {
            debugPrint("player \(String(describing: playerID)) is on team \(self.team) and is hostile:\(self.hostile) with team \(team)" )
            debugPrint("player \(String(describing: playerID)) is on team \(self.team) and is war:\(self.war) with team \(team)" )
        }*/
    }
    // from SP_STATS 23
    // swiftlint:disable:next function_parameter_count - one parameter per packet field
    public func updatePlayer(playerId: Int, tournamentKills: Int, tournamentLosses: Int, overallKills: Int, overallLosses: Int, tournamentTicks: Int, tournamentPlanets: Int, tournamentArmies: Int, starbaseKills: Int, starbaseLosses: Int, practiceArmies: Int, practicePlanets: Int, maxKills: Double, sbMaxKills: Double) {
        self.tournamentKills = tournamentKills
        self.tournamentLosses = tournamentLosses
        self.overallKills = overallKills
        self.overallLosses = overallLosses
        self.tournamentTicks = tournamentTicks
        self.tournamentPlanets = tournamentPlanets
        self.tournamentArmies = tournamentArmies
        self.starbaseKills = starbaseKills
        self.starbaseLosses = starbaseLosses
        self.practiceArmies = practiceArmies
        self.practicePlanets = practicePlanets
        self.maxKills = maxKills
        self.sbMaxKills = sbMaxKills
    }

    public func update(rank: Int, name: String, login: String) {
        for netrekRank in Rank.allCases {
            if netrekRank.rawValue == rank {
                self.rank = netrekRank
            }
        }
        self.name = name
        self.login = login
    }
}

