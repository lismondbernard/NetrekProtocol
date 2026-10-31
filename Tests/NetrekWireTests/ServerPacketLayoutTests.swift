//
//  ServerPacketLayoutTests.swift
//  NetrekWireTests
//

import XCTest
import NetrekWire

/// Senders copy each SP_* struct straight out of memory, so the
/// struct's in-memory size has to equal its classic wire size. These
/// tests pin the sizes and field offsets to classic packets.h.
final class ServerPacketLayoutTests: XCTestCase {

    func offset<T>(_ key: PartialKeyPath<T>) -> Int? {
        return MemoryLayout<T>.offset(of: key)
    }

    // MARK: - Struct size matches the wire size

    func testStructSizesMatchWireSizes() {
        XCTAssertEqual(MemoryLayout<SP_MESSAGE>.size, 84)
        XCTAssertEqual(MemoryLayout<SP_PLAYER_INFO>.size, 4)
        XCTAssertEqual(MemoryLayout<SP_KILLS>.size, 8)
        XCTAssertEqual(MemoryLayout<SP_PLAYER>.size, 12)
        XCTAssertEqual(MemoryLayout<SP_TORP_INFO>.size, 8)
        XCTAssertEqual(MemoryLayout<SP_TORP>.size, 12)
        XCTAssertEqual(MemoryLayout<SP_LASER>.size, 16)
        XCTAssertEqual(MemoryLayout<SP_PLASMA_INFO>.size, 8)
        XCTAssertEqual(MemoryLayout<SP_PLASMA>.size, 12)
        XCTAssertEqual(MemoryLayout<SP_MOTD>.size, 84)
        XCTAssertEqual(MemoryLayout<SP_YOU>.size, 32)
        XCTAssertEqual(MemoryLayout<SP_QUEUE>.size, 4)
        XCTAssertEqual(MemoryLayout<SP_PLANET>.size, 12)
        XCTAssertEqual(MemoryLayout<SP_PICKOK>.size, 4)
        XCTAssertEqual(MemoryLayout<SP_LOGIN>.size, 104)
        XCTAssertEqual(MemoryLayout<SP_FLAGS>.size, 8)
        XCTAssertEqual(MemoryLayout<SP_MASK>.size, 4)
        XCTAssertEqual(MemoryLayout<SP_PLAYER_STATUS>.size, 4)
        XCTAssertEqual(MemoryLayout<SP_HOSTILE>.size, 4)
        XCTAssertEqual(MemoryLayout<SP_STATS>.size, 56)
        XCTAssertEqual(MemoryLayout<SP_PL_LOGIN>.size, 52)
        XCTAssertEqual(MemoryLayout<SP_PLANET_LOC>.size, 28)
        XCTAssertEqual(MemoryLayout<SP_SHIP_CAP>.size, 60)
    }

    func testDeclaredSizesMatchStructSizes() {
        XCTAssertEqual(SP_MESSAGE().size, MemoryLayout<SP_MESSAGE>.size)
        XCTAssertEqual(SP_MOTD().size, MemoryLayout<SP_MOTD>.size)
        XCTAssertEqual(SP_LOGIN().size, MemoryLayout<SP_LOGIN>.size)
        XCTAssertEqual(SP_PICKOK().size, MemoryLayout<SP_PICKOK>.size)
        XCTAssertEqual(SP_LASER().size, MemoryLayout<SP_LASER>.size)
        XCTAssertEqual(SP_SHIP_CAP().size, MemoryLayout<SP_SHIP_CAP>.size)
    }

    // MARK: - Field offsets

    func testSpMessageOffsets() {
        XCTAssertEqual(offset(\SP_MESSAGE.flags), 1)
        XCTAssertEqual(offset(\SP_MESSAGE.recpt), 2)
        XCTAssertEqual(offset(\SP_MESSAGE.from), 3)
        XCTAssertEqual(offset(\SP_MESSAGE.message), 4)
    }

    func testSpPlayerInfoOffsets() {
        XCTAssertEqual(offset(\SP_PLAYER_INFO.playerNum), 1)
        XCTAssertEqual(offset(\SP_PLAYER_INFO.shipType), 2)
        XCTAssertEqual(offset(\SP_PLAYER_INFO.team), 3)
    }

    func testSpKillsOffsets() {
        XCTAssertEqual(offset(\SP_KILLS.playerNum), 1)
        XCTAssertEqual(offset(\SP_KILLS.kills), 4)
    }

