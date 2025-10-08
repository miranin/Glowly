//
//  CircularProductSelector.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct CircularProductSelector: View {
    let product: Product
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundGradient)
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Product image or icon
                if let asset = product.category.assetName, let uiImage = UIImage(named: asset) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Image(systemName: product.category.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Expiry indicator
                if product.isExpired || product.isExpiringSoon {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(expiryColor)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("!")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onTapGesture {
                HapticsService.shared.impactLight()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
            .onLongPressGesture {
                HapticsService.shared.impactMedium()
                showingDeleteAlert = true
            }
            
            // Product name
            Text(product.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 80)
            
            // Brand
            Text(product.brand)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 80)
        }
        .alert("Удалить продукт", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) { }
            Button("Удалить", role: .destructive) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    onDelete()
                }
            }
        } message: {
            Text("Вы уверены, что хотите удалить \(product.name)?")
        }
    }
    
    private var backgroundGradient: LinearGradient {
        let colors: [Color]
        switch product.category {
        case .lipstick: colors = [.pink, .purple]
        case .eyeshadow: colors = [.purple, .blue]
        case .foundation: colors = [.orange, .pink]
        case .moisturizer: colors = [.teal, .blue]
        case .mascara: colors = [.black, .gray]
        case .blush: colors = [.pink, .red]
        case .bronzer: colors = [.brown, .orange]
        case .highlighter: colors = [.yellow, .white]
        default: colors = [.pink, .purple]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private var expiryColor: Color {
        if product.isExpired { return .red }
        if product.isExpiringSoon { return .orange }
        return .green
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
        CircularProductSelector(
            product: Product(
                name: "Помада Ruby Woo",
                brand: "MAC",
                category: .lipstick,
                purchaseDate: Date(),
                expiryDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()),
                barcode: nil,
                imageData: nil,
                notes: "Классический красный"
            ),
            onTap: {},
            onDelete: {}
        )
        
        CircularProductSelector(
            product: Product(
                name: "Тональный крем",
                brand: "L'Oréal",
                category: .foundation,
                purchaseDate: Date(),
                expiryDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()),
                barcode: nil,
                imageData: nil,
                notes: "Любимый оттенок"
            ),
            onTap: {},
            onDelete: {}
        )
    }
    .padding()
}
