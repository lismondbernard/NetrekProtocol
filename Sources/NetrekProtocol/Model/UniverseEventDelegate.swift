//
//  UniverseEventDelegate.swift
//  NetrekProtocol
//
//  Moments in the game a client may want to react to, for example with a
//  sound or a change of screen. Set `Universe.eventDelegate` to receive them.
//  Every method has an empty default, so implement only what you need.
//

import Foundation

public protocol UniverseEventDelegate: AnyObject {
    /// My slot reached the outfit state (SP_PSTATUS POUTFIT): the server is
    /// ready for a team and ship choice. Called on the main queue.
    func universeServerReadyForOutfit(_ universe: Universe)

    /// My ship exploded or died after being alive. Called on the main queue.
    func universeMyShipDestroyed(_ universe: Universe)

    /// Another ship blew up while I was alive or exploding. `distance` is the
    /// taxicab distance from my last live position, in game units.
    func universe(_ universe: Universe, playerExploded player: Player, distance: Int)

    /// A newly fired torpedo was seen within a quarter of
    /// `NetrekMath.displayDistance` of me. Reported once per launch.
    func universe(_ universe: Universe, torpedoNearby torpedo: Torpedo, distance: Int)

    /// A newly fired plasma was seen within a third of
    /// `NetrekMath.displayDistance` of me. Reported once per launch.
    func universe(_ universe: Universe, plasmaNearby plasma: Plasma, distance: Int)

    /// A laser (phaser) was fired within half of `NetrekMath.displayDistance`
    /// of me.
    func universe(_ universe: Universe, laserFired laser: Laser, distance: Int)
}

public extension UniverseEventDelegate {
    func universeServerReadyForOutfit(_ universe: Universe) {}
    func universeMyShipDestroyed(_ universe: Universe) {}
    func universe(_ universe: Universe, playerExploded player: Player, distance: Int) {}
    func universe(_ universe: Universe, torpedoNearby torpedo: Torpedo, distance: Int) {}
    func universe(_ universe: Universe, plasmaNearby plasma: Plasma, distance: Int) {}
    func universe(_ universe: Universe, laserFired laser: Laser, distance: Int) {}
}
