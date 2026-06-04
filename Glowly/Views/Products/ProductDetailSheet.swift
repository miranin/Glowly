//
//  ProductDetailSheet.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//  Redesigned on 10/10/25.
//

import SwiftUI

struct ProductDetailSheet: View {
    let product: Product
    let onClose: () -> Void
    let onDelete: () -> Void
    let onMarkUsed: (() -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Product Image Section
                        productImageSection
                        
                        // Product Info Section
                        productInfoSection
                        
                        // Status Cards
                        statusCardsSection

                        // AI Description
                        if !product.productDescription.isEmpty {
                            descriptionSection
                        }

                        // Usage time + skin types + concerns
                        metaChipsSection

                        // Key Ingredients (with roles)
                        if !product.keyIngredients.isEmpty {
                            keyIngredientsSection
                        }

                        // Benefits Section
                        if !product.benefits.isEmpty {
                            benefitsSection
                        }

                        // How to Use Section
                        if !product.howToUse.isEmpty {
                            howToUseSection
                        }

                        // Ingredients Section
                        if !product.ingredients.isEmpty {
                            ingredientsSection
                        }
                        
                        // Warnings Section
                        if !product.warnings.isEmpty {
                            warningsSection
                        }
                        
                        // Notes Section
                        if !product.notes.isEmpty {
                            notesSection
                        }
                        
                        // Actions Section
                        actionsSection
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("О продукте")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onClose) {
                        Text("Готово")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.accent)
                    }
                }
            }
        }
    }
    
    // MARK: - Product Image Section
    private var productImageSection: some View {
        VStack(spacing: 16) {
            if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, maxHeight: 200)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
            } else {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.categoryColor(product.category).opacity(0.2), Theme.categoryColor(product.category).opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)
                    
                    Image(systemName: product.category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(Theme.categoryColor(product.category))
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Product Info Section
    private var productInfoSection: some View {
        VStack(spacing: 8) {
            Text(product.name)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text(product.brand)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Theme.accent)
        }
    }
    
    // MARK: - Status Cards Section
    private var statusCardsSection: some View {
        HStack(spacing: 12) {
            // Category Card
            statusCard(
                title: product.category.rawValue,
                subtitle: "Категория",
                color: Theme.categoryColor(product.category)
            )
            
            // Application Zone Card
            statusCard(
                title: product.applicationZone.rawValue,
                subtitle: "Зона применения",
                color: Theme.accent
            )
        }
    }
    
    // MARK: - AI Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)
                Text("Описание")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Text(product.productDescription)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Meta Chips (usage time, skin types, concerns)
    @ViewBuilder
    private var metaChipsSection: some View {
        let hasContent = !product.skinTypes.isEmpty || !product.concerns.isEmpty
        if hasContent {
            VStack(alignment: .leading, spacing: 16) {
                // Usage time badge
                HStack(spacing: 8) {
                    Image(systemName: usageIcon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Theme.accent)
                    Text(usageLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                }

                if !product.skinTypes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        chipGroupTitle("Подходит для", icon: "person.fill", color: Theme.info)
                        TagFlow(items: product.skinTypes.map { skinTypeLabel($0) }, tint: Theme.info)
                    }
                }

                if !product.concerns.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        chipGroupTitle("Решает проблемы", icon: "target", color: Theme.success)
                        TagFlow(items: product.concerns.map { concernLabel($0) }, tint: Theme.success)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
        }
    }

    private func chipGroupTitle(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }

    // MARK: - Key Ingredients Section (with roles)
    private var keyIngredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.success)
                Text("Активные ингредиенты")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 14) {
                ForEach(product.keyIngredients, id: \.self) { ing in
                    let parts = ing.components(separatedBy: " — ")
                    let name = parts.first ?? ing
                    let role = parts.count > 1 ? parts.dropFirst().joined(separator: " — ") : ""
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Theme.success.opacity(0.5))
                            .frame(width: 7, height: 7)
                            .padding(.top, 6)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(name)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            if !role.isEmpty {
                                Text(role)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Label helpers

    private var usageLabel: String {
        switch product.usageTime.lowercased() {
        case "morning": return "Использовать утром"
        case "night": return "Использовать вечером"
        default: return "Утром и вечером"
        }
    }

    private var usageIcon: String {
        switch product.usageTime.lowercased() {
        case "morning": return "sun.max.fill"
        case "night": return "moon.fill"
        default: return "sun.and.horizon.fill"
        }
    }

    private func skinTypeLabel(_ key: String) -> String {
        switch key.lowercased() {
        case "oily": return "Жирная"
        case "dry": return "Сухая"
        case "combination": return "Комбинированная"
        case "sensitive": return "Чувствительная"
        case "normal": return "Нормальная"
        case "all": return "Все типы"
        case "acne_prone", "acne": return "Склонная к акне"
        case "mature": return "Зрелая"
        default: return key.capitalized
        }
    }

    private func concernLabel(_ key: String) -> String {
        switch key.lowercased() {
        case "acne": return "Акне"
        case "aging": return "Старение"
        case "dryness": return "Сухость"
        case "hyperpigmentation": return "Пигментация"
        case "pores": return "Поры"
        case "redness": return "Покраснения"
        case "sensitivity": return "Чувствительность"
        case "brightening": return "Сияние"
        case "firmness": return "Упругость"
        case "dark_circles": return "Тёмные круги"
        default: return key.capitalized
        }
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.success)
                Text("Польза")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(product.benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.success)
                            .font(.system(size: 16))
                        Text(benefit)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - How to Use Section
    private var howToUseSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.info)
                Text("Как использовать")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(product.howToUse)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Ingredients Section
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "flask.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)
                Text("Состав")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(product.ingredients)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Warnings Section
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.warning)
                Text("Предупреждения")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(product.warnings, id: \.self) { warning in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(Theme.warning)
                            .font(.system(size: 16))
                        Text(warning)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.neutral)
                Text("Заметки")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text(product.notes)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if let onMarkUsed = onMarkUsed {
                Button(action: onMarkUsed) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                        Text("Израсходован")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.success)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: onDelete) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .medium))
                    Text("Удалить")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.danger)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Views
    private func statusCard(title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Tag Flow (wraps chips onto multiple lines)

private struct TagFlow: View {
    let items: [String]
    let tint: Color

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }
}
