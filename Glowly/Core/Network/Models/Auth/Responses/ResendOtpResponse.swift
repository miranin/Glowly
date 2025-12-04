//
//  ResendOtpResponse.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Response model for resending OTP code
struct ResendOtpResponse: Decodable {
    let message: String
    let identifier: String
    let expiresIn: Int
    let maskedIdentifier: String
}
