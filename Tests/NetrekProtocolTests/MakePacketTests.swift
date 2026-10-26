//
//  MakePacketTests.swift
//  NetrekCoreTests
//
//  Unit tests for outgoing packet construction.
//  These packets are sent to the server to control your ship.
//  Wrong encoding = wrong commands sent to server.
//

import XCTest
@testable import NetrekProtocol

final class MakePacketTests: XCTestCase {

    // MARK: - CP_SPEED Tests (Type 2)

    func testCpSpeed_PacketType_Is2() {
        guard let data = MakePacket.cpSpeed(speed: 5) else {
            XCTFail("cpSpeed should return data for valid speed")
            return
        }
        XCTAssertEqual(data[0], 2, "CP_SPEED packet type should be 2")
    }

    func testCpSpeed_Size_Is4() {
        guard let data = MakePacket.cpSpeed(speed: 5) else {
            XCTFail("cpSpeed should return data for valid speed")
            return
        }
        XCTAssertEqual(data.count, 4, "CP_SPEED packet should be 4 bytes")
    }

    func testCpSpeed_SpeedValue_EncodedAtIndex1() {
        guard let data = MakePacket.cpSpeed(speed: 7) else {
            XCTFail("cpSpeed should return data for valid speed")
            return
        }
        XCTAssertEqual(data[1], 7, "Speed value should be at index 1")
    }

    func testCpSpeed_MinSpeed_Zero() {
        guard let data = MakePacket.cpSpeed(speed: 0) else {
            XCTFail("cpSpeed should accept speed 0")
            return
        }
        XCTAssertEqual(data[1], 0, "Minimum speed 0 should be encoded")
    }

    func testCpSpeed_MaxSpeed_12() {
        guard let data = MakePacket.cpSpeed(speed: 12) else {
            XCTFail("cpSpeed should accept speed 12")
            return
        }
        XCTAssertEqual(data[1], 12, "Maximum speed 12 should be encoded")
    }

    func testCpSpeed_NegativeSpeed_ReturnsNil() {
        let data = MakePacket.cpSpeed(speed: -1)
        XCTAssertNil(data, "Negative speed should return nil")
    }

    func testCpSpeed_TooHighSpeed_ReturnsNil() {
        let data = MakePacket.cpSpeed(speed: 13)
        XCTAssertNil(data, "Speed > 12 should return nil")
    }

    // MARK: - CP_DIRECTION Tests (Type 3)

    func testCpDirection_PacketType_Is3() {
        guard let data = MakePacket.cpDirection(netrekDirection: 0) else {
            XCTFail("cpDirection should return data")
            return
        }
        XCTAssertEqual(data[0], 3, "CP_DIRECTION packet type should be 3")
    }

    func testCpDirection_Size_Is4() {
        guard let data = MakePacket.cpDirection(netrekDirection: 64) else {
            XCTFail("cpDirection should return data")
            return
        }
        XCTAssertEqual(data.count, 4, "CP_DIRECTION packet should be 4 bytes")
    }

    func testCpDirection_Direction_EncodedAtIndex1() {
        guard let data = MakePacket.cpDirection(netrekDirection: 128) else {
            XCTFail("cpDirection should return data")
            return
        }
        XCTAssertEqual(data[1], 128, "Direction value should be at index 1")
    }

    func testCpDirection_AllDirections() {
        // Test all 256 possible directions
        for direction: UInt8 in 0...255 {
            guard let data = MakePacket.cpDirection(netrekDirection: direction) else {
                XCTFail("cpDirection should accept direction \(direction)")
                continue
            }
            XCTAssertEqual(data[1], direction, "Direction \(direction) should be encoded correctly")
        }
    }

    // MARK: - CP_LASER Tests (Type 4)

    func testCpLaser_PacketType_Is4() {
        let data = MakePacket.cpLaser(netrekDirection: 0)
        XCTAssertEqual(data[0], 4, "CP_LASER packet type should be 4")
    }

