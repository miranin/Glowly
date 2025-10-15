//
//  FeedView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct FeedView: View {
    @ObservedObject var productStore: ProductStore
    @ObservedObject var wishListService: WishListService
    @StateObject private var feedService = FeedService()
    @StateObject private var commentService = CommentService()
    @StateObject private var userProfileService = UserProfileService()
    
    var body: some View {
        NavigationView {
            ZStack {
                if feedService.isLoading {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(Theme.accent)
                        
                        Text("Загружаем ленту...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    // Content state
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(feedService.posts) { post in
                                VStack(spacing: 0) {
                                    PostCard(
                                        post: post,
                                        feedService: feedService,
                                        commentService: commentService,
                                        userProfileService: userProfileService,
                                        wishListService: wishListService
                                    )
                                    
                                    // Divider между постами
                                    Divider()
                                        .padding(.vertical, 8)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Лента")
            .refreshable {
                feedService.refresh()
            }
            .onAppear {
                if feedService.posts.isEmpty {
                    feedService.loadMockPosts()
                }
            }
        }
    }
}

// MARK: - Post Card
struct PostCard: View {
    let post: Post
    @ObservedObject var feedService: FeedService
    @ObservedObject var commentService: CommentService
    @ObservedObject var userProfileService: UserProfileService
    @ObservedObject var wishListService: WishListService
    
    @State private var showComments = false
    @State private var showUserProfile = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (User info)
            Button {
                showUserProfile = true
            } label: {
                HStack(spacing: 12) {
                    // Avatar
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: post.userType == .store ? "bag.fill" : "person.fill")
                                .foregroundColor(.gray)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(post.userName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if post.isPremium {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Theme.accent)
                            }
                        }
                        
                        Text(timeAgoString(from: post.createdAt))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        // More options
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.primary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 16)
            
            // Content
            Text(post.content)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
            
            // Image (if exists)
            if post.imageUrl != nil {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 300)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    feedService.toggleLike(postId: post.id)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .primary)
                        Text("\(post.likesCount)")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }
                }
                
                Button {
                    showComments = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.right")
                        Text("\(post.commentsCount)")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    // Share
                } label: {
                    Image(systemName: "paperplane")
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showComments) {
            CommentsView(post: post, commentService: commentService)
        }
        .sheet(isPresented: $showUserProfile) {
            UserProfileView(
                userId: post.userId,
                userProfileService: userProfileService,
                wishListService: wishListService
            )
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        if hours < 24 {
            return "\(hours)ч назад"
        }
        let days = Int(interval / 86400)
        return "\(days)д назад"
    }
}

#Preview {
    FeedView(productStore: ProductStore(), wishListService: WishListService())
}

