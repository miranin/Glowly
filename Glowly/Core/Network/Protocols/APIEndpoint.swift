//
//  APIEndpoint.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

/// Protocol defining an API endpoint
protocol APIEndpoint {
    /// The path component of the URL (e.g., "/auth/login")
    var path: String { get }
    
    /// HTTP method for the request
    var method: HTTPMethod { get }
    
    /// Query parameters (optional)
    var queryParameters: [String: String]? { get }
    
    /// HTTP headers (optional)
    var headers: [String: String]? { get }
    
    /// Request body (optional)
    var body: Encodable? { get }
    
    /// Timeout interval in seconds (default: 30)
    var timeoutInterval: TimeInterval { get }
}

// MARK: - Default Implementations
extension APIEndpoint {
    var queryParameters: [String: String]? { nil }
    var headers: [String: String]? { nil }
    var body: Encodable? { nil }
    var timeoutInterval: TimeInterval { 30 }
}

