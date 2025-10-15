//
//  OTPVerificationView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct OTPVerificationView: View {
    let contactInfo: String
    let verificationType: VerificationType
    let onSuccess: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var otpCode = ["", "", "", "", "", ""]
    @State private var isVerifying = false
    @State private var canResend = false
    @State private var countdown = 60
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @FocusState private var focusedField: Int?
    
    enum VerificationType {
        case email
        case sms
        
        var title: String {
            switch self {
            case .email: return "проверьте почту"
            case .sms: return "проверьте SMS"
            }
        }
        
        var description: String {
            switch self {
            case .email: return "мы выслали код на вашу почту для\nподтверждения регистрации"
            case .sms: return "мы выслали код на ваш номер для\nподтверждения регистрации"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text(verificationType.title)
                            .font(.system(size: 32, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(verificationType.description)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(contactInfo)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Theme.accent)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 24)
                    
                    // OTP Input
                    HStack(spacing: 12) {
                        ForEach(0..<6, id: \.self) { index in
                            OTPDigitField(
                                digit: $otpCode[index],
                                isFocused: focusedField == index
                            )
                            .focused($focusedField, equals: index)
                            .onChange(of: otpCode[index]) { oldValue, newValue in
                                handleOTPChange(index: index, oldValue: oldValue, newValue: newValue)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Resend Code
                    HStack(spacing: 4) {
                        Text("не получили код?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        if canResend {
                            Button {
                                resendCode()
                            } label: {
                                Text("отправить еще раз")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Theme.accent)
                            }
                        } else {
                            Text("(\(countdown)с)")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Auto-fill hint (appears above keyboard)
                if focusedField != nil {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "envelope.badge.fill")
                                    .foregroundColor(Theme.accent)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Код из \(verificationType == .email ? "почты" : "SMS")")
                                        .font(.system(size: 13, weight: .medium))
                                    
                                    Text("123456")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Theme.accent)
                                }
                                
                                Spacer()
                                
                                Button {
                                    autoFillCode("123456")
                                } label: {
                                    Text("вставить")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                        }
                        .padding()
                        .padding(.bottom, 20)
                    }
                    .transition(.move(edge: .bottom))
                }
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
        .onAppear {
            startCountdown()
            focusedField = 0
        }
        .overlay(alignment: .bottom) {
            if showError {
                ErrorToast(message: errorMessage) {
                    withAnimation {
                        showError = false
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .center) {
            if showSuccess {
                SuccessOverlay()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Success Overlay
    struct SuccessOverlay: View {
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("успешно!")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.2), radius: 20)
            )
        }
    }
    
    // MARK: - OTP Logic
    
    private func handleOTPChange(index: Int, oldValue: String, newValue: String) {
        // Only allow single digit
        if newValue.count > 1 {
            otpCode[index] = String(newValue.last!)
        }
        
        // Move to next field
        if !newValue.isEmpty && index < 5 {
            focusedField = index + 1
        }
        
        // Auto-verify when all digits entered
        if index == 5 && !newValue.isEmpty {
            verifyOTP()
        }
    }
    
    private func autoFillCode(_ code: String) {
        let digits = Array(code.prefix(6))
        for (index, digit) in digits.enumerated() {
            otpCode[index] = String(digit)
        }
        focusedField = nil
        
        // Auto-verify
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            verifyOTP()
        }
    }
    
    private func verifyOTP() {
        let code = otpCode.joined()
        guard code.count == 6 else { return }
        
        isVerifying = true
        HapticsService.shared.impactMedium()
        
        // Simulate API verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isVerifying = false
            
            // Mock: check if code is correct
            if code == "123456" {
                HapticsService.shared.success()
                withAnimation {
                    showSuccess = true
                }
                
                // Call success callback after short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onSuccess()
                }
            } else {
                errorMessage = "неверный код подтверждения"
                withAnimation {
                    showError = true
                }
                // Clear code
                otpCode = ["", "", "", "", "", ""]
                focusedField = 0
            }
        }
    }
    
    private func resendCode() {
        HapticsService.shared.impactMedium()
        canResend = false
        countdown = 60
        startCountdown()
        
        // Simulate API call
        // TODO: Implement actual resend logic
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 0 {
                countdown -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - OTP Digit Field
struct OTPDigitField: View {
    @Binding var digit: String
    let isFocused: Bool
    
    var body: some View {
        TextField("", text: $digit)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.system(size: 24, weight: .semibold))
            .frame(width: 48, height: 56)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Theme.accent : Color.clear, lineWidth: 2)
            )
    }
}

#Preview {
    OTPVerificationView(
        contactInfo: "yukiko@uprock.pro",
        verificationType: .email,
        onSuccess: {}
    )
}

