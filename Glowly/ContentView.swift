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
    @State private var shouldRequestPermissions = false
    @State private var showSplash = true

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
        ZStack {
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
            .opacity(showSplash ? 0 : 1)

            // Splash screen overlay
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            authManager.initialize()

            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            withAnimation(.easeOut(duration: 0.5)) {
                showSplash = false
            }
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if !oldValue && newValue {
                if let currentUser = authManager.currentUser {
                    userProfilePresenter.syncWithAuthenticatedUser(currentUser)
                }

                let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
                if !hasCompletedOnboarding {
                    shouldRequestPermissions = true
                }
            }
        }
        .onChange(of: userProfilePresenter.needsOnboarding) { oldValue, newValue in
            // When onboarding completes (needsOnboarding changes from true to false)
            if oldValue && !newValue && shouldRequestPermissions {
                shouldRequestPermissions = false

                // Request permissions after onboarding completion
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await permissionsService.completeFirstTimeOnboarding()
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
