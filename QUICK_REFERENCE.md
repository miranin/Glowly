# Glowly - Quick Reference Guide

**Project Name:** Glowly
**Bundle ID:** tamirlan-aubakirov.Glowly
**Platform:** iOS 18.2+ (originally 16.0+)
**Language:** Swift 5.0
**Architecture:** MVVM + Dependency Injection
**Last Updated:** 2025-12-04

---

## Project Summary

**Glowly** is an AI-powered beauty and cosmetics management app featuring:
- Personal cosmetic bag with product tracking
- AI recommendations based on skin profile
- TikTok-style social feed for product discovery
- GPT-4 powered beauty assistant
- Multi-language support (RU, EN, KZ)

**Business Model:** Freemium ($4.99/month for premium)

---

## Project Structure Overview

### Main Application (`/Glowly/`)

#### **Core** (Foundation Layer)
**Components:**
- `CachedAsyncImage.swift` - Smart image loader (cache://, http://, assets)
- `VideoPlayer/` - Video playback components
- `BottomSheetError.swift` - Error handling UI
- `SimpleTabBar.swift` - Custom tab bar

**Configuration:**
- `FeatureFlags.swift` - Feature toggles

**Localization:**
- `AppLanguage.swift` - Language management (RU, EN, KZ)
- `LanguageSwitcher.swift` - Language selector UI

**Services:**
- `ImageCacheService.swift` - NSCache-based image caching (100MB, 100 images)
- `HapticManager.swift` - Haptic feedback patterns

**Utilities:**
- `Theme.swift` - Colors, fonts, spacing

#### **Modules** (Feature Layer)

**Authentication:**
- `Login/` - Email/phone login, biometric auth
- `Registration/` - Signup with OTP verification
- `Shared/Services/`
  - `AuthManager.swift` - Auth orchestration
  - `KeychainService.swift` - Secure storage
  - `BiometricAuthService.swift` - Face ID/Touch ID

**Onboarding:**
- 7-step personalization flow
- `Models/` - UserProfile, SkinType, SkinCondition, BeautyGoal
- `Presenter/UserProfilePresenter.swift` - Profile management
- `Views/` - OnboardingWelcomeView, BasicInfo, SkinType, etc.

**Products:**
- `Models/Product.swift` - Product data model
- `Services/`
  - `ProductStore.swift` - CRUD operations
  - `NotificationService.swift` - Routine reminders
- `Views/` - ProductList, ProductDetail, AddProduct

**Social:**
- TikTok-style vertical feed with horizontal media carousel
- `Models/` - Post, Comment, WishListItem, SocialUserProfile
- `Services/`
  - `FeedService.swift` - Post management
  - `UserProfileService.swift` - User profiles (mock data)
  - `CommentService.swift` - Comments with likes
  - `WishListService.swift` - Saved products
- `Views/` - ReelsView, ReelCard, UserProfileView, CommentsView

**PostCreation:**
- Multi-image PhotosPicker integration
- Image caching with `cache://` URLs
- Product tagging from cosmetic bag

**AIHelper:**
- `Services/OpenRouterService.swift` - GPT-4-turbo integration
- `Views/AIHelperView.swift` - Chat interface

#### **Views** (Presentation Layer)
- `MainTabView.swift` - Tab bar controller
- `Feed/ReelsView.swift` - Primary social feed
- `Profile/SettingsView.swift` - User settings

---

## Architecture Patterns

### Design Pattern: MVVM
- **Views:** SwiftUI declarative UI
- **ViewModels:** ObservableObject with @Published properties
- **Models:** Codable structs
- **Services:** Business logic layer

### No Singletons
- Dependency injection via `@EnvironmentObject` and `@StateObject`
- No `shared` instances (unlike Lottery app)

### State Management
- `@StateObject` for owned state
- `@ObservedObject` for passed state
- `@Published` for reactive updates
- UserDefaults for persistence (temporary, planned: Core Data)

---

## Key Features Breakdown

### 1. Authentication
- Email/password (mock, no real backend)
- Phone number (+7 Kazakhstan/Russia)
- Google OAuth (mocked)
- Biometric (Face ID/Touch ID)
- Storage: UserDefaults + Keychain

### 2. Onboarding (7 Steps)
1. Welcome
2. Basic Info (name, age, sex)
3. Skin Type selection
4. Skin Conditions (multi-select)
5. Allergies & Sensitivities
6. Beauty Profile (experience, goals)
7. Preferences (frequency, complexity)
8. Completion: AI recommendations

**Haptic Feedback:** Progression pattern on each step, completion on finish

### 3. Product Management
- 16 pre-loaded sample products
- Categories: Foundation, concealer, serum, mascara, etc.
- Tracking: Purchase date, expiration, ingredients
- Operations: Add, edit, delete, filter, export
- Storage: UserDefaults (`SavedProducts`)

### 4. Social Feed (TikTok-Style)
- Vertical paging (swipe up/down between posts)
- Horizontal carousel (swipe left/right for media)
- Features: Like, comment, share, wishlist
- Preloading: First 3 posts + look-ahead loading
- Mock users: Beauty by Anna, Sephora Russia, Skincare with Maria

**Image Handling:**
- `cache://UUID` - NSCache lookup
- `https://...` - Remote URL
- Asset name - Local assets

### 5. Post Creation
1. PhotosPicker (multi-select)
2. Load images → cache with UUID keys
3. Add caption + tag products
4. Publish → FeedService

### 6. AI Helper
- GPT-4-turbo via OpenRouter API
- Context: User profile + product inventory
- Features: Skincare advice, recommendations, routines

### 7. Profile & Settings
- Profile photo upload
- WishList display (first 5 items)
- Language switcher (RU/EN/KZ)
- Account management:
  - **Reset Personalization:** Keep name, restart onboarding
  - **Delete Account:** Permanent deletion (irreversible)

---

## Data Models

### User (Authentication)
```swift
- id: String (UUID)
- email: String
- name: String?
- profilePhotoURL: String?
- authProvider: .email | .google
- isPremium: Bool
- createdAt: Date
```
**Storage:** UserDefaults (`user_{email}`) + Keychain (tokens)

### UserProfile (Personalization)
```swift
- hasCompletedOnboarding: Bool
- name, ageRange, sex
- skinType, skinTone, skinConditions
- allergies, sensitivities
- experienceLevel, beautyGoals
- makeupFrequency, skincareRoutineComplexity
- profilePhotoData: Data?
```
**Storage:** UserDefaults (`UserProfile`)

### Product
```swift
- id, name, brand, category
- applicationZone: face, eyes, lips, etc.
- purchaseDate, expiryMonths
- imageData: Data? (JPEG 80%)
- ingredients, howToUse, benefits, warnings
- isActive: Bool
```
**Storage:** UserDefaults (`SavedProducts`)

### Post (Social)
```swift
- id, userId, caption
- mediaItems: [PostMedia]  // type: .image/.video, url
- taggedProducts: [TaggedProduct]
- likesCount, commentsCount, sharesCount
- isLiked: Bool
- userType: .regular | .premium | .store
```
**Storage:** FeedService.posts (in-memory @Published)

---

## Dependencies

### Internal (No External Packages)
- SwiftUI, Combine, Foundation, UIKit
- PhotosUI - Image/video picker
- LocalAuthentication - Biometrics
- UserNotifications - Routine reminders

### External APIs
- **OpenRouter** (https://openrouter.ai/api/v1)
  - Model: `openai/gpt-4-turbo`
  - Authentication: Bearer token

### Planned
- Core Data (replace UserDefaults)
- CloudKit (sync)
- StoreKit 2 (in-app purchases)
- Firebase (analytics, crashlytics)

---

## Build Configuration

### Targets
1. **Glowly** (Main App)
2. **GlowlyTests** (Unit Tests)
3. **GlowlyUITests** (UI Tests)

### Configuration
- **Debug:** Development team: J9U97A9NY8
- **Release:** Marketing version: 1.0.0
- **Deployment:** iOS 18.2+
- **Localization:** English (primary), Russian, Kazakh

### Permissions
- Camera: "Для фотографирования косметических продуктов"
- Photo Library: "Для выбора фотографий косметических продуктов"
- Face ID: "Для быстрого и безопасного входа"

---

## Services Overview

### Core Services

**ImageCacheService**
- NSCache with 100MB limit, 100 images max
- Memory-aware caching
- Dependency injection via @EnvironmentObject

**HapticManager**
- selection(), lightImpact(), softImpact()
- mediumImpact(), heavyImpact(), rigidImpact()
- success(), warning(), error()
- progression(), completion(), doubleTap()

**ProductRecommendationEngine**
- AI-powered recommendations based on UserProfile
- Matches: Skin type, conditions, goals, experience
- Returns: Top 6 products with priority ranking

### Authentication Services

**AuthManager** (@Published state)
- signIn(), signUp(), signOut(), deleteAccount()
- enableBiometrics(), disableBiometrics()
- currentUser: User?, isAuthenticated: Bool

**KeychainService**
- save(), retrieveString(), delete()
- Keys: userToken, userId, refreshToken, userEmail

**BiometricAuthService**
- isBiometricAvailable() -> Bool
- biometricType() -> .faceID | .touchID | .none
- authenticateWithBiometrics()

### Product Services

**ProductStore** (@Published products)
- addProduct(), updateProduct(), deleteProduct()
- markProductUsed(), getProductsByCategory()
- shareExportURL() -> URL (JSON export)
- clearAllData()

**NotificationService**
- scheduleDailyRoutineReminder() - 9:00 AM
- scheduleEveningRoutineReminder() - 9:00 PM

### Social Services

**FeedService** (@Published posts)
- refresh(), addPost(), toggleLike()
- incrementCommentCount()
- Mock data with preloaded posts

**UserProfileService** (@Published userProfiles)
- loadUserProfile(userId)
- Request deduplication (Set tracking)
- Mock profiles: user1, store1, user2, user3, store2

**CommentService** (@Published comments)
- loadComments(for postId)
- addComment(), toggleCommentLike()
- Keyed by postId

**WishListService** (@Published wishListItems)
- addToWishList(), removeFromWishList()
- isInWishList() -> Bool
- clearAllWishList()

### AI Service

**OpenRouterService**
- chat(messages, model, stream) async throws -> String
- Base URL: https://openrouter.ai/api/v1
- Default model: openai/gpt-4-turbo

---

## Design System

### Colors (Theme.swift)
- accent: Primary brand color (pink/purple)
- accentDark, accentGradient
- success (green), danger (red), warning (orange)
- neutral, neutralLight, backgroundPowder

### Typography
- Large Title: 34pt bold
- Title: 28pt bold
- Body: 17pt regular
- Caption: 12pt regular

### Spacing
- Tight: 4-8pt
- Normal: 12-16pt
- Spacious: 20-24pt
- Sections: 32pt

### Corner Radius
- Buttons: 12-16pt
- Cards: 16-20pt
- Sheets: 24pt (top)

---

## Key Files Reference

| Purpose | File Path | Notes |
|---------|-----------|-------|
| App Entry | `GlowlyApp.swift:11` | @main, DI setup |
| Auth | `Modules/Authentication/Shared/Services/AuthManager.swift` | ObservableObject |
| Products | `Modules/Products/Services/ProductStore.swift` | CRUD operations |
| Social Feed | `Modules/Social/Views/ReelsView.swift` | TikTok-style feed |
| AI Chat | `Modules/AIHelper/Services/OpenRouterService.swift` | GPT integration |
| Image Cache | `Core/Services/ImageCacheService.swift` | NSCache 100MB |
| Haptics | `Core/Utilities/HapticManager.swift` | Feedback patterns |
| Theme | `Core/Theme/Theme.swift` | Design tokens |

---

## Documentation Files

- **PROJECT_OVERVIEW.md** (2100+ lines) - Comprehensive documentation
- **CODE_TEMPLATES.md** - Code patterns and examples
- **DARK_MODE_FIX_GUIDE.md** - Dark mode implementation
- **DARK_MODE_SUMMARY.md** - Dark mode status
- **LEAN_MVP_ROADMAP.md** - Product roadmap
- **NETWORK_LAYER_STRUCTURE.md** - Network architecture
- **REFACTORING_SUMMARY.md** - Refactoring history
- **API_INTEGRATION_TEST_PLAN.md** - API testing guide

---

## Quick Context Notes

**For Token Efficiency:**
- Beauty/cosmetics management app with AI recommendations
- Mock backend (no real API, UserDefaults storage)
- TikTok-inspired social feed with vertical/horizontal scrolling
- MVVM with dependency injection (no singletons)
- GPT-4-turbo for AI assistant
- Multi-language: Russian (primary), English, Kazakh
- Premium subscription UI (not implemented backend)

**Common Tasks:**
- Modifying UI → Check `Modules/[Feature]/Views/`
- Changing auth logic → `Modules/Authentication/Shared/Services/AuthManager.swift`
- Product management → `Modules/Products/Services/ProductStore.swift`
- Social feed → `Modules/Social/Services/FeedService.swift`
- AI integration → `Modules/AIHelper/Services/OpenRouterService.swift`
- Adding haptics → Use `HapticManager.shared.[method]()`
- Image caching → `@EnvironmentObject var imageCacheService: ImageCacheService`

**Key Differences from Lottery App:**
- **No Singletons:** All DI via @EnvironmentObject
- **Mock Data:** No real backend (vs Lottery's GraphQL + REST)
- **Social Focus:** TikTok-style feed (vs Lottery's game-focused UI)
- **Storage:** UserDefaults only (vs Lottery's more complex setup)
- **AI Integration:** Direct OpenRouter API (Lottery has none)

---

## Known Issues & Limitations

**Current Limitations:**
1. UserDefaults storage (temporary, no backup)
2. Mock authentication (no real backend, passwords not hashed)
3. Social features use mock data only
4. API key hardcoded (security risk)
5. No pagination on feed
6. Image cache limited to 100MB

**Planned Improvements:**
- [ ] Migrate to Core Data
- [ ] Implement real backend API
- [ ] Add CloudKit sync
- [ ] Proper authentication with JWT
- [ ] Add search functionality
- [ ] Implement barcode scanning
- [ ] Add push notifications

---

## Feature Flags (FeatureFlags.swift)

```swift
useReelsFeed = true              // TikTok vs classic feed
enableVideoPlayback = true        // Video posts
isPremiumEnabled = true           // Subscription system
showPremiumBadge = true           // Crown icon
enableAIChat = true               // GPT integration
enableProductScan = false         // Barcode scanning (future)
enableFaceScanner = false         // Face analysis (future)
enableARTryOn = false             // AR makeup (future)
```

---

*This quick reference complements the comprehensive PROJECT_OVERVIEW.md. For detailed architecture, data flows, and implementation details, refer to that document.*
