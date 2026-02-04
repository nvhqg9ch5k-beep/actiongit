import Foundation
import UserNotifications
import CoreData

class ReminderManager {
    static let shared = ReminderManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    func scheduleReminder(for ritual: MoneyRitual) {
        guard ritual.reminderEnabled,
              let ritualId = ritual.id?.uuidString,
              let name = ritual.name else {
            return
        }
        
        // Cancel existing reminder
        cancelReminder(for: ritual)
        
        // Calculate next reminder time based on frequency
        guard let reminderDate = calculateReminderDate(for: ritual) else {
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for your ritual"
        content.body = name
        content.sound = .default
        content.categoryIdentifier = "RITUAL_REMINDER"
        content.userInfo = ["ritualId": ritualId]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "ritual_\(ritualId)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                // Silent failure - user can retry
                _ = error
            }
        }
    }
    
    func cancelReminder(for ritual: MoneyRitual) {
        guard let ritualId = ritual.id?.uuidString else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ritual_\(ritualId)"])
    }
    
    func updateAllReminders(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<MoneyRitual> = MoneyRitual.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "reminderEnabled == YES AND isArchived == NO AND isPaused == NO")
        
        do {
            let rituals = try context.fetch(fetchRequest)
            for ritual in rituals {
                scheduleReminder(for: ritual)
            }
        } catch {
            // Silent failure
        }
    }
    
    private func calculateReminderDate(for ritual: MoneyRitual) -> Date? {
        guard let frequency = ritual.frequency else { return nil }
        let calendar = Calendar.current
        let now = Date()
        
        switch frequency {
        case "Daily":
            // Default to 9 AM today or tomorrow
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 9
            components.minute = 0
            let reminderDate = calendar.date(from: components) ?? now
            return reminderDate > now ? reminderDate : calendar.date(byAdding: .day, value: 1, to: reminderDate)
            
        case "Weekly":
            // Default to next Monday at 9 AM
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilMonday = (2 - weekday + 7) % 7
            let daysToAdd = daysUntilMonday == 0 ? 7 : daysUntilMonday
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.day = (components.day ?? 1) + daysToAdd
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components)
            
        case "Monthly":
            // Default to first day of next month at 9 AM
            var components = calendar.dateComponents([.year, .month], from: now)
            components.month = (components.month ?? 1) + 1
            components.day = 1
            components.hour = 9
            components.minute = 0
            return calendar.date(from: components)
            
        default:
            return nil
        }
    }
}
