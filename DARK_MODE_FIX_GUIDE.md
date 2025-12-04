# Dark Mode Fix - Implementation Guide

## Problem
The app currently has poor visibility in dark mode due to hard-coded light mode colors that don't adapt to the system color scheme.

## Solution
Updated `Theme.swift` with adaptive colors that automatically switch between light and dark modes based on the system setting.

## What Was Changed

### 1. Theme.swift - New Adaptive Color System

#### Before:
```swift
static let accent: Color = Color(hex: "#7DD3FC") // Fixed color
static let textPrimary: Color = Color(hex: "#2D2D2D") // Always dark gray
static let backgroundCard: Color = Color(hex: "#FFFFFF") // Always white
```

#### After:
```swift
static var accent: Color {
    Color(light: Color(hex: "#38BDF8"), dark: Color(hex: "#7DD3FC"))
}

static var textPrimary: Color {
    Color(light: Color(hex: "#2D2D2D"), dark: Color(hex: "#FFFFFF"))
}

static var backgroundCard: Color {
    Color(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#262626"))
}
```

### 2. New Color Extension

Added adaptive color support:

```swift
extension Color {
    /// Initialize adaptive color for light and dark mode
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor(dynamicProvider: { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        }))
    }
}
```

### 3. New View Modifiers

For easier application of theme colors:

```swift
extension View {
    func primaryTextColor() -> some View
    func secondaryTextColor() -> some View
    func tertiaryTextColor() -> some View
    func primaryBackground() -> some View
    func secondaryBackground() -> some View
    func cardBackground() -> some View
}
```

## Updated Color Palette

### Backgrounds
| Property | Light Mode | Dark Mode |
|----------|------------|-----------|
| `backgroundPrimary` | #FFFFFF (White) | #1A1A1A (Almost Black) |
| `backgroundSecondary` | #F5F5F5 (Light Gray) | #2D2D2D (Dark Gray) |
| `backgroundPowder` | #FFF8F6 (Warm White) | #1F1F1F (Dark) |
| `backgroundCard` | #FFFFFF (White) | #262626 (Card Dark) |

### Text Colors
| Property | Light Mode | Dark Mode |
|----------|------------|-----------|
| `textPrimary` | #2D2D2D (Dark Gray) | #FFFFFF (White) |
| `textSecondary` | #666666 (Medium Gray) | #B3B3B3 (Light Gray) |
| `textTertiary` | #999999 (Light Gray) | #808080 (Medium Gray) |

### Accent Colors
| Property | Light Mode | Dark Mode |
|----------|------------|-----------|
| `accent` | #38BDF8 (Sky Blue) | #7DD3FC (Lighter Blue) |
| `accentDark` | #0284C7 (Deep Blue) | #38BDF8 (Sky Blue) |
| `accentLight` | #BAE6FD (Light Cyan) | #0C4A6E (Dark Blue) |

### Status Colors (Brighter in Dark Mode)
| Property | Light Mode | Dark Mode |
|----------|------------|-----------|
| `warning` | #FFB347 (Orange) | #FFD580 (Lighter Orange) |
| `danger` | #FF6B6B (Red) | #FF8A8A (Lighter Red) |
| `success` | #51CF66 (Green) | #69DB7C (Lighter Green) |
| `info` | #74C0FC (Blue) | #A5D8FF (Lighter Blue) |

### Category Colors
All 20 product category colors now have darker variants for dark mode (20% darker while maintaining hue).

## Migration Guide

### Required Changes in Views

43 files need to be updated. Here's the pattern for each type of change:

#### 1. Replace `.foregroundColor(.secondary)`
```swift
// Before:
Text("Description")
    .foregroundColor(.secondary)

// After:
Text("Description")
    .secondaryTextColor()
// OR
Text("Description")
    .foregroundColor(Theme.textSecondary)
```

#### 2. Replace `.foregroundColor(.primary)`
```swift
// Before:
Text("Title")
    .foregroundColor(.primary)

// After:
Text("Title")
    .primaryTextColor()
// OR
Text("Title")
    .foregroundColor(Theme.textPrimary)
```

#### 3. Replace `Color(.systemGray6)` Backgrounds
```swift
// Before:
.background(Color(.systemGray6))

// After:
.secondaryBackground()
// OR
.background(Theme.backgroundSecondary)
```

#### 4. Replace `Color(.systemBackground)`
```swift
// Before:
Color(.systemBackground).ignoresSafeArea()

// After:
Theme.backgroundPowder.ignoresSafeArea()
// OR
Theme.backgroundPrimary.ignoresSafeArea()
```

#### 5. Replace `.foregroundColor(.gray)`
```swift
// Before:
Icon().foregroundColor(.gray)

// After:
Icon().foregroundColor(Theme.neutral)
```

#### 6. Keep Theme.accent, Theme.danger, etc
```swift
// These are already adaptive - no changes needed:
.foregroundColor(Theme.accent) ✅
.background(Theme.danger) ✅
.foregroundColor(Theme.success) ✅
```

## Files Requiring Updates (43 files)

### Authentication (4 files)
- ✅ `/Modules/Authentication/Login/View/LoginView.swift` (PARTIALLY DONE)
- `/Modules/Authentication/Registration/View/RegistrationView.swift`
- `/Modules/Authentication/Shared/Views/ForgotPasswordView.swift`
- `/Modules/Authentication/Shared/Views/OTPVerificationView.swift`

