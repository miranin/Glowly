//
//  Sex.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum Sex: String, Codable, CaseIterable {
    case male = "Мужской"
    case female = "Женский"
    case nonBinary = "Небинарный"
    case notSpecified = "Не указано"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .male: return languageManager.translate("gender_male")
        case .female: return languageManager.translate("gender_female")
        case .nonBinary: return languageManager.translate("gender_other")
        case .notSpecified: return languageManager.currentLanguage == .russian ? "Не указано" :
                           languageManager.currentLanguage == .english ? "Not specified" :
                           "Көрсетілмеген"
        }
    }
}

