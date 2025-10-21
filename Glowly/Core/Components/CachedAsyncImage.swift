//
//  CachedAsyncImage.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 20/10/25.
//

import SwiftUI

/// A view that loads images from multiple sources
/// Supports: cache://, http://, https://, and local asset names
struct CachedAsyncImage: View {
    let url: String
    let contentMode: ContentMode

    @EnvironmentObject private var imageCacheService: ImageCacheService

    init(url: String, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if url.hasPrefix("cache://") {
                // Load from memory cache (user-created posts)
                let cacheKey = String(url.dropFirst(8))
                if let cachedImage = imageCacheService.getImage(forKey: cacheKey) {
                    Image(uiImage: cachedImage)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                } else {
                    placeholderView
                }
            } else if url.hasPrefix("http://") || url.hasPrefix("https://") {
                // Load from remote URL
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                // Load from Xcode Assets (demo content)
                Image(url)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
            )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Cached image example
        CachedAsyncImage(url: "cache://test-key")
            .frame(height: 200)

        // Remote URL example
        CachedAsyncImage(url: "https://example.com/image.jpg")
            .frame(height: 200)
    }
    .padding()
    .environmentObject(ImageCacheService())
}
