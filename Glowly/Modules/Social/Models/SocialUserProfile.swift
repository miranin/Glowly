//
//  SocialUserProfile.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation
import SwiftUI

struct SocialUserProfile: Identifiable, Codable {
    let id: String
    let userName: String
    let bio: String?
    let avatar: String?
    let isPremium: Bool
    let userType: Post.UserType
    var followersCount: Int
    var followingCount: Int
    let postsCount: Int
    var isFollowing: Bool
    
    // Косметичка пользователя (краткая версия)
    let cosmeticBagPreview: [ProductPreview]
    
    struct ProductPreview: Identifiable, Codable {
        let id: String
        let name: String
        let brand: String
        let category: CosmeticCategory
        let imageUrl: String?
    }
    
    enum CosmeticCategory: String, Codable, CaseIterable {
        case facialSkincare = "Facial Skincare"
        case makeup = "Makeup"
        case bodyCare = "Body Care"
        case hairCare = "Hair Care"
        
        var icon: String {
            switch self {
            case .facialSkincare: return "face.smiling"
            case .makeup: return "paintbrush.pointed"
            case .bodyCare: return "figure.walk"
            case .hairCare: return "comb"
            }
        }
        
        var color: Color {
            switch self {
            case .facialSkincare: return Color(red: 0.85, green: 0.33, blue: 0.52)
            case .makeup: return Color(red: 0.95, green: 0.62, blue: 0.10)
            case .bodyCare: return Color(red: 0.14, green: 0.66, blue: 0.40)
            case .hairCare: return Color(red: 0.40, green: 0.30, blue: 0.45)
            }
        }
    }
}

// MARK: - Mock Data
extension SocialUserProfile {
    static let mockProfile = SocialUserProfile(
        id: "user1",
        userName: "Анна Иванова",
        bio: "Бьюти-блогер 💄✨\nДелюсь секретами красоты",
        avatar: nil,
        isPremium: true,
        userType: .premium,
        followersCount: 1234,
        followingCount: 567,
        postsCount: 89,
        isFollowing: false,
        cosmeticBagPreview: [
            ProductPreview(id: "1", name: "Foundation", brand: "Dior", category: .makeup, imageUrl: nil),
            ProductPreview(id: "2", name: "Moisturizer", brand: "CeraVe", category: .facialSkincare, imageUrl: nil),
            ProductPreview(id: "3", name: "Body Lotion", brand: "Nivea", category: .bodyCare, imageUrl: nil),
            ProductPreview(id: "4", name: "Shampoo", brand: "Pantene", category: .hairCare, imageUrl: nil),
            ProductPreview(id: "5", name: "Lipstick", brand: "MAC", category: .makeup, imageUrl: nil),
            ProductPreview(id: "6", name: "Serum", brand: "The Ordinary", category: .facialSkincare, imageUrl: nil),
            ProductPreview(id: "7", name: "Mascara", brand: "Maybelline", category: .makeup, imageUrl: nil),
            ProductPreview(id: "8", name: "Sunscreen", brand: "Bioré", category: .facialSkincare, imageUrl: nil)
        ]
    )
}
