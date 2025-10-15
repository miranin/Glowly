//
//  SkinType.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum SkinType: String, Codable, CaseIterable {
    case notSpecified = "Не указано"
    case normal = "Нормальная"
    case dry = "Сухая"
    case oily = "Жирная"
    case combination = "Комбинированная"
    case sensitive = "Чувствительная"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .notSpecified: return languageManager.currentLanguage == .russian ? "Не указано" :
                           languageManager.currentLanguage == .english ? "Not specified" :
                           "Көрсетілмеген"
        case .normal: return languageManager.translate("skin_type_normal")
        case .dry: return languageManager.translate("skin_type_dry")
        case .oily: return languageManager.translate("skin_type_oily")
        case .combination: return languageManager.translate("skin_type_combination")
        case .sensitive: return languageManager.translate("skin_type_sensitive")
        }
    }
}

