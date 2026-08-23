import XCTest
import SwiftData
@testable import Pip

@MainActor
final class HomeStateTests: XCTestCase {
    private var preferences: UserDefaults!
    private var preferenceSuiteName: String!

    override func setUp() {
        super.setUp()
        preferenceSuiteName = "Pip.HomeStateTests.\(UUID().uuidString)"
        preferences = UserDefaults(suiteName: preferenceSuiteName)
    }

    override func tearDown() {
        preferences.removePersistentDomain(forName: preferenceSuiteName)
        preferences = nil
        preferenceSuiteName = nil
        super.tearDown()
    }

    func testHomeStartsIdleAndReadsTodayCountWithoutComputingStreak() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore(
            snapshot: PipSnapshot(
                deviceDayKey: PipDateKey.make(from: now),
                todayCompletedCount: 2,
                currentStreakDays: 9
            )
        )

        let viewModel = makeViewModel(store: store, now: now)

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.stage, .idle)
        XCTAssertEqual(viewModel.todayCompletedCount, 2)
        XCTAssertTrue(viewModel.voiceOverLabel.contains("Today 2"))
        XCTAssertFalse(viewModel.voiceOverLabel.contains("streak"))
    }

    func testFirstStartOnlyPresentsShortExplanationThenStartsSession() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore()
        let viewModel = makeViewModel(store: store, now: now)

        viewModel.start()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.isExplanationPresented)
        XCTAssertEqual(viewModel.engine.phase, .idle)

        viewModel.confirmStartExplanation()
        XCTAssertFalse(viewModel.isExplanationPresented)
        XCTAssertEqual(viewModel.state, .session)
        XCTAssertEqual(viewModel.stage, .lift)
        XCTAssertEqual(viewModel.remainingSeconds, 48)

        viewModel.cancelSession()
        viewModel.start()
        XCTAssertFalse(viewModel.isExplanationPresented)
        XCTAssertEqual(viewModel.state, .session)
    }

    func testStartClockRunsAfterFirstExplanationConfirmation() async throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore()
        let viewModel = makeViewModel(store: store, now: now)

        viewModel.start()
        viewModel.confirmStartExplanation()

        XCTAssertEqual(viewModel.state, .session)
        XCTAssertEqual(viewModel.remainingSeconds, 48)

        try await Task.sleep(nanoseconds: 3_200_000_000)

        let remainingSeconds = viewModel.remainingSeconds
        viewModel.stopClock()
        XCTAssertLessThan(remainingSeconds, 48)
    }

    func testLeavingAnUnfinishedSessionPausesWithoutRefreshingCountOrSnapshot() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore(
            snapshot: PipSnapshot(
                deviceDayKey: PipDateKey.make(from: now),
                todayCompletedCount: 3,
                currentStreakDays: 4,
                pipStaticState: .idle
            )
        )
        let viewModel = makeViewModel(store: store, now: now)
        let before = store.read(now: now)

        viewModel.beginSession()
        viewModel.advance(by: 2)
        viewModel.pauseForLeaving()
        viewModel.advance(by: 20)

        XCTAssertEqual(viewModel.state, .session)
        XCTAssertTrue(viewModel.isPaused)
        XCTAssertEqual(viewModel.engine.activeSeconds, 2)
        XCTAssertEqual(viewModel.todayCompletedCount, 3)
        XCTAssertEqual(store.read(now: now), before)
    }

    func testOnlyCompleteSessionTransitionsToDoneAndRefreshesCountAndSnapshot() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore(
            snapshot: PipSnapshot(
                deviceDayKey: PipDateKey.make(from: now),
                todayCompletedCount: 1,
                currentStreakDays: 6
            )
        )
        let viewModel = makeViewModel(store: store, now: now)

        viewModel.beginSession()
        viewModel.advance(by: 47)

        XCTAssertEqual(viewModel.state, .session)
        XCTAssertEqual(viewModel.todayCompletedCount, 1)
        XCTAssertEqual(store.read(now: now).todayCompletedCount, 1)

        viewModel.advance(by: 1)

        let snapshot = store.read(now: now)
        XCTAssertEqual(viewModel.state, .done)
        XCTAssertEqual(viewModel.stage, .done)
        XCTAssertEqual(viewModel.todayCompletedCount, 2)
        XCTAssertEqual(snapshot.todayCompletedCount, 2)
        XCTAssertEqual(snapshot.currentStreakDays, 6)
        XCTAssertEqual(snapshot.pipStaticState, .done)
        XCTAssertTrue(viewModel.hapticEvents.contains(.light))
        XCTAssertTrue(viewModel.hapticEvents.contains(.success))
    }

    func testCompletionRebuildsCalendarStatsAndSingletonStreak() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let snapshotStore = try makeStore()
        let localStore = try LocalStore.makeInMemoryForTesting()
        localStore.context.insert(CalendarDayStat(
            dayKey: "2026-08-19",
            completedSessionCount: 4,
            streakLengthEndingOnDay: 4
        ))
        try localStore.context.save()

        let viewModel = makeViewModel(
            store: snapshotStore,
            now: now,
            modelContext: localStore.context
        )
        viewModel.beginSession()
        viewModel.advance(by: 48)

        let stats = try localStore.context.fetch(FetchDescriptor<CalendarDayStat>())
        XCTAssertEqual(stats.map(\.dayKey), [PipDateKey.make(from: now)])
        XCTAssertEqual(stats.first?.completedSessionCount, 1)
        XCTAssertEqual(stats.first?.streakLengthEndingOnDay, 1)

        let streakStates = try localStore.context.fetch(FetchDescriptor<StreakState>())
        XCTAssertEqual(streakStates.count, 1)
        XCTAssertEqual(streakStates.first?.id, "singleton")
        XCTAssertEqual(streakStates.first?.currentStreakDays, 1)
        XCTAssertEqual(streakStates.first?.lastCompletedDayKey, PipDateKey.make(from: now))
    }

    func testCancelDoesNotRefreshCountOrSnapshot() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore(
            snapshot: PipSnapshot(
                deviceDayKey: PipDateKey.make(from: now),
                todayCompletedCount: 4,
                currentStreakDays: 3
            )
        )
        let viewModel = makeViewModel(store: store, now: now)

        viewModel.beginSession()
        viewModel.advance(by: 6)
        viewModel.cancelSession()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.todayCompletedCount, 4)
        XCTAssertEqual(store.read(now: now).todayCompletedCount, 4)
        XCTAssertEqual(store.read(now: now).currentStreakDays, 3)
    }

    func testVoiceOverIncludesStageRemainingTimeAndAvailableAction() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore()
        let viewModel = makeViewModel(store: store, now: now)

        viewModel.beginSession()
        XCTAssertTrue(viewModel.voiceOverLabel.contains("Lift"))
        XCTAssertTrue(viewModel.voiceOverLabel.contains("48 seconds"))
        XCTAssertTrue(viewModel.voiceOverHint.contains("Pause"))

        viewModel.advance(by: 2)
        viewModel.pauseSession()

        XCTAssertTrue(viewModel.voiceOverLabel.contains("46 seconds"))
        XCTAssertTrue(viewModel.voiceOverLabel.contains("Paused"))
        XCTAssertTrue(viewModel.voiceOverHint.contains("Resume"))
    }

    func testReduceMotionUsesFadePathWithTenStaticFramesAndKeepsHaptics() throws {
        let now = Date(timeIntervalSince1970: 1_750_000_000)
        let store = try makeStore()
        let viewModel = makeViewModel(store: store, now: now)

        XCTAssertEqual(PipStage.staticFrameCount, 10)
        XCTAssertEqual(viewModel.frameIndex(reduceMotion: true), 0)
        XCTAssertEqual(PipStage.lift.animationAssetNames.count, 4)
        XCTAssertEqual(PipStage.release.animationAssetNames.count, 3)
        XCTAssertEqual(PipStage.lift.animationAsset(progress: 0, reduceMotion: true), "lift")
        XCTAssertEqual(PipStage.lift.animationAsset(progress: 0.99, reduceMotion: false), "lift4")

        viewModel.beginSession()
        viewModel.advance(by: 3)

        XCTAssertEqual(viewModel.stage, .release)
        XCTAssertEqual(viewModel.frameIndex(reduceMotion: true), 0)
        XCTAssertTrue(viewModel.hapticEvents.contains(.light))
    }

    private func makeViewModel(
        store: PipSnapshotStore,
        now: Date,
        modelContext: ModelContext? = nil
    ) -> HomeViewModel {
        HomeViewModel(
            snapshotStore: store,
            modelContext: modelContext,
            now: { now },
            preferences: preferences,
            hapticHandler: { _ in }
        )
    }

    private func makeStore(
        snapshot: PipSnapshot? = nil
    ) throws -> PipSnapshotStore {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PipHomeStateTests-\(UUID().uuidString)-\(PipSnapshotStore.fileName)")
        let store = PipSnapshotStore(fileURL: fileURL)
        if let snapshot {
            try store.write(snapshot)
        }
        addTeardownBlock {
            try? FileManager.default.removeItem(at: fileURL)
        }
        return store
    }
}
