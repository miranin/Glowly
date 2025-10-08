//
//  NotificationService.swift
//  Glowly
//
//  Created by Tamirlan Aubakirov on 02/10/25.
//

import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleExpiryReminders(for products: [Product]) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for product in products {
            guard let expiryDate = product.expiryDate,
                  !product.isExpired,
                  product.isActive else { continue }
            
            let calendar = Calendar.current
            let daysUntilExpiry = calendar.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
            
            // Schedule notifications for 30, 14, 7, 3, and 1 days before expiry
            let reminderDays = [30, 14, 7, 3, 1]
            
            for days in reminderDays {
                if daysUntilExpiry >= days {
                    scheduleNotification(
                        for: product,
                        daysBeforeExpiry: days,
                        actualDaysUntilExpiry: daysUntilExpiry
                    )
                }
            }
        }
    }
    
    private func scheduleNotification(for product: Product, daysBeforeExpiry: Int, actualDaysUntilExpiry: Int) {
        guard let expiryDate = product.expiryDate else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Glowly - Напоминание"
        
        if daysBeforeExpiry == 1 {
            content.body = "⚠️ \(product.name) от \(product.brand) истекает завтра!"
        } else if daysBeforeExpiry <= 3 {
            content.body = "⚠️ \(product.name) от \(product.brand) истекает через \(actualDaysUntilExpiry) дня!"
        }
        
        content.sound = .default
        content.badge = 1
        
        // Calculate trigger date
        let triggerDate = Calendar.current.date(byAdding: .day, value: -(daysBeforeExpiry - actualDaysUntilExpiry), to: expiryDate)!
        let triggerDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDateComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(product.id.uuidString)_\(daysBeforeExpiry)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func scheduleDailyRoutineReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Glowly - Утренняя рутина"
        content.body = "✨ Время для утреннего ухода! Проверь свою косметичку"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_routine_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily reminder: \(error)")
            }
        }
    }
    
    func scheduleEveningRoutineReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Glowly - Вечерняя рутина"
        content.body = "🌙 Время для вечернего ухода! Не забудь снять макияж"
        content.sound = .default
        content.badge = 1
        
        var dateComponents = DateComponents()
        dateComponents.hour = 22
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "evening_routine_reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling evening reminder: \(error)")
            }
        }
    }
}
