//
//  MessagesController.swift
//  NetrekIPad
//
//  Created by Darrell Root on 6/10/20.
//  Copyright © 2020 Darrell Root. All rights reserved.
//

import Foundation

/// Sends chat messages (CP_MESSAGE) to all, or to my team.
public class MessagesController {
    public weak var networkSender: NetworkSending?
    /// MAYDAY and escort requests are sent only while this reports `.gameActive`.
    public weak var gameStateProvider: (any GameStateSource)?

    public var universe: Universe

    public init(universe: Universe) {
        self.universe = universe
    }
    
    public func sendMayday() {
        guard gameStateProvider?.gameState == .gameActive else { return }
        let me = self.universe.players[self.universe.me]
        let (planetOptional,_) = findClosestPlanet(x: me.positionX, y: me.positionY)
        guard let planet = planetOptional else { return }

        let message = "MAYDAY near \(planet.name) shields \(me.shieldStrength) damage \(me.damage) armies \(me.armies)"
        self.sendMessage(message: message, sendToAll: false)
    }
    public func sendEscort() {
        guard gameStateProvider?.gameState == .gameActive else { return }
        let me = self.universe.players[self.universe.me]
        let (planetOptional,_) = findClosestPlanet(x: me.positionX, y: me.positionY)
        guard let planet = planetOptional else { return }

        let message = "Request Escort near \(planet.name) shields \(me.shieldStrength) damage \(me.damage) armies \(me.armies)"
        self.sendMessage(message: message, sendToAll: false)
    }

    public func sendMessage(message: String) {
        self.sendMessage(message: message, sendToAll: false)
    }
    public func sendMessage(message: String, sendToAll: Bool) {
        if message == "" {
            return
        }
        if sendToAll {
            let data = MakePacket.cpMessage(message: message, team: .independent, individual: 0)
            self.networkSender?.send(content: data)
        } else {
            let data = MakePacket.cpMessage(message: message, team: self.universe.players[self.universe.me].team, individual: 0)
            self.networkSender?.send(content: data)
        }
    }
    private func findClosestPlanet(x: Int, y: Int) -> (planet: Planet?,distance: Int) {
        var closestPlanetDistance = 10000
        var closestPlanet: Planet?
        for planet in self.universe.planets {
            let thisPlanetDistance = abs(planet.positionX - x) + abs(planet.positionY - y)
            if thisPlanetDistance < closestPlanetDistance {
                closestPlanetDistance = thisPlanetDistance
                closestPlanet = planet
            }
        }
        return (closestPlanet,closestPlanetDistance)
    }

}
