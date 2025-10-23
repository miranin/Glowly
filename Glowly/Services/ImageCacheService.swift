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
/// Uses NSCache for automatic memory management and eviction
@MainActor
class ImageCacheService: ObservableObject {
    // NSCache automatically handles memory pressure and eviction
    private let imageCache = NSCache<NSString, UIImage>()

    init() {
        // Set memory limits to prevent excessive memory usage
        imageCache.totalCostLimit = 100 * 1024 * 1024  // 100MB max
        imageCache.countLimit = 100  // Maximum 100 images

        // NSCache will automatically evict objects when memory is low
        imageCache.name = "com.glowly.imagecache"
    }

    // MARK: - Public Methods

    /// Store an image in cache with a unique key
    func cacheImage(_ image: UIImage, forKey key: String) {
        // Calculate cost (approximate size in bytes)
        let cost = estimateImageSize(image)
        imageCache.setObject(image, forKey: key as NSString, cost: cost)

        #if DEBUG
        print("🖼️ Cached image for key: \(key) (≈\(cost/1024)KB)")
        #endif
    }

    /// Retrieve an image from cache
    func getImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
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
        imageCache.removeObject(forKey: key as NSString)
    }

    /// Clear all cached images
    func clearCache() {
        imageCache.removeAllObjects()

        #if DEBUG
        print("🗑️ Image cache cleared")
        #endif
    }

    /// Get cache size for debugging (approximate)
    var cacheSize: Int {
        // NSCache doesn't provide count, so this is an approximation
        // In production, you might want to track this separately if needed
        return 0
    }

    // MARK: - Private Helpers

    private func estimateImageSize(_ image: UIImage) -> Int {
        // Estimate size based on image dimensions and scale
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = 4 // RGBA
        return cgImage.width * cgImage.height * bytesPerPixel * Int(image.scale)
    }
}
