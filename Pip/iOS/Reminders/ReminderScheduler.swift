import Foundation
import UserNotifications

public struct ReminderNotificationDescriptor: Equatable, Sendable {
    public let identifier: String
    public let slotKey: String
    public let weekday: Int
    public let hour: Int
    public let minute: Int

    public init(identifier: String, slotKey: String, weekday: Int, hour: Int, minute: Int) {
        self.identifier = identifier
        self.slotKey = slotKey
        self.weekday = weekday
        self.hour = hour
        self.minute = minute
    }
}

public final class ReminderScheduler {
    public static let identifierPrefix = "Pip.Reminder"
    public static let slotKeys = ["morning", "afternoon", "evening"]

    private let center: UNUserNotificationCenter
    private let calendar: Calendar
    private let timeZone: TimeZone

    public init(
        center: UNUserNotificationCenter = .current(),
        calendar: Calendar = .current,
        timeZone: TimeZone = .current
    ) {
        self.center = center
        var calendar = calendar
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.timeZone = timeZone
    }

    public func descriptors(for slot: ReminderSlot) -> [ReminderNotificationDescriptor] {
        guard slot.isEnabled, slot.isValidForScheduling else { return [] }

        return (0..<7).compactMap { dayIndex in
            guard slot.weekdayMask & (1 << dayIndex) != 0 else { return nil }
            let weekday = Self.foundationWeekday(forBitIndex: dayIndex)
            return ReminderNotificationDescriptor(
                identifier: Self.identifier(slotKey: slot.slotKey, weekday: weekday),
                slotKey: slot.slotKey,
                weekday: weekday,
                hour: slot.hour,
                minute: slot.minute
            )
        }
    }

    public func descriptors(for slots: [ReminderSlot]) -> [ReminderNotificationDescriptor] {
        slots.flatMap(descriptors(for:))
    }

    public func requests(for slots: [ReminderSlot]) -> [UNNotificationRequest] {
        descriptors(for: slots).map { descriptor in
            let content = UNMutableNotificationContent()
            content.title = "Pip reminder"
            content.body = "A short Kegel session is ready when you are."
            content.sound = .default

            var components = DateComponents()
            components.calendar = calendar
            components.timeZone = timeZone
            components.weekday = descriptor.weekday
            components.hour = descriptor.hour
            components.minute = descriptor.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            return UNNotificationRequest(identifier: descriptor.identifier, content: content, trigger: trigger)
        }
    }

    public func replaceScheduledReminders(
        with slots: [ReminderSlot],
        completion: ((Error?) -> Void)? = nil
    ) {
        let requests = requests(for: slots)
        center.removePendingNotificationRequests(withIdentifiers: Self.allOwnedIdentifiers)
        for request in requests {
            center.add(request) { error in
                completion?(error)
            }
        }
        if requests.isEmpty {
            completion?(nil)
        }
    }

    public static func identifier(slotKey: String, weekday: Int) -> String {
        "\(identifierPrefix).\(slotKey).weekday-\(weekday)"
    }

    public static var allOwnedIdentifiers: [String] {
        slotKeys.flatMap { slotKey in
            (1...7).map { identifier(slotKey: slotKey, weekday: $0) }
        }
    }

    public static func foundationWeekday(forBitIndex index: Int) -> Int {
        precondition((0...6).contains(index))
        return index == 6 ? 1 : index + 2
    }

    public static func bitIndex(forFoundationWeekday weekday: Int) -> Int? {
        switch weekday {
        case 1: return 6
        case 2...7: return weekday - 2
        default: return nil
        }
    }
}
