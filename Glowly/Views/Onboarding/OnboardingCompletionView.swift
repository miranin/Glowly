//
//  OnboardingCompletionView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingCompletionView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("Готово!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Ваш профиль настроен.\nТеперь AI-помощник сможет давать вам персональные рекомендации.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 16) {
                FeatureCompletionRow(icon: "sparkles", title: "Персональные советы готовы")
                FeatureCompletionRow(icon: "bag.fill", title: "Можно добавлять продукты")
                FeatureCompletionRow(icon: "chart.line.uptrend.xyaxis", title: "Отслеживайте прогресс")
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: onComplete) {
                Text("Начать использовать Glowly")
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

struct FeatureCompletionRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.success)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.success)
        }
    }
}

#Preview {
    OnboardingCompletionView(onComplete: {})
}

