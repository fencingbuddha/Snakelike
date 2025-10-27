//
//  SnakeGameViewModel.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import Combine
import Foundation

@MainActor
final class SnakeGameViewModel: ObservableObject {
    @Published private(set) var state: SnakeGameState

    private var engine: SnakeGameEngine
    private var timer: DispatchSourceTimer?

    init(engine: SnakeGameEngine = SnakeGameEngine()) {
        self.engine = engine
        self.state = engine.state
    }

    deinit {
        timer?.cancel()
    }

    func startGameLoop() {
        scheduleNextTick()
    }

    func stopGameLoop() {
        timer?.cancel()
        timer = nil
    }

    func restart() {
        engine.reset()
        state = engine.state
        scheduleNextTick()
    }

    func queue(direction: Direction) {
        guard !state.isGameOver else { return }
        engine.queue(direction: direction)
        state = engine.state
    }

    private func scheduleNextTick() {
        timer?.cancel()

        guard !state.isGameOver else {
            timer = nil
            return
        }

        let interval = state.tickInterval
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + interval)
        timer.setEventHandler { [weak self] in
            self?.handleTick()
        }
        timer.activate()
        self.timer = timer
    }

    private func handleTick() {
        engine.advance()
        state = engine.state
        scheduleNextTick()
    }
}
