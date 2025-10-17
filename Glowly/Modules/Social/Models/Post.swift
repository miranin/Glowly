//
//  Post.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

enum PostMediaType: String, Codable {
    case image
    case video
}

struct PostMedia: Identifiable, Codable {
    let id: String
    let type: PostMediaType
    let url: String
    let thumbnailUrl: String?  // For video thumbnails

    init(id: String = UUID().uuidString, type: PostMediaType, url: String, thumbnailUrl: String? = nil) {
        self.id = id
        self.type = type
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }
}

struct Post: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let userAvatar: String?
    let content: String

    // Premium users can attach multiple photos/videos
    let media: [PostMedia]  // Replaces single imageUrl

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

    // Helper computed properties
    var hasMedia: Bool {
        return !media.isEmpty
    }

    var canHaveMedia: Bool {
        return userType == .premium || userType == .store
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
            media: [
                PostMedia(type: .image, url: "https://example.com/dior-lipstick.jpg")
            ],
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
            media: [
                PostMedia(type: .image, url: "https://example.com/sephora-sale.jpg"),
                PostMedia(type: .video, url: "https://example.com/sephora-promo.mp4", thumbnailUrl: "https://example.com/sephora-promo-thumb.jpg")
            ],
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
            media: [],  // Regular user without media
            createdAt: Date().addingTimeInterval(-10800),
            likesCount: 89,
            commentsCount: 12,
            isLiked: false,
            isPremium: false,
            userType: .regular
        )
    ]
}

