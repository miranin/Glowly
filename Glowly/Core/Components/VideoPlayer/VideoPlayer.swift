//
//  VideoPlayer.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 21/10/25.
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspectFill
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
}