### Onboarding (7 files)
- `/Views/Onboarding/OnboardingWelcomeView.swift`
- `/Views/Onboarding/OnboardingBasicInfoView.swift`
- `/Views/Onboarding/OnboardingSkinTypeView.swift`
- `/Views/Onboarding/OnboardingBeautyProfileView.swift`
- `/Views/Onboarding/OnboardingAllergiesView.swift`
- `/Views/Onboarding/OnboardingSkinConditionsView.swift`
- `/Views/Onboarding/OnboardingCompletionView.swift`
- `/Views/Onboarding/Components/OnboardingComponents.swift`

### Products (7 files)
- `/Views/Products/ProductCard.swift`
- `/Views/Products/ProductGridCard.swift`
- `/Views/Products/ProductDetailSheet.swift`
- `/Views/Products/ProductDetailSimpleSheet.swift`
- `/Views/Products/ShowcaseCard.swift`
- `/Views/Products/SwipeCard.swift`
- `/Views/Products/CircularProductSelector.swift`

### Add Product (5 files)
- `/Views/AddProduct/AddProductView.swift`
- `/Views/AddProduct/AddEntryChooserView.swift`
- `/Views/AddProduct/CameraUploadView.swift`
- `/Views/AddProduct/CameraAddProductView.swift`
- `/Views/AddProduct/ProductConfirmationView.swift`

### Feed & Social (8 files)
- `/Views/Feed/FeedView.swift`
- `/Views/Feed/ReelsView.swift`
- `/Modules/Social/Views/UserProfileView.swift`
- `/Modules/Social/Views/CommentsView.swift`
- `/Modules/Social/Views/CategoryProductsView.swift`
- `/Modules/Social/Views/FullCosmeticBagView.swift`
- `/Modules/Social/Views/SocialProductDetailSheet.swift`
- `/Modules/PostCreation/Views/CreatePostView.swift`

### Profile & Settings (3 files)
- `/Views/Profile/ModernProfileEditView.swift`
- `/Views/Profile/SettingsView.swift`
- `/Views/Bag/BagListView.swift`

### Other (9 files)
- `/Views/AI/AIHelperView.swift`
- `/Views/Learning/LearningView.swift`
- `/Views/Common/PremiumPaywallView.swift`
- `/Views/Common/PrivacyPolicyView.swift`
- `/Core/Localization/LanguageSwitcher.swift`
- `/Core/Components/BottomSheetError.swift`
- `/Core/Components/BottomSheetNotice.swift`
- `/Core/Components/CachedAsyncImage.swift`
- `/Views/Debug/APITestView.swift`

## Quick Find & Replace Patterns

Use these patterns carefully in each file:

### Pattern 1: Secondary Text
```regex
Find:    \.foregroundColor\(\.secondary\)
Replace: .secondaryTextColor()
```

### Pattern 2: Primary Text
```regex
Find:    \.foregroundColor\(\.primary\)
Replace: .primaryTextColor()
```

### Pattern 3: Gray Background
```regex
Find:    \.background\(Color\(\.systemGray6\)\)
Replace: .secondaryBackground()
```

### Pattern 4: System Background
```regex
Find:    Color\(\.systemBackground\)
Replace: Theme.backgroundPrimary
```

### Pattern 5: Gray Foreground
```regex
Find:    \.foregroundColor\(\.gray\)
Replace: .foregroundColor(Theme.neutral)
```

## Testing Dark Mode

### Method 1: Settings App
1. Open Settings > Display & Brightness
2. Toggle between Light/Dark appearance
3. Check app for visibility issues

### Method 2: Xcode Preview
```swift
#Preview {
    LoginView()
        .environment(\.colorScheme, .dark)
}
```

### Method 3: Control Center
- Swipe down from top-right
- Long-press Brightness
- Toggle Dark Mode

## Benefits After Implementation

✅ **Automatic Adaptation**: Colors switch automatically based on system setting
✅ **Better Readability**: High contrast text on appropriate backgrounds
✅ **Consistent Look**: Unified theme across light and dark modes
✅ **Modern UX**: Follows iOS design guidelines
✅ **Reduced Eye Strain**: Darker UI in low-light conditions
✅ **Professional Appearance**: Polished, production-ready UI

## Next Steps

1. **Open Xcode Project**
2. **Add New Files to Project**: The updated `Theme.swift` with new extensions
3. **Update Each View**: Follow the migration patterns above
4. **Test Thoroughly**: Check both light and dark modes
5. **Handle Edge Cases**: Some custom colors may need manual adjustment

## Examples

### Before (Bad in Dark Mode)
```swift
VStack {
    Text("Title")
        .foregroundColor(.primary) // Invisible in dark mode
    Text("Description")
        .foregroundColor(.secondary) // Hard to read
}
.background(Color(.systemGray6)) // Wrong background
```

### After (Good in Both Modes)
```swift
VStack {
    Text("Title")
        .primaryTextColor() // White in dark, black in light
    Text("Description")
        .secondaryTextColor() // Always readable
}
.secondaryBackground() // Adapts automatically
```

## Notes

- The Theme changes are **backward compatible** - existing code using `Theme.accent` still works
- Category colors for products automatically adapt
- Gradients use adaptive colors
- Status colors (danger, warning, success) are slightly brighter in dark mode for visibility

## Support

If you encounter any color issues after migration:
1. Check if the color is using Theme properties
2. Verify the view is not forcing a color scheme with `.preferredColorScheme()`
3. Test in both light and dark modes
4. Adjust specific colors if needed using the `Color(light:dark:)` initializer
