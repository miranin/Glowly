//
//  ResendOtpRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for resending OTP code
struct ResendOtpRequest: Encodable {
    let identifier: String

    init(identifier: String) {
        self.identifier = identifier
    }
}
