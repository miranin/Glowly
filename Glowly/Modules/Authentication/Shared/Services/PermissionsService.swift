//
//  PermissionsService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 10/10/25.
//

import SwiftUI
import UserNotifications
import LocalAuthentication

final class PermissionsService: ObservableObject {
    private let biometricService: BiometricAuthServiceProtocol
    
    init(biometricService: BiometricAuthServiceProtocol) {
        self.biometricService = biometricService
    }
    
    // MARK: - Biometric Permission
    @MainActor
    func requestBiometricPermission() async -> Bool {
        let biometricType = biometricService.biometricType()
        
        // Check if biometric is available
        guard biometricService.isBiometricAvailable() else {
            print("⚠️ Biometric not available")
            return false
        }
        
        // Check if already enabled
        if UserDefaults.standard.bool(forKey: "biometricEnabled") {
            print("✅ Biometric already enabled")
            return true
        }
        
        print("🔐 Requesting biometric permission...")
        
        // Show system alert for biometric permission
        let granted = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    print("❌ Could not find root view controller")
                    continuation.resume(returning: false)
                    return
                }
                
                let alert = UIAlertController(
                    title: "Быстрый вход",
                    message: "Используйте \(biometricType.displayName) для быстрого и безопасного входа",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Включить", style: .default) { _ in
                    print("✅ User granted biometric permission")
                    continuation.resume(returning: true)
                })
                
                alert.addAction(UIAlertAction(title: "Позже", style: .cancel) { _ in
                    print("⏭️ User skipped biometric permission")
                    continuation.resume(returning: false)
                })
                
                rootVC.present(alert, animated: true) {
                    print("📱 Biometric alert presented")
                }
            }
        }
        
        if granted {
            UserDefaults.standard.set(true, forKey: "biometricEnabled")
            HapticsService.shared.success()
        } else {
            HapticsService.shared.impactLight()
        }
        
        return granted
    }
    
    // MARK: - Push Notifications Permission
    @MainActor
    func requestNotificationPermission() async -> Bool {
        // Check if already granted
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        if settings.authorizationStatus == .authorized {
            print("✅ Notifications already authorized")
            return true
        }
        
        print("🔔 Requesting notification permission...")
        
        // Show custom alert first to explain
        let userWantsToEnable = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                      let rootVC = windowScene.windows.first?.rootViewController else {
                    print("❌ Could not find root view controller")
                    continuation.resume(returning: false)
                    return
                }
                
                let alert = UIAlertController(
                    title: "Уведомления",
                    message: "Получайте полезные советы и напоминания о красоте",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Разрешить", style: .default) { _ in
                    print("✅ User wants to enable notifications")
                    continuation.resume(returning: true)
                })
                
                alert.addAction(UIAlertAction(title: "Позже", style: .cancel) { _ in
                    print("⏭️ User skipped notifications")
                    continuation.resume(returning: false)
                })
                
                rootVC.present(alert, animated: true) {
                    print("📱 Notifications alert presented")
                }
            }
        }
        
        if userWantsToEnable {
            // Request actual system notification permission
            do {
                let result = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
                print("📱 System notification permission result: \(result)")
                if result {
                    HapticsService.shared.success()
                }
                return result
            } catch {
                print("❌ Notification permission error: \(error)")
                HapticsService.shared.impactMedium()
                return false
            }
        } else {
            HapticsService.shared.impactLight()
            return false
        }
    }
    
    // MARK: - Complete Onboarding
    @MainActor
    func completeFirstTimeOnboarding() async {
        // Request biometric permission
        _ = await requestBiometricPermission()
        
        // Small delay between requests
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Request notification permission
        _ = await requestNotificationPermission()
    }
}
