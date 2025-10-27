//
//  MainMenuView.swift
//  UpdatedSnakeGame
//
//  Created by Codex on 2024-05-24.
//

import SwiftUI

struct MainMenuView: View {
    var onStart: () -> Void

    private let gradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#060913") ?? .black, Color(hex: "#0d1324") ?? .black]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            gradient.ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 8) {
                    Text("Chromatic Current")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    Text("Ride the elemental wave and keep your harmony flowing.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#8f9bb5") ?? .gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                Button(action: onStart) {
                    Text("Start Run")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color(hex: "#05070f") ?? .black)
                        .padding(.horizontal, 48)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color(hex: "#61dbff") ?? .cyan)
                        )
                        .shadow(color: (Color(hex: "#61dbff") ?? .cyan).opacity(0.4), radius: 10, y: 8)
                }

                VStack(spacing: 6) {
                    Text("Elemental Effects")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(FoodType.allCases, id: \.self) { foodType in
                            let metadata = foodType.metadata
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(hex: metadata.colorHex) ?? .white)
                                    .frame(width: 20, height: 20)
                                VStack(alignment: .leading, spacing: 2) {
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
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "#0d1324") ?? .black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(hex: "#1f2a4c") ?? .gray, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .padding(.top, 80)
            .padding(.bottom, 40)
        }
    }
}

struct MainMenuView_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuView(onStart: {})
            .preferredColorScheme(.dark)
    }
}
