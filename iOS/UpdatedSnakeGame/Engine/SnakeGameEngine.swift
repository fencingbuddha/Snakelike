//
//  SnakeGameEngine.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import Foundation

struct Food: Equatable, Codable {
    var position: GridPosition
    var type: FoodType
}

struct SnakeGameState: Equatable {
    private(set) var snake: [GridPosition]
    private(set) var direction: Direction
    private(set) var queuedDirection: Direction
    private(set) var growth: Int

    var food: Food
    var score: Int
    var harmony: Int
    var lastFood: FoodType?
    var phaseTurns: Int
    var isGameOver: Bool

    var tickInterval: TimeInterval {
        let base = GameConfig.baseTickMilliseconds - (harmony * GameConfig.tickHarmonyReduction)
        let clamped = max(GameConfig.minTickMilliseconds, base)
        return TimeInterval(clamped) / 1000.0
    }

    var harmonySegments: [Bool] {
        (0 ..< GameConfig.maxHarmony).map { $0 < harmony }
    }

    var head: GridPosition {
        snake[0]
    }

    var snakeBodyWithoutHead: ArraySlice<GridPosition> {
        snake.dropFirst()
    }
}

struct AnyRandomNumberGenerator: RandomNumberGenerator {
    private var nextClosure: () -> UInt64

    init<T: RandomNumberGenerator>(_ generator: T) {
        var mutableGenerator = generator
        nextClosure = {
            mutableGenerator.next()
        }
    }

    mutating func next() -> UInt64 {
        nextClosure()
    }
}

private let foodWeights: [(FoodType, Int)] = [
    (.ember, 3),
    (.tidal, 3),
    (.gale, 4),
    (.prism, 1)
]

struct SnakeGameEngine {
    private(set) var state: SnakeGameState
    private var generator: AnyRandomNumberGenerator

    init<RNG: RandomNumberGenerator>(generator: RNG) {
        self.generator = AnyRandomNumberGenerator(generator)
        let snake = SnakeGameEngine.initialSnake()
        let food = SnakeGameEngine.spawnFood(excluding: snake, using: &self.generator)
        state = SnakeGameState(
            snake: snake,
            direction: .right,
            queuedDirection: .right,
            growth: 0,
            food: food,
            score: 0,
            harmony: 3,
            lastFood: nil,
            phaseTurns: 0,
            isGameOver: false
        )
    }

    init() {
        self.init(generator: SystemRandomNumberGenerator())
    }

    mutating func reset() {
        let snake = SnakeGameEngine.initialSnake()
        let food = SnakeGameEngine.spawnFood(excluding: snake, using: &generator)
        state = SnakeGameState(
            snake: snake,
            direction: .right,
            queuedDirection: .right,
            growth: 0,
            food: food,
            score: 0,
            harmony: 3,
            lastFood: nil,
            phaseTurns: 0,
            isGameOver: false
        )
    }

    mutating func queue(direction: Direction) {
        guard !direction.isOpposite(to: state.queuedDirection) else {
            return
        }
        state = SnakeGameState(
            snake: state.snake,
            direction: state.direction,
            queuedDirection: direction,
            growth: state.growth,
            food: state.food,
            score: state.score,
            harmony: state.harmony,
            lastFood: state.lastFood,
            phaseTurns: state.phaseTurns,
            isGameOver: state.isGameOver
        )
    }

    mutating func advance() {
        guard !state.isGameOver else { return }

        var newDirection = state.queuedDirection
        var body = state.snake
        let currentDirection = newDirection.vector
        let head = state.head
        let newHead = head.offset(by: currentDirection)

        if SnakeGameEngine.isOutOfBounds(newHead) {
            markGameOver()
            return
        }

        let intersectsBody = state.snakeBodyWithoutHead.contains(newHead)
        let phaseActive = state.phaseTurns > 0
        if intersectsBody, !phaseActive {
            markGameOver()
            return
        }

        body.insert(newHead, at: 0)

        var growth = state.growth
        var phaseTurns = state.phaseTurns
        var score = state.score
        var harmony = state.harmony
        var lastFood = state.lastFood
        var food = state.food

        let consumedFood = state.food.position == newHead

        if consumedFood {
            let metadata = food.type.metadata
            score += metadata.baseScore + (harmony * 2)

            let newHarmony: Int
            if food.type == .prism {
                newHarmony = GameConfig.maxHarmony
            } else if let lastFood, lastFood == food.type {
                newHarmony = max(GameConfig.minHarmony, harmony - metadata.repeatPenalty)
            } else if lastFood == nil {
                newHarmony = min(GameConfig.maxHarmony, harmony + 1)
            } else {
                newHarmony = min(GameConfig.maxHarmony, harmony + metadata.mixBoost)
            }
            harmony = newHarmony

            if metadata.phaseBonus > 0 {
                phaseTurns = min(GameConfig.maxPhaseTurns, phaseTurns + metadata.phaseBonus)
            }

            growth += metadata.bonusGrowth
            lastFood = food.type

            food = SnakeGameEngine.spawnFood(excluding: body, using: &generator)
        } else {
            if growth > 0 {
                growth -= 1
            } else {
                body.removeLast()
            }

            if phaseTurns > 0 {
                phaseTurns -= 1
            }
        }

        state = SnakeGameState(
            snake: body,
            direction: newDirection,
            queuedDirection: newDirection,
            growth: growth,
            food: food,
            score: score,
            harmony: harmony,
            lastFood: lastFood,
            phaseTurns: phaseTurns,
            isGameOver: false
        )
    }

    private mutating func markGameOver() {
        state = SnakeGameState(
            snake: state.snake,
            direction: state.direction,
            queuedDirection: state.queuedDirection,
            growth: state.growth,
            food: state.food,
            score: state.score,
            harmony: state.harmony,
            lastFood: state.lastFood,
            phaseTurns: state.phaseTurns,
            isGameOver: true
        )
    }

    private static func initialSnake() -> [GridPosition] {
        let center = GameConfig.gridSize / 2
        return [
            GridPosition(x: center + 1, y: center),
            GridPosition(x: center, y: center),
            GridPosition(x: center - 1, y: center)
        ]
    }

    private static func spawnFood(excluding snake: [GridPosition], using generator: inout AnyRandomNumberGenerator) -> Food {
        let taken = Set(snake)
        var available: [GridPosition] = []

        for y in 0 ..< GameConfig.gridSize {
            for x in 0 ..< GameConfig.gridSize {
                let position = GridPosition(x: x, y: y)
                if !taken.contains(position) {
                    available.append(position)
                }
            }
        }

        if available.isEmpty {
            let fallback = snake.first ?? GridPosition(x: 0, y: 0)
            return Food(position: fallback, type: .prism)
        }

        let position = available.randomElement(using: &generator) ?? GridPosition(x: 0, y: 0)
        let type = pickFoodType(using: &generator)
        return Food(position: position, type: type)
    }

    private static func pickFoodType(using generator: inout AnyRandomNumberGenerator) -> FoodType {
        let total = foodWeights.reduce(0) { $0 + $1.1 }
        let randomValue = Int.random(in: 0 ..< total, using: &generator)
        var cumulative = 0
        for (type, weight) in foodWeights {
            cumulative += weight
            if randomValue < cumulative {
                return type
            }
        }
        return .gale
    }

    private static func isOutOfBounds(_ position: GridPosition) -> Bool {
        position.x < 0 ||
            position.x >= GameConfig.gridSize ||
            position.y < 0 ||
            position.y >= GameConfig.gridSize
    }

    mutating func forceStateForTesting(_ state: SnakeGameState) {
        self.state = state
    }
}
