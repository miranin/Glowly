//
//  OnboardingWelcomeView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo/Icon
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("Добро пожаловать в Glowly")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Твой персональный AI-помощник для ухода за кожей и макияжа")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 20) {
                FeatureRow(icon: "person.fill", title: "Персонализация", description: "Настройте под свой тип кожи")
                FeatureRow(icon: "brain.head.profile", title: "AI-советы", description: "Получайте умные рекомендации")
                FeatureRow(icon: "bag.fill", title: "Организация", description: "Управляйте своей косметичкой")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Начать")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentGradient)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.accent)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Theme.accent.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}

