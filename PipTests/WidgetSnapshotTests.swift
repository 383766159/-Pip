import XCTest
@testable import Pip

final class WidgetSnapshotTests: XCTestCase {
    func testValidIdleWaitingAndDoneSnapshotsAreReadOnly() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        for state in PipStaticState.allCases {
            let url = temporaryURL()
            defer { try? FileManager.default.removeItem(at: url) }
            let store = PipSnapshotStore(fileURL: url)
            let snapshot = try PipSnapshot(
                deviceDayKey: PipDateKey.make(from: now),
                todayCompletedCount: state == .idle ? 0 : 2,
                pipStaticState: state,
                updatedAt: now
            )
            try store.write(snapshot)
            let before = try Data(contentsOf: url)

            XCTAssertEqual(PipWidgetSnapshotReader(store: store).read(now: now), .valid(snapshot))
            XCTAssertEqual(try Data(contentsOf: url), before)
        }
    }

    func testExpiredSnapshotUsesSafeEmptyState() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let snapshot = try PipSnapshot(
            deviceDayKey: PipDateKey.make(from: now),
            updatedAt: now.addingTimeInterval(-PipWidgetSnapshotReader.expirationInterval - 1)
        )
        let store = PipSnapshotStore(fileURL: url)
        try store.write(snapshot)

        XCTAssertEqual(PipWidgetSnapshotReader(store: store).read(now: now), .empty(.expired))
    }

    func testUnknownSchemaUsesSafeEmptyState() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let unknown = #"{"schemaVersion":99,"deviceDayKey":"2026-08-21","todayCompletedCount":1,"currentStreakDays":1,"nextReminderAt":null,"nextReminderSlotKey":null,"pipStaticState":"idle","updatedAt":"2026-08-21T00:00:00Z"}"#
        try Data(unknown.utf8).write(to: url)

        XCTAssertEqual(PipWidgetSnapshotReader(store: PipSnapshotStore(fileURL: url)).read(), .empty(.unknownSchema))
    }

    func testCorruptAndMissingSnapshotsUseSafeEmptyState() {
        let missing = temporaryURL()
        XCTAssertEqual(PipWidgetSnapshotReader(store: PipSnapshotStore(fileURL: missing)).read(), .empty(.missing))

        let corrupt = temporaryURL()
        defer {
            try? FileManager.default.removeItem(at: missing)
            try? FileManager.default.removeItem(at: corrupt)
        }
        try? Data("not-json".utf8).write(to: corrupt)
        XCTAssertEqual(PipWidgetSnapshotReader(store: PipSnapshotStore(fileURL: corrupt)).read(), .empty(.corrupt))
    }

    func testIncompleteReminderPairFallsBackToSafeEmptyState() throws {
        let url = temporaryURL()
        defer { try? FileManager.default.removeItem(at: url) }
        let corrupt = #"{"schemaVersion":1,"deviceDayKey":"2026-08-21","todayCompletedCount":1,"currentStreakDays":1,"nextReminderAt":"2026-08-21T09:00:00Z","nextReminderSlotKey":null,"pipStaticState":"idle","updatedAt":"2026-08-21T00:00:00Z"}"#
        try Data(corrupt.utf8).write(to: url)

        XCTAssertEqual(
            PipWidgetSnapshotReader(store: PipSnapshotStore(fileURL: url)).read(),
            .empty(.corrupt)
        )
    }

    private func temporaryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("pip-widget-\(UUID().uuidString).json")
    }
}
