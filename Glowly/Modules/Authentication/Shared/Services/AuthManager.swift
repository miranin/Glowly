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
    
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, name: String?) async throws -> User
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
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(
        keychainService: KeychainServiceProtocol = KeychainService(),
        biometricService: BiometricAuthServiceProtocol = BiometricAuthService()
    ) {
        self.keychain = keychainService
        self.biometric = biometricService
        
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
    /// - Note: ⚠️ This is a MOCK implementation. In production:
    ///   1. Send credentials to backend
    ///   2. Backend validates and returns JWT token
    ///   3. Store token in Keychain (NEVER store passwords)
    func signIn(email: String, password: String) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidCredentials
        }
        
        // ⚠️ MOCK: Simulate API call delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // ⚠️ MOCK: In production, send to backend API:
        // let response = try await networkService.post("/auth/login", body: ["email": email, "password": password])
        // let token = response.token
        // let user = response.user
        
        // For mock, check if user exists
        let userKey = "user_\(email)"
        guard let userData = UserDefaults.standard.data(forKey: userKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            throw AuthError.userNotFound
        }
        
        // ✅ SECURITY FIX: NO password storage or verification locally
        // In production: Backend validates password and returns token
        // For mock: Just simulate successful login
        
        handleSuccessfulAuth(user: user)
        return user
    }
    
    /// Sign up with email and password
    /// - Note: ⚠️ This is a MOCK implementation. In production:
    ///   1. Send credentials to backend
    ///   2. Backend creates user and returns JWT token
    ///   3. Store token in Keychain (NEVER store passwords)
    func signUp(email: String, password: String, name: String?) async throws -> User {
        isLoading = true
        defer { isLoading = false }
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }
        
        // ⚠️ MOCK: Skip email validation for phone numbers (starts with +7)
        if !email.hasPrefix("+7") {
            guard isValidEmail(email) else {
                throw AuthError.invalidCredentials
            }
        }
        
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        // ⚠️ MOCK: Simulate API call delay
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // ⚠️ MOCK: In production, send to backend API:
        // let response = try await networkService.post("/auth/register", body: ["email": email, "password": password, "name": name])
        // let token = response.token
        // let user = response.user
        
        // For mock, check if user already exists
        let userKey = "user_\(email)"
        if UserDefaults.standard.data(forKey: userKey) != nil {
            throw AuthError.emailAlreadyExists
        }
        
        // Create new user
        let user = User(
            id: UUID().uuidString,
            email: email,
            name: name,
            profilePhotoURL: nil,
            authProvider: .email,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        
        // ✅ SECURITY FIX: NO password storage
        // In production: Backend stores hashed password
        // For mock: Just save user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userKey)
            // ❌ REMOVED: UserDefaults.standard.set(password, forKey: "password_\(email)")
            
            handleSuccessfulAuth(user: user)
            return user
        } else {
            throw AuthError.unknown("Не удалось создать пользователя")
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
}
