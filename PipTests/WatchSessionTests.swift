import XCTest
@testable import Pip

final class WatchSessionTests: XCTestCase {
    func testWatchSessionUsesIndependent48SecondEngine() {
        var engine = SessionEngine()
        _ = engine.start()
        let events = engine.advance(by: 48)

        XCTAssertEqual(engine.configuration.totalDuration, 48)
        XCTAssertEqual(engine.completedRepetitions, 8)
        XCTAssertEqual(engine.activeSeconds, 48)
        XCTAssertTrue(events.contains(.completed))
    }

    func testWatchPauseAndResumeDoNotWriteOrCompleteEarly() {
        var engine = SessionEngine()
        _ = engine.start()
        _ = engine.advance(by: 5)
        _ = engine.pause()
        _ = engine.advance(by: 48)

        XCTAssertEqual(engine.phase, .paused)
        XCTAssertFalse(engine.isCompleted)

        _ = engine.resume()
        let events = engine.advance(by: 43)
        XCTAssertTrue(events.contains(.completed))
        XCTAssertEqual(engine.activeSeconds, 48)
    }

    func testWatchSnapshotReaderNeverWrites() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pip-watch-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let snapshot = try PipSnapshot(
            deviceDayKey: PipDateKey.make(from: now),
            todayCompletedCount: 1,
            updatedAt: now
        )
        let store = PipSnapshotStore(fileURL: url)
        try store.write(snapshot)
        let before = try Data(contentsOf: url)

        let reader = WatchSurfaceSnapshotReader(store: store)
        XCTAssertEqual(reader.read(now: now), snapshot)
        XCTAssertEqual(try Data(contentsOf: url), before)
    }

    func testWatchReaderSafelyRejectsIncompleteReminderPair() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pip-watch-corrupt-(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let corrupt = #"{"schemaVersion":1,"deviceDayKey":"2026-08-21","todayCompletedCount":1,"currentStreakDays":1,"nextReminderAt":null,"nextReminderSlotKey":"morning","pipStaticState":"idle","updatedAt":"2026-08-21T00:00:00Z"}"#
        try Data(corrupt.utf8).write(to: url)

        XCTAssertNil(WatchSurfaceSnapshotReader(store: PipSnapshotStore(fileURL: url)).read())
    }
}
