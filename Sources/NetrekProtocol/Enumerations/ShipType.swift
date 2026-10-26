//
//  ShipType.swift
//  Netrek2
//
//  Created by Darrell Root on 5/5/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

public enum ShipType: Int, CaseIterable, Codable {
    case scout = 0
    case destroyer = 1
    case cruiser = 2
    case battleship = 3
    case assault = 4
    case starbase = 5
    case battlecruiser = 6
    //case att = 7
    public var description: String {
        switch self {
            
        case .scout:
            return "SC"
        case .destroyer:
            return "DD"
        case .cruiser:
            return "CA"
        case .battleship:
            return "BB"
        case .assault:
            return "AS"
        case .starbase:
            return "SB"
        case .battlecruiser:
            return "BC"
        }
    }

    /// A one-word name for tight spots such as a picker (SSS-243).
    public var shortName: String {
        self == .assault ? "Assault" : name
    }

    /// The ship's full name, for sentences ("a Federation Cruiser").
    public var name: String {
        switch self {
        case .scout: return "Scout"
        case .destroyer: return "Destroyer"
        case .cruiser: return "Cruiser"
        case .battleship: return "Battleship"
        case .assault: return "Assault Ship"
        case .starbase: return "Starbase"
        case .battlecruiser: return "Battlecruiser"
        }
    }
}
