//
//  LoginRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for user login
struct LoginRequest: Encodable {
    let usernameOrEmail: String
    let password: String

    init(usernameOrEmail: String, password: String) {
        self.usernameOrEmail = usernameOrEmail
        self.password = password
    }
}
