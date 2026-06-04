# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Glowly is an AI-powered beauty assistant iOS app built with SwiftUI. It helps users organize their cosmetic collection, track expiration dates, and receive personalized beauty advice. The app follows a clean MVVM/MVP architecture with protocol-based dependency injection.

**Platform:** iOS 18.2+
**Language:** Swift 5.0
**Architecture:** MVVM + MVP with Dependency Injection
**Business Model:** Freemium ($4.99/month premium)

## Essential Documentation

- **[BACKEND_INTEGRATION_PLAN.md](BACKEND_INTEGRATION_PLAN.md)** - Complete guide for backend implementation, server setup, SMS/email services, and deployment
- **[DATABASE_SCHEMA.md](DATABASE_SCHEMA.md)** - Full PostgreSQL database schema with all tables, indexes, and relationships
- **[AUTH_IMPLEMENTATION.md](AUTH_IMPLEMENTATION.md)** - Complete authentication implementation with code examples
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete API endpoint reference (~44 endpoints) with request/response examples
- **[README.md](README.md)** - Project overview and quick start guide

## Build & Run Commands

### Building the Project
```bash
# Open project in Xcode
open Glowly.xcodeproj

# Build from command line
xcodebuild -project Glowly.xcodeproj -scheme Glowly -configuration Debug build

# Clean build folder
xcodebuild clean -project Glowly.xcodeproj -scheme Glowly
```

### Running Tests
```bash
# Run all tests
xcodebuild test -project Glowly.xcodeproj -scheme Glowly -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run specific test
xcodebuild test -project Glowly.xcodeproj -scheme Glowly -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:GlowlyTests/TestClassName/testMethodName
```

### Development
- Run the app in Xcode simulator (Cmd+R)
- The app uses Development network configuration by default (see NetworkConfiguration.swift)
- No external dependencies (no CocoaPods or SPM packages)

## High-Level Architecture

### Core Layer Structure
The app is organized into four main layers:

