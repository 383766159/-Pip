import Foundation
import SwiftData
import SwiftUI

@MainActor
public final class CalendarViewModel: ObservableObject {
    @Published public private(set) var countsByDayKey: [String: Int] = [:]
    @Published public private(set) var streakByDayKey: [String: Int] = [:]
    @Published public private(set) var currentStreakDays = 0
    @Published public private(set) var selectedDate: Date
    @Published public private(set) var displayedMonth: Date

    public let calendar: Calendar
    public let timeZone: TimeZone

    private let calculator: StreakCalculator

    public init(
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current,
        calculator: StreakCalculator = StreakCalculator()
    ) {
        var calendar = calendar
        calendar.timeZone = timeZone
        self.calendar = calendar
        self.timeZone = timeZone
        self.calculator = calculator
        self.selectedDate = now
        self.displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
    }

    public var selectedDayKey: String {
        StreakCalculator.dayKey(for: selectedDate, calendar: calendar, timeZone: timeZone)
    }

    public var selectedDayCount: Int {
        countsByDayKey[selectedDayKey, default: 0]
    }

    public var selectedDayStreak: Int {
        streakByDayKey[selectedDayKey, default: 0]
    }

    public var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    public var weekdaySymbols: [String] {
        calendar.veryShortStandaloneWeekdaySymbols
    }

    public var monthDays: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstDay = calendar.dateInterval(of: .day, for: interval.start)?.start else {
            return []
        }

        let leading = (calendar.component(.weekday, from: firstDay) - calendar.firstWeekday + 7) % 7
        let count = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 0
        let dates = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
        return Array(repeating: nil, count: leading) + dates.map(Optional.some)
    }

    public func load(context: ModelContext) {
        do {
            let summary = try LocalStatsRebuilder(calculator: calculator).rebuild(
                context: context,
                calendar: calendar,
                timeZone: timeZone,
                now: Date()
            )
            apply(summary)
        } catch {
            countsByDayKey = [:]
            streakByDayKey = [:]
            currentStreakDays = 0
        }
    }

    public func apply(_ summary: StreakSummary) {
        countsByDayKey = summary.countsByDayKey
        streakByDayKey = summary.streakByDayKey
        currentStreakDays = summary.currentStreakDays
    }

    public func select(_ date: Date) {
        selectedDate = date
        displayedMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    public func moveMonth(by value: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) ?? displayedMonth
    }

    public func count(for date: Date) -> Int {
        countsByDayKey[StreakCalculator.dayKey(for: date, calendar: calendar, timeZone: timeZone), default: 0]
    }
}
