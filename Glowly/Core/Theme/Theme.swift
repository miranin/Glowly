//
//  Theme.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 06/10/25.
//

import SwiftUI

extension Color {
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
}

enum Theme {
    // Modern blue-cyan palette (fresh and clean) - matching Figma design
    static let accent: Color = Color(hex: "#7DD3FC") // sky blue (cyan)
    static let accentDark: Color = Color(hex: "#38BDF8") // deeper blue
    static let accentLight: Color = Color(hex: "#BAE6FD") // light cyan
    
    // Backgrounds
    static let backgroundPowder: Color = Color(hex: "#FFF8F6") // warm white
    static let backgroundCard: Color = Color(hex: "#FFFFFF") // pure white
    
    // Neutrals
    static let neutral: Color = Color(hex: "#8B8B8B") // medium gray
    static let neutralLight: Color = Color(hex: "#F5F5F5") // light gray
    static let textPrimary: Color = Color(hex: "#2D2D2D") // dark gray
    static let textSecondary: Color = Color(hex: "#999999") // medium gray
    
    // Status colors
    static let warning: Color = Color(hex: "#FFB347") // warm orange
    static let danger: Color = Color(hex: "#FF6B6B") // coral red
    static let success: Color = Color(hex: "#51CF66") // fresh green
    static let info: Color = Color(hex: "#74C0FC") // sky blue

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

    static func categoryColor(_ category: ProductCategory) -> Color {
        switch category {
        case .foundation: return Color(hex: "#FFB4A2") // peachy
        case .concealer: return Color(hex: "#FFD5C2") // light peach
        case .powder: return Color(hex: "#E8B4E8") // lavender
        case .blush: return Color(hex: "#FFB6D9") // pink
        case .bronzer: return Color(hex: "#D4A574") // bronze
        case .highlighter: return Color(hex: "#FFE4B5") // champagne
        case .eyeshadow: return Color(hex: "#B4C7E7") // soft blue
        case .eyeliner: return Color(hex: "#8B8B8B") // gray
        case .mascara: return Color(hex: "#5D5D5D") // charcoal
        case .lipstick: return Color(hex: "#FF8FAB") // rose
        case .lipGloss: return Color(hex: "#FFB6C1") // light pink
        case .lipLiner: return Color(hex: "#D8869C") // mauve
        case .primer: return Color(hex: "#C8D8E4") // blue-gray
        case .settingSpray: return Color(hex: "#B4E4FF") // sky blue
        case .cleanser: return Color(hex: "#B4E7D5") // mint
        case .moisturizer: return Color(hex: "#C8E6C9") // sage
        case .serum: return Color(hex: "#D4B4E7") // lilac
        case .sunscreen: return Color(hex: "#FFE4B5") // yellow
        case .mask: return Color(hex: "#B4E7E0") // aqua
        case .other: return neutral
        }
    }
}


