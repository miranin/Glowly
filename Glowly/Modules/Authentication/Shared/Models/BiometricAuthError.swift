//
//  BiometricAuthError.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

enum BiometricAuthError: LocalizedError {
    case notAvailable
    case notEnrolled
    case failed(String)
    case cancelled
    case fallback
    case passcodeNotSet
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Биометрическая аутентификация недоступна на этом устройстве"
        case .notEnrolled:
            return "Биометрическая аутентификация не настроена. Пожалуйста, настройте Face ID или Touch ID в настройках устройства"
        case .failed(let message):
            return message
        case .cancelled:
            return "Аутентификация отменена"
        case .fallback:
            return "Выбрана альтернативная аутентификация"
        case .passcodeNotSet:
            return "Необходимо установить пароль устройства"
        }
    }
}

