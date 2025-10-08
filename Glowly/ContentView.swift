//
//  ContentView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var productStore = ProductStore()
    @StateObject private var userProfilePresenter = UserProfilePresenter()
    
    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                // Show login if not authenticated
                LoginView()
            } else if userProfilePresenter.needsOnboarding {
                // Show onboarding after authentication if needed
                OnboardingContainerView(userProfilePresenter: userProfilePresenter)
            } else {
                // Show main app
                mainAppView
            }
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
            SettingsView(productStore: productStore, userProfilePresenter: userProfilePresenter)
                .tabItem { Label("Профиль", systemImage: "person.fill") }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
}
