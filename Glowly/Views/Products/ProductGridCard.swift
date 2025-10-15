//
//  ProductGridCard.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct ProductGridCard: View {
    let product: Product
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticsService.shared.impactLight()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
                onTap()
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(gradient(for: product.category))
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: product.category.icon)
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundColor(.white.opacity(0.95))
                        )
                }
                
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(product.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
    }
    
    
    private func gradient(for category: ProductCategory) -> LinearGradient {
        let colors: [Color]
        switch category {
        case .lipstick: colors = [.pink, .purple]
        case .eyeshadow: colors = [.purple, .blue]
        case .foundation: colors = [.orange, .pink]
        case .moisturizer: colors = [.teal, .blue]
        default: colors = [.pink, .purple]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

#Preview {
    ProductGridCard(
        product: Product(
            name: "Помада",
            brand: "MAC",
            category: .lipstick,
            applicationZone: .lips,
            purchaseDate: Date(),
            barcode: nil,
            imageData: nil,
            notes: ""
        ),
        onTap: {}
    )
    .padding()
}

