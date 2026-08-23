import Foundation
import SwiftData
import XCTest
@testable import Pip

@MainActor
final class LocalStatsRebuilderTests: XCTestCase {
    func testRebuildUsesCompletionDayKeysAndRemovesStaleAggregates() throws {
        let store = try LocalStore.makeInMemoryForTesting()
        let firstDate = Date(timeIntervalSince1970: 1_750_000_000)
        let secondDate = firstDate.addingTimeInterval(86_400)
        store.context.insert(completedSession(dayKey: "2026-08-20", completedAt: firstDate))
        store.context.insert(completedSession(dayKey: "2026-08-21", completedAt: secondDate))
        store.context.insert(completedSession(dayKey: "2026-08-21", completedAt: secondDate.addingTimeInterval(60)))
        store.context.insert(CalendarDayStat(
            dayKey: "2026-08-19",
            completedSessionCount: 99,
            streakLengthEndingOnDay: 99
        ))
        store.context.insert(CalendarDayStat(
            dayKey: "2026-08-20",
            completedSessionCount: 99,
            streakLengthEndingOnDay: 99
        ))
        store.context.insert(StreakState(
            id: "singleton",
            currentStreakDays: 99,
            lastCompletedDayKey: "2026-08-19"
        ))
        store.context.insert(StreakState(id: "obsolete"))
        try store.context.save()

        let summary = try LocalStatsRebuilder().rebuild(
            context: store.context,
            timeZone: TimeZone(identifier: "America/New_York")!,
            now: secondDate
        )

        XCTAssertEqual(summary.countsByDayKey, ["2026-08-20": 1, "2026-08-21": 2])
        XCTAssertEqual(summary.streakByDayKey, ["2026-08-20": 1, "2026-08-21": 2])

        let stats = try store.context.fetch(FetchDescriptor<CalendarDayStat>())
        XCTAssertEqual(stats.map(\.dayKey).sorted(), ["2026-08-20", "2026-08-21"])
        XCTAssertEqual(
            Dictionary(uniqueKeysWithValues: stats.map { ($0.dayKey, $0.completedSessionCount) }),
            ["2026-08-20": 1, "2026-08-21": 2]
        )
        XCTAssertTrue(stats.allSatisfy { $0.updatedAt == secondDate })

        let states = try store.context.fetch(FetchDescriptor<StreakState>())
        XCTAssertEqual(states.count, 1)
        XCTAssertEqual(states.first?.id, "singleton")
        XCTAssertEqual(states.first?.currentStreakDays, 2)
        XCTAssertEqual(states.first?.lastCompletedDayKey, "2026-08-21")
    }

    func testCalendarLoadRebuildsAndPersistsLocalStats() throws {
        let store = try LocalStore.makeInMemoryForTesting()
        let date = Date(timeIntervalSince1970: 1_750_000_000)
        store.context.insert(completedSession(dayKey: "2026-08-21", completedAt: date))
        try store.context.save()

        let viewModel = CalendarViewModel(
            now: date,
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        viewModel.load(context: store.context)

        XCTAssertEqual(viewModel.countsByDayKey, ["2026-08-21": 1])
        XCTAssertEqual(viewModel.currentStreakDays, 1)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<CalendarDayStat>()).count, 1)
        XCTAssertEqual(try store.context.fetch(FetchDescriptor<StreakState>()).count, 1)
    }

    private func completedSession(dayKey: String, completedAt: Date) -> SessionRecord {
        SessionRecord(
            status: .completed,
            startedAt: completedAt.addingTimeInterval(-48),
            completedAt: completedAt,
            startDayKey: dayKey,
            completionDayKey: dayKey,
            completedCycles: 8,
            activeSeconds: 48,
            createdAt: completedAt.addingTimeInterval(-48),
            updatedAt: completedAt
        )
    }
}
