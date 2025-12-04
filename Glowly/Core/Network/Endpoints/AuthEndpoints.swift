//
//  AuthEndpoints.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

// MARK: - Authentication Endpoints

/// Defines all authentication-related API endpoints
enum AuthEndpoints: APIEndpoint {
    case login(LoginRequest)
    case register(RegisterRequest)
    case logout
    case refreshToken(RefreshTokenRequest)
    case forgotPassword(ForgotPasswordRequest)
    case resetPassword(ResetPasswordRequest)
    case verifyEmail(VerifyEmailRequest)
    case verifyOtp(VerifyOtpRequest)
    case resendOtp(ResendOtpRequest)

    var path: String {
        switch self {
        case .login:
            return "/api/auth/login"
        case .register:
            return "/api/auth/register"
        case .logout:
            return "/api/auth/logout"
        case .refreshToken:
            return "/api/auth/refresh"
        case .forgotPassword:
            return "/api/auth/forgot-password"
        case .resetPassword:
            return "/api/auth/reset-password"
        case .verifyEmail:
            return "/api/auth/verify-email"
        case .verifyOtp:
            return "/api/auth/verify-otp"
        case .resendOtp:
            return "/api/auth/resend-otp"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .refreshToken, .forgotPassword, .resetPassword, .verifyEmail, .verifyOtp, .resendOtp:
            return .post
        }
    }

    var body: Encodable? {
        switch self {
        case .login(let request):
            return request
        case .register(let request):
            return request
        case .refreshToken(let request):
            return request
        case .forgotPassword(let request):
            return request
        case .resetPassword(let request):
            return request
        case .verifyEmail(let request):
            return request
        case .verifyOtp(let request):
            return request
        case .resendOtp(let request):
            return request
        case .logout:
            return nil
        }
    }
}

