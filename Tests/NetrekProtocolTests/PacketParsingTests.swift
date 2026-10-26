//
//  PacketParsingTests.swift
//  NetrekCoreTests
//
//  Tests for parsing individual Netrek protocol packets.
//  These tests verify that packet data is correctly extracted and converted.
//

import XCTest
@testable import NetrekProtocol

final class PacketParsingTests: XCTestCase {

    // MARK: - SP_PLAYER (Type 4) Tests

    func testParseSpPlayer_ExtractsPlayerId() {
        let packet = PacketBuilder.spPlayer(playerId: 5)

        XCTAssertEqual(packet[0], 4, "Packet type should be 4 (SP_PLAYER)")
        XCTAssertEqual(packet[1], 5, "Player ID should be 5")
    }

    func testParseSpPlayer_ExtractsDirection() {
        let packet = PacketBuilder.spPlayer(playerId: 3, direction: 128)

        XCTAssertEqual(packet[2], 128, "Direction should be 128 (south)")
    }

    func testParseSpPlayer_ExtractsSpeed() {
        let packet = PacketBuilder.spPlayer(playerId: 2, speed: 9)

        XCTAssertEqual(packet[3], 9, "Speed should be 9")
    }

    func testParseSpPlayer_ExtractsPosition() {
        // Create packet with specific position
        let packet = PacketBuilder.spPlayer(playerId: 1, positionX: 75000, positionY: 25000)

        // Extract position X (bytes 4-7, big endian)
        let posXNetrek = packet.subdata(in: 4..<8).withUnsafeBytes {
            $0.load(as: Int32.self).byteSwapped
        }
        XCTAssertEqual(posXNetrek, 75000, "Position X should be 75000")

        // Extract position Y (bytes 8-11, big endian)
        let posYNetrek = packet.subdata(in: 8..<12).withUnsafeBytes {
            $0.load(as: Int32.self).byteSwapped
        }
        XCTAssertEqual(posYNetrek, 25000, "Position Y should be 25000")
    }

    func testParseSpPlayer_ConvertsCoordinates() {
        // Netrek coords are 0-100000, converted to game coords 0-10000
        let packet = PacketBuilder.spPlayer(playerId: 1, positionX: 50000, positionY: 50000)

        let posXNetrek = packet.subdata(in: 4..<8).withUnsafeBytes {
            $0.load(as: Int32.self).byteSwapped
        }
        let posYNetrek = packet.subdata(in: 8..<12).withUnsafeBytes {
            $0.load(as: Int32.self).byteSwapped
        }

        let gameX = NetrekMath.netrekX2GameX(Int(posXNetrek))
        let gameY = NetrekMath.netrekY2GameY(Int(posYNetrek))

        XCTAssertEqual(gameX, 5000, "Game X should be 5000")
        XCTAssertEqual(gameY, 5000, "Game Y should be 5000")
    }

    // MARK: - SP_YOU (Type 12) Tests

    func testParseSpYou_ExtractsPlayerNumber() {
        let packet = PacketBuilder.spYou(playerId: 7)

        XCTAssertEqual(packet[0], 12, "Packet type should be 12 (SP_YOU)")
        XCTAssertEqual(packet[1], 7, "Player ID should be 7")
    }

    func testParseSpYou_ExtractsFlags() {
        let shieldFlag: UInt32 = 0x0001
        let packet = PacketBuilder.spYou(playerId: 5, flags: shieldFlag)

        let flags = packet.subdata(in: 8..<12).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertEqual(flags, shieldFlag, "Flags should match")
        XCTAssertTrue(flags & 0x0001 != 0, "Shield flag should be set")
    }

    func testParseSpYou_ExtractsDamage() {
        let packet = PacketBuilder.spYou(playerId: 3, damage: 50)

        let damage = packet.subdata(in: 12..<16).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertEqual(damage, 50, "Damage should be 50")
    }

