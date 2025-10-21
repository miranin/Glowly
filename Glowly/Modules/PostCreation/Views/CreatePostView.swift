//
//  CreatePostView.swift
//  Glowly
//
//  TikTok-style post creation with photos and videos
//

import SwiftUI
import PhotosUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var imageCacheService: ImageCacheService
    @StateObject private var viewModel = CreatePostViewModel()
    @ObservedObject var authManager: AuthManager
    @ObservedObject var feedService: FeedService

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Media Gallery
                        mediaSection

                        // Caption Input - Clean, no box
                        captionSection

                        // Product Tags (Feature Flag Controlled)
                        if FeatureFlags.enableProductTagging && !viewModel.taggedProducts.isEmpty {
                            productTagsSection
                        }
                    }
                    .padding()
                    .padding(.bottom, 100)
                }

                // Publish Button
                VStack {
                    Spacer()
                    publishButton
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Media Section
    private var mediaSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(
                selection: $viewModel.selectedPhotos,
                maxSelectionCount: 10,
                matching: .images
            ) {
                if viewModel.loadedImages.isEmpty {
                    // Empty state - large, clean button
                    VStack(spacing: 16) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 48))
                            .foregroundColor(Theme.accent)

                        Text("Add Photos")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Text("Tap to select up to 10 photos")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                } else {
                    // Has media - show grid
                    HStack {
                        Text("\(viewModel.loadedImages.count) photo\(viewModel.loadedImages.count == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("Change")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.accent)
                    }
                    .padding(.horizontal, 4)
                }
            }
            .onChange(of: viewModel.selectedPhotos) { _, newValue in
                Task {
                    await viewModel.loadImages(from: newValue)
                }
            }

            // Image Grid
            if !viewModel.loadedImages.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(viewModel.loadedImages.enumerated()), id: \.offset) { index, image in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(8)

                            Button {
                                viewModel.removeImage(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Color.black.opacity(0.5), in: Circle())
                                    .padding(6)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Caption Section (Clean, Instagram-style)
    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Write a caption...", text: $viewModel.caption, axis: .vertical)
                .font(.system(size: 15))
                .lineLimit(5...15)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

            HStack {
                // AI Button (Feature Flag Controlled)
                if FeatureFlags.enableAICaptions {
                    Button {
                        viewModel.generateAISuggestions()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13))
                            Text("AI Help")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(Theme.accent)
                    }
                    .disabled(viewModel.isGeneratingAI)
                }

                Spacer()

                Text("\(viewModel.caption.count)/2200")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            // AI Suggestions
            if viewModel.showAISuggestions && !viewModel.aiSuggestions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(viewModel.aiSuggestions, id: \.self) { suggestion in
                        Button {
                            viewModel.caption = suggestion
                            viewModel.showAISuggestions = false
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Product Tags Section
    private var productTagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tagged Products")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            ForEach(viewModel.taggedProducts) { product in
                HStack {
                    Text(product.name)
                        .font(.system(size: 14))
                    Spacer()
                    Button {
                        viewModel.removeProduct(product)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Publish Button
    private var publishButton: some View {
        Button {
            Task {
                await viewModel.publishPost(
                    authManager: authManager,
                    feedService: feedService,
                    imageCacheService: imageCacheService
                )
                dismiss()
            }
        } label: {
            HStack {
                if viewModel.isPublishing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Publish")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    colors: viewModel.canPublish ? [Theme.accent, Theme.accentDark] : [Color.gray, Color.gray.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .disabled(!viewModel.canPublish || viewModel.isPublishing)
    }
}

#Preview {
    CreatePostView(
        authManager: AuthManager(),
        feedService: FeedService()
    )
    .environmentObject(LanguageManager())
}
