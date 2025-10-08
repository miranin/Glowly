//
//  Sex.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum Sex: String, Codable, CaseIterable {
    case male = "Мужской"
    case female = "Женский"
    case nonBinary = "Небинарный"
    case notSpecified = "Не указано"
}

