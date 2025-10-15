//
//  CommonAllergen.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum CommonAllergen: String, Codable, CaseIterable {
    case parabens = "Парабены"
    case sulfates = "Сульфаты"
    case fragrance = "Ароматизаторы"
    case alcohol = "Спирт"
    case essentialOils = "Эфирные масла"
    case silicones = "Силиконы"
    case dyes = "Красители"
    case retinol = "Ретинол"
    case aha = "AHA кислоты"
    case bha = "BHA кислоты"
    case vitaminC = "Витамин С"
    case niacinamide = "Ниацинамид"
    case mineralOil = "Минеральное масло"
    case lanolin = "Ланолин"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .parabens: return languageManager.translate("allergen_parabens")
        case .sulfates: return languageManager.translate("allergen_sulfates")
        case .fragrance: return languageManager.translate("allergen_fragrances")
        case .alcohol: return languageManager.translate("allergen_alcohol")
        case .essentialOils: return languageManager.translate("allergen_essential_oils")
        case .silicones: return languageManager.translate("allergen_silicones")
        case .dyes: return languageManager.translate("allergen_dyes")
        case .retinol: return languageManager.translate("allergen_retinol")
        case .aha: return languageManager.translate("allergen_aha_acids")
        case .bha: return languageManager.translate("allergen_bha_acids")
        case .vitaminC: return languageManager.translate("allergen_vitamin_c")
        case .niacinamide: return languageManager.translate("allergen_niacinamide")
        case .mineralOil: return languageManager.currentLanguage == .russian ? "Минеральное масло" :
                         languageManager.currentLanguage == .english ? "Mineral oil" :
                         "Минерал майы"
        case .lanolin: return languageManager.currentLanguage == .russian ? "Ланолин" :
                      languageManager.currentLanguage == .english ? "Lanolin" :
                      "Ланолин"
        }
    }
}

