//
//  OnboardingCompletionView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingCompletionView: View {
    let userProfile: UserProfile
    let onComplete: () -> Void

    @State private var showSuccess = false
    @State private var showRecommendations = false
    @State private var recommendations: [ProductRecommendation] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Success Animation
                ZStack {
                    Circle()
                        .fill(Theme.accentGradient)
                        .frame(width: 120, height: 120)
                        .scaleEffect(showSuccess ? 1.0 : 0.5)
                        .opacity(showSuccess ? 1.0 : 0.0)

                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(showSuccess ? 1.0 : 0.5)
                        .opacity(showSuccess ? 1.0 : 0.0)
                }
                .padding(.top, 60)

                VStack(spacing: 16) {
                    Text("Готово!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(showSuccess ? 1.0 : 0.0)

                    Text("Ваш профиль настроен.\nТеперь AI-помощник сможет давать вам персональные рекомендации.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .opacity(showSuccess ? 1.0 : 0.0)
                }

                VStack(spacing: 16) {
                    FeatureCompletionRow(icon: "sparkles", title: "Персональные советы готовы")
                    FeatureCompletionRow(icon: "bag.fill", title: "Можно добавлять продукты")
                    FeatureCompletionRow(icon: "chart.line.uptrend.xyaxis", title: "Отслеживайте прогресс")
                }
                .padding(.horizontal, 40)
                .opacity(showSuccess ? 1.0 : 0.0)

                // Product Recommendations Section
                if showRecommendations && !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Рекомендуем для вас")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 40)

                        Text("На основе вашего профиля мы подобрали эти продукты")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recommendations) { recommendation in
                                    RecommendedProductCard(recommendation: recommendation)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Button(action: {
                    HapticManager.shared.mediumImpact()
                    onComplete()
                }) {
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
                .opacity(showSuccess ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showSuccess = true
            }

            // Generate recommendations
            recommendations = ProductRecommendationEngine.shared.generateRecommendations(for: userProfile)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.0)) {
                showRecommendations = true
            }
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

// MARK: - Recommended Product Card

struct RecommendedProductCard: View {
    let recommendation: ProductRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.2), Theme.accent.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 140)

                if let imageAsset = recommendation.imageAsset {
                    Image(imageAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.accent)
                }
            }

            // Product Info
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.category)
                    .font(.caption)
                    .foregroundColor(Theme.accent)
                    .textCase(.uppercase)

                Text(recommendation.productName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)

                Text(recommendation.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Reason Badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.success)

                    Text(recommendation.reason)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                .padding(.top, 4)
            }
            .frame(width: 200, alignment: .leading)
        }
        .frame(width: 200)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

#Preview {
    OnboardingCompletionView(
        userProfile: UserProfile(),
        onComplete: {}
    )
}

