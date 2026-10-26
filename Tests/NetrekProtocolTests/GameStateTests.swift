//
//  GameStateTests.swift
//  NetrekCoreTests
//
//  Tests for GameState enum and state machine transitions.
//  These tests verify the game connection lifecycle:
//  noServerSelected → serverSelected → serverConnected → serverSlotFound → loginAccepted → gameActive
//

import XCTest
@testable import NetrekProtocol

final class GameStateTests: XCTestCase {

    // MARK: - GameState Enum Tests

    func testGameState_AllCases() {
        let allStates = GameState.allCases

        XCTAssertEqual(allStates.count, 6, "GameState should have 6 cases")
        XCTAssertTrue(allStates.contains(.noServerSelected), "Should include noServerSelected")
        XCTAssertTrue(allStates.contains(.serverSelected), "Should include serverSelected")
        XCTAssertTrue(allStates.contains(.serverConnected), "Should include serverConnected")
        XCTAssertTrue(allStates.contains(.serverSlotFound), "Should include serverSlotFound")
        XCTAssertTrue(allStates.contains(.loginAccepted), "Should include loginAccepted")
        XCTAssertTrue(allStates.contains(.gameActive), "Should include gameActive")
    }

    func testGameState_RawValues() {
        XCTAssertEqual(GameState.noServerSelected.rawValue, "noServerSelected")
        XCTAssertEqual(GameState.serverSelected.rawValue, "serverSelected")
        XCTAssertEqual(GameState.serverConnected.rawValue, "serverConnected")
        XCTAssertEqual(GameState.serverSlotFound.rawValue, "serverSlotFound")
        XCTAssertEqual(GameState.loginAccepted.rawValue, "loginAccepted")
        XCTAssertEqual(GameState.gameActive.rawValue, "gameActive")
    }

    func testGameState_InitFromRawValue_Valid() {
        XCTAssertEqual(GameState(rawValue: "noServerSelected"), .noServerSelected)
        XCTAssertEqual(GameState(rawValue: "serverSelected"), .serverSelected)
        XCTAssertEqual(GameState(rawValue: "serverConnected"), .serverConnected)
        XCTAssertEqual(GameState(rawValue: "serverSlotFound"), .serverSlotFound)
        XCTAssertEqual(GameState(rawValue: "loginAccepted"), .loginAccepted)
        XCTAssertEqual(GameState(rawValue: "gameActive"), .gameActive)
    }

    func testGameState_InitFromRawValue_Invalid() {
        XCTAssertNil(GameState(rawValue: "invalidState"), "Invalid raw value should return nil")
        XCTAssertNil(GameState(rawValue: ""), "Empty string should return nil")
        XCTAssertNil(GameState(rawValue: "gameactive"), "Case-sensitive: wrong case should return nil")
    }

    // MARK: - State Ordering Tests

    func testGameState_ExpectedOrder() {
        // Verify states are in the expected progression order
        let states = GameState.allCases

        XCTAssertEqual(states[0], .noServerSelected, "First state should be noServerSelected")
        XCTAssertEqual(states[1], .serverSelected, "Second state should be serverSelected")
        XCTAssertEqual(states[2], .serverConnected, "Third state should be serverConnected")
        XCTAssertEqual(states[3], .serverSlotFound, "Fourth state should be serverSlotFound")
        XCTAssertEqual(states[4], .loginAccepted, "Fifth state should be loginAccepted")
        XCTAssertEqual(states[5], .gameActive, "Sixth state should be gameActive")
    }

    // MARK: - State Transition Validation Tests
    // These tests verify the logical progression of states

    func testStateProgression_NoServerToServerSelected() {
        // This is the first transition when user selects a server
        let initialState = GameState.noServerSelected
        let nextState = GameState.serverSelected

        XCTAssertNotEqual(initialState, nextState, "States should be different")
        XCTAssertTrue(GameState.allCases.firstIndex(of: initialState)! < GameState.allCases.firstIndex(of: nextState)!,
                     "serverSelected should come after noServerSelected")
    }