1. **Core/** - Foundation components and infrastructure (37 files)
   - **Network/** - Backend API communication with type-safe endpoints
     - `NetworkService.swift` - Async/await-based HTTP client with protocol-based injection
     - `APIEndpoint.swift` - Protocol defining request structure
     - `NetworkConfiguration.swift` - Environment configs (Development, Staging, Production, Mock)
     - Multipart file upload support built-in
   - **Components/** - Reusable UI building blocks (CachedAsyncImage, SimpleTabBar, VideoPlayer, BottomSheetError)
   - **Configuration/** - `FeatureFlags.swift` controls premium features, reels feed, AI captions, post creation
   - **Theme/** - Design system with adaptive light/dark colors via hex codes
   - **Localization/** - Multi-language support (EN, RU, KZ)
   - **Services/** - ImageCacheService (NSCache-based, 100MB/100 images), HapticManager, ProductRecommendationEngine

2. **Modules/** - Feature-specific logic with MVP/MVVM patterns
   - **Authentication/** (MVP) - Email/password, biometric (Face ID/Touch ID), Google OAuth
     - `AuthManager.swift` - Orchestrates sign-in/sign-up, token management
     - `KeychainService.swift` - Secure token storage
     - `BiometricAuthService.swift` - Face ID/Touch ID integration
   - **Onboarding/** (MVP) - 7-step personalization flow (skin type, tone, beauty goals)
   - **Products/** (MVVM) - CRUD for cosmetic products
     - `ProductStore.swift` - Currently uses UserDefaults (needs Core Data migration)
   - **Social/** (MVVM) - TikTok-style reels feed, comments, wish list (currently mock data)
   - **PostCreation/** (MVVM) - Premium feature for creating posts with AI caption suggestions

3. **Views/** - Screen-level UI components organized by feature
   - Feed, Products, Profile, Onboarding, AI, Common (PremiumPaywallView, ImagePicker), Bag, Learning

4. **Services/** - App-level coordination
   - `Config/APIConfig.swift` - AI provider configuration (Claude, OpenAI, OpenRouter)

### Key Data Flow

**Authentication Flow:**
```
ContentView (Root)
  ↓
  ├─ if !isAuthenticated → LoginView → AuthManager → Keychain
  ├─ if needsOnboarding → OnboardingContainerView → UserProfilePresenter
  └─ else → MainTabView (5 tabs: Cosmetics, Feed, Add Post, Learning, Profile)
```

**Product Management:**
```
ProductStore (ObservableObject)
  ├─ CRUD operations (addProduct, updateProduct, deleteProduct)
  ├─ Filtering by category (getProductsByCategory)
  ├─ UserDefaults persistence (key: "SavedProducts")
  ├─ 18 pre-loaded sample products
  └─ Export to JSON functionality
```

**Network Layer Pattern:**
```swift
protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
}

// All services use protocol-based DI for testability
class AuthManager {
    private let networkService: NetworkServiceProtocol
    nonisolated init(networkService: NetworkServiceProtocol = NetworkService()) { ... }
}
```

## Critical File Locations

### Authentication
- [Glowly/Modules/Authentication/Shared/Services/AuthManager.swift](Glowly/Modules/Authentication/Shared/Services/AuthManager.swift) - Main auth orchestration
- [Glowly/Modules/Authentication/Shared/Services/KeychainService.swift](Glowly/Modules/Authentication/Shared/Services/KeychainService.swift) - Secure token storage
- [Glowly/Modules/Authentication/Shared/Services/BiometricAuthService.swift](Glowly/Modules/Authentication/Shared/Services/BiometricAuthService.swift) - Face ID/Touch ID

### Network Layer
- [Glowly/Core/Network/Services/NetworkService.swift](Glowly/Core/Network/Services/NetworkService.swift) - Main HTTP client
- [Glowly/Core/Network/Protocols/APIEndpoint.swift](Glowly/Core/Network/Protocols/APIEndpoint.swift) - Endpoint protocol
- [Glowly/Core/Network/Endpoints/AuthEndpoints.swift](Glowly/Core/Network/Endpoints/AuthEndpoints.swift) - Auth API endpoints
- [Glowly/Core/Network/Models/NetworkConfiguration.swift](Glowly/Core/Network/Models/NetworkConfiguration.swift) - Environment configs

### Data & Business Logic
- [Glowly/Modules/Products/Services/ProductStore.swift](Glowly/Modules/Products/Services/ProductStore.swift) - Product management (currently UserDefaults)
- [Glowly/Modules/Social/Services/FeedService.swift](Glowly/Modules/Social/Services/FeedService.swift) - Social feed (mock data)

### Configuration & Design System
- [Glowly/Core/Theme/Theme.swift](Glowly/Core/Theme/Theme.swift) - Colors, fonts, spacing with dark mode support
- [Glowly/Core/Configuration/FeatureFlags.swift](Glowly/Core/Configuration/FeatureFlags.swift) - Feature toggles
- [Glowly/Services/Config/APIConfig.swift](Glowly/Services/Config/APIConfig.swift) - AI provider configs (Claude, OpenAI)

### Entry Points
- [Glowly/GlowlyApp.swift](Glowly/GlowlyApp.swift) - App initialization
- [Glowly/ContentView.swift](Glowly/ContentView.swift) - Root navigation and auth state routing

## Design Patterns Used

- **MVVM** - Product management, Feed, Social features (ObservableObject + @Published)
- **MVP** - Authentication, Onboarding (Presenter pattern)
- **Protocol-based Dependency Injection** - All services inherit from protocols for testability
- **Async/Await** - Modern concurrency throughout (no callback hell)
- **Feature Flags** - Runtime feature toggles via FeatureFlags struct
- **Adaptive Design System** - Theme.swift with light/dark color pairs

## Environment Configuration

**Network Environments:**
```swift
// Located in NetworkConfiguration.swift
.development   // http://172.234.116.129:8080 (default)
.staging       // https://api-staging.glowly.app
.production    // https://api.glowly.app
.mock          // https://mock.glowly.app
```

**Feature Flags:**
```swift
// Toggle features in FeatureFlags.swift
isPremiumEnabled = true
requiresPremiumForPostCreation = true
useReelsFeed = true
enableAICaptions = true
enableProductTagging = true
```

## Known Technical Debt

1. **Data Persistence:** ProductStore uses UserDefaults - needs Core Data migration for scalability
2. **API Security:** Hardcoded API keys in APIConfig.swift - should use environment variables
3. **Mock Data:** FeedService, CommentService, WishListService use mock data - needs backend integration
4. **Error Handling:** Limited error handling in some flows - needs comprehensive error states
5. **Testing:** Minimal test coverage - needs unit tests for NetworkService, ProductStore, AuthManager
6. **Offline Sync:** No offline-first capability yet

**Backend Integration Status:**
- ❌ Server not set up - See [BACKEND_INTEGRATION_PLAN.md](BACKEND_INTEGRATION_PLAN.md) for step-by-step server setup instructions
- ❌ Database not configured - See [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) for complete schema
- ❌ API endpoints not implemented - See [AUTH_IMPLEMENTATION.md](AUTH_IMPLEMENTATION.md) for authentication code examples
- ❌ SMS service not integrated - Guide included in [BACKEND_INTEGRATION_PLAN.md](BACKEND_INTEGRATION_PLAN.md#sms-service-integration)
- ✅ iOS network layer: 100% ready for backend integration

## Important Models

**User Model:**
- Located in [Glowly/Modules/Authentication/Shared/Models/User.swift](Glowly/Modules/Authentication/Shared/Models/User.swift)
- Codable with authProvider enum (email, biometric, google)

**Product Model:**
- Located in [Glowly/Modules/Products/Models/Product.swift](Glowly/Modules/Products/Models/Product.swift)
- Comprehensive cosmetic data: ApplicationZone (face, eyes, lips, etc.), ingredients, usage instructions, benefits, warnings

**Social Models:**
- Post.swift, Comment.swift, WishListItem.swift for social features

## Security Notes

- **Keychain Usage:** All auth tokens stored securely via KeychainService
- **Biometric Auth:** Face ID/Touch ID properly configured with Info.plist
- **Development Security:** Info.plist allows arbitrary loads for development IP (172.234.116.129)
- **Production TODO:** Implement SSL pinning, jailbreak detection, remove hardcoded API keys

## Multi-language Support

Three language packs available:
- en.lproj (English)
- ru.lproj (Russian)
- kk.lproj (Kazakh)

Language switching via LanguageSwitcher component

## Debugging Tools

- **Network Logging:** Enable in NetworkConfiguration with `enableLogging = true`
- **Feature Flags:** Toggle features without recompiling
- **SwiftUI Previews:** Most views have #Preview macros
- **Sample Data:** 18 pre-loaded cosmetic products in ProductStore.swift (lines 142-304)

## External Integrations

- **Google Sign-In** - OAuth authentication
- **Claude/OpenAI/OpenRouter APIs** - AI features (configured in APIConfig.swift)
- **Keychain Framework** - Secure credential storage
- **Vision Framework** - Text recognition capabilities
- **Local Notifications** - Product expiration reminders

## When Making Changes

1. **Always read files before modifying** - Understand existing patterns
2. **Follow protocol-based DI** - All services should have protocol interfaces
3. **Use async/await** - No completion handlers or callbacks
4. **Respect Feature Flags** - Check FeatureFlags before accessing premium features
5. **Update localization** - Add strings to all three .lproj folders
6. **Maintain Theme consistency** - Use Theme.swift colors, never hardcoded hex
7. **Test with dark mode** - All colors should have light/dark variants
8. **Consider premium gates** - Post creation and some features require premium subscription
