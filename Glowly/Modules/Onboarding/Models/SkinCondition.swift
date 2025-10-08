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
}