    func testStateProgression_ServerSelectedToConnected() {
        // Transition when TCP connection established
        let initialState = GameState.serverSelected
        let nextState = GameState.serverConnected

        XCTAssertTrue(GameState.allCases.firstIndex(of: initialState)! < GameState.allCases.firstIndex(of: nextState)!,
                     "serverConnected should come after serverSelected")
    }

    func testStateProgression_ConnectedToSlotFound() {
        // Transition when server assigns a player slot (SP_YOU packet)
        let initialState = GameState.serverConnected
        let nextState = GameState.serverSlotFound

        XCTAssertTrue(GameState.allCases.firstIndex(of: initialState)! < GameState.allCases.firstIndex(of: nextState)!,
                     "serverSlotFound should come after serverConnected")
    }

    func testStateProgression_SlotFoundToLoginAccepted() {
        // Transition when login credentials accepted (SP_LOGIN packet)
        let initialState = GameState.serverSlotFound
        let nextState = GameState.loginAccepted

        XCTAssertTrue(GameState.allCases.firstIndex(of: initialState)! < GameState.allCases.firstIndex(of: nextState)!,
                     "loginAccepted should come after serverSlotFound")
    }

    func testStateProgression_LoginAcceptedToGameActive() {
        // Transition when entering outfit/game (SP_PICKOK packet)
        let initialState = GameState.loginAccepted
        let nextState = GameState.gameActive

        XCTAssertTrue(GameState.allCases.firstIndex(of: initialState)! < GameState.allCases.firstIndex(of: nextState)!,
                     "gameActive should come after loginAccepted")
    }

    func testStateProgression_CompleteSequence() {
        // Verify the complete happy path progression
        let progression: [GameState] = [
            .noServerSelected,
            .serverSelected,
            .serverConnected,
            .serverSlotFound,
            .loginAccepted,
            .gameActive
        ]

        for i in 0..<(progression.count - 1) {
            let currentIndex = GameState.allCases.firstIndex(of: progression[i])!
            let nextIndex = GameState.allCases.firstIndex(of: progression[i + 1])!

            XCTAssertTrue(currentIndex < nextIndex,
                         "\(progression[i+1]) should come after \(progression[i])")
        }
    }

    // MARK: - State Equality Tests

    func testGameState_Equality() {
        XCTAssertEqual(GameState.noServerSelected, GameState.noServerSelected)
        XCTAssertEqual(GameState.gameActive, GameState.gameActive)
    }

    func testGameState_Inequality() {
        XCTAssertNotEqual(GameState.noServerSelected, GameState.serverSelected)
        XCTAssertNotEqual(GameState.loginAccepted, GameState.gameActive)
        XCTAssertNotEqual(GameState.serverConnected, GameState.noServerSelected)
    }

    // MARK: - Reset/Disconnect Scenarios

    func testStateReset_FromGameActiveToNoServer() {
        // When user disconnects or gets ghostbusted
        let activeState = GameState.gameActive
        let resetState = GameState.noServerSelected

        XCTAssertNotEqual(activeState, resetState, "States should be different")
        // This is a backward transition (reset)
        XCTAssertTrue(GameState.allCases.firstIndex(of: resetState)! < GameState.allCases.firstIndex(of: activeState)!,
                     "Reset goes back to first state")
    }

    func testStateReset_FromServerConnectedToNoServer() {
        // Connection failed scenario
        let connectedState = GameState.serverConnected
        let resetState = GameState.noServerSelected

        XCTAssertTrue(GameState.allCases.firstIndex(of: resetState)! < GameState.allCases.firstIndex(of: connectedState)!,
                     "Reset goes back to first state")
    }

    func testStateReset_FromLoginAcceptedToNoServer() {
        // Disconnected during outfit
        let loginState = GameState.loginAccepted
        let resetState = GameState.noServerSelected

        XCTAssertTrue(GameState.allCases.firstIndex(of: resetState)! < GameState.allCases.firstIndex(of: loginState)!,
                     "Reset goes back to first state")
    }

    // MARK: - State Name Validation Tests

