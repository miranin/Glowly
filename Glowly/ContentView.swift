//
//  ContentView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Dependencies (Injected)
    @StateObject private var authManager: AuthManager
    @StateObject private var productStore = ProductStore()
    @StateObject private var userProfilePresenter = UserProfilePresenter()
    private let biometricService: BiometricAuthServiceProtocol
    @StateObject private var permissionsService: PermissionsService
    @State private var isFirstLogin = false
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(
        authManager: AuthManager = AuthManager(),
        biometricService: BiometricAuthServiceProtocol = BiometricAuthService()
    ) {
        _authManager = StateObject(wrappedValue: authManager)
        self.biometricService = biometricService
        _permissionsService = StateObject(wrappedValue: PermissionsService(biometricService: biometricService))
    }
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                // Show login if not authenticated
                LoginView(authManager: authManager)
            } else if userProfilePresenter.needsOnboarding {
                // Show onboarding after authentication if needed
                OnboardingContainerView(userProfilePresenter: userProfilePresenter)
            } else {
                // Show main app
                mainAppView
            }
        }
        .task {
            // Initialize auth manager (but don't auto-authenticate)
            authManager.initialize()
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            // Check if user just authenticated (first login)
            if !oldValue && newValue {
                // Check if it's first login (no biometric preference set)
                let hasSetBiometric = UserDefaults.standard.object(forKey: "hasSetBiometricPreference") != nil
                if !hasSetBiometric {
                    isFirstLogin = true
                    UserDefaults.standard.set(true, forKey: "hasSetBiometricPreference")
                    
                    // Request permissions after a short delay
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        await permissionsService.completeFirstTimeOnboarding()
                        isFirstLogin = false
                    }
                }
            }
        }
    }
    
    private var mainAppView: some View {
        MainTabView(
            productStore: productStore,
            userProfilePresenter: userProfilePresenter,
            authManager: authManager,
            biometricService: biometricService
        )
    }
}

#Preview {
    ContentView()
}
