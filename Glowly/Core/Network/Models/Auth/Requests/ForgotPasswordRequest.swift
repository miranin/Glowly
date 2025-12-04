//
//  ForgotPasswordRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for forgot password
struct ForgotPasswordRequest: Encodable {
    let email: String

    init(email: String) {
        self.email = email
    }
}
