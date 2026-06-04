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
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    @Published var showOTPVerification: Bool = false
    @Published var agreedToTerms: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Dependencies (Injected)
    let authManager: any AuthManagerProtocol

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

        await signUpWithEmail()
    }

    // MARK: - Email Registration Flow (Email-only with OTP)

    private func signUpWithEmail() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Create registration request (email-only)
            let request = RegisterRequest(
                username: name.isEmpty ? email.components(separatedBy: "@").first ?? "user" : name,
                email: email,
                password: password,
                valid: true
            )

            // Email registration - authenticate with backend API
            _ = try await authManager.signUp(request)
            HapticsService.shared.success()
            // Show OTP verification - user will receive OTP via email
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
        // Email-only validation
        let hasValidEmail = isValidEmail(email)

        // Password must be at least medium strength (3+) or strong (4+)
        let hasStrongEnoughPassword = calculatePasswordStrength() >= 3

        return !name.isEmpty &&
               hasValidEmail &&
               !password.isEmpty &&
               !confirmPassword.isEmpty &&
               passwordsMatch() &&
               hasStrongEnoughPassword
    }

    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
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
}
