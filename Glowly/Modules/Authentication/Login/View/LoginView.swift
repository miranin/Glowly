//
//  LoginView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import SwiftUI

struct LoginView: View {
    // MARK: - Dependencies (Injected)
    @StateObject private var authManager: AuthManager
    @StateObject private var presenter: LoginPresenter
    @State private var showPassword: Bool = false
    @State private var showRegistration: Bool = false
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(authManager: AuthManager = AuthManager()) {
        let manager = authManager
        _authManager = StateObject(wrappedValue: manager)
        _presenter = StateObject(wrappedValue: LoginPresenter(authManager: manager))
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
                        // Logo and Title
                        logoSection
                        
                        // Email/Password Form
                        loginFormSection
                        
                        // Sign In Button
                        signInButton
                        
                        // Biometric Login (if enabled) - Below main login
                        if presenter.canUseBiometrics() {
                            biometricSection
                        }
                        
                        // Forgot Password
                        forgotPasswordButton
                        
                        // Divider
                        dividerSection
                        
                        // Google Sign In
                        googleSignInButton
                        
                        // Sign Up Link
                        signUpSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 40)
                }
            }
            .navigationBarHidden(true)
            .dismissKeyboardOnTap()
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
        }
        .alert("Ошибка", isPresented: $presenter.showError) {
            Button("OK", role: .cancel) {
                presenter.clearError()
            }
        } message: {
            Text(presenter.errorMessage ?? "Неизвестная ошибка")
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.accent.opacity(0.2), Theme.accentDark.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 20)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.accent, Theme.accentDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(height: 100)
            
            Text("Добро пожаловать")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Theme.textPrimary)
            
            Text("Войдите в свой аккаунт")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
        }
    }
    
    // MARK: - Biometric Section
    
    private var biometricSection: some View {
        Button(action: { authenticateWithBiometrics() }) {
            HStack(spacing: 12) {
                Image(systemName: presenter.getBiometricType().iconName)
                    .font(.title2)
                Text("Войти с \(presenter.getBiometricType().displayName)")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Theme.info, Theme.info.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Theme.info.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(presenter.isLoading)
    }
    
    // MARK: - Login Form
    
    private var loginFormSection: some View {
        VStack(spacing: 16) {
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
                        TextField("••••••••", text: $presenter.password)
                            .textContentType(.password)
                            .foregroundColor(Theme.textPrimary)
                    } else {
                        SecureField("••••••••", text: $presenter.password)
                            .textContentType(.password)
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
                        .stroke(Theme.neutralLight, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Sign In Button
    
    private var signInButton: some View {
        Button(action: { signIn() }) {
            HStack(spacing: 8) {
                if presenter.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                    Text("Войти")
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
        .disabled(presenter.isLoading || !presenter.isFormValid())
        .opacity((presenter.isLoading || !presenter.isFormValid()) ? 0.6 : 1.0)
    }
    
    // MARK: - Forgot Password
    
    private var forgotPasswordButton: some View {
        Button(action: { /* Handle forgot password */ }) {
            Text("Забыли пароль?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Theme.accent)
        }
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
    
    // MARK: - Google Sign In
    
    private var googleSignInButton: some View {
        Button(action: { signInWithGoogle() }) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.title2)
                Text("Войти через Google")
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
    
    // MARK: - Sign Up Section
    
    private var signUpSection: some View {
        HStack(spacing: 4) {
            Text("Нет аккаунта?")
                .font(.subheadline)
                .foregroundColor(Theme.textSecondary)
            
            Button(action: { showRegistration = true }) {
                Text("Зарегистрироваться")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.accent)
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Actions (Async/Await)
    
    private func signIn() {
        HapticsService.shared.impactMedium()
        
        Task {
            _ = await presenter.signIn()
            // Navigation handled by AuthManager state
        }
    }
    
    private func authenticateWithBiometrics() {
        HapticsService.shared.impactMedium()
        
        Task {
            _ = await presenter.signInWithBiometrics()
            // Navigation handled by AuthManager state
        }
    }
    
    private func signInWithGoogle() {
        HapticsService.shared.impactMedium()
        
        Task {
            _ = await presenter.signInWithGoogle()
            // Navigation handled by AuthManager state
        }
    }
    
}

#Preview {
    LoginView()
}

