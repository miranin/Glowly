//
//  CreatePostViewModel.swift
//  Glowly
//
//  Post creation with PhotosPicker integration and feed sync
//

import Foundation
import SwiftUI
import PhotosUI

@MainActor
class CreatePostViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var loadedImages: [UIImage] = []
    @Published var caption: String = ""
    @Published var taggedProducts: [Product] = []

    @Published var showAISuggestions = false
    @Published var aiSuggestions: [String] = []
    @Published var isGeneratingAI = false

    @Published var isPublishing = false
    @Published var showError = false
    @Published var errorMessage = ""

    private let maxCaptionLength = 2200
    private let maxImageCount = 10

    // MARK: - Computed Properties
    var canPublish: Bool {
        return !loadedImages.isEmpty &&
               !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !isPublishing
    }

    // MARK: - Image Loading
    func loadImages(from items: [PhotosPickerItem]) async {
        loadedImages.removeAll()

        for item in items {
            guard loadedImages.count < maxImageCount else { break }

            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loadedImages.append(image)
            }
        }
    }

    func removeImage(at index: Int) {
        guard index < loadedImages.count else { return }
        loadedImages.remove(at: index)
        selectedPhotos.remove(at: index)
    }

    // MARK: - Caption Management
    func limitCaption() {
        if caption.count > maxCaptionLength {
            caption = String(caption.prefix(maxCaptionLength))
        }
    }

    // MARK: - Product Management
    func addProduct(_ product: Product) {
        guard !taggedProducts.contains(where: { $0.id == product.id }) else { return }
        taggedProducts.append(product)
    }

    func removeProduct(_ product: Product) {
        taggedProducts.removeAll { $0.id == product.id }
    }

    // MARK: - AI Suggestions
    func generateAISuggestions() {
        guard !isGeneratingAI else { return }

        isGeneratingAI = true
        showAISuggestions = false

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            await MainActor.run {
                self.aiSuggestions = [
                    "✨ Just discovered this amazing product! Swipe to see the transformation 💫",
                    "My daily skincare routine essentials 🌸 What's in your routine?",
                    "Honest review: I've been using this for 2 weeks and here's what happened... 💄",
                    "Beauty tip: This product changed everything for me! Here's why 🎀"
                ]

                self.showAISuggestions = true
                self.isGeneratingAI = false
            }
        }
    }

    // MARK: - Publishing
    func publishPost(authManager: AuthManager, feedService: FeedService, imageCacheService: ImageCacheService) async {
        guard canPublish else { return }
        guard let currentUser = authManager.currentUser else { return }

        isPublishing = true

        // Simulate upload delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        await MainActor.run {
            // Cache images and create media array
            let mediaItems = loadedImages.map { image in
                let cacheKey = UUID().uuidString
                imageCacheService.cacheImage(image, forKey: cacheKey)
                return PostMedia(
                    id: UUID().uuidString,
                    type: .image,
                    url: "cache://\(cacheKey)",  // Use cache:// prefix to indicate cached image
                    thumbnailUrl: nil
                )
            }

            // Create new post
            let newPost = Post(
                id: UUID().uuidString,
                userId: currentUser.id,
                userName: currentUser.name ?? "Unknown User",
                userAvatar: currentUser.profilePhotoURL,
                content: caption,
                media: mediaItems,
                createdAt: Date(),
                likesCount: 0,
                commentsCount: 0,
                isLiked: false,
                isPremium: currentUser.isPremium,
                userType: currentUser.isPremium ? .premium : .regular
            )

            // Add to feed
            feedService.addPost(newPost)

            print("✅ Post published successfully!")
            print("   - User: \(currentUser.name ?? "Unknown")")
            print("   - Images: \(loadedImages.count)")
            print("   - Caption: \(caption)")

            isPublishing = false
        }
    }
}
