import Foundation

public struct StreakSummary: Equatable, Sendable {
    public let countsByDayKey: [String: Int]
    public let streakByDayKey: [String: Int]
    public let currentStreakDays: Int
    public let lastCompletedDayKey: String?

    public init(
        countsByDayKey: [String: Int],
        streakByDayKey: [String: Int],
        currentStreakDays: Int,
        lastCompletedDayKey: String?
    ) {
        self.countsByDayKey = countsByDayKey
        self.streakByDayKey = streakByDayKey
        self.currentStreakDays = currentStreakDays
        self.lastCompletedDayKey = lastCompletedDayKey
    }
}

public struct StreakCalculator: Sendable {
    public init() {}

    public func summarize(
        completionDates: [Date],
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> StreakSummary {
        var calendar = calendar
        calendar.timeZone = timeZone

        let counts = completionDates.reduce(into: [String: Int]()) { result, date in
            let dayKey = Self.dayKey(for: date, calendar: calendar, timeZone: timeZone)
            result[dayKey, default: 0] += 1
        }

        return summarize(dayCounts: counts, calendar: calendar)
    }

    private func summarize(
        dayCounts: [String: Int],
        calendar: Calendar
    ) -> StreakSummary {
        let counts = dayCounts

        let sortedKeys = counts.keys.sorted()
        var streaks: [String: Int] = [:]
        var currentRun = 0
        var previousDate: Date?

        for key in sortedKeys {
            guard let date = Self.date(fromDayKey: key, calendar: calendar) else {
                continue
            }

            if let previousDate,
               calendar.dateComponents([.day], from: previousDate, to: date).day == 1 {
                currentRun += 1
            } else {
                currentRun = 1
            }
            streaks[key] = currentRun
            previousDate = date
        }

        let lastKey = sortedKeys.last
        return StreakSummary(
            countsByDayKey: counts,
            streakByDayKey: streaks,
            currentStreakDays: lastKey.flatMap { streaks[$0] } ?? 0,
            lastCompletedDayKey: lastKey
        )
    }

    public func summarize(
        sessions: [SessionRecord],
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> StreakSummary {
        summarize(
            dayCounts: sessions
                .filter { $0.status == .completed && $0.satisfiesCompletionInvariant }
                .compactMap(\.completionDayKey)
                .reduce(into: [String: Int]()) { result, dayKey in
                    guard PipDateKey.isValid(dayKey) else { return }
                    result[dayKey, default: 0] += 1
                },
            calendar: calendarWithTimeZone(calendar, timeZone: timeZone)
        )
    }

    private func calendarWithTimeZone(_ calendar: Calendar, timeZone: TimeZone) -> Calendar {
        var calendar = calendar
        calendar.timeZone = timeZone
        return calendar
    }

    public static func dayKey(
        for date: Date,
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

    public static func date(
        fromDayKey dayKey: String,
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> Date? {
        var calendar = calendar
        calendar.timeZone = timeZone
        return date(fromDayKey: dayKey, calendar: calendar)
    }

    private static func date(fromDayKey dayKey: String, calendar: Calendar) -> Date? {
        let components = dayKey.split(separator: "-").compactMap { Int($0) }
        guard components.count == 3 else { return nil }
        return calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: components[0],
            month: components[1],
            day: components[2]
        ))
    }
}
