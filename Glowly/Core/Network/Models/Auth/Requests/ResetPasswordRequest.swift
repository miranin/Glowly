//
//  ResetPasswordRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for resetting password
struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String

    init(token: String, newPassword: String) {
        self.token = token
        self.newPassword = newPassword
    }
}
