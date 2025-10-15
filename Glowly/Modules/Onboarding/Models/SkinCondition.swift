//
//  SkinCondition.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum SkinCondition: String, Codable, CaseIterable {
    case noIssues = "У меня нет таких проблем"
    case acne = "Акне"
    case rosacea = "Розацеа"
    case eczema = "Экзема"
    case psoriasis = "Псориаз"
    case hyperpigmentation = "Гиперпигментация"
    case dryPatches = "Сухие участки"
    case largesPores = "Расширенные поры"
    case fineLines = "Мелкие морщины"
    case darkCircles = "Темные круги"
    case redness = "Покраснения"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .noIssues: return languageManager.currentLanguage == .russian ? "У меня нет таких проблем" :
                        languageManager.currentLanguage == .english ? "I don't have these issues" :
                        "Менде мұндай мәселелер жоқ"
        case .acne: return languageManager.translate("skin_condition_acne")
        case .rosacea: return languageManager.translate("skin_condition_rosacea")
        case .eczema: return languageManager.translate("skin_condition_eczema")
        case .psoriasis: return languageManager.translate("skin_condition_psoriasis")
        case .hyperpigmentation: return languageManager.translate("skin_condition_hyperpigmentation")
        case .dryPatches: return languageManager.translate("skin_condition_dry_patches")
        case .largesPores: return languageManager.translate("skin_condition_enlarged_pores")
        case .fineLines: return languageManager.translate("skin_condition_fine_lines")
        case .darkCircles: return languageManager.translate("skin_condition_dark_circles")
        case .redness: return languageManager.translate("skin_condition_redness")
        }
    }
}

