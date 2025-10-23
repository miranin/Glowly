//
//  CommentService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

final class CommentService: ObservableObject {
    @Published var comments: [String: [Comment]] = [:] // postId: [Comment]
    @Published var isLoading = false
    private var loadingPostIds: Set<String> = []

    func loadComments(for postId: String) {
        // Skip if already loaded or currently loading this specific post
        if comments[postId] != nil || loadingPostIds.contains(postId) {
            return
        }

        loadingPostIds.insert(postId)
        isLoading = true

        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.comments[postId] = Comment.mockComments(for: postId)
            self.loadingPostIds.remove(postId)
            self.isLoading = self.loadingPostIds.isEmpty
        }
    }
    
    func addComment(postId: String, content: String, userId: String, userName: String) {
        let newComment = Comment(
            postId: postId,
            userId: userId,
            userName: userName,
            content: content
        )
        
        if comments[postId] != nil {
            comments[postId]?.insert(newComment, at: 0)
        } else {
            comments[postId] = [newComment]
        }
    }
    
    func toggleCommentLike(postId: String, commentId: String) {
        guard var postComments = comments[postId],
              let index = postComments.firstIndex(where: { $0.id == commentId }) else {
            return
        }

        postComments[index].isLiked.toggle()
        if postComments[index].isLiked {
            postComments[index].likesCount += 1
        } else {
            // Prevent negative like counts
            postComments[index].likesCount = max(0, postComments[index].likesCount - 1)
        }

        comments[postId] = postComments
    }
    
    func getComments(for postId: String) -> [Comment] {
        comments[postId] ?? []
    }
}

