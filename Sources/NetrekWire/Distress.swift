//
//  Distress.swift
//  NetrekWire
//
//  RCD (receiver-configurable distress) calls: the binary team messages
//  classic clients send for "carrying", "help", "ogging" and the rest, which
//  each receiving client turns into text with its own macros.
//
//  The format and the default texts are the COW client's, by the COW (BRM)
//  authors, "including but not limited to Kevin Powell, Nick Trown, Jeff
//  Nelson, Kurt Siegl" (COW copyright.h), with the RCD code signed "jn" and
//  "jmn" in COW's distress.c and senddist.c. Line numbers below are for
//  https://github.com/quozl/netrek-client-cow at f680bd3 and
//  https://github.com/quozl/netrek-server at 43b641f.
//

/// The RCD types, with the numbers of `enum dist_type` in COW struct.h:41-74.
/// The vanilla server has the same enum (include/struct.h:795-812) without
/// `rcm`.
public enum DistressType: UInt8, CaseIterable, Sendable {
    // "Help me do" series.
    /// ^t "taking": I am carrying armies to the target planet.
    case take = 1
    /// ^o "ogg": help ogg the target player.
    case ogg = 2
    /// ^b "bomb": bomb the target planet.
    case bomb = 3
    /// ^c "space_control": help control the area at the target planet.
    case spaceControl = 4
    /// ^1 "save_planet": emergency at the target planet.
    case savePlanet = 5
    /// ^2 "base_ogg": sync with the target friend for a base ogg.
    case baseOgg = 6
    /// ^3 "help1": help me, with my ship state.
    case help1 = 7
    /// ^4 "help2": same default text as `help1`.
    case help2 = 8

    // "Doing" series.
    /// ^e "escorting": I am escorting the target friend.
    case escorting = 9
    /// ^p "ogging": I am ogging the target enemy.
    case ogging = 10
    /// ^m "bombing": I am bombing the target planet.
    case bombing = 11
    /// ^l "controlling": I am controlling at the target planet.
    case controlling = 12
    /// ^5 "asw": anti-bombing the target player near my nearest planet.
    case asw = 13
    /// ^6 "asbomb": don't bomb the target planet, let me bomb it.
    case asbomb = 14
    /// ^7 "doing1": general information about me.
    case doing1 = 15
    /// ^8 "doing2": same default text as `doing1`.
    case doing2 = 16

    // "Other info" series.
    /// ^f "free_beer": the target player is free beer.
    case freeBeer = 17
    /// ^n "no_gas": the target player has no fuel.
    case noGas = 18
    /// ^h "crippled": the target player is crippled.
    case crippled = 19
    /// ^9 "pickup": the target player picked up armies.
    case pickup = 20
    /// ^0 "pop": armies at the target planet.
    case pop = 21
    /// F "carrying": I am carrying armies.
    case carrying = 22
    /// ^@ "other1": general information, like `doing1`.
    case other1 = 23
    /// ^# "other2": general information, like `doing1`.
    case other2 = 24

    /// E "help": the generic distress call.
    case generic = 25

    /// RCM, COW's receiver-configurable server messages (under its RCM
    /// option). COW builds these itself from short-packet server warnings
    /// (COW short.c:1534 and on) and never sends them; its sender turns
    /// any type outside `take...generic` into `generic` (senddist.c:50-51),
    /// and so does `Distress.encode()`. A distress call of this type never
    /// decodes.
    case rcm = 26

    /// The types a client may send: `take` to `generic` (COW senddist.c:50).
    public static let sendable: ClosedRange<UInt8> = DistressType.take.rawValue...DistressType.generic.rawValue

    /// The name COW gives the type in `dist_defaults` (COW data.c:436-490)
    /// and in `dist.<key>.<name>` lines of a .netrekrc.
    public var classicName: String {
        switch self {
        case .take: return "taking"
        case .ogg: return "ogg"
        case .bomb: return "bomb"
        case .spaceControl: return "space_control"
        case .savePlanet: return "save_planet"
        case .baseOgg: return "base_ogg"
        case .help1: return "help1"
        case .help2: return "help2"
        case .escorting: return "escorting"
        case .ogging: return "ogging"
        case .bombing: return "bombing"
        case .controlling: return "controlling"
        case .asw: return "asw"
        case .asbomb: return "asbomb"
        case .doing1: return "doing1"
        case .doing2: return "doing2"
        case .freeBeer: return "free_beer"
        case .noGas: return "no_gas"
        case .crippled: return "crippled"
        case .pickup: return "pickup"
        case .pop: return "pop"
        case .carrying: return "carrying"
        case .other1: return "other1"
        case .other2: return "other2"
        case .generic: return "help"
        case .rcm: return "rcm"
        }
    }
}

