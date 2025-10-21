//
//  ImageCacheService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 20/10/25.
//

import SwiftUI
import UIKit

/// Service for caching images locally for posts
/// Stores UIImage data for newly created posts before server upload
@MainActor
class ImageCacheService: ObservableObject {
    // In-memory cache for recently uploaded images
    private var imageCache: [String: UIImage] = [:]

    init() {}

    // MARK: - Public Methods

    /// Store an image in cache with a unique key
    func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache[key] = image
        print("🖼️ Cached image for key: \(key)")
    }

    /// Retrieve an image from cache
    func getImage(forKey key: String) -> UIImage? {
        return imageCache[key]
    }

    /// Store multiple images and return their cache keys
    func cacheImages(_ images: [UIImage]) -> [String] {
        return images.map { image in
            let key = UUID().uuidString
            cacheImage(image, forKey: key)
            return key
        }
    }

    /// Remove an image from cache
    func removeImage(forKey key: String) {
        imageCache.removeValue(forKey: key)
    }

    /// Clear all cached images
    func clearCache() {
        imageCache.removeAll()
        print("🗑️ Image cache cleared")
    }

    /// Get cache size for debugging
    var cacheSize: Int {
        return imageCache.count
    }
}
