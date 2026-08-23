import Foundation
import SwiftData

@Model
public final class ReminderSlot {
    @Attribute(.unique) public var id: UUID
    @Attribute(.unique) public var slotKey: String
    public var hour: Int
    public var minute: Int
    public var weekdayMask: Int
    public var isEnabled: Bool
    public var timezoneIdentifierAtLastSchedule: String?
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        slotKey: String,
        hour: Int,
        minute: Int,
        weekdayMask: Int,
        isEnabled: Bool = true,
        timezoneIdentifierAtLastSchedule: String? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.slotKey = slotKey
        self.hour = hour
        self.minute = minute
        self.weekdayMask = weekdayMask
        self.isEnabled = isEnabled
        self.timezoneIdentifierAtLastSchedule = timezoneIdentifierAtLastSchedule
        self.updatedAt = updatedAt
    }

    public var isValidForScheduling: Bool {
        (0...23).contains(hour) &&
            (0...59).contains(minute) &&
            (1...127).contains(weekdayMask)
    }

    public static func defaultSlots(now: Date = Date()) -> [ReminderSlot] {
        let workdays = 0b0001_1111
        return [
            ReminderSlot(slotKey: "morning", hour: 9, minute: 0, weekdayMask: workdays, updatedAt: now),
            ReminderSlot(slotKey: "afternoon", hour: 13, minute: 0, weekdayMask: workdays, updatedAt: now),
            ReminderSlot(slotKey: "evening", hour: 20, minute: 0, weekdayMask: workdays, updatedAt: now)
        ]
    }
}
