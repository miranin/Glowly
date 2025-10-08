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

