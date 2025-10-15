//
//  RegistrationViewModel.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//  Consolidated: Merged Presenter functionality into ViewModel
//

import SwiftUI
import Combine

@MainActor
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
    @Published var agreedToTerms: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Dependencies (Injected)
    private let authManager: any AuthManagerProtocol

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

    // MARK: - Initialization with Dependency Injection
    nonisolated init(authManager: any AuthManagerProtocol) {
        self.authManager = authManager
    }

    // MARK: - Registration Actions

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

        do {
            _ = try await authManager.signUp(
                email: identifier,
                password: password,
                name: name.isEmpty ? nil : name
            )
            HapticsService.shared.success()
            // Show OTP verification
            showOTPVerification = true
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        } catch {
            showError(message: "Произошла ошибка. Попробуйте снова.")
            HapticsService.shared.warning()
        }
    }

    // MARK: - Google Sign-Up

    func signUpWithGoogle() async {
        HapticsService.shared.impactMedium()
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

            _ = try await authManager.signInWithGoogle(credentials: mockCredentials)
            HapticsService.shared.success()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        } catch {
            showError(message: "Ошибка регистрации через Google")
            HapticsService.shared.warning()
        }
        #else
        // Production: Implement real Google Sign-In here
        showError(message: "Google Sign-In не настроен")
        #endif
    }

    // MARK: - UI Actions

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

    // MARK: - Password Strength

    func calculatePasswordStrength() -> Int {
        var strength = 0

        if password.count >= 8 { strength += 1 }
        if password.count >= 12 { strength += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil { strength += 1 }

        return strength
    }

    func passwordStrengthText() -> String {
        let strength = calculatePasswordStrength()
        switch strength {
        case 0...2: return "слабый пароль"
        case 3: return "средний пароль"
        default: return "надежный пароль"
        }
    }

    func passwordStrengthColor() -> Color {
        let strength = calculatePasswordStrength()
        switch strength {
        case 0...2: return .red
        case 3: return .orange
        default: return .green
        }
    }

    func passwordStrengthIcon() -> String {
        let strength = calculatePasswordStrength()
        switch strength {
        case 0...2: return "xmark.circle.fill"
        case 3: return "exclamationmark.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }

    // MARK: - Border Colors

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
