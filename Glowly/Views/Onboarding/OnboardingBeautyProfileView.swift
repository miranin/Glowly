//
//  OnboardingBeautyProfileView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingBeautyProfileView: View {
    @Binding var userProfile: UserProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var selectedGoals: Set<BeautyGoal> = []
    
    var body: some View {
        OnboardingStepContainer(
            title: "Бьюти-профиль",
            subtitle: "Расскажите о своем опыте и целях",
            onContinue: {
                saveAndContinue()
            },
            onBack: onBack,
            canContinue: !selectedGoals.isEmpty
        ) {
            VStack(spacing: 24) {
                // Experience Level
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ваш уровень опыта")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(ExperienceLevel.allCases, id: \.self) { level in
                        SelectionButton(
                            title: level.rawValue,
                            subtitle: getExperienceDescription(level),
                            isSelected: selectedLevel == level,
                            action: { selectedLevel = level }
                        )
                    }
                }
                
                Divider()
                
                // Beauty Goals
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ваши цели (выберите несколько)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(BeautyGoal.allCases, id: \.self) { goal in
                            MultiSelectButton(
                                title: goal.rawValue,
                                isSelected: selectedGoals.contains(goal),
                                action: {
                                    if selectedGoals.contains(goal) {
                                        selectedGoals.remove(goal)
                                    } else {
                                        selectedGoals.insert(goal)
                                    }
                                }
                            )
                        }
                    }
                    
                    if !selectedGoals.isEmpty {
                        Text("Выбрано: \(selectedGoals.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            selectedLevel = userProfile.experienceLevel
            selectedGoals = Set(userProfile.beautyGoals)
        }
    }
    
    private func saveAndContinue() {
        userProfile.experienceLevel = selectedLevel
        userProfile.beautyGoals = Array(selectedGoals)
        onContinue()
    }
    
    private func getExperienceDescription(_ level: ExperienceLevel) -> String {
        switch level {
        case .beginner: return "Только начинаю"
        case .intermediate: return "Знаю основы"
        case .advanced: return "Уверенный пользователь"
        case .professional: return "Профессионал"
        }
    }
}

#Preview {
    OnboardingBeautyProfileView(
        userProfile: .constant(UserProfile()),
        onContinue: {},
        onBack: {}
    )
}

