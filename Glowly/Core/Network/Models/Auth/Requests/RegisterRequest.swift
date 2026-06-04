//
//  RegisterRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for user registration (email-only)
struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let password: String
    let valid: Bool

    init(
        username: String,
        email: String,
        password: String,
        valid: Bool = true
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.valid = valid
    }
}
