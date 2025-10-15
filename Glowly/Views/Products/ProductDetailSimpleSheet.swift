//
//  ProductDetailSimpleSheet.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//  Redesigned on 10/10/25.
//

import SwiftUI

struct ProductDetailSimpleSheet: View {
    let product: Product
    @ObservedObject var productStore: ProductStore
    @Environment(\.dismiss) private var dismiss

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
                        
                        // Tags Section
                        if product.isSensitiveSafe || product.isAcneSafe {
                            tagsSection
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
                    Button("Готово") { 
                        dismiss() 
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)
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
    
    // MARK: - Tags Section
    private var tagsSection: some View {
        HStack(spacing: 8) {
            if product.isSensitiveSafe {
                tagView(title: "Чувствительная кожа", color: Theme.info)
            }
            if product.isAcneSafe {
                tagView(title: "Acne-safe", color: Theme.success)
            }
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: { 
                HapticsService.shared.success()
                productStore.markProductUsed(product)
                dismiss()
            }) {
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
            
            Button(action: { 
                HapticsService.shared.warning()
                productStore.deleteProduct(product)
                dismiss()
            }) {
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
    
    private func tagView(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .medium))
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
            applicationZone: .face,
            purchaseDate: Date(),
            barcode: nil,
            imageData: nil,
            notes: "Пример"
        ),
        productStore: ProductStore()
    )
}


