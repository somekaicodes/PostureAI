import UserNotifications

// Schedules the daily "Ready to Exercise?" reminder as a local notification —
// no server or push capability needed, just on-device scheduling.
enum NotificationService {
    private static let reminderID = "daily-exercise-reminder"

    // Ask the user once for permission to show notifications.
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    // Schedule (or replace) a reminder that repeats every day at the given time.
    static func scheduleDailyReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])

        let content = UNMutableNotificationContent()
        content.title = "Ready to Exercise?"
        content.body = "Time for your workout — let's get those reps in!"
        content.sound = .default

        var time = DateComponents()
        time.hour = hour
        time.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)

        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderID])
    }
}
