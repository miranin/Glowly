//
//  LoginPresenter.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation
import Combine

class LoginPresenter: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authManager = AuthManager.shared
    private let biometricService = BiometricAuthService.shared
    
    // MARK: - Email/Password Login
    
    func signIn(completion: @escaping (Result<User, AuthError>) -> Void) {
        guard !email.isEmpty, !password.isEmpty else {
            showError(message: "Пожалуйста, заполните все поля")
            completion(.failure(.invalidCredentials))
            return
        }
        
        isLoading = true
        
        authManager.signIn(email: email, password: password) { [weak self] result in
            self?.isLoading = false
            
            switch result {
            case .success(let user):
                HapticsService.shared.success()
                completion(.success(user))
            case .failure(let error):
                self?.showError(message: error.localizedDescription)
                HapticsService.shared.warning()
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Biometric Login
    
    func canUseBiometrics() -> Bool {
        // Check if biometrics are available
        guard biometricService.isBiometricAvailable() else { 
            return false 
        }
        
        // Check if biometrics are enabled in settings
        guard authManager.isBiometricEnabled else { 
            return false 
        }
        
        // Verify there's a saved email (means user has logged in before)
        let keychain = KeychainService.shared
        guard let _ = keychain.retrieveString(forKey: KeychainService.Keys.userEmail) else {
            return false
        }
        
        return true
    }
    
    func signInWithBiometrics(completion: @escaping (Result<User, AuthError>) -> Void) {
        // Double check before attempting
        guard canUseBiometrics() else {
            showError(message: "Биометрическая аутентификация недоступна")
            completion(.failure(.unknown("Биометрическая аутентификация недоступна")))
            return
        }
        
        isLoading = true
        
        authManager.signInWithBiometrics { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    HapticsService.shared.success()
                    completion(.success(user))
                case .failure(let error):
                    self?.showError(message: error.localizedDescription)
                    HapticsService.shared.warning()
                    completion(.failure(error))
                }
            }
        }
    }
    
    func getBiometricType() -> BiometricType {
        return biometricService.biometricType()
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle(completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        
        // This will be implemented with real Google Sign-In SDK
        // For now, we'll use ASWebAuthenticationSession for demonstration
        
        #if DEBUG
        // Mock implementation for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let mockCredentials = GoogleAuthCredentials(
                idToken: UUID().uuidString,
                email: "user@gmail.com",
                name: "Google User",
                profileImageURL: nil
            )
            
            self?.authManager.signInWithGoogle(credentials: mockCredentials) { result in
                self?.isLoading = false
                
                switch result {
                case .success(let user):
                    HapticsService.shared.success()
                    completion(.success(user))
                case .failure(let error):
                    self?.showError(message: error.localizedDescription)
                    HapticsService.shared.warning()
                    completion(.failure(error))
                }
            }
        }
        #else
        // Production: Implement real Google Sign-In here
        self.isLoading = false
        showError(message: "Google Sign-In не настроен")
        completion(.failure(.unknown("Google Sign-In не настроен")))
        #endif
    }
    
    // MARK: - Validation
    
    func isFormValid() -> Bool {
        return !email.isEmpty && !password.isEmpty
    }
    
    // MARK: - Error Handling
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
}

