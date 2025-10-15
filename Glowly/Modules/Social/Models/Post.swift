//
//  Post.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userAvatar: String?
    let content: String
    let imageUrl: String?
    let createdAt: Date
    var likesCount: Int
    var commentsCount: Int
    var isLiked: Bool
    
    // For premium users/stores
    let isPremium: Bool
    let userType: UserType
    
    enum UserType: String, Codable {
        case regular = "regular"
        case premium = "premium"
        case store = "store"
    }
}

// MARK: - Mock Data
extension Post {
    static let mockPosts: [Post] = [
        Post(
            id: "1",
            userId: "user1",
            userName: "Анна Иванова",
            userAvatar: nil,
            content: "Новая коллекция помад от Dior! 💄✨",
            imageUrl: nil,
            createdAt: Date().addingTimeInterval(-3600),
            likesCount: 24,
            commentsCount: 5,
            isLiked: false,
            isPremium: true,
            userType: .premium
        ),
        Post(
            id: "2",
            userId: "store1",
            userName: "Sephora Russia",
            userAvatar: nil,
            content: "Скидка 20% на всю косметику по уходу! 🎉",
            imageUrl: nil,
            createdAt: Date().addingTimeInterval(-7200),
            likesCount: 156,
            commentsCount: 23,
            isLiked: true,
            isPremium: true,
            userType: .store
        ),
        Post(
            id: "3",
            userId: "user2",
            userName: "Мария Петрова",
            userAvatar: nil,
            content: "Мой вечерний уход за кожей ✨",
            imageUrl: nil,
            createdAt: Date().addingTimeInterval(-10800),
            likesCount: 89,
            commentsCount: 12,
            isLiked: false,
            isPremium: true,
            userType: .premium
        )
    ]
}

