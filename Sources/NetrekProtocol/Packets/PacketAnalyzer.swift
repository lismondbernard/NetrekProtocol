//
//  PacketAnalyzer.swift
//  Netrek
//
//  Created by Darrell Root on 3/2/19.
//  Copyright © 2019 Network Mom LLC. All rights reserved.
//

import Foundation

/// What `PacketAnalyzer` reports back to the client: login and outfit
/// results, team eligibility, server features, and when to read more bytes.
public protocol PacketAnalyzerDelegate: AnyObject {
    var gameState: GameState { get }
    var serverFeatures: [String] { get set }

    func newGameState(_ state: GameState)
    func triggerReceive()
    func updateTeamEligibility(mask: UInt8)
    func outfitRefused()
    /// The analyzer lost its place in the stream and has stopped: it will
    /// not call `triggerReceive()` again, and ignores bytes it is given
    /// from now on. End the session; the connection is no use any more.
    /// Only sent under `UnreadablePolicy.stopReading`.
    func packetStreamUnreadable(_ packet: UnreadablePacket)
}

extension PacketAnalyzerDelegate {
    /// Leaves the server, so a delegate that doesn't implement this never
    /// freezes in silence: `newGameState(.noServerSelected)` is how the
    /// analyzer already ends a session. Implement it to say why as well.
    public func packetStreamUnreadable(_ packet: UnreadablePacket) {
        newGameState(.noServerSelected)
    }
}

/// What `PacketAnalyzer` does with a packet type it cannot size.
public enum UnreadablePolicy: Equatable, Sendable {
    /// Stop reading for good and tell the delegate
    /// (`packetStreamUnreadable`). Right for a TCP stream, where every
    /// packet's start comes from the length of the one before, so the
    /// place is lost.
    case stopReading
    /// Drop the rest of this batch, log it, and read the next batch as
    /// normal. Only for a source that hands over whole packets in each
    /// batch, such as a server in the same process, so the next batch
    /// starts on a packet.
    case dropBatch
}

/// The last text the server sent about the session itself: an SP_WARNING,
/// or why an SP_BADVERSION refused the client. A client can show it after
/// the connection ends, when the message board is cleared.
public struct ServerNotice: Equatable, Sendable {
    public let text: String
    public let receivedAt: Date

    public init(text: String, receivedAt: Date) {
        self.text = text
        self.receivedAt = receivedAt
    }
}

/// Parses the server-to-client (SP_*) packet stream into a `Universe`.
/// Feed it every chunk a `TcpReader` receives; it keeps partial packets
/// between calls.
public class PacketAnalyzer {
    public weak var delegate: PacketAnalyzerDelegate?

    public let universe: Universe
    var leftOverData: Data?

    /// Bytes of the stream read so far, in whole packets.
    public private(set) var bytesRead = 0
    /// The type of the last whole packet read.
    private var lastPacketType: UInt8?
    /// Set once the stream could not be read. From then on `analyze`
    /// ignores its input and no longer asks for more.
    public private(set) var unreadable: UnreadablePacket?
    /// What to do with a packet type that cannot be sized.
    public var unreadablePolicy: UnreadablePolicy = .stopReading
    /// Batches dropped under `UnreadablePolicy.dropBatch`.
    public private(set) var droppedBatches = 0
    /// The last SP_WARNING or SP_BADVERSION, kept until the next one.
    public private(set) var lastServerNotice: ServerNotice?

    let msg_len = MSG_LEN
    let name_len = 16
    let keymap_len = KEYMAP_LEN
    let playerMax = 100 // we ignore player updates for more than this

    /// Applied to every message and planet name the server sends. The
    /// default, `NetrekMath.sanitizeString`, uses the names Parallax shows
    /// (Rome, Kazari, Prague, laser); pass `{ $0 }` to keep the classic ones.
    public var textFilter: (String) -> String

