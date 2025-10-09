//
//  NetworkService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 09/10/25.
//

import Foundation

// MARK: - NetworkService Protocol for DI (Rule #2)
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
    func upload<T: Decodable>(_ endpoint: APIEndpoint, data: Data, fileName: String) async throws -> T
}

// MARK: - NetworkService Implementation
final class NetworkService: NetworkServiceProtocol {
    // MARK: - Dependencies (Injected - Rule #2)
    private let configuration: NetworkConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // MARK: - Initialization with Dependency Injection (Rule #2)
    init(
        configuration: NetworkConfiguration = .development,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.configuration = configuration
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        
        // Configure decoder for common date formats
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Configure encoder
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    // MARK: - Request with Response (Async/Await - Rule #3)
    
    /// Performs a network request and decodes the response
    /// - Parameter endpoint: The API endpoint to call
    /// - Returns: Decoded response of type T
    /// - Throws: NetworkError if request fails
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let urlRequest = try buildURLRequest(from: endpoint)
        
        if configuration.enableLogging {
            logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            if configuration.enableLogging {
                logResponse(data: data, response: response)
            }
            
            try validateResponse(response, data: data)
            
            do {
                let decodedResponse = try decoder.decode(T.self, from: data)
                return decodedResponse
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    // MARK: - Request without Response (Async/Await - Rule #3)
    
    /// Performs a network request without expecting a response body
    /// - Parameter endpoint: The API endpoint to call
    /// - Throws: NetworkError if request fails
    func request(_ endpoint: APIEndpoint) async throws {
        let urlRequest = try buildURLRequest(from: endpoint)
        
        if configuration.enableLogging {
            logRequest(urlRequest)
        }
        
        do {
            let (data, response) = try await session.data(for: urlRequest)
            
            if configuration.enableLogging {
                logResponse(data: data, response: response)
            }
            
            try validateResponse(response, data: data)
        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    // MARK: - Upload (Async/Await - Rule #3)
    
    /// Uploads data to the server
    /// - Parameters:
    ///   - endpoint: The API endpoint to call
    ///   - data: Data to upload
    ///   - fileName: Name of the file
    /// - Returns: Decoded response of type T
    /// - Throws: NetworkError if upload fails
    func upload<T: Decodable>(_ endpoint: APIEndpoint, data: Data, fileName: String) async throws -> T {
        let urlRequest = try buildMultipartURLRequest(from: endpoint, data: data, fileName: fileName)
        
        if configuration.enableLogging {
            logRequest(urlRequest)
        }
        
        do {
            let (responseData, response) = try await session.data(for: urlRequest)
            
            if configuration.enableLogging {
                logResponse(data: responseData, response: response)
            }
            
            try validateResponse(response, data: responseData)
            
            do {
                let decodedResponse = try decoder.decode(T.self, from: responseData)
                return decodedResponse
            } catch {
                throw NetworkError.decodingFailed(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch let urlError as URLError {
            throw mapURLError(urlError)
        } catch {
            throw NetworkError.unknown(error)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func buildURLRequest(from endpoint: APIEndpoint) throws -> URLRequest {
        // Build URL
        guard let baseURL = URL(string: configuration.baseURL) else {
            throw NetworkError.invalidURL
        }
        
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        
        // Add query parameters
        if let queryParameters = endpoint.queryParameters, !queryParameters.isEmpty {
            urlComponents?.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents?.url else {
            throw NetworkError.invalidURL
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        // Add default headers
        for (key, value) in configuration.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add endpoint-specific headers
        if let headers = endpoint.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Add body
        if let body = endpoint.body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingFailed(error)
            }
        }
        
        return request
    }
    
    private func buildMultipartURLRequest(from endpoint: APIEndpoint, data: Data, fileName: String) throws -> URLRequest {
        guard let baseURL = URL(string: configuration.baseURL) else {
            throw NetworkError.invalidURL
        }
        
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add default headers (except Content-Type which we just set)
        for (key, value) in configuration.defaultHeaders where key != "Content-Type" {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add endpoint-specific headers (except Content-Type)
        if let headers = endpoint.headers {
            for (key, value) in headers where key != "Content-Type" {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // Build multipart body
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add additional fields from endpoint body if present
        if let bodyFields = endpoint.body as? [String: Any] {
            for (key, value) in bodyFields {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError
        default:
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
    }
    
    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        default:
            return .unknown(error)
        }
    }
    
    // MARK: - Logging
    
    private func logRequest(_ request: URLRequest) {
        print("🌐 [NetworkService] Request:")
        print("  URL: \(request.url?.absoluteString ?? "nil")")
        print("  Method: \(request.httpMethod ?? "nil")")
        print("  Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            print("  Body: \(bodyString)")
        }
    }
    
    private func logResponse(data: Data, response: URLResponse) {
        print("📥 [NetworkService] Response:")
        if let httpResponse = response as? HTTPURLResponse {
            print("  Status Code: \(httpResponse.statusCode)")
        }
        if let responseString = String(data: data, encoding: .utf8) {
            print("  Body: \(responseString)")
        }
    }
}

// MARK: - Helper Types

/// Wrapper to make any Encodable type work with JSONEncoder
private struct AnyEncodable: Encodable {
    private let encodable: Encodable
    
    init(_ encodable: Encodable) {
        self.encodable = encodable
    }
    
    func encode(to encoder: Encoder) throws {
        try encodable.encode(to: encoder)
    }
}

