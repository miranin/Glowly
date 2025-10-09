//
//  RegistrationPresenter.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//  Refactored: 09/10/25 - Added DI, async/await
//

import Foundation
import Combine

@MainActor
final class RegistrationPresenter: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var agreedToTerms: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies (Injected)
    private let authManager: any AuthManagerProtocol
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(authManager: any AuthManagerProtocol) {
        self.authManager = authManager
    }
    
    // MARK: - Registration (Async/Await)
    
    func signUp() async -> Result<User, AuthError> {
        guard isFormValid() else {
            showError(message: "Пожалуйста, заполните все поля корректно")
            return .failure(.invalidCredentials)
        }
        
        guard password == confirmPassword else {
            showError(message: "Пароли не совпадают")
            return .failure(.invalidCredentials)
        }
        
        guard agreedToTerms else {
            showError(message: "Необходимо согласиться с условиями использования")
            return .failure(.invalidCredentials)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await authManager.signUp(
                email: email,
                password: password,
                name: name.isEmpty ? nil : name
            )
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
    
    // MARK: - Google Sign-Up
    
    func signUpWithGoogle() async -> Result<User, AuthError> {
        isLoading = true
        defer { isLoading = false }
        
        #if DEBUG
        // Mock implementation for development
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            let mockCredentials = GoogleAuthCredentials(
                idToken: UUID().uuidString,
                email: "newuser@gmail.com",
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
        return !email.isEmpty &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 8 &&
               agreedToTerms &&
               isValidEmail(email)
    }
    
    func passwordsMatch() -> Bool {
        return !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    func calculatePasswordStrength() -> Int {
        var strength = 0
        
        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { strength += 1 }
        
        return strength
    }
    
    func getPasswordStrengthText() -> String {
        let strength = calculatePasswordStrength()
        switch strength {
        case 0...2: return "Слабый пароль"
        case 3: return "Средний пароль"
        default: return "Надежный пароль"
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