    /// What to do with an RCD distress call (an SP_MESSAGE with flags
    /// MTEAM | MDISTR | MVALID and a valid binary body). Every SP_MESSAGE,
    /// distress or not, also goes to `Universe.eventDelegate` through
    /// `universe(_:receivedMessage:)`, and a distress call through
    /// `universe(_:receivedDistress:message:)`.
    ///
    /// `false` (the default) keeps the message list as before: the call's
    /// bytes go through the same ASCII decoding as chat, which gives
    /// unreadable text where the platform accepts bytes over 0x7f, and
    /// nothing at all where it does not (Linux).
    /// `true` puts the call's default text in `Universe.gotMessage`
    /// instead, the line a classic client shows, through `textFilter`.
    public var expandsDistressCalls = false

    /// The value the server sent with each feature name in SP_FEATURE,
    /// -1 meaning the server does not know the feature. `delegate.serverFeatures`
    /// keeps the names only.
    public private(set) var serverFeatureValues: [String: Int] = [:]

    /// Whether the server answered RC_DISTRESS with a positive value, so it
    /// relays binary RCD calls. COW sends a call in binary only then
    /// (COW feature.c:82, senddist.c:104); otherwise it sends the call's
    /// text as an ordinary team message (`Distress.plainText`). Send
    /// `MakePacket.cpFeatures(feature: "RC_DISTRESS")` to ask.
    public var serverOffersRCDistress: Bool {
        return (serverFeatureValues["RC_DISTRESS"] ?? 0) > 0
    }

    public init(delegate: PacketAnalyzerDelegate, universe: Universe = .universe,
                textFilter: @escaping (String) -> String = NetrekMath.sanitizeString) {
        self.delegate = delegate
        self.universe = universe
        self.textFilter = textFilter
    }

    public func analyze(incomingData: Data) {
        guard unreadable == nil else {
            debugPrint("PacketAnalyzer.analyze: ignoring \(incomingData.count) bytes after an unreadable packet")
            return
        }
        //debugPrint("incoming data size \(incomingData.count) leftOverData.size \(String(describing: leftOverData?.count))")
        var data = Data()
        //debugPrint("one data.startIndex \(data.startIndex) data.endIndex \(data.endIndex)")
        
        if leftOverData != nil {
            //debugPrint("leftoverdata.startIndex \(leftOverData!.startIndex) leftoverdata.endIndex \(leftOverData!.endIndex)")
            //data.append(leftOverData!)
            var leftOverDataStruct: [UInt8] = []
            for byte in leftOverData! {
                leftOverDataStruct.append(byte)
            }
            //let leftOverDataStruct: [UInt8] = leftOverData!
            data = leftOverDataStruct + incomingData
            //debugPrint("two")
            //debugPrint("data startIndex \(data.startIndex) endIndex \(data.endIndex)\n")
            //debugPrint("incomingData startIndex \(incomingData.startIndex) endIndex \(incomingData.endIndex)\n")

            //data.append(incomingData)
            //debugPrint("three")
            self.leftOverData = nil
        } else {
            //debugPrint("four")
            data = incomingData
        }
        //debugPrint("done copying data")
        repeat {
            guard let packetType: UInt8 = data.first else {
                debugPrint("PacketAnalyzer.analyze is done, should not have gotten here")
                delegate?.triggerReceive()
                return
            }
            if let reason = UnreadablePacket.reason(forType: packetType) {
                let packet = UnreadablePacket(packetType: packetType, reason: reason,
                                              streamOffset: bytesRead,
                                              previousPacketType: lastPacketType,
                                              leadingBytes: [UInt8](data.prefix(UnreadablePacket.leadingByteLimit)))
                if unreadablePolicy == .dropBatch {
                    // The next batch starts on a packet, so read on.
                    debugPrint("PacketAnalyzer.analyze: dropping \(data.count) bytes of this batch: \(packet)")
                    droppedBatches += 1
                    leftOverData = nil
                    universe.serverUpdate.increment()
                    delegate?.triggerReceive()
                    return
                }
                // Without this packet's length there is no way to find the
                // next one, so reading ends here, and says so.
                debugPrint("PacketAnalyzer.analyze: \(packet)")
                unreadable = packet
                universe.serverUpdate.increment()
                delegate?.packetStreamUnreadable(packet)
                return
            }
            let packetLength = PACKET_SIZES[Int(packetType)]
            guard data.count >= packetLength else {
                debugPrint("PacketAnalyzer.analyze: fractional packet expected length \(packetLength) remaining size \(data.count) saving for next round")
                self.leftOverData = Data()
                for byte in data {
                    self.leftOverData?.append(byte)
                }
                delegate?.triggerReceive()
                return
            }
            let range = (data.startIndex..<data.startIndex + packetLength)
            //debugPrint("packetAnalyzer.analyze startIndex \(data.startIndex) packetLength \(packetLength) endindex \(data.endIndex) packetType \(packetType)")
            let thisPacket = data.subdata(in: range)
            self.analyzeOnePacket(data: thisPacket)
            data.removeFirst(packetLength)
            bytesRead += packetLength
            lastPacketType = packetType
        } while !data.isEmpty
        // now that we've analyzed our data, we can try
        // to receive more
        /*DispatchQueue.main.async() {
            self.appDelegate.tacticalViewController?.scene.packetUpdate()
        }*/
        universe.serverUpdate.increment()

        delegate?.triggerReceive()
    }

