//
//  ModernProfileEditView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct ModernProfileEditView: View {
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.dismiss) var dismiss
    
    @State private var editedProfile: UserProfile
    @State private var showingImagePicker = false
    @State private var showingPhotoActionSheet = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(userProfilePresenter: UserProfilePresenter) {
        self.userProfilePresenter = userProfilePresenter
        _editedProfile = State(initialValue: userProfilePresenter.userProfile)
    }
    
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Profile Photo
                        profilePhotoSection
                        
                        VStack(spacing: 16) {
                            basicInfoSection
                            skinInfoSection
                            skinConditionsSection
                            allergiesSection
                            beautyProfileSection
                            preferencesSection
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(languageManager.translate("personalization_title"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(languageManager.translate("personalization_cancel")) {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.translate("personalization_save")) {
                        HapticsService.shared.impactMedium()
                        saveChanges()
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: .init(
                get: {
                    if let data = editedProfile.profilePhotoData {
                        return UIImage(data: data)
                    }
                    return nil
                },
                set: { image in
                    if let image = image, let imageData = image.jpegData(compressionQuality: 0.7) {
                        editedProfile.profilePhotoData = imageData
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
            if editedProfile.profilePhotoData != nil {
                Button("Удалить фото", role: .destructive) {
                    editedProfile.profilePhotoData = nil
                }
            }
            Button("Отмена", role: .cancel) {}
        }
    }
    
    private var profilePhotoSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                HapticsService.shared.impactMedium()
                showingPhotoActionSheet = true
            }) {
                ZStack(alignment: .bottomTrailing) {
                    if let photoData = editedProfile.profilePhotoData,
                       let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
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
                            )
                            .shadow(color: Theme.accent.opacity(0.2), radius: 15, x: 0, y: 6)
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accentDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: Theme.accent.opacity(0.3), radius: 15, x: 0, y: 6)
                    }
                    
                    // Camera badge
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .fill(Theme.accent)
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Нажмите, чтобы изменить фото")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    private var basicInfoSection: some View {
        ModernSection(title: languageManager.translate("personalization_basic_info"), icon: "person.fill") {
            VStack(spacing: 16) {
                ModernTextField(label: languageManager.translate("personalization_name"), text: $editedProfile.name)
                ModernPicker(label: languageManager.translate("personalization_age"), selection: $editedProfile.ageRange)
                ModernPicker(label: languageManager.translate("personalization_gender"), selection: $editedProfile.sex)
            }
        }
    }
    
    private var skinInfoSection: some View {
        ModernSection(title: languageManager.translate("personalization_skin_info"), icon: "drop.fill") {
            VStack(spacing: 16) {
                ModernPicker(label: languageManager.translate("personalization_skin_type"), selection: $editedProfile.skinType)
                ModernPicker(label: languageManager.translate("personalization_skin_tone"), selection: $editedProfile.skinTone)
            }
        }
    }
    
    private var skinConditionsSection: some View {
        ModernSection(title: languageManager.translate("personalization_skin_conditions"), icon: "face.smiling") {
            VStack(spacing: 12) {
                Text(languageManager.currentLanguage == .russian ? "Выберите проблемы кожи" : 
                     languageManager.currentLanguage == .english ? "Select skin problems" : 
                     "Тері проблемаларын таңдаңыз")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ModernMultiSelect(
                    options: SkinCondition.allCases.filter { $0 != .noIssues },
                    selection: $editedProfile.skinConditions
                )
            }
        }
    }
    
    private var allergiesSection: some View {
        ModernSection(title: languageManager.translate("personalization_allergies"), icon: "exclamationmark.triangle") {
            VStack(spacing: 12) {
                Text(languageManager.currentLanguage == .russian ? "Выберите аллергены" :
                     languageManager.currentLanguage == .english ? "Select allergens" :
                     "Аллергендерді таңдаңыз")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ModernMultiSelect(
                    options: CommonAllergen.allCases,
                    selection: $editedProfile.allergies
                )
            }
        }
    }
    
    private var beautyProfileSection: some View {
        ModernSection(title: languageManager.translate("personalization_beauty_profile"), icon: "sparkles") {
            VStack(spacing: 16) {
                ModernPicker(label: languageManager.translate("personalization_experience"), selection: $editedProfile.experienceLevel)
                
                VStack(spacing: 12) {
                    Text(languageManager.translate("personalization_goals"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ModernMultiSelect(
                        options: BeautyGoal.allCases,
                        selection: $editedProfile.beautyGoals
                    )
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        ModernSection(title: languageManager.translate("personalization_preferences"), icon: "slider.horizontal.3") {
            VStack(spacing: 16) {
                ModernPicker(label: languageManager.translate("personalization_makeup_frequency"), selection: $editedProfile.makeupFrequency)
                ModernPicker(label: languageManager.translate("personalization_skincare_complexity"), selection: $editedProfile.skincareRoutineComplexity)
            }
        }
    }
    
    private func saveChanges() {
        userProfilePresenter.userProfile = editedProfile
        userProfilePresenter.saveProfile()
        
        // Send notification for AI chat
        NotificationCenter.default.post(name: .profileUpdated, object: nil)
    }
}

// MARK: - Modern Components

struct ModernSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Theme.accent)
                    )
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                content
                    .padding(20)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
        }
    }
}

