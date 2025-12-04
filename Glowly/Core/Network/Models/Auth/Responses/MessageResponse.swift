//
//  MessageResponse.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 27/10/25.
//

import Foundation

/// Generic response model for simple message responses
struct MessageResponse: Decodable {
    let message: String
}
