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
    @State private var showingShareSheet = false
    @State private var showingExportOptions = false
    @State private var showingProfileEdit = false
    @State private var showingImagePicker = false
    @State private var showingPhotoActionSheet = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var userProfile = UserProfile()
    @State private var allergies: String = ""
    @State private var userSegment: String = "Новичок"
    @State private var showingLogoutAlert = false
    @StateObject private var pdfService = PDFExportService()
    private let segments = ["Новичок", "Эксперт", "Визажист"]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    profileHeader
                    profileEditButton
                    securitySection
                    sharingSection
                    exportSection
                    aboutSection
                    logoutButton
                }
                .padding(20)
            }
            .navigationTitle("Профиль")
        }
        .alert("Выход из аккаунта", isPresented: $showingLogoutAlert) {
            Button("Отмена", role: .cancel) {}
            Button("Выйти", role: .destructive) {
                authManager.signOut()
                HapticsService.shared.success()
            }
        } message: {
            Text("Вы уверены, что хотите выйти из аккаунта?")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [productStore.shareExportURL()])
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileEditView(userProfilePresenter: userProfilePresenter)
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
        .confirmationDialog("Поделиться косметичкой", isPresented: $showingExportOptions, titleVisibility: .visible) {
            Button("Создать PDF для просмотра") {
                createAndSharePDF()
            }
            Button("Поделиться данными (для пользователей Glowly)") {
                showingShareSheet = true
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Выберите способ экспорта")
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Button(action: { 
                HapticsService.shared.impactMedium()
                showingPhotoActionSheet = true 
            }) {
                ZStack(alignment: .bottomTrailing) {
                    ZStack {
                        // Animated gradient background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.accent.opacity(0.2), Theme.accentDark.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .blur(radius: 15)
                        
                        if let photoData = userProfilePresenter.userProfile.profilePhotoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 90, height: 90)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [Theme.accent, Theme.accentDark],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 3
                                        )
                                        .shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                                )
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.accentDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Theme.accent.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                    }
                    
                    // Camera badge with gradient
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
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Theme.backgroundCard, lineWidth: 3)
                        )
                        .shadow(color: Theme.accent.opacity(0.4), radius: 6, x: 0, y: 3)
                        .offset(x: 4, y: 4)
                }
                .contentShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            
            VStack(spacing: 4) {
                Text(userProfilePresenter.userProfile.name.isEmpty ? "Пользователь Glowly" : userProfilePresenter.userProfile.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack(spacing: 6) {
                    Image(systemName: "bag.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("\(productStore.products.filter { $0.isActive }.count) продуктов в косметичке")
                        .font(.caption)
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.1), Theme.accentLight.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
    
    private var profileEditButton: some View {
        Button(action: { 
            HapticsService.shared.impactLight()
            showingProfileEdit = true 
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.15), Theme.accentDark.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: "person.crop.circle.badge.pencil")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accentDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Редактировать профиль")
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.accent)
                    .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Theme.neutralLight, Theme.backgroundCard],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Персонализация")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Picker("Уровень", selection: $userSegment) {
                    ForEach(segments, id: \.self) { Text($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.neutralLight)
                )
                
                TextField("Аллергии / триггеры", text: $allergies)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.neutralLight)
                    )
            }
        }
    }
    
    private var sharingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Поделиться")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Button(action: { showingExportOptions = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.accent)
                        Text("Поделиться косметичкой")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.neutralLight)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Создайте PDF для друзей без приложения или поделитесь данными с другими пользователями Glowly")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Экспорт данных")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                Button(action: { createAndSharePDF() }) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(Theme.accent)
                        Text("Экспорт в PDF")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.neutralLight)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Theme.accent)
                        Text("Экспорт данных")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Theme.neutralLight)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("О приложении")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Версия")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.primary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.neutralLight)
                )
                
                HStack {
                    Text("Продуктов в базе")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(productStore.products.count)")
                        .foregroundColor(.primary)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.neutralLight)
                )
            }
        }
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Безопасность")
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
    
    private var logoutButton: some View {
        Button(action: {
            HapticsService.shared.impactMedium()
            showingLogoutAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.right.square.fill")
                    .foregroundColor(Theme.danger)
                Text("Выйти из аккаунта")
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
    
    private func createAndSharePDF() {
        if let pdfURL = pdfService.createCosmeticBagPDF(products: productStore.products, userProfile: userProfile) {
            let shareSheet = ShareSheet(items: [pdfURL])
            // Present the share sheet with PDF
            DispatchQueue.main.async {
                // This would present the PDF share sheet
                showingShareSheet = true
            }
        }
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

// Scale button style for better tap feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