    func testSpPlayerOffsets() {
        XCTAssertEqual(offset(\SP_PLAYER.playerNum), 1)
        XCTAssertEqual(offset(\SP_PLAYER.directionNetrek), 2)
        XCTAssertEqual(offset(\SP_PLAYER.speed), 3)
        XCTAssertEqual(offset(\SP_PLAYER.positionX), 4)
        XCTAssertEqual(offset(\SP_PLAYER.positionY), 8)
    }

    func testSpTorpInfoOffsets() {
        XCTAssertEqual(offset(\SP_TORP_INFO.war), 1)
        XCTAssertEqual(offset(\SP_TORP_INFO.status), 2)
        XCTAssertEqual(offset(\SP_TORP_INFO.torpedoNumber), 4)
        XCTAssertEqual(offset(\SP_TORP_INFO.pad2), 6)
    }

    func testSpTorpOffsets() {
        XCTAssertEqual(offset(\SP_TORP.direction), 1)
        XCTAssertEqual(offset(\SP_TORP.torpedoNum), 2)
        XCTAssertEqual(offset(\SP_TORP.positionX), 4)
        XCTAssertEqual(offset(\SP_TORP.positionY), 8)
    }

    func testSpLaserOffsets() {
        XCTAssertEqual(offset(\SP_LASER.laserID), 1)
        XCTAssertEqual(offset(\SP_LASER.status), 2)
        XCTAssertEqual(offset(\SP_LASER.direction), 3)
        XCTAssertEqual(offset(\SP_LASER.positionX), 4)
        XCTAssertEqual(offset(\SP_LASER.positionY), 8)
        XCTAssertEqual(offset(\SP_LASER.target), 12)
    }

    func testSpPlasmaInfoOffsets() {
        XCTAssertEqual(offset(\SP_PLASMA_INFO.war), 1)
        XCTAssertEqual(offset(\SP_PLASMA_INFO.status), 2)
        XCTAssertEqual(offset(\SP_PLASMA_INFO.plasmaNumber), 4)
        XCTAssertEqual(offset(\SP_PLASMA_INFO.pad2), 6)
    }

    func testSpPlasmaOffsets() {
        XCTAssertEqual(offset(\SP_PLASMA.direction), 1)
        XCTAssertEqual(offset(\SP_PLASMA.plasmaNum), 2)
        XCTAssertEqual(offset(\SP_PLASMA.positionX), 4)
        XCTAssertEqual(offset(\SP_PLASMA.positionY), 8)
    }

    func testSpMotdOffsets() {
        XCTAssertEqual(offset(\SP_MOTD.motd), 4)
    }

    func testSpYouOffsets() {
        XCTAssertEqual(offset(\SP_YOU.playerNum), 1)
        XCTAssertEqual(offset(\SP_YOU.hostile), 2)
        XCTAssertEqual(offset(\SP_YOU.war), 3)
        XCTAssertEqual(offset(\SP_YOU.armies), 4)
        XCTAssertEqual(offset(\SP_YOU.tractor), 5)
        XCTAssertEqual(offset(\SP_YOU.flags), 8)
        XCTAssertEqual(offset(\SP_YOU.damage), 12)
        XCTAssertEqual(offset(\SP_YOU.shield), 16)
        XCTAssertEqual(offset(\SP_YOU.fuel), 20)
        XCTAssertEqual(offset(\SP_YOU.etmp), 24)
        XCTAssertEqual(offset(\SP_YOU.wtmp), 26)
        XCTAssertEqual(offset(\SP_YOU.whydead), 28)
        XCTAssertEqual(offset(\SP_YOU.whodead), 30)
    }

    func testSpQueueOffsets() {
        XCTAssertEqual(offset(\SP_QUEUE.position), 2)
    }

    func testSpPlanetOffsets() {
        XCTAssertEqual(offset(\SP_PLANET.planetNum), 1)
        XCTAssertEqual(offset(\SP_PLANET.owner), 2)
        XCTAssertEqual(offset(\SP_PLANET.info), 3)
        XCTAssertEqual(offset(\SP_PLANET.flags), 4)
        XCTAssertEqual(offset(\SP_PLANET.armies), 8)
    }

    func testSpPickOkOffsets() {
        XCTAssertEqual(offset(\SP_PICKOK.state), 1)
    }

    func testSpLoginOffsets() {
        XCTAssertEqual(offset(\SP_LOGIN.accept), 1)
        XCTAssertEqual(offset(\SP_LOGIN.paradise1), 2)
        XCTAssertEqual(offset(\SP_LOGIN.paradise2), 3)
        XCTAssertEqual(offset(\SP_LOGIN.flags), 4)
        XCTAssertEqual(offset(\SP_LOGIN.keymap), 8)
        XCTAssertEqual(MemoryLayout.size(ofValue: SP_LOGIN().keymap), 96)
    }

