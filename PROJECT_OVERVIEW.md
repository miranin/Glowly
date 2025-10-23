# Glowly - AI-Powered Beauty & Cosmetics Management Platform

> **Version:** 1.0.0
> **Platform:** iOS (SwiftUI)
> **Architecture:** MVVM
> **Language:** Swift
> **Minimum iOS:** 16.0

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Design Patterns](#architecture--design-patterns)
3. [Core Features](#core-features)
4. [Technical Stack](#technical-stack)
5. [Module Structure](#module-structure)
6. [Data Models](#data-models)
7. [Services & Managers](#services--managers)
8. [User Flows](#user-flows)
9. [UI/UX Patterns](#uiux-patterns)
10. [State Management](#state-management)
11. [Data Persistence](#data-persistence)
12. [Feature Flags](#feature-flags)
13. [Localization](#localization)
14. [Dependencies](#dependencies)
15. [Build & Deployment](#build--deployment)

---

## Project Overview

**Glowly** is an AI-powered beauty and cosmetics management platform that helps users:
- Track their cosmetic products (expiration, purchase dates, ingredients)
- Get personalized skincare and makeup recommendations
- Discover and save products from other users via TikTok-style social feed
- Manage their beauty routine and product usage
- Share their cosmetic bag with friends

### Business Model
- **Freemium**: Free tier with basic features
- **Premium**: $4.99/month unlocks:
  - Advanced AI recommendations
  - Unlimited product storage
  - Priority customer support
  - Exclusive content access

### Target Audience
- Beauty enthusiasts (18-45 years old)
- Skincare beginners seeking guidance
- Makeup professionals organizing inventory
- People with sensitive skin needing ingredient tracking

---

## Architecture & Design Patterns

### MVVM (Model-View-ViewModel)

```
┌─────────────────────────────────────────┐
│              SwiftUI Views              │
│  (Declarative UI, State-Driven)         │
└──────────────┬──────────────────────────┘
               │ @ObservedObject
               │ @StateObject
┌──────────────▼──────────────────────────┐
│          ViewModels/Presenters          │
│  (Business Logic, State Management)     │
└──────────────┬──────────────────────────┘
               │ ObservableObject
               │ @Published
┌──────────────▼──────────────────────────┐
│         Models & Services               │
│  (Data, Networking, Persistence)        │
└─────────────────────────────────────────┘
```

### Key Principles
1. **No Singletons**: Dependency injection via `@EnvironmentObject` and `@StateObject`
2. **Separation of Concerns**: Views only handle UI, ViewModels handle logic
3. **Observable Pattern**: ViewModels publish state changes to Views
4. **Unidirectional Data Flow**: Data flows down, events flow up

---

## Core Features

### 1. Authentication & Onboarding

#### Authentication Methods
- **Email/Password**: Traditional signup with validation
- **Phone Number**: Support for +7 (Kazakhstan/Russia) format
- **Google OAuth**: Third-party authentication (mocked)
- **Biometric Login**: Face ID / Touch ID for quick access

#### Onboarding Flow (7 Steps)
1. **Welcome Screen**: Introduction to Glowly
2. **Basic Info**: Name, age range, sex
3. **Skin Type**: Normal, Dry, Oily, Combination, Sensitive
4. **Skin Conditions**: Acne, rosacea, hyperpigmentation, fine lines, etc.
5. **Allergies & Sensitivities**: Common allergens tracking
6. **Beauty Profile**: Experience level, beauty goals
7. **Preferences**: Makeup frequency, skincare routine complexity
8. **Completion**: Personalized product recommendations

**Key Features:**
- Lovi-inspired haptic feedback throughout
- Spring animations with smooth transitions
- AI-powered product recommendations based on user profile
- Horizontal scrollable product cards at completion
- Name preservation when resetting personalization

**Technical Details:**
- UserProfile stored in UserDefaults (JSON encoded)
- `hasCompletedOnboarding` flag determines app entry point
- ProductRecommendationEngine generates 6 top recommendations
- HapticManager provides tactile feedback (selection, progression, completion patterns)

### 2. Product Management (Cosmetic Bag)

#### Product Categories
```swift
enum ProductCategory: String, Codable, CaseIterable {
    case foundation, concealer, powder, blush, bronzer
    case highlighter, mascara, eyeliner, eyeshadow
    case lipstick, lipGloss, primer, cleanser
    case moisturizer, serum, sunscreen
}
```

#### Product Properties
- **Basic Info**: Name, brand, category, application zone
- **Dates**: Purchase date, expiration tracking
- **Images**: Photo capture or gallery selection (JPEG data)
- **Details**: Ingredients, how to use, benefits, warnings
- **Status**: Active/expired products
- **Barcode**: Optional barcode scanning (future feature)

#### Product Operations
- **Add Product**: Manual entry or barcode scan
- **Edit Product**: Update any property
- **Delete Product**: Remove from bag
- **Mark as Used**: Move to inactive state
- **Filter by Category**: View products by type
- **Export Cosmetic Bag**: JSON export for sharing

#### Sample Products
- 16 pre-loaded products with real images from Assets
- Detailed ingredient lists and usage instructions
- Realistic expiration dates (3-12 months)
- Added only on first app launch

**Technical Details:**
- Storage: UserDefaults (JSON encoded array)
- Images: JPEG data at 80% compression
- Notifications: Daily and evening routine reminders
- First launch flag prevents duplicate sample data

### 3. Social Feed (TikTok-Style Reels)

#### Feed Architecture
```
ReelsView (Vertical Scroll)
└── ReelCard (Single Post)
    ├── MediaCarousel (Horizontal TabView)
    │   ├── Photo/Video (Multiple media)
    │   └── Page Indicators
    ├── User Info Overlay
    │   ├── Profile Picture
    │   ├── Username & Caption
    │   └── Tagged Products
    └── Action Buttons
        ├── Like (Heart animation)
        ├── Comment (Sheet modal)
        ├── Share (System share)
        └── Wishlist (Add to saved)
```

#### Key Features
- **Vertical Paging**: Swipe up/down between posts
- **Horizontal Media**: Swipe left/right for multiple images/videos
- **Auto-play Videos**: Background playback with mute toggle
- **Gradient Overlays**: Text readability on images
- **User Profiles**: Tap to view full profile
- **Comments**: Real-time comment system with likes
- **Wishlist**: Save products from other users
- **Product Tags**: Clickable product references

#### Data Preloading Strategy
```swift
// Load first 3 posts on appear
func preloadData() {
    for i in 0..<min(3, posts.count) {
        loadUserProfile(posts[i].userId)
        loadComments(posts[i].id)
    }
}

// Look-ahead: Load current + next post
func preloadDataForIndex(_ index: Int) {
    loadData(for: posts[index])
    if index + 1 < posts.count {
        loadData(for: posts[index + 1])
    }
}
```

**Request Deduplication:**
- Services track loading requests in Set
- Prevents duplicate API calls for same data
- Caches loaded data in memory

#### Image Handling
- **CachedAsyncImage**: Custom component for three sources:
  - `cache://` prefix: NSCache lookup (user-created posts)
  - `http(s)://` prefix: Remote URL loading
  - Asset name: Local Assets.xcassets
- **NSCache**: Memory-aware cache (100MB limit, 100 images max)
- **Content Modes**: `.fit` for photos (letterbox), `.fill` for full bleed

**Technical Details:**
- Mock users: user1 (Beauty by Anna), store1 (Sephora Russia), user2 (Skincare with Maria)
- UserProfileService: User-specific mock profiles with proper IDs
- CommentService: Mock comments with like functionality
- WishListService: In-memory wishlist with product references

### 4. Post Creation

#### Creation Flow
1. **Photo Selection**: PhotosPicker (multiple selection)
2. **Load Images**: Async image loading from PhotosPickerItem
3. **Add Caption**: Multi-line text input
4. **Tag Products** (Optional): Link products from cosmetic bag
5. **Publish**: Create post with cached images

#### Image Pipeline
```swift
PhotosPickerItem
    → loadTransferable(type: Data.self)
    → UIImage(data:)
    → ImageCacheService.cacheImage(_:forKey:)
    → Post.media = [PostMedia(url: "cache://UUID")]
```

**Technical Details:**
- Images cached immediately on selection
- Cache keys: UUID strings
- Post references: `cache://` URL scheme
- FeedService: In-memory posts array (published)
- ReelsView: Reactive UI updates on new posts

### 5. AI Helper

#### GPT Integration
- **Provider**: OpenRouter API
- **Model**: GPT-4-turbo
- **Context**: User profile + product inventory
- **Features**:
  - Personalized skincare advice
  - Product recommendations
  - Routine building
  - Ingredient analysis
  - Skin concern troubleshooting

#### Conversation Flow
```swift
Messages (Chat History)
    ├── User Message
    ├── AI Response (Streaming)
    └── Context Injection
        ├── UserProfile.aiContextString
        └── Product inventory summary
```

**Technical Details:**
- OpenRouterService: API client with streaming support
- Message persistence: UserDefaults (conversation history)
- Context building: User profile + active products
- Markdown rendering: Simple text display (future: rich formatting)

### 6. Profile & Settings

#### Profile Features
- **Profile Photo**: Camera capture or gallery selection
- **User Info**: Name, product count, premium badge
- **WishList Display**: Horizontal scroll (first 5 items)
- **Account Management**:
  - Reset Personalization (restart onboarding)
  - Delete Account (permanent deletion)
- **Language Selection**: Russian, English, Kazakh (flag icons)
- **App Version**: Display current version
- **Logout**: Sign out (preserves account)

#### Account Management

**Reset Personalization:**
```swift
func resetPersonalizationAndRestartOnboarding() {
    let currentName = userProfile.name  // Preserve name
    userProfile = UserProfile()
    userProfile.name = currentName
    userProfile.hasCompletedOnboarding = false
    saveProfile()
}
```
- Clears all personalization data
- Preserves user's name from registration
- Sets `hasCompletedOnboarding = false`
- User goes through onboarding again
- New recommendations generated

**Delete Account:**
```swift
func deleteAccountCompletely() {
    authManager.deleteAccount()        // Remove from auth system
    userProfilePresenter.resetProfile() // Clear personalization
    productStore.clearAllData()        // Remove products
    wishListService.clearAllWishList() // Clear wishlist
}
```
- **Irreversible action**
- Removes user from UserDefaults: `user_{email}`, `currentUser_{id}`
- Clears all Keychain data: tokens, credentials
- Disables biometric login
- Clears all local data
- User cannot sign in again (userNotFound error)

**Difference: Logout vs Delete:**
- **Logout**: Temporary (clear session, keep account)
- **Delete**: Permanent (remove account, all data)

**Technical Details:**
- WishList: First 5 items shown, "+N more" button for rest
- Photo update: Immediate save with haptic feedback
- Biometric toggle: Only shown if Face ID/Touch ID available
- Language switcher: Flag buttons with selection indicator

---

## Technical Stack

### Frameworks & Libraries

```swift
// Core
import SwiftUI          // Declarative UI framework
import Combine          // Reactive programming
import Foundation       // Core Swift types

// UI Components
import PhotosUI         // PhotosPicker for image selection
import PDFKit           // PDF viewing (future: export reports)

// Storage & Security
import UserDefaults     // Simple data persistence (temporary)
import Keychain         // Secure credential storage

// System Integration
import LocalAuthentication  // Biometric authentication
import UIKit            // UIImage, haptics, share sheet

// Notifications
import UserNotifications  // Local push notifications
```

### External APIs
- **OpenRouter**: GPT-4-turbo AI chat (https://openrouter.ai)

### Future Dependencies (Planned)
- **Core Data**: Replace UserDefaults for robust persistence
- **CloudKit**: Cross-device sync
- **Firebase**: Analytics, crash reporting
- **Stripe**: Payment processing for premium subscriptions

---

## Module Structure

```
Glowly/
├── GlowlyApp.swift                    # App entry point, DI setup
├── ContentView.swift                  # Root view controller
├── Assets.xcassets/                   # Images, colors, icons
│   ├── AppIcon.appiconset
│   ├── DemoContentPhotos/             # Beauty product images
│   └── Colors/
│
├── Core/
│   ├── Configuration/
│   │   └── FeatureFlags.swift         # Feature toggle flags
│   ├── Services/
│   │   ├── ProductRecommendationEngine.swift  # AI recommendations
│   │   └── ImageCacheService.swift    # NSCache-based image caching
│   ├── Utilities/
│   │   ├── HapticManager.swift        # Haptic feedback patterns
│   │   └── Theme.swift                # App-wide colors, fonts
│   └── Components/
│       ├── CachedAsyncImage.swift     # Smart image loader
│       └── VideoPlayerView.swift      # Video playback
│
├── Modules/
│   ├── Authentication/
│   │   ├── Login/
│   │   │   ├── View/
│   │   │   │   └── LoginView.swift
│   │   │   └── ViewModel/
│   │   │       └── LoginViewModel.swift
│   │   ├── Registration/
│   │   │   ├── View/
│   │   │   │   ├── RegistrationView.swift
│   │   │   │   └── OTPVerificationView.swift
│   │   │   └── ViewModel/
│   │   │       └── RegistrationViewModel.swift
│   │   └── Shared/
│   │       ├── Models/
│   │       │   └── User.swift
│   │       └── Services/
│   │           ├── AuthManager.swift         # Auth orchestration
│   │           ├── KeychainService.swift     # Secure storage
│   │           └── BiometricAuthService.swift
│   │
│   ├── Onboarding/
│   │   ├── Models/
│   │   │   ├── UserProfile.swift            # Personalization data
│   │   │   ├── SkinType.swift
│   │   │   ├── SkinCondition.swift
│   │   │   ├── BeautyGoal.swift
│   │   │   └── ExperienceLevel.swift
│   │   ├── Presenter/
│   │   │   └── UserProfilePresenter.swift   # Profile management
│   │   ├── Views/
│   │   │   ├── OnboardingContainerView.swift  # Step coordinator
│   │   │   ├── OnboardingWelcomeView.swift
│   │   │   ├── OnboardingBasicInfoView.swift
│   │   │   ├── OnboardingSkinTypeView.swift
│   │   │   ├── OnboardingSkinConditionsView.swift
│   │   │   ├── OnboardingAllergiesView.swift
│   │   │   ├── OnboardingBeautyProfileView.swift
│   │   │   ├── OnboardingPreferencesView.swift
│   │   │   └── OnboardingCompletionView.swift  # + Recommendations
│   │   └── Components/
│   │       └── OnboardingComponents.swift   # Shared UI elements
│   │
│   ├── Products/
│   │   ├── Models/
│   │   │   └── Product.swift                # Product data model
│   │   ├── Services/
│   │   │   ├── ProductStore.swift           # Product CRUD
│   │   │   └── NotificationService.swift    # Routine reminders
│   │   └── Views/
│   │       ├── ProductListView.swift
│   │       ├── ProductDetailView.swift
│   │       └── AddProductView.swift
│   │
│   ├── Social/
│   │   ├── Models/
│   │   │   ├── Post.swift                   # Social post model
│   │   │   ├── Comment.swift
│   │   │   ├── WishListItem.swift
│   │   │   └── SocialUserProfile.swift
│   │   ├── Services/
│   │   │   ├── FeedService.swift            # Post management
│   │   │   ├── UserProfileService.swift     # User data
│   │   │   ├── CommentService.swift         # Comments
│   │   │   └── WishListService.swift        # Saved products
│   │   └── Views/
│   │       ├── ReelsView.swift              # TikTok-style feed
│   │       ├── ReelCard.swift               # Individual post
│   │       ├── UserProfileView.swift        # User profile sheet
│   │       └── CommentsView.swift           # Comments sheet
│   │
│   ├── PostCreation/
│   │   ├── Views/
│   │   │   └── CreatePostView.swift
│   │   └── ViewModels/
│   │       └── CreatePostViewModel.swift
│   │
│   └── AIHelper/
│       ├── Services/
│       │   └── OpenRouterService.swift      # GPT API client
│       └── Views/
│           └── AIHelperView.swift           # Chat interface
│
├── Views/
│   ├── MainTabView.swift                    # Tab bar controller
│   ├── Feed/
│   │   ├── FeedView.swift                   # Classic feed (legacy)
│   │   └── ReelsView.swift                  # New TikTok feed
│   ├── Profile/
│   │   └── SettingsView.swift               # User settings
│   └── AddProduct/
│       └── AddEntryChooserView.swift
│
└── Localization/
    └── LanguageManager.swift                # Multi-language support
```

---

## Data Models

### User
```swift
struct User: Codable, Identifiable {
    let id: String                  // UUID
    let email: String               // user@example.com or +7...
    var name: String?               // Display name
    var profilePhotoURL: String?    // Photo URL or nil
    let authProvider: AuthProvider  // .email or .google
    var isPremium: Bool = false     // Premium subscription status
    let createdAt: Date
    var lastLoginAt: Date
}

enum AuthProvider: String, Codable {
    case email, google
}
```

**Storage:**
- UserDefaults key: `user_{email}`
- Current user: `currentUser_{userId}`
- Keychain: `userToken`, `userId`, `refreshToken`, `userEmail`

### UserProfile (Personalization)
```swift
struct UserProfile: Codable {
    var id: UUID
    var hasCompletedOnboarding: Bool = false

    // Basic Info
    var name: String = ""
    var ageRange: AgeRange = .preferNotToSay
    var sex: Sex = .notSpecified

    // Skin Information
    var skinType: SkinType = .notSpecified
    var skinTone: SkinTone = .notSpecified
    var skinConditions: [SkinCondition] = []
    var allergies: [CommonAllergen] = []
    var sensitivities: [CommonAllergen] = []

    // Beauty Profile
    var experienceLevel: ExperienceLevel = .beginner
    var beautyGoals: [BeautyGoal] = []
    var preferredBrands: [String] = []

    // Preferences
    var makeupFrequency: MakeupFrequency = .occasionally
    var skincareRoutineComplexity: RoutineComplexity = .basic
    var preferredProductTypes: [ProductCategory] = []

    // Profile Photo
    var profilePhotoData: Data?

    // Metadata
    var lastUpdated: Date = Date()

    // AI Context
    var aiContextString: String { /* computed */ }
}
```

**Enums:**
```swift
enum SkinType: String, Codable, CaseIterable {
    case normal, dry, oily, combination, sensitive, notSpecified
}

enum SkinCondition: String, Codable, CaseIterable {
    case noIssues, acne, rosacea, eczema, psoriasis
    case hyperpigmentation, dryPatches, largesPores
    case fineLines, darkCircles, redness
}

enum BeautyGoal: String, Codable, CaseIterable {
    case antiAging, hydration, acneTreatment
    case brighten, evenTone, minimize
    case firmness, glowySkin
    case naturalLook, dramaticLook
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case beginner, intermediate, advanced, professional
}

enum RoutineComplexity: String, Codable, CaseIterable {
    case minimal    // 1-3 products
    case basic      // 4-6 products
    case moderate   // 7-9 products
    case extensive  // 10+ products
}
```

**Storage:** UserDefaults key: `UserProfile`

### Product
```swift
struct Product: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var brand: String
    var category: ProductCategory
    var applicationZone: ApplicationZone
    var purchaseDate: Date
    var expiryMonths: Int           // Typical: 6, 12, 24, 36
    var barcode: String?
    var imageData: Data?            // JPEG at 80% quality
    var notes: String
    var isActive: Bool = true

    // Detailed Information
    var ingredients: String = ""
    var howToUse: String = ""
    var benefits: [String] = []
    var warnings: [String] = []

    // Computed
    var expiryDate: Date { /* purchaseDate + months */ }
    var isExpiringSoon: Bool { /* < 30 days */ }
    var daysUntilExpiry: Int { /* days remaining */ }
}

enum ProductCategory: String, Codable, CaseIterable {
    case foundation, concealer, powder, blush, bronzer
    case highlighter, mascara, eyeliner, eyeshadow
    case lipstick, lipGloss, primer, cleanser
    case moisturizer, serum, sunscreen
}

enum ApplicationZone: String, Codable, CaseIterable {
    case face, eyes, lips, cheeks, body
}
```

**Storage:** UserDefaults key: `SavedProducts`

### Post (Social)
```swift
struct Post: Identifiable, Codable {
    let id: String                  // UUID
    let userId: String              // Author ID
    var caption: String
    var mediaItems: [PostMedia]     // Photos/videos
    var taggedProducts: [TaggedProduct]
    var likesCount: Int = 0
    var commentsCount: Int = 0
    var sharesCount: Int = 0
    var isLiked: Bool = false
    let createdAt: Date
    let userType: UserType          // .regular, .premium, .store
}

struct PostMedia: Identifiable, Codable {
    let id: String
    let type: MediaType             // .image or .video
    let url: String                 // "cache://UUID" or "https://..."
    var thumbnailUrl: String?
    var duration: TimeInterval?     // For videos
}

enum MediaType: String, Codable {
    case image, video
}

struct TaggedProduct: Identifiable, Codable {
    let id: String
    let productName: String
    let productBrand: String
    var productImage: String?
}
```

**Storage:** FeedService.posts (in-memory, @Published)

### Comment
```swift
struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let userId: String
    let userName: String
    var userAvatar: String?
    var content: String
    var likesCount: Int = 0
    var isLiked: Bool = false
    let createdAt: Date
}
```

**Storage:** CommentService.comments (in-memory, keyed by postId)

### WishListItem
```swift
struct WishListItem: Identifiable, Codable {
    let id: String = UUID().uuidString
    let productId: String           // Referenced product
    let productName: String
    let productBrand: String
    let category: String
    let imageUrl: String?
    let fromUserId: String          // User who posted it
    let fromUserName: String
    let addedAt: Date = Date()
}
```

**Storage:** WishListService.wishListItems (in-memory, @Published)

### SocialUserProfile
```swift
struct SocialUserProfile: Identifiable, Codable {
    let id: String
    let userName: String
    var bio: String?
    var avatarUrl: String?
    var isPremium: Bool = false
    var userType: Post.UserType = .regular
    var followers: Int = 0
    var following: Int = 0
    var posts: Int = 0
    var productPreviews: [ProductPreview] = []

    struct ProductPreview: Identifiable, Codable {
        let id: String
        let name: String
        let brand: String
        let category: String
        let imageUrl: String?
    }
}
```

**Storage:** UserProfileService.userProfiles (in-memory, keyed by userId)

---

## Services & Managers

### AuthManager
**Responsibility:** User authentication and session management

**Methods:**
```swift
// Sign-in
func signIn(email: String, password: String) async throws -> User
func signInWithGoogle(credentials: GoogleAuthCredentials) async throws -> User
func signInWithBiometrics() async throws -> User

// Sign-up
func signUp(email: String, password: String, name: String?) async throws -> User

// Biometrics
func enableBiometrics()
func disableBiometrics()

// Session
func signOut()
func deleteAccount()  // Permanent deletion
```

**State:**
```swift
@Published var currentUser: User?
@Published var isAuthenticated: Bool = false
@Published var isLoading: Bool = false
@Published var isBiometricEnabled: Bool = false
```

**Storage:**
- UserDefaults: `user_{email}`, `currentUser_{userId}`, `biometricEnabled`
- Keychain: `userToken`, `userId`, `refreshToken`, `userEmail`

### UserProfilePresenter
**Responsibility:** User personalization management

**Methods:**
```swift
func saveProfile()
func completeOnboarding()
func updateBasicInfo(name: String, ageRange: AgeRange, sex: Sex)
func updateSkinInfo(skinType: SkinType, skinTone: SkinTone, conditions: [SkinCondition])
func updateAllergies(_ allergies: [CommonAllergen], sensitivities: [CommonAllergen])
func updateBeautyProfile(level: ExperienceLevel, goals: [BeautyGoal])
func updatePreferences(makeupFrequency: MakeupFrequency, routineComplexity: RoutineComplexity)
func resetProfile()  // Complete reset
func resetPersonalizationAndRestartOnboarding()  // Reset but keep name
func syncWithAuthenticatedUser(_ user: User)
```

**State:**
```swift
@Published var userProfile: UserProfile
var needsOnboarding: Bool { !userProfile.hasCompletedOnboarding }
```

### ProductStore
**Responsibility:** Product inventory management

**Methods:**
```swift
func addProduct(_ product: Product)
func updateProduct(_ product: Product)
func deleteProduct(_ product: Product)
func markProductUsed(_ product: Product)
func getProductsByCategory(_ category: ProductCategory) -> [Product]
func shareExportURL() -> URL  // JSON export
func createShareableLink() -> String
func clearAllData()  // For account deletion
```

**State:**
```swift
@Published var products: [Product] = []
```

**Storage:** UserDefaults key: `SavedProducts`

### ImageCacheService
**Responsibility:** Memory-efficient image caching

**Implementation:**
```swift
@MainActor
class ImageCacheService: ObservableObject {
    private let imageCache = NSCache<NSString, UIImage>()

    init() {
        imageCache.totalCostLimit = 100 * 1024 * 1024  // 100MB
        imageCache.countLimit = 100                     // Max 100 images
        imageCache.name = "com.glowly.imagecache"
    }

    func cacheImage(_ image: UIImage, forKey key: String) {
        let cost = estimateImageSize(image)
        imageCache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func getImage(forKey key: String) -> UIImage? {
        imageCache.object(forKey: key as NSString)
    }

    private func estimateImageSize(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = 4 // RGBA
        return cgImage.width * cgImage.height * bytesPerPixel * Int(image.scale)
    }
}
```

**Dependency Injection:**
```swift
// GlowlyApp.swift
@StateObject private var imageCacheService = ImageCacheService()

var body: some Scene {
    WindowGroup {
        ContentView()
            .environmentObject(imageCacheService)
    }
}

// Usage in views
@EnvironmentObject private var imageCacheService: ImageCacheService
```

### HapticManager
**Responsibility:** Tactile feedback patterns

**Methods:**
```swift
// Basic Haptics
func selection()        // Light tap for UI selections
func lightImpact()      // Very light tap
func softImpact()       // Soft confirmation
func mediumImpact()     // Standard confirmation
func heavyImpact()      // Important action
func rigidImpact()      // Critical action

// Notifications
func success()          // Completed action
func warning()          // Warning message
func error()            // Error occurred

// Custom Patterns
func doubleTap()        // Two quick taps
func progression()      // Soft → Medium (moving forward)
func completion()       // Medium → Heavy → Success (finishing flow)
```

**Usage:**
```swift
Button("Continue") {
    HapticManager.shared.progression()
    navigateToNextStep()
}

Button("Delete Account") {
    HapticManager.shared.warning()
    showDeleteAlert = true
}

// On onboarding completion
HapticManager.shared.completion()
```

### ProductRecommendationEngine
**Responsibility:** AI-powered product recommendations

**Method:**
```swift
func generateRecommendations(for userProfile: UserProfile) -> [ProductRecommendation]
```

**Algorithm:**
1. **Skin Type Matching**: Recommends products for specific skin type
2. **Condition Treatment**: Targets specific skin conditions
3. **Goal Alignment**: Matches products to beauty goals
4. **Experience Level**: Suggests appropriate complexity
5. **Priority Ranking**: Sorts by importance (1-10)
6. **Top Selection**: Returns top 6 recommendations

**Example Output:**
```swift
struct ProductRecommendation: Identifiable {
    let id = UUID()
    let productName: String        // "Hydrating Cream"
    let brand: String              // "CeraVe"
    let category: String           // "Moisturizer"
    let reason: String             // "Rich hydration for dry skin"
    let priority: Int              // 10 (highest)
    let imageAsset: String?        // "beauty-1"
}
```

### FeedService
**Responsibility:** Social feed management

**Methods:**
```swift
func refresh()                     // Reload feed
func addPost(_ post: Post)         // Create post
func toggleLike(postId: String)    // Like/unlike
func incrementCommentCount(postId: String)
```

**State:**
```swift
@Published var posts: [Post] = []
@Published var isLoading: Bool = false
```

### UserProfileService
**Responsibility:** Social user profiles

**Methods:**
```swift
func loadUserProfile(userId: String)
```

**State:**
```swift
@Published var userProfiles: [String: SocialUserProfile] = [:]
@Published var isLoading: Bool = false
private var loadingUserIds: Set<String> = []  // Request deduplication
```

**Mock Data:**
- user1: "Beauty by Anna" (regular user)
- store1: "Sephora Russia" (verified store)
- user2: "Skincare with Maria" (premium user)
- user3: "Makeup Artist Pro" (professional)
- store2: "L'Oréal Official" (verified store)

### CommentService
**Responsibility:** Comment management

**Methods:**
```swift
func loadComments(for postId: String)
func addComment(postId: String, content: String, userId: String, userName: String)
func toggleCommentLike(postId: String, commentId: String)
```

**State:**
```swift
@Published var comments: [String: [Comment]] = [:]  // Keyed by postId
@Published var isLoading: Bool = false
private var loadingPostIds: Set<String> = []  // Request deduplication
```

### WishListService
**Responsibility:** Saved products management

**Methods:**
```swift
func addToWishList(product: SocialUserProfile.ProductPreview, fromUser: SocialUserProfile)
func removeFromWishList(itemId: String)
func isInWishList(productId: String) -> Bool
func clearAllWishList()  // For account deletion
```

**State:**
```swift
@Published var wishListItems: [WishListItem] = []
```

### OpenRouterService
**Responsibility:** GPT API integration

**Methods:**
```swift
func chat(
    messages: [ChatMessage],
    model: String = "openai/gpt-4-turbo",
    stream: Bool = false
) async throws -> String
```

**Configuration:**
```swift
private let baseURL = "https://openrouter.ai/api/v1"
private let apiKey: String  // From environment or config
```

### KeychainService
**Responsibility:** Secure credential storage

**Methods:**
```swift
func save(_ value: String, forKey key: String) -> Bool
func retrieveString(forKey key: String) -> String?
func delete(forKey key: String) -> Bool
```

**Keys:**
```swift
enum Keys {
    static let userToken = "userToken"
    static let userId = "userId"
    static let refreshToken = "refreshToken"
    static let userEmail = "userEmail"
}
```

### BiometricAuthService
**Responsibility:** Face ID / Touch ID authentication

**Methods:**
```swift
func isBiometricAvailable() -> Bool
func biometricType() -> BiometricType  // .faceID, .touchID, .none
func authenticateWithBiometrics(
    reason: String?,
    completion: @escaping (Result<Void, Error>) -> Void
)
```

### NotificationService
**Responsibility:** Local push notifications

**Methods:**
```swift
func requestPermission()
func scheduleDailyRoutineReminder()    // 9:00 AM
func scheduleEveningRoutineReminder()  // 9:00 PM
```

---

## User Flows

### 1. First-Time User Journey

```
App Launch
    ↓
Check hasCompletedOnboarding
    ↓ (false)
Show Onboarding
    ↓
Step 1: Welcome → "Начать"
    ↓
Step 2: Basic Info (Name, Age, Sex)
    ↓ [HapticManager.progression()]
Step 3: Skin Type Selection
    ↓ [HapticManager.progression()]
Step 4: Skin Conditions (Multi-select)
    ↓ [HapticManager.progression()]
Step 5: Allergies & Sensitivities
    ↓ [HapticManager.progression()]
Step 6: Beauty Profile (Level + Goals)
    ↓ [HapticManager.progression()]
Step 7: Preferences (Frequency + Complexity)
    ↓ [HapticManager.progression()]
Step 8: Completion Screen
    ↓
ProductRecommendationEngine.generateRecommendations()
    ↓
Show 6 personalized products
    ↓ [HapticManager.completion()]
"Начать использовать Glowly"
    ↓
userProfilePresenter.completeOnboarding()
    ↓
Navigate to MainTabView
```

### 2. Authentication Flow

```
LoginView
    ↓
Enter Email/Phone + Password
    ↓
[OR] Tap "Sign in with Google"
    ↓
[OR] Tap Face ID/Touch ID (if enabled)
    ↓
AuthManager.signIn()
    ↓
Check UserDefaults: user_{email}
    ↓ (not found)
throw AuthError.userNotFound
    ↓ (found)
Load User object
    ↓
handleSuccessfulAuth()
    ↓
Set currentUser, isAuthenticated = true
    ↓
Save to Keychain: userToken, userId
    ↓
Navigate to MainTabView (or Onboarding)
```

### 3. Product Addition Flow

```
MainTabView → Tap "+" FAB
    ↓
AddEntryChooserView
    ↓
Choose "Добавить продукт"
    ↓
AddProductView
    ↓
Fill form:
    - Name, Brand
    - Category (dropdown)
    - Application Zone
    - Purchase Date (date picker)
    - Expiry Months (stepper)
    - Photo (camera/gallery)
    - Notes (optional)
    ↓
Tap "Сохранить"
    ↓
ProductStore.addProduct()
    ↓
Encode to JSON
    ↓
Save to UserDefaults: SavedProducts
    ↓
Publish update (@Published products)
    ↓
UI refreshes (ProductListView)
    ↓
[HapticManager.success()]
    ↓
Dismiss sheet
```

### 4. Post Creation Flow

```
MainTabView → Tap "+" FAB
    ↓
AddEntryChooserView
    ↓
Choose "Создать пост"
    ↓
CreatePostView
    ↓
Tap "Выбрать фото"
    ↓
PhotosPicker (multi-selection)
    ↓
User selects photos
    ↓
For each PhotosPickerItem:
    ↓
    loadTransferable(type: Data.self)
    ↓
    UIImage(data:)
    ↓
    ImageCacheService.cacheImage(image, forKey: UUID)
    ↓
    Store cache key
    ↓
Add caption (text field)
    ↓
Tap "Опубликовать"
    ↓
CreatePostViewModel.publishPost()
    ↓
Create PostMedia array:
    [PostMedia(url: "cache://UUID1"), ...]
    ↓
Create Post object
    ↓
FeedService.addPost(post)
    ↓
Publish update (@Published posts)
    ↓
ReelsView refreshes
    ↓
[HapticManager.success()]
    ↓
Dismiss sheet
```

### 5. Social Interaction Flow

```
ReelsView (Feed)
    ↓
User swipes up/down → View posts
    ↓
User swipes left/right → View media carousel
    ↓
[ON APPEAR] preloadData()
    - Load first 3 posts
    - UserProfileService.loadUserProfile()
    - CommentService.loadComments()
    ↓
[ON INDEX CHANGE] preloadDataForIndex()
    - Load current + next post
    ↓
User taps "❤️ Like"
    ↓
FeedService.toggleLike(postId)
    ↓
[HapticManager.softImpact()]
    ↓
Heart animation
    ↓
User taps "💬 Comment"
    ↓
CommentsView sheet
    ↓
Load comments for post
    ↓
User types comment → "Отправить"
    ↓
CommentService.addComment()
    ↓
[HapticManager.success()]
    ↓
User taps username
    ↓
UserProfileView sheet
    ↓
UserProfileService.loadUserProfile(userId)
    ↓
Show profile (bio, products, stats)
    ↓
User taps product
    ↓
WishListService.addToWishList()
    ↓
[HapticManager.success()]
```

### 6. Account Management Flow

```
SettingsView → Profile Tab
    ↓
Scroll to "Управление профилем"
    ↓
[OPTION 1] Tap "Сбросить персонализацию"
    ↓
    [HapticManager.lightImpact()]
    ↓
    Alert: "Сбросить персонализацию?"
    ↓
    User taps "Сбросить"
    ↓
    [HapticManager.warning()]
    ↓
    userProfilePresenter.resetPersonalizationAndRestartOnboarding()
        - Keep name
        - Clear all other data
        - Set hasCompletedOnboarding = false
    ↓
    [HapticManager.success()]
    ↓
    Next navigation shows OnboardingContainerView
    ↓
    User completes onboarding again
    ↓
    New recommendations generated

[OPTION 2] Tap "Удалить аккаунт"
    ↓
    [HapticManager.warning()]
    ↓
    Alert: "Удалить аккаунт?"
    ↓
    User taps "Удалить навсегда"
    ↓
    [HapticManager.error()]
    ↓
    deleteAccountCompletely()
        1. authManager.deleteAccount()
           - Remove user_{email}
           - Remove currentUser_{id}
           - Clear Keychain
           - Disable biometrics
        2. userProfilePresenter.resetProfile()
        3. productStore.clearAllData()
        4. wishListService.clearAllWishList()
    ↓
    [HapticManager.success()]
    ↓
    Navigate to LoginView
    ↓
    User tries to sign in
    ↓
    throws AuthError.userNotFound
    ↓
    Show error: "Пользователь не найден"
```

---

## UI/UX Patterns

### Design System

**Colors (Theme.swift):**
```swift
// Brand Colors
static let accent = Color("AccentColor")       // Primary pink/purple
static let accentDark = Color("AccentDark")
static let accentGradient = LinearGradient(...)

// Semantic Colors
static let success = Color.green
static let danger = Color.red
static let warning = Color.orange

// Neutral Colors
static let neutral = Color.gray
static let neutralLight = Color(.systemGray6)
static let backgroundPowder = Color(.systemBackground)
```

**Typography:**
```swift
// Headers
.font(.largeTitle)              // 34pt, bold
.font(.title)                   // 28pt, bold
.font(.title2)                  // 22pt, semibold

// Body
.font(.headline)                // 17pt, semibold
.font(.body)                    // 17pt, regular
.font(.subheadline)             // 15pt, regular

// Small
.font(.caption)                 // 12pt, regular
.font(.caption2)                // 11pt, regular
```

**Spacing:**
- Tight: 4-8pt
- Normal: 12-16pt
- Spacious: 20-24pt
- Sections: 32pt

**Corner Radius:**
- Buttons: 12-16pt
- Cards: 16-20pt
- Sheets: 24pt (top corners)

### Animation Patterns

**Spring Animations:**
```swift
.animation(.spring(response: 0.5, dampingFraction: 0.8), value: showContent)
```

**Transitions:**
```swift
// Slide + Fade
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))

// Scale + Fade
.transition(.scale.combined(with: .opacity))
```

**Button Press Effect:**
```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
```

**Loading States:**
```swift
if isLoading {
    ProgressView()
        .scaleEffect(1.5)
} else {
    content
}
```

### Haptic Patterns

**Selection Actions:**
- Button taps: `HapticManager.shared.selection()`
- Toggle switches: `HapticManager.shared.lightImpact()`

**Navigation:**
- Forward: `HapticManager.shared.progression()`
- Back: `HapticManager.shared.lightImpact()`

**Success/Error:**
- Success: `HapticManager.shared.success()`
- Warning: `HapticManager.shared.warning()`
- Error: `HapticManager.shared.error()`

**Complex Actions:**
- Delete: `HapticManager.shared.warning()` → Confirm → `HapticManager.shared.error()`
- Complete flow: `HapticManager.shared.completion()` (3-stage pattern)

### Navigation Patterns

**Tab Bar:**
```swift
enum Tab: String, CaseIterable {
    case feed = "house.fill"
    case products = "bag.fill"
    case create = "plus.circle.fill"
    case ai = "brain.head.profile"
    case profile = "person.fill"
}
```

**Modal Sheets:**
- `.sheet(isPresented:)` for non-critical views
- `.fullScreenCover(isPresented:)` for important flows
- Custom dismiss with swipe gesture

**Alerts:**
- Confirmation dialogs for destructive actions
- Simple alerts for errors/info

---

## State Management

### Observable Pattern

```swift
// Service Layer
class FeedService: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading: Bool = false
}

// View Layer
struct ReelsView: View {
    @StateObject var feedService: FeedService

    var body: some View {
        // UI automatically updates when @Published properties change
    }
}
```

### Dependency Injection

**Environment Objects (Shared State):**
```swift
// App Level
@main
struct GlowlyApp: App {
    @StateObject private var imageCacheService = ImageCacheService()
    @StateObject private var languageManager = LanguageManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageCacheService)
                .environmentObject(languageManager)
        }
    }
}

// View Level
struct SomeView: View {
    @EnvironmentObject var imageCacheService: ImageCacheService
    @EnvironmentObject var languageManager: LanguageManager
}
```

**State Objects (Owned State):**
```swift
struct ParentView: View {
    @StateObject private var feedService = FeedService()

    var body: some View {
        ChildView(feedService: feedService)
    }
}

struct ChildView: View {
    @ObservedObject var feedService: FeedService
}
```

### State Persistence

**UserDefaults (Temporary Storage):**
```swift
// Save
let encoded = try JSONEncoder().encode(object)
UserDefaults.standard.set(encoded, forKey: "key")

// Load
let data = UserDefaults.standard.data(forKey: "key")
let object = try JSONDecoder().decode(Type.self, from: data)
```

**Keychain (Secure Storage):**
```swift
// Save
KeychainService().save("token", forKey: "userToken")

// Retrieve
let token = KeychainService().retrieveString(forKey: "userToken")
```

**NSCache (Memory-Only):**
```swift
let cache = NSCache<NSString, UIImage>()
cache.setObject(image, forKey: "key" as NSString)
let cached = cache.object(forKey: "key" as NSString)
```

---

## Data Persistence

### Current Implementation (UserDefaults)

**Stored Data:**
```swift
// Authentication
user_{email} → User object
currentUser_{userId} → User object
biometricEnabled → Bool

// Personalization
UserProfile → UserProfile object

// Products
SavedProducts → [Product]
hasLaunchedBefore → Bool (prevents duplicate samples)

// AI Chat
aiMessages → [ChatMessage]
```

**Limitations:**
- ⚠️ Not suitable for large datasets
- ⚠️ No relational queries
- ⚠️ Risk of data loss (no backup)
- ⚠️ No cross-device sync

### Planned Migration (Core Data)

**Future Schema:**
```
User (Entity)
    - id: UUID
    - email: String
    - name: String
    - isPremium: Bool
    - createdAt: Date
    - relationship: userProfile (one-to-one)
    - relationship: products (one-to-many)

UserProfile (Entity)
    - id: UUID
    - skinType: String
    - beautyGoals: [String]
    - lastUpdated: Date
    - relationship: user (one-to-one)

Product (Entity)
    - id: UUID
    - name: String
    - brand: String
    - purchaseDate: Date
    - imageData: Binary Data
    - relationship: user (many-to-one)

Post (Entity)
    - id: UUID
    - caption: String
    - likesCount: Int
    - createdAt: Date
    - relationship: media (one-to-many)
    - relationship: author (many-to-one)
```

**Benefits:**
- ✅ Efficient queries with NSPredicate
- ✅ Relationships between entities
- ✅ Automatic data validation
- ✅ iCloud sync support
- ✅ Batch operations
- ✅ Undo/redo support

---

## Feature Flags

**File:** `Core/Configuration/FeatureFlags.swift`

```swift
struct FeatureFlags {
    // Social Features
    static let useReelsFeed = true          // TikTok-style vs classic feed
    static let enableVideoPlayback = true    // Video posts

    // Premium Features
    static let isPremiumEnabled = true       // Subscription system
    static let showPremiumBadge = true       // Crown icon

    // AI Features
    static let enableAIChat = true           // GPT integration
    static let enableProductScan = false     // Barcode scanning (future)

    // Experimental
    static let enableFaceScanner = false     // Lovi-style face analysis
    static let enableARTryOn = false         // AR makeup try-on
}
```

**Usage:**
```swift
if FeatureFlags.useReelsFeed {
    ReelsView(...)
} else {
    FeedView(...)
}
```

---

## Localization

**Supported Languages:**
- 🇷🇺 Russian (default)
- 🇬🇧 English
- 🇰🇿 Kazakh

**Implementation:**
```swift
class LanguageManager: ObservableObject {
    @Published var currentLanguage: Language = .russian

    enum Language: String, CaseIterable {
        case russian = "ru"
        case english = "en"
        case kazakh = "kz"
    }

    func translate(_ key: String) -> String {
        // Dictionary lookup based on currentLanguage
    }
}
```

**Usage:**
```swift
@EnvironmentObject var languageManager: LanguageManager

Text(languageManager.translate("profile_title"))
```

**Translation Keys (Examples):**
```
profile_title → "Профиль" / "Profile" / "Профиль"
profile_logout → "Выйти" / "Logout" / "Шығу"
profile_wishlist → "WishList" / "WishList" / "WishList"
```

---

## Dependencies

### Internal (No External Packages)

**Swift Frameworks:**
- SwiftUI
- Combine
- Foundation
- UIKit
- PhotosUI
- LocalAuthentication
- UserNotifications
- PDFKit

### External APIs
- **OpenRouter**: https://openrouter.ai/api/v1
  - Model: `openai/gpt-4-turbo`
  - Authentication: Bearer token
  - Rate limits: Check API docs

### Future Dependencies (Planned)

**Analytics:**
- Firebase Analytics
- Crashlytics

**Payments:**
- StoreKit 2 (in-app purchases)
- RevenueCat (subscription management)

**Storage:**
- CloudKit (iCloud sync)
- Firebase Firestore (alternative)

**Media:**
- Kingfisher (advanced image loading)
- AVFoundation (video recording)

---

## Build & Deployment

### Xcode Configuration

**Project Settings:**
- Product Name: Glowly
- Bundle Identifier: com.glowly.app
- Team: [Your Team]
- Deployment Target: iOS 16.0+
- Swift Version: 5.9+

**Build Configurations:**
- Debug: Development with verbose logging
- Release: Optimized for App Store

### Environment Variables

**Required:**
```swift
// Config/Secrets.swift (not committed)
struct Secrets {
    static let openRouterAPIKey = "YOUR_API_KEY"
    static let googleClientID = "YOUR_CLIENT_ID"
}
```

### Asset Catalog

**AppIcon.appiconset:**
- 1024×1024 (App Store)
- 60×60@2x (iPhone)
- 76×76@2x (iPad)
- 83.5×83.5@2x (iPad Pro)

**Demo Content:**
- beauty-1.jpg → beauty-3.jpg (product photos)
- Sample product images for social feed

### App Store Metadata

**Categories:**
- Primary: Health & Fitness
- Secondary: Lifestyle

**Keywords:**
- beauty, cosmetics, skincare, makeup
- ai, personalized, recommendations
- product tracker, expiration

**Privacy:**
- Camera: Product photos
- Photo Library: Profile pictures, post creation
- Face ID: Biometric authentication
- Notifications: Routine reminders

---

## Testing Strategy

### Unit Tests (Future)
- AuthManager authentication logic
- ProductRecommendationEngine algorithm
- UserProfile validation
- Data encoding/decoding

### Integration Tests (Future)
- Authentication flow end-to-end
- Product CRUD operations
- Feed loading and interaction
- API integration (OpenRouter)

### UI Tests (Future)
- Onboarding completion
- Product addition flow
- Post creation and publishing
- Settings navigation

### Manual Testing Checklist

**Authentication:**
- [ ] Email/password signup
- [ ] Email/password login
- [ ] Google OAuth (mocked)
- [ ] Biometric login
- [ ] Logout
- [ ] Account deletion

**Onboarding:**
- [ ] Complete 7-step flow
- [ ] See personalized recommendations
- [ ] Reset personalization

**Products:**
- [ ] Add product with photo
- [ ] Edit product
- [ ] Delete product
- [ ] Filter by category
- [ ] Export cosmetic bag

**Social:**
- [ ] View reels feed
- [ ] Swipe vertical/horizontal
- [ ] Like/unlike posts
- [ ] Add comments
- [ ] View user profiles
- [ ] Add to wishlist

**Post Creation:**
- [ ] Select multiple photos
- [ ] Add caption
- [ ] Publish post
- [ ] View in feed

---

## Known Issues & Limitations

### Current Limitations

1. **Data Storage:**
   - UserDefaults is temporary solution
   - No offline sync
   - Risk of data loss

2. **Authentication:**
   - Mock implementation (no real backend)
   - Passwords not hashed
   - No session expiration

3. **Social Features:**
   - Mock data only (no real users)
   - No real-time updates
   - Images stored in memory (NSCache)

4. **AI Integration:**
   - API key hardcoded (insecure)
   - No conversation history limit
   - No streaming UI feedback

5. **Performance:**
   - Large product lists may lag
   - Image cache limited to 100MB
   - No pagination on feed

### Future Improvements

**High Priority:**
- [ ] Migrate to Core Data for persistence
- [ ] Implement real backend API
- [ ] Add CloudKit sync
- [ ] Implement proper authentication with JWT
- [ ] Add image compression pipeline
- [ ] Implement pagination on feed

**Medium Priority:**
- [ ] Add search functionality
- [ ] Implement product barcode scanning
- [ ] Add AR makeup try-on
- [ ] Implement push notifications
- [ ] Add social sharing (Instagram, TikTok)
- [ ] Implement in-app purchases

**Low Priority:**
- [ ] Add dark mode support
- [ ] Implement widgets
- [ ] Add Apple Watch companion
- [ ] Implement Shortcuts support
- [ ] Add accessibility improvements

---

## Development Guidelines

### Code Style

**Naming Conventions:**
```swift
// Types: PascalCase
class ProductStore { }
struct UserProfile { }
enum ProductCategory { }

// Properties/Methods: camelCase
var userName: String
func addProduct(_ product: Product)

// Constants: camelCase
let maxProducts = 100

// Private properties: underscore prefix (optional)
private var _cache: [String: UIImage]
```

**File Organization:**
```swift
// MARK: - Type Definition
struct MyView: View { }

// MARK: - Properties
@State private var isLoading = false

// MARK: - Body
var body: some View { }

// MARK: - Subviews
private var headerView: some View { }

// MARK: - Methods
private func loadData() { }

// MARK: - Preview
#Preview { MyView() }
```

**SwiftUI Best Practices:**
```swift
// ✅ Extract complex views
var complexSection: some View {
    VStack { ... }
}

// ✅ Use computed properties for logic
var filteredProducts: [Product] {
    products.filter { $0.isActive }
}

// ✅ Avoid nested ternaries
let text = isLoading ? "Loading..." : products.isEmpty ? "Empty" : "Loaded"
// Better:
var statusText: String {
    if isLoading { return "Loading..." }
    if products.isEmpty { return "Empty" }
    return "Loaded"
}
```

### Git Workflow

**Branch Naming:**
```
feature/GLOWLY-XXX-description
bugfix/GLOWLY-XXX-description
hotfix/critical-issue
```

**Commit Messages:**
```
[GLOWLY-XXX] Add product recommendation engine

- Implement skin type matching algorithm
- Add priority-based ranking
- Create ProductRecommendation model
- Integrate with OnboardingCompletionView
```

**PR Template:**
```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Refactoring
- [ ] Documentation

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing completed
- [ ] Build succeeds

## Screenshots (if applicable)
```

---

## Changelog

### Version 1.0.0 (Current)

**Features:**
- ✅ Complete authentication system (email, phone, biometric)
- ✅ 7-step personalization onboarding
- ✅ AI-powered product recommendations
- ✅ Cosmetic bag management (16 sample products)
- ✅ TikTok-style social feed with reels
- ✅ Post creation with multi-image support
- ✅ Comments and likes system
- ✅ Wishlist functionality
- ✅ GPT-4 AI chat assistant
- ✅ Profile settings and account management
- ✅ Multi-language support (RU, EN, KZ)
- ✅ Haptic feedback system
- ✅ Premium subscription UI

**Bug Fixes:**
- ✅ Fixed account deletion (proper user removal)
- ✅ Fixed width inconsistency in settings sections
- ✅ Fixed image caching memory leaks (NSCache)
- ✅ Fixed product data loss on app launch
- ✅ Fixed white screens in social profiles
- ✅ Fixed like count going negative
- ✅ Removed redundant profile edit feature

**Technical Improvements:**
- ✅ Removed singleton pattern (dependency injection)
- ✅ Implemented data preloading for smooth scrolling
- ✅ Added request deduplication for services
- ✅ Improved image handling (fit vs fill)
- ✅ Enhanced animations with spring physics

---

## Support & Contribution

### For Developers

**Getting Started:**
1. Clone repository
2. Open `Glowly.xcodeproj`
3. Add `Config/Secrets.swift` with API keys
4. Build and run on simulator or device

**Questions?**
- Read this document first
- Check code comments
- Review git commit history

### For AI Models

**Understanding this Project:**
This document provides complete context for:
- Architecture decisions (MVVM, no singletons)
- Data flow (ObservableObject pattern)
- Feature implementation details
- Known limitations and future plans

**When Making Changes:**
1. Update this document's relevant sections
2. Follow established patterns (see Code Style)
3. Maintain consistency with existing UX
4. Test thoroughly before committing
5. Update changelog at bottom of document

**Key Patterns to Maintain:**
- Dependency injection via `@EnvironmentObject`
- Haptic feedback on all user interactions
- Spring animations for smooth transitions
- Data preloading for performance
- Proper error handling with user-friendly messages

---

**Last Updated:** 2025-10-23
**Document Version:** 1.0.0
**Maintained By:** Development Team
