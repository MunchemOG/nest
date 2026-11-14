import Foundation
import NestKit
import UserNotifications

/// Delivers critical pings as macOS notifications, asking for permission the first time one is needed.
enum SystemNotifications {
    static func post(_ note: PingNote) async {
        let center = UNUserNotificationCenter.current()
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
        let content = UNMutableNotificationContent()
        content.title = note.title
        content.body = note.body
        content.sound = .default
        try? await center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
