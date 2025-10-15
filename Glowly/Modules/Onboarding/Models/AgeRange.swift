//
//  AgeRange.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum AgeRange: String, Codable, CaseIterable {
    case under18 = "До 18"
    case range18to24 = "18-24"
    case range25to34 = "25-34"
    case range35to44 = "35-44"
    case range45to54 = "45-54"
    case range55plus = "55+"
    case preferNotToSay = "Предпочитаю не указывать"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .under18: return languageManager.currentLanguage == .russian ? "До 18" :
                       languageManager.currentLanguage == .english ? "Under 18" :
                       "18-ге дейін"
        case .range18to24: return languageManager.translate("age_range_18_24")
        case .range25to34: return languageManager.translate("age_range_25_34")
        case .range35to44: return languageManager.translate("age_range_35_44")
        case .range45to54: return languageManager.translate("age_range_45_54")
        case .range55plus: return languageManager.translate("age_range_55_plus")
        case .preferNotToSay: return languageManager.currentLanguage == .russian ? "Предпочитаю не указывать" :
                             languageManager.currentLanguage == .english ? "Prefer not to say" :
                             "Көрсеткім келмейді"
        }
    }
}

