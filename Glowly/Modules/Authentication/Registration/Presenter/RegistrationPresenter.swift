//
//  RegistrationPresenter.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation
import Combine

class RegistrationPresenter: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var agreedToTerms: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authManager = AuthManager.shared
    
    // MARK: - Registration
    
    func signUp(completion: @escaping (Result<User, AuthError>) -> Void) {
        guard isFormValid() else {
            showError(message: "Пожалуйста, заполните все поля корректно")
            completion(.failure(.invalidCredentials))
            return
        }
        
        guard password == confirmPassword else {
            showError(message: "Пароли не совпадают")
            completion(.failure(.invalidCredentials))
            return
        }
        
        guard agreedToTerms else {
            showError(message: "Необходимо согласиться с условиями использования")
            completion(.failure(.invalidCredentials))
            return
        }
        
        isLoading = true
        
        authManager.signUp(email: email, password: password, name: name.isEmpty ? nil : name) { [weak self] result in
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
    
    // MARK: - Google Sign-Up
    
    func signUpWithGoogle(completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        
        #if DEBUG
        // Mock implementation for development
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let mockCredentials = GoogleAuthCredentials(
                idToken: UUID().uuidString,
                email: "newuser@gmail.com",
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

