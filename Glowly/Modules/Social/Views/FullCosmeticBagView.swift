//
//  FullCosmeticBagView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct FullCosmeticBagView: View {
    let profile: SocialUserProfile
    @StateObject var wishListService: WishListService
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: SocialUserProfile.CosmeticCategory?
    
    init(profile: SocialUserProfile, wishListService: WishListService = WishListService()) {
        self.profile = profile
        _wishListService = StateObject(wrappedValue: wishListService)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Categories Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(SocialUserProfile.CosmeticCategory.allCases, id: \.self) { category in
                            CategoryCard(
                                category: category,
                                productCount: productsCount(for: category),
                                action: {
                                    selectedCategory = category
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Косметичка \(profile.userName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(item: $selectedCategory) { category in
                CategoryProductsView(
                    category: category,
                    products: products(for: category),
                    profile: profile,
                    wishListService: wishListService
                )
            }
        }
    }
    
    private func productsCount(for category: SocialUserProfile.CosmeticCategory) -> Int {
        profile.cosmeticBagPreview.filter { $0.category == category }.count
    }
    
    private func products(for category: SocialUserProfile.CosmeticCategory) -> [SocialUserProfile.ProductPreview] {
        profile.cosmeticBagPreview.filter { $0.category == category }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: SocialUserProfile.CosmeticCategory
    let productCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [category.color.opacity(0.2), category.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 36))
                        .foregroundColor(category.color)
                }
                
                // Title & Count
                VStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text("\(productCount) продуктов")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(category.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FullCosmeticBagView(profile: SocialUserProfile.mockProfile)
}


