//
//  SkinTone.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum SkinTone: String, Codable, CaseIterable {
    case notSpecified = "Не указано"
    case veryFair = "Очень светлый"
    case fair = "Светлый"
    case light = "Светло-средний"
    case medium = "Средний"
    case tan = "Загорелый"
    case deep = "Темный"
    case veryDeep = "Очень темный"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .notSpecified: return languageManager.currentLanguage == .russian ? "Не указано" :
                           languageManager.currentLanguage == .english ? "Not specified" :
                           "Көрсетілмеген"
        case .veryFair: return languageManager.translate("skin_tone_fair")
        case .fair: return languageManager.translate("skin_tone_light")
        case .light: return languageManager.translate("skin_tone_light")
        case .medium: return languageManager.translate("skin_tone_medium")
        case .tan: return languageManager.translate("skin_tone_tan")
        case .deep: return languageManager.translate("skin_tone_dark")
        case .veryDeep: return languageManager.translate("skin_tone_deep")
        }
    }
    
    var colorHex: String {
        switch self {
        case .notSpecified: return "#CCCCCC"
        case .veryFair: return "#FFE4D6"
        case .fair: return "#F5D5C5"
        case .light: return "#E8B896"
        case .medium: return "#D4A574"
        case .tan: return "#C18A5A"
        case .deep: return "#8D5524"
        case .veryDeep: return "#5C3A21"
        }
    }
}

