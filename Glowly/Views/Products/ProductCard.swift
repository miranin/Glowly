//
//  ProductCard.swift
//  Glowly
//

import SwiftUI

struct ProductCard: View {
    let product: Product
    let productStore: ProductStore
    @State private var showingDeleteAlert = false

    var body: some View {
        HStack(spacing: 14) {
            // Image / icon
            productThumbnail

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(product.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(product.brand)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    categoryBadge

                    if product.isSensitiveSafe {
                        tagBadge("Sensitive", color: .green)
                    }
                    if !product.isAcneSafe {
                        tagBadge("Comedogenic", color: .orange)
                    }
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            // Menu
            Menu {
                Button("Редактировать", systemImage: "pencil", action: {})
                Divider()
                Button("Удалить", systemImage: "trash", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(.tertiaryLabel))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.systemGray5), lineWidth: 1)
        )
        .alert("Удалить продукт?", isPresented: $showingDeleteAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить", role: .destructive) {
                productStore.deleteProduct(product)
            }
        } message: {
            Text("\(product.name) будет удалён из вашего косметического набора.")
        }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var productThumbnail: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(categoryTint.opacity(0.1))
                .frame(width: 54, height: 54)

            if let imageData = product.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: product.category.icon)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(categoryTint)
            }
        }
    }

    // MARK: - Badges

    private var categoryBadge: some View {
        Text(product.category.rawValue)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(categoryTint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(categoryTint.opacity(0.1))
            .clipShape(Capsule())
    }

    private func tagBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
    }

    private var categoryTint: Color {
        Theme.categoryColor(product.category)
    }
}

#Preview {
    VStack(spacing: 10) {
        ProductCard(
            product: Product(
                name: "Dermaclear Cleansing Foam",
                brand: "Dr.Jart+",
                category: .cleanser,
                applicationZone: .face,
                purchaseDate: Date(),
                barcode: nil,
                imageData: nil,
                notes: "",
                isSensitiveSafe: true,
                isAcneSafe: true
            ),
            productStore: ProductStore()
        )
        ProductCard(
            product: Product(
                name: "Moisturizing Cream",
                brand: "CeraVe",
                category: .moisturizer,
                applicationZone: .face,
                purchaseDate: Date(),
                barcode: nil,
                imageData: nil,
                notes: ""
            ),
            productStore: ProductStore()
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
