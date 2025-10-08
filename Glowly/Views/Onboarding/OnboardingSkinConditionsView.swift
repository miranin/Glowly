//
//  OnboardingSkinConditionsView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingSkinConditionsView: View {
    @Binding var userProfile: UserProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var selectedConditions: Set<SkinCondition> = []
    
    var body: some View {
        OnboardingStepContainer(
            title: "Состояние кожи",
            subtitle: "Выберите все, что применимо (необязательно)",
            onContinue: {
                saveAndContinue()
            },
            onBack: onBack,
            canContinue: true
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Есть ли у вас какие-либо из этих состояний?")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                // "No issues" option first, full width
                MultiSelectButton(
                    title: SkinCondition.noIssues.rawValue,
                    isSelected: selectedConditions.contains(.noIssues),
                    action: {
                        if selectedConditions.contains(.noIssues) {
                            selectedConditions.remove(.noIssues)
                        } else {
                            // If "no issues" is selected, clear all other conditions
                            selectedConditions = [.noIssues]
                        }
                    }
                )
                
                if !selectedConditions.contains(.noIssues) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(SkinCondition.allCases.filter { $0 != .noIssues }, id: \.self) { condition in
                            MultiSelectButton(
                                title: condition.rawValue,
                                isSelected: selectedConditions.contains(condition),
                                action: {
                                    if selectedConditions.contains(condition) {
                                        selectedConditions.remove(condition)
                                    } else {
                                        // Remove "no issues" if selecting a specific condition
                                        selectedConditions.remove(.noIssues)
                                        selectedConditions.insert(condition)
                                    }
                                }
                            )
                        }
                    }
                }
                
                if !selectedConditions.isEmpty && !selectedConditions.contains(.noIssues) {
                    Text("Выбрано: \(selectedConditions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
        }
        .onAppear {
            selectedConditions = Set(userProfile.skinConditions)
        }
    }
    
    private func saveAndContinue() {
        userProfile.skinConditions = Array(selectedConditions)
        onContinue()
    }
}

#Preview {
    OnboardingSkinConditionsView(
        userProfile: .constant(UserProfile()),
        onContinue: {},
        onBack: {}
    )
}

