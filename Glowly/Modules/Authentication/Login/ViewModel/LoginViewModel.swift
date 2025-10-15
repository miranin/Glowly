//
//  LoginViewModel.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

final class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var loginType: LoginType = .email
    @Published var showPassword: Bool = false
    @Published var showForgotPassword: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    let authManager: AuthManager
    let presenter: LoginPresenter
    
    // MARK: - Types
    enum LoginType {
        case email
        case phone
        
        var placeholder: String {
            switch self {
            case .email: return "e-mail"
            case .phone: return "700 123 45 67"
            }
        }
    }
    
    // MARK: - Init
    init(authManager: AuthManager) {
        self.authManager = authManager
        self.presenter = LoginPresenter(authManager: authManager)
    }
    
    // MARK: - Actions
    func signIn() async {
        HapticsService.shared.impactMedium()
        
        guard isFormValid() else {
            showError(message: "Заполните все поля корректно")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Use email or phone as identifier
        let identifier = loginType == .email ? email : "+7\(phone)"
        
        // Call presenter
        let result = await presenter.signIn(email: identifier, password: password)
        
        switch result {
        case .success:
            HapticsService.shared.success()
        case .failure(let error):
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        }
    }
    
    func signInWithGoogle() async {
        HapticsService.shared.impactMedium()
        let result = await presenter.signInWithGoogle()
        
        switch result {
        case .success:
            HapticsService.shared.success()
        case .failure(let error):
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        }
    }
    
    func togglePasswordVisibility() {
        showPassword.toggle()
        HapticsService.shared.impactLight()
    }
    
    func clearError() {
        withAnimation {
            showError = false
            errorMessage = nil
        }
    }
    
    private func showError(message: String) {
        withAnimation {
            errorMessage = message
            showError = true
        }
    }
    
    // MARK: - Validation
    func isFormValid() -> Bool {
        let hasValidContact = loginType == .email ? 
            isValidEmail(email) : 
            isValidPhone(phone)
        
        return hasValidContact && !password.isEmpty && password.count >= 8
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPhone(_ phone: String) -> Bool {
        let digitsOnly = phone.filter { $0.isNumber }
        return digitsOnly.count == 10 && digitsOnly.hasPrefix("7")
    }
    
    func emailBorderColor() -> Color {
        if email.isEmpty {
            return .clear
        }
        return isValidEmail(email) ? .green : .red
    }
    
    func phoneBorderColor() -> Color {
        if phone.isEmpty {
            return .clear
        }
        return isValidPhone(phone) ? .green : .red
    }
    
    // MARK: - Phone Formatting
    func formatPhone(_ input: String) -> String {
        let digitsOnly = input.filter { $0.isNumber }
        let limited = String(digitsOnly.prefix(10))
        
        // Format: 700 123 45 67
        var formatted = ""
        for (index, char) in limited.enumerated() {
            if index == 3 || index == 6 || index == 8 {
                formatted += " "
            }
            formatted.append(char)
        }
        
        return formatted
    }
    
    func handlePhoneInput(_ newValue: String) {
        let digitsOnly = newValue.filter { $0.isNumber }
        if digitsOnly.count > 10 {
            phone = String(digitsOnly.prefix(10))
        }
    }
    
    // MARK: - Clear Fields on Type Change
    func handleLoginTypeChange(_ newType: LoginType) {
        if newType != loginType {
            // Clear both fields when switching
            email = ""
            phone = ""
            loginType = newType
        }
    }
}

