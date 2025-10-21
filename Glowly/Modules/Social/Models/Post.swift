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
        // Post 1: Beauty Products - Single Image
        Post(
            id: "1",
            userId: "user1",
            userName: "Beauty by Anna",
            userAvatar: nil,
            content: "✨ Just discovered this amazing product! Swipe to see the transformation 💫",
            media: [
                PostMedia(type: .image, url: "beauty-1")
            ],
            createdAt: Date().addingTimeInterval(-3600),
            likesCount: 1247,
            commentsCount: 89,
            isLiked: false,
            isPremium: true,
            userType: .premium
        ),

        // Post 2: Product Collection - Multiple Images
        Post(
            id: "2",
            userId: "store1",
            userName: "Sephora Russia",
            userAvatar: nil,
            content: "🎉 Новая коллекция от Dior! Скидка 20% на все помады до конца недели 💋",
            media: [
                PostMedia(type: .image, url: "beauty-1"),
                PostMedia(type: .image, url: "beauty-2"),
                PostMedia(type: .image, url: "beauty-3")
            ],
            createdAt: Date().addingTimeInterval(-7200),
            likesCount: 2345,
            commentsCount: 156,
            isLiked: true,
            isPremium: true,
            userType: .store
        ),

        // Post 3: Skincare Routine
        Post(
            id: "3",
            userId: "user2",
            userName: "Skincare with Maria",
            userAvatar: nil,
            content: "🌸 My 5-step morning routine for glowing skin! Which products do you use?",
            media: [
                PostMedia(type: .image, url: "beauty-2")
            ],
            createdAt: Date().addingTimeInterval(-10800),
            likesCount: 892,
            commentsCount: 67,
            isLiked: false,
            isPremium: true,
            userType: .premium
        ),

        // Post 4: Makeup Haul
        Post(
            id: "4",
            userId: "user3",
            userName: "Makeup Artist Pro",
            userAvatar: nil,
            content: "My essential products for 2024 💖 Which one should I review next?",
            media: [
                PostMedia(type: .image, url: "beauty-3"),
                PostMedia(type: .image, url: "beauty-1")
            ],
            createdAt: Date().addingTimeInterval(-14400),
            likesCount: 567,
            commentsCount: 43,
            isLiked: false,
            isPremium: false,
            userType: .regular
        ),

        // Post 5: Product Focus
        Post(
            id: "5",
            userId: "store2",
            userName: "MAC Cosmetics",
            userAvatar: nil,
            content: "💄 New Retro Matte Lipstick shades - perfect for autumn! Available now",
            media: [
                PostMedia(type: .image, url: "beauty-2")
            ],
            createdAt: Date().addingTimeInterval(-18000),
            likesCount: 1823,
            commentsCount: 134,
            isLiked: true,
            isPremium: true,
            userType: .store
        ),

        // Post 6: Before/After Comparison
        Post(
            id: "6",
            userId: "user4",
            userName: "Glam Squad",
            userAvatar: nil,
            content: "Before & After: Natural glam look for everyday ✨ Which look do you prefer?",
            media: [
                PostMedia(type: .image, url: "beauty-1"),
                PostMedia(type: .image, url: "beauty-3")
            ],
            createdAt: Date().addingTimeInterval(-21600),
            likesCount: 456,
            commentsCount: 32,
            isLiked: false,
            isPremium: true,
            userType: .premium
        ),

        // Post 7: Product Recommendation
        Post(
            id: "7",
            userId: "user5",
            userName: "Beauty Blogger",
            userAvatar: nil,
            content: "This is the BEST moisturizer I've ever tried! 💧 Perfect for all skin types",
            media: [
                PostMedia(type: .image, url: "beauty-3")
            ],
            createdAt: Date().addingTimeInterval(-25200),
            likesCount: 789,
            commentsCount: 56,
            isLiked: true,
            isPremium: false,
            userType: .regular
        ),

        // Post 8: Shopping Haul
        Post(
            id: "8",
            userId: "user6",
            userName: "Korean Beauty Lover",
            userAvatar: nil,
            content: "🇰🇷 My latest K-beauty haul! Trying these products for the next 30 days 🌸",
            media: [
                PostMedia(type: .image, url: "beauty-1"),
                PostMedia(type: .image, url: "beauty-2"),
                PostMedia(type: .image, url: "beauty-3")
            ],
            createdAt: Date().addingTimeInterval(-28800),
            likesCount: 923,
            commentsCount: 78,
            isLiked: false,
            isPremium: true,
            userType: .premium
        )
    ]
}

