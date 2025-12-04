//
//  RegisterRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for user registration
struct RegisterRequest: Encodable {
    let username: String
    let email: String
    let phoneNumber: String
    let password: String
    let valid: Bool

    init(
        username: String,
        email: String,
        phoneNumber: String,
        password: String,
        valid: Bool = true
    ) {
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.password = password
        self.valid = valid
    }
}
