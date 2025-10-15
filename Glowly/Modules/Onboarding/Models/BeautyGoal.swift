//
//  BeautyGoal.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum BeautyGoal: String, Codable, CaseIterable {
    case antiAging = "Антивозрастной уход"
    case hydration = "Увлажнение"
    case acneTreatment = "Лечение акне"
    case brighten = "Осветление"
    case evenTone = "Выравнивание тона"
    case minimize = "Минимизация пор"
    case firmness = "Упругость"
    case glowySkin = "Сияние кожи"
    case naturalLook = "Естественный макияж"
    case dramaticLook = "Драматический макияж"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .antiAging: return languageManager.translate("beauty_goal_anti_aging")
        case .hydration: return languageManager.translate("beauty_goal_hydration")
        case .acneTreatment: return languageManager.translate("beauty_goal_acne_treatment")
        case .brighten: return languageManager.translate("beauty_goal_brightening")
        case .evenTone: return languageManager.translate("beauty_goal_even_tone")
        case .minimize: return languageManager.currentLanguage == .russian ? "Минимизация пор" :
                       languageManager.currentLanguage == .english ? "Minimize pores" :
                       "Тесіктерді азайту"
        case .firmness: return languageManager.currentLanguage == .russian ? "Упругость" :
                       languageManager.currentLanguage == .english ? "Firmness" :
                       "Беріктік"
        case .glowySkin: return languageManager.currentLanguage == .russian ? "Сияние кожи" :
                        languageManager.currentLanguage == .english ? "Glowy skin" :
                        "Терінің жарқырауы"
        case .naturalLook: return languageManager.currentLanguage == .russian ? "Естественный макияж" :
                          languageManager.currentLanguage == .english ? "Natural look" :
                          "Табиғи көрініс"
        case .dramaticLook: return languageManager.currentLanguage == .russian ? "Драматический макияж" :
                           languageManager.currentLanguage == .english ? "Dramatic look" :
                           "Драмалық көрініс"
        }
    }
}

