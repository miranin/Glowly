//
//  MainTabView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var productStore: ProductStore
    @ObservedObject var userProfilePresenter: UserProfilePresenter
    @ObservedObject var authManager: AuthManager
    let biometricService: BiometricAuthServiceProtocol
    
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var wishListService = WishListService()
    @State private var selectedTab: TabItem = .cosmetics
    @State private var showCameraUpload = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case .cosmetics:
                    BagListView(productStore: productStore, userProfilePresenter: userProfilePresenter)
                        .environmentObject(languageManager)
                    
                case .feed:
                    // Feature Flag: Switch between Reels and traditional Feed
                    if FeatureFlags.useReelsFeed {
                        ReelsView(feedService: FeedService(), authManager: authManager)
                            .environmentObject(languageManager)
                    } else {
                        FeedView(productStore: productStore, wishListService: wishListService, authManager: authManager)
                            .environmentObject(languageManager)
                    }
                    
                case .add:
                    Color.clear
                    
                case .learning:
                    LearningView(productStore: productStore, userProfilePresenter: userProfilePresenter)
                        .environmentObject(languageManager)
                    
                case .profile:
                    SettingsView(
                        productStore: productStore,
                        userProfilePresenter: userProfilePresenter,
                        authManager: authManager,
                        biometricService: biometricService,
                        wishListService: wishListService
                    )
                    .environmentObject(languageManager)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: 50)
            }
            
            // Tab Bar
            SimpleTabBar(selectedTab: $selectedTab)
                .environmentObject(languageManager)
        }
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .add {
                showCameraUpload = true
                // Reset tab
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = oldValue
                }
            }
        }
        .fullScreenCover(isPresented: $showCameraUpload) {
            CameraUploadView(productStore: productStore)
        }
    }
}

#Preview {
    MainTabView(
        productStore: ProductStore(),
        userProfilePresenter: UserProfilePresenter(),
        authManager: AuthManager(),
        biometricService: BiometricAuthService()
    )
}

