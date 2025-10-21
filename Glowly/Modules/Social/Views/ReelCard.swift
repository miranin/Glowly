//
//  ReelCard.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 20/10/25.
//

import SwiftUI

/// TikTok-style full-screen reel card
/// Supports both photos and videos with overlay UI
struct ReelCard: View {
    let post: Post
    let isActive: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onShare: () -> Void
    let onUserTap: () -> Void

    @EnvironmentObject private var imageCacheService: ImageCacheService
    @State private var currentMediaIndex: Int = 0

    var body: some View {
        ZStack {
            // Background - Horizontal carousel for multiple media
            if !post.media.isEmpty {
                if post.media.count == 1 {
                    // Single media - no carousel needed
                    singleMediaView(media: post.media[0])
                } else {
                    // Multiple media - horizontal swipe carousel
                    TabView(selection: $currentMediaIndex) {
                        ForEach(Array(post.media.enumerated()), id: \.element.id) { index, media in
                            singleMediaView(media: media)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .ignoresSafeArea(.all, edges: .all)
                }
            } else {
                // No media - just black background with text
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
            }

            // Gradient overlay at bottom
            VStack {
                Spacer()
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                .ignoresSafeArea()
            }

            // Content overlay
            VStack {
                Spacer()

                HStack(alignment: .bottom) {
                    // Left side - User info and caption
                    leftSideContent

                    Spacer()

                    // Right side - Actions
                    rightSideActions
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120)  // Space for tab bar
            }
        }
        .ignoresSafeArea(.all, edges: .all)
    }

    // MARK: - Left Side Content
    private var leftSideContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User info
            Button(action: onUserTap) {
                HStack(spacing: 8) {
                    // Avatar
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        )

                    // Username with premium badge
                    HStack(spacing: 4) {
                        Text(post.userName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)

                        if FeatureFlags.isPremiumEnabled && FeatureFlags.showPremiumBadge && post.isPremium {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.accent)
                        }
                    }

                    // Follow button
                    Button {
                        // Follow user action (future: integrate with UserService)
                        print("👥 Follow user: \(post.userName)")
                    } label: {
                        Text("Follow")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.accent)
                            .cornerRadius(4)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            // Caption
            Text(post.content)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 250, alignment: .leading)

            // Pagination dots (TikTok-style)
            if post.media.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<post.media.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentMediaIndex ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Right Side Actions
    private var rightSideActions: some View {
        VStack(spacing: 24) {
            // Like button
            actionButton(
                icon: post.isLiked ? "heart.fill" : "heart",
                count: post.likesCount,
                color: post.isLiked ? .red : .white,
                action: onLike
            )

            // Comment button
            actionButton(
                icon: "bubble.right",
                count: post.commentsCount,
                color: .white,
                action: onComment
            )

            // Share button
            actionButton(
                icon: "paperplane",
                count: nil,
                color: .white,
                action: onShare
            )

            // More options
            Button(action: {
                // More options
            }) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.bottom, 20)
    }

    // MARK: - Single Media View
    @ViewBuilder
    private func singleMediaView(media: PostMedia) -> some View {
        if media.type == .video {
            // Video player - only play if this is the active reel AND active media item
            VideoPlayerView(
                url: media.url,
                isActive: isActive && (post.media.count == 1 || currentMediaIndex == post.media.firstIndex(where: { $0.id == media.id }) ?? 0)
            )
            .ignoresSafeArea(.all, edges: .all)
        } else {
            // Photo - fit to screen with black background (TikTok style)
            ZStack {
                Color.black
                    .ignoresSafeArea(.all, edges: .all)

                CachedAsyncImage(url: media.url, contentMode: .fit)
            }
            .ignoresSafeArea(.all, edges: .all)
        }
    }

    // MARK: - Action Button Helper
    private func actionButton(icon: String, count: Int?, color: Color, action: @escaping () -> Void) -> some View {
        VStack(spacing: 4) {
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: icon.contains("fill") ? .bold : .regular))
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
            }

            if let count = count {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ReelCard(
        post: Post.mockPosts[0],
        isActive: true,
        onLike: {},
        onComment: {},
        onShare: {},
        onUserTap: {}
    )
}
