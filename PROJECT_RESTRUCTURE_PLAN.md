# 🏗️ Project Restructure Plan - Micro-Module Architecture

## 🎯 Current Issues

1. **Multiple models in single files** - Product.swift contains Product + ProductCategory
2. **Mixed responsibilities** - Views, ViewModels, Presenters not clearly separated
3. **No clear module boundaries** - Hard to test and maintain
4. **Inconsistent organization** - Some features follow MVP, others don't

---

## 📐 Target Structure

### Clean Micro-Module Architecture

```
Glowly/
├── App/
│   ├── GlowlyApp.swift
│   ├── ContentView.swift
│   └── Info.plist
│
├── Core/                           # Shared across all modules
│   ├── Theme/
│   │   ├── Theme.swift
│   │   ├── ColorExtensions.swift
│   │   └── GradientStyles.swift
│   ├── Extensions/
│   │   ├── View+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── String+Extensions.swift
│   ├── Components/                 # Reusable UI components
│   │   ├── KeyboardDismissalModifier.swift
│   │   ├── LoadingView.swift
│   │   └── ErrorView.swift
│   └── Utilities/
│       ├── Constants.swift
│       └── Helpers.swift
│
├── Modules/
│   │
│   ├── Authentication/            # Already well-structured
│   │   ├── Login/
│   │   │   ├── Model/
│   │   │   ├── View/
│   │   │   │   └── LoginView.swift
│   │   │   └── Presenter/
│   │   │       └── LoginPresenter.swift
│   │   ├── Registration/
│   │   │   ├── Model/
│   │   │   ├── View/
│   │   │   │   └── RegistrationView.swift
│   │   │   └── Presenter/
│   │   │       └── RegistrationPresenter.swift
│   │   └── Shared/
│   │       ├── Models/
│   │       │   ├── User.swift
│   │       │   └── AuthToken.swift
│   │       └── Services/
│   │           ├── AuthManager.swift
│   │           ├── KeychainService.swift
│   │           ├── BiometricAuthService.swift
│   │           └── GoogleSignInService.swift
│   │
│   ├── Onboarding/                # Needs restructure
│   │   ├── Models/
│   │   │   ├── UserProfile.swift       # Renamed from UserProfileModel
│   │   │   ├── AgeRange.swift
│   │   │   ├── SkinType.swift
│   │   │   ├── SkinTone.swift
│   │   │   ├── SkinCondition.swift
│   │   │   ├── ExperienceLevel.swift
│   │   │   ├── BeautyGoal.swift
│   │   │   ├── CommonAllergen.swift
│   │   │   ├── MakeupFrequency.swift
│   │   │   └── RoutineComplexity.swift
│   │   ├── Views/
│   │   │   ├── OnboardingContainerView.swift
│   │   │   ├── OnboardingWelcomeView.swift
│   │   │   ├── OnboardingBasicInfoView.swift
│   │   │   ├── OnboardingSkinTypeView.swift
│   │   │   ├── OnboardingSkinConditionsView.swift
│   │   │   ├── OnboardingAllergiesView.swift
│   │   │   ├── OnboardingBeautyProfileView.swift
│   │   │   ├── OnboardingPreferencesView.swift
│   │   │   ├── OnboardingCompletionView.swift
│   │   │   └── Components/
│   │   │       └── OnboardingComponents.swift
│   │   └── Presenter/
│   │       └── UserProfilePresenter.swift
│   │
│   ├── Products/                  # Needs restructure
│   │   ├── Models/
│   │   │   ├── Product.swift
│   │   │   └── ProductCategory.swift
│   │   ├── Views/
│   │   │   ├── List/
│   │   │   │   ├── BagListView.swift
│   │   │   │   ├── ProductCard.swift
│   │   │   │   └── ProductGridCard.swift
│   │   │   ├── Detail/
│   │   │   │   ├── ProductDetailSheet.swift
│   │   │   │   ├── ProductDetailSimpleSheet.swift
│   │   │   │   └── ShowcaseCard.swift
│   │   │   ├── Add/
│   │   │   │   ├── AddEntryChooserView.swift
│   │   │   │   ├── AddProductView.swift
│   │   │   │   ├── AddProductSimpleView.swift
│   │   │   │   ├── CameraAddProductView.swift
│   │   │   │   └── ProductConfirmationView.swift
│   │   │   └── Components/
│   │   │       ├── CircularProductSelector.swift
│   │   │       ├── SwipeCard.swift
│   │   │       └── ImagePicker.swift
│   │   ├── Presenter/
│   │   │   └── ProductPresenter.swift        # New - extract from ProductStore
│   │   └── Services/
│   │       ├── ProductStore.swift            # Keep as repository
│   │       └── ImageRecognitionService.swift
│   │
│   ├── AIChat/                    # Needs restructure
│   │   ├── Models/
│   │   │   ├── ChatMessage.swift
│   │   │   └── ChatSession.swift
│   │   ├── Views/
│   │   │   ├── AIHelperView.swift
│   │   │   └── Components/
│   │   │       ├── MessageBubble.swift
│   │   │       └── QuickActionButton.swift
│   │   ├── Presenter/
│   │   │   └── AIChatPresenter.swift        # New - extract logic
│   │   └── Services/
│   │       └── AIService.swift              # New - for backend integration
│   │
│   ├── Profile/                   # Needs restructure
│   │   ├── Models/
│   │   │   └── ProfileSettings.swift        # New
│   │   ├── Views/
│   │   │   ├── SettingsView.swift
│   │   │   ├── ProfileEditView.swift
│   │   │   └── Components/
│   │   │       ├── CompactSection.swift
│   │   │       ├── CompactTextField.swift
│   │   │       ├── CompactPicker.swift
│   │   │       ├── TagsView.swift
│   │   │       └── LargeTagsView.swift
│   │   └── Presenter/
│   │       └── ProfilePresenter.swift       # New
│   │
│   └── Notifications/             # Needs restructure
│       ├── Models/
│       │   └── NotificationConfig.swift     # New
│       ├── Views/
│       │   └── NotificationsView.swift
│       ├── Presenter/
│       │   └── NotificationPresenter.swift  # New
│       └── Services/
│           └── NotificationService.swift
│
└── Services/                      # Global services
    ├── HapticsService.swift
    ├── PDFExportService.swift
    └── Network/                   # To be created
        ├── NetworkService.swift
        ├── APIEndpoints.swift
        └── NetworkError.swift
```

