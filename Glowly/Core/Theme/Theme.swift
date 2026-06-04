//
//  Theme.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

extension Color {
    /// Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

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

enum Theme {
    // MARK: - Accent Colors (Adaptive for Dark Mode)
    static var accent: Color {
        Color(light: Color(hex: "#38BDF8"), dark: Color(hex: "#7DD3FC"))
    }

    static var accentDark: Color {
        Color(light: Color(hex: "#0284C7"), dark: Color(hex: "#38BDF8"))
    }

    static var accentLight: Color {
        Color(light: Color(hex: "#BAE6FD"), dark: Color(hex: "#0C4A6E"))
    }

    // MARK: - Backgrounds (Adaptive)
    static var backgroundPrimary: Color {
        Color(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#1A1A1A"))
    }

    static var backgroundSecondary: Color {
        Color(light: Color(hex: "#F5F5F5"), dark: Color(hex: "#2D2D2D"))
    }

    static var backgroundPowder: Color {
        Color(light: Color(hex: "#FFF8F6"), dark: Color(hex: "#1F1F1F"))
    }

    static var backgroundCard: Color {
        Color(light: Color(hex: "#FFFFFF"), dark: Color(hex: "#262626"))
    }

    // MARK: - Text Colors (Adaptive)
    static var textPrimary: Color {
        Color(light: Color(hex: "#2D2D2D"), dark: Color(hex: "#FFFFFF"))
    }

    static var textSecondary: Color {
        Color(light: Color(hex: "#666666"), dark: Color(hex: "#B3B3B3"))
    }

    static var textTertiary: Color {
        Color(light: Color(hex: "#999999"), dark: Color(hex: "#808080"))
    }

    // MARK: - Neutral Colors (Adaptive)
    static var neutral: Color {
        Color(light: Color(hex: "#8B8B8B"), dark: Color(hex: "#A0A0A0"))
    }

    static var neutralLight: Color {
        Color(light: Color(hex: "#F5F5F5"), dark: Color(hex: "#333333"))
    }

    static var border: Color {
        Color(light: Color(hex: "#E0E0E0"), dark: Color(hex: "#404040"))
    }

    // MARK: - Status Colors (Same for both modes but brighter in dark)
    static var warning: Color {
        Color(light: Color(hex: "#FFB347"), dark: Color(hex: "#FFD580"))
    }

    static var danger: Color {
        Color(light: Color(hex: "#FF6B6B"), dark: Color(hex: "#FF8A8A"))
    }

    static var success: Color {
        Color(light: Color(hex: "#51CF66"), dark: Color(hex: "#69DB7C"))
    }

    static var info: Color {
        Color(light: Color(hex: "#74C0FC"), dark: Color(hex: "#A5D8FF"))
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [accentLight.opacity(0.3), backgroundCard],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Category Colors (Adaptive)
    static func categoryColor(_ category: ProductCategory) -> Color {
        switch category {
        case .foundation:
            return Color(light: Color(hex: "#FFB4A2"), dark: Color(hex: "#CC9082"))
        case .concealer:
            return Color(light: Color(hex: "#FFD5C2"), dark: Color(hex: "#CCAA9B"))
        case .powder:
            return Color(light: Color(hex: "#E8B4E8"), dark: Color(hex: "#B890B8"))
        case .blush:
            return Color(light: Color(hex: "#FFB6D9"), dark: Color(hex: "#CC91AD"))
        case .bronzer:
            return Color(light: Color(hex: "#D4A574"), dark: Color(hex: "#A6835D"))
        case .highlighter:
            return Color(light: Color(hex: "#FFE4B5"), dark: Color(hex: "#CCB690"))
        case .eyeshadow:
            return Color(light: Color(hex: "#B4C7E7"), dark: Color(hex: "#8F9FB8"))
        case .eyeliner:
            return Color(light: Color(hex: "#8B8B8B"), dark: Color(hex: "#A6A6A6"))
        case .mascara:
            return Color(light: Color(hex: "#5D5D5D"), dark: Color(hex: "#8F8F8F"))
        case .lipstick:
            return Color(light: Color(hex: "#FF8FAB"), dark: Color(hex: "#CC7288"))
        case .lipGloss:
            return Color(light: Color(hex: "#FFB6C1"), dark: Color(hex: "#CC919A"))
        case .lipLiner:
            return Color(light: Color(hex: "#D8869C"), dark: Color(hex: "#AD6B7D"))
        case .primer:
            return Color(light: Color(hex: "#C8D8E4"), dark: Color(hex: "#9FADB6"))
        case .settingSpray:
            return Color(light: Color(hex: "#B4E4FF"), dark: Color(hex: "#8FB6CC"))
        case .cleanser:
            return Color(light: Color(hex: "#B4E7D5"), dark: Color(hex: "#8FB8A9"))
        case .toner:
            return Color(light: Color(hex: "#B4DCE7"), dark: Color(hex: "#8FAFB8"))
        case .essence:
            return Color(light: Color(hex: "#C4E0F0"), dark: Color(hex: "#9BB2C0"))
        case .moisturizer:
            return Color(light: Color(hex: "#C8E6C9"), dark: Color(hex: "#9FB8A1"))
        case .eyeCream:
            return Color(light: Color(hex: "#C7D2F0"), dark: Color(hex: "#9CA5C0"))
        case .faceOil:
            return Color(light: Color(hex: "#F0E0A8"), dark: Color(hex: "#C0B286"))
        case .exfoliant:
            return Color(light: Color(hex: "#F0C4B4"), dark: Color(hex: "#C09B8F"))
        case .spotTreatment:
            return Color(light: Color(hex: "#F0B4B4"), dark: Color(hex: "#C08F8F"))
        case .mist:
            return Color(light: Color(hex: "#B4E4FF"), dark: Color(hex: "#8FB6CC"))
        case .serum:
            return Color(light: Color(hex: "#D4B4E7"), dark: Color(hex: "#A990B8"))
        case .sunscreen:
            return Color(light: Color(hex: "#FFE4B5"), dark: Color(hex: "#CCB690"))
        case .mask:
            return Color(light: Color(hex: "#B4E7E0"), dark: Color(hex: "#8FB8B3"))
        case .lipCare:
            return Color(light: Color(hex: "#F0B6C9"), dark: Color(hex: "#C0919E"))
        case .other:
            return neutral
        }
    }
}

// MARK: - View Modifiers for Easy Theme Application

extension View {
    /// Apply primary text color (adaptive for dark mode)
    func primaryTextColor() -> some View {
        self.foregroundColor(Theme.textPrimary)
    }

    /// Apply secondary text color (adaptive for dark mode)
    func secondaryTextColor() -> some View {
        self.foregroundColor(Theme.textSecondary)
    }

    /// Apply tertiary text color (adaptive for dark mode)
    func tertiaryTextColor() -> some View {
        self.foregroundColor(Theme.textTertiary)
    }

    /// Apply primary background (adaptive for dark mode)
    func primaryBackground() -> some View {
        self.background(Theme.backgroundPrimary)
    }

    /// Apply secondary background (adaptive for dark mode)
    func secondaryBackground() -> some View {
        self.background(Theme.backgroundSecondary)
    }

    /// Apply card background (adaptive for dark mode)
    func cardBackground() -> some View {
        self.background(Theme.backgroundCard)
    }
}


