//
//  User.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    var email: String
    var name: String?
    var profilePhotoURL: String?
    var authProvider: AuthProvider
    var createdAt: Date
    var lastLoginAt: Date
    
    enum AuthProvider: String, Codable {
        case email
        case google
        case apple
    }
}

struct AuthCredentials {
    let email: String
    let password: String
}

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}

struct GoogleAuthCredentials {
    let idToken: String
    let email: String
    let name: String?
    let profileImageURL: String?
}

