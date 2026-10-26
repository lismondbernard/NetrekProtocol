//
//  PacketBuilder.swift
//  NetrekCoreTests
//
//  Test fixtures for building valid Netrek protocol packets.
//  Use these to create test data without depending on network.
//

import Foundation

/// Builds Netrek protocol packets for testing
struct PacketBuilder {

    // MARK: - Incoming Server Packets

    /// SP_PLAYER (Type 4) - Player position update, 12 bytes
    static func spPlayer(
        playerId: UInt8,
        direction: UInt8 = 0,
        speed: UInt8 = 0,
        positionX: Int32 = 50000,
        positionY: Int32 = 50000
    ) -> Data {
        var data = Data(count: 12)
        data[0] = 4           // packet type
        data[1] = playerId
        data[2] = direction
        data[3] = speed

        // Position X (big endian, 4 bytes)
        let xBE = positionX.bigEndian
        withUnsafeBytes(of: xBE) { bytes in
            data[4] = bytes[0]
            data[5] = bytes[1]
            data[6] = bytes[2]
            data[7] = bytes[3]
        }

        // Position Y (big endian, 4 bytes)
        let yBE = positionY.bigEndian
        withUnsafeBytes(of: yBE) { bytes in
            data[8] = bytes[0]
            data[9] = bytes[1]
            data[10] = bytes[2]
            data[11] = bytes[3]
        }

        return data
    }

    /// SP_YOU (Type 12) - Own ship status, 32 bytes
    static func spYou(
        playerId: UInt8,
        hostile: UInt8 = 0,
        war: UInt8 = 0,
        armies: UInt8 = 0,
        tractor: UInt8 = 0,
        flags: UInt32 = 0x0800,  // Green alert by default
        damage: UInt32 = 0,
        shieldStrength: UInt32 = 100,
        fuel: UInt32 = 10000,
        engineTemp: UInt16 = 0,
        weaponsTemp: UInt16 = 0,
        whyDead: UInt16 = 0,
        whoDead: UInt16 = 0
    ) -> Data {
        var data = Data(count: 32)
        data[0] = 12          // packet type
        data[1] = playerId
        data[2] = hostile
        data[3] = war
        data[4] = armies
        data[5] = tractor
        data[6] = 0           // padding
        data[7] = 0           // padding

        // Flags (big endian, 4 bytes at offset 8-11)
        let flagsBE = flags.bigEndian
        withUnsafeBytes(of: flagsBE) { bytes in
            data[8] = bytes[0]
            data[9] = bytes[1]
            data[10] = bytes[2]
            data[11] = bytes[3]
        }

        // Damage (big endian, 4 bytes at offset 12-15)
        let damageBE = damage.bigEndian
        withUnsafeBytes(of: damageBE) { bytes in
            data[12] = bytes[0]
            data[13] = bytes[1]
            data[14] = bytes[2]
            data[15] = bytes[3]
        }

        // Shield strength (big endian, 4 bytes at offset 16-19)
        let shieldBE = shieldStrength.bigEndian
        withUnsafeBytes(of: shieldBE) { bytes in
            data[16] = bytes[0]
            data[17] = bytes[1]
            data[18] = bytes[2]
            data[19] = bytes[3]
        }

        // Fuel (big endian, 4 bytes at offset 20-23)
        let fuelBE = fuel.bigEndian
        withUnsafeBytes(of: fuelBE) { bytes in
            data[20] = bytes[0]
            data[21] = bytes[1]
            data[22] = bytes[2]
            data[23] = bytes[3]
        }

        // Engine temp (big endian, 2 bytes at offset 24-25)
        let engineTempBE = engineTemp.bigEndian
        withUnsafeBytes(of: engineTempBE) { bytes in
            data[24] = bytes[0]
            data[25] = bytes[1]
        }

        // Weapons temp (big endian, 2 bytes at offset 26-27)
        let weaponsTempBE = weaponsTemp.bigEndian
        withUnsafeBytes(of: weaponsTempBE) { bytes in
            data[26] = bytes[0]
            data[27] = bytes[1]
        }

        // whyDead (big endian, 2 bytes at offset 28-29)
        let whyDeadBE = whyDead.bigEndian
        withUnsafeBytes(of: whyDeadBE) { bytes in
            data[28] = bytes[0]
            data[29] = bytes[1]
        }

        // whoDead (big endian, 2 bytes at offset 30-31)
        let whoDeadBE = whoDead.bigEndian
        withUnsafeBytes(of: whoDeadBE) { bytes in
            data[30] = bytes[0]
            data[31] = bytes[1]
        }

        return data
    }

