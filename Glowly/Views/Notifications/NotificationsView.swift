//
//  NotificationsView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var productStore: ProductStore
    @State private var showingSettings = false
    
    var expiringProducts: [Product] {
        productStore.getExpiringProducts()
    }
    
    var expiredProducts: [Product] {
        productStore.getExpiredProducts()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.pink)
                        
                        Text("Уведомления")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Следи за сроками годности")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Expiring Soon Section
                    if !expiringProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Скоро истекает")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(expiringProducts.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .cornerRadius(10)
                            }
                            
                            ForEach(expiringProducts) { product in
                                ExpiryCard(product: product, isExpired: false)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.orange.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Expired Section
                    if !expiredProducts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                Text("Просрочено")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(expiredProducts.count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                            
                            ForEach(expiredProducts) { product in
                                ExpiryCard(product: product, isExpired: true)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // All Good Section
                    if expiringProducts.isEmpty && expiredProducts.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                            
                            Text("Все отлично!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("У вас нет продуктов с истекающим сроком годности")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.1))
                        )
                    }
                    
                    // Settings Section
                    VStack(spacing: 12) {
                        SettingsRow(
                            icon: "bell.fill",
                            title: "Утренние напоминания",
                            subtitle: "8:00 каждый день"
                        )
                        
                        SettingsRow(
                            icon: "moon.fill",
                            title: "Вечерние напоминания",
                            subtitle: "22:00 каждый день"
                        )
                        
                        SettingsRow(
                            icon: "calendar.badge.exclamationmark",
                            title: "Напоминания о сроке годности",
                            subtitle: "За 30, 14, 7, 3, 1 день"
                        )
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

struct ExpiryCard: View {
    let product: Product
    let isExpired: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: product.category.icon)
                .font(.title3)
                .foregroundColor(isExpired ? .red : .orange)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill((isExpired ? Color.red : Color.orange).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(product.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let days = product.daysUntilExpiry {
                    if isExpired {
                        Text("Просрочено")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else {
                        Text("\(days) дн.")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
                
                if let expiryDate = product.expiryDate {
                    Text(formatDate(expiryDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.pink)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark")
                .font(.caption)
                .foregroundColor(.green)
        }
    }
}

#Preview {
    NotificationsView(productStore: ProductStore())
}
