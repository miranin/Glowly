//
//  ProductCategory.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum ProductCategory: String, CaseIterable, Codable {
    case foundation = "Тональный крем"
    case concealer = "Консилер"
    case powder = "Пудра"
    case blush = "Румяна"
    case bronzer = "Бронзер"
    case highlighter = "Хайлайтер"
    case eyeshadow = "Тени для век"
    case eyeliner = "Подводка"
    case mascara = "Тушь"
    case lipstick = "Помада"
    case lipGloss = "Блеск для губ"
    case lipLiner = "Контур для губ"
    case primer = "Праймер"
    case settingSpray = "Фиксирующий спрей"
    case cleanser = "Очищающее средство"
    case moisturizer = "Увлажняющий крем"
    case serum = "Сыворотка"
    case sunscreen = "Солнцезащитный крем"
    case mask = "Маска"
    case other = "Другое"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .foundation: return languageManager.translate("category_foundation")
        case .concealer: return languageManager.translate("category_concealer")
        case .powder: return languageManager.translate("category_powder")
        case .blush: return languageManager.translate("category_blush")
        case .bronzer: return languageManager.translate("category_bronzer")
        case .highlighter: return languageManager.translate("category_highlighter")
        case .eyeshadow: return languageManager.translate("category_eyeshadow")
        case .eyeliner: return languageManager.translate("category_eyeliner")
        case .mascara: return languageManager.translate("category_mascara")
        case .lipstick: return languageManager.translate("category_lipstick")
        case .lipGloss: return languageManager.translate("category_lip_gloss")
        case .lipLiner: return languageManager.translate("category_lip_liner")
        case .primer: return languageManager.translate("category_primer")
        case .settingSpray: return languageManager.translate("category_setting_spray")
        case .cleanser: return languageManager.translate("category_cleanser")
        case .moisturizer: return languageManager.translate("category_moisturizer")
        case .serum: return languageManager.translate("category_serum")
        case .sunscreen: return languageManager.translate("category_sunscreen")
        case .mask: return languageManager.translate("category_mask")
        case .other: return languageManager.translate("category_other")
        }
    }
    
    // Optional asset name to display custom image from Assets.xcassets
    var assetName: String? {
        switch self {
        case .foundation: return "tone"
        case .concealer: return "concealer"
        case .powder: return "poudre"
        default: return nil
        }
    }
    
    var icon: String {
        switch self {
        case .foundation: return "drop.fill"
        case .concealer: return "circle.fill"
        case .powder: return "sparkles"
        case .blush: return "heart.fill"
        case .bronzer: return "sun.max.fill"
        case .highlighter: return "star.fill"
        case .eyeshadow: return "eye.fill"
        case .eyeliner: return "pencil"
        case .mascara: return "eye"
        case .lipstick: return "lips"
        case .lipGloss: return "sparkle"
        case .lipLiner: return "pencil.and.outline"
        case .primer: return "paintbrush.fill"
        case .settingSpray: return "spray"
        case .cleanser: return "drop"
        case .moisturizer: return "leaf.fill"
        case .serum: return "flask.fill"
        case .sunscreen: return "sun.max"
        case .mask: return "face.smiling"
        case .other: return "questionmark.circle"
        }
    }
}

