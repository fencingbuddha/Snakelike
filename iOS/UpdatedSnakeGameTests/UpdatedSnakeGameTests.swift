//
//  UpdatedSnakeGameTests.swift
//  UpdatedSnakeGameTests
//
//  Created by Codex on 2024-05-24.
//

import XCTest
@testable import UpdatedSnakeGame

private struct DeterministicGenerator: RandomNumberGenerator {
    private var numbers: [UInt64]
    private var index: Int = 0

    init(_ numbers: [UInt64]) {
        self.numbers = numbers
    }

    mutating func next() -> UInt64 {
        guard !numbers.isEmpty else {
            return 0
        }
        let value = numbers[index % numbers.count]
        index += 1
        return value
    }
}

final class UpdatedSnakeGameTests: XCTestCase {
    func testEngineStartsInExpectedState() {
        var engine = SnakeGameEngine(generator: DeterministicGenerator([0, 1, 2]))

        let state = engine.state
        XCTAssertEqual(state.snake.count, 3)
        XCTAssertEqual(state.direction, .right)
        XCTAssertEqual(state.score, 0)
        XCTAssertEqual(state.harmony, 3)
        XCTAssertFalse(state.isGameOver)
        XCTAssertTrue((0 ..< GameConfig.gridSize).contains(state.food.position.x))
        XCTAssertTrue((0 ..< GameConfig.gridSize).contains(state.food.position.y))
    }

    func testMovingWithoutFoodConsumesTail() {
        var engine = SnakeGameEngine(generator: DeterministicGenerator([0, 1, 2]))
        let initialState = engine.state
        let tail = initialState.snake.last!

        engine.advance()
        let newState = engine.state

        XCTAssertEqual(newState.snake.count, initialState.snake.count)
        XCTAssertFalse(newState.snake.contains(tail))
        XCTAssertGreaterThan(newState.snake.first!.x, initialState.snake.first!.x - 1)
    }

    func testFoodConsumptionImprovesScoreAndGrowth() {
        var engine = SnakeGameEngine(generator: DeterministicGenerator([0]))
        var state = engine.state

        // Force food to be directly in front of head
        let head = state.head
        let front = head.offset(by: state.direction.vector)
        state = SnakeGameState(
            snake: state.snake,
            direction: state.direction,
            queuedDirection: state.queuedDirection,
            growth: state.growth,
            food: Food(position: front, type: .ember),
            score: state.score,
            harmony: state.harmony,
            lastFood: state.lastFood,
            phaseTurns: state.phaseTurns,
            isGameOver: state.isGameOver
        )
        engine.forceStateForTesting(state)

        engine.advance()

        let updated = engine.state
        XCTAssertGreaterThan(updated.score, 0)
        XCTAssertEqual(updated.lastFood, .ember)
        XCTAssertGreaterThanOrEqual(updated.harmony, state.harmony)
    }

    func testRepeatingFoodPenalizesHarmony() {
        var engine = SnakeGameEngine(generator: DeterministicGenerator([0]))
        var head = engine.state.head
        let forward = head.offset(by: engine.state.direction.vector)

        var forcedState = engine.state
        forcedState = SnakeGameState(
            snake: forcedState.snake,
            direction: forcedState.direction,
            queuedDirection: forcedState.queuedDirection,
            growth: forcedState.growth,
            food: Food(position: forward, type: .ember),
            score: forcedState.score,
            harmony: forcedState.harmony,
            lastFood: .ember,
            phaseTurns: forcedState.phaseTurns,
            isGameOver: forcedState.isGameOver
        )
        engine.forceStateForTesting(forcedState)

        engine.advance()

        XCTAssertLessThanOrEqual(engine.state.harmony, forcedState.harmony)
    }

    func testPhaseTurnsAllowSelfIntersection() {
        var engine = SnakeGameEngine(generator: DeterministicGenerator([0]))

        // Build a small loop manually
        let head = engine.state.head
        let right = head.offset(by: Direction.right.vector)

        var forcedState = engine.state
        forcedState = SnakeGameState(
            snake: [
                right,
                head,
                GridPosition(x: head.x - 1, y: head.y),
                GridPosition(x: head.x - 1, y: head.y + 1),
                GridPosition(x: head.x, y: head.y + 1)
            ],
            direction: .up,
            queuedDirection: .up,
            growth: 0,
            food: Food(position: GridPosition(x: head.x, y: head.y - 1), type: .tidal),
            score: 0,
            harmony: 3,
            lastFood: .tidal,
            phaseTurns: 2,
            isGameOver: false
        )
        engine.forceStateForTesting(forcedState)

        engine.advance()
        XCTAssertFalse(engine.state.isGameOver)
    }

    func testCollisionWithoutPhaseEndsGame() {
        var engine = SnakeGameEngine(generator: DeterministicGenerator([0]))

        let head = engine.state.head
        let right = head.offset(by: Direction.right.vector)

        var forcedState = engine.state
        forcedState = SnakeGameState(
            snake: [
                right,
                head,
                GridPosition(x: head.x - 1, y: head.y),
                GridPosition(x: head.x - 1, y: head.y + 1),
                GridPosition(x: head.x, y: head.y + 1)
            ],
            direction: .up,
            queuedDirection: .up,
            growth: 0,
            food: forcedState.food,
            score: forcedState.score,
            harmony: forcedState.harmony,
            lastFood: forcedState.lastFood,
            phaseTurns: 0,
            isGameOver: false
        )
        engine.forceStateForTesting(forcedState)

        engine.advance()
        XCTAssertTrue(engine.state.isGameOver)
    }
}
