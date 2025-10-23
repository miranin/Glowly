//
//  UserProfilePresenter.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 07/10/25.
//

import Foundation
import Combine

// Import User model for sync functionality
// User model is defined in: Modules/Authentication/Shared/Models/User.swift

class UserProfilePresenter: ObservableObject {
    @Published var userProfile: UserProfile
    
    private let userDefaults = UserDefaults.standard
    private let userProfileKey = "UserProfile"
    
    init() {
        // Load existing profile or create new one
        if let data = userDefaults.data(forKey: userProfileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.userProfile = decoded
        } else {
            self.userProfile = UserProfile()
        }
    }
    
    func saveProfile() {
        userProfile.lastUpdated = Date()
        if let encoded = try? JSONEncoder().encode(userProfile) {
            userDefaults.set(encoded, forKey: userProfileKey)
        }
    }
    
    func completeOnboarding() {
        userProfile.hasCompletedOnboarding = true
        saveProfile()
    }
    
    func updateBasicInfo(name: String, ageRange: AgeRange, sex: Sex) {
        userProfile.name = name
        userProfile.ageRange = ageRange
        userProfile.sex = sex
        saveProfile()
    }
    
    func updateSkinInfo(skinType: SkinType, skinTone: SkinTone, conditions: [SkinCondition]) {
        userProfile.skinType = skinType
        userProfile.skinTone = skinTone
        userProfile.skinConditions = conditions
        saveProfile()
    }
    
    func updateAllergies(_ allergies: [CommonAllergen], sensitivities: [CommonAllergen]) {
        userProfile.allergies = allergies
        userProfile.sensitivities = sensitivities
        saveProfile()
    }
    
    func updateBeautyProfile(level: ExperienceLevel, goals: [BeautyGoal]) {
        userProfile.experienceLevel = level
        userProfile.beautyGoals = goals
        saveProfile()
    }
    
    func updatePreferences(makeupFrequency: MakeupFrequency, routineComplexity: RoutineComplexity) {
        userProfile.makeupFrequency = makeupFrequency
        userProfile.skincareRoutineComplexity = routineComplexity
        saveProfile()
    }
    
    func resetProfile() {
        userProfile = UserProfile()
        saveProfile()
    }

    /// Resets personalization and restarts onboarding flow
    /// Preserves user name but clears all other profile data
    func resetPersonalizationAndRestartOnboarding() {
        let currentName = userProfile.name
        userProfile = UserProfile()
        userProfile.name = currentName
        userProfile.hasCompletedOnboarding = false
        saveProfile()
    }

    var needsOnboarding: Bool {
        return !userProfile.hasCompletedOnboarding
    }

    // MARK: - Sync with Authenticated User

    /// Sync name from authenticated user to profile
    /// This ensures the name entered during registration appears in the profile
    /// Always updates profile name with the authenticated user's name
    func syncWithAuthenticatedUser(_ user: User) {
        if let userName = user.name, !userName.isEmpty {
            userProfile.name = userName
            saveProfile()
        }
    }
}

