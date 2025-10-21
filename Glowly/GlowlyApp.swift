//
//  GlowlyApp.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import SwiftUI

@main
struct GlowlyApp: App {
    @StateObject private var imageCacheService = ImageCacheService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageCacheService)
        }
    }
}
