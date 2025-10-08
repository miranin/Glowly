//
//  HapticsService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import Foundation
import UIKit

final class HapticsService {
    static let shared = HapticsService()
    private init() {}
    
    func impactLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func impactMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

