//
//  OnboardingAllergiesView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingAllergiesView: View {
    @Binding var userProfile: UserProfile
    let onContinue: () -> Void
    let onBack: () -> Void
    
    @State private var selectedAllergies: Set<CommonAllergen> = []
    @State private var selectedSensitivities: Set<CommonAllergen> = []
    
    var body: some View {
        OnboardingStepContainer(
            title: "Аллергии и чувствительность",
            subtitle: "Выберите компоненты, которых следует избегать",
            onContinue: {
                saveAndContinue()
            },
            onBack: onBack,
            canContinue: true
        ) {
            VStack(spacing: 24) {
                // Allergies
                VStack(alignment: .leading, spacing: 12) {
                    Text("Аллергии на ингредиенты")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Выберите компоненты, на которые у вас аллергия")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(CommonAllergen.allCases, id: \.self) { allergen in
                            MultiSelectButton(
                                title: allergen.rawValue,
                                isSelected: selectedAllergies.contains(allergen),
                                action: {
                                    if selectedAllergies.contains(allergen) {
                                        selectedAllergies.remove(allergen)
                                    } else {
                                        selectedAllergies.insert(allergen)
                                    }
                                }
                            )
                        }
                    }
                    
                    if !selectedAllergies.isEmpty {
                        Text("Выбрано: \(selectedAllergies.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                
                Divider()
                
                // Sensitivities
                VStack(alignment: .leading, spacing: 12) {
                    Text("Чувствительность к компонентам")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Компоненты, которые могут вызвать раздражение")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(CommonAllergen.allCases, id: \.self) { allergen in
                            MultiSelectButton(
                                title: allergen.rawValue,
                                isSelected: selectedSensitivities.contains(allergen),
                                action: {
                                    if selectedSensitivities.contains(allergen) {
                                        selectedSensitivities.remove(allergen)
                                    } else {
                                        selectedSensitivities.insert(allergen)
                                    }
                                }
                            )
                        }
                    }
                    
                    if !selectedSensitivities.isEmpty {
                        Text("Выбрано: \(selectedSensitivities.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            selectedAllergies = Set(userProfile.allergies)
            selectedSensitivities = Set(userProfile.sensitivities)
        }
    }
    
    private func saveAndContinue() {
        userProfile.allergies = Array(selectedAllergies)
        userProfile.sensitivities = Array(selectedSensitivities)
        onContinue()
    }
}

struct ChipView: View {
    let text: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Theme.accent.opacity(0.1))
        .foregroundColor(Theme.accent)
        .cornerRadius(12)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.offsets[index].x, y: bounds.minY + result.offsets[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var offsets: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                offsets.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

#Preview {
    OnboardingAllergiesView(
        userProfile: .constant(UserProfile()),
        onContinue: {},
        onBack: {}
    )
}

