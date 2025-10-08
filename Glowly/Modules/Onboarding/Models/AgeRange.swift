//
//  AgeRange.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov
//

import Foundation

enum AgeRange: String, Codable, CaseIterable {
    case under18 = "До 18"
    case range18to24 = "18-24"
    case range25to34 = "25-34"
    case range35to44 = "35-44"
    case range45to54 = "45-54"
    case range55plus = "55+"
    case preferNotToSay = "Предпочитаю не указывать"
}

