//
//  CategoryProductsView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct CategoryProductsView: View {
    let category: SocialUserProfile.CosmeticCategory
    let products: [SocialUserProfile.ProductPreview]
    let profile: SocialUserProfile
    @ObservedObject var wishListService: WishListService
    @State private var searchText = ""
    @State private var selectedProduct: SocialUserProfile.ProductPreview?

    var filteredProducts: [SocialUserProfile.ProductPreview] {
        if searchText.isEmpty {
            return products
        }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.brand.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Поиск в \(category.rawValue)...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            // Products List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredProducts) { product in
                        ProductRow(
                            product: product,
                            profile: profile,
                            wishListService: wishListService,
                            onTap: {
                                selectedProduct = product
                            }
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle(category.rawValue)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedProduct) { product in
            SocialProductDetailSheet(
                product: product,
                profile: profile,
                wishListService: wishListService
            )
        }
    }
}

// MARK: - Product Row
struct ProductRow: View {
    let product: SocialUserProfile.ProductPreview
    let profile: SocialUserProfile
    @ObservedObject var wishListService: WishListService
    let onTap: () -> Void

    var isInWishList: Bool {
        wishListService.isInWishList(productId: product.id)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Product Image
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: product.category.icon)
                            .font(.system(size: 24))
                            .foregroundColor(product.category.color)
                    )

                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(product.brand)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    Text(product.category.rawValue)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(product.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(product.category.color.opacity(0.1))
                        )
                }

                Spacer()

                // WishList Button & Arrow
                HStack(spacing: 8) {
                    // WishList Button
                    Button {
                        HapticsService.shared.impactLight()
                        if isInWishList {
                            // Найти и удалить из wishlist
                            if let item = wishListService.wishListItems.first(where: { $0.productId == product.id }) {
                                wishListService.removeFromWishList(itemId: item.id)
                            }
                        } else {
                            wishListService.addToWishList(product: product, fromUser: profile)
                        }
                    } label: {
                        Image(systemName: isInWishList ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isInWishList ? .red : .gray)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Chevron to indicate tappable
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(product.category.color.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Category Identifiable Extension
extension SocialUserProfile.CosmeticCategory: Identifiable {
    var id: String { rawValue }
}

#Preview {
    CategoryProductsView(
        category: .makeup,
        products: SocialUserProfile.mockProfile.cosmeticBagPreview.filter { $0.category == .makeup },
        profile: SocialUserProfile.mockProfile,
        wishListService: WishListService()
    )
}

