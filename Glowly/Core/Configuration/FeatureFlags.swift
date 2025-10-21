//
//  FeatureFlags.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 20/10/25.
//

import Foundation

/// Feature flags for controlling app functionality
/// Allows easy enable/disable of features for MVP and testing
struct FeatureFlags {

    // MARK: - Premium Features

    /// Master toggle for all premium features
    /// Set to `false` to disable premium subscription system entirely for MVP
    static var isPremiumEnabled: Bool = true

    /// Controls whether non-premium users can create posts
    /// If true, only premium users can create posts (shows paywall)
    /// If false, all users can create posts
    static var requiresPremiumForPostCreation: Bool = true

    /// Show premium badge (crown) next to premium users
    static var showPremiumBadge: Bool = true

    /// Show premium paywall when non-premium users attempt premium actions
    static var showPremiumPaywall: Bool = true

    // MARK: - Social Features

    /// Use TikTok-style Reels feed instead of traditional feed
    /// When true: Full-screen vertical scroll reels (TikTok/Instagram Reels style)
    /// When false: Traditional list feed (Instagram classic style)
    static var useReelsFeed: Bool = true

    /// Enable post creation functionality
    static var enablePostCreation: Bool = true

    /// Enable AI caption suggestions in post creation
    static var enableAICaptions: Bool = true

    /// Enable product tagging in posts
    static var enableProductTagging: Bool = true

    /// Enable media upload (photos/videos) in posts
    static var enableMediaUpload: Bool = true

    // MARK: - Computed Properties

    /// Whether to show the "Create Post" button in feed
    static var shouldShowCreatePostButton: Bool {
        return enablePostCreation && (isPremiumEnabled || !requiresPremiumForPostCreation)
    }

    /// Whether to show premium features UI elements
    static var shouldShowPremiumUI: Bool {
        return isPremiumEnabled && (showPremiumBadge || showPremiumPaywall)
    }
}

// MARK: - Usage Examples
/*

 Example 1: Disable all premium features for MVP
 ```
 FeatureFlags.isPremiumEnabled = false
 ```

 Example 2: Allow all users to create posts (no premium requirement)
 ```
 FeatureFlags.requiresPremiumForPostCreation = false
 ```

 Example 3: Disable AI captions temporarily
 ```
 FeatureFlags.enableAICaptions = false
 ```

 Example 4: Check before showing create post button
 ```
 if FeatureFlags.shouldShowCreatePostButton {
     // Show button
 }
 ```

 */
