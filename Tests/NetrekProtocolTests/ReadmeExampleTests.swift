//
//  ReadmeExampleTests.swift
//  NetrekProtocolTests
//
//  The example client from README.md, kept here so it always compiles.
//  If you change one, change the other.
//

import XCTest
import NetrekProtocol

// --- README example starts ---
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
// --- README example ends ---

final class ReadmeExampleTests: XCTestCase {
    func testExampleClient_FollowsTheLoginSteps() {
        let client = MinimalClient()
        XCTAssertEqual(client.gameState, .serverSelected)
        client.newGameState(.serverSlotFound)
        client.newGameState(.loginAccepted)
        XCTAssertEqual(client.gameState, .loginAccepted)
        client.report()
    }
}