    func testParseSpYou_ExtractsFuel() {
        let packet = PacketBuilder.spYou(playerId: 2, fuel: 8000)

        let fuel = packet.subdata(in: 20..<24).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertEqual(fuel, 8000, "Fuel should be 8000")
    }

    func testParseSpYou_ExtractsShieldStrength() {
        let packet = PacketBuilder.spYou(playerId: 1, shieldStrength: 75)

        let shields = packet.subdata(in: 16..<20).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertEqual(shields, 75, "Shield strength should be 75")
    }

    func testParseSpYou_ExtractsMultipleFlags() {
        // Shield + Cloak + Green Alert
        let flags: UInt32 = 0x0001 | 0x0010 | 0x0800
        let packet = PacketBuilder.spYou(playerId: 4, flags: flags)

        let extractedFlags = packet.subdata(in: 8..<12).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertTrue(extractedFlags & 0x0001 != 0, "Shield flag should be set")
        XCTAssertTrue(extractedFlags & 0x0010 != 0, "Cloak flag should be set")
        XCTAssertTrue(extractedFlags & 0x0800 != 0, "Green alert flag should be set")
    }

    // MARK: - SP_FLAGS (Type 18) Tests

    func testParseSpFlags_ExtractsTractor() {
        let packet = PacketBuilder.spFlags(playerId: 8, tractor: 50, flags: 0x400000)

        XCTAssertEqual(packet[0], 18, "Packet type should be 18 (SP_FLAGS)")
        XCTAssertEqual(packet[1], 8, "Player ID should be 8")
        XCTAssertEqual(packet[2], 50, "Tractor should be 50")
    }

    func testParseSpFlags_ExtractsShieldFlag() {
        let packet = PacketBuilder.spFlags(playerId: 3, tractor: 0, flags: 0x0001)

        let flags = packet.subdata(in: 4..<8).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertTrue(flags & 0x0001 != 0, "Shield flag should be set")
    }

    func testParseSpFlags_ExtractsCloakFlag() {
        let packet = PacketBuilder.spFlags(playerId: 5, tractor: 0, flags: 0x0010)

        let flags = packet.subdata(in: 4..<8).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertTrue(flags & 0x0010 != 0, "Cloak flag should be set")
    }

    // MARK: - SP_PLANET (Type 15) Tests

    func testParseSpPlanet_ExtractsPlanetId() {
        let packet = PacketBuilder.spPlanet(planetId: 12)

        XCTAssertEqual(packet[0], 15, "Packet type should be 15 (SP_PLANET)")
        XCTAssertEqual(packet[1], 12, "Planet ID should be 12")
    }

    func testParseSpPlanet_ExtractsOwner() {
        // Owner byte contains team value (0=IND, 1=FED, 2=ROM, 4=KAZ, 8=ORI)
        let packet = PacketBuilder.spPlanet(planetId: 5, owner: 1)

        XCTAssertEqual(packet[2], 1, "Owner should be 1 (Federation)")
    }

    func testParseSpPlanet_ExtractsArmies() {
        let packet = PacketBuilder.spPlanet(planetId: 3, armies: 25)

        let armies = packet.subdata(in: 8..<12).withUnsafeBytes {
            $0.load(as: UInt32.self).byteSwapped
        }

        XCTAssertEqual(armies, 25, "Armies should be 25")
    }

    func testParseSpPlanet_ExtractsFlags() {
        // Repair flag = 0x010
        let packet = PacketBuilder.spPlanet(planetId: 7, flags: 0x010)

        let flags = packet.subdata(in: 4..<6).withUnsafeBytes {
            $0.load(as: UInt16.self).byteSwapped
        }

        XCTAssertEqual(flags, 0x010, "Flags should be 0x010 (repair)")
    }