    /// SP_PSTATUS (Type 20) - Player slot status, 4 bytes
    static func spPstatus(playerId: UInt8, status: UInt8) -> Data {
        var data = Data(count: 4)
        data[0] = 20          // packet type
        data[1] = playerId
        data[2] = status      // 0=free, 1=outfit, 2=alive, 3=explode, 4=dead, 5=observe
        data[3] = 0           // padding
        return data
    }

    /// SP_FLAGS (Type 18) - Player flags, 8 bytes
    static func spFlags(playerId: UInt8, tractor: UInt8, flags: UInt32) -> Data {
        var data = Data(count: 8)
        data[0] = 18          // packet type
        data[1] = playerId
        data[2] = tractor
        data[3] = 0           // padding

        // Flags (big endian, 4 bytes)
        let flagsBE = flags.bigEndian
        withUnsafeBytes(of: flagsBE) { bytes in
            data[4] = bytes[0]
            data[5] = bytes[1]
            data[6] = bytes[2]
            data[7] = bytes[3]
        }

        return data
    }

    /// SP_PICKOK (Type 16) - Outfit accepted, 4 bytes
    static func spPickok(state: UInt8) -> Data {
        var data = Data(count: 4)
        data[0] = 16          // packet type
        data[1] = state       // 1 = accepted, 0 = rejected
        data[2] = 0           // padding
        data[3] = 0           // padding
        return data
    }

    /// SP_TORP (Type 6) - Torpedo position, 12 bytes
    static func spTorp(
        torpedoId: UInt16,
        direction: UInt8 = 0,
        positionX: UInt32 = 50000,
        positionY: UInt32 = 50000
    ) -> Data {
        var data = Data(count: 12)
        data[0] = 6           // packet type
        data[1] = direction

        // Torpedo ID (big endian, 2 bytes)
        let torpIdBE = torpedoId.bigEndian
        withUnsafeBytes(of: torpIdBE) { bytes in
            data[2] = bytes[0]
            data[3] = bytes[1]
        }

        // Position (big endian)
        let xBE = positionX.bigEndian
        let yBE = positionY.bigEndian
        withUnsafeBytes(of: xBE) { bytes in
            for i in 0..<4 { data[4 + i] = bytes[i] }
        }
        withUnsafeBytes(of: yBE) { bytes in
            for i in 0..<4 { data[8 + i] = bytes[i] }
        }

        return data
    }

    /// SP_TORP_INFO (Type 5) - Torpedo status, 8 bytes
    static func spTorpInfo(
        torpedoId: UInt16,
        war: UInt8,
        status: UInt8  // 0=inactive, 1=active, 2-3=exploding
    ) -> Data {
        var data = Data(count: 8)
        data[0] = 5           // packet type
        data[1] = war
        data[2] = status
        data[3] = 0           // padding

        // Torpedo ID (big endian, 2 bytes)
        let torpIdBE = torpedoId.bigEndian
        withUnsafeBytes(of: torpIdBE) { bytes in
            data[4] = bytes[0]
            data[5] = bytes[1]
        }

        data[6] = 0           // padding
        data[7] = 0
        return data
    }

