//
//  ReelsView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 20/10/25.
//

import SwiftUI

/// TikTok-style vertical scrolling reels feed
/// Full-screen posts with swipe-up navigation
struct ReelsView: View {
    @StateObject var feedService: FeedService
    @StateObject var authManager: AuthManager
    @State private var currentIndex: Int = 0
    @State private var scrollPosition: Int? = 0
    @State private var showComments: Bool = false
    @State private var selectedPost: Post?
    @State private var showUserProfile: Bool = false
    @State private var selectedUserId: String?
    @State private var showCreatePost: Bool = false
    @State private var showPaywall: Bool = false

    var body: some View {
        ZStack {
            if feedService.posts.isEmpty {
                // Empty state
                emptyStateView
            } else {
                // Vertical paging scroll view (TikTok-style: swipe UP = next reel)
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(feedService.posts.enumerated()), id: \.element.id) { index, post in
                            ReelCard(
                                post: post,
                                isActive: currentIndex == index,
                                onLike: {
                                    feedService.toggleLike(postId: post.id)
                                },
                                onComment: {
                                    selectedPost = post
                                    showComments = true
                                },
                                onShare: {
                                    sharePost(post)
                                },
                                onUserTap: {
                                    selectedUserId = post.userId
                                    showUserProfile = true
                                }
                            )
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .ignoresSafeArea(.all, edges: .all)
                            .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $scrollPosition)
                .onChange(of: scrollPosition) { _, newValue in
                    if let newValue = newValue {
                        currentIndex = newValue
                    }
                }
                .ignoresSafeArea(.all, edges: .all)
            }

            // Floating Create Post Button (top-right)
            if FeatureFlags.enablePostCreation {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            handleCreatePost()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.accentDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(color: Theme.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 60)
                    }
                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showComments) {
            if let post = selectedPost {
                CommentsView(post: post, commentService: CommentService())
            }
        }
        .sheet(isPresented: $showUserProfile) {
            if let userId = selectedUserId {
                UserProfileView(
                    userId: userId,
                    userProfileService: UserProfileService(),
                    wishListService: WishListService()
                )
            }
        }
        .fullScreenCover(isPresented: $showCreatePost) {
            CreatePostView(
                authManager: authManager,
                feedService: feedService
            )
            .environmentObject(LanguageManager())
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PremiumPaywallView(onPurchase: handlePurchase)
        }
        .onAppear {
            if feedService.posts.isEmpty {
                feedService.refresh()
            }
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Theme.accent)

            Text("No Reels Yet")
                .font(.system(size: 24, weight: .bold))

            Text("Be the first to create a reel!")
                .font(.system(size: 16))
                .foregroundColor(.secondary)

            if FeatureFlags.enablePostCreation {
                Button {
                    handleCreatePost()
                } label: {
                    Text("Create Reel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accentDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Actions
    private func handleCreatePost() {
        if FeatureFlags.isPremiumEnabled && FeatureFlags.requiresPremiumForPostCreation {
            if let currentUser = authManager.currentUser, currentUser.isPremium {
                showCreatePost = true
            } else {
                if FeatureFlags.showPremiumPaywall {
                    showPaywall = true
                } else {
                    showCreatePost = true
                }
            }
        } else {
            showCreatePost = true
        }
    }

    private func handlePurchase(_ plan: SubscriptionPlan) {
        print("💳 User selected \(plan.title) plan")
        // TODO: Integrate with StoreKit
        showPaywall = false
        showCreatePost = true
    }

    private func sharePost(_ post: Post) {
        // TODO: Implement share sheet
        print("📤 Share post: \(post.id)")
    }
}

// MARK: - Preview
#Preview {
    ReelsView(
        feedService: FeedService(),
        authManager: AuthManager()
    )
}