    func testParseSpPlanet_ExtractsMultipleFlags() {
        // Repair + Fuel + Agri = 0x010 + 0x020 + 0x040 = 0x070
        let flags: UInt16 = 0x070
        let packet = PacketBuilder.spPlanet(planetId: 2, flags: flags)

        let extractedFlags = packet.subdata(in: 4..<6).withUnsafeBytes {
            $0.load(as: UInt16.self).byteSwapped
        }

        XCTAssertTrue(extractedFlags & 0x010 != 0, "Repair flag should be set")
        XCTAssertTrue(extractedFlags & 0x020 != 0, "Fuel flag should be set")
        XCTAssertTrue(extractedFlags & 0x040 != 0, "Agri flag should be set")
    }

    // MARK: - SP_PSTATUS (Type 20) Tests

    func testParseSpPstatus_Free() {
        let packet = PacketBuilder.spPstatus(playerId: 5, status: 0)

        XCTAssertEqual(packet[0], 20, "Packet type should be 20 (SP_PSTATUS)")
        XCTAssertEqual(packet[1], 5, "Player ID should be 5")
        XCTAssertEqual(packet[2], 0, "Status should be 0 (free)")
    }

    func testParseSpPstatus_Outfit() {
        let packet = PacketBuilder.spPstatus(playerId: 3, status: 1)

        XCTAssertEqual(packet[2], 1, "Status should be 1 (outfit)")
    }

    func testParseSpPstatus_Alive() {
        let packet = PacketBuilder.spPstatus(playerId: 7, status: 2)

        XCTAssertEqual(packet[2], 2, "Status should be 2 (alive)")
    }

    func testParseSpPstatus_Explode() {
        let packet = PacketBuilder.spPstatus(playerId: 2, status: 3)

        XCTAssertEqual(packet[2], 3, "Status should be 3 (explode)")
    }

    func testParseSpPstatus_Dead() {
        let packet = PacketBuilder.spPstatus(playerId: 9, status: 4)

        XCTAssertEqual(packet[2], 4, "Status should be 4 (dead)")
    }

    // MARK: - SP_TORP_INFO (Type 5) Tests

    func testParseSpTorpInfo_ExtractsWar() {
        let packet = PacketBuilder.spTorpInfo(torpedoId: 100, war: 0x03, status: 1)

        XCTAssertEqual(packet[0], 5, "Packet type should be 5 (SP_TORP_INFO)")
        XCTAssertEqual(packet[1], 0x03, "War mask should be 0x03 (hostile to FED+ROM)")
    }

    func testParseSpTorpInfo_ExtractsStatus() {
        let packet = PacketBuilder.spTorpInfo(torpedoId: 50, war: 0x01, status: 1)

        XCTAssertEqual(packet[2], 1, "Status should be 1 (active)")
    }

    func testParseSpTorpInfo_ExtractsTorpedoNumber() {
        let packet = PacketBuilder.spTorpInfo(torpedoId: 123, war: 0x04, status: 2)

        let torpId = packet.subdata(in: 4..<6).withUnsafeBytes {
            $0.load(as: UInt16.self).byteSwapped
        }

        XCTAssertEqual(torpId, 123, "Torpedo ID should be 123")
    }

    // MARK: - SP_LASER (Type 7) Tests

    func testParseSpLaser_ExtractsLaserId() {
        let packet = PacketBuilder.spLaser(laserId: 8, status: 1)

        XCTAssertEqual(packet[0], 7, "Packet type should be 7 (SP_LASER)")
        XCTAssertEqual(packet[1], 8, "Laser ID should be 8")
    }

    func testParseSpLaser_ExtractsStatus_Hit() {
        let packet = PacketBuilder.spLaser(laserId: 3, status: 1)

        XCTAssertEqual(packet[2], 1, "Status should be 1 (hit)")
    }

    func testParseSpLaser_ExtractsStatus_Miss() {
        let packet = PacketBuilder.spLaser(laserId: 5, status: 2)

        XCTAssertEqual(packet[2], 2, "Status should be 2 (miss)")
    }

    func testParseSpLaser_ExtractsDirection() {
        let packet = PacketBuilder.spLaser(laserId: 2, status: 2, direction: 64)

        XCTAssertEqual(packet[3], 64, "Direction should be 64")
    }
}
