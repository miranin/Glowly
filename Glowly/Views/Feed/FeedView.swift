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
    @ObservedObject var authManager: AuthManager
    @StateObject private var feedService = FeedService()
    @StateObject private var commentService = CommentService()
    @StateObject private var userProfileService = UserProfileService()
    @State private var showPaywall = false
    @State private var showCreatePost = false

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
                        .padding(.bottom, 100) // Space for tab bar + floating button
                    }
                }

                // Floating Create Post Button (Feature Flag Controlled)
                if FeatureFlags.enablePostCreation {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                handleCreatePost()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 20, weight: .semibold))
                                    Text("Create Post")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.accentDark],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(30)
                                .shadow(color: Theme.accent.opacity(0.4), radius: 15, x: 0, y: 8)
                            }
                            .padding(.trailing, 20)
                            .padding(.bottom, 90)
                        }
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
            .sheet(isPresented: $showPaywall) {
                PremiumPaywallView { plan in
                    handlePurchase(plan)
                }
            }
            .fullScreenCover(isPresented: $showCreatePost) {
                CreatePostView(
                    authManager: authManager,
                    feedService: feedService
                )
                .environmentObject(LanguageManager())
            }
        }
    }

    private func handleCreatePost() {
        // Check if premium is required for post creation
        if FeatureFlags.isPremiumEnabled && FeatureFlags.requiresPremiumForPostCreation {
            // Premium feature - check user status
            if let currentUser = authManager.currentUser, currentUser.isPremium {
                // Show create post screen for premium user
                showCreatePost = true
            } else {
                // Show paywall for non-premium users
                if FeatureFlags.showPremiumPaywall {
                    showPaywall = true
                } else {
                    // Premium disabled, allow post creation
                    showCreatePost = true
                }
            }
        } else {
            // Premium not required, allow all users to create posts
            showCreatePost = true
        }
    }

    private func handlePurchase(_ plan: SubscriptionPlan) {
        // TODO: Integrate with StoreKit
        print("💳 User selected \(plan.title) plan")
        // For now, just mark user as premium
        if var currentUser = authManager.currentUser {
            currentUser.isPremium = true
            authManager.currentUser = currentUser
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

                            // Premium Badge (Feature Flag Controlled)
                            if FeatureFlags.isPremiumEnabled && FeatureFlags.showPremiumBadge && post.isPremium {
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
            
            // Media (if exists - Premium users only)
            if post.hasMedia {
                if post.media.count == 1 {
                    // Single image
                    if let mediaUrl = post.media.first?.url {
                        CachedAsyncImage(url: mediaUrl, contentMode: .fill)
                            .frame(height: 300)
                            .clipped()
                    }
                } else if post.media.count > 1 {
                    // Multiple images - show first with count indicator
                    ZStack(alignment: .topTrailing) {
                        if let mediaUrl = post.media.first?.url {
                            CachedAsyncImage(url: mediaUrl, contentMode: .fill)
                                .frame(height: 300)
                                .clipped()
                        }

                        // Count indicator
                        if post.media.count > 1 {
                            HStack(spacing: 4) {
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 12))
                                Text("\(post.media.count)")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)
                            .padding(12)
                        }
                    }
                }
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
    FeedView(productStore: ProductStore(), wishListService: WishListService(), authManager: AuthManager())
}

