//
//  NetworkError.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingFailed(Error)
    case encodingFailed(Error)
    case httpError(statusCode: Int, data: Data?)
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case timeout
    case noInternetConnection
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .unauthorized:
            return "Unauthorized. Please log in again"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .serverError:
            return "Server error. Please try again later"
        case .timeout:
            return "Request timed out. Please check your connection"
        case .noInternetConnection:
            return "No internet connection"
        case .unknown(let error):
            return "An error occurred: \(error.localizedDescription)"
        }
    }
    
    var isAuthenticationError: Bool {
        switch self {
        case .unauthorized, .forbidden:
            return true
        default:
            return false
        }
    }
    
    var shouldRetry: Bool {
        switch self {
        case .timeout, .noInternetConnection, .serverError:
            return true
        default:
            return false
        }
    }
}

