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
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var agreedToTerms: Bool = true // Auto-agreed in new design
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
        return await signUp(
            name: name,
            identifier: !email.isEmpty ? email : "+7\(phone)",
            password: password,
            confirmPassword: confirmPassword
        )
    }
    
    func signUp(name: String, identifier: String, password: String, confirmPassword: String) async -> Result<User, AuthError> {
        guard !name.isEmpty, !identifier.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            showError(message: "Пожалуйста, заполните все поля")
            return .failure(.invalidCredentials)
        }
        
        guard password == confirmPassword else {
            showError(message: "Пароли не совпадают")
            return .failure(.invalidCredentials)
        }
        
        guard password.count >= 8 else {
            showError(message: "Пароль должен содержать минимум 8 символов")
            return .failure(.weakPassword)
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await authManager.signUp(
                email: identifier,
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
        let hasValidContact = !email.isEmpty ? isValidEmail(email) : isValidPhone(phone)
        
        return !name.isEmpty &&
               hasValidContact &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               password == confirmPassword &&
               password.count >= 8
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        // Kazakhstan phone: 10 digits (700-799 range)
        let digitsOnly = phone.filter { $0.isNumber }
        return digitsOnly.count == 10 && digitsOnly.hasPrefix("7")
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
