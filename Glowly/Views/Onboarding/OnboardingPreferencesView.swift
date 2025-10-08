//
//  OnboardingPreferencesView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingPreferencesView: View {
    @Binding var userProfile: UserProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var makeupFrequency: MakeupFrequency = .occasionally
    @State private var routineComplexity: RoutineComplexity = .basic
    
    var body: some View {
        OnboardingStepContainer(
            title: "Предпочтения",
            subtitle: "Последний шаг!",
            onContinue: {
                saveAndContinue()
            },
            onBack: onBack,
            canContinue: true
        ) {
            VStack(spacing: 24) {
                // Makeup Frequency
                VStack(alignment: .leading, spacing: 12) {
                    Text("Как часто вы используете макияж?")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(MakeupFrequency.allCases, id: \.self) { frequency in
                        SelectionButton(
                            title: frequency.rawValue,
                            isSelected: makeupFrequency == frequency,
                            action: { makeupFrequency = frequency }
                        )
                    }
                }
                
                Divider()
                
                // Routine Complexity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Сложность вашей рутины ухода")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    ForEach(RoutineComplexity.allCases, id: \.self) { complexity in
                        SelectionButton(
                            title: complexity.rawValue,
                            isSelected: routineComplexity == complexity,
                            action: { routineComplexity = complexity }
                        )
                    }
                }
            }
        }
        .onAppear {
            makeupFrequency = userProfile.makeupFrequency
            routineComplexity = userProfile.skincareRoutineComplexity
        }
    }
    
    private func saveAndContinue() {
        userProfile.makeupFrequency = makeupFrequency
        userProfile.skincareRoutineComplexity = routineComplexity
        onContinue()
    }
}

#Preview {
    OnboardingPreferencesView(
        userProfile: .constant(UserProfile()),
        onContinue: {},
        onBack: {}
    )
}

