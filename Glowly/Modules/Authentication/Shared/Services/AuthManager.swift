//
//  AuthManager.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation
import Combine

enum AuthError: LocalizedError {
    case invalidCredentials
    case userNotFound
    case emailAlreadyExists
    case weakPassword
    case networkError
    case invalidToken
    case biometricFailed(BiometricAuthError)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Неверный email или пароль"
        case .userNotFound:
            return "Пользователь не найден"
        case .emailAlreadyExists:
            return "Пользователь с таким email уже существует"
        case .weakPassword:
            return "Пароль должен содержать минимум 8 символов"
        case .networkError:
            return "Ошибка сети. Проверьте подключение к интернету"
        case .invalidToken:
            return "Сессия истекла. Войдите заново"
        case .biometricFailed(let error):
            return error.errorDescription
        case .unknown(let message):
            return message
        }
    }
}

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var isBiometricEnabled: Bool = false
    
    private let keychain = KeychainService.shared
    private let biometric = BiometricAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAuthenticationStatus()
        loadBiometricPreference()
    }
    
    // MARK: - Check Authentication
    
    private func checkAuthenticationStatus() {
        // Check if user token exists
        if let token = keychain.retrieveString(forKey: KeychainService.Keys.userToken),
           let userId = keychain.retrieveString(forKey: KeychainService.Keys.userId) {
            // Load user data
            loadUserData(userId: userId)
        }
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
    
    // MARK: - Email/Password Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            isLoading = false
            completion(.failure(.invalidCredentials))
            return
        }
        
        guard isValidEmail(email) else {
            isLoading = false
            completion(.failure(.invalidCredentials))
            return
        }
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Check if user exists (mock)
            let userKey = "user_\(email)"
            if let userData = UserDefaults.standard.data(forKey: userKey),
               let storedPassword = UserDefaults.standard.string(forKey: "password_\(email)") {
                
                // Verify password
                if storedPassword == password {
                    do {
                        let user = try JSONDecoder().decode(User.self, from: userData)
                        self.handleSuccessfulAuth(user: user)
                        completion(.success(user))
                    } catch {
                        self.isLoading = false
                        completion(.failure(.unknown("Ошибка загрузки данных пользователя")))
                    }
                } else {
                    self.isLoading = false
                    completion(.failure(.invalidCredentials))
                }
            } else {
                self.isLoading = false
                completion(.failure(.userNotFound))
            }
        }
    }
    
    func signUp(email: String, password: String, name: String?, completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty else {
            isLoading = false
            completion(.failure(.invalidCredentials))
            return
        }
        
        guard isValidEmail(email) else {
            isLoading = false
            completion(.failure(.invalidCredentials))
            return
        }
        
        guard password.count >= 8 else {
            isLoading = false
            completion(.failure(.weakPassword))
            return
        }
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Check if user already exists
            let userKey = "user_\(email)"
            if UserDefaults.standard.data(forKey: userKey) != nil {
                self.isLoading = false
                completion(.failure(.emailAlreadyExists))
                return
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
            
            // Save user data
            if let userData = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(userData, forKey: userKey)
                UserDefaults.standard.set(password, forKey: "password_\(email)")
                
                self.handleSuccessfulAuth(user: user)
                completion(.success(user))
            } else {
                self.isLoading = false
                completion(.failure(.unknown("Не удалось создать пользователя")))
            }
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle(credentials: GoogleAuthCredentials, completion: @escaping (Result<User, AuthError>) -> Void) {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Check if user exists, otherwise create
            let userKey = "user_\(credentials.email)"
            
            if let userData = UserDefaults.standard.data(forKey: userKey),
               let existingUser = try? JSONDecoder().decode(User.self, from: userData) {
                // Existing user
                self.handleSuccessfulAuth(user: existingUser)
                completion(.success(existingUser))
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
                    self.handleSuccessfulAuth(user: user)
                    completion(.success(user))
                } else {
                    self.isLoading = false
                    completion(.failure(.unknown("Не удалось создать пользователя")))
                }
            }
        }
    }
    
    // MARK: - Biometric Authentication
    
    func signInWithBiometrics(completion: @escaping (Result<User, AuthError>) -> Void) {
        guard isBiometricEnabled else {
            completion(.failure(.unknown("Биометрическая аутентификация не включена")))
            return
        }
        
        guard let email = keychain.retrieveString(forKey: KeychainService.Keys.userEmail) else {
            completion(.failure(.userNotFound))
            return
        }
        
        isLoading = true
        
        biometric.authenticateWithBiometrics { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                // Load user
                let userKey = "user_\(email)"
                if let userData = UserDefaults.standard.data(forKey: userKey),
                   let user = try? JSONDecoder().decode(User.self, from: userData) {
                    self.handleSuccessfulAuth(user: user)
                    completion(.success(user))
                } else {
                    self.isLoading = false
                    completion(.failure(.userNotFound))
                }
                
            case .failure(let error):
                self.isLoading = false
                completion(.failure(.biometricFailed(error)))
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
        self.isLoading = false
        
        // Save tokens (mock)
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

