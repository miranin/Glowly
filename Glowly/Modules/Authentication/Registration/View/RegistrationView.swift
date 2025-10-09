//
//  RegistrationView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    // MARK: - Dependencies (Injected)
    @StateObject private var authManager: AuthManager
    @StateObject private var presenter: RegistrationPresenter
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(authManager: AuthManager = AuthManager()) {
        let manager = authManager
        _authManager = StateObject(wrappedValue: manager)
        _presenter = StateObject(wrappedValue: RegistrationPresenter(authManager: manager))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Theme.backgroundPowder, Theme.accentLight.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Registration Form
                        registrationFormSection
                        
                        // Terms
                        termsSection
                        
                        // Sign Up Button
                        signUpButton
                        
                        // Divider
                        dividerSection
                        
                        // Google Sign Up
                        googleSignUpButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textPrimary)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 32)
                            .background(Theme.backgroundCard)
                            .clipShape(Circle())
                    }
                }
            }
            .dismissKeyboardOnTap()
        }
        .alert("Ошибка", isPresented: $presenter.showError) {
            Button("OK", role: .cancel) {
                presenter.clearError()
            }
        } message: {
            Text(presenter.errorMessage ?? "Неизвестная ошибка")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Создать аккаунт")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            Text("Присоединяйтесь к Glowly")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Registration Form
    
    private var registrationFormSection: some View {
        VStack(spacing: 16) {
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Имя")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(Theme.accent)
                        .frame(width: 20)
                    
                    TextField("Ваше имя", text: $presenter.name)
                        .textContentType(.name)
                        .autocapitalization(.words)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(16)
                .background(Theme.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.neutralLight, lineWidth: 1)
                )
            }
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Theme.accent)
                        .frame(width: 20)
                    
                    TextField("example@mail.com", text: $presenter.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .foregroundColor(Theme.textPrimary)
                }
                .padding(16)
                .background(Theme.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.neutralLight, lineWidth: 1)
                )
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Пароль")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Theme.accent)
                        .frame(width: 20)
                    
                    if showPassword {
                        TextField("Минимум 8 символов", text: $presenter.password)
                            .textContentType(.newPassword)
                            .foregroundColor(Theme.textPrimary)
                    } else {
                        SecureField("Минимум 8 символов", text: $presenter.password)
                            .textContentType(.newPassword)
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(16)
                .background(Theme.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(passwordStrengthColor(), lineWidth: presenter.password.isEmpty ? 1 : 2)
                )
                
                // Password Strength
                if !presenter.password.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: passwordStrengthIcon())
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor())
                        Text(presenter.getPasswordStrengthText())
                            .font(.caption)
                            .foregroundColor(passwordStrengthColor())
                    }
                }
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Подтвердите пароль")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.textPrimary)
                
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(Theme.accent)
                        .frame(width: 20)
                    
                    if showConfirmPassword {
                        TextField("Повторите пароль", text: $presenter.confirmPassword)
                            .textContentType(.newPassword)
                            .foregroundColor(Theme.textPrimary)
                    } else {
                        SecureField("Повторите пароль", text: $presenter.confirmPassword)
                            .textContentType(.newPassword)
                            .foregroundColor(Theme.textPrimary)
                    }
                    
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(16)
                .background(Theme.backgroundCard)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(presenter.passwordsMatch() ? Theme.success : Theme.neutralLight, lineWidth: presenter.confirmPassword.isEmpty ? 1 : 2)
                )
                
                // Password Match Indicator
                if !presenter.confirmPassword.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: presenter.passwordsMatch() ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(presenter.passwordsMatch() ? Theme.success : Theme.danger)
                        Text(presenter.passwordsMatch() ? "Пароли совпадают" : "Пароли не совпадают")
                            .font(.caption)
                            .foregroundColor(presenter.passwordsMatch() ? Theme.success : Theme.danger)
                    }
                }
            }
        }
    }
    
    // MARK: - Terms
    
    private var termsSection: some View {
        Button(action: { presenter.agreedToTerms.toggle() }) {
            HStack(spacing: 12) {
                Image(systemName: presenter.agreedToTerms ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(presenter.agreedToTerms ? Theme.accent : Theme.textSecondary)
                
                Text("Я согласен с ")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                +
                Text("условиями использования")
                    .font(.subheadline)
                    .foregroundColor(Theme.accent)
                +
                Text(" и ")
                    .font(.subheadline)
                    .foregroundColor(Theme.textSecondary)
                +
                Text("политикой конфиденциальности")
                    .font(.subheadline)
                    .foregroundColor(Theme.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Sign Up Button
    
    private var signUpButton: some View {
        Button(action: { signUp() }) {
            HStack(spacing: 8) {
                if presenter.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Зарегистрироваться")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Theme.accent, Theme.accentDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Theme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!presenter.isFormValid() || presenter.isLoading)
        .opacity(presenter.isFormValid() && !presenter.isLoading ? 1.0 : 0.6)
    }
    
    // MARK: - Divider
    
    private var dividerSection: some View {
        HStack(spacing: 16) {
            Rectangle()
                .fill(Theme.neutralLight)
                .frame(height: 1)
            
            Text("или")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Rectangle()
                .fill(Theme.neutralLight)
                .frame(height: 1)
        }
    }
    
    // MARK: - Google Sign Up
    
    private var googleSignUpButton: some View {
        Button(action: { signUpWithGoogle() }) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                Text("Зарегистрироваться через Google")
                    .fontWeight(.semibold)
            }
            .foregroundColor(Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.backgroundCard)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Theme.neutralLight, lineWidth: 1.5)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(presenter.isLoading)
    }
    
    // MARK: - Helper Methods
    
    private func passwordStrengthColor() -> Color {
        let strength = presenter.calculatePasswordStrength()
        switch strength {
        case 0...2: return Theme.danger
        case 3: return Theme.warning
        default: return Theme.success
        }
    }
    
    private func passwordStrengthIcon() -> String {
        let strength = presenter.calculatePasswordStrength()
        switch strength {
        case 0...2: return "xmark.circle.fill"
        case 3: return "exclamationmark.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
    
    // MARK: - Actions (Async/Await)
    
    private func signUp() {
        HapticsService.shared.impactMedium()
        
        Task {
            let result = await presenter.signUp()
            if case .success = result {
                dismiss()
            }
        }
    }
    
    private func signUpWithGoogle() {
        HapticsService.shared.impactMedium()
        
        Task {
            let result = await presenter.signUpWithGoogle()
            if case .success = result {
                dismiss()
            }
        }
    }
}

#Preview {
    RegistrationView()
}

