import Foundation
import UserNotifications
import SwiftData
import UIKit

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Permission Request
    
    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Scheduling Notifications
    
    func scheduleReviewNotifications(for locations: [Location]) async {
        let center = UNUserNotificationCenter.current()
        
        // Remove all pending notifications first
        center.removeAllPendingNotificationRequests()
        
        // Group locations by their next review date
        let calendar = Calendar.current
        let now = Date()
        
        // Filter locations that are due today or in the future
        let upcomingLocations = locations.filter { $0.nextReview >= calendar.startOfDay(for: now) }
        
        // Group by date
        let groupedByDate = Dictionary(grouping: upcomingLocations) { location in
            calendar.startOfDay(for: location.nextReview)
        }
        
        // Schedule one notification per day with review count
        for (date, locationsOnDate) in groupedByDate {
            guard date >= now else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = "Reviews Due"
            
            let count = locationsOnDate.count
            content.body = count == 1 
                ? "You have 1 location to review"
                : "You have \(count) locations to review"
            
            content.sound = .default
            content.badge = NSNumber(value: count)
            
            // Schedule for 9 AM on the review date
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            dateComponents.hour = 9
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "review-\(date.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await center.add(request)
            } catch {
                print("Error scheduling notification: \(error)")
            }
        }
        
        // Also schedule a daily reminder if there are overdue reviews
        await scheduleOverdueNotification(for: locations)
    }
    
    private func scheduleOverdueNotification(for locations: [Location]) async {
        let now = Date()
        let overdueCount = locations.filter { $0.nextReview < now }.count
        
        guard overdueCount > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Overdue Reviews"
        content.body = overdueCount == 1
            ? "You have 1 overdue review"
            : "You have \(overdueCount) overdue reviews"
        content.sound = .default
        content.badge = NSNumber(value: overdueCount)
        
        // Schedule for tomorrow at 9 AM and repeat daily
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "overdue-daily",
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Error scheduling overdue notification: \(error)")
        }
    }
    
    // MARK: - Clear Notifications
    
    func clearNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        setBadgeCount(0)
    }
    
    func updateBadgeCount(to count: Int) {
        setBadgeCount(count)
    }
    
    private func setBadgeCount(_ count: Int) {
        Task {
            do {
                try await UNUserNotificationCenter.current().setBadgeCount(count)
            } catch {
                print("Error setting badge count: \(error)")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                               willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse) async {
        // Handle notification tap
        // Post a notification that the app can listen to
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("OpenReviewMode"),
                object: nil
            )
        }
    }
}