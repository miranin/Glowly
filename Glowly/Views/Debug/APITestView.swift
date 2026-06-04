//
//  APITestView.swift
//  Glowly
//
//  Debug view for testing API integration
//  Add this to your app during development to quickly test API calls
//

import SwiftUI

#if DEBUG
struct APITestView: View {
    @State private var testResult: String = "Ready to test..."
    @State private var isLoading: Bool = false
    @State private var testEmail: String = ""
    @State private var testPassword: String = "TestPass123!"

    private let networkService = NetworkService(configuration: .development)

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Configuration Info
                    configurationSection

                    // Test Registration
                    registrationTestSection

                    // Test Login
                    loginTestSection

                    // Test Results
                    resultsSection
                }
                .padding()
            }
            .navigationTitle("API Integration Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Configuration")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Base URL", value: NetworkConfiguration.development.baseURL)
                InfoRow(label: "Logging", value: "Enabled")
                InfoRow(label: "Timeout", value: "30s")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }

    // MARK: - Registration Test Section

    private var registrationTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Registration")
                .font(.headline)

            Button {
                Task { await testRegistration() }
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("Test POST /api/auth/register")
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading)

            Text("This will create a new user with random email")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Login Test Section

    private var loginTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Login")
                .font(.headline)

            VStack(spacing: 12) {
                TextField("Email", text: $testEmail)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                SecureField("Password", text: $testPassword)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            Button {
                Task { await testLogin() }
            } label: {
                HStack {
                    Image(systemName: "person.badge.key")
                    Text("Test POST /api/auth/login")
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isLoading || testEmail.isEmpty)
        }
    }

    // MARK: - Results Section

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Test Results")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    testResult = "Ready to test..."
                }
                .font(.caption)
            }

            ScrollView {
                Text(testResult)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
            .frame(maxHeight: 300)
        }
    }

    // MARK: - Test Functions

    private func testRegistration() async {
        isLoading = true
        testResult = "🧪 Testing Registration...\n\n"

        // Generate random test data
        let randomId = UUID().uuidString.prefix(8)
        let email = "test_\(randomId)@example.com"
        let username = "TestUser_\(randomId)"
        let phone = "+7700\(Int.random(in: 1000000...9999999))"

        testResult += "📝 Request Data:\n"
        testResult += "  • Username: \(username)\n"
        testResult += "  • Email: \(email)\n"
        testResult += "  • Phone: \(phone)\n"
        testResult += "  • Password: \(testPassword)\n\n"

        // Create request
        let request = RegisterRequest(
            username: username,
            email: email,
//            phoneNumber: phone,
            password: testPassword,
            valid: true
        )

        do {
            testResult += "🌐 Sending request to: /api/auth/register\n\n"

            let endpoint = AuthEndpoints.register(request)
            let response: AuthResponse = try await networkService.request(endpoint)

            testResult += "✅ SUCCESS!\n\n"
            testResult += "📥 Response:\n"
            testResult += "  • Username: \(response.username)\n"
            testResult += "  • Email: \(response.email)\n"
            testResult += "  • Access Token: \(response.accessToken.prefix(40))...\n"
            testResult += "  • Token Type: \(response.tokenType)\n"
            testResult += "  • Roles: \(response.roles.joined(separator: ", "))\n\n"

            // Save email for login test
            testEmail = email

            testResult += "💡 Tip: You can now test login with this email!\n"

        } catch let error as NetworkError {
            testResult += "❌ NETWORK ERROR\n\n"
            testResult += "Error: \(error)\n"
            testResult += "Description: \(error.localizedDescription)\n"
        } catch {
            testResult += "❌ ERROR\n\n"
            testResult += "\(error)\n"
        }

        isLoading = false
    }

    private func testLogin() async {
        isLoading = true
        testResult = "🧪 Testing Login...\n\n"

        testResult += "📝 Request Data:\n"
        testResult += "  • Email: \(testEmail)\n"
        testResult += "  • Password: \(testPassword)\n\n"

        let request = LoginRequest(
            usernameOrEmail: testEmail,
            password: testPassword
        )

        do {
            testResult += "🌐 Sending request to: /api/auth/login\n\n"

            let endpoint = AuthEndpoints.login(request)
            let response: AuthResponse = try await networkService.request(endpoint)

            testResult += "✅ SUCCESS!\n\n"
            testResult += "📥 Response:\n"
            testResult += "  • Username: \(response.username)\n"
            testResult += "  • Email: \(response.email)\n"
            testResult += "  • Access Token: \(response.accessToken.prefix(40))...\n"
            testResult += "  • Token Type: \(response.tokenType)\n"
            testResult += "  • Roles: \(response.roles.joined(separator: ", "))\n"

        } catch let error as NetworkError {
            testResult += "❌ NETWORK ERROR\n\n"
            testResult += "Error: \(error)\n"

            switch error {
            case .unauthorized:
                testResult += "\n💡 Tip: User not found or wrong password\n"
            case .noInternetConnection:
                testResult += "\n💡 Tip: Check if backend server is running\n"
            case .timeout:
                testResult += "\n💡 Tip: Server took too long to respond\n"
            default:
                testResult += "Description: \(error.localizedDescription)\n"
            }
        } catch {
            testResult += "❌ ERROR\n\n"
            testResult += "\(error)\n"
        }

        isLoading = false
    }
}

// MARK: - Helper Views

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

#Preview {
    APITestView()
}
#endif
