//
//  FoodType.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import Foundation

enum FoodType: String, CaseIterable, Codable {
    case ember
    case tidal
    case gale
    case prism

    struct Metadata {
        let colorHex: String
        let label: String
        let description: String
        let baseScore: Int
        let bonusGrowth: Int
        let mixBoost: Int
        let repeatPenalty: Int
        let phaseBonus: Int
    }

    var metadata: Metadata {
        switch self {
        case .ember:
            return Metadata(
                colorHex: "#ff6b6b",
                label: "Ember Bloom",
                description: "Supercharges growth but punishes repeats.",
                baseScore: 14,
                bonusGrowth: 1,
                mixBoost: 2,
                repeatPenalty: 2,
                phaseBonus: 0
            )
        case .tidal:
            return Metadata(
                colorHex: "#4d96ff",
                label: "Tidal Pearl",
                description: "Adds phase turns to slip through yourself.",
                baseScore: 16,
                bonusGrowth: 0,
                mixBoost: 1,
                repeatPenalty: 1,
                phaseBonus: 2
            )
        case .gale:
            return Metadata(
                colorHex: "#3ad29f",
                label: "Gale Petal",
                description: "Keeps harmony steady and awards steady points.",
                baseScore: 12,
                bonusGrowth: 0,
                mixBoost: 1,
                repeatPenalty: 0,
                phaseBonus: 0
            )
        case .prism:
            return Metadata(
                colorHex: "#b388ff",
                label: "Prism Core",
                description: "Refills harmony and grants long phasing.",
                baseScore: 32,
                bonusGrowth: 0,
                mixBoost: GameConfig.maxHarmony,
                repeatPenalty: 0,
                phaseBonus: 6
            )
        }
    }
}
