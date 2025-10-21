//
//  VideoPlayerView.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 20/10/25.
//

import SwiftUI
import AVKit
import AVFoundation

/// Video player with auto-play, loop, and mute controls
/// Designed for TikTok-style reels feed
struct VideoPlayerView: View {
    let url: String
    let isActive: Bool  // Auto-play when active

    @StateObject private var playerManager: VideoPlayerManager
    @State private var isMuted: Bool = false

    init(url: String, isActive: Bool) {
        self.url = url
        self.isActive = isActive
        _playerManager = StateObject(wrappedValue: VideoPlayerManager(url: url))
    }

    var body: some View {
        ZStack {
            if let player = playerManager.player {
                VideoPlayer(player: player)
                    .aspectRatio(contentMode: .fill)
                    .disabled(true)  // Disable default controls
                    .onAppear {
                        playerManager.setupPlayer()
                    }
                    .onDisappear {
                        playerManager.pause()
                    }
                    .onChange(of: isActive) { _, newValue in
                        if newValue {
                            playerManager.play()
                        } else {
                            playerManager.pause()
                        }
                    }

                // Mute/Unmute button
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            isMuted.toggle()
                            playerManager.setMuted(isMuted)
                        } label: {
                            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                    Spacer()
                }
            } else {
                // Loading or error state
                Rectangle()
                    .fill(Color.black)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
        }
    }
}
