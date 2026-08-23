import Foundation
import SwiftData
import XCTest
@testable import Pip

@MainActor
final class PipPersistenceTests: XCTestCase {
    func testLocalStoreAcceptsInMemoryContainerInjection() throws {
        let store = try LocalStore.makeInMemoryForTesting()
        let slot = ReminderSlot(
            slotKey: "morning",
            hour: 9,
            minute: 0,
            weekdayMask: 0b0001_1111
        )

        store.context.insert(slot)
        try store.context.save()

        let descriptor = FetchDescriptor<ReminderSlot>()
        let slots = try store.context.fetch(descriptor)
        XCTAssertEqual(slots.map(\.slotKey), ["morning"])
    }

    func testSnapshotRoundTripUsesInjectedFileURL() throws {
        let fileURL = makeTemporarySnapshotURL()
        defer { try? FileManager.default.removeItem(at: fileURL) }

        let updatedAt = Date(timeIntervalSince1970: 1_750_000_000)
        let snapshot = try PipSnapshot(
            deviceDayKey: "2026-08-21",
            todayCompletedCount: 2,
            currentStreakDays: 4,
            nextReminderAt: updatedAt.addingTimeInterval(3600),
            nextReminderSlotKey: "afternoon",
            pipStaticState: .done,
            updatedAt: updatedAt
        )
        let store = PipSnapshotStore(fileURL: fileURL)

        try store.write(snapshot)

        XCTAssertEqual(store.read(), snapshot)
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }

    func testSnapshotRejectsIncompleteOrEmptyReminderPair() {
        let updatedAt = Date(timeIntervalSince1970: 1_750_000_000)
        let dayKey = PipDateKey.make(from: updatedAt)

        XCTAssertThrowsError(try PipSnapshot(
            deviceDayKey: dayKey,
            nextReminderAt: updatedAt,
            nextReminderSlotKey: nil
        ))
        XCTAssertThrowsError(try PipSnapshot(
            deviceDayKey: dayKey,
            nextReminderAt: nil,
            nextReminderSlotKey: "morning"
        ))
        XCTAssertThrowsError(try PipSnapshot(
            deviceDayKey: dayKey,
            nextReminderAt: nil,
            nextReminderSlotKey: ""
        ))
        XCTAssertThrowsError(try PipSnapshot(
            deviceDayKey: dayKey,
            nextReminderAt: updatedAt,
            nextReminderSlotKey: ""
        ))
    }

    func testCorruptSnapshotFallsBackToSafeEmptyState() throws {
        let fileURL = makeTemporarySnapshotURL()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        try Data("not-json".utf8).write(to: fileURL)

        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let snapshot = PipSnapshotStore(fileURL: fileURL).read(now: now)

        XCTAssertEqual(snapshot.todayCompletedCount, 0)
        XCTAssertEqual(snapshot.currentStreakDays, 0)
        XCTAssertNil(snapshot.nextReminderAt)
        XCTAssertNil(snapshot.nextReminderSlotKey)
        XCTAssertEqual(snapshot.pipStaticState, .idle)
        XCTAssertEqual(snapshot.deviceDayKey, PipDateKey.make(from: now))
    }

    func testUnknownSchemaAndNegativeCountsFallBackToSafeEmptyState() throws {
        let fileURL = makeTemporarySnapshotURL()
        defer { try? FileManager.default.removeItem(at: fileURL) }
        let store = PipSnapshotStore(fileURL: fileURL)
        let now = Date(timeIntervalSince1970: 1_750_000_000)

        let unknownVersion = #"{"schemaVersion":2,"deviceDayKey":"2026-08-21","todayCompletedCount":0,"currentStreakDays":0,"nextReminderAt":null,"nextReminderSlotKey":null,"pipStaticState":"idle","updatedAt":"2026-08-21T00:00:00Z"}"#
        try Data(unknownVersion.utf8).write(to: fileURL)
        XCTAssertEqual(store.read(now: now).schemaVersion, PipSnapshot.supportedSchemaVersion)
        XCTAssertEqual(store.read(now: now).todayCompletedCount, 0)

        let negativeCount = #"{"schemaVersion":1,"deviceDayKey":"2026-08-21","todayCompletedCount":-1,"currentStreakDays":0,"nextReminderAt":null,"nextReminderSlotKey":null,"pipStaticState":"idle","updatedAt":"2026-08-21T00:00:00Z"}"#
        try Data(negativeCount.utf8).write(to: fileURL)
        XCTAssertEqual(store.read(now: now).todayCompletedCount, 0)
    }

    func testInvalidSnapshotDateKeyIsRejected() {
        XCTAssertThrowsError(try PipSnapshot(deviceDayKey: "2026-02-30"))
        XCTAssertFalse(PipDateKey.isValid("2026-02-30"))
        XCTAssertTrue(PipDateKey.isValid("2026-08-21"))
    }

    func testDefaultSnapshotStoreDoesNotUsePrivateApplicationSupportFallback() {
        let store = PipSnapshotStore(fileManager: NoAppGroupFileManager())
        let now = Date(timeIntervalSince1970: 1_750_000_000)

        XCTAssertNil(store.fileURL)
        XCTAssertEqual(store.read(now: now), PipSnapshot.empty(now: now))
        XCTAssertThrowsError(try store.write(try! PipSnapshot(
            deviceDayKey: PipDateKey.make(from: now)
        ))) { error in
            XCTAssertEqual(error as? PipSnapshotStoreError, .unavailable)
        }
    }

    private func makeTemporarySnapshotURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PipPersistenceTests-\(UUID().uuidString)-\(PipSnapshotStore.fileName)")
    }
}

private final class NoAppGroupFileManager: FileManager {
    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        nil
    }
}