/// The ship status bits an RCD call carries: the low byte of the sender's
/// `p_flags` (COW senddist.c:44), without its top bit, which the wire format
/// uses as a mark. Values from COW struct.h:120-127.
public struct DistressStatus: OptionSet, Hashable, Sendable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue & 0x7f }

    /// PFSHIELD 0x01.
    public static let shields = DistressStatus(rawValue: 0x01)
    /// PFREPAIR 0x02.
    public static let repairing = DistressStatus(rawValue: 0x02)
    /// PFBOMB 0x04.
    public static let bombing = DistressStatus(rawValue: 0x04)
    /// PFORBIT 0x08.
    public static let orbiting = DistressStatus(rawValue: 0x08)
    /// PFCLOAK 0x10.
    public static let cloaked = DistressStatus(rawValue: 0x10)
    /// PFWEP 0x20: weapons overheated.
    public static let weaponsOverheated = DistressStatus(rawValue: 0x20)
    /// PFENG 0x40: engines overheated.
    public static let enginesOverheated = DistressStatus(rawValue: 0x40)
}

/// One RCD distress call: the fields of COW's `struct distress`
/// (COW struct.h:11-23) that go on the wire, in plain Swift types.
///
/// Player and planet fields are slot and planet numbers. COW fills each
/// "nearest" field from the sender's position and each "target" field from
/// the mouse position (COW senddist.c:53-75); when there is no such player,
/// COW puts the sender's own slot there (COW util.c:112-120), and so does
/// the initializer here when you pass `nil`.
///
/// To fill one from your own ship, use
/// `Distress.fromShip(type:sender:damage:maxDamage:...)`, which does what
/// COW's loaddistress() does:
///
/// ```swift
/// var call = Distress.fromShip(
///     type: .take, sender: mySlot,
///     damage: me.damage, maxDamage: info.maxDamage,
///     shield: me.shieldStrength, maxShield: info.maxShield,
///     fuel: me.fuel, maxFuel: info.maxFuel,
///     weaponTemp: me.weaponsTemp, maxWeaponTemp: info.maxWpnTmp,
///     engineTemp: me.engineTemp, maxEngineTemp: info.maxEngTmp,
///     armies: me.armies, flags: me.flags)
/// call.nearestPlanet = closestPlanetToMe
/// call.targetPlanet = lockedPlanet      // the planet to take
/// let bytes = call.encode()             // 80 bytes for CP_MESSAGE
/// ```
public struct Distress: Hashable, Sendable {

    /// Where the free text goes relative to the call's own text. Classic
    /// clients and the vanilla server never show the text at all (see
    /// `text`), so this is only carried along.
    public enum TextPosition: UInt8, Hashable, Sendable {
        /// cc list terminator 0x80, the one COW always sends
        /// (COW senddist.c:78; distress.c:149-150 reads it as "pre_app").
        case prepend = 0x80
        /// cc list terminator 0x40 (vanilla include/struct.h:845, a
        /// comment only; no client or server code sends it).
        case append = 0x40
    }

    /// The call type. `rcm` is sent as `generic`.
    public var type: DistressType
    /// The macro flag, bit 0x20 of the first byte (COW distress.c:123).
    /// COW always sends it clear (senddist.c:80) and no default text uses it.
    public var isMacro: Bool
    /// The sender's slot. Not part of the bytes: the server adds it as the
    /// SP_MESSAGE `m_from`.
    public var sender: Int

    /// Damage, percent of the ship's maximum (`dam`). 0...127 on the wire.
    public var damage: Int
    /// Shields, percent of maximum (`shld`). 0...127 on the wire.
    public var shields: Int
    /// Fuel, percent of maximum (`fuelp`). 0...127 on the wire.
    public var fuel: Int
    /// Engine temperature, percent of the overheat point (`etmp`).
    /// 0...127 on the wire.
    public var engineTemp: Int
    /// Weapon temperature, percent of the overheat point (`wtmp`).
    /// 0...127 on the wire; COW clamps it there (senddist.c:37-41).
    public var weaponTemp: Int
    /// Armies carried (`arms`). 0...31 on the wire: receivers read five bits
    /// (COW distress.c:129).
    public var armies: Int
    /// Ship status bits (`sts`).
    public var status: DistressStatus

