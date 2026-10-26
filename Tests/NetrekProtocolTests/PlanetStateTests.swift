//
//  PlanetStateTests.swift
//  NetrekCoreTests
//
//  Tests for Planet model state updates.
//  These tests verify that Planet objects correctly update from packet data.
//

import XCTest
@testable import NetrekProtocol

final class PlanetStateTests: XCTestCase {

    var planet: Planet!

    override func setUp() {
        super.setUp()
        planet = Planet(planetId: 10)
    }

    override func tearDown() {
        planet = nil
        super.tearDown()
    }

    // MARK: - Planet Creation Tests

    func testPlanetUpdate_NameAndPosition() {
        let expectation = XCTestExpectation(description: "Planet update")
        planet.update(name: "Earth", positionX: 2500, positionY: 7500)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.name, "Earth", "Name should update to Earth")
            XCTAssertEqual(self.planet.positionX, 2500, "Position X should update")
            XCTAssertEqual(self.planet.positionY, 7500, "Position Y should update")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_ShortName() {
        let expectation = XCTestExpectation(description: "Planet update")
        planet.update(name: "Earth", positionX: 2500, positionY: 7500)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.shortName, "Ear", "Short name should be first 3 characters")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_ShortName_LessThan3Chars() {
        planet.update(name: "Ea", positionX: 2500, positionY: 7500)

        // Short name should handle names < 3 characters gracefully
        XCTAssertTrue(planet.shortName.count <= 3, "Short name should be <= 3 characters")
    }

    // MARK: - Owner Update Tests

    func testPlanetUpdate_OwnerFederation() {
        let expectation = XCTestExpectation(description: "Owner update")
        // Owner value 1 = Federation (team.rawValue)
        planet.update(owner: 1, info: 0, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.owner, .federation, "Owner should be Federation")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_OwnerRoman() {
        let expectation = XCTestExpectation(description: "Owner update")
        planet.update(owner: 2, info: 0, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.owner, .roman, "Owner should be Roman")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_OwnerKazari() {
        let expectation = XCTestExpectation(description: "Owner update")
        planet.update(owner: 4, info: 0, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.owner, .kazari, "Owner should be Kazari")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_OwnerOrion() {
        let expectation = XCTestExpectation(description: "Owner update")
        planet.update(owner: 8, info: 0, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.owner, .orion, "Owner should be Orion")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_OwnerIndependent() {
        let expectation = XCTestExpectation(description: "Owner update")
        planet.update(owner: 0, info: 0, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.owner, .independent, "Owner should be Independent")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Armies Update Tests

    func testPlanetUpdate_Armies() {
        let expectation = XCTestExpectation(description: "Armies update")
        planet.update(owner: 1, info: 0, flags: 0, armies: 25)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.planet.armies, 25, "Armies should be 25")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_ArmiesZero() {
        planet.update(owner: 1, info: 0, flags: 0, armies: 0)

        XCTAssertEqual(planet.armies, 0, "Armies can be zero")
    }

    // MARK: - Planet Flags Tests

    func testPlanetUpdate_AgriFlag() {
        let expectation = XCTestExpectation(description: "Flag update")
        // Agri flag = 0x040
        planet.update(owner: 1, info: 0, flags: 0x040, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.planet.agri, "Agri flag should be set")
            XCTAssertFalse(self.planet.fuel, "Fuel flag should not be set")
            XCTAssertFalse(self.planet.repair, "Repair flag should not be set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_FuelFlag() {
        let expectation = XCTestExpectation(description: "Flag update")
        // Fuel flag = 0x020
        planet.update(owner: 1, info: 0, flags: 0x020, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.planet.agri, "Agri flag should not be set")
            XCTAssertTrue(self.planet.fuel, "Fuel flag should be set")
            XCTAssertFalse(self.planet.repair, "Repair flag should not be set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_RepairFlag() {
        let expectation = XCTestExpectation(description: "Flag update")
        // Repair flag = 0x010
        planet.update(owner: 1, info: 0, flags: 0x010, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.planet.agri, "Agri flag should not be set")
            XCTAssertFalse(self.planet.fuel, "Fuel flag should not be set")
            XCTAssertTrue(self.planet.repair, "Repair flag should be set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_MultipleFlags() {
        let expectation = XCTestExpectation(description: "Flag update")
        // Repair + Fuel + Agri = 0x010 + 0x020 + 0x040 = 0x070
        planet.update(owner: 1, info: 0, flags: 0x070, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.planet.agri, "Agri flag should be set")
            XCTAssertTrue(self.planet.fuel, "Fuel flag should be set")
            XCTAssertTrue(self.planet.repair, "Repair flag should be set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_NoFlags() {
        let expectation = XCTestExpectation(description: "Flag update")
        planet.update(owner: 1, info: 0, flags: 0x000, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.planet.agri, "Agri flag should not be set")
            XCTAssertFalse(self.planet.fuel, "Fuel flag should not be set")
            XCTAssertFalse(self.planet.repair, "Repair flag should not be set")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Planet Visibility (Info) Tests

    func testPlanetUpdate_SeenByFederation() {
        let expectation = XCTestExpectation(description: "Visibility update")
        // Info field: bitmask of teams that have seen the planet
        // Federation = 1
        planet.update(owner: 0, info: 1, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.planet.seen[.federation] ?? false, "Federation should have seen planet")
            XCTAssertFalse(self.planet.seen[.roman] ?? true, "Roman should not have seen planet")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_SeenByMultipleTeams() {
        let expectation = XCTestExpectation(description: "Visibility update")
        // Federation (1) + Kazari (4) = 5
        planet.update(owner: 0, info: 5, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.planet.seen[.federation] ?? false, "Federation should have seen planet")
            XCTAssertFalse(self.planet.seen[.roman] ?? true, "Roman should not have seen planet")
            XCTAssertTrue(self.planet.seen[.kazari] ?? false, "Kazari should have seen planet")
            XCTAssertFalse(self.planet.seen[.orion] ?? true, "Orion should not have seen planet")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testPlanetUpdate_NotSeenByAnyTeam() {
        let expectation = XCTestExpectation(description: "Visibility update")
        planet.update(owner: 0, info: 0, flags: 0, armies: 10)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.planet.seen[.federation] ?? true, "Federation should not have seen planet")
            XCTAssertFalse(self.planet.seen[.roman] ?? true, "Roman should not have seen planet")
            XCTAssertFalse(self.planet.seen[.kazari] ?? true, "Kazari should not have seen planet")
            XCTAssertFalse(self.planet.seen[.orion] ?? true, "Orion should not have seen planet")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - isSeen

    func testIsSeen_FollowsInfoBits() {
        let expectation = XCTestExpectation(description: "Planet update")
        planet.update(owner: 1, info: 0x01 | 0x04, flags: 0, armies: 0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.planet.isSeen(by: .federation))
            XCTAssertTrue(self.planet.isSeen(by: .kazari))
            XCTAssertFalse(self.planet.isSeen(by: .roman))
            XCTAssertFalse(self.planet.isSeen(by: .orion))
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
