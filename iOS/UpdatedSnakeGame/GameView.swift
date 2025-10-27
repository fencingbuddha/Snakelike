//
//  GameView.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = SnakeGameViewModel()
    var onExit: () -> Void = {}

    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#060913") ?? .black, Color(hex: "#0d1324") ?? .black]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                gradient.ignoresSafeArea()

                VStack(spacing: 20) {
                    header
                    harmonyMeter
                    board
                        .frame(maxWidth: .infinity)
                        .layoutPriority(1)
                    footer
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 20))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                exitButton
                    .padding(.trailing, 24)
                    .padding(.top, 24)
            }
            .onAppear {
                viewModel.startGameLoop()
            }
            .onDisappear {
                viewModel.stopGameLoop()
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Chromatic Current")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Keep your elemental harmony high by weaving between different blooms.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#8f9bb5") ?? .gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#6c7aa1") ?? .gray)
                Text("\(viewModel.state.score)")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Text("Phase \(max(0, viewModel.state.phaseTurns))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#7dd3fc") ?? .teal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "#0d1324") ?? .black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#1f2a4c") ?? .gray, lineWidth: 1)
                    )
            )
        }
    }

    private var harmonyMeter: some View {
        let segments = viewModel.state.harmonySegments

        return VStack(alignment: .leading, spacing: 8) {
            Text("Harmony")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "#9bb5ff") ?? .blue)

            HStack(spacing: 6) {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, filled in
                    RoundedRectangle(cornerRadius: 6)
                        .fill(filled ? (Color(hex: "#61dbff") ?? .cyan) : (Color(hex: "#1a2542") ?? .black))
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(hex: "#1b243d") ?? .gray.opacity(0.6), lineWidth: 1)
                        )
                }
            }

            if let lastFood = viewModel.state.lastFood {
                Text("Last: \(lastFood.metadata.label)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: lastFood.metadata.colorHex) ?? .white)
            } else {
                Text("Grab different blooms to build harmony.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "#0d1324") ?? .black)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#1b243d") ?? .gray, lineWidth: 1)
                )
        )
    }

    private var board: some View {
        GeometryReader { geometry in
            let boardSize = min(geometry.size.width, geometry.size.height)
            let cellSize = boardSize / CGFloat(GameConfig.gridSize)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(hex: "#05070f") ?? .black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: "#10182d") ?? .gray, lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    ForEach(0 ..< GameConfig.gridSize, id: \.self) { y in
                        HStack(spacing: 0) {
                            ForEach(0 ..< GameConfig.gridSize, id: \.self) { x in
                                let position = GridPosition(x: x, y: y)
                                let isHead = position == viewModel.state.head
                                let isBody = viewModel.state.snake.contains(position)
                                let isFood = position == viewModel.state.food.position

                                CellView(
                                    isHead: isHead,
                                    isBody: isBody,
                                    isFood: isFood,
                                    foodType: viewModel.state.food.type
                                )
                                .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(12)
            }
            .frame(width: boardSize, height: boardSize)
            .gesture(dragGesture)
            .overlay(gameOverOverlay)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Elemental Effects")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(FoodType.allCases, id: \.self) { foodType in
                    let metadata = foodType.metadata
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: metadata.colorHex) ?? .white)
                            .frame(width: 22, height: 22)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(metadata.label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Text(metadata.description)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#8f9bb5") ?? .gray)
                        }
                    }
                }
            }

            Text("Matching colors repeatedly drains harmony. Fill the meter to speed up and gain bigger score bonuses!")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#6c7aa1") ?? .gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "#0d1324") ?? .black)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color(hex: "#1f2a4c") ?? .gray, lineWidth: 1)
                )
        )
    }

    private var gameOverOverlay: some View {
        Group {
            if viewModel.state.isGameOver {
                ZStack {
                    Color.black.opacity(0.7)
                    VStack(spacing: 12) {
                        Text("Harmony Shattered")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Your chromatic current collapsed.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#9bb5ff") ?? .blue)
                        Button(action: {
                            viewModel.restart()
                        }) {
                            Text("Restart Run")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#05070f") ?? .black)
                                .padding(.horizontal, 28)
                                .padding(.vertical, 14)
                                .background((Color(hex: "#61dbff") ?? .cyan).cornerRadius(999))
                        }
                    }
                    .padding()
                }
            }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onEnded { value in
                let translation = value.translation
                if abs(translation.width) > abs(translation.height) {
                    if translation.width > 0 {
                        viewModel.queue(direction: .right)
                    } else {
                        viewModel.queue(direction: .left)
                    }
                } else {
                    if translation.height > 0 {
                        viewModel.queue(direction: .down)
                    } else {
                        viewModel.queue(direction: .up)
                    }
                }
            }
    }

    private var exitButton: some View {
        Button(action: onExit) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.9), Color.white.opacity(0.2))
                .shadow(radius: 8, y: 4)
        }
        .accessibilityLabel("Exit Game")
    }
}

private struct CellView: View {
    var isHead: Bool
    var isBody: Bool
    var isFood: Bool
    var foodType: FoodType

    private var background: Color {
        if isHead {
            return Color(hex: "#61dbff") ?? .cyan
        }
        if isBody {
            return Color(hex: "#32e0c4") ?? .green
        }
        if isFood {
            return Color(hex: foodType.metadata.colorHex) ?? .white
        }
        return Color(hex: "#070b18") ?? .black
    }

    private var border: Color {
        if isHead {
            return Color(hex: "#9bf6ff") ?? .white
        }
        if isBody {
            return Color(hex: "#22b498") ?? .green
        }
        if isFood {
            return Color.white.opacity(0.13)
        }
        return Color(hex: "#0b1329") ?? .gray
    }

    var body: some View {
        Rectangle()
            .fill(background)
            .overlay(
                Rectangle()
                    .stroke(border, lineWidth: 0.6)
            )
    }
}

struct GameView_Previews: PreviewProvider {
    static var previews: some View {
        GameView()
            .preferredColorScheme(.dark)
    }
}
