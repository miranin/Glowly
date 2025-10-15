//
//  RegistrationView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct RegistrationView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel: RegistrationViewModel
    @State private var showPrivacyPolicy = false
    
    nonisolated init(authManager: AuthManager = AuthManager()) {
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(authManager: authManager))
    }
    
    var body: some View {
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
                    
                    // Register Button
                    registerButton
                    
                    // Terms
                    termsSection
                    
                    Spacer().frame(height: 60)
                    
                    // Login
                    loginSection
                    
                    // Social Sign Up
                    socialSignUpSection
                }
            }
            .dismissKeyboardOnTap()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false) // System back button only
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .background(
            NavigationLink(
                destination: OTPVerificationView(
                    contactInfo: viewModel.registrationType == .email ? viewModel.email : "+7\(viewModel.phone)",
                    verificationType: viewModel.registrationType == .email ? .email : .sms,
                    onSuccess: {
                        // OTP verified successfully
                    }
                ),
                isActive: $viewModel.showOTPVerification
            ) {
                EmptyView()
            }
        )
        .overlay(alignment: .bottom) {
            if viewModel.showError, let error = viewModel.errorMessage {
                ErrorToast(message: error) {
                    viewModel.clearError()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("регистрация 🎉")
                .font(.system(size: 32, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("создайте аккаунт, чтобы начать\nиспользовать приложение")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Segmented Control
    private var segmentedControl: some View {
        Picker("", selection: $viewModel.registrationType) {
            Text("Email").tag(RegistrationViewModel.RegistrationType.email)
            Text("Телефон").tag(RegistrationViewModel.RegistrationType.phone)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 24)
        .onChange(of: viewModel.registrationType) { _, newValue in
            viewModel.handleRegistrationTypeChange(newValue)
        }
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 16) {
            // Name
            nameInputField
            
            // Email or Phone
            if viewModel.registrationType == .email {
                emailInputField
            } else {
                phoneInputField
            }
            
            // Password
            passwordInputField
            
            // Confirm Password
            confirmPasswordInputField
        }
        .padding(.horizontal, 24)
    }
    
    private var nameInputField: some View {
        TextField("имя", text: $viewModel.name)
            .textContentType(.name)
            .autocapitalization(.words)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if viewModel.showPassword {
                    TextField("пароль (минимум 8 символов)", text: $viewModel.password)
                } else {
                    SecureField("пароль (минимум 8 символов)", text: $viewModel.password)
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
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.passwordBorderColor(), lineWidth: !viewModel.password.isEmpty ? 2 : 0)
            )
            
            if !viewModel.password.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.passwordStrengthIcon())
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.passwordStrengthColor())
                    Text(viewModel.passwordStrengthText())
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.passwordStrengthColor())
                }
            }
        }
    }
    
    private var confirmPasswordInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if viewModel.showConfirmPassword {
                    TextField("подтвердите пароль", text: $viewModel.confirmPassword)
                } else {
                    SecureField("подтвердите пароль", text: $viewModel.confirmPassword)
                }
                
                Button {
                    viewModel.toggleConfirmPasswordVisibility()
                } label: {
                    Image(systemName: viewModel.showConfirmPassword ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.confirmPasswordBorderColor(), lineWidth: !viewModel.confirmPassword.isEmpty ? 2 : 0)
            )
            
            if !viewModel.confirmPassword.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: viewModel.passwordsMatch() ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.passwordsMatch() ? .green : .red)
                    Text(viewModel.passwordsMatch() ? "пароли совпадают" : "пароли не совпадают")
                        .font(.system(size: 12))
                        .foregroundColor(viewModel.passwordsMatch() ? .green : .red)
                }
            }
        }
    }
    
    // MARK: - Register Button
    private var registerButton: some View {
        Button {
            Task { await viewModel.signUp() }
        } label: {
            Text(viewModel.isLoading ? "" : "зарегистрироваться")
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
            (Text("нажимая кнопку \"зарегистрироваться\", вы принимаете условия ")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            + Text("политики конфиденциальности")
                .font(.system(size: 12))
                .foregroundColor(Theme.accent))
            .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Login Section
    private var loginSection: some View {
        HStack(spacing: 4) {
            Text("уже есть аккаунт?")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
            
            Button {
                dismiss()
            } label: {
                Text("войти")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.accent)
            }
        }
    }
    
    // MARK: - Social Sign Up Section
    private var socialSignUpSection: some View {
        HStack(spacing: 16) {
            Button {
                // Apple Sign Up - TODO
            } label: {
                Image(systemName: "apple.logo")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                    .frame(width: 56, height: 56)
                    .background(Color(.systemGray6))
                    .cornerRadius(28)
            }
            
            Button {
                Task { await viewModel.signUpWithGoogle() }
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
    NavigationView {
        RegistrationView()
    }
}

