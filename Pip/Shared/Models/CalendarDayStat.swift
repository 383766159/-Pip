import Foundation
import SwiftData

@Model
public final class CalendarDayStat {
    @Attribute(.unique) public var dayKey: String
    public var completedSessionCount: Int
    public var streakLengthEndingOnDay: Int
    public var updatedAt: Date

    public init(
        dayKey: String,
        completedSessionCount: Int = 0,
        streakLengthEndingOnDay: Int = 0,
        updatedAt: Date = Date()
    ) {
        self.dayKey = dayKey
        self.completedSessionCount = completedSessionCount
        self.streakLengthEndingOnDay = streakLengthEndingOnDay
        self.updatedAt = updatedAt
    }
}
