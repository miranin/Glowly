//
//  MakeupFrequency.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum MakeupFrequency: String, Codable, CaseIterable {
    case never = "Никогда"
    case rarely = "Редко"
    case occasionally = "Иногда"
    case regularly = "Регулярно"
    case daily = "Ежедневно"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .never: return languageManager.translate("makeup_frequency_never")
        case .rarely: return languageManager.translate("makeup_frequency_rarely")
        case .occasionally: return languageManager.translate("makeup_frequency_sometimes")
        case .regularly: return languageManager.translate("makeup_frequency_often")
        case .daily: return languageManager.translate("makeup_frequency_daily")
        }
    }
}

