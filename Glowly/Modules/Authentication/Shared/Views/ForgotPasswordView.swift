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
        .overlay(alignment: .bottom) {
            if showError {
                ErrorToast(message: errorMessage) {
                    showError = false
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            if showSuccess {
                SuccessToast(message: "Проверьте почту") {
                    showSuccess = false
                    dismiss()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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

// MARK: - Success Toast
struct SuccessToast: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("успешно")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            Divider()
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
        }
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -5)
        .padding(.bottom, 20)
        .onAppear {
            HapticsService.shared.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    onDismiss()
                }
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}