    /// SP_LASER (Type 7) - Laser/phaser, 16 bytes
    static func spLaser(
        laserId: UInt8,
        status: UInt8,  // 0=inactive, 1=hit, 2=miss, 4=hit plasma
        direction: UInt8 = 0,
        positionX: UInt32 = 50000,
        positionY: UInt32 = 50000,
        target: Int32 = 0
    ) -> Data {
        var data = Data(count: 16)
        data[0] = 7           // packet type
        data[1] = laserId
        data[2] = status
        data[3] = direction

        // Position (big endian)
        let xBE = positionX.bigEndian
        let yBE = positionY.bigEndian
        withUnsafeBytes(of: xBE) { bytes in
            for i in 0..<4 { data[4 + i] = bytes[i] }
        }
        withUnsafeBytes(of: yBE) { bytes in
            for i in 0..<4 { data[8 + i] = bytes[i] }
        }

        // Target player (bytes 12-15, big endian Int32)
        let targetBE = target.bigEndian
        withUnsafeBytes(of: targetBE) { bytes in
            for i in 0..<4 { data[12 + i] = bytes[i] }
        }

        return data
    }

    /// SP_PHASER (Type 7) - Alias for spLaser for backward compatibility
    static func spPhaser(
        playerId: UInt8,
        status: UInt8,
        direction: UInt8,
        targetX: Int32 = 50000,
        targetY: Int32 = 50000
    ) -> Data {
        return spLaser(laserId: playerId, status: status, direction: direction,
                       positionX: UInt32(targetX), positionY: UInt32(targetY))
    }

    /// SP_PLANET (Type 15) - Planet state, 16 bytes (per PACKET_SIZES)
    static func spPlanet(
        planetId: UInt8,
        owner: UInt8 = 0,
        info: UInt8 = 0,
        flags: UInt16 = 0,
        armies: UInt32 = 10
    ) -> Data {
        var data = Data(count: 16)
        data[0] = 15          // packet type
        data[1] = planetId
        data[2] = owner
        data[3] = info

        // Flags (big endian, 2 bytes)
        let flagsBE = flags.bigEndian
        withUnsafeBytes(of: flagsBE) { bytes in
            data[4] = bytes[0]
            data[5] = bytes[1]
        }

        // Padding bytes 6-7
        data[6] = 0
        data[7] = 0

        // Armies (big endian, 4 bytes at offset 8-11)
        let armiesBE = armies.bigEndian
        withUnsafeBytes(of: armiesBE) { bytes in
            data[8] = bytes[0]
            data[9] = bytes[1]
            data[10] = bytes[2]
            data[11] = bytes[3]
        }

        // Padding bytes 12-15
        data[12] = 0
        data[13] = 0
        data[14] = 0
        data[15] = 0

        return data
    }

    /// SP_MESSAGE (Type 1) - Chat message, 84 bytes
    static func spMessage(
        flags: UInt8 = 0,
        recipient: UInt8 = 0,
        from: UInt8 = 255,
        message: String
    ) -> Data {
        var data = Data(count: 84)
        data[0] = 1           // packet type
        data[1] = flags
        data[2] = recipient
        data[3] = from

        // Message text (80 bytes, null-terminated)
        let messageBytes = Array(message.utf8.prefix(79))
        for (i, byte) in messageBytes.enumerated() {
            data[4 + i] = byte
        }
        // Remaining bytes are already 0 (null padding)

        return data
    }

    // MARK: - Packet Sequence Builders

    /// Creates a sequence of packets for testing packet framing
    static func gameplayBurst(playerCount: Int = 3, torpCount: Int = 2) -> Data {
        var data = Data()

        // Player position updates
        for i in 0..<playerCount {
            data.append(spPlayer(playerId: UInt8(i), direction: UInt8(i * 32), speed: 5))
        }

        // Torpedo updates
        for i in 0..<torpCount {
            data.append(spTorpInfo(torpedoId: UInt16(i), war: 0, status: 1))
            data.append(spTorp(torpedoId: UInt16(i)))
        }

        return data
    }

    /// Creates a login sequence of packets
    static func loginSequence(playerId: UInt8) -> Data {
        var data = Data()
        data.append(spYou(playerId: playerId))
        data.append(spPstatus(playerId: playerId, status: 1))  // outfit
        data.append(spPickok(state: 1))
        data.append(spPstatus(playerId: playerId, status: 2))  // alive
        return data
    }
}
