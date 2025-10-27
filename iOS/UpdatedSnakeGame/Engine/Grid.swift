//
//  Grid.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import Foundation

struct GridPosition: Hashable, Codable {
    var x: Int
    var y: Int
}

struct GridVector {
    var x: Int
    var y: Int
}

extension GridPosition {
    func offset(by vector: GridVector) -> GridPosition {
        GridPosition(x: x + vector.x, y: y + vector.y)
    }
}
