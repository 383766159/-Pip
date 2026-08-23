import Foundation

public enum PipStaticState: String, Codable, CaseIterable, Sendable {
    case idle
    case waiting
    case done
}

public enum PipDateKey {
    public static func make(
        from date: Date,
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> String {
        var calendar = calendar
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04ld-%02ld-%02ld",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    public static func isValid(_ value: String) -> Bool {
        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0].count == 4,
              parts[1].count == 2,
              parts[2].count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else {
            return false
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = calendar.date(from: components) else {
            return false
        }
        return make(from: date, calendar: calendar, timeZone: calendar.timeZone) == value
    }
}

public enum PipSnapshotValidationError: Error, Equatable {
    case unsupportedSchemaVersion(Int)
    case invalidDeviceDayKey(String)
    case negativeCount
    case invalidState(String)
    case missingReminderSlotKey
}

public struct PipSnapshot: Codable, Equatable, Sendable {
    public static let supportedSchemaVersion = 1

    public let schemaVersion: Int
    public let deviceDayKey: String
    public let todayCompletedCount: Int
    public let currentStreakDays: Int
    public let nextReminderAt: Date?
    public let nextReminderSlotKey: String?
    public let pipStaticState: PipStaticState
    public let updatedAt: Date

    public init(
        schemaVersion: Int = PipSnapshot.supportedSchemaVersion,
        deviceDayKey: String,
        todayCompletedCount: Int = 0,
        currentStreakDays: Int = 0,
        nextReminderAt: Date? = nil,
        nextReminderSlotKey: String? = nil,
        pipStaticState: PipStaticState = .idle,
        updatedAt: Date = Date()
    ) throws {
        guard schemaVersion == Self.supportedSchemaVersion else {
            throw PipSnapshotValidationError.unsupportedSchemaVersion(schemaVersion)
        }
        guard PipDateKey.isValid(deviceDayKey) else {
            throw PipSnapshotValidationError.invalidDeviceDayKey(deviceDayKey)
        }
        guard todayCompletedCount >= 0, currentStreakDays >= 0 else {
            throw PipSnapshotValidationError.negativeCount
        }
        guard (nextReminderAt == nil) == (nextReminderSlotKey == nil) else {
            throw PipSnapshotValidationError.missingReminderSlotKey
        }
        if let nextReminderSlotKey, nextReminderSlotKey.isEmpty {
            throw PipSnapshotValidationError.missingReminderSlotKey
        }

        self.schemaVersion = schemaVersion
        self.deviceDayKey = deviceDayKey
        self.todayCompletedCount = todayCompletedCount
        self.currentStreakDays = currentStreakDays
        self.nextReminderAt = nextReminderAt
        self.nextReminderSlotKey = nextReminderSlotKey
        self.pipStaticState = pipStaticState
        self.updatedAt = updatedAt
    }

    public static func empty(
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> PipSnapshot {
        let dayKey = PipDateKey.make(from: now, calendar: calendar, timeZone: timeZone)
        return try! PipSnapshot(deviceDayKey: dayKey, updatedAt: now)
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion
        case deviceDayKey
        case todayCompletedCount
        case currentStreakDays
        case nextReminderAt
        case nextReminderSlotKey
        case pipStaticState
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        let deviceDayKey = try container.decode(String.self, forKey: .deviceDayKey)
        let todayCompletedCount = try container.decode(Int.self, forKey: .todayCompletedCount)
        let currentStreakDays = try container.decode(Int.self, forKey: .currentStreakDays)
        let nextReminderAt = try container.decodeIfPresent(Date.self, forKey: .nextReminderAt)
        let nextReminderSlotKey = try container.decodeIfPresent(String.self, forKey: .nextReminderSlotKey)
        let state = try container.decode(PipStaticState.self, forKey: .pipStaticState)
        let updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        try self.init(
            schemaVersion: schemaVersion,
            deviceDayKey: deviceDayKey,
            todayCompletedCount: todayCompletedCount,
            currentStreakDays: currentStreakDays,
            nextReminderAt: nextReminderAt,
            nextReminderSlotKey: nextReminderSlotKey,
            pipStaticState: state,
            updatedAt: updatedAt
        )
    }
}
