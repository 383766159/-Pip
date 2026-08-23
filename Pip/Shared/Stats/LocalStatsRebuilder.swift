import Foundation
import SwiftData

@MainActor
public struct LocalStatsRebuilder {
    private let calculator: StreakCalculator

    public init(calculator: StreakCalculator = StreakCalculator()) {
        self.calculator = calculator
    }

    @discardableResult
    public func rebuild(
        context: ModelContext,
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current,
        now: Date = Date()
    ) throws -> StreakSummary {
        let sessions = try context.fetch(FetchDescriptor<SessionRecord>())
        let summary = calculator.summarize(
            sessions: sessions,
            calendar: calendar,
            timeZone: timeZone
        )

        let storedStats = try context.fetch(FetchDescriptor<CalendarDayStat>())
        var retainedDayKeys = Set<String>()
        for stat in storedStats {
            guard let count = summary.countsByDayKey[stat.dayKey] else {
                context.delete(stat)
                continue
            }

            guard retainedDayKeys.insert(stat.dayKey).inserted else {
                context.delete(stat)
                continue
            }

            stat.completedSessionCount = count
            stat.streakLengthEndingOnDay = summary.streakByDayKey[stat.dayKey, default: 0]
            stat.updatedAt = now
        }

        for dayKey in summary.countsByDayKey.keys where !retainedDayKeys.contains(dayKey) {
            context.insert(CalendarDayStat(
                dayKey: dayKey,
                completedSessionCount: summary.countsByDayKey[dayKey, default: 0],
                streakLengthEndingOnDay: summary.streakByDayKey[dayKey, default: 0],
                updatedAt: now
            ))
        }

        let states = try context.fetch(FetchDescriptor<StreakState>())
        let singleton = states.first(where: { $0.id == "singleton" }) ?? {
            let state = StreakState(id: "singleton")
            context.insert(state)
            return state
        }()
        for state in states where state !== singleton {
            context.delete(state)
        }
        singleton.currentStreakDays = summary.currentStreakDays
        singleton.lastCompletedDayKey = summary.lastCompletedDayKey
        singleton.calculationVersion = 1
        singleton.updatedAt = now

        try context.save()
        return summary
    }
}
