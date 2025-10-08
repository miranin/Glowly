//
//  ProfileEditView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI
import Combine

extension Notification.Name {
    static let profileUpdated = Notification.Name("profileUpdated")
}

struct ProfileEditView: View {
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @Environment(\.dismiss) var dismiss
    
    @State private var editedProfile: UserProfile
    @State private var showingImagePicker = false
    @State private var photoSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(userProfilePresenter: UserProfilePresenter) {
        self.userProfilePresenter = userProfilePresenter
        _editedProfile = State(initialValue: userProfilePresenter.userProfile)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.backgroundPowder.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Profile Photo - Compact
                        profilePhotoSection
                        
                        // Basic Info
                        CompactSection(title: "Основная информация", icon: "person.fill", color: Theme.accent) {
                            VStack(spacing: 12) {
                                CompactTextField(label: "Имя", text: $editedProfile.name)
                                CompactPicker(label: "Возраст", selection: $editedProfile.ageRange)
                                CompactPicker(label: "Пол", selection: $editedProfile.sex)
                            }
                        }
                        
                        // Skin Info
                        CompactSection(title: "Тип кожи", icon: "drop.fill", color: Theme.info) {
                            VStack(spacing: 12) {
                                CompactPicker(label: "Тип кожи", selection: $editedProfile.skinType)
                                CompactPicker(label: "Тон кожи", selection: $editedProfile.skinTone)
                                
                                if !editedProfile.skinConditions.isEmpty {
                                    LargeTagsView(title: "Проблемы кожи", items: editedProfile.skinConditions.map { $0.rawValue }, color: Theme.info)
                                }
                            }
                        }
                        
                        // Allergies
                        if !editedProfile.allergies.isEmpty || !editedProfile.sensitivities.isEmpty {
                            CompactSection(title: "Аллергии и чувствительность", icon: "exclamationmark.triangle.fill", color: Theme.warning) {
                                VStack(spacing: 14) {
                                    if !editedProfile.allergies.isEmpty {
                                        LargeTagsView(title: "Аллергии", items: editedProfile.allergies.map { $0.rawValue }, color: Theme.danger)
                                    }
                                    if !editedProfile.sensitivities.isEmpty {
                                        LargeTagsView(title: "Чувствительность", items: editedProfile.sensitivities.map { $0.rawValue }, color: Theme.warning)
                                    }
                                }
                            }
                        }
                        
                        // Beauty Profile
                        CompactSection(title: "Бьюти-профиль", icon: "sparkles", color: Theme.accent) {
                            VStack(spacing: 12) {
                                CompactPicker(label: "Уровень опыта", selection: $editedProfile.experienceLevel)
                                
                                if !editedProfile.beautyGoals.isEmpty {
                                    LargeTagsView(title: "Цели", items: editedProfile.beautyGoals.map { $0.rawValue }, color: Theme.accent)
                                }
                            }
                        }
                        
                        // Preferences
                        CompactSection(title: "Предпочтения", icon: "slider.horizontal.3", color: Theme.info) {
                            VStack(spacing: 12) {
                                CompactPicker(label: "Частота макияжа", selection: $editedProfile.makeupFrequency)
                                CompactPicker(label: "Сложность ухода", selection: $editedProfile.skincareRoutineComplexity)
                            }
                        }
                        
                        // Save Button
                        Button(action: {
                            HapticsService.shared.impactMedium()
                            saveChanges()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Сохранить изменения")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Theme.accent, Theme.accentDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Редактировать профиль")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        HapticsService.shared.impactLight()
                        dismiss()
                    }
                    .foregroundColor(Theme.accent)
                }
            }
            .dismissKeyboardOnTap()
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
    }
    
    private var profilePhotoSection: some View {
        HStack(spacing: 16) {
            // Photo
            ZStack {
                if let photoData = editedProfile.profilePhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
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
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent.opacity(0.2), Theme.accentDark.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Theme.accent)
                        )
                }
            }
            
            // Actions
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    HapticsService.shared.impactLight()
                    photoSourceType = .camera
                    showingImagePicker = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.caption)
                        Text("Камера")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                
                Button(action: {
                    HapticsService.shared.impactLight()
                    photoSourceType = .photoLibrary
                    showingImagePicker = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.fill")
                            .font(.caption)
                        Text("Галерея")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Theme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Theme.accent.opacity(0.1))
                    .cornerRadius(10)
                }
                
                if editedProfile.profilePhotoData != nil {
                    Button(action: {
                        HapticsService.shared.impactLight()
                        editedProfile.profilePhotoData = nil
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.fill")
                                .font(.caption)
                            Text("Удалить")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(Theme.danger)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.danger.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.backgroundCard)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
    
    private func saveChanges() {
        // Update timestamp and save
        editedProfile.lastUpdated = Date()
        userProfilePresenter.userProfile = editedProfile
        userProfilePresenter.saveProfile()
        
        // Notify AI system that profile has been updated
        NotificationCenter.default.post(name: .profileUpdated, object: nil, userInfo: ["profile": editedProfile])
        
        HapticsService.shared.success()
        dismiss()
    }
    
}

// MARK: - Compact Components

struct CompactSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)
            }
            
            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Theme.backgroundCard)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }
}

struct CompactTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            TextField("", text: $text)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.neutralLight)
                .cornerRadius(8)
        }
    }
}

struct CompactPicker<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let label: String
    @Binding var selection: T
    
    var body: some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            Picker("", selection: $selection) {
                ForEach(Array(T.allCases), id: \.self) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.accent)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.neutralLight)
            .cornerRadius(8)
        }
    }
}

struct TagsView: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(Theme.textSecondary)
            
            TagFlowLayout(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(color.opacity(0.1))
                        .foregroundColor(color)
                        .cornerRadius(6)
                }
            }
        }
    }
}

struct LargeTagsView: View {
    let title: String
    let items: [String]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.textPrimary)
            
            TagFlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(color.opacity(0.12))
                        )
                        .foregroundColor(color)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// Custom tag flow layout helper
struct TagFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize
        var frames: [CGRect]
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var frames: [CGRect] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)
                
                if currentX + subviewSize.width > width && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: subviewSize))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX - spacing)
                size.height = currentY + lineHeight
            }
            
            self.frames = frames
            self.size = size
        }
    }
}

#Preview {
    ProfileEditView(userProfilePresenter: UserProfilePresenter())
}


