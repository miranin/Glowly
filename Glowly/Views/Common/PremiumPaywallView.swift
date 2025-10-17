//
//  PremiumPaywallView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 16/10/25.
//

import SwiftUI

struct PremiumPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @State private var selectedPlan: SubscriptionPlan = .monthly
    let onPurchase: (SubscriptionPlan) -> Void

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.93),
                    Color(red: 0.95, green: 0.90, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.secondary.opacity(0.6))
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 8)

                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.85, green: 0.65, blue: 0.20),
                                        Color(red: 0.75, green: 0.55, blue: 0.10)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(red: 0.85, green: 0.65, blue: 0.20).opacity(0.3), radius: 10)

                        Text(languageManager.translate("premium_title"))
                            .font(.system(size: 32, weight: .bold))
                            .multilineTextAlignment(.center)

                        Text(languageManager.translate("premium_subtitle"))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Features - Creator Economy Model
                    VStack(alignment: .leading, spacing: 20) {
                        PremiumFeatureRow(
                            icon: "photo.on.rectangle.angled",
                            title: languageManager.translate("premium_feature_viral_posts_title"),
                            description: languageManager.translate("premium_feature_viral_posts_desc")
                        )

                        PremiumFeatureRow(
                            icon: "sparkles.rectangle.stack.fill",
                            title: languageManager.translate("premium_feature_ai_helper_title"),
                            description: languageManager.translate("premium_feature_ai_helper_desc")
                        )

                        PremiumFeatureRow(
                            icon: "dollarsign.circle.fill",
                            title: languageManager.translate("premium_feature_monetize_title"),
                            description: languageManager.translate("premium_feature_monetize_desc")
                        )

                        PremiumFeatureRow(
                            icon: "link.circle.fill",
                            title: languageManager.translate("premium_feature_deeplinks_title"),
                            description: languageManager.translate("premium_feature_deeplinks_desc")
                        )
                    }
                    .padding(.horizontal, 24)

                    // Subscription Plans
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.system(size: 20, weight: .semibold))
                            .padding(.top, 8)

                        SubscriptionPlanCard(
                            plan: .annual,
                            isSelected: selectedPlan == .annual,
                            onTap: { selectedPlan = .annual },
                            languageManager: languageManager
                        )

                        SubscriptionPlanCard(
                            plan: .monthly,
                            isSelected: selectedPlan == .monthly,
                            onTap: { selectedPlan = .monthly },
                            languageManager: languageManager
                        )
                    }
                    .padding(.horizontal, 24)

                    // Continue button
                    Button {
                        onPurchase(selectedPlan)
                        dismiss()
                    } label: {
                        Text(languageManager.translate("premium_continue"))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accentDark],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 24)

                    // Fine print
                    Text(languageManager.translate("premium_terms"))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: - Premium Feature Row
struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accentDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Theme.accent.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Subscription Plans
enum SubscriptionPlan {
    case monthly
    case annual

    func title(languageManager: LanguageManager) -> String {
        switch self {
        case .monthly: return languageManager.translate("premium_plan_monthly")
        case .annual: return languageManager.translate("premium_plan_annual")
        }
    }

    var price: String {
        switch self {
        case .monthly: return "$4.99"
        case .annual: return "$39.99"
        }
    }

    func billing(languageManager: LanguageManager) -> String {
        switch self {
        case .monthly: return languageManager.translate("premium_per_month")
        case .annual: return languageManager.translate("premium_per_year")
        }
    }

    func savings(languageManager: LanguageManager) -> String? {
        switch self {
        case .monthly: return nil
        case .annual: return languageManager.translate("premium_save_percent")
        }
    }

    var mostPopular: Bool {
        switch self {
        case .annual: return true
        default: return false
        }
    }
}

// MARK: - Plan Card
struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void
    let languageManager: LanguageManager

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(plan.title(languageManager: languageManager))
                                .font(.system(size: 18, weight: .semibold))

                            if plan.mostPopular {
                                Text(languageManager.translate("premium_most_popular"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(
                                                LinearGradient(
                                                    colors: [Theme.accent, Theme.accentDark],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                            }
                        }

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(plan.price)
                                .font(.system(size: 24, weight: .bold))
                            Text(plan.billing(languageManager: languageManager))
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }

                        if let savings = plan.savings(languageManager: languageManager) {
                            Text(savings)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Theme.accent)
                        }
                    }

                    Spacer()

                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? Theme.accent : .secondary.opacity(0.3))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Theme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PremiumPaywallView(onPurchase: { _ in })
}
