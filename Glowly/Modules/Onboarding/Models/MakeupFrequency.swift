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
}

