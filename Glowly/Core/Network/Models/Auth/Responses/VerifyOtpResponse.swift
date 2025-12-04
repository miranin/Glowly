//
//  VerifyOtpResponse.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Response model for OTP verification
struct VerifyOtpResponse: Decodable {
    let message: String
    let verified: Bool
    let identifier: String
}