    func testCpLaser_Size_Is4() {
        let data = MakePacket.cpLaser(netrekDirection: 0)
        XCTAssertEqual(data.count, 4, "CP_LASER packet should be 4 bytes")
    }

    func testCpLaser_Direction_EncodedAtIndex1() {
        let data = MakePacket.cpLaser(netrekDirection: 192)
        XCTAssertEqual(data[1], 192, "Laser direction should be at index 1")
    }

    // MARK: - CP_PLASMA Tests (Type 5)

    func testCpPlasma_PacketType_Is5() {
        let data = MakePacket.cpPlasma(netrekDirection: 0)
        XCTAssertEqual(data[0], 5, "CP_PLASMA packet type should be 5")
    }

    func testCpPlasma_Size_Is4() {
        let data = MakePacket.cpPlasma(netrekDirection: 0)
        XCTAssertEqual(data.count, 4, "CP_PLASMA packet should be 4 bytes")
    }

    // MARK: - CP_TORP Tests (Type 6)

    func testCpTorp_PacketType_Is6() {
        let data = MakePacket.cpTorp(netrekDirection: 0)
        XCTAssertEqual(data[0], 6, "CP_TORP packet type should be 6")
    }

    func testCpTorp_Size_Is4() {
        let data = MakePacket.cpTorp(netrekDirection: 0)
        XCTAssertEqual(data.count, 4, "CP_TORP packet should be 4 bytes")
    }

    func testCpTorp_Direction_EncodedAtIndex1() {
        let data = MakePacket.cpTorp(netrekDirection: 64)
        XCTAssertEqual(data[1], 64, "Torpedo direction should be at index 1")
    }

    // MARK: - CP_LOGIN Tests (Type 8)

    func testCpLogin_PacketType_Is8() {
        let data = MakePacket.cpLogin(name: "test", password: "pass", login: "tester")
        XCTAssertEqual(data[0], 8, "CP_LOGIN packet type should be 8")
    }

    func testCpLogin_Size_Is52() {
        let data = MakePacket.cpLogin(name: "test", password: "pass", login: "tester")
        XCTAssertEqual(data.count, 52, "CP_LOGIN packet should be 52 bytes")
    }

    // MARK: - CP_OUTFIT Tests (Type 9)

