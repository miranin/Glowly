//
//  AuthManager.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation
import Combine

// MARK: - AuthManager Protocol for DI
@MainActor
protocol AuthManagerProtocol: ObservableObject {
    var currentUser: User? { get set }
    var isAuthenticated: Bool { get set }
    var isLoading: Bool { get set }
    var isBiometricEnabled: Bool { get set }

    func signIn(_ request: LoginRequest) async throws -> User
    func signUp(_ request: RegisterRequest) async throws -> User
    func signInWithGoogle(credentials: GoogleAuthCredentials) async throws -> User
    func signInWithBiometrics() async throws -> User
    func enableBiometrics()
    func disableBiometrics()
    func signOut()
}

// MARK: - AuthManager Implementation
@MainActor
final class AuthManager: ObservableObject, AuthManagerProtocol {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var isBiometricEnabled: Bool = false
    
    // MARK: - Dependencies (Injected)
    private let keychain: KeychainServiceProtocol
    private let biometric: BiometricAuthServiceProtocol
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization with Dependency Injection
    nonisolated init(
        keychainService: KeychainServiceProtocol = KeychainService(),
        biometricService: BiometricAuthServiceProtocol = BiometricAuthService(),
        networkService: NetworkServiceProtocol = NetworkService()
    ) {
        self.keychain = keychainService
        self.biometric = biometricService
        self.networkService = networkService

        // Note: checkAuthenticationStatus() and loadBiometricPreference()
        // will be called in onAppear or task modifier instead
    }
    
    // Call this after initialization to check auth status
    func initialize() {
        checkAuthenticationStatus()
        loadBiometricPreference()
    }
    
    // MARK: - Check Authentication
    private func checkAuthenticationStatus() {
        // Always start with unauthenticated state
        // User must explicitly sign in each time
        // In the future, we'll add session management with expiration
        self.isAuthenticated = false
        self.currentUser = nil
    }
    
