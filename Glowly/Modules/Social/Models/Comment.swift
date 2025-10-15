//
//  Comment.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

struct Comment: Identifiable, Codable {
    let id: String
    let postId: String
    let userId: String
    let userName: String
    let userAvatar: String?
    let content: String
    let createdAt: Date
    var likesCount: Int
    var isLiked: Bool
    
    init(id: String = UUID().uuidString, postId: String, userId: String, userName: String, userAvatar: String? = nil, content: String, createdAt: Date = Date(), likesCount: Int = 0, isLiked: Bool = false) {
        self.id = id
        self.postId = postId
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.content = content
        self.createdAt = createdAt
        self.likesCount = likesCount
        self.isLiked = isLiked
    }
}

// MARK: - Mock Data
extension Comment {
    static func mockComments(for postId: String) -> [Comment] {
        [
            Comment(
                postId: postId,
                userId: "user3",
                userName: "Екатерина",
                content: "Очень красиво! 😍",
                createdAt: Date().addingTimeInterval(-1800),
                likesCount: 5
            ),
            Comment(
                postId: postId,
                userId: "user4",
                userName: "Ольга",
                content: "Где можно купить?",
                createdAt: Date().addingTimeInterval(-3600),
                likesCount: 2
            ),
            Comment(
                postId: postId,
                userId: "user5",
                userName: "Дарья",
                content: "Спасибо за обзор! 🙏",
                createdAt: Date().addingTimeInterval(-5400),
                likesCount: 8
            )
        ]
    }
}

