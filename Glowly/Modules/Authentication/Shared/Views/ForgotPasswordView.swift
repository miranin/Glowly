//
//  ForgotPasswordView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        Spacer()
                            .frame(height: 60)
                        
                        // Title
                        VStack(spacing: 8) {
                            Text("восстановить\nпароль")
                                .font(.system(size: 32, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("введите почту — мы вышлем ссылку для\nвосстановления пароля")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 24)
                        
                        // Email Field
                        TextField("e-mail", text: $email)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                        
                        // Send Button
                        Button {
                            sendResetLink()
                        } label: {
                            Text(isLoading ? "" : "отправить")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Theme.accent)
                                .cornerRadius(26)
                                .overlay {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                        }
                        .disabled(isLoading || !isValidEmail())
                        .opacity(isValidEmail() ? 1.0 : 0.5)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // Back to login
                        HStack(spacing: 4) {
                            Text("я вспомнил пароль?")
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
                }
                .dismissKeyboardOnTap()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .bottomSheetError(
            isPresented: $showError,
            title: "ошибка",
            message: errorMessage,
            buttonTitle: "понятно",
            action: { showError = false }
        )
        .successNotice(
            isPresented: $showSuccess,
            message: "Проверьте почту. Мы отправили ссылку для восстановления пароля"
        )
    }
    
    private func isValidEmail() -> Bool {
        email.contains("@") && email.contains(".") && email.count > 5
    }
    
    private func sendResetLink() {
        guard isValidEmail() else { return }
        
        HapticsService.shared.impactMedium()
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            
            // Mock: в реальности проверяем существование email
            if email.contains("test") {
                withAnimation {
                    showSuccess = true
                }
            } else {
                errorMessage = "пользователь с таким email не найден"
                withAnimation {
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}

