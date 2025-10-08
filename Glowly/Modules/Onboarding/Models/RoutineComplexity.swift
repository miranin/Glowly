//
//  RoutineComplexity.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum RoutineComplexity: String, Codable, CaseIterable {
    case minimal = "Минимальный (1-3 продукта)"
    case basic = "Базовый (4-6 продуктов)"
    case moderate = "Умеренный (7-9 продуктов)"
    case extensive = "Расширенный (10+ продуктов)"
}