    func testSpFlagsOffsets() {
        XCTAssertEqual(offset(\SP_FLAGS.playerID), 1)
        XCTAssertEqual(offset(\SP_FLAGS.tractor), 2)
        XCTAssertEqual(offset(\SP_FLAGS.flags), 4)
    }

    func testSpMaskOffsets() {
        XCTAssertEqual(offset(\SP_MASK.mask), 1)
    }

    func testSpPlayerStatusOffsets() {
        XCTAssertEqual(offset(\SP_PLAYER_STATUS.playerNum), 1)
        XCTAssertEqual(offset(\SP_PLAYER_STATUS.status), 2)
    }

    func testSpHostileOffsets() {
        XCTAssertEqual(offset(\SP_HOSTILE.playerID), 1)
        XCTAssertEqual(offset(\SP_HOSTILE.war), 2)
        XCTAssertEqual(offset(\SP_HOSTILE.hostile), 3)
    }

    func testSpStatsOffsets() {
        XCTAssertEqual(offset(\SP_STATS.playerID), 1)
        XCTAssertEqual(offset(\SP_STATS.tournamentKills), 4)
        XCTAssertEqual(offset(\SP_STATS.tournamentLosses), 8)
        XCTAssertEqual(offset(\SP_STATS.overallKills), 12)
        XCTAssertEqual(offset(\SP_STATS.overallLosses), 16)
        XCTAssertEqual(offset(\SP_STATS.tournamentTicks), 20)
        XCTAssertEqual(offset(\SP_STATS.tournamentPlanets), 24)
        XCTAssertEqual(offset(\SP_STATS.tournamentArmies), 28)
        XCTAssertEqual(offset(\SP_STATS.starbaseKills), 32)
        XCTAssertEqual(offset(\SP_STATS.starbaseLosses), 36)
        XCTAssertEqual(offset(\SP_STATS.intramuralArmies), 40)
        XCTAssertEqual(offset(\SP_STATS.intramuralPlanets), 44)
        XCTAssertEqual(offset(\SP_STATS.maxKills100), 48)
        XCTAssertEqual(offset(\SP_STATS.starbaseMaxKills100), 52)
    }

    func testSpPlLoginOffsets() {
        XCTAssertEqual(offset(\SP_PL_LOGIN.playerNum), 1)
        XCTAssertEqual(offset(\SP_PL_LOGIN.rank), 2)
        XCTAssertEqual(offset(\SP_PL_LOGIN.name), 4)
        XCTAssertEqual(offset(\SP_PL_LOGIN.monitor), 20)
        XCTAssertEqual(offset(\SP_PL_LOGIN.login), 36)
    }

    func testSpPlanetLocOffsets() {
        XCTAssertEqual(offset(\SP_PLANET_LOC.planetID), 1)
        XCTAssertEqual(offset(\SP_PLANET_LOC.positionX), 4)
        XCTAssertEqual(offset(\SP_PLANET_LOC.positionY), 8)
        XCTAssertEqual(offset(\SP_PLANET_LOC.name), 12)
    }

    func testSpShipCapOffsets() {
        XCTAssertEqual(offset(\SP_SHIP_CAP.operation), 1)
        XCTAssertEqual(offset(\SP_SHIP_CAP.shipType), 2)
        XCTAssertEqual(offset(\SP_SHIP_CAP.torpSpeed), 4)
        XCTAssertEqual(offset(\SP_SHIP_CAP.phaserRange), 6)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxSpeed), 8)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxFuel), 12)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxShield), 16)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxDamage), 20)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxWeaponTemp), 24)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxEngineTemp), 28)
        XCTAssertEqual(offset(\SP_SHIP_CAP.width), 32)
        XCTAssertEqual(offset(\SP_SHIP_CAP.height), 34)
        XCTAssertEqual(offset(\SP_SHIP_CAP.maxArmies), 36)
        XCTAssertEqual(offset(\SP_SHIP_CAP.letter), 38)
        XCTAssertEqual(offset(\SP_SHIP_CAP.name), 40)
        XCTAssertEqual(offset(\SP_SHIP_CAP.designation1), 56)
        XCTAssertEqual(offset(\SP_SHIP_CAP.designation2), 57)
        XCTAssertEqual(offset(\SP_SHIP_CAP.bitmap), 58)
    }

    // MARK: - Client to server sizes

    func testCpScanHasASize() {
        XCTAssertEqual(CLIENT_PACKET_SIZES[34], 4)
    }
}
