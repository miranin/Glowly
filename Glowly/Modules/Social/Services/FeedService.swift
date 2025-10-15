//
//  FeedService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import Foundation

final class FeedService: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    
    init() {
        // Don't load immediately - wait for onAppear
    }
    
    func loadMockPosts() {
        isLoading = true
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.posts = Post.mockPosts
            self.isLoading = false
        }
    }
    
    func toggleLike(postId: String) {
        if let index = posts.firstIndex(where: { $0.id == postId }) {
            posts[index].isLiked.toggle()
            
            // Обновляем счетчик лайков
            if posts[index].isLiked {
                posts[index].likesCount += 1
            } else {
                posts[index].likesCount = max(0, posts[index].likesCount - 1)
            }
        }
    }
    
    func refresh() {
        loadMockPosts()
    }
}

