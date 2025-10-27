//
//  RootView.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import SwiftUI

struct RootView: View {
    @State private var isPlaying = false

    var body: some View {
        Group {
            if isPlaying {
                GameView {
                    withAnimation(.easeInOut) {
                        isPlaying = false
                    }
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                MainMenuView {
                    withAnimation(.easeInOut) {
                        isPlaying = true
                    }
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isPlaying)
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .preferredColorScheme(.dark)
    }
}