struct ModernTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField(label, text: $text)
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
}

struct ModernPicker<T: CaseIterable & RawRepresentable & Hashable>: View where T.RawValue == String {
    let label: String
    @Binding var selection: T
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Button(getLocalizedName(for: option)) {
                        selection = option
                        HapticsService.shared.impactLight()
                    }
                }
            } label: {
                HStack {
                    Text(getLocalizedName(for: selection))
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private func getLocalizedName(for option: T) -> String {
        // Use localizedName method if available
        if let sex = option as? Sex {
            return sex.localizedName(languageManager: languageManager)
        } else if let skinType = option as? SkinType {
            return skinType.localizedName(languageManager: languageManager)
        } else if let skinTone = option as? SkinTone {
            return skinTone.localizedName(languageManager: languageManager)
        } else if let ageRange = option as? AgeRange {
            return ageRange.localizedName(languageManager: languageManager)
        } else if let experienceLevel = option as? ExperienceLevel {
            return experienceLevel.localizedName(languageManager: languageManager)
        } else if let makeupFrequency = option as? MakeupFrequency {
            return makeupFrequency.localizedName(languageManager: languageManager)
        } else if let routineComplexity = option as? RoutineComplexity {
            return routineComplexity.localizedName(languageManager: languageManager)
        }
        // Fallback to rawValue
        return option.rawValue
    }
}

struct ModernMultiSelect<T: CaseIterable & RawRepresentable & Hashable>: View where T.RawValue == String {
    let options: [T]
    @Binding var selection: [T]
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    HapticsService.shared.impactLight()
                    if selection.contains(option) {
                        selection.removeAll { $0 == option }
                    } else {
                        selection.append(option)
                    }
                }) {
                    Text(getLocalizedName(for: option))
                        .font(.system(size: 14, weight: selection.contains(option) ? .medium : .regular))
                        .foregroundColor(selection.contains(option) ? Theme.accent : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection.contains(option) ? 
                                      Theme.accent.opacity(0.1) : Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selection.contains(option) ? 
                                               Theme.accent : Color.clear, lineWidth: 1.5)
                                )
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func getLocalizedName(for option: T) -> String {
        // Use localizedName method if available
        if let skinCondition = option as? SkinCondition {
            return skinCondition.localizedName(languageManager: languageManager)
        } else if let allergen = option as? CommonAllergen {
            return allergen.localizedName(languageManager: languageManager)
        } else if let beautyGoal = option as? BeautyGoal {
            return beautyGoal.localizedName(languageManager: languageManager)
        }
        // Fallback to rawValue
        return option.rawValue
    }
}

#Preview {
    ModernProfileEditView(userProfilePresenter: UserProfilePresenter())
}
