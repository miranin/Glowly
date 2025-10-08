//
//  GoogleSignInService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 08/10/25.
//

import Foundation
import AuthenticationServices

class GoogleSignInService: NSObject, ObservableObject {
    static let shared = GoogleSignInService()
    
    private var authSession: ASWebAuthenticationSession?
    private var completion: ((Result<GoogleAuthCredentials, Error>) -> Void)?
    
    // MARK: - Configuration
    // In production, replace with your actual Google OAuth credentials
    private let clientID = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    private let redirectURI = "com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID:/oauth2redirect"
    private let scope = "email profile"
    
    private override init() {
        super.init()
    }
    
    // MARK: - Sign In
    
    func signIn(presentingWindow: ASPresentationAnchor? = nil, completion: @escaping (Result<GoogleAuthCredentials, Error>) -> Void) {
        self.completion = completion
        
        // Construct Google OAuth URL
        let authURL = buildGoogleAuthURL()
        
        guard let url = authURL else {
            completion(.failure(GoogleSignInError.invalidConfiguration))
            return
        }
        
        // Create authentication session
        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "com.googleusercontent.apps"
        ) { [weak self] callbackURL, error in
            guard let self = self else { return }
            
            if let error = error {
                // User cancelled or error occurred
                if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    completion(.failure(GoogleSignInError.userCancelled))
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            guard let callbackURL = callbackURL else {
                completion(.failure(GoogleSignInError.noCallback))
                return
            }
            
            // Parse the callback URL to extract tokens
            self.handleCallback(url: callbackURL, completion: completion)
        }
        
        // For iOS 13+, set presentation context provider
        if #available(iOS 13.0, *) {
            authSession?.presentationContextProvider = self
        }
        
        // Prefer ephemeral session (doesn't save cookies)
        authSession?.prefersEphemeralWebBrowserSession = true
        
        // Start the authentication session
        authSession?.start()
    }
    
    // MARK: - URL Building
    
    private func buildGoogleAuthURL() -> URL? {
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        
        return components?.url
    }
    
    // MARK: - Callback Handling
    
    private func handleCallback(url: URL, completion: @escaping (Result<GoogleAuthCredentials, Error>) -> Void) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            completion(.failure(GoogleSignInError.invalidCallback))
            return
        }
        
        // Check for error in callback
        if let error = queryItems.first(where: { $0.name == "error" })?.value {
            completion(.failure(GoogleSignInError.authenticationFailed(error)))
            return
        }
        
        // Extract authorization code
        guard let code = queryItems.first(where: { $0.name == "code" })?.value else {
            completion(.failure(GoogleSignInError.noAuthCode))
            return
        }
        
        // Exchange code for tokens
        exchangeCodeForTokens(code: code, completion: completion)
    }
    
    // MARK: - Token Exchange
    
    private func exchangeCodeForTokens(code: String, completion: @escaping (Result<GoogleAuthCredentials, Error>) -> Void) {
        // In production, this would make a request to your backend
        // which would then exchange the code with Google's token endpoint
        
        // For now, simulate the exchange
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Mock: Extract user info from Google's userinfo endpoint
            // In production, use the access token to call:
            // https://www.googleapis.com/oauth2/v3/userinfo
            
            let mockCredentials = GoogleAuthCredentials(
                idToken: code,
                email: "user@gmail.com",
                name: "Google User",
                profileImageURL: nil
            )
            
            completion(.success(mockCredentials))
        }
    }
    
    // MARK: - Mock Sign-In (for testing without real OAuth)
    
    func mockSignIn(completion: @escaping (Result<GoogleAuthCredentials, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let mockCredentials = GoogleAuthCredentials(
                idToken: UUID().uuidString,
                email: "test.user@gmail.com",
                name: "Test User",
                profileImageURL: nil
            )
            
            completion(.success(mockCredentials))
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

@available(iOS 13.0, *)
extension GoogleSignInService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Return the key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window
        }
        
        // Fallback
        return ASPresentationAnchor()
    }
}

// MARK: - Errors

enum GoogleSignInError: LocalizedError {
    case invalidConfiguration
    case userCancelled
    case noCallback
    case invalidCallback
    case noAuthCode
    case authenticationFailed(String)
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration:
            return "Google Sign-In не настроен корректно"
        case .userCancelled:
            return "Вход через Google отменен"
        case .noCallback:
            return "Не получен ответ от Google"
        case .invalidCallback:
            return "Получен некорректный ответ от Google"
        case .noAuthCode:
            return "Не получен код авторизации"
        case .authenticationFailed(let reason):
            return "Ошибка авторизации: \(reason)"
        case .networkError:
            return "Ошибка сети. Проверьте подключение"
        }
    }
}