---

## 📋 Refactoring Steps

### Phase 1: Extract Models (1-2 hours)

#### 1.1 Split Product.swift
- [x] Create `ProductCategory.swift` - extract enum
- [x] Keep `Product.swift` with only Product struct

#### 1.2 Split UserProfileModel.swift
- [x] Rename to `UserProfile.swift`
- [x] Extract all enums to separate files:
  - `AgeRange.swift`
  - `Sex.swift`
  - `SkinType.swift`
  - `SkinTone.swift`
  - `SkinCondition.swift`
  - `ExperienceLevel.swift`
  - `BeautyGoal.swift`
  - `CommonAllergen.swift`
  - `MakeupFrequency.swift`
  - `RoutineComplexity.swift`

### Phase 2: Reorganize Views (2-3 hours)

#### 2.1 Create Module Folders
- [x] `Modules/Products/`
- [x] `Modules/AIChat/`
- [x] `Modules/Profile/`
- [x] `Modules/Notifications/`
- [x] `Core/Components/`
- [x] `Core/Theme/`

#### 2.2 Move Views to Modules
- [x] Move product views to `Modules/Products/Views/`
- [x] Move AI view to `Modules/AIChat/Views/`
- [x] Move profile views to `Modules/Profile/Views/`
- [x] Move notification view to `Modules/Notifications/Views/`
- [x] Move onboarding to `Modules/Onboarding/` (already structured)

#### 2.3 Extract Components
- [x] Move `KeyboardDismissalModifier` to `Core/Components/`
- [x] Move `ImagePicker` to `Modules/Products/Views/Components/`
- [x] Extract reusable components from `ProfileEditView`

### Phase 3: Create Presenters (2-3 hours)

#### 3.1 Create ProductPresenter
Extract business logic from:
- `ProductStore` (keep as repository)
- `AddProductView`
- `ProductDetailSheet`

#### 3.2 Create AIChatPresenter
Extract business logic from:
- `AIHelperView`

#### 3.3 Create ProfilePresenter
Extract business logic from:
- `SettingsView`
- `ProfileEditView`

#### 3.4 Create NotificationPresenter
Extract business logic from:
- `NotificationsView`

### Phase 4: Update Imports (30 minutes)
- [ ] Update all import statements
- [ ] Fix broken references
- [ ] Test compilation

### Phase 5: Clean Up (30 minutes)
- [ ] Remove old directories
- [ ] Update Xcode project structure
- [ ] Clean DerivedData
- [ ] Final build test

---

## 🎯 Benefits of This Structure

### 1. Clear Separation of Concerns
- **Models** - Pure data structures
- **Views** - UI only
- **Presenters** - Business logic
- **Services** - Shared functionality

### 2. Easy Testing
- Test presenters without UI
- Test services in isolation
- Mock dependencies easily

### 3. Scalability
- Add new features without affecting existing code
- Clear boundaries between modules
- Easy to understand for new developers

### 4. Reusability
- Share components across modules
- Reuse services
- Consistent theming

### 5. Maintainability
- Find code quickly
- Change one module without breaking others
- Clear ownership of code

---

## 📊 Before vs After

### Before (Current)
```
Models/Product.swift           → 125 lines (Product + ProductCategory + logic)
Models/UserProfileModel.swift  → 195 lines (UserProfile + 10 enums)
Views/                         → Mixed structure
ViewModels/ProductStore.swift  → 200+ lines (store + business logic)
```

### After (Target)
```
Modules/Products/Models/
  ├── Product.swift            → 50 lines (Product only)
  └── ProductCategory.swift    → 75 lines (Category only)

Modules/Onboarding/Models/
  ├── UserProfile.swift        → 40 lines (UserProfile only)
  ├── AgeRange.swift           → 15 lines
  ├── SkinType.swift           → 15 lines
  ├── SkinTone.swift           → 25 lines
  └── ... (each enum in own file)

Modules/Products/
  ├── Models/
  ├── Views/
  ├── Presenter/
  └── Services/
```

---

## 🚀 Implementation Order

1. **Phase 1** - Extract models (low risk, no UI changes)
2. **Phase 2** - Reorganize views (medium risk, test after each move)
3. **Phase 3** - Create presenters (high value, extract logic)
4. **Phase 4** - Update imports (cleanup)
5. **Phase 5** - Final polish

**Total Time:** 6-8 hours  
**Risk:** Low (if done step by step with testing)

---

## ✅ Ready to Start?

**Step 1:** Extract models (safest first step)  
**Step 2:** Test compilation after each extraction  
**Step 3:** Move views to modules  
**Step 4:** Create presenters  
**Step 5:** Clean up

Let's start with Phase 1! 🚀