    /// Planet nearest the sender (`close_pl`).
    public var nearestPlanet: Int
    /// Enemy nearest the sender (`close_en`).
    public var nearestEnemy: Int
    /// Friend nearest the sender (`close_fr`).
    public var nearestFriend: Int
    /// Player of any team nearest the sender (`close_j`).
    public var nearestPlayer: Int
    /// Target planet (`tclose_pl`): the planet to take, bomb, save...
    public var targetPlanet: Int
    /// Target enemy (`tclose_en`): the player to ogg.
    public var targetEnemy: Int
    /// Target friend (`tclose_fr`): the team mate to escort or sync with.
    public var targetFriend: Int
    /// Target player of any team (`tclose_j`).
    public var targetPlayer: Int

    /// Players to copy the call to (`cclist`), at most `maxCcCount`. No
    /// classic client fills it and the vanilla server ignores it.
    public var ccList: [Int]
    /// Where `text` goes; see `TextPosition`.
    public var textPosition: TextPosition
    /// Free text after the binary part (`preappend`). COW and the vanilla
    /// server carry it but never show it: their makedistress() does not use
    /// it. At most `maxTextLength` bytes fit in the message and at most
    /// `maxRelayedTextLength` survive the server.
    public var text: String

    /// Length of the "F1->FED" address the server puts before every relayed
    /// message (ADDRLEN, COW distress.c:24; vanilla ntserv/smessage.c:195).
    public static let addressLength = 10
    /// Bytes in the binary part: sixteen fields and the cc list terminator.
    public static let headerLength = 17
    /// At most this many players in `ccList` (COW struct.h:18, "up to 5
    /// people").
    public static let maxCcCount = 5
    /// Text bytes that fit after the header with no cc list:
    /// MSG_LEN - 1 - 17 (COW distress.c:199-205).
    public static let maxTextLength = MSG_LEN - 1 - headerLength
    /// Text bytes the vanilla server passes on with no cc list: it ends
    /// every client message at byte 69 (ntserv/socket.c:1485).
    public static let maxRelayedTextLength = MSG_LEN - 11 - headerLength

    /// A call with the given fields. Player fields left `nil` get the
    /// sender's slot, as COW does when there is no such player.
    public init(type: DistressType, sender: Int,
                damage: Int = 0, shields: Int = 0, fuel: Int = 0,
                engineTemp: Int = 0, weaponTemp: Int = 0,
                armies: Int = 0, status: DistressStatus = [],
                nearestPlanet: Int = 0, nearestEnemy: Int? = nil,
                nearestFriend: Int? = nil, nearestPlayer: Int? = nil,
                targetPlanet: Int = 0, targetEnemy: Int? = nil,
                targetFriend: Int? = nil, targetPlayer: Int? = nil,
                ccList: [Int] = [], textPosition: TextPosition = .prepend,
                text: String = "", isMacro: Bool = false) {
        self.type = type
        self.isMacro = isMacro
        self.sender = sender
        self.damage = damage
        self.shields = shields
        self.fuel = fuel
        self.engineTemp = engineTemp
        self.weaponTemp = weaponTemp
        self.armies = armies
        self.status = status
        self.nearestPlanet = nearestPlanet
        self.nearestEnemy = nearestEnemy ?? sender
        self.nearestFriend = nearestFriend ?? sender
        self.nearestPlayer = nearestPlayer ?? sender
        self.targetPlanet = targetPlanet
        self.targetEnemy = targetEnemy ?? sender
        self.targetFriend = targetFriend ?? sender
        self.targetPlayer = targetPlayer ?? sender
        self.ccList = ccList
        self.textPosition = textPosition
        self.text = text
    }