    func testGameState_DescriptiveNames() {
        // Verify state names are descriptive and match expected patterns
        XCTAssertTrue(GameState.noServerSelected.rawValue.lowercased().contains("server"))
        XCTAssertTrue(GameState.serverSelected.rawValue.lowercased().contains("server"))
        XCTAssertTrue(GameState.serverConnected.rawValue.lowercased().contains("connected"))
        XCTAssertTrue(GameState.serverSlotFound.rawValue.lowercased().contains("slot"))
        XCTAssertTrue(GameState.loginAccepted.rawValue.lowercased().contains("login"))
        XCTAssertTrue(GameState.gameActive.rawValue.lowercased().contains("active"))
    }

    // MARK: - CaseIterable Tests

    func testGameState_CaseIterableConformance() {
        // Verify CaseIterable provides all cases
        let allCases = GameState.allCases

        XCTAssertFalse(allCases.isEmpty, "allCases should not be empty")

        // Each case should appear exactly once
        let uniqueCases = Set(allCases)
        XCTAssertEqual(uniqueCases.count, allCases.count, "All cases should be unique")
    }

    func testGameState_CanIterateAllCases() {
        // Verify we can iterate through all cases
        var stateNames: [String] = []

        for state in GameState.allCases {
            stateNames.append(state.rawValue)
        }

        XCTAssertEqual(stateNames.count, 6, "Should iterate through 6 states")
        XCTAssertTrue(stateNames.contains("noServerSelected"))
        XCTAssertTrue(stateNames.contains("serverSelected"))
        XCTAssertTrue(stateNames.contains("serverConnected"))
        XCTAssertTrue(stateNames.contains("serverSlotFound"))
        XCTAssertTrue(stateNames.contains("loginAccepted"))
        XCTAssertTrue(stateNames.contains("gameActive"))
    }

    // MARK: - Switch Statement Coverage Tests

    func testGameState_SwitchExhaustiveness() {
        // Verify all states can be handled in a switch
        var handledStates: [GameState] = []

        for state in GameState.allCases {
            switch state {
            case .noServerSelected:
                handledStates.append(.noServerSelected)
            case .serverSelected:
                handledStates.append(.serverSelected)
            case .serverConnected:
                handledStates.append(.serverConnected)
            case .serverSlotFound:
                handledStates.append(.serverSlotFound)
            case .loginAccepted:
                handledStates.append(.loginAccepted)
            case .gameActive:
                handledStates.append(.gameActive)
            }
        }

        XCTAssertEqual(handledStates.count, 6, "All 6 states should be handled")
        XCTAssertEqual(Set(handledStates).count, 6, "All handled states should be unique")
    }

    // MARK: - Initial State Tests

    func testGameState_InitialState() {
        // The initial state should always be noServerSelected
        let initialState = GameState.noServerSelected

        XCTAssertEqual(initialState.rawValue, "noServerSelected")
        XCTAssertEqual(GameState.allCases.first, .noServerSelected,
                      "First state in progression should be noServerSelected")
    }

    func testGameState_FinalState() {
        // The final state in normal progression should be gameActive
        let finalState = GameState.gameActive

        XCTAssertEqual(finalState.rawValue, "gameActive")
        XCTAssertEqual(GameState.allCases.last, .gameActive,
                      "Last state in progression should be gameActive")
    }

    // MARK: - State Comparison Tests

    func testGameState_BeforeAfterComparison() {
        // Test that we can compare state progression using array indices
        let noServer = GameState.noServerSelected
        let serverSel = GameState.serverSelected

        let noServerIndex = GameState.allCases.firstIndex(of: noServer)!
        let serverSelIndex = GameState.allCases.firstIndex(of: serverSel)!

        XCTAssertTrue(noServerIndex < serverSelIndex,
                     "noServerSelected should have lower index than serverSelected")
    }

    func testGameState_ProgressionDistance() {
        // Test the "distance" between states in the progression
        let startState = GameState.noServerSelected
        let endState = GameState.gameActive

        let startIndex = GameState.allCases.firstIndex(of: startState)!
        let endIndex = GameState.allCases.firstIndex(of: endState)!

        let distance = endIndex - startIndex
        XCTAssertEqual(distance, 5, "Distance from noServerSelected to gameActive should be 5 steps")
    }
}
