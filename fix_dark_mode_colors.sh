#!/bin/bash

# Dark Mode Color Fix Script
# This script updates all SwiftUI views to use adaptive Theme colors

echo "🎨 Starting Dark Mode Color Fix..."
echo ""

# Base directory
BASE_DIR="/Users/tamirlanaubakirov/Developer/Glowly/Glowly"

# Files to update (43 files)
FILES=(
    "Modules/Authentication/Registration/View/RegistrationView.swift"
    "Modules/Authentication/Shared/Views/ForgotPasswordView.swift"
    "Modules/Authentication/Shared/Views/OTPVerificationView.swift"
    "Views/Onboarding/OnboardingWelcomeView.swift"
    "Views/Onboarding/OnboardingBasicInfoView.swift"
    "Views/Onboarding/OnboardingSkinTypeView.swift"
    "Views/Onboarding/OnboardingBeautyProfileView.swift"
    "Views/Onboarding/OnboardingAllergiesView.swift"
    "Views/Onboarding/OnboardingSkinConditionsView.swift"
    "Views/Onboarding/OnboardingCompletionView.swift"
    "Views/Onboarding/Components/OnboardingComponents.swift"
    "Views/Products/ProductCard.swift"
    "Views/Products/ProductGridCard.swift"
    "Views/Products/ProductDetailSheet.swift"
    "Views/Products/ProductDetailSimpleSheet.swift"
    "Views/Products/ShowcaseCard.swift"
    "Views/Products/SwipeCard.swift"
    "Views/Products/CircularProductSelector.swift"
    "Views/AddProduct/AddProductView.swift"
    "Views/AddProduct/AddEntryChooserView.swift"
    "Views/AddProduct/CameraUploadView.swift"
    "Views/AddProduct/CameraAddProductView.swift"
    "Views/AddProduct/ProductConfirmationView.swift"
    "Views/Feed/FeedView.swift"
    "Views/Feed/ReelsView.swift"
    "Modules/Social/Views/UserProfileView.swift"
    "Modules/Social/Views/CommentsView.swift"
    "Modules/Social/Views/CategoryProductsView.swift"
    "Modules/Social/Views/FullCosmeticBagView.swift"
    "Modules/Social/Views/SocialProductDetailSheet.swift"
    "Modules/PostCreation/Views/CreatePostView.swift"
    "Views/Profile/ModernProfileEditView.swift"
    "Views/Profile/SettingsView.swift"
    "Views/Bag/BagListView.swift"
    "Views/AI/AIHelperView.swift"
    "Views/Learning/LearningView.swift"
    "Views/Common/PremiumPaywallView.swift"
    "Views/Common/PrivacyPolicyView.swift"
    "Core/Localization/LanguageSwitcher.swift"
    "Core/Components/BottomSheetError.swift"
    "Core/Components/BottomSheetNotice.swift"
    "Core/Components/CachedAsyncImage.swift"
    "Views/Debug/APITestView.swift"
)

# Create backup directory
BACKUP_DIR="$BASE_DIR/../dark_mode_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "📦 Created backup directory: $BACKUP_DIR"
echo ""

# Counter
UPDATED=0
SKIPPED=0

# Process each file
for FILE in "${FILES[@]}"; do
    FULL_PATH="$BASE_DIR/$FILE"

    if [ -f "$FULL_PATH" ]; then
        echo "Processing: $FILE"

        # Create backup
        BACKUP_PATH="$BACKUP_DIR/$FILE"
        mkdir -p "$(dirname "$BACKUP_PATH")"
        cp "$FULL_PATH" "$BACKUP_PATH"

        # Apply replacements
        sed -i '' 's/\.foregroundColor(\.secondary)/.secondaryTextColor()/g' "$FULL_PATH"
        sed -i '' 's/\.foregroundColor(\.primary)/.primaryTextColor()/g' "$FULL_PATH"
        sed -i '' 's/\.background(Color(\.systemGray6))/.secondaryBackground()/g' "$FULL_PATH"
        sed -i '' 's/Color(\.systemBackground)/Theme.backgroundPrimary/g' "$FULL_PATH"
        sed -i '' 's/\.foregroundColor(\.gray)/.foregroundColor(Theme.neutral)/g' "$FULL_PATH"

        ((UPDATED++))
        echo "  ✅ Updated"
    else
        echo "  ⚠️  File not found: $FILE"
        ((SKIPPED++))
    fi
    echo ""
done

echo ""
echo "🎉 Dark Mode Fix Complete!"
echo ""
echo "📊 Summary:"
echo "  ✅ Updated: $UPDATED files"
echo "  ⚠️  Skipped: $SKIPPED files"
echo "  📦 Backup: $BACKUP_DIR"
echo ""
echo "⚡ Next Steps:"
echo "  1. Open Xcode and build the project"
echo "  2. Test in both light and dark modes"
echo "  3. Review changes and adjust if needed"
echo "  4. If issues occur, restore from backup"
echo ""
echo "📖 See DARK_MODE_FIX_GUIDE.md for detailed information"
