//
//  UserProfileView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct UserProfileView: View {
    let userId: String
    @ObservedObject var userProfileService: UserProfileService
    @ObservedObject var wishListService: WishListService
    @Environment(\.dismiss) var dismiss
    
    var userProfile: SocialUserProfile? {
        userProfileService.getUserProfile(userId: userId)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                if let profile = userProfile {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            // Avatar
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: profile.userType == .store ? "bag.fill" : "person.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gray)
                                )
                            
                            // Name & Bio
                            VStack(spacing: 8) {
                                HStack(spacing: 6) {
                                    Text(profile.userName)
                                        .font(.system(size: 20, weight: .bold))
                                    
                                    if profile.isPremium {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                
                                if let bio = profile.bio {
                                    Text(bio)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                            
                            // Stats
                            HStack(spacing: 40) {
                                StatItem(title: "Посты", value: "\(profile.postsCount)")
                                StatItem(title: "Подписчики", value: "\(profile.followersCount)")
                                StatItem(title: "Подписки", value: "\(profile.followingCount)")
                            }
                            .padding(.top, 8)
                            
                            // Follow Button
                            Button {
                                userProfileService.toggleFollow(userId: userId)
                            } label: {
                                Text(profile.isFollowing ? "Отписаться" : "Подписаться")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(profile.isFollowing ? .primary : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(profile.isFollowing ? Color.clear : Theme.accent)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(profile.isFollowing ? Color.gray.opacity(0.3) : Color.clear, lineWidth: 1)
                                    )
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.top, 24)
                        
                        Divider()
                        
                        // Совпадения по персонализации
                        VStack(alignment: .leading, spacing: 12) {
                            Text("У вас общее")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    MatchTag(text: "Комбинированная кожа", icon: "drop.fill")
                                    MatchTag(text: "Анти-акне", icon: "sparkles")
                                    MatchTag(text: "SPF защита", icon: "sun.max.fill")
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 8)
                        
                        Divider()
                        
                        // Cosmetic Bag - 4 Categories
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Косметичка")
                                .font(.system(size: 18, weight: .bold))
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(SocialUserProfile.CosmeticCategory.allCases, id: \.self) { category in
                                    NavigationLink {
                                        CategoryProductsView(
                                            category: category,
                                            products: products(for: category, from: profile),
                                            profile: profile,
                                            wishListService: wishListService
                                        )
                                    } label: {
                                        CategoryPreviewCard(
                                            category: category,
                                            productCount: productsCount(for: category, from: profile)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                } else {
                    ProgressView()
                        .padding(.top, 100)
                }
            }
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
            .onAppear {
                if userProfile == nil {
                    userProfileService.loadUserProfile(userId: userId)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func productsCount(for category: SocialUserProfile.CosmeticCategory, from profile: SocialUserProfile) -> Int {
        profile.cosmeticBagPreview.filter { $0.category == category }.count
    }
    
    private func products(for category: SocialUserProfile.CosmeticCategory, from profile: SocialUserProfile) -> [SocialUserProfile.ProductPreview] {
        profile.cosmeticBagPreview.filter { $0.category == category }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
            Text(title)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Match Tag
struct MatchTag: View {
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(Theme.accent)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Theme.accent.opacity(0.1))
        )
    }
}

// MARK: - Category Preview Card
struct CategoryPreviewCard: View {
    let category: SocialUserProfile.CosmeticCategory
    let productCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
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
                    .frame(width: 60, height: 60)
                
                Image(systemName: category.icon)
                    .font(.system(size: 28))
                    .foregroundColor(category.color)
            }
            
            // Title & Count
            VStack(spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("\(productCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(category.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Product Preview Card
struct ProductPreviewCard: View {
    let product: SocialUserProfile.ProductPreview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(height: 120)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
                
                Text(product.brand)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    UserProfileView(userId: "user1", userProfileService: UserProfileService(), wishListService: WishListService())
}

