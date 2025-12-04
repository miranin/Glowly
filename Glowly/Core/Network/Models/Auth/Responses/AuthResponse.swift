//
//  AuthResponse.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Response model for authentication (login/register)
struct AuthResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let username: String
    let email: String
    let roles: [String]
}

// MARK: - Conversion to User Model

extension AuthResponse {
    /// Converts AuthResponse to User model for app usage
    /// - Parameter authProvider: The authentication provider used
    /// - Returns: User model instance
    func toUser(authProvider: User.AuthProvider = .email) -> User {
        return User(
            id: UUID().uuidString, // Backend doesn't return user ID, generate one
            email: email,
            name: username,
            profilePhotoURL: nil,
            authProvider: authProvider,
            createdAt: Date(),
            lastLoginAt: Date(),
            isPremium: false // Default to non-premium
        )
    }
}
