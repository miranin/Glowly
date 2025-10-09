//
//  AuthError.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case networkError
    case invalidToken
    case biometricFailed(BiometricAuthError)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .userNotFound:
            return "Пользователь не найден"
        case .emailAlreadyExists:
            return "Пользователь с таким email уже существует"
        case .weakPassword:
            return "Пароль должен содержать минимум 8 символов"
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету"
        case .invalidToken:
            return "Сессия истекла. Войдите заново"
        case .biometricFailed(let error):
            return error.errorDescription
        case .unknown(let message):
            return message
        }
    }
}

