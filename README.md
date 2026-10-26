# NetrekProtocol

[![CI](https://github.com/lismondbernard/NetrekProtocol/actions/workflows/ci.yml/badge.svg)](https://github.com/lismondbernard/NetrekProtocol/actions/workflows/ci.yml)

A Swift package for writing a [Netrek](https://www.netrek.org) client. It speaks the classic Netrek protocol: it connects to a game server over TCP, logs in, sends your commands, and keeps a model of the universe up to date as the server reports it. It can also ask the metaserver for the list of public servers and find servers on your local network.

This is the protocol and networking code from [Parallax](https://silentspice.com/parallax/), a Netrek client for Mac, iPad and Apple TV, published on its own so anyone can build a client.

## What is in it

- **Connection:** `TcpReader` (a TCP connection built on Network.framework) and the `NetworkDelegate` protocols.
- **Sending:** `MakePacket` builds every client packet: login, outfit, speed, direction, torpedo, laser, plasma, shields, cloak, tractor, pressor, orbit, bomb, beam, messages and the rest.
- **Receiving:** `PacketAnalyzer` reads the server's packet stream and updates a `Universe`. Its `PacketAnalyzerDelegate` hears about login, outfit and team eligibility.
- **The universe:** `Universe` holds `Player`, `Planet`, `Torpedo`, `Laser`, `Plasma` and `ShipInfo` objects plus the message log. They are `ObservableObject`s, so SwiftUI views can watch them. `UniverseEventDelegate` tells you when your ship is destroyed, when the server is ready for a new ship, and when weapons fire near you (Parallax uses it for sound).
- **Servers:** `MetaServer` and `MetaServerEntry` list the public servers from metaserver.netrek.org, and `LocalServerBrowser` finds `_netrek._tcp` servers over Bonjour.
- **Basics:** `Team`, `ShipType`, `Rank`, `SlotStatus`, `PlayerStatus`, `AlertCondition`, `GameState`, `PacketType`, `PACKET_SIZES` and `NetrekMath` (coordinate and direction conversions).

## Platforms

macOS 12, iOS 15 and tvOS 15 or later, Swift 5.9 or later. The code avoids SwiftUI and keeps Network.framework and Combine behind `canImport` checks so the package also builds on Linux, where CI runs the tests too. On Linux there is no `TcpReader` or `LocalServerBrowser` (both use Network.framework), so bring your own TCP connection and feed what it receives to `PacketAnalyzer`.

## Adding it

```swift
dependencies: [
    .package(url: "https://github.com/lismondbernard/NetrekProtocol.git", branch: "main"),
],
targets: [
    .target(name: "MyClient", dependencies: ["NetrekProtocol"]),
]
```

## A minimal client

Connect, log in as a guest, pick a team and ship, and read the universe. Steering and fighting are more `MakePacket` calls (`cpDirection`, `cpTorp`, `cpLaser`, `cpShield`, ...).

```swift
import NetrekProtocol

final class MinimalClient: NetworkDelegateExtended, PacketAnalyzerDelegate {
    let universe = Universe()
    var gameState: GameState = .serverSelected
    var serverFeatures: [String] = []
    private var reader: TcpReader?
    private lazy var analyzer = PacketAnalyzer(delegate: self, universe: universe)

    func connect(to host: String, port: Int = 2592) {
        reader = TcpReader(hostname: host, port: port, delegate: self)
    }

    // NetworkDelegateExtended: called on the connection's own queue.
    func connectionStateChanged(connected: Bool) {
        DispatchQueue.main.async {
            guard connected else {
                self.newGameState(.noServerSelected)
                return
            }
            self.gameState = .serverConnected
            self.reader?.send(content: MakePacket.cpSocket())
        }
    }

    func gotData(data: Data, from: String, port: Int) {
        DispatchQueue.main.async { self.analyzer.analyze(incomingData: data) }
    }

    // PacketAnalyzerDelegate: called as packets arrive.
    func newGameState(_ state: GameState) {
        gameState = state
        switch state {
        case .serverSlotFound:   // the server gave us a slot: log in
            reader?.send(content: MakePacket.cpLogin(name: "guest", password: "", login: "guest"))
        case .loginAccepted:     // pick a team and ship
            reader?.send(content: MakePacket.cpOutfit(team: .federation, ship: .cruiser))
        case .gameActive:        // flying: steer and fire with MakePacket
            if let speed = MakePacket.cpSpeed(speed: 4) {
                reader?.send(content: speed)
            }
        default:
            break
        }
    }

    func triggerReceive() { reader?.receive() }
    func updateTeamEligibility(mask: UInt8) {}
    func outfitRefused() {}

    /// Read the universe on the main queue.
    func report() {
        let me = universe.players[universe.me]
        print("I am \(me.name) at \(me.positionX),\(me.positionY), fuel \(me.fuel)")
        for player in universe.alivePlayers {
            print(player.team.letter, NetrekMath.playerLetter(playerId: player.playerId), player.ship?.description ?? "??")
        }
        for planet in universe.planets where planet.owner == .federation {
            print(planet.name, planet.armies)
        }
        print("Torpedoes in flight:", universe.activeTorpedoes.count)
        print(universe.recentMessages.joined(separator: "\n"))
    }
}

let client = MinimalClient()
client.connect(to: "pickled.netrek.org")
// Keep the main run loop going (an app does this for you),
// and call client.report() from a timer to watch the game.
```

The login steps are: the TCP connection opens, you send `cpSocket`, the server answers with your slot (`.serverSlotFound`), you send `cpLogin`, the server accepts (`.loginAccepted`), you send `cpOutfit`, and the server launches your ship (`.gameActive`).

A few things to know:

- `PacketAnalyzer` updates most of the model on the main queue, so read the universe there.
- Positions are game units: the galaxy is 10,000 across with y pointing up. `NetrekMath` converts to and from the server's units and its 0-255 directions.
- By default `PacketAnalyzer` shows the names Parallax uses (Rome, Kazari, Prague, laser for phaser). Pass `textFilter: { $0 }` to keep the classic names.
- `Universe.universe` is a shared instance for apps that want one; you can also make your own and pass it to `PacketAnalyzer`.

## Tests

```
swift test
```

## Open source plan

Multiplayer in Parallax is free to play, always. We open the code in three steps.

1. **Now:** this package, NetrekProtocol, the protocol and networking code. MIT license, keeping Darrell Root's copyright, because it grew from his Netrek-SwiftUI client.
2. **When Parallax 1.0 ships:** the multiplayer client and the game engine, under MIT. The engine grew from Darrell Root's netrek-server-swift.
3. **Three years after 1.0, or sooner if Parallax has been off the App Store for 12 months:** the missions, tutorial, robots and new ship art. Code is MIT, art is CC-BY.

Part of what Parallax earns goes to the volunteers who run the public Netrek servers. We will post a yearly note of what came in and what went out.

## Credits

This code began as Darrell Root's [Netrek-SwiftUI](https://github.com/darrellroot/Netrek-SwiftUI) client, and its protocol work also fed his [netrek-server-swift](https://github.com/darrellroot/netrek-server-swift). Thank you, Darrell. Silent Spice has since reworked it for Parallax and split it out as this package.

Netrek itself is the work of many people since 1989. See [netrek.org](https://www.netrek.org).

## License

MIT. See [LICENSE](LICENSE).
