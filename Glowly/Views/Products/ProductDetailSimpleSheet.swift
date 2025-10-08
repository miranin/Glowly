//
//  ProductDetailSimpleSheet.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

struct ProductDetailSimpleSheet: View {
    let product: Product
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Product Image Header
                    ZStack {
                        // Background gradient
                        LinearGradient(
                            colors: [Theme.categoryColor(product.category).opacity(0.1), Theme.backgroundPowder],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 250)
                        
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
                                                colors: [Theme.categoryColor(product.category).opacity(0.3), Theme.categoryColor(product.category).opacity(0.1)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 150, height: 150)
                                    
                                    Image(systemName: product.category.icon)
                                        .font(.system(size: 60))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Theme.accent, Theme.accentDark],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                    // Product Title
                    VStack(spacing: 8) {
                        Text(product.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(product.brand)
                            .font(.headline)
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.horizontal)
                    
                    // Info cards
                    HStack(spacing: 12) {
                        infoCard(title: "Категория", value: product.category.rawValue, color: Theme.categoryColor(product.category))
                        if let days = product.daysUntilExpiry {
                            infoCard(
                                title: product.isExpired ? "Статус" : "Осталось", 
                                value: product.isExpired ? "Просрочено" : "\(days) дн.", 
                                color: product.isExpired ? Theme.danger : (product.isExpiringSoon ? Theme.warning : Theme.success)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Benefits
                    if !product.benefits.isEmpty {
                        detailSection(
                            title: "Польза",
                            icon: "sparkles",
                            color: Theme.success
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(product.benefits, id: \.self) { benefit in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.success)
                                            .font(.caption)
                                        Text(benefit)
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    // How to Use
                    if !product.howToUse.isEmpty {
                        detailSection(
                            title: "Как использовать",
                            icon: "hand.raised.fill",
                            color: Theme.info
                        ) {
                            Text(product.howToUse)
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Ingredients
                    if !product.ingredients.isEmpty {
                        detailSection(
                            title: "Состав",
                            icon: "flask.fill",
                            color: Theme.accent
                        ) {
                            Text(product.ingredients)
                                .font(.caption)
                                .foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Warnings
                    if !product.warnings.isEmpty {
                        detailSection(
                            title: "Предупреждения",
                            icon: "exclamationmark.triangle.fill",
                            color: Theme.warning
                        ) {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(product.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundColor(Theme.warning)
                                            .font(.caption)
                                        Text(warning)
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textPrimary)
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if !product.notes.isEmpty {
                        detailSection(
                            title: "Заметки",
                            icon: "note.text",
                            color: Theme.neutral
                        ) {
                            Text(product.notes)
                                .font(.subheadline)
                                .foregroundColor(Theme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    // Tags
                    if product.isSensitiveSafe || product.isAcneSafe {
                        HStack(spacing: 8) {
                            if product.isSensitiveSafe {
                                tagView(title: "Чувствительная кожа", color: Theme.info)
                            }
                            if product.isAcneSafe {
                                tagView(title: "Acne-safe", color: Theme.success)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: { 
                            HapticsService.shared.success()
                            productStore.markProductUsed(product)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Израсходован")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.success, Theme.success.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Theme.success.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: { 
                            HapticsService.shared.warning()
                            productStore.deleteProduct(product)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("Удалить")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.danger, Theme.danger.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Theme.danger.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Theme.backgroundPowder)
            .navigationTitle("О продукте")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") { 
                        dismiss() 
                    }
                    .foregroundColor(Theme.accent)
                }
            }
        }
    }
    
    private func infoCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func detailSection<Content: View>(
        title: String,
        icon: String,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }
            
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Theme.backgroundCard)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    private func tagView(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
            )
            .foregroundColor(color)
    }
}

#Preview {
    ProductDetailSimpleSheet(
        product: Product(
            name: "Тональный крем",
            brand: "L'Oréal",
            category: .foundation,
            purchaseDate: Date(),
            expiryDate: Calendar.current.date(byAdding: .day, value: 20, to: Date()),
            barcode: nil,
            imageData: nil,
            notes: "Пример"
        ),
        productStore: ProductStore()
    )
}


