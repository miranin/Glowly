//
//  CommentsView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI

struct CommentsView: View {
    let post: Post
    @ObservedObject var commentService: CommentService
    @Environment(\.dismiss) var dismiss
    
    @State private var commentText = ""
    @FocusState private var isInputFocused: Bool
    
    var comments: [Comment] {
        commentService.getComments(for: post.id)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Post Preview (чтобы видеть пост при комментировании)
                    ScrollView {
                        VStack(spacing: 0) {
                            PostPreview(post: post)
                                .padding(.bottom, 16)

                            Divider()

                            // Comments List
                            if comments.isEmpty && commentService.isLoading {
                                VStack(spacing: 16) {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("Loading comments...")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else if comments.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("No comments yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Text("Be the first to comment!")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                            } else {
                                LazyVStack(spacing: 16) {
                                    ForEach(comments) { comment in
                                        CommentRow(comment: comment, commentService: commentService, postId: post.id)
                                    }
                                }
                                .padding()
                            }
                        }
                    }

                    Divider()

                    // Input Field
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            )

                        TextField("Добавить комментарий...", text: $commentText)
                            .focused($isInputFocused)
                            .textFieldStyle(.plain)

                        if !commentText.isEmpty {
                            Button {
                                addComment()
                            } label: {
                                Text("Отправить")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(Theme.accent)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Комментарии")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .onAppear {
                // Always trigger load - the service will handle if already loaded
                commentService.loadComments(for: post.id)
            }
        }
    }
    
    private func addComment() {
        guard !commentText.isEmpty else { return }
        
        commentService.addComment(
            postId: post.id,
            content: commentText,
            userId: "currentUser",
            userName: "Вы"
        )
        
        commentText = ""
        isInputFocused = false
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: Comment
    @ObservedObject var commentService: CommentService
    let postId: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.userName)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(timeAgoString(from: comment.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.system(size: 14))
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    Button {
                        commentService.toggleCommentLike(postId: postId, commentId: comment.id)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: comment.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 12))
                                .foregroundColor(comment.isLiked ? .red : .gray)
                            
                            if comment.likesCount > 0 {
                                Text("\(comment.likesCount)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Button {
                        // Reply
                    } label: {
                        Text("Ответить")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)м"
        }
        let hours = Int(interval / 3600)
        if hours < 24 {
            return "\(hours)ч"
        }
        let days = Int(interval / 86400)
        return "\(days)д"
    }
}

// MARK: - Post Preview
struct PostPreview: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack(spacing: 12) {
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
                        
                        if post.isPremium {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Theme.accent)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Content
            Text(post.content)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
            
            // Media (if exists)
            if post.hasMedia {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: post.media.first?.type == .video ? "play.circle" : "photo")
                            .font(.system(size: 32))
                            .foregroundColor(.gray)
                    )
            }
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    CommentsView(post: Post.mockPosts[0], commentService: CommentService())
}

