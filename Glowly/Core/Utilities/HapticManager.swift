//
//  HapticManager.swift
//  Glowly
//
//  Enhanced haptic feedback system for smooth UI/UX
//

import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        // Pre-warm generators for instant response
        impactLight.prepare()
        impactMedium.prepare()
        selectionFeedback.prepare()
    }

    // MARK: - Selection Feedback

    /// Light haptic for selections (buttons, toggles, etc.)
    func selection() {
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    // MARK: - Impact Feedback

    /// Very light tap - for subtle interactions
    func lightImpact() {
        impactLight.impactOccurred()
        impactLight.prepare()
    }

    /// Soft impact - for gentle confirmations
    func softImpact() {
        impactSoft.impactOccurred()
        impactSoft.prepare()
    }

    /// Medium impact - for standard confirmations
    func mediumImpact() {
        impactMedium.impactOccurred()
        impactMedium.prepare()
    }

    /// Heavy impact - for important actions
    func heavyImpact() {
        impactHeavy.impactOccurred()
        impactHeavy.prepare()
    }

    /// Rigid impact - for critical actions
    func rigidImpact() {
        impactRigid.impactOccurred()
        impactRigid.prepare()
    }

    // MARK: - Notification Feedback

    /// Success notification - for completed actions
    func success() {
        notificationFeedback.notificationOccurred(.success)
        notificationFeedback.prepare()
    }

    /// Warning notification - for warnings
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
        notificationFeedback.prepare()
    }

    /// Error notification - for errors
    func error() {
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }

    // MARK: - Custom Sequences

    /// Double tap pattern - for special selections
    func doubleTap() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }

    /// Progression pattern - for moving forward in flow
    func progression() {
        softImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.mediumImpact()
        }
    }

    /// Completion pattern - for finishing a flow
    func completion() {
        mediumImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heavyImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.success()
        }
    }
}
