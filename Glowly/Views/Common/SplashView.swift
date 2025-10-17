//
//  SplashView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 16/10/25.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.93),
                    Color(red: 0.95, green: 0.92, blue: 0.90)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // App Icon/Logo
                Image(systemName: "sparkles")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.55),
                                Color(red: 0.75, green: 0.55, blue: 0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(
                        .spring(response: 0.8, dampingFraction: 0.6)
                        .delay(0.1),
                        value: scale
                    )

                // App Name
                Text("Glowly")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.3, green: 0.25, blue: 0.2),
                                Color(red: 0.5, green: 0.4, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .delay(0.3),
                        value: opacity
                    )

                // Tagline
                Text("Your beauty journey starts here")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.35).opacity(0.7))
                    .opacity(opacity)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .delay(0.5),
                        value: opacity
                    )
            }

            // Animated sparkles around the logo
            ForEach(0..<6, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.65, blue: 0.55).opacity(0.6),
                                Color(red: 0.75, green: 0.55, blue: 0.45).opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 8, height: 8)
                    .offset(
                        x: cos(Double(index) * .pi / 3) * (isAnimating ? 100 : 60),
                        y: sin(Double(index) * .pi / 3) * (isAnimating ? 100 : 60)
                    )
                    .opacity(isAnimating ? 0 : 0.8)
                    .animation(
                        .easeOut(duration: 1.2)
                        .repeatForever(autoreverses: false)
                        .delay(0.6 + Double(index) * 0.1),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            // Trigger animations
            opacity = 1.0
            scale = 1.0

            // Start sparkle animation after main elements appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