    /// A call filled from the sender's own ship, in game units, the way
    /// COW's loaddistress() does it (COW senddist.c:31-47): each value as a
    /// whole percentage of its maximum, weapon temperature capped at 127,
    /// and the low byte of `flags` (`p_flags`, as in SP_YOU) as the status.
    /// The location fields start as "none"; set the ones the type uses.
    public static func fromShip(type: DistressType, sender: Int,
                                damage: Int, maxDamage: Int,
                                shield: Int, maxShield: Int,
                                fuel: Int, maxFuel: Int,
                                weaponTemp: Int, maxWeaponTemp: Int,
                                engineTemp: Int, maxEngineTemp: Int,
                                armies: Int, flags: UInt32) -> Distress {
        return Distress(type: type, sender: sender,
                        damage: percent(damage, of: maxDamage),
                        shields: percent(shield, of: maxShield),
                        fuel: percent(fuel, of: maxFuel),
                        engineTemp: percent(engineTemp, of: maxEngineTemp),
                        weaponTemp: min(percent(weaponTemp, of: maxWeaponTemp), 0x7f),
                        armies: armies,
                        status: DistressStatus(rawValue: UInt8(truncatingIfNeeded: flags)))
    }

    /// `value` as a whole percentage of `maximum`, rounded down, as COW
    /// computes it: (100 * value) / maximum. 0 when `maximum` is not
    /// positive.
    public static func percent(_ value: Int, of maximum: Int) -> Int {
        guard maximum > 0 else { return 0 }
        return (100 * value) / maximum
    }

    // MARK: - Status shortcuts

    /// The sender was cloaked (PFCLOAK).
    public var isCloaked: Bool {
        get { status.contains(.cloaked) }
        set { if newValue { status.insert(.cloaked) } else { status.remove(.cloaked) } }
    }
    /// The sender's weapons were overheated (PFWEP); shown by %W.
    public var weaponsOverheated: Bool {
        get { status.contains(.weaponsOverheated) }
        set { if newValue { status.insert(.weaponsOverheated) } else { status.remove(.weaponsOverheated) } }
    }
    /// The sender's engines were overheated (PFENG); shown by %E.
    public var enginesOverheated: Bool {
        get { status.contains(.enginesOverheated) }
        set { if newValue { status.insert(.enginesOverheated) } else { status.remove(.enginesOverheated) } }
    }

    // MARK: - Encoding

    /// The CP_MESSAGE `group` for a call: MTEAM | MDISTR. The `indiv` is the
    /// sender's team bit (COW senddist.c:99-100, 108).
    public static let group: UInt8 = MessageFlag.teamDistress

