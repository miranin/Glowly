//
//  OnboardingBasicInfoView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingBasicInfoView: View {
    @Binding var userProfile: UserProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var name: String = ""
    @State private var selectedAgeRange: AgeRange = .preferNotToSay
    @State private var selectedSex: Sex = .notSpecified
    
    var body: some View {
        OnboardingStepContainer(
            title: "Основная информация",
            subtitle: "Расскажите немного о себе",
            onContinue: {
                saveAndContinue()
            },
            onBack: onBack,
            canContinue: !name.isEmpty
        ) {
            VStack(spacing: 24) {
                // Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Как вас зовут?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("Введите имя", text: $name)
                        .textFieldStyle(OnboardingTextFieldStyle())
                }
                
                // Age Range
                VStack(alignment: .leading, spacing: 8) {
                    Text("Возрастная группа")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Menu {
                        ForEach(AgeRange.allCases, id: \.self) { ageRange in
                            Button(action: {
                                selectedAgeRange = ageRange
                            }) {
                                Text(ageRange.rawValue)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedAgeRange.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Theme.neutralLight)
                        )
                    }
                }
                
                // Sex
                VStack(alignment: .leading, spacing: 12) {
                    Text("Пол")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(Sex.allCases, id: \.self) { sex in
                        SelectionButton(
                            title: sex.rawValue,
                            isSelected: selectedSex == sex,
                            action: { selectedSex = sex }
                        )
                    }
                }
            }
        }
        .onAppear {
            name = userProfile.name
            selectedAgeRange = userProfile.ageRange
            selectedSex = userProfile.sex
        }
    }
    
    private func saveAndContinue() {
        userProfile.name = name
        userProfile.ageRange = selectedAgeRange
        userProfile.sex = selectedSex
        onContinue()
    }
}

#Preview {
    OnboardingBasicInfoView(
        userProfile: .constant(UserProfile()),
        onContinue: {},
        onBack: {}
    )
}

