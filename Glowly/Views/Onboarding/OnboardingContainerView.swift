//
//  OnboardingContainerView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import SwiftUI

struct OnboardingContainerView: View {
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @State private var currentStep: OnboardingStep = .welcome
    @State private var showingCompletion = false
    
    var body: some View {
        ZStack {
            Theme.backgroundPowder.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                if currentStep != .welcome && currentStep != .completion {
                    OnboardingProgressBar(currentStep: currentStep, totalSteps: OnboardingStep.allCases.count - 2)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                }
                
                // Content
                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(onContinue: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            currentStep = .basicInfo
                        }
                    })
                    .tag(OnboardingStep.welcome)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    OnboardingBasicInfoView(
                        userProfile: $userProfilePresenter.userProfile,
                        onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .skinType
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .welcome
                            }
                        }
                    )
                    .tag(OnboardingStep.basicInfo)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    
                    OnboardingSkinTypeView(
                        userProfile: $userProfilePresenter.userProfile,
                        onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .skinConditions
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .basicInfo
                            }
                        }
                    )
                    .tag(OnboardingStep.skinType)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    OnboardingSkinConditionsView(
                        userProfile: $userProfilePresenter.userProfile,
                        onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .allergies
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .skinType
                            }
                        }
                    )
                    .tag(OnboardingStep.skinConditions)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    OnboardingAllergiesView(
                        userProfile: $userProfilePresenter.userProfile,
                        onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .beautyProfile
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .skinConditions
                            }
                        }
                    )
                    .tag(OnboardingStep.allergies)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    OnboardingBeautyProfileView(
                        userProfile: $userProfilePresenter.userProfile,
                        onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .preferences
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .allergies
                            }
                        }
                    )
                    .tag(OnboardingStep.beautyProfile)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    OnboardingPreferencesView(
                        userProfile: $userProfilePresenter.userProfile,
                        onContinue: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .completion
                            }
                        },
                        onBack: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentStep = .beautyProfile
                            }
                        }
                    )
                    .tag(OnboardingStep.preferences)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

                    OnboardingCompletionView(
                        userProfile: userProfilePresenter.userProfile,
                        onComplete: {
                            HapticManager.shared.completion()
                            userProfilePresenter.completeOnboarding()
                        }
                    )
                    .tag(OnboardingStep.completion)
                    .transition(.scale.combined(with: .opacity))
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
    }
}

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case basicInfo = 1
    case skinType = 2
    case skinConditions = 3
    case allergies = 4
    case beautyProfile = 5
    case preferences = 6
    case completion = 7
    
    var title: String {
        switch self {
        case .welcome: return "Добро пожаловать"
        case .basicInfo: return "Основная информация"
        case .skinType: return "Тип кожи"
        case .skinConditions: return "Состояние кожи"
        case .allergies: return "Аллергии и чувствительность"
        case .beautyProfile: return "Бьюти-профиль"
        case .preferences: return "Предпочтения"
        case .completion: return "Готово"
        }
    }
}

struct OnboardingProgressBar: View {
    let currentStep: OnboardingStep
    let totalSteps: Int
    
    private var progress: CGFloat {
        CGFloat(currentStep.rawValue) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.neutralLight)
                    .frame(height: 4)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.accentGradient)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut, value: progress)
            }
        }
        .frame(height: 4)
    }
}

#Preview {
    OnboardingContainerView(userProfilePresenter: UserProfilePresenter())
}

