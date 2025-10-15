//
//  LoginPresenter.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//  Refactored: 09/10/25 - Added DI, async/await
//

import Foundation
import Combine

@MainActor
final class LoginPresenter: ObservableObject {
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies (Injected)
    let authManager: any AuthManagerProtocol
    private let biometricService: BiometricAuthServiceProtocol
    private let keychainService: KeychainServiceProtocol
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(
        authManager: any AuthManagerProtocol,
        biometricService: BiometricAuthServiceProtocol = BiometricAuthService(),
        keychainService: KeychainServiceProtocol = KeychainService()
    ) {
        self.authManager = authManager
        self.biometricService = biometricService
        self.keychainService = keychainService
    }
    
    // MARK: - Email/Password Login (Async/Await)
    
    func signIn() async -> Result<User, AuthError> {
        guard !email.isEmpty, !password.isEmpty else {
            showError(message: "Пожалуйста, заполните все поля")
            return .failure(.invalidCredentials)
        }
        
        return await signIn(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async -> Result<User, AuthError> {
        guard !email.isEmpty, !password.isEmpty else {
            showError(message: "Пожалуйста, заполните все поля")
            return .failure(.invalidCredentials)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await authManager.signIn(email: email, password: password)
            HapticsService.shared.success()
            return .success(user)
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
            return .failure(error)
        } catch {
            let authError = AuthError.unknown(error.localizedDescription)
            showError(message: authError.localizedDescription)
            HapticsService.shared.warning()
            return .failure(authError)
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
        guard keychainService.retrieveString(forKey: KeychainService.Keys.userEmail) != nil else {
            return false
        }
        
        return true
    }
    
    func signInWithBiometrics() async -> Result<User, AuthError> {
        // Double check before attempting
        guard canUseBiometrics() else {
            showError(message: "Биометрическая аутентификация недоступна")
            return .failure(.unknown("Биометрическая аутентификация недоступна"))
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await authManager.signInWithBiometrics()
            HapticsService.shared.success()
            return .success(user)
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
            return .failure(error)
        } catch {
            let authError = AuthError.unknown(error.localizedDescription)
            showError(message: authError.localizedDescription)
            HapticsService.shared.warning()
            return .failure(authError)
        }
    }
    
    func getBiometricType() -> BiometricType {
        return biometricService.biometricType()
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async -> Result<User, AuthError> {
        isLoading = true
        defer { isLoading = false }
        
        #if DEBUG
        // Mock implementation for development
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            let mockCredentials = GoogleAuthCredentials(
                idToken: UUID().uuidString,
                email: "user@gmail.com",
                name: "Google User",
                profileImageURL: nil
            )
            
            let user = try await authManager.signInWithGoogle(credentials: mockCredentials)
            HapticsService.shared.success()
            return .success(user)
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
            return .failure(error)
        } catch {
            let authError = AuthError.unknown(error.localizedDescription)
            showError(message: authError.localizedDescription)
            HapticsService.shared.warning()
            return .failure(authError)
        }
        #else
        // Production: Implement real Google Sign-In here
        showError(message: "Google Sign-In не настроен")
        return .failure(.unknown("Google Sign-In не настроен"))
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