    func printData(_ data: Data, success: Bool) {
        let printPacketDumps = true
            if printPacketDumps {
            var dumpString = "\(success) "
            for byte in data {
                let addString = String(format:"%x ",byte)
                dumpString += addString
            }
            debugPrint(dumpString)
        }
    }
    /// What a classic client says for an SP_BADVERSION (socket.c
    /// handleBadVersion): 0 is the wrong client version, anything else a
    /// refusal for now.
    static func badVersionText(why: UInt8) -> String {
        why == 0
            ? "The server does not accept this client version."
            : "The server is not taking players now. Try again later."
    }

    /// A fixed-size C string field: the bytes up to the first NUL, as UTF-8,
    /// or Latin-1 when they aren't valid UTF-8 (older clients and servers).
    static func cString(_ field: Data) -> String {
        let bytes = field.prefix { $0 != 0 }
        return String(data: bytes, encoding: .utf8) ?? String(data: bytes, encoding: .isoLatin1) ?? ""
    }

    public func analyzeOnePacket(data: Data) {
        //debugPrint("in analyze one packet")
        guard !data.isEmpty else {
            debugPrint("PacketAnalyer.analyzeOnePacket data length 0")
            return
        }
        let packetType: UInt8 = data[0]
        //debugPrint("in analyze one packet packetType \(packetType)")
        guard let packetLength = PACKET_SIZES[safe: Int(packetType)] else {
            debugPrint("Warning: PacketAnalyzer.analyzeOnePacket received invalid packet type \(packetType)")
            printData(data, success: false)
            return
        }
        guard packetLength > 0 else {
            debugPrint("PacketAnalyzer.analyzeOnePacket invalid packet length \(packetLength) type \(packetType)")
            printData(data, success: false)
            return
        }
        guard packetLength == data.count else {
            debugPrint("PacketAnalyzer.analyeOnePacket unexpected data length \(data.count) expected \(packetLength) type \(packetType)")
            printData(data, success: false)
            return
        }
        switch packetType {
            
        case 1:
            let flags = Int(data[1])
            let m_recpt = Int(data[2])
            let m_from = Int(data[3])
            let range = (4..<(4 + msg_len))
            let messageData = data.subdata(in: range)
            let received = ReceivedMessage(flags: UInt8(flags), recipient: m_recpt, sender: m_from,
                                           body: [UInt8](messageData))
            let distress = received.distress
            if expandsDistressCalls && distress != nil {
                // Shown as its default text instead of its bytes.
                universe.received(received, distress: distress, distressFilter: textFilter)
                break
            }
            var messageString = "message_decode_error"
//            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
            if let messageStringWithNulls = String(data: messageData, encoding: .ascii) {
                messageString = ""
                var done = false
                for char in messageStringWithNulls {
                    if !done && char != "\0" {
                        messageString.append(char)
                    } else {
                        done = true
                    }
                }
 
                messageString = textFilter(messageString)
                universe.gotMessage(messageString)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 1")
                printData(data, success: false)
            }
            messageString = textFilter(messageString)
            //debugPrint("Received SP_MESSAGE 1 from \(m_from) message \(messageString)")
            universe.received(received, distress: distress, distressFilter: nil)

        case 2:
            //SP_PLAYER_INFO
            let playerID = Int(data[1])
            let shipType = Int(data[2])
            let team = Int(data[3])
            DispatchQueue.main.async {
                self.universe.updatePlayer(playerId: playerID, shipType: shipType, team: team)
            }
       
        case 3:
            // SP_KILLS
            let playerID = Int(data[1])
            let killsInt = data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped
            let kills: Double = Double(killsInt) / 100.0
            universe.updatePlayer(playerId: playerID, kills: kills)
            //debugPrint("Received SP_KILLS 3 playerID \(playerID) killsInt \(killsInt) kills \(kills)")

        case 4:
            // SP_PLAYER py-struct
            let playerID = Int(data[1])
            let directionNetrek = UInt8(data[2])
            let speed = Int(data[3])
            let positionX = NetrekMath.netrekX2GameX(Int(data.subdata(in: (4..<8)).to(type: Int32.self).byteSwapped))
            let positionY = NetrekMath.netrekY2GameY(Int(data.subdata(in: (8..<12)).to(type: Int32.self).byteSwapped))
            universe.updatePlayer(playerId: playerID, directionNetrek: directionNetrek, speed: speed, positionX: positionX, positionY: positionY)

        case 5:
            // SP_TORP_INFO
            let war = UInt8(data[1])  //mask of teams torp is hostile to
            let status = UInt8(data[2]) // new status of torp, TFREE, TDET, etc
            let pad1 = UInt8(data[3])
            let torpedoNumber = Int(data.subdata(in: (4..<6)).to(type: UInt16.self).byteSwapped)
            universe.updateTorpedo(torpedoNumber: torpedoNumber, war: war, status: status)
            //debugPrint("Received SP_TORP_INFO 5 torpedoNumber \(torpedoNumber) war \(war) status \(status)")
        
        case 6:
            // SP_TORP
            let directionNetrek = Int(UInt8(data[1]))
            let torpedoNumber = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            let positionX = NetrekMath.netrekX2GameX(Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped))
            let positionY = NetrekMath.netrekY2GameY((Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)))
            universe.updateTorpedo(torpedoNumber: torpedoNumber, directionNetrek: directionNetrek, positionX: positionX, positionY: positionY)
            
