//
//  NetrekMath.swift
//  Netrek
//
//  Created by Darrell Root on 3/7/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

/// Coordinate conversions and small helpers for the Netrek protocol.
///
/// The server's galaxy is 100,000 units across with y pointing down; the
/// game coordinates used by `Universe` are 10,000 across with y pointing up
/// (`netrekX2GameX`, `netrekY2GameY`). Directions on the wire are 0-255,
/// clockwise from north (`directionNetrek2radian`).
public enum NetrekMath {

    #if os(macOS)
    /// How far, in game units, the client's tactical view reaches. The
    /// model uses it for `Universe.visibleTractors` and to decide which
    /// weapons are close enough to report through `UniverseEventDelegate`.
    public static var displayDistance = 3000
    #else
    public static var displayDistance = 1500
    #endif

    public static var visualDisplayDistance: Int { 6 * NetrekMath.displayDistance / 10 }

    public static var displayDistanceFloat: Float { Float(displayDistance) }

    /// The galaxy's width and height in game units.
    public static let galacticSize = 10000

    // size = 112 / 3000 * width
    
    public static func sanitizeString(_ input: String) -> String {
        var outputString = input.replacingOccurrences(of: "Romulus", with: "Rome")
        outputString = outputString.replacingOccurrences(of: "Klingus", with: "Kazari")
        outputString = outputString.replacingOccurrences(of: "Praxis", with: "Prague")
        outputString = outputString.replacingOccurrences(of: "phaser", with: "laser")
        outputString = outputString.replacingOccurrences(of: "Phaser", with: "Laser")
        outputString = outputString.replacingOccurrences(of: "KLI", with: "KAZ")
        return outputString
    }
    public static func directionNetrek2radian(_ directionNetrek: UInt8) -> Double {
        let answer = Double.pi * ((Double(directionNetrek) / -128.0) + 0.5)
        if answer > 0 {
            return answer
        } else {
            return answer + 2.0 * Double.pi
        }
    }
    
    public static func angleDiff(_ angle1: Double, _ angle2: Double) -> Double {
        //returns diff between two angles, including dealing with 2*pi case
        // inputs must be between 0 and 2*Pi
        switch angle1 - angle2 {
        case 0:
            return 0.0
        case 0 ..< Double.pi:
            return angle1 - angle2
        case -Double.pi ..< 0:
            return angle1 - angle2
        case Double.pi...:
            return Double.pi - (angle1 - (angle2 + Double.pi))
        case ...Double.pi:
            return Double.pi * 2 + angle2 - angle1
        default:
            // should not get here
            return 0.0
        }
    }

    public static func directionNetrek2radian(_ directionNetrek: UInt8) -> CGFloat {
        let answer = CGFloat(Double.pi * ((Double(directionNetrek) / -128.0) + 0.5))
        if answer > 0 {
            return answer
        } else {
            return answer - 2.0 * CGFloat.pi
        }
    }

    public static func netrekY2GameY(_ netrekY: Int) -> Int {
        return ( 100000 - netrekY) / 10
    }
    public static func netrekX2GameX(_ netrekX: Int) -> Int {
        return netrekX / 10
    }
    public static func calculateNetrekDirection(mePositionX: Double, mePositionY: Double, destinationX: Double, destinationY: Double) -> UInt8 {
        let deltaX = Double(destinationX - mePositionX)
        let deltaY = Double(destinationY - mePositionY)
        var angleRadians = atan2(deltaY,deltaX)
        if angleRadians < 0 { angleRadians = angleRadians + Double.pi + Double.pi }
        let netrekDirection = Int(64.0 - 128.0 * angleRadians / Double.pi)
        if netrekDirection >= 0 {
            return(UInt8(netrekDirection))
        } else {
            return(UInt8(netrekDirection + 256))
        }
    }
    public static func teamLetter(team: Team) -> String {
        switch team {
            
        case .independent:
            return "I"
        case .federation:
            return "F"
        case .roman:
            return "R"
        case .kazari:
            return "K"
        case .orion:
            return "O"
        case .ogg:
            return "I"
        }
    }
    public static func playerLetter(playerId: Int) -> String {
        let playerLetter: String
        if playerId < 16 {
            playerLetter = String(format: "%x", playerId)
        } else {
            switch playerId {
            case 16:
                playerLetter = "g"
            case 17:
                playerLetter = "h"
            case 18:
                playerLetter = "i"
            case 19:
                playerLetter = "j"
            case 20:
                playerLetter = "k"
            case 21:
                playerLetter = "l"
            case 22:
                playerLetter = "m"
            case 23:
                playerLetter = "n"
            case 24:
                playerLetter = "o"
            case 25:
                playerLetter = "p"
            case 26:
                playerLetter = "q"
            case 27:
                playerLetter = "r"
            case 28:
                playerLetter = "s"
            case 29:
                playerLetter = "t"
            case 30:
                playerLetter = "u"
            case 31:
                playerLetter = "v"
            default:
                playerLetter = "?"
            }
        }
        return playerLetter
    }
}
