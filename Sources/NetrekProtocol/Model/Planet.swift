//
//  Planet.swift
//  Netrek
//
//  Created by Darrell Root on 3/3/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

/// Planet resource flags in SP_PLANET.
public enum PlanetFlags: UInt16 {
    case repair = 0x010
    case fuel = 0x020
    case agri = 0x040
}

/// One of the 40 planets. Updated from SP_PLANET_LOC and SP_PLANET.
public class Planet: CustomStringConvertible, ObservableObject, Identifiable {

    /// The universe this planet belongs to (set by `Universe`).
    public internal(set) weak var universe: Universe?
    
    public private(set) var planetId: Int
    public var id: Int {
        return self.planetId
    }
    @Published public private(set) var name: String {
        didSet {
            if name.count >= 3 {
                let index3 = name.index(name.startIndex, offsetBy: 3)
                self.shortName = String(name[..<index3])
            }
        }
    }
    @Published public private(set) var shortName: String
    @Published public private(set) var positionX: Int
    @Published public private(set) var positionY: Int
    @Published public private(set) var owner: Team = .independent
    //private(set) var info: Int = 0  //shows which teams have seen the planet
    public private(set) var seen: [Team:Bool] = [:]
    //calculated from info
    
    public private(set) var flags: UInt16 = 0
    @Published public private(set) var agri: Bool = false
    @Published public private(set) var fuel: Bool = false
    @Published public private(set) var repair: Bool = false
    @Published public var armies: Int = 0
    
    /// Whether `team` has scanned this planet (from the SP_PLANET info bits).
    public func isSeen(by team: Team) -> Bool {
        return seen[team] ?? false
    }

    public var description: String {
        get {
            return "planet planetID: \(planetId) name: \(name) position: \(positionX) \(positionY)"
        }
    }
    public init(planetId: Int) {
        self.planetId = planetId
        self.name = "Unknown"
        self.shortName = "Unk"
        self.positionX = 0
        self.positionY = 0
        
        for team in Team.allCases {
            seen[team] = false
        }
    }
    deinit {
        debugPrint("planet ID \(planetId) deinit")
    }

    public func reset() {
        self.name = "unknown"
        self.positionX = 0
        self.positionY = 0
    }
    public func showInfo(team: Team) {
        let infoString: String
        if seen[team] == false {
            infoString = "No scanner information on \(name)"
        } else {
            switch (self.agri, self.fuel, self.repair) {
                
            case (false, false, false):
                infoString = "\(armies) armies"
            case (false, false, true):
                infoString = "REPAIR \(armies) armies"
            case (false, true, false):
                infoString = "FUEL \(armies) armies"
            case (false, true, true):
                infoString = "FUEL REPAIR \(armies) armies"
            case (true, false, false):
                infoString = "AGRI \(armies) armies"
            case (true, false, true):
                infoString = "AGRI REPAIR \(armies) armies"
            case (true, true, false):
                infoString = "AGRI FUEL \(armies) armies"
            case (true, true, true):
                infoString = "AGRI FUEL REPAIR\(armies) armies"
            }
        }
        debugPrint("\(self.name) \(infoString)")
        (universe ?? Universe.universe).gotMessage("\(self.name) \(infoString)")
    }

    public func update(name: String, positionX: Int, positionY: Int) {
        DispatchQueue.main.async {
            self.name = name
            self.positionX = positionX
            self.positionY = positionY
        }
        
        //self.remakeNode()
    }
    public func update(owner: Int, info: Int, flags: UInt16, armies: Int) {
        DispatchQueue.main.async {
            self.agri = flags & PlanetFlags.agri.rawValue != 0
            self.fuel = flags & PlanetFlags.fuel.rawValue != 0
            self.repair = flags & PlanetFlags.repair.rawValue != 0
            self.flags = flags
            //self.info = info
            for team in Team.allCases {
                if info & team.rawValue != 0 {
                    self.seen[team] = true
                } else {
                    self.seen[team] = false
                }
            }
            self.armies = armies
            for team in Team.allCases {
                if owner == team.rawValue {
                    self.owner = team
                    //self.remakeNode()
                    return
                }
            }
        }
        //self.remakeNode()
    }
}