    func testCpOutfit_PacketType_Is9() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .cruiser)
        XCTAssertEqual(data[0], 9, "CP_OUTFIT packet type should be 9")
    }

    func testCpOutfit_Size_Is4() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .cruiser)
        XCTAssertEqual(data.count, 4, "CP_OUTFIT packet should be 4 bytes")
    }

    func testCpOutfit_TeamMapping_FederationIs0() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .cruiser)
        XCTAssertEqual(data[1], 0, "Federation should map to team byte 0")
    }

    func testCpOutfit_TeamMapping_RomanIs1() {
        let data = MakePacket.cpOutfit(team: .roman, ship: .cruiser)
        XCTAssertEqual(data[1], 1, "Roman should map to team byte 1")
    }

    func testCpOutfit_TeamMapping_KazariIs2() {
        let data = MakePacket.cpOutfit(team: .kazari, ship: .cruiser)
        XCTAssertEqual(data[1], 2, "Kazari should map to team byte 2")
    }

    func testCpOutfit_TeamMapping_OrionIs3() {
        let data = MakePacket.cpOutfit(team: .orion, ship: .cruiser)
        XCTAssertEqual(data[1], 3, "Orion should map to team byte 3")
    }

    func testCpOutfit_TeamMapping_IndependentIs255() {
        let data = MakePacket.cpOutfit(team: .independent, ship: .cruiser)
        XCTAssertEqual(data[1], 255, "Independent should map to team byte 255")
    }

    func testCpOutfit_TeamMapping_OggIs255() {
        let data = MakePacket.cpOutfit(team: .ogg, ship: .cruiser)
        XCTAssertEqual(data[1], 255, "Ogg should map to team byte 255")
    }

    func testCpOutfit_ShipType_Scout() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .scout)
        XCTAssertEqual(data[2], 0, "Scout should map to ship byte 0")
    }

    func testCpOutfit_ShipType_Destroyer() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .destroyer)
        XCTAssertEqual(data[2], 1, "Destroyer should map to ship byte 1")
    }

    func testCpOutfit_ShipType_Cruiser() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .cruiser)
        XCTAssertEqual(data[2], 2, "Cruiser should map to ship byte 2")
    }

    func testCpOutfit_ShipType_Battleship() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .battleship)
        XCTAssertEqual(data[2], 3, "Battleship should map to ship byte 3")
    }

    func testCpOutfit_ShipType_Assault() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .assault)
        XCTAssertEqual(data[2], 4, "Assault should map to ship byte 4")
    }

    func testCpOutfit_ShipType_Starbase() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .starbase)
        XCTAssertEqual(data[2], 5, "Starbase should map to ship byte 5")
    }

    func testCpOutfit_ShipType_Battlecruiser() {
        let data = MakePacket.cpOutfit(team: .federation, ship: .battlecruiser)
        XCTAssertEqual(data[2], 6, "Battlecruiser should map to ship byte 6")
    }

    // MARK: - CP_SHIELD Tests (Type 12)

    func testCpShield_PacketType_Is12() {
        let data = MakePacket.cpShield(up: true)
        XCTAssertEqual(data[0], 12, "CP_SHIELD packet type should be 12")
    }

    func testCpShield_Size_Is4() {
        let data = MakePacket.cpShield(up: true)
        XCTAssertEqual(data.count, 4, "CP_SHIELD packet should be 4 bytes")
    }

    func testCpShield_Up_State1() {
        let data = MakePacket.cpShield(up: true)
        XCTAssertEqual(data[1], 1, "Shields up should be state 1")
    }

    func testCpShield_Down_State0() {
        let data = MakePacket.cpShield(up: false)
        XCTAssertEqual(data[1], 0, "Shields down should be state 0")
    }

    // MARK: - CP_CLOAK Tests (Type 19)

    func testCpCloak_PacketType_Is19() {
        let data = MakePacket.cpCloak(state: true)
        XCTAssertEqual(data[0], 19, "CP_CLOAK packet type should be 19")
    }

    func testCpCloak_On_State1() {
        let data = MakePacket.cpCloak(state: true)
        XCTAssertEqual(data[1], 1, "Cloak on should be state 1")
    }

    func testCpCloak_Off_State0() {
        let data = MakePacket.cpCloak(state: false)
        XCTAssertEqual(data[1], 0, "Cloak off should be state 0")
    }

    // MARK: - make16Tuple Tests (String packing)

    func testMake16Tuple_ShortString_PadsWithNulls() {
        let tuple = MakePacket.make16Tuple(string: "test")
        // First 4 bytes should be 't', 'e', 's', 't'
        XCTAssertEqual(tuple.0, UInt8(ascii: "t"))
        XCTAssertEqual(tuple.1, UInt8(ascii: "e"))
        XCTAssertEqual(tuple.2, UInt8(ascii: "s"))
        XCTAssertEqual(tuple.3, UInt8(ascii: "t"))
        // Remaining should be null
        XCTAssertEqual(tuple.4, 0)
        XCTAssertEqual(tuple.5, 0)
        XCTAssertEqual(tuple.15, 0)
    }

    func testMake16Tuple_EmptyString() {
        let tuple = MakePacket.make16Tuple(string: "")
        // All should be null
        XCTAssertEqual(tuple.0, 0)
        XCTAssertEqual(tuple.1, 0)
        XCTAssertEqual(tuple.15, 0)
    }

    func testMake16Tuple_ExactLength15_LastIsNull() {
        // 15 characters - last position should still be null
        let tuple = MakePacket.make16Tuple(string: "123456789012345")
        XCTAssertEqual(tuple.0, UInt8(ascii: "1"))
        XCTAssertEqual(tuple.14, UInt8(ascii: "5"))
        XCTAssertEqual(tuple.15, 0, "Position 15 should always be null for null-termination")
    }

    func testMake16Tuple_LongString_Truncates() {
        // 20 characters - should truncate to 15
        let tuple = MakePacket.make16Tuple(string: "12345678901234567890")
        XCTAssertEqual(tuple.0, UInt8(ascii: "1"))
        XCTAssertEqual(tuple.14, UInt8(ascii: "5"))  // 15th char
        XCTAssertEqual(tuple.15, 0, "Position 15 should be null even with long string")
    }

    // MARK: - CP_QUIT Tests (Type 7)

    func testCpQuit_PacketType_Is7() {
        let data = MakePacket.cpQuit()
        XCTAssertEqual(data[0], 7, "CP_QUIT packet type should be 7")
    }

    func testCpQuit_Size_Is4() {
        let data = MakePacket.cpQuit()
        XCTAssertEqual(data.count, 4, "CP_QUIT packet should be 4 bytes")
    }

    // MARK: - CP_BYE Tests (Type 29)

    func testCpBye_PacketType_Is29() {
        let data = MakePacket.cpBye()
        XCTAssertEqual(data[0], 29, "CP_BYE packet type should be 29")
    }

    // MARK: - CP_UPDATES Tests (Type 31)

    func testCpUpdates_PacketType_Is31() {
        let data = MakePacket.cpUpdates()
        XCTAssertEqual(data[0], 31, "CP_UPDATES packet type should be 31")
    }

    // MARK: - CP_DET_TORPS Tests (Type 20)

    func testCpDetTorps_PacketType_Is20() {
        let data = MakePacket.cpDetTorps()
        XCTAssertEqual(data[0], 20, "CP_DET_TORPS packet type should be 20")
    }

    // MARK: - CP_TRACTOR Tests (Type 24)

    func testCpTractor_On() {
        let data = MakePacket.cpTractor(on: true, playerID: 5)
        XCTAssertEqual(data[0], 24, "CP_TRACTOR packet type should be 24")
        XCTAssertEqual(data[1], 1, "Tractor on should be state 1")
        XCTAssertEqual(data[2], 5, "Player ID should be encoded")
    }

    func testCpTractor_Off() {
        let data = MakePacket.cpTractor(on: false, playerID: 3)
        XCTAssertEqual(data[1], 0, "Tractor off should be state 0")
    }

    // MARK: - CP_PRESSOR Tests (Type 25)

    func testCpPressor_On() {
        let data = MakePacket.cpPressor(on: true, playerID: 7)
        XCTAssertEqual(data[0], 25, "CP_REPRESS packet type should be 25")
        XCTAssertEqual(data[1], 1, "Pressor on should be state 1")
        XCTAssertEqual(data[2], 7, "Player ID should be encoded")
    }

    // MARK: - CP_BOMB Tests (Type 17)

    func testCpBomb_On() {
        let data = MakePacket.cpBomb(state: true)
        XCTAssertEqual(data[0], 17, "CP_BOMB packet type should be 17")
        XCTAssertEqual(data[1], 1, "Bomb on should be state 1")
    }

    func testCpBomb_Off() {
        let data = MakePacket.cpBomb(state: false)
        XCTAssertEqual(data[1], 0, "Bomb off should be state 0")
    }

    // MARK: - CP_BEAM Tests (Type 18)

    func testCpBeam_Up_State1() {
        let data = MakePacket.cpBeam(state: true)
        XCTAssertEqual(data[0], 18, "CP_BEAM packet type should be 18")
        XCTAssertEqual(data[1], 1, "Beam up should be state 1")
    }

    func testCpBeam_Down_State2() {
        let data = MakePacket.cpBeam(state: false)
        XCTAssertEqual(data[1], 2, "Beam down should be state 2")
    }
}
