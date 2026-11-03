//
//  Universe+Distress.swift
//  NetrekProtocol
//
//  RCD distress calls and the universe: filling a call from my own ship,
//  and expanding a received call with what the universe knows about its
//  sender, planets and players. Read these on the main queue, like the rest
//  of the universe.
//

import Foundation

extension Universe {

    /// The sender of a call as this universe knows them: team, name and
    /// ship type. `nil` for a slot out of range.
    public func distressSender(slot: Int) -> DistressSender? {
        guard let player = players[safe: slot] else { return nil }
        return DistressSender(team: UInt8(player.team.rawValue), name: player.name,
                              shipType: player.ship?.rawValue)
    }

    /// Planet and player lookups for `Distress.defaultText(sender:lookup:)`,
    /// backed by this universe. Planet names are the ones the universe holds,
    /// so they have already been through `PacketAnalyzer.textFilter`.
    public var distressLookup: DistressLookup {
        return DistressLookup(
            planetName: { [weak self] planet in
                self?.planets[safe: planet]?.name
            },
            planetOwner: { [weak self] planet in
                guard let planet = self?.planets[safe: planet] else { return nil }
                return UInt8(planet.owner.rawValue)
            },
            planetArmies: { [weak self] planet, team in
                guard let planet = self?.planets[safe: planet],
                      let team = Team(rawValue: Int(team)),
                      planet.isSeen(by: team) else { return nil }
                return planet.armies
            },
            playerTeam: { [weak self] slot in
                guard let player = self?.players[safe: slot] else { return nil }
                return UInt8(player.team.rawValue)
            })
    }

    /// The line a classic client shows for `distress` with COW's default
    /// texts, such as " F1->FED Carrying 3 armies.", or `nil` if the sender
    /// is unknown or the text comes out empty.
    public func defaultText(for distress: Distress) -> String? {
        guard let sender = distressSender(slot: distress.sender) else { return nil }
        return distress.defaultText(sender: sender, lookup: distressLookup)
    }

    /// The text to send as an ordinary team message (`MakePacket.cpMessage`
    /// to my team) when the server does not offer RC_DISTRESS, as COW does:
    /// the default text without my own address. See `Distress.plainText`.
    public func plainText(for distress: Distress) -> String? {
        guard let sender = distressSender(slot: distress.sender) else { return nil }
        return distress.plainText(sender: sender, lookup: distressLookup)
    }

    /// A call of `type` filled from my ship the way COW does it (see
    /// `Distress.fromShip`), with the location fields given. Player fields
    /// left `nil` mean "none" and get my own slot, as in COW. `nil` until
    /// the server has sent the ship's limits (SP_SHIP_CAP).
    ///
    /// The fields each call type reads in its default text:
    /// - `carrying`, `generic` (help), `help1`, `help2`: only the ship state.
    /// - `take`, `bomb`, `bombing`, `controlling`, `asbomb`, `pop`,
    ///   `spaceControl`, `savePlanet`: `targetPlanet`.
    /// - `ogging`: `targetEnemy`. `escorting`, `baseOgg`: `targetFriend`.
    /// - `ogg`, `freeBeer`, `noGas`, `crippled`, `pickup`: `targetPlayer`,
    ///   and `targetPlanet` for "at", "@".
    /// - `asw`: `targetPlayer` and `nearestPlanet`.
    /// - `doing1`, `doing2`, `other1`, `other2`: `targetPlanet`.
    ///
    /// Fill the others too when you know them: classic clients can be set
    /// up to show any field.
    public func makeDistress(_ type: DistressType,
                             nearestPlanet: Int = 0, nearestEnemy: Int? = nil,
                             nearestFriend: Int? = nil, nearestPlayer: Int? = nil,
                             targetPlanet: Int = 0, targetEnemy: Int? = nil,
                             targetFriend: Int? = nil, targetPlayer: Int? = nil) -> Distress? {
        guard let player = players[safe: me], let ship = player.ship,
              let info = shipInfo[ship] else { return nil }
        // SP_YOU's flags as Player keeps them (Player.updateMe).
        var flags: UInt32 = 0
        if player.shieldsUp { flags |= PlayerStatus.shield.rawValue }
        if player.repair { flags |= PlayerStatus.repair.rawValue }
        if player.bomb { flags |= PlayerStatus.bomb.rawValue }
        if player.orbit { flags |= PlayerStatus.orbit.rawValue }
        if player.cloak { flags |= PlayerStatus.cloak.rawValue }
        if player.weaponsOverheated { flags |= PlayerStatus.weaponTemp.rawValue }
        if player.enginesOverheated { flags |= PlayerStatus.engineTemp.rawValue }
        var call = Distress.fromShip(
            type: type, sender: me,
            damage: player.damage, maxDamage: info.maxDamage,
            shield: player.shieldStrength, maxShield: info.maxShield,
            fuel: player.fuel, maxFuel: info.maxFuel,
            weaponTemp: player.weaponsTemp, maxWeaponTemp: info.maxWpnTmp,
            engineTemp: player.engineTemp, maxEngineTemp: info.maxEngTmp,
            armies: player.armies, flags: flags)
        call.nearestPlanet = nearestPlanet
        call.nearestEnemy = nearestEnemy ?? me
        call.nearestFriend = nearestFriend ?? me
        call.nearestPlayer = nearestPlayer ?? me
        call.targetPlanet = targetPlanet
        call.targetEnemy = targetEnemy ?? me
        call.targetFriend = targetFriend ?? me
        call.targetPlayer = targetPlayer ?? me
        return call
    }

    /// Hands a received SP_MESSAGE to the event delegate on the main queue.
    /// When `distressFilter` is set and the message is a distress call, its
    /// default text goes through the filter into the message list first.
    func received(_ message: ReceivedMessage, distress: Distress?,
                  distressFilter: ((String) -> String)?) {
        DispatchQueue.main.async {
            if let filter = distressFilter, let distress = distress,
               let text = self.defaultText(for: distress) {
                self.appendMessage(filter(text))
            }
            self.eventDelegate?.universe(self, receivedMessage: message)
            if let distress = distress {
                self.eventDelegate?.universe(self, receivedDistress: distress, message: message)
            }
        }
    }
}
