import Foundation
import SwiftData

@Model
public final class StreakState {
    @Attribute(.unique) public var id: String
    public var currentStreakDays: Int
    public var lastCompletedDayKey: String?
    public var calculationVersion: Int
    public var updatedAt: Date

    public init(
        id: String = "singleton",
        currentStreakDays: Int = 0,
        lastCompletedDayKey: String? = nil,
        calculationVersion: Int = 1,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.currentStreakDays = currentStreakDays
        self.lastCompletedDayKey = lastCompletedDayKey
        self.calculationVersion = calculationVersion
        self.updatedAt = updatedAt
    }
}
