//
//  SocialProductDetailSheet.swift
//  Glowly
//
//  Created for viewing detailed product information from other users' cosmetic bags
//

import SwiftUI

struct SocialProductDetailSheet: View {
    let product: SocialUserProfile.ProductPreview
    let profile: SocialUserProfile
    @ObservedObject var wishListService: WishListService
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var isInWishList: Bool {
        wishListService.isInWishList(productId: product.id)
    }

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

                        // Owner Info Section
                        ownerInfoSection

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

                        // User Notes Section
                        if !product.notes.isEmpty {
                            userNotesSection
                        }

                        // Tags Section
                        if product.isSensitiveSafe || product.isAcneSafe {
                            tagsSection
                        }

                        // WishList Action
                        wishListActionSection

                        Spacer().frame(height: 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle(languageManager.translate("product_detail_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.translate("product_detail_done")) {
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
            // TODO: When backend is ready, load image from imageUrl
            if let imageUrl = product.imageUrl, !imageUrl.isEmpty {
                // Future: AsyncImage or Kingfisher for remote images
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [product.category.color.opacity(0.2), product.category.color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)

                    Image(systemName: product.category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(product.category.color)
                }
            } else {
                // Placeholder when no image
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [product.category.color.opacity(0.2), product.category.color.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)

                    Image(systemName: product.category.icon)
                        .font(.system(size: 60))
                        .foregroundColor(product.category.color)
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

    // MARK: - Owner Info Section
    private var ownerInfoSection: some View {
        HStack(spacing: 12) {
            // User Avatar Placeholder
            Circle()
                .fill(Theme.accent.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(profile.userName.prefix(1).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Theme.accent)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(languageManager.translate("product_detail_from_bag"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if profile.isPremium {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Theme.accent)
                    }
                }

                Text(profile.userName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }

    // MARK: - Status Cards Section
    private var statusCardsSection: some View {
        HStack(spacing: 12) {
            // Category Card
            statusCard(
                title: product.category.rawValue,
                subtitle: languageManager.translate("product_detail_category"),
                color: product.category.color
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
                Text(languageManager.translate("product_detail_benefits"))
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
                Text(languageManager.translate("product_detail_how_to_use"))
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
                Text(languageManager.translate("product_detail_ingredients"))
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
                Text(languageManager.translate("product_detail_warnings"))
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

    // MARK: - User Notes Section
    private var userNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.accent)
                Text("\(languageManager.translate("product_detail_user_notes")) \(profile.userName)")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }

            Text(product.notes)
                .font(.system(size: 15))
                .italic()
                .foregroundColor(.secondary)
                .lineSpacing(4)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.accent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Theme.accent.opacity(0.2), lineWidth: 1)
                        )
                )
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
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Theme.neutral)
                Text(languageManager.translate("product_detail_properties"))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }

            HStack(spacing: 8) {
                if product.isSensitiveSafe {
                    tagView(
                        title: languageManager.translate("product_detail_sensitive_safe"),
                        icon: "leaf.fill",
                        color: Theme.info
                    )
                }
                if product.isAcneSafe {
                    tagView(
                        title: languageManager.translate("product_detail_acne_safe"),
                        icon: "checkmark.shield.fill",
                        color: Theme.success
                    )
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

    // MARK: - WishList Action Section
    private var wishListActionSection: some View {
        Button {
            HapticsService.shared.impactMedium()

            if isInWishList {
                // Remove from wishlist
                if let item = wishListService.wishListItems.first(where: { $0.productId == product.id }) {
                    wishListService.removeFromWishList(itemId: item.id)
                }
            } else {
                // Add to wishlist
                wishListService.addToWishList(product: product, fromUser: profile)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isInWishList ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))

                Text(isInWishList ?
                     languageManager.translate("product_detail_remove_from_wishlist") :
                     languageManager.translate("product_detail_add_to_wishlist"))
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isInWishList ? Theme.danger : Theme.accent)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Views
    private func statusCard(title: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .multilineTextAlignment(.center)
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

    private func tagView(title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(title)
                .font(.system(size: 12, weight: .medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
        )
        .foregroundColor(color)
    }
}

#Preview {
    SocialProductDetailSheet(
        product: SocialUserProfile.mockProfile.cosmeticBagPreview[0],
        profile: SocialUserProfile.mockProfile,
        wishListService: WishListService()
    )
    .environmentObject(LanguageManager())
}
