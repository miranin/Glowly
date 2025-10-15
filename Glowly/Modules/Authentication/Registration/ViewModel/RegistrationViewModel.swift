//
//  RegistrationViewModel.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

final class RegistrationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var registrationType: RegistrationType = .email
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var showOTPVerification: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Dependencies
    private let authManager: AuthManager
    private let presenter: RegistrationPresenter
    
    // MARK: - Types
    enum RegistrationType {
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
        self.presenter = RegistrationPresenter(authManager: authManager)
    }
    
    // MARK: - Actions
    func signUp() async {
        HapticsService.shared.impactMedium()
        
        guard isFormValid() else {
            showError(message: "Заполните все поля корректно")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Use email or phone as identifier
        let identifier = registrationType == .email ? email : "+7\(phone)"
        
        // Call presenter
        let result = await presenter.signUp(
            name: name,
            identifier: identifier,
            password: password,
            confirmPassword: confirmPassword
        )
        
        switch result {
        case .success:
            HapticsService.shared.success()
            // Show OTP verification
            showOTPVerification = true
        case .failure(let error):
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        }
    }
    
    func signUpWithGoogle() async {
        HapticsService.shared.impactMedium()
        // TODO: Implement Google Sign Up
    }
    
    func togglePasswordVisibility() {
        showPassword.toggle()
        HapticsService.shared.impactLight()
    }
    
    func toggleConfirmPasswordVisibility() {
        showConfirmPassword.toggle()
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
        let hasValidContact = registrationType == .email ? 
            isValidEmail(email) : 
            isValidPhone(phone)
        
        return !name.isEmpty &&
               hasValidContact &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               passwordsMatch() &&
               password.count >= 8
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
    
    func passwordsMatch() -> Bool {
        !password.isEmpty && !confirmPassword.isEmpty && password == confirmPassword
    }
    
    func passwordStrengthColor() -> Color {
        if password.count < 8 { return .red }
        else if password.count < 12 { return .orange }
        else { return .green }
    }
    
    func passwordStrengthText() -> String {
        if password.count < 8 { return "слабый пароль" }
        else if password.count < 12 { return "средний пароль" }
        else { return "надежный пароль" }
    }
    
    func passwordStrengthIcon() -> String {
        if password.count < 8 { return "xmark.circle.fill" }
        else if password.count < 12 { return "exclamationmark.circle.fill" }
        else { return "checkmark.circle.fill" }
    }
    
    func passwordBorderColor() -> Color {
        password.isEmpty ? .clear : passwordStrengthColor()
    }
    
    func confirmPasswordBorderColor() -> Color {
        if confirmPassword.isEmpty { return .clear }
        return passwordsMatch() ? .green : .red
    }
    
    func emailBorderColor() -> Color {
        if email.isEmpty { return .clear }
        return isValidEmail(email) ? .green : .red
    }
    
    func phoneBorderColor() -> Color {
        if phone.isEmpty { return .clear }
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
    func handleRegistrationTypeChange(_ newType: RegistrationType) {
        if newType != registrationType {
            // Clear both fields when switching
            email = ""
            phone = ""
            registrationType = newType
        }
    }
}

