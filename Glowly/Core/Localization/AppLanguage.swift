//
//  AppLanguage.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation
import SwiftUI

// MARK: - Supported Languages
enum AppLanguage: String, CaseIterable, Identifiable {
    case russian = "ru"
    case english = "en"
    case kazakh = "kk"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .kazakh: return "Қазақша"
        }
    }
    
    var flag: String {
        switch self {
        case .russian: return "🇷🇺"
        case .english: return "🇺🇸"
        case .kazakh: return "🇰🇿"
        }
    }
}

// MARK: - Language Manager
final class LanguageManager: ObservableObject {
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "app_language")
        }
    }
    
    init() {
        let savedLanguage = UserDefaults.standard.string(forKey: "app_language") ?? "ru"
        self.currentLanguage = AppLanguage(rawValue: savedLanguage) ?? .russian
    }
    
    func changeLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    func translate(_ key: String) -> String {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return key
        }
        return NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }
}

