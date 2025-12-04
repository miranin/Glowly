//
//  VerifyOtpRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for OTP verification
struct VerifyOtpRequest: Encodable {
    let identifier: String
    let otpCode: String

    init(identifier: String, otpCode: String) {
        self.identifier = identifier
        self.otpCode = otpCode
    }
}
