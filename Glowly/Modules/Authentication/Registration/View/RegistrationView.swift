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
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name, email, phone, password, confirmPassword
    }

    nonisolated init(authManager: any AuthManagerProtocol) {
        _viewModel = StateObject(wrappedValue: RegistrationViewModel(authManager: authManager))
    }

    init() {
        self.init(authManager: AuthManager())
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollViewReader { proxy in
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
                        // OTP verified successfully - now authenticate the user
                        Task {
                            let identifier = viewModel.registrationType == .email ? viewModel.email : "+7\(viewModel.phone)"
                            do {
                                let loginRequest = LoginRequest(usernameOrEmail: identifier, password: viewModel.password)
                                _ = try await viewModel.authManager.signIn(loginRequest)
                                // Authentication successful - ContentView will handle navigation
                                print("✅ Authentication successful, isAuthenticated = \(viewModel.authManager.isAuthenticated)")
                            } catch {
                                print("❌ Authentication error: \(error)")
                                // If auth fails, go back to registration
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
                print("🎉 Authentication detected in RegistrationView, resetting OTP state")
                viewModel.showOTPVerification = false
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
        HStack {
            TextField("имя", text: $viewModel.name)
                .textContentType(.name)
                .autocapitalization(.words)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onSubmit {
                    if !viewModel.name.isEmpty {
                        focusedField = viewModel.registrationType == .email ? .email : .phone
                    }
                }

            // Clear button (only show when focused)
            if !viewModel.name.isEmpty && focusedField == .name {
                Button(action: {
                    viewModel.name = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .id(Field.name)
    }
    
    private var emailInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("e-mail", text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        if viewModel.isValidEmail(viewModel.email) {
                            focusedField = .password
                        }
                    }

                // Clear button (only show when focused)
                if !viewModel.email.isEmpty && focusedField == .email {
                    Button(action: {
                        viewModel.email = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.emailBorderColor(), lineWidth: !viewModel.email.isEmpty ? 2 : 0)
            )
            .id(Field.email)
            
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
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .phone)
                    .onChange(of: viewModel.phone) { _, newValue in
                        viewModel.handlePhoneInput(newValue)
                        viewModel.phone = viewModel.formatPhone(viewModel.phone)

                        // Auto-move when phone is complete (10 digits)
                        if viewModel.isValidPhone(viewModel.phone) {
                            focusedField = .password
                        }
                    }

                // Clear button (only show when focused)
                if !viewModel.phone.isEmpty && focusedField == .phone {
                    Button(action: {
                        viewModel.phone = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(viewModel.phoneBorderColor(), lineWidth: !viewModel.phone.isEmpty ? 2 : 0)
            )
            .id(Field.phone)
            
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
                        .focused($focusedField, equals: .password)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .submitLabel(.next)
                        .onSubmit {
                            if viewModel.calculatePasswordStrength() >= 3 {
                                focusedField = .confirmPassword
                            }
                        }
                } else {
                    SecureField("пароль (минимум 8 символов)", text: $viewModel.password)
                        .focused($focusedField, equals: .password)
                        .textContentType(.newPassword)
                        .submitLabel(.next)
                        .onSubmit {
                            if viewModel.calculatePasswordStrength() >= 3 {
                                focusedField = .confirmPassword
                            }
                        }
                }

                // Clear button (only show when focused)
                if !viewModel.password.isEmpty && focusedField == .password {
                    Button(action: {
                        viewModel.password = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    // Store if this field was focused
                    let wasFocused = focusedField == .password
                    viewModel.togglePasswordVisibility()
                    // Restore focus after toggle
                    if wasFocused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .password
                        }
                    }
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
            .id(Field.password)
            
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
                        .focused($focusedField, equals: .confirmPassword)
                        .textContentType(.newPassword)
                        .autocapitalization(.none)
                        .submitLabel(.done)
                        .onSubmit {
                            if viewModel.passwordsMatch() {
                                focusedField = nil // Dismiss keyboard
                            }
                        }
                } else {
                    SecureField("подтвердите пароль", text: $viewModel.confirmPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .textContentType(.newPassword)
                        .submitLabel(.done)
                        .onSubmit {
                            if viewModel.passwordsMatch() {
                                focusedField = nil // Dismiss keyboard
                            }
                        }
                }

                // Clear button (only show when focused)
                if !viewModel.confirmPassword.isEmpty && focusedField == .confirmPassword {
                    Button(action: {
                        viewModel.confirmPassword = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    // Store if this field was focused
                    let wasFocused = focusedField == .confirmPassword
                    viewModel.toggleConfirmPasswordVisibility()
                    // Restore focus after toggle
                    if wasFocused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedField = .confirmPassword
                        }
                    }
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
            .id(Field.confirmPassword)
            
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