    /// The 80 bytes COW puts into the CP_MESSAGE `mesg` for this call:
    /// Dist2Mesg() (COW distress.c:166-206) copied with STRNCPY
    /// (socket.c:2309). Send them with group `Distress.group` and the
    /// sender's team bit as `indiv`.
    ///
    /// Byte 0 is the type, plus 0x20 for the macro flag. Bytes 1-15 are the
    /// fields with 0x80 set: fuel, damage, shields, engine temperature,
    /// weapon temperature, armies, status, nearest planet, nearest enemy,
    /// target planet, target enemy, target player, nearest player, target
    /// friend, nearest friend. Then one byte 0xC0 | slot per cc, the 0x80
    /// (or 0x40) terminator, the text, and zeros.
    ///
    /// Values out of the wire's range are clamped into it, so that what is
    /// sent is what every receiver reads back; COW itself only clamps the
    /// weapon temperature.
    public func encode() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: MSG_LEN)
        let type = DistressType.sendable.contains(self.type.rawValue) ? self.type : .generic
        bytes[0] = (isMacro ? 0x20 : 0) + type.rawValue
        let fields = [fuel, damage, shields, engineTemp, weaponTemp,
                      Distress.clamp(armies, 0x1f), Int(status.rawValue),
                      nearestPlanet, nearestEnemy, targetPlanet, targetEnemy,
                      targetPlayer, nearestPlayer, targetFriend, nearestFriend]
        for (index, value) in fields.enumerated() {
            bytes[1 + index] = UInt8(Distress.clamp(value, 0x7f)) | 0x80
        }
        var index = 16
        for slot in ccList.prefix(Distress.maxCcCount) {
            bytes[index] = 0xC0 | UInt8(Distress.clamp(slot, 0x1f))
            index += 1
        }
        bytes[index] = textPosition.rawValue
        index += 1
        for byte in text.utf8 {
            guard byte != 0, index < MSG_LEN - 1 else { break }
            bytes[index] = byte
            index += 1
        }
        return bytes
    }

    /// The whole 84 byte CP_MESSAGE for this call to `team`, the sender's
    /// team bit (1 FED, 2 ROM, 4 KLI, 8 ORI): type 1, group
    /// `Distress.group`, `indiv` the team, a zero pad byte, then `encode()`.
    public func clientPacket(team: UInt8) -> [UInt8] {
        return [ClientPacketType.message.rawValue, Distress.group, team, 0] + encode()
    }

    private static func clamp(_ value: Int, _ maximum: Int) -> Int {
        return Swift.min(Swift.max(value, 0), maximum)
    }

    // MARK: - Decoding

    /// Reads a distress call from an SP_MESSAGE body: the 80 `mesg` bytes,
    /// which start with the server's 10 byte "F1->FED" address.
    ///
    /// When `flags` is given (the SP_MESSAGE `m_flags`), it must be
    /// MTEAM | MDISTR | MVALID, the only value COW reads as a distress call
    /// (COW dmessage.c:71). The bytes must also look like Dist2Mesg()
    /// output: a type from `take` to `generic`, the 0x80 mark on bytes 1-15,
    /// and a 0x80 or 0x40 terminator. Chat never has those marks, so it
    /// returns `nil` for chat, empty or short messages and anything else.
    ///
    /// Fields are read the way HandleGenDistr() reads them (COW
    /// distress.c:107-160; the vanilla server's copy, ntserv/distress.c:
    /// 121-171, is the same).
    public static func decode<Bytes: Collection>(_ message: Bytes, from sender: Int,
                                                 flags: UInt8? = nil) -> Distress?
    where Bytes.Element == UInt8 {
        if let flags = flags, flags != MessageFlag.relayedTeamDistress {
            return nil
        }
        let bytes = Array(message)
        guard bytes.count > addressLength else { return nil }
        return parse(bytes, at: addressLength, sender: sender)
    }

    /// Reads a distress call from a CP_MESSAGE body, the bytes a client
    /// sends, which have no address in front. For a server or a test. The
    /// group must be `Distress.group` when given.
    public static func decode<Bytes: Collection>(clientMessage message: Bytes, from sender: Int,
                                                 group: UInt8? = nil) -> Distress?
    where Bytes.Element == UInt8 {
        if let group = group, group != Distress.group {
            return nil
        }
        return parse(Array(message), at: 0, sender: sender)
    }

    private static func parse(_ bytes: [UInt8], at start: Int, sender: Int) -> Distress? {
        guard bytes.count >= start + headerLength else { return nil }
        func byte(_ offset: Int) -> UInt8 { bytes[start + offset] }

        let typeNumber = byte(0) & 0x1f
        guard DistressType.sendable.contains(typeNumber),
              let type = DistressType(rawValue: typeNumber) else { return nil }
        for offset in 1...15 where byte(offset) & 0x80 == 0 {
            return nil
        }

        var ccList: [Int] = []
        var offset = 16
        // COW reads up to six cc entries (distress.c:143-147).
        while start + offset < bytes.count, byte(offset) & 0xc0 == 0xc0, ccList.count < 6 {
            ccList.append(Int(byte(offset) & 0x1f))
            offset += 1
        }
        guard start + offset < bytes.count,
              let position = TextPosition(rawValue: byte(offset)) else { return nil }
        offset += 1

        var textBytes: [UInt8] = []
        while start + offset < bytes.count, byte(offset) != 0 {
            textBytes.append(byte(offset))
            offset += 1
        }

        var distress = Distress(type: type, sender: sender)
        distress.isMacro = byte(0) & 0x20 != 0
        distress.fuel = Int(byte(1) & 0x7f)
        distress.damage = Int(byte(2) & 0x7f)
        distress.shields = Int(byte(3) & 0x7f)
        distress.engineTemp = Int(byte(4) & 0x7f)
        distress.weaponTemp = Int(byte(5) & 0x7f)
        distress.armies = Int(byte(6) & 0x1f)
        distress.status = DistressStatus(rawValue: byte(7))
        distress.nearestPlanet = Int(byte(8) & 0x7f)
        distress.nearestEnemy = Int(byte(9) & 0x7f)
        distress.targetPlanet = Int(byte(10) & 0x7f)
        distress.targetEnemy = Int(byte(11) & 0x7f)
        distress.targetPlayer = Int(byte(12) & 0x7f)
        distress.nearestPlayer = Int(byte(13) & 0x7f)
        distress.targetFriend = Int(byte(14) & 0x7f)
        distress.nearestFriend = Int(byte(15) & 0x7f)
        distress.ccList = ccList
        distress.textPosition = position
        distress.text = String(decoding: textBytes, as: UTF8.self)
        return distress
    }
}
