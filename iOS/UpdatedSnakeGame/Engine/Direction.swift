//
//  Direction.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import Foundation

enum Direction: CaseIterable {
    case up
    case down
    case left
    case right

    var vector: GridVector {
        switch self {
        case .up:
            return GridVector(x: 0, y: -1)
        case .down:
            return GridVector(x: 0, y: 1)
        case .left:
            return GridVector(x: -1, y: 0)
        case .right:
            return GridVector(x: 1, y: 0)
        }
    }

    var name: String {
        switch self {
        case .up: return "UP"
        case .down: return "DOWN"
        case .left: return "LEFT"
        case .right: return "RIGHT"
        }
    }

    func isOpposite(to other: Direction) -> Bool {
        (vector.x + other.vector.x == 0) && (vector.y + other.vector.y == 0)
    }
}
