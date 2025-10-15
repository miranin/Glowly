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