    private func loadUserData(userId: String) {
        // In a real app, fetch from server
        // For now, load from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "currentUser_\(userId)"),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    // MARK: - Email/Password Authentication (Async/Await)
    
    /// Sign in with email and password
    /// Sends credentials to backend API and receives JWT token
    func signIn(_ request: LoginRequest) async throws -> User {
        isLoading = true
        defer { isLoading = false }

        // Validate input
        guard !request.usernameOrEmail.isEmpty, !request.password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        // Skip email validation for phone numbers (starts with +7)
        if !request.usernameOrEmail.hasPrefix("+7") {
            guard isValidEmail(request.usernameOrEmail) else {
                throw AuthError.invalidCredentials
            }
        }

        do {
            // Call backend API
            let endpoint = AuthEndpoints.login(request)
            let response: AuthResponse = try await networkService.request(endpoint)

            // Convert AuthResponse to User model
            let user = response.toUser(authProvider: .email)

            // Store access token securely
            _ = keychain.save(response.accessToken, forKey: KeychainService.Keys.userToken)
            // Note: Backend doesn't return refresh token for login

            // Update auth state
            handleSuccessfulAuth(user: user)
            return user
        } catch let error as NetworkError {
            // Map network errors to auth errors
            throw mapNetworkErrorToAuthError(error)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    /// Sign up with email and password
    /// Sends registration data to backend API and receives JWT token
    func signUp(_ request: RegisterRequest) async throws -> User {
        isLoading = true
        defer { isLoading = false }

        // Validate input
        guard !request.email.isEmpty, !request.password.isEmpty, !request.username.isEmpty else {
            throw AuthError.invalidCredentials
        }

        // Validate email format if provided (skip for phone-only registration)
        if !request.email.isEmpty && !request.email.hasPrefix("+7") {
            guard isValidEmail(request.email) else {
                throw AuthError.invalidCredentials
            }
        }

        guard request.password.count >= 8 else {
            throw AuthError.weakPassword
        }

        do {
            // Call backend API
            let endpoint = AuthEndpoints.register(request)
            let response: AuthResponse = try await networkService.request(endpoint)

            // Convert AuthResponse to User model
            let user = response.toUser(authProvider: .email)

            // Store access token securely
            _ = keychain.save(response.accessToken, forKey: KeychainService.Keys.userToken)
            // Note: Backend doesn't return refresh token for registration

            // Update auth state
            handleSuccessfulAuth(user: user)
            return user
        } catch let error as NetworkError {
            // Map network errors to auth errors
            throw mapNetworkErrorToAuthError(error)
        } catch {
            throw AuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle(credentials: GoogleAuthCredentials) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // ⚠️ MOCK: Simulate API call delay
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Check if user exists, otherwise create
        let userKey = "user_\(credentials.email)"
        
        if let userData = UserDefaults.standard.data(forKey: userKey),
           let existingUser = try? JSONDecoder().decode(User.self, from: userData) {
            // Existing user
            handleSuccessfulAuth(user: existingUser)
            return existingUser
        } else {
            // New user
            let user = User(
                id: UUID().uuidString,
                email: credentials.email,
                name: credentials.name,
                profilePhotoURL: credentials.profileImageURL,
                authProvider: .google,
                createdAt: Date(),
                lastLoginAt: Date()
            )
            
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: userKey)
                handleSuccessfulAuth(user: user)
                return user
            } else {
                throw AuthError.unknown("Не удалось создать пользователя")
            }
        }
    }
    
    // MARK: - Biometric Authentication
    
    func signInWithBiometrics() async throws -> User {
        guard isBiometricEnabled else {
            throw AuthError.unknown("Биометрическая аутентификация не включена")
        }
        
        guard let email = keychain.retrieveString(forKey: KeychainService.Keys.userEmail) else {
            throw AuthError.userNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Perform biometric authentication
        return try await withCheckedThrowingContinuation { continuation in
            biometric.authenticateWithBiometrics(reason: nil) { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success:
                    // Load user
                    let userKey = "user_\(email)"
                    if let userData = UserDefaults.standard.data(forKey: userKey),
                       let user = try? JSONDecoder().decode(User.self, from: userData) {
                        self.handleSuccessfulAuth(user: user)
                        continuation.resume(returning: user)
                    } else {
                        continuation.resume(throwing: AuthError.userNotFound)
                    }
                    
                case .failure(let error):
                    continuation.resume(throwing: AuthError.biometricFailed(error))
                }
            }
        }
    }
    
    func enableBiometrics() {
        isBiometricEnabled = true
        UserDefaults.standard.set(true, forKey: "biometricEnabled")
        
        // Save user email for biometric login
        if let email = currentUser?.email {
            _ = keychain.save(email, forKey: KeychainService.Keys.userEmail)
        }
    }
    
    func disableBiometrics() {
        isBiometricEnabled = false
        UserDefaults.standard.set(false, forKey: "biometricEnabled")
        _ = keychain.delete(forKey: KeychainService.Keys.userEmail)
    }
    
    private func loadBiometricPreference() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometricEnabled")
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false

        // Clear tokens
        _ = keychain.delete(forKey: KeychainService.Keys.userToken)
        _ = keychain.delete(forKey: KeychainService.Keys.userId)
        _ = keychain.delete(forKey: KeychainService.Keys.refreshToken)

        // Don't clear email if biometric is enabled
        if !isBiometricEnabled {
            _ = keychain.delete(forKey: KeychainService.Keys.userEmail)
        }
    }

    // MARK: - Account Deletion

    /// Permanently deletes the user account and all associated data
    /// - Note: This action is irreversible
    func deleteAccount() {
        guard let user = currentUser else { return }

        // 1. Delete user data from UserDefaults
        let userKey = "user_\(user.email)"
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: "currentUser_\(user.id)")

        // 2. Clear all keychain data
        _ = keychain.delete(forKey: KeychainService.Keys.userToken)
        _ = keychain.delete(forKey: KeychainService.Keys.userId)
        _ = keychain.delete(forKey: KeychainService.Keys.refreshToken)
        _ = keychain.delete(forKey: KeychainService.Keys.userEmail)

        // 3. Disable biometrics
        disableBiometrics()

        // 4. Clear authentication state
        currentUser = nil
        isAuthenticated = false

        // In production, this would also:
        // - Send DELETE request to backend API
        // - Backend would remove user from database
        // - Backend would delete user's files from cloud storage
        // - Backend would cancel subscriptions
    }
    
    // MARK: - Helper Methods
    
    private func handleSuccessfulAuth(user: User) {
        self.currentUser = user
        self.isAuthenticated = true
        
        // Save tokens (mock - in production, these come from backend)
        let token = UUID().uuidString
        _ = keychain.save(token, forKey: KeychainService.Keys.userToken)
        _ = keychain.save(user.id, forKey: KeychainService.Keys.userId)
        
        // Save current user
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser_\(user.id)")
        }
        
        HapticsService.shared.success()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    /// Maps NetworkError to AuthError for better error handling
    private func mapNetworkErrorToAuthError(_ error: NetworkError) -> AuthError {
        switch error {
        case .unauthorized:
            return .invalidCredentials
        case .forbidden:
            return .unknown("Access forbidden")
        case .notFound:
            return .userNotFound
        case .serverError:
            return .unknown("Server error. Please try again later.")
        case .noInternetConnection:
            return .unknown("No internet connection")
        case .timeout:
            return .unknown("Request timed out")
        case .decodingFailed:
            return .unknown("Invalid response from server")
        case .httpError(let statusCode, _):
            if statusCode == 400 {
                return .emailAlreadyExists
            }
            return .unknown("HTTP error: \(statusCode)")
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
