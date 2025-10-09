//
//  BiometricAuthService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import LocalAuthentication
import Foundation

// MARK: - BiometricAuthService Protocol for DI
protocol BiometricAuthServiceProtocol {
    func biometricType() -> BiometricType
    func isBiometricAvailable() -> Bool
    func canUseBiometrics() -> Result<Bool, BiometricAuthError>
    func authenticateWithBiometrics(reason: String?, completion: @escaping (Result<Void, BiometricAuthError>) -> Void)
    func authenticateWithDeviceOwner(reason: String, completion: @escaping (Result<Void, BiometricAuthError>) -> Void)
}

final class BiometricAuthService: BiometricAuthServiceProtocol {
    // Removed singleton - use dependency injection instead
    private let context = LAContext()
    
    init() {}
    
    // MARK: - Check Biometric Availability
    
    func biometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    func canUseBiometrics() -> Result<Bool, BiometricAuthError> {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                switch error.code {
                case LAError.biometryNotAvailable.rawValue:
                    return .failure(.notAvailable)
                case LAError.biometryNotEnrolled.rawValue:
                    return .failure(.notEnrolled)
                case LAError.passcodeNotSet.rawValue:
                    return .failure(.passcodeNotSet)
                default:
                    return .failure(.failed(error.localizedDescription))
                }
            }
            return .failure(.notAvailable)
        }
        
        return .success(true)
    }
    
    // MARK: - Authenticate
    
    func authenticateWithBiometrics(reason: String? = nil, completion: @escaping (Result<Void, BiometricAuthError>) -> Void) {
        let context = LAContext()
        context.localizedFallbackTitle = "Использовать пароль"
        context.localizedCancelTitle = "Отмена"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let error = error {
                switch error.code {
                case LAError.biometryNotAvailable.rawValue:
                    completion(.failure(.notAvailable))
                case LAError.biometryNotEnrolled.rawValue:
                    completion(.failure(.notEnrolled))
                case LAError.passcodeNotSet.rawValue:
                    completion(.failure(.passcodeNotSet))
                default:
                    completion(.failure(.failed(error.localizedDescription)))
                }
            } else {
                completion(.failure(.notAvailable))
            }
            return
        }
        
        let biometricType = self.biometricType()
        let authReason = reason ?? "Войдите, используя \(biometricType.displayName)"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: authReason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel, .appCancel, .systemCancel:
                            completion(.failure(.cancelled))
                        case .userFallback:
                            completion(.failure(.fallback))
                        case .biometryNotAvailable:
                            completion(.failure(.notAvailable))
                        case .biometryNotEnrolled:
                            completion(.failure(.notEnrolled))
                        case .passcodeNotSet:
                            completion(.failure(.passcodeNotSet))
                        default:
                            completion(.failure(.failed(error.localizedDescription)))
                        }
                    } else {
                        completion(.failure(.failed("Ошибка аутентификации")))
                    }
                }
            }
        }
    }
    
    // MARK: - Device Owner Authentication (includes passcode)
    
    func authenticateWithDeviceOwner(reason: String, completion: @escaping (Result<Void, BiometricAuthError>) -> Void) {
        let context = LAContext()
        context.localizedCancelTitle = "Отмена"
        
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(.failure(.notAvailable))
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel, .appCancel, .systemCancel:
                            completion(.failure(.cancelled))
                        default:
                            completion(.failure(.failed(error.localizedDescription)))
                        }
                    } else {
                        completion(.failure(.failed("Ошибка аутентификации")))
                    }
                }
            }
        }
    }
}

