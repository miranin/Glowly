//
//  ProductCard.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct ProductCard: View {
    let product: Product
    let productStore: ProductStore
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 14) {
            // Product Icon with gradient and proper aspect ratio
            ZStack {
                Circle()
                    .fill(Theme.backgroundCard)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Theme.categoryColor(product.category).opacity(0.2), lineWidth: 2)
                    )
                
                if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit) // Changed to .fit to show full product
                        .frame(width: 52, height: 52) // Slightly smaller to add padding
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.categoryColor(product.category).opacity(0.8), Theme.categoryColor(product.category).opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .overlay(
                            Image(systemName: product.category.icon)
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                }
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 6) {
                Text(product.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)
                
                Text(product.brand)
                    .font(.system(size: 14))
                    .foregroundColor(Theme.textSecondary)
                
                HStack(spacing: 6) {
                    Text(product.category.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.categoryColor(product.category))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Theme.categoryColor(product.category).opacity(0.15))
                        )
                    
                    if product.isExpired {
                        Text("Просрочено")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Theme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Theme.danger.opacity(0.15))
                            )
                    } else if product.isExpiringSoon {
                        if let days = product.daysUntilExpiry {
                            Text("\(days) дн.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Theme.warning)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Theme.warning.opacity(0.15))
                                )
                        }
                    }
                }
            }
            
            Spacer()
            
            // Expiry date badge
            VStack(spacing: 4) {
                if let expiryDate = product.expiryDate {
                    VStack(spacing: 2) {
                        Text(formatDateShort(expiryDate))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(product.isExpired ? Theme.danger : product.isExpiringSoon ? Theme.warning : Theme.success)
                        
                        if let days = product.daysUntilExpiry, !product.isExpired {
                            Text("\(days) дн.")
                                .font(.system(size: 10))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }
                }
                
                Menu {
                    Button("Редактировать", action: {})
                    Button("Удалить", role: .destructive) {
                        showingDeleteAlert = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Theme.neutral.opacity(0.6))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Theme.backgroundCard)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: product.isExpired ? 
                            [Theme.danger.opacity(0.5), Theme.danger.opacity(0.3)] :
                        product.isExpiringSoon ? 
                            [Theme.warning.opacity(0.4), Theme.warning.opacity(0.2)] :
                            [Theme.categoryColor(product.category).opacity(0.3), Theme.categoryColor(product.category).opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .shadow(
                    color: product.isExpired ? Theme.danger.opacity(0.2) :
                    product.isExpiringSoon ? Theme.warning.opacity(0.15) :
                    Theme.categoryColor(product.category).opacity(0.1),
                    radius: 6,
                    x: 0,
                    y: 2
                )
        )
        .alert("Удалить продукт", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                productStore.deleteProduct(product)
            }
        } message: {
            Text("Вы уверены, что хотите удалить \(product.name)?")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 12) {
        ProductCard(
            product: Product(
                name: "Тональный крем",
                brand: "L'Oréal",
                category: .foundation,
                purchaseDate: Date(),
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                barcode: nil,
                imageData: nil,
                notes: "Любимый оттенок"
            ),
            productStore: ProductStore()
        )
        
        ProductCard(
            product: Product(
                name: "Помада",
                brand: "MAC",
                category: .lipstick,
                purchaseDate: Date(),
                expiryDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                barcode: nil,
                imageData: nil,
                notes: "Классический красный"
            ),
            productStore: ProductStore()
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
