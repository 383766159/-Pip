import XCTest
@testable import Pip

final class StreakCalculatorTests: XCTestCase {
    private let calculator = StreakCalculator()

    func testSameDayMultipleRoundsCountOnceForStreak() {
        let timeZone = TimeZone(secondsFromGMT: 0)!
        let dates = [
            date("2026-01-05T08:00:00Z"),
            date("2026-01-05T12:00:00Z"),
            date("2026-01-06T08:00:00Z")
        ]

        let summary = calculator.summarize(completionDates: dates, timeZone: timeZone)

        XCTAssertEqual(summary.countsByDayKey["2026-01-05"], 2)
        XCTAssertEqual(summary.streakByDayKey["2026-01-05"], 1)
        XCTAssertEqual(summary.streakByDayKey["2026-01-06"], 2)
        XCTAssertEqual(summary.currentStreakDays, 2)
    }

    func testGapBreaksStreak() {
        let dates = [date("2026-01-10T08:00:00Z"), date("2026-01-12T08:00:00Z")]

        let summary = calculator.summarize(completionDates: dates, timeZone: TimeZone(secondsFromGMT: 0)!)

        XCTAssertEqual(summary.currentStreakDays, 1)
        XCTAssertEqual(summary.streakByDayKey["2026-01-10"], 1)
        XCTAssertEqual(summary.streakByDayKey["2026-01-12"], 1)
    }

    func testMonthBoundaryIsContinuousAcrossDecemberAndJanuary() {
        let dates = [date("2025-12-31T23:00:00Z"), date("2026-01-01T01:00:00Z")]

        let summary = calculator.summarize(completionDates: dates, timeZone: TimeZone(secondsFromGMT: 0)!)

        XCTAssertEqual(summary.currentStreakDays, 2)
        XCTAssertEqual(summary.streakByDayKey["2025-12-31"], 1)
        XCTAssertEqual(summary.streakByDayKey["2026-01-01"], 2)
    }

    func testDeviceTimeZoneDeterminesDayOwnership() {
        let date = date("2026-01-01T00:30:00Z")
        let newYork = TimeZone(identifier: "America/New_York")!
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!

        let newYorkSummary = calculator.summarize(completionDates: [date], timeZone: newYork)
        let tokyoSummary = calculator.summarize(completionDates: [date], timeZone: tokyo)

        XCTAssertEqual(newYorkSummary.lastCompletedDayKey, "2025-12-31")
        XCTAssertEqual(tokyoSummary.lastCompletedDayKey, "2026-01-01")
    }

    func testSessionsUsePersistedCompletionDayKeyAcrossTimeZones() {
        let sessions = [
            completedSession(
                completionDayKey: "2026-01-01",
                completedAt: "2025-12-31T23:30:00Z"
            ),
            completedSession(
                completionDayKey: "2026-01-01",
                completedAt: "2026-01-01T00:30:00Z"
            )
        ]
        let newYork = TimeZone(identifier: "America/New_York")!
        let tokyo = TimeZone(identifier: "Asia/Tokyo")!

        let newYorkSummary = calculator.summarize(sessions: sessions, timeZone: newYork)
        let tokyoSummary = calculator.summarize(sessions: sessions, timeZone: tokyo)

        XCTAssertEqual(newYorkSummary.countsByDayKey, ["2026-01-01": 2])
        XCTAssertEqual(tokyoSummary.countsByDayKey, ["2026-01-01": 2])
        XCTAssertEqual(newYorkSummary.lastCompletedDayKey, "2026-01-01")
        XCTAssertEqual(tokyoSummary.lastCompletedDayKey, "2026-01-01")
    }

    func testEmptyInputHasNoStreak() {
        let summary = calculator.summarize(completionDates: [], timeZone: TimeZone(secondsFromGMT: 0)!)

        XCTAssertEqual(summary.currentStreakDays, 0)
        XCTAssertNil(summary.lastCompletedDayKey)
        XCTAssertTrue(summary.countsByDayKey.isEmpty)
    }

    private func date(_ value: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: value)!
    }

    private func completedSession(
        completionDayKey: String,
        completedAt: String
    ) -> SessionRecord {
        let completedAt = date(completedAt)
        return SessionRecord(
            status: .completed,
            startedAt: completedAt.addingTimeInterval(-48),
            completedAt: completedAt,
            startDayKey: "2025-12-31",
            completionDayKey: completionDayKey,
            completedCycles: 8,
            activeSeconds: 48,
            createdAt: completedAt.addingTimeInterval(-48),
            updatedAt: completedAt
        )
    }
}
