//
//  LoginView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    @State private var showPrivacyPolicy = false

    nonisolated init(authManager: any AuthManagerProtocol) {
        _viewModel = StateObject(wrappedValue: LoginViewModel(authManager: authManager))
    }

    init() {
        self.init(authManager: AuthManager())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer().frame(height: 60)
                        
                        // Title
                        titleSection
                        
                        // Segmented Control
                        segmentedControl
                        
                        // Form
                        formSection
                        
                        // Forgot Password
                        forgotPasswordButton
                        
                        // Login Button
                        loginButton
                        
                        // Terms
                        termsSection
                        
                        Spacer().frame(height: 60)
                        
                        // Registration
                        registrationSection
                        
                        // Social Sign In
                        socialSignInSection
                    }
                }
                .dismissKeyboardOnTap()
            }
            .sheet(isPresented: $viewModel.showForgotPassword) {
                ForgotPasswordView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .background(
                NavigationLink(
                    destination: OTPVerificationView(
                        contactInfo: viewModel.loginType == .email ? viewModel.email : "+7\(viewModel.phone)",
                        verificationType: viewModel.loginType == .email ? .email : .sms,
                        onSuccess: {
                            // OTP verified successfully - now authenticate
                            Task {
                                let identifier = viewModel.loginType == .email ? viewModel.email : "+7\(viewModel.phone)"
                                do {
                                    _ = try await viewModel.authManager.signIn(email: identifier, password: viewModel.password)
                                    // Authentication successful - ContentView will handle navigation
                                    print("✅ Authentication successful, isAuthenticated = \(viewModel.authManager.isAuthenticated)")
                                } catch {
                                    print("❌ Authentication error: \(error)")
                                    // If auth fails, go back to login
                                    await MainActor.run {
                                        viewModel.showOTPVerification = false
                                        viewModel.showError = true
                                        viewModel.errorMessage = "Ошибка аутентификации"
                                    }
                                }
                            }
                        }
                    ),
                    isActive: $viewModel.showOTPVerification
                ) {
                    EmptyView()
                }
            )
        }
        .bottomSheetError(
            isPresented: $viewModel.showError,
            title: "ошибка",
            message: viewModel.errorMessage ?? "",
            buttonTitle: "понятно",
            action: { viewModel.clearError() }
        )
        .onChange(of: viewModel.authManager.isAuthenticated) { _, isAuthenticated in
            // When authentication succeeds, reset navigation state
            if isAuthenticated {
                print("🎉 Authentication detected in LoginView, resetting OTP state")
                viewModel.showOTPVerification = false
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("вход 👋")
                .font(.system(size: 32, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("введите почту и пароль, чтобы войти\nв приложение")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        Picker("", selection: $viewModel.loginType) {
            Text("Email").tag(LoginViewModel.LoginType.email)
            Text("Телефон").tag(LoginViewModel.LoginType.phone)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 24)
        .onChange(of: viewModel.loginType) { _, newValue in
            viewModel.handleLoginTypeChange(newValue)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Email or Phone Input
            if viewModel.loginType == .email {
                emailInputField
            } else {
                phoneInputField
            }
            
            // Password Input
            passwordInputField
        }
        .padding(.horizontal, 24)
    }
    
    private var emailInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("e-mail", text: $viewModel.email)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.emailBorderColor(), lineWidth: !viewModel.email.isEmpty ? 2 : 0)
                )
            
            if !viewModel.email.isEmpty && !viewModel.isValidEmail(viewModel.email) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("неверный формат email")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var phoneInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("+7")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .padding(.leading, 4)
                
                TextField("700 123 45 67", text: $viewModel.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .onChange(of: viewModel.phone) { _, newValue in
                        viewModel.handlePhoneInput(newValue)
                        viewModel.phone = viewModel.formatPhone(viewModel.phone)
                    }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.phoneBorderColor(), lineWidth: !viewModel.phone.isEmpty ? 2 : 0)
            )
            
            if !viewModel.phone.isEmpty && !viewModel.isValidPhone(viewModel.phone) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    Text("введите 10 цифр номера")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private var passwordInputField: some View {
        HStack {
            if viewModel.showPassword {
                TextField("пароль", text: $viewModel.password)
                    .textContentType(.password)
            } else {
                SecureField("пароль", text: $viewModel.password)
                    .textContentType(.password)
            }
            
            Button {
                viewModel.togglePasswordVisibility()
            } label: {
                Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Forgot Password Button
    private var forgotPasswordButton: some View {
        Button {
            viewModel.showForgotPassword = true
        } label: {
            Text("забыли пароль?")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Login Button
    private var loginButton: some View {
        Button {
            Task { await viewModel.signIn() }
        } label: {
            Text(viewModel.isLoading ? "" : "войти")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.isFormValid() ? Theme.accent : Color.gray)
                .cornerRadius(26)
                .overlay {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    }
                }
        }
        .disabled(viewModel.isLoading || !viewModel.isFormValid())
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    // MARK: - Terms Section
    private var termsSection: some View {
        Button {
            showPrivacyPolicy = true
        } label: {
            (Text("нажимая кнопку \"войти\", вы принимаете\nусловия ")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            + Text("политики конфиденциальности")
                .font(.system(size: 12))
                .foregroundColor(Theme.accent))
            .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Registration Section
    private var registrationSection: some View {
        HStack(spacing: 4) {
            Text("нет аккаунта?")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            NavigationLink(destination: RegistrationView(authManager: viewModel.authManager)) {
                Text("зарегистрируйтесь")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.accent)
            }
        }
    }
    
    // MARK: - Social Sign In Section
    private var socialSignInSection: some View {
        HStack(spacing: 16) {
            Button {
                // Apple Sign In - TODO
            } label: {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGray6))
                    .cornerRadius(28)
            }
            
            Button {
                Task { await viewModel.signInWithGoogle() }
            } label: {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGray6))
                    .cornerRadius(28)
            }
        }
        .padding(.top, 8)
    }
}

#Preview {
    LoginView()
}

