//
//  Product.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum ApplicationZone: String, CaseIterable, Codable {
    case face = "Лицо"
    case eyes = "Глаза"
    case lips = "Губы"
    case cheeks = "Щеки"
    case body = "Тело"
    case hair = "Волосы"
    case hands = "Руки"
    case feet = "Ноги"
    case nails = "Ногти"
    case neck = "Шея"
    case décolletage = "Декольте"
    
    func localizedName(languageManager: LanguageManager) -> String {
        switch self {
        case .face: return languageManager.translate("application_zone_face")
        case .eyes: return languageManager.translate("application_zone_eyes")
        case .lips: return languageManager.translate("application_zone_lips")
        case .cheeks: return languageManager.translate("application_zone_cheeks")
        case .body: return languageManager.translate("application_zone_body")
        case .hair: return languageManager.translate("application_zone_hair")
        case .hands: return languageManager.translate("application_zone_hands")
        case .feet: return languageManager.translate("application_zone_feet")
        case .nails: return languageManager.translate("application_zone_nails")
        case .neck: return languageManager.translate("application_zone_neck")
        case .décolletage: return languageManager.translate("application_zone_decolletage")
        }
    }
    
    var localizedName: String {
        return self.rawValue
    }
}

struct Product: Identifiable, Codable {
    let id = UUID()
    var name: String
    var brand: String
    var category: ProductCategory
    var applicationZone: ApplicationZone
    var purchaseDate: Date
    var barcode: String?
    var imageData: Data?
    var notes: String
    var isActive: Bool = true
    
    // Detailed Product Information
    var ingredients: String = ""
    var howToUse: String = ""
    var benefits: [String] = []
    var warnings: [String] = []

    // AI-extracted rich information
    var productDescription: String = ""
    var keyIngredients: [String] = []      // role-annotated, e.g. "Niacinamide — brightening"
    var skinTypes: [String] = []           // e.g. ["oily", "combination"]
    var concerns: [String] = []            // e.g. ["acne", "pores"]
    var usageTime: String = "both"         // "morning" | "night" | "both"

    // Personalization tags
    var isSensitiveSafe: Bool = false
    var isAcneSafe: Bool = true

}
