//
//  LoginViewModel.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//  Consolidated: Merged Presenter functionality into ViewModel
//

import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var loginType: LoginType = .email
    @Published var showPassword: Bool = false
    @Published var showForgotPassword: Bool = false
    @Published var showOTPVerification: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Dependencies (Injected)
    let authManager: any AuthManagerProtocol
    private let biometricService: BiometricAuthServiceProtocol
    private let keychainService: KeychainServiceProtocol

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

    // MARK: - Sign In Actions

    func signIn() async {
        HapticsService.shared.impactMedium()

        guard isFormValid() else {
            showError(message: "Заполните все поля корректно")
            return
        }

        // Route to appropriate login flow
        if loginType == .email {
            await signInWithEmail()
        } else {
            await signInWithPhone()
        }
    }

    // MARK: - Email Login Flow

    private func signInWithEmail() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Email login - direct authentication (no OTP for MVP)
            _ = try await authManager.signIn(email: email, password: password)
            HapticsService.shared.success()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        } catch {
            showError(message: "Произошла ошибка. Попробуйте снова.")
            HapticsService.shared.warning()
        }
    }

    // MARK: - Phone Login Flow

    private func signInWithPhone() async {
        isLoading = true
        defer { isLoading = false }

        let identifier = "+7\(phone)"

        do {
            // Mock: Verify phone and password exist
            // In production: Backend would verify and send OTP
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // Check if user exists with this phone
            let userKey = "user_\(identifier)"
            guard UserDefaults.standard.data(forKey: userKey) != nil else {
                throw AuthError.userNotFound
            }

            // Credentials are valid, show OTP screen
            HapticsService.shared.success()
            showOTPVerification = true
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        } catch {
            showError(message: "Произошла ошибка. Попробуйте снова.")
            HapticsService.shared.warning()
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

    func signInWithBiometrics() async {
        guard canUseBiometrics() else {
            showError(message: "Биометрическая аутентификация недоступна")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await authManager.signInWithBiometrics()
            HapticsService.shared.success()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        } catch {
            showError(message: "Ошибка биометрической аутентификации")
            HapticsService.shared.warning()
        }
    }

    func getBiometricType() -> BiometricType {
        return biometricService.biometricType()
    }

    // MARK: - Google Sign-In

    func signInWithGoogle() async {
        HapticsService.shared.impactMedium()
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

            _ = try await authManager.signInWithGoogle(credentials: mockCredentials)
            HapticsService.shared.success()
        } catch let error as AuthError {
            showError(message: error.localizedDescription)
            HapticsService.shared.warning()
        } catch {
            showError(message: "Ошибка входа через Google")
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
            // Clear all form fields when switching between email and phone
            // This ensures no mixed data between the two separate flows
            email = ""
            phone = ""
            password = ""
            // Note: showPassword state is preserved for UX consistency

            loginType = newType
            HapticsService.shared.impactLight()
        }
    }
}
