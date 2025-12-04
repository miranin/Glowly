//
//  VerifyEmailRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for email verification
struct VerifyEmailRequest: Encodable {
    let token: String

    init(token: String) {
        self.token = token
    }
}
