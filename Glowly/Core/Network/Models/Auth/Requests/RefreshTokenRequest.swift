//
//  RefreshTokenRequest.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Request model for refreshing access token
struct RefreshTokenRequest: Encodable {
    let refreshToken: String

    init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
