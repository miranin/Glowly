//
//  ExperienceLevel.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner = "Новичок"
    case intermediate = "Любитель"
    case advanced = "Эксперт"
    case professional = "Визажист"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .beginner: return languageManager.translate("experience_level_beginner")
        case .intermediate: return languageManager.translate("experience_level_intermediate")
        case .advanced: return languageManager.translate("experience_level_advanced")
        case .professional: return languageManager.currentLanguage == .russian ? "Визажист" :
                           languageManager.currentLanguage == .english ? "Professional" :
                           "Маман"
        }
    }
}

