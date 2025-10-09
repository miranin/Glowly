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
    
    // MARK: - Initialization with Dependency Injection
    nonisolated init(
        authManager: AuthManager = AuthManager(),
        biometricService: BiometricAuthServiceProtocol = BiometricAuthService()
    ) {
        _authManager = StateObject(wrappedValue: authManager)
        self.biometricService = biometricService
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
            // Initialize auth manager to check authentication status
            authManager.initialize()
        }
    }
    
    private var mainAppView: some View {
        TabView {
            BagListView(productStore: productStore)
                .tabItem { Label("Косметичка", systemImage: "bag.fill") }
            AddEntryChooserView(productStore: productStore)
                .tabItem { Label("Добавить", systemImage: "plus.circle.fill") }
            AIHelperView(productStore: productStore, userProfilePresenter: userProfilePresenter)
                .tabItem { Label("AI", systemImage: "sparkles") }
            SettingsView(productStore: productStore, userProfilePresenter: userProfilePresenter, authManager: authManager, biometricService: biometricService)
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
}
