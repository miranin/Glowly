//
//  UserResponse.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Response model for user data
struct UserResponse: Decodable {
    let id: String
    let email: String
    let name: String?
    let profilePhotoURL: String?
    let createdAt: Date
    let lastLoginAt: Date
    let isPremium: Bool?
}

// MARK: - Conversion to User Model

extension UserResponse {
    /// Converts UserResponse to User model for app usage
    /// - Parameter authProvider: The authentication provider used
    /// - Returns: User model instance
    func toUser(authProvider: User.AuthProvider = .email) -> User {
        return User(
            id: id,
            email: email,
            name: name,
            profilePhotoURL: profilePhotoURL,
            authProvider: authProvider,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt,
            isPremium: isPremium ?? false
        )
    }
}