        case 7:
            // SP_LASER 7
            let laserId = Int(data[1])
            let status = Int(data[2]) // LA_HIT etc...
            let directionNetrek = UInt8(data[3])
            let positionX = NetrekMath.netrekX2GameX(Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped))
            let positionY = NetrekMath.netrekY2GameY(Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped))
            let target = Int(data.subdata(in: (12..<16)).to(type: Int32.self).byteSwapped)
            universe.updateLaser(laserId: laserId, status: status, directionNetrek: directionNetrek, positionX: positionX, positionY: positionY, target: target)
        case 8:
            //SP_PLASMA_INFO
            let war = UInt8(data[1])
            let status = Int(data[2])
            let plasmaId = Int(data.subdata(in: (4..<6)).to(type: UInt16.self).byteSwapped)
            universe.updatePlasma(plasmaId: plasmaId, war: war, status: status)
            //debugPrint("Received SP_PLASMA 8 plasmaID \(plasmaId) war \(war) status \(status)")

        case 9:
            //SP_PLASMA
            let plasmaId = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            let positionX = NetrekMath.netrekX2GameX(Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped))
            let positionY = NetrekMath.netrekY2GameY(Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped))
            universe.updatePlasma(plasmaId: plasmaId, positionX: positionX, positionY: positionY)
        
        case 10:
            // SP_WARNING
            let range = (4..<84)
            let messageData = data.subdata(in: range)
            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
                var messageString = messageStringWithNulls.filter { $0 != "\0" }
                
                //debugPrint("Received SP_WARNING 10 MESSAGE \(messageString) sent to messages")

                lastServerNotice = ServerNotice(text: textFilter(messageString), receivedAt: Date())
                messageString.append("\n")
                messageString = textFilter(messageString)
                universe.gotMessage(messageString)
                //debugPrint(messageString)
                //printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 10")
                printData(data, success: false)
            }

        case 11:
            // SP_MOTD message
            let range = (4..<84)
            let messageData = data.subdata(in: range)
            if let messageStringWithNulls = String(data: messageData, encoding: .utf8) {
                var messageString = messageStringWithNulls.filter { $0 != "\0" }
                lastServerNotice = ServerNotice(text: textFilter(messageString), receivedAt: Date())
                messageString.append("\n")
                messageString = textFilter(messageString)
                universe.gotMessage(messageString)
                //printData(data, success: true)
            } else {
                debugPrint("PacketAnalyzer unable to decode message type 11")
                printData(data, success: false)
            }
        case 12:
            // My information
            // SP_YOU length 32
            let myPlayerID = Int(data[1])
            let hostile = UInt32(data[2])
            let war = UInt32(data[3])
            let armies = Int(data[4])
            let tractor = Int(data[5])
            let flags = data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped
            let damage = Int(data.subdata(in: (12..<16)).to(type: UInt32.self).byteSwapped)
            let shieldStrength = Int(data.subdata(in: (16..<20)).to(type: UInt32.self).byteSwapped)
            let fuel = Int(data.subdata(in: (20..<24)).to(type: UInt32.self).byteSwapped)
            let engineTemp = Int(data.subdata(in: (24..<26)).to(type: UInt16.self).byteSwapped)
            let weaponsTemp = Int(data.subdata(in: (26..<28)).to(type: UInt16.self).byteSwapped)
            let whyDead = Int(data.subdata(in: (28..<30)).to(type: UInt16.self).byteSwapped)
            let whoDead = Int(data.subdata(in: (30..<32)).to(type: UInt16.self).byteSwapped)
            //if tractor is between 64 and 95, tractor target is tractor - 40

            //printFlags(flags: flags)
            universe.updateMe(myPlayerId: myPlayerID, hostile: hostile, war: war, armies: armies, tractor: tractor, flags: flags, damage: damage, shieldStrength: shieldStrength, fuel: fuel, engineTemp: engineTemp, weaponsTemp: weaponsTemp, whyDead: whyDead, whoDead: whoDead)
            if let state = delegate?.gameState, state == .serverSelected || state == .serverConnected {
                delegate?.newGameState(.serverSlotFound)
            }
            //debugPrint(me.description)
            //printData(data, success: true)

        case 13:
            // SP_QUEUE
            let queue = data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped
            debugPrint("Connected to server. Wait queue position \(queue)")
            DispatchQueue.main.async {
                self.universe.waitQueue = Int(queue)
            }
            //printData(data, success: true)
            
        case 14:
            let tourn = Int(data[1])
            //pad1
            //pad2
            let armsBomb = (data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let planets = (data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            let kills = (data.subdata(in: (12..<16)).to(type: UInt32.self).byteSwapped)
            let losses = (data.subdata(in: (16..<20)).to(type: UInt32.self).byteSwapped)
            let time = (data.subdata(in: (20..<24)).to(type: UInt32.self).byteSwapped)
            let timeProd = (data.subdata(in: (24..<28)).to(type: Int32.self).byteSwapped)
            //debugPrint("Received SP_STATUS 14 tourn \(tourn) armsBomb \(armsBomb) planets \(planets) kills \(kills) losses \(losses) time \(time) timeProd \(timeProd)")
            // These stats are server-wide and useless
            //let messageString = "Your stats: bombed \(armsBomb) armies, captured \(planets) planets, killed \(kills) enemies, died \(losses) times in \(time/3600) hours"
            //universe.gotMessage(messageString)
        case 15:
            //SP_PLANET
            let planetID = Int(data[1])
            let owner = Int(data[2])
            let info = Int(data[3])
            let flags = data.subdata(in: (4..<6)).to(type: UInt16.self).byteSwapped
            // pad
            // pad
            let armies = Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            //debugPrint("Received SP_PLANET 15 planetID \(planetID) owner \(owner) info \(info) flags \(flags) armies \(armies)")
            guard let planet = universe.planets[safe: planetID] else {
                debugPrint("ERROR: invalid planetID \(planetID)")
                return
            }
            planet.update(owner: owner, info: info, flags: flags, armies: armies)
            
        case 16:
            // SP_PICKOK
            let state = Int(data[1]) // 0 = no, 1 = yes
            //pad2
            //pad3
            //debugPrint("Received SP_PICKOK 16 state: \(state)")
            if state == 1 {
                delegate?.newGameState(.gameActive)
            }
            if state == 0 {
                delegate?.outfitRefused()
            }

        case 17:
            // SP_LOGIN
            let accept = Int(data[1])
            let paradise1 = Int(data[2])
            let paradise2 = Int(data[3])
            let flags = data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped
            let keymap = data.subdata(in: (8..<96))
            
            if paradise1 == 69 && paradise2 == 42 {
                debugPrint("paradise server not supported")
                delegate?.newGameState(.noServerSelected)
            }
            if accept == 0 {   // login failed
                debugPrint("login failed")
                delegate?.newGameState(.noServerSelected)
            } else {
                delegate?.newGameState(.loginAccepted)
            }
            //printData(data, success: true)

        case 18:
            //SP_FLAGS 18
            let playerId = Int(data[1])
            let tractor = Int(data[2])
            let flags = data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped

            guard let player = universe.players[safe: playerId] else {
                debugPrint("PacketAnalyzer type 18 invalid player id \(playerId)")
                printData(data, success: false)

                return
            }
            DispatchQueue.main.async {
                player.update(tractor: tractor, flags: flags)
            }
            //debugPrint(player)
            //printData(data, success: true)

        case 19:
            //TODO process mask  Tournament mode mask
            //SP_MASK
            let mask = UInt8(data[1])
            DispatchQueue.main.async {
                self.delegate?.updateTeamEligibility(mask: mask)
            }
            // pad2
            // pad3
            //debugPrint("Received SP_MASK 19 mask \(mask)")
        case 20:
            // SP_PSTATUS
            let playerID = Int(data[1])
            let status = Int(data[2])
            guard let player = universe.players[safe: playerID] else {
                debugPrint("PacketAnalyzer type 20 invalid player id \(playerID)")
                printData(data, success: false)
                return
            }
            //debugPrint("Received SP_PSTATUS 20 playerID \(playerID) status \(status)")
            player.update(sp_pstatus: status)
            //player.status = Int(status)
            //debugPrint(player)
            //printData(data, success: true)
        case 21: //SP_BADVERSION
            // struct badversion_spacket { char type; char why; char pad2, pad3; }
            let why = UInt8(data[1])
            debugPrint("Received SP_BADVERSION 21 reason: \(why)")
            lastServerNotice = ServerNotice(text: Self.badVersionText(why: why), receivedAt: Date())

        case 22:
            let playerID = Int(data[1])
            let war = UInt32(data[2])
            let hostile = UInt32(data[3])
            universe.updatePlayer(playerId: playerID, war: war, hostile: hostile)
            
        case 23:
            // SP_STATS 23
            let playerID = Int(data[1])
            // pad1
            // pad2
            let tournamentKills = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            let tournamentLosses = Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            let overallKills = Int(data.subdata(in: (12..<16)).to(type: UInt32.self).byteSwapped)
            let overallLosses = Int(data.subdata(in: (16..<20)).to(type: UInt32.self).byteSwapped)
            let tournamentTicks = Int(data.subdata(in: (20..<24)).to(type: UInt32.self).byteSwapped)
            let tournamentPlanets = Int(data.subdata(in: (24..<28)).to(type: UInt32.self).byteSwapped)
            let tournamentArmies = Int(data.subdata(in: (28..<32)).to(type: UInt32.self).byteSwapped)
            let starbaseKills = Int(data.subdata(in: (32..<36)).to(type: UInt32.self).byteSwapped)
            let starbaseLosses = Int(data.subdata(in: (36..<40)).to(type: UInt32.self).byteSwapped)
            let practiceArmies = Int(data.subdata(in: (40..<44)).to(type: UInt32.self).byteSwapped)
            let practicePlanets = Int(data.subdata(in: (44..<48)).to(type: UInt32.self).byteSwapped)
            let maxKills100 = Int(data.subdata(in: (48..<52)).to(type: UInt32.self).byteSwapped)
            let starbaseMaxKills100 = Int(data.subdata(in: (52..<56)).to(type: UInt32.self).byteSwapped)
            let maxKills = Double(maxKills100) / 100.0
            let sbMaxKills = Double(starbaseMaxKills100) / 100.0
            universe.updatePlayer(playerID: playerID, tournamentKills: tournamentKills, tournamentLosses: tournamentLosses,
                overallKills: overallKills,
                overallLosses: overallLosses,
                tournamentTicks: tournamentTicks,
                tournamentPlanets: tournamentPlanets,
                tournamentArmies: tournamentArmies,
                starbaseKills: starbaseKills,
                starbaseLosses: starbaseLosses,
                practiceArmies: practiceArmies,
                practicePlanets: practicePlanets,
                maxKills: maxKills,
                sbMaxKills: sbMaxKills)
            //debugPrint("Received SP_STATS 23")
            //TODO need to process this data
        case 24:
            //plyr_long_spacket SP_PL_LOGIN
            // new player logged in
            let playerID = Int(data[1])
            let rank = Int(data[2])
            // name, monitor (the player's host) and login are 16-byte C
            // strings: each ends at its first NUL, and anything after it is
            // left over from an older value.
            let name = Self.cString(data.subdata(in: (4..<20)))
            let monitor = Self.cString(data.subdata(in: (20..<36)))
            let login = Self.cString(data.subdata(in: (36..<52)))
            universe.updatePlayer(playerId: playerID, rank: rank, name: name, login: login, monitor: monitor)
        /*case 25:
            // is reserved, but I got one on pickled.netrek.org
            break*/
        case 26:
            // SP_PLANET_LOC
            let planetID = Int(data[1])
            let positionX = NetrekMath.netrekX2GameX(Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped))
            let positionY = NetrekMath.netrekY2GameY(Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped))
            let nameData = data.subdata(in: (12..<28))
            var name = "unknown"
            if let nameStringWithNulls = String(data: nameData, encoding: .utf8) {
                name = nameStringWithNulls.filter { $0 != "\0" }
            }
            name = textFilter(name)
            universe.createPlanet(planetId: planetID, positionX: positionX, positionY: positionY, name: name)
            /*if let planet = universe.planets[planetID] {
                //debugPrint(planet)
            }*/
            //debugPrint("Received SP_PLANET_LOC 26 name \(name) planetID \(planetID) positionX \(positionX) positionY \(positionY)")
            //printData(data, success: true)

        
        case 32:
            let version = Int(data[1])
            guard version == 98 else {
                //debugPrint("Received SPGeneric 32 version \(version) discarding)")
                return
            }
            let repairTime = (data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            let pl_orbit = Int8(data[3])
            let gameup = (data.subdata(in: (4..<6)).to(type: UInt16.self).byteSwapped)
            let tournamentTeams = UInt8(data[6])
            let tournamentAge = UInt8(data[7])
            let tournamentUnits = UInt8(data[8])
            let tournamentRemain = UInt8(data[9])
            let tournamentRemainUnits = UInt8(data[10])
            let starbaseRemain = UInt8(data[11]) //starbase reconstruction in minutes
            let teamRemain = UInt8(data[12]) // team surrender time
            // 18 bytes padding
            //debugPrint("Received SP_GENERIC 32 version \(version) repairTime \(repairTime) orbit \(pl_orbit)")
            // 26 bytes of unused padding
        case 39:
            // SP_SHIP_CAP
            let operation = UInt8(data[1])  // /* 0 = add/change a ship, 1 = remove a ship */
            let shipType = Int(data.subdata(in: (2..<4)).to(type: UInt16.self).byteSwapped)
            let torpSpeed = Int(data.subdata(in: (4..<6)).to(type: UInt16.self).byteSwapped)
            let phaserRange = Int(data.subdata(in: (6..<8)).to(type: UInt16.self).byteSwapped)
            let maxSpeed = Int(data.subdata(in: (8..<12)).to(type: UInt32.self).byteSwapped)
            let maxFuel = Int(data.subdata(in: (12..<16)).to(type: UInt32.self).byteSwapped)
            let maxShield = Int(data.subdata(in: (16..<20)).to(type: UInt32.self).byteSwapped)
            let maxDamage = Int(data.subdata(in: (20..<24)).to(type: UInt32.self).byteSwapped)
            let maxWpnTmp = Int(data.subdata(in: (24..<28)).to(type: Int32.self).byteSwapped)
            let maxEngTmp = Int(data.subdata(in: (28..<32)).to(type: Int32.self).byteSwapped)
            let width = Int(data.subdata(in: (32..<34)).to(type: UInt16.self).byteSwapped)
            let height = Int(data.subdata(in: (34..<36)).to(type: UInt16.self).byteSwapped)
            let maxArmies = Int(data.subdata(in: (36..<38)).to(type: UInt16.self).byteSwapped)
            let letter = Character(UnicodeScalar(Int(data[38])) ?? "U")
            // pad 39
            let nameData = data.subdata(in: (40..<56))
            var shipName = "unknown"
            if let nameStringWithNulls = String(data: nameData, encoding: .utf8) {
                shipName = nameStringWithNulls.filter { $0 != "\0" }
            }
            let s_desig1 = UInt8(data[56])
            let s_desig2 = UInt8(data[57])
            let bitmap = (data.subdata(in: (58..<60)).to(type: UInt16.self).byteSwapped)
            //debugPrint("Received SP_SHIP_CAP 39 shipType \(shipType) shipName \(shipName)")
            for ship in ShipType.allCases {
                if ship.rawValue == shipType {
                    universe.shipinfo(shipType: ship, torpSpeed: torpSpeed, phaserRange: phaserRange, maxSpeed: maxSpeed, maxFuel: maxFuel, maxShield: maxShield, maxDamage: maxDamage, maxWpnTmp: maxWpnTmp, maxEngTmp: maxEngTmp, width: width, height: height, maxArmies: maxArmies)

                }
            }
        case 60:
            var datacopy = data
            let feature_type = Character(UnicodeScalar(Int(data[1])) ?? "U") // expect C
            let arg1 = Int(data[2])
            let arg2 = Int(data[3])
            let value = Int(data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped)
            var features: [String] = []
            var newString: String = ""
            var newStringValid = false
            for index in 8 ..< 88 {  // feature packet size better be 88
                if data[index] != 0 {
                    if let unicodeScalar = UnicodeScalar(Int(data[index])) {
                        let char = Character(unicodeScalar)
                        newStringValid = true
                        newString.append(char)
                    }
                } else {
                    if newStringValid == true {
                        features.append(newString)
                        newString = ""
                        newStringValid = false
                    }
                }
            }
            if !features.isEmpty {
                for feature in features {
                    //debugPrint("Received SP_FEATURE 60 \(feature)")
                }
            } else {
                //debugPrint("Received SP_FEATURE 60 empty")
            }
            let signedValue = Int(Int32(bitPattern: data.subdata(in: (4..<8)).to(type: UInt32.self).byteSwapped))
            for feature in features {
                serverFeatureValues[feature] = signedValue
            }
            if let existingFeatures = delegate?.serverFeatures {
                delegate?.serverFeatures = existingFeatures + features
            }

        default:
            debugPrint("Default case: Received packet type \(packetType) length \(packetLength)\n")
            printData(data, success: true)

        }
    }
    func printFlags(flags: UInt32) {
        var flags = flags
        for bit in 0..<32 {
            let thisFlag = flags & 0x01
            debugPrint("bit \(bit) flag \(thisFlag)\n")
            flags = flags >> 1
        }
    }
}
