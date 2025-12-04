//
//  RefreshTokenResponse.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Response model for token refresh
struct RefreshTokenResponse: Decodable {
    let token: String
    let refreshToken: String
}
