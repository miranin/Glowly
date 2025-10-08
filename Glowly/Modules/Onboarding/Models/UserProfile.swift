//
//  UserProfile.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

struct UserProfile: Codable {
    var id: UUID = UUID()
    var hasCompletedOnboarding: Bool = false
    
    // Basic Information
    var name: String = ""
    var ageRange: AgeRange = .preferNotToSay
    var sex: Sex = .notSpecified
    
    // Skin Information
    var skinType: SkinType = .notSpecified
    var skinTone: SkinTone = .notSpecified
    var skinConditions: [SkinCondition] = []
    var allergies: [CommonAllergen] = []
    var sensitivities: [CommonAllergen] = []
    
    // Beauty Profile
    var experienceLevel: ExperienceLevel = .beginner
    var beautyGoals: [BeautyGoal] = []
    var preferredBrands: [String] = []
    
    // Preferences
    var makeupFrequency: MakeupFrequency = .occasionally
    var skincareRoutineComplexity: RoutineComplexity = .basic
    var preferredProductTypes: [ProductCategory] = []
    
    // Profile Photo
    var profilePhotoData: Data?
    
    // AI Context
    var lastUpdated: Date = Date()
    
    // Computed property for AI prompt context
    var aiContextString: String {
        var context = "User Profile:\n"
        context += "- Age Range: \(ageRange.rawValue)\n"
        context += "- Sex: \(sex.rawValue)\n"
        context += "- Skin Type: \(skinType.rawValue)\n"
        context += "- Skin Tone: \(skinTone.rawValue)\n"
        
        if !skinConditions.isEmpty {
            context += "- Skin Conditions: \(skinConditions.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        if !allergies.isEmpty {
            context += "- Allergies: \(allergies.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        if !sensitivities.isEmpty {
            context += "- Sensitivities: \(sensitivities.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        context += "- Experience Level: \(experienceLevel.rawValue)\n"
        
        if !beautyGoals.isEmpty {
            context += "- Beauty Goals: \(beautyGoals.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        context += "- Makeup Frequency: \(makeupFrequency.rawValue)\n"
        context += "- Skincare Routine: \(skincareRoutineComplexity.rawValue)\n"
        
        return context
    }
}

