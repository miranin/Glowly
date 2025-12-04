//
//  NetworkDebugger.swift
//  Glowly
//
//  Network debugging helper for API integration testing
//

import Foundation

#if DEBUG
struct NetworkDebugger {

    /// Print detailed request information
    static func logRequest(_ request: URLRequest) {
        print("\n" + String(repeating: "=", count: 80))
        print("🌐 NETWORK REQUEST")
        print(String(repeating: "=", count: 80))

        // URL
        if let url = request.url {
            print("📍 URL: \(url.absoluteString)")
        }

        // Method
        if let method = request.httpMethod {
            print("📤 Method: \(method)")
        }

        // Headers
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("\n📋 Headers:")
            for (key, value) in headers.sorted(by: { $0.key < $1.key }) {
                print("  • \(key): \(value)")
            }
        }

        // Body
        if let body = request.httpBody {
            print("\n📦 Body:")
            if let jsonObject = try? JSONSerialization.jsonObject(with: body),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print(prettyString)
            } else if let bodyString = String(data: body, encoding: .utf8) {
                print(bodyString)
            } else {
                print("  [Binary data: \(body.count) bytes]")
            }
        }

        print(String(repeating: "=", count: 80) + "\n")
    }

    /// Print detailed response information
    static func logResponse(data: Data?, response: URLResponse?, error: Error?) {
        print("\n" + String(repeating: "=", count: 80))
        print("📥 NETWORK RESPONSE")
        print(String(repeating: "=", count: 80))

        // Status Code
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
            print("\(statusEmoji) Status Code: \(httpResponse.statusCode)")

            // Response Headers
            if !httpResponse.allHeaderFields.isEmpty {
                print("\n📋 Response Headers:")
                for (key, value) in httpResponse.allHeaderFields.sorted(by: { "\($0.key)" < "\($1.key)" }) {
                    print("  • \(key): \(value)")
                }
            }
        }

        // Response Body
        if let data = data, !data.isEmpty {
            print("\n📦 Response Body:")
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
               let prettyString = String(data: prettyData, encoding: .utf8) {
                print(prettyString)
            } else if let bodyString = String(data: data, encoding: .utf8) {
                print(bodyString)
            } else {
                print("  [Binary data: \(data.count) bytes]")
            }
        }

        // Error
        if let error = error {
            print("\n❌ Error: \(error.localizedDescription)")
        }

        print(String(repeating: "=", count: 80) + "\n")
    }

    /// Test a specific endpoint
    static func testEndpoint(_ endpoint: APIEndpoint, with networkService: NetworkServiceProtocol) async {
        print("\n🧪 TESTING ENDPOINT: \(endpoint.path)")
        print(String(repeating: "-", count: 80))

        do {
            let response: AuthResponse = try await networkService.request(endpoint)
            print("✅ SUCCESS!")
            print("Username: \(response.username)")
            print("Email: \(response.email)")
            print("Access Token: \(response.accessToken.prefix(30))...")
            print("Token Type: \(response.tokenType)")
            print("Roles: \(response.roles)")
        } catch let error as NetworkError {
            print("❌ NETWORK ERROR: \(error)")
        } catch {
            print("❌ ERROR: \(error)")
        }

        print(String(repeating: "-", count: 80) + "\n")
    }
}
#endif
