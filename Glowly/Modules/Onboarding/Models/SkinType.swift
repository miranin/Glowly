//
//  SkinType.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum SkinType: String, Codable, CaseIterable {
    case notSpecified = "Не указано"
    case normal = "Нормальная"
    case dry = "Сухая"
    case oily = "Жирная"
    case combination = "Комбинированная"
    case sensitive = "Чувствительная"
}

