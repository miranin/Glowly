//
//  AuthEndpoints.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

// MARK: - Authentication Endpoints
enum AuthEndpoints: APIEndpoint {
    case login(email: String, password: String)
    case register(email: String, password: String, name: String?)
    case logout
    case refreshToken(refreshToken: String)
    case forgotPassword(email: String)
    case resetPassword(token: String, newPassword: String)
    case verifyEmail(token: String)
    
    var path: String {
        switch self {
        case .login:
            return "/auth/login"
        case .register:
            return "/auth/register"
        case .logout:
            return "/auth/logout"
        case .refreshToken:
            return "/auth/refresh"
        case .forgotPassword:
            return "/auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"
        case .verifyEmail:
            return "/auth/verify-email"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .login, .register, .logout, .refreshToken, .forgotPassword, .resetPassword, .verifyEmail:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .login(let email, let password):
            return LoginRequest(email: email, password: password)
        case .register(let email, let password, let name):
            return RegisterRequest(email: email, password: password, name: name)
        case .refreshToken(let refreshToken):
            return RefreshTokenRequest(refreshToken: refreshToken)
        case .forgotPassword(let email):
            return ForgotPasswordRequest(email: email)
        case .resetPassword(let token, let newPassword):
            return ResetPasswordRequest(token: token, newPassword: newPassword)
        case .verifyEmail(let token):
            return VerifyEmailRequest(token: token)
        case .logout:
            return nil
        }
    }
}

// MARK: - Request Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let name: String?
}

struct RefreshTokenRequest: Encodable {
    let refreshToken: String
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String
}

struct VerifyEmailRequest: Encodable {
    let token: String
}

// MARK: - Response Models

struct AuthResponse: Decodable {
    let user: UserResponse
    let token: String
    let refreshToken: String
}

struct UserResponse: Decodable {
    let id: String
    let email: String
    let name: String?
    let profilePhotoURL: String?
    let createdAt: Date
    let lastLoginAt: Date
}

struct RefreshTokenResponse: Decodable {
    let token: String
    let refreshToken: String
}

struct MessageResponse: Decodable {
    let message: String
}

