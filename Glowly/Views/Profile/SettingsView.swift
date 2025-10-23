//
//  SettingsView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI
import PDFKit

struct SettingsView: View {
    @ObservedObject var productStore: ProductStore
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @ObservedObject var authManager: AuthManager
    let biometricService: BiometricAuthServiceProtocol
    @ObservedObject var wishListService: WishListService
    @EnvironmentObject var languageManager: LanguageManager
    @State private var showingImagePicker = false
    @State private var showingPhotoActionSheet = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showingLogoutAlert = false
    @State private var showingWishListSheet = false
    @State private var showingResetPersonalizationAlert = false
    @State private var showingDeleteAccountAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color(.systemGray6).opacity(0.3), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        
                        VStack(spacing: 16) {
                            wishListSection
                            accountManagementSection
                            languageSection
                            aboutSection
                        }
                        .padding(.horizontal, 20)

                        logoutButton
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 100) // Safe area для Tab Bar
                }
            }
                    .navigationTitle(languageManager.translate("profile_title"))
            .navigationBarTitleDisplayMode(.large)
        }
        .alert(languageManager.translate("profile_logout"), isPresented: $showingLogoutAlert) {
            Button(languageManager.translate("profile_cancel"), role: .cancel) {}
            Button(languageManager.translate("profile_logout"), role: .destructive) {
                authManager.signOut()
                HapticsService.shared.success()
            }
        } message: {
            Text(languageManager.translate("profile_logout_confirm"))
        }
        .alert("Сбросить персонализацию?", isPresented: $showingResetPersonalizationAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Сбросить", role: .destructive) {
                HapticManager.shared.warning()
                userProfilePresenter.resetPersonalizationAndRestartOnboarding()
                HapticManager.shared.success()
            }
        } message: {
            Text("Все данные вашей персонализации будут удалены, и вы пройдете онбординг заново. Это поможет настроить более точные рекомендации.")
        }
        .alert("Удалить аккаунт?", isPresented: $showingDeleteAccountAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Удалить навсегда", role: .destructive) {
                HapticManager.shared.error()
                deleteAccountCompletely()
            }
        } message: {
            Text("Это действие необратимо. Будут удалены все ваши данные: профиль, продукты, посты и настройки. Вы выйдете из аккаунта.")
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: .init(
                get: { 
                    if let data = userProfilePresenter.userProfile.profilePhotoData {
                        return UIImage(data: data)
                    }
                    return nil
                },
                set: { image in
                    if let image = image, let imageData = image.jpegData(compressionQuality: 0.7) {
                        userProfilePresenter.userProfile.profilePhotoData = imageData
                        userProfilePresenter.saveProfile()
                    }
                }
            ), sourceType: photoSourceType)
        }
        .confirmationDialog("Фото профиля", isPresented: $showingPhotoActionSheet, titleVisibility: .visible) {
            Button("Сделать фото") {
                photoSourceType = .camera
                showingImagePicker = true
            }
            Button("Выбрать из галереи") {
                photoSourceType = .photoLibrary
                showingImagePicker = true
            }
            if userProfilePresenter.userProfile.profilePhotoData != nil {
                Button("Удалить фото", role: .destructive) {
                    userProfilePresenter.userProfile.profilePhotoData = nil
                    userProfilePresenter.saveProfile()
                }
            }
            Button("Отмена", role: .cancel) {}
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 20) {
            Button(action: { 
                HapticsService.shared.impactMedium()
                showingPhotoActionSheet = true 
            }) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = userProfilePresenter.userProfile.profilePhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Theme.accent, Theme.accentDark],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                            .shadow(color: Theme.accent.opacity(0.2), radius: 20, x: 0, y: 8)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accentDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Theme.accent.opacity(0.3), radius: 20, x: 0, y: 8)
                    }
                    
                    // Camera badge
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.accentDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .offset(x: 8, y: 8)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(userProfilePresenter.userProfile.name.isEmpty ? "Glowly User" : userProfilePresenter.userProfile.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // Premium Badge (Feature Flag Controlled)
                    if FeatureFlags.isPremiumEnabled && FeatureFlags.showPremiumBadge {
                        if let currentUser = authManager.currentUser, currentUser.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(red: 0.85, green: 0.65, blue: 0.20), Color(red: 0.75, green: 0.55, blue: 0.10)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.accent)

                    Text("\(productStore.products.filter { $0.isActive }.count) \(languageManager.translate("profile_products_count"))")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Theme.accent.opacity(0.1))
                )
            }
        }
        .padding(.top, 20)
        .padding(.horizontal, 20)
    }
    
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.translate("profile_language"))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            LanguageSwitcher(languageManager: languageManager)
        }
    }
    
    private var aboutSection: some View {
        HStack {
            Text(languageManager.translate("profile_version"))
                .font(.system(size: 14))
                .foregroundColor(.secondary)

            Spacer()

            Text("1.0.0")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 12)
    }
    
    private var wishListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(languageManager.translate("profile_wishlist"))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !wishListService.wishListItems.isEmpty {
                    Button {
                        showingWishListSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(languageManager.translate("profile_share"))
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 12))
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.accent)
                    }
                }
            }
            
            if wishListService.wishListItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text(languageManager.translate("profile_wishlist_empty"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(languageManager.translate("profile_wishlist_empty_desc"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(wishListService.wishListItems.prefix(5)) { item in
                            WishListItemCard(item: item)
                        }
                        
                        if wishListService.wishListItems.count > 5 {
                            Button {
                                showingWishListSheet = true
                            } label: {
                                VStack(spacing: 8) {
                                    Text("+\(wishListService.wishListItems.count - 5)")
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(Theme.accent)
                                    
                                    Text(languageManager.translate("profile_more"))
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 100, height: 120)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                )
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingWishListSheet) {
            WishListFullView(wishListService: wishListService)
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security") // Not localized - will be removed
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                // Biometric Authentication Toggle
                if biometricService.isBiometricAvailable() {
                    Toggle(isOn: Binding(
                        get: { authManager.isBiometricEnabled },
                        set: { enabled in
                            if enabled {
                                authManager.enableBiometrics()
                            } else {
                                authManager.disableBiometrics()
                            }
                            HapticsService.shared.success()
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: biometricService.biometricType().iconName)
                                .foregroundColor(Theme.accent)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(biometricService.biometricType().displayName)
                                    .foregroundColor(.primary)
                                Text("Быстрый вход в приложение")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(Theme.accent)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.neutralLight)
                    )
                }
                
                // User Info
                if let user = authManager.currentUser {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Email")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.neutralLight)
                        )
                        
                        HStack {
                            Text("Провайдер")
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Image(systemName: user.authProvider == .google ? "g.circle.fill" : "envelope.fill")
                                    .foregroundColor(Theme.accent)
                                Text(user.authProvider == .google ? "Google" : "Email")
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.neutralLight)
                        )
                    }
                }
            }
        }
    }
    
    private var accountManagementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Управление профилем")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            VStack(spacing: 12) {
                // Reset Personalization Button
                Button(action: {
                    HapticManager.shared.lightImpact()
                    showingResetPersonalizationAlert = true
                }) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.orange)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Сбросить персонализацию")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)

                            Text("Пройти онбординг заново")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())

                // Delete Account Button
                Button(action: {
                    HapticManager.shared.warning()
                    showingDeleteAccountAlert = true
                }) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Theme.danger.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(Theme.danger)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Удалить аккаунт")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.danger)

                            Text("Необратимое действие")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var logoutButton: some View {
        Button(action: {
            HapticsService.shared.impactMedium()
            showingLogoutAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.square.fill")
                    .foregroundColor(Theme.danger)
                Text(languageManager.translate("profile_logout"))
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.danger)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Theme.danger.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Theme.danger.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Account Deletion

    private func deleteAccountCompletely() {
        // 1. Delete user account from authentication system
        // This removes the user from UserDefaults and Keychain
        // User won't be able to sign in with these credentials anymore
        authManager.deleteAccount()

        // 2. Reset user profile and personalization
        userProfilePresenter.resetProfile()

        // 3. Clear all products
        productStore.clearAllData()

        // 4. Clear wishlist
        wishListService.clearAllWishList()

        // 5. Success haptic
        HapticManager.shared.success()
    }

}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - WishList Item Card
struct WishListItemCard: View {
    let item: WishListItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                Text(item.productBrand)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("от \(item.fromUserName)")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.accent)
                    .lineLimit(1)
            }
            .frame(width: 100)
        }
    }
}

// MARK: - WishList Full View
struct WishListFullView: View {
    @ObservedObject var wishListService: WishListService
    @Environment(\.dismiss) var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(wishListService.wishListItems) { item in
                        WishListItemRow(item: item, wishListService: wishListService)
                    }
                }
                .padding()
            }
            .navigationTitle("WishList")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingShareSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.accent)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [generateWishListText()])
            }
        }
    }
    
    private func generateWishListText() -> String {
        var text = "🌟 Мой WishList в Glowly:\n\n"
        for item in wishListService.wishListItems {
            text += "• \(item.productName) - \(item.productBrand) (от \(item.fromUserName))\n"
        }
        text += "\nСкачай Glowly: [App Store Link]"
        return text
    }
}

// MARK: - WishList Item Row
struct WishListItemRow: View {
    let item: WishListItem
    @ObservedObject var wishListService: WishListService
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.gray)
                )
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.system(size: 15, weight: .medium))
                
                Text(item.productBrand)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("от \(item.fromUserName)")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.accent)
            }
            
            Spacer()
            
            // Remove Button
            Button {
                wishListService.removeFromWishList(itemId: item.id)
            } label: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
        )
    }
}

// Scale button style for better tap feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
