//
//  VideoPlayerManager.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 21/10/25.
//

import SwiftUI
import AVKit
import AVFoundation

final class VideoPlayerManager: ObservableObject {
    @Published var player: AVPlayer?
    private var playerLooper: AVPlayerLooper?
    private var timeObserver: Any?

    let url: String

    init(url: String) {
        self.url = url
    }

    func setupPlayer() {
        // Handle multiple URL types: cache://, http://, https://, or local assets
        let videoURL: URL?

        if url.hasPrefix("cache://") {
            // Future: Load from video cache when we implement video upload
            videoURL = nil
        } else if url.hasPrefix("http://") || url.hasPrefix("https://") {
            // Remote video URL
            videoURL = URL(string: url)
        } else {
            // Local asset from Bundle (demo content)
            videoURL = Bundle.main.url(forResource: url, withExtension: "mp4")
        }

        guard let videoURL = videoURL else {
            print("⚠️ Invalid video URL: \(url)")
            return
        }

        let playerItem = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: playerItem)

        // Setup looping
        playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        player = queuePlayer
        player?.volume = 1.0
    }

    func play() {
        player?.play()
    }

    func pause() {
        player?.pause()
    }

    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    deinit {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
