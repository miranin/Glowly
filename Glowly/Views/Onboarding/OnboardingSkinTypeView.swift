//
//  OnboardingSkinTypeView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingSkinTypeView: View {
    @Binding var userProfile: UserProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var selectedSkinType: SkinType = .notSpecified
    @State private var selectedSkinTone: SkinTone = .notSpecified
    
    var body: some View {
        OnboardingStepContainer(
            title: "Тип кожи",
            subtitle: "Это поможет подобрать правильный уход",
            onContinue: {
                saveAndContinue()
            },
            onBack: onBack,
            canContinue: selectedSkinType != .notSpecified
        ) {
            VStack(spacing: 24) {
                // Skin Type
                VStack(alignment: .leading, spacing: 12) {
                    Text("Какой у вас тип кожи?")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(SkinType.allCases.filter { $0 != .notSpecified }, id: \.self) { type in
                        SelectionButton(
                            title: type.rawValue,
                            subtitle: getSkinTypeDescription(type),
                            isSelected: selectedSkinType == type,
                            action: { selectedSkinType = type }
                        )
                    }
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                // Skin Tone
                VStack(alignment: .leading, spacing: 12) {
                    Text("Тон кожи (опционально)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 8) {
                        ForEach(SkinTone.allCases, id: \.self) { tone in
                            Button(action: { selectedSkinTone = tone }) {
                                HStack(spacing: 12) {
                                    // Color circle indicator
                                    Circle()
                                        .fill(Color(hex: tone.colorHex))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
                                        )
                                    
                                    Text(tone.rawValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: selectedSkinTone == tone ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(selectedSkinTone == tone ? Theme.accent : Theme.neutral)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedSkinTone == tone ? Theme.accent.opacity(0.1) : Theme.neutralLight)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedSkinTone == tone ? Theme.accent : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .onAppear {
            selectedSkinType = userProfile.skinType
            selectedSkinTone = userProfile.skinTone
        }
    }
    
    private func saveAndContinue() {
        userProfile.skinType = selectedSkinType
        userProfile.skinTone = selectedSkinTone
        onContinue()
    }
    
    private func getSkinTypeDescription(_ type: SkinType) -> String {
        switch type {
        case .normal: return "Сбалансированная, без проблем"
        case .dry: return "Шелушения, стянутость"
        case .oily: return "Жирный блеск, расширенные поры"
        case .combination: return "Жирная T-зона, сухие щеки"
        case .sensitive: return "Покраснения, раздражения"
        case .notSpecified: return ""
        }
    }
}

#Preview {
    OnboardingSkinTypeView(
        userProfile: .constant(UserProfile()),
        onContinue: {},
        onBack: {}
    )
}

