import Foundation
import UIKit
import SwiftData
import SwiftUI

public enum HomeHaptic: Equatable, Sendable {
    case light
    case success
}

public typealias HomeHapticHandler = @MainActor (HomeHaptic) -> Void

@MainActor
public final class HomeViewModel: ObservableObject {
    public static let hasShownStartExplanationKey = "Pip.Home.hasShownStartExplanation"

    @Published public private(set) var state: HomeState = .idle
    @Published public private(set) var stage: PipStage = .idle
    @Published public private(set) var phase: SessionPhase = .idle
    @Published public private(set) var todayCompletedCount: Int
    @Published public private(set) var remainingSeconds: Int
    @Published public private(set) var currentRepetition = 0
    @Published public private(set) var elapsedSecondsInPhase = 0
    @Published public private(set) var isPaused = false
    @Published public var isExplanationPresented = false
    @Published public private(set) var accessibilityAnnouncement = ""
    @Published public private(set) var snapshotWriteErrorMessage: String?
    @Published public private(set) var phaseStartedAt: Date

    public private(set) var engine: SessionEngine
    public private(set) var hapticEvents: [HomeHaptic] = []

    private let snapshotStore: PipSnapshotStore
    private let modelContext: ModelContext?
    private let now: () -> Date
    private let preferences: UserDefaults
    private let hapticHandler: HomeHapticHandler
    private var clockTask: Task<Void, Never>?
    private var didRecordCompletion = false
    private var sessionStartedAt: Date?

    public init(
        snapshotStore: PipSnapshotStore = PipSnapshotStore(),
        modelContext: ModelContext? = nil,
        now: @escaping () -> Date = { Date() },
        preferences: UserDefaults = .standard,
        hapticHandler: HomeHapticHandler? = nil
    ) {
        self.snapshotStore = snapshotStore
        self.modelContext = modelContext
        self.now = now
        self.preferences = preferences
        self.hapticHandler = hapticHandler ?? Self.performDefaultHaptic
        self.engine = SessionEngine()

        let currentDate = now()
        let snapshot = snapshotStore.read(now: currentDate)
        let currentDayKey = PipDateKey.make(from: currentDate)
        self.todayCompletedCount = snapshot.deviceDayKey == currentDayKey
            ? snapshot.todayCompletedCount
            : 0
        self.remainingSeconds = engine.configuration.totalDuration
        self.phaseStartedAt = currentDate
    }

    public var totalSessionSeconds: Int {
        engine.configuration.totalDuration
    }

    public var isSessionActive: Bool {
        state == .session && !isPaused
    }

    public var phaseDuration: Int {
        switch stage {
        case .lift:
            return engine.configuration.liftDuration
        case .release:
            return engine.configuration.releaseDuration
        case .idle, .done:
            return 1
        }
    }

    public var voiceOverLabel: String {
        switch state {
        case .idle:
            return "Pip. Today \(todayCompletedCount) completed sessions. Ready to start."
        case .session:
            let pauseState = isPaused ? "Paused." : "In progress."
            return "\(stage.accessibilityTitle). \(remainingSeconds) seconds remaining. \(pauseState)"
        case .done:
            return "Session complete. Today \(todayCompletedCount) completed sessions."
        }
    }

    public var voiceOverHint: String {
        switch state {
        case .idle:
            return "Start button available. Calendar opens a page. Settings opens a sheet."
        case .session:
            return isPaused
                ? "Resume or cancel the session."
                : "Pause or cancel the session."
        case .done:
            return "Start again when you are ready."
        }
    }

    public var primaryActionTitle: String {
        switch state {
        case .idle:
            return "Start"
        case .session:
            return isPaused ? "Resume" : "Pause"
        case .done:
            return "Start again"
        }
    }

    public func frameIndex(reduceMotion: Bool) -> Int {
        stage.frameIndex(
            elapsedSecondsInPhase: elapsedSecondsInPhase,
            phaseDuration: phaseDuration,
            reduceMotion: reduceMotion
        )
    }

    public func visualProgress(at date: Date) -> Double {
        let duration = max(Double(phaseDuration), 0.001)
        if isPaused || state != .session {
            return min(1, Double(elapsedSecondsInPhase) / duration)
        }
        return min(max(date.timeIntervalSince(phaseStartedAt) / duration, 0), 1)
    }

    public func visualRemainingSeconds(at date: Date) -> Double {
        guard state == .session else {
            return Double(remainingSeconds)
        }
        if isPaused {
            return Double(remainingSeconds)
        }
        let extra = date.timeIntervalSince(phaseStartedAt) - Double(elapsedSecondsInPhase)
        return max(0, Double(remainingSeconds) - extra)
    }

    public func start() {
        guard state == .idle || state == .done else {
            return
        }

        if !preferences.bool(forKey: Self.hasShownStartExplanationKey) {
            preferences.set(true, forKey: Self.hasShownStartExplanationKey)
            isExplanationPresented = true
            accessibilityAnnouncement = "Before starting, follow Pip's lift and release rhythm."
            return
        }

        beginSession()
    }

    public func requestStart() {
        start()
    }

    public func confirmStartExplanation() {
        guard isExplanationPresented else {
            return
        }

        isExplanationPresented = false
        beginSession()
    }

    public func dismissStartExplanation() {
        isExplanationPresented = false
    }

    public func beginSession() {
        guard state == .idle || state == .done else {
            return
        }

        stopClock()
        engine = SessionEngine()
        sessionStartedAt = now()
        hapticEvents.removeAll()
        snapshotWriteErrorMessage = nil
        didRecordCompletion = false
        state = .session
        isPaused = false

        let events = engine.start()
        phaseStartedAt = now()
        syncPresentationFromEngine()
        handle(events)
        startClock()
    }

    public func pauseSession() {
        guard state == .session, engine.phase.isActive else {
            return
        }

        _ = engine.pause()
        isPaused = true
        syncPresentationFromEngine()
        accessibilityAnnouncement = "Paused. \(remainingSeconds) seconds remaining."
    }

    public func pauseForLeaving() {
        pauseSession()
    }

    public func resumeSession() {
        guard state == .session, engine.phase == .paused else {
            return
        }

        _ = engine.resume()
        isPaused = false
        phaseStartedAt = now().addingTimeInterval(-TimeInterval(elapsedSecondsInPhase))
        syncPresentationFromEngine()
        accessibilityAnnouncement = "Resumed. \(stage.accessibilityTitle). \(remainingSeconds) seconds remaining."
    }

    public func cancelSession() {
        guard state == .session else {
            return
        }

        _ = engine.cancel()
        stopClock()
        state = .idle
        stage = .idle
        phase = engine.phase
        isPaused = false
        currentRepetition = 0
        elapsedSecondsInPhase = 0
        remainingSeconds = totalSessionSeconds
        sessionStartedAt = nil
        phaseStartedAt = now()
        accessibilityAnnouncement = "Session cancelled. Ready to start."
    }

    public func tick() {
        advance(by: 1)
    }

    public func advance(by seconds: Int) {
        guard state == .session, !isPaused, seconds > 0 else {
            return
        }

        let events = engine.advance(by: seconds)
        handle(events)
        syncPresentationFromEngine()
    }

    public func startClock() {
        guard clockTask == nil else {
            return
        }

        clockTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }

                guard !Task.isCancelled else {
                    return
                }
                self?.tick()
            }
        }
    }

    public func stopClock() {
        clockTask?.cancel()
        clockTask = nil
    }

    private func syncPresentationFromEngine() {
        let previousStage = stage
        phase = engine.phase
        currentRepetition = engine.currentRepetition
        elapsedSecondsInPhase = engine.elapsedSecondsInPhase
        remainingSeconds = max(0, totalSessionSeconds - engine.activeSeconds)

        switch engine.phase {
        case .idle:
            stage = .idle
        case .lift:
            stage = .lift
        case .release:
            stage = .release
        case .paused:
            break
        case .completed:
            state = .done
            stage = .done
            isPaused = false
            remainingSeconds = 0
        case .cancelled:
            stage = .idle
        }

        if stage != previousStage {
            phaseStartedAt = now()
        }

        if state == .session, stage != previousStage {
            accessibilityAnnouncement = "\(stage.accessibilityTitle). \(remainingSeconds) seconds remaining."
        }
    }

    private func handle(_ events: [SessionEngine.Event]) {
        for event in events {
            switch event {
            case let .haptic(event):
                switch event {
                case .lift, .release:
                    emit(.light)
                case .success:
                    emit(.success)
                }
            case .completed:
                finishSession()
            }
        }
    }

    private func finishSession() {
        guard !didRecordCompletion else {
            return
        }

        didRecordCompletion = true
        stopClock()

        let completionDate = now()
        let dayKey = PipDateKey.make(from: completionDate)
        let storedSnapshot = snapshotStore.read(now: completionDate)

        if let modelContext {
            guard let sessionStartedAt else {
                snapshotWriteErrorMessage = "The completed session had no start time and was not saved."
                self.sessionStartedAt = nil
                return
            }

            let record = SessionRecord(
                status: .completed,
                startedAt: sessionStartedAt,
                completedAt: completionDate,
                startDayKey: PipDateKey.make(from: sessionStartedAt),
                completionDayKey: dayKey,
                completedCycles: engine.completedRepetitions,
                activeSeconds: engine.activeSeconds
            )

            guard record.satisfiesCompletionInvariant else {
                snapshotWriteErrorMessage = "The completed session did not satisfy Pip's 48-second completion contract."
                state = .idle
                stage = .idle
                isPaused = false
                remainingSeconds = totalSessionSeconds
                self.sessionStartedAt = nil
                return
            }

            modelContext.insert(record)
            do {
                try modelContext.save()
            } catch {
                snapshotWriteErrorMessage = String(describing: error)
                modelContext.delete(record)
                state = .idle
                stage = .idle
                isPaused = false
                remainingSeconds = totalSessionSeconds
                self.sessionStartedAt = nil
                accessibilityAnnouncement = "Session could not be saved. Please try again."
                return
            }

            let fallbackCount = storedSnapshot.deviceDayKey == dayKey
                ? storedSnapshot.todayCompletedCount + 1
                : 1
            var count = fallbackCount
            var currentStreakDays = storedSnapshot.currentStreakDays
            do {
                let summary = try LocalStatsRebuilder().rebuild(
                    context: modelContext,
                    timeZone: .current,
                    now: completionDate
                )
                count = summary.countsByDayKey[dayKey] ?? fallbackCount
                currentStreakDays = summary.currentStreakDays
            } catch {
                snapshotWriteErrorMessage = String(describing: error)
            }
            finishPresentation(count: count)
            writeSnapshot(
                dayKey: dayKey,
                count: count,
                currentStreakDays: currentStreakDays,
                storedSnapshot: storedSnapshot,
                completionDate: completionDate
            )
        } else {
            #if DEBUG
            // Snapshot-only completion is retained for deterministic unit tests.
            let count = storedSnapshot.deviceDayKey == dayKey
                ? storedSnapshot.todayCompletedCount + 1
                : 1
            finishPresentation(count: count)
            writeSnapshot(
                dayKey: dayKey,
                count: count,
                currentStreakDays: storedSnapshot.currentStreakDays,
                storedSnapshot: storedSnapshot,
                completionDate: completionDate
            )
            #else
            state = .idle
            stage = .idle
            isPaused = false
            remainingSeconds = totalSessionSeconds
            snapshotWriteErrorMessage = "Pip could not save the completed session locally."
            sessionStartedAt = nil
            return
            #endif
        }

        self.sessionStartedAt = nil

        NotificationCenter.default.post(name: .pipSessionCompleted, object: nil)
    }

    private func finishPresentation(count: Int) {
        state = .done
        stage = .done
        phase = .completed
        isPaused = false
        remainingSeconds = 0
        todayCompletedCount = count
        accessibilityAnnouncement = "Session complete. Today count is \(count)."
    }

    private func writeSnapshot(
        dayKey: String,
        count: Int,
        currentStreakDays: Int,
        storedSnapshot: PipSnapshot,
        completionDate: Date
    ) {
        do {
            let snapshot = try PipSnapshot(
                deviceDayKey: dayKey,
                todayCompletedCount: count,
                currentStreakDays: currentStreakDays,
                nextReminderAt: storedSnapshot.nextReminderAt,
                nextReminderSlotKey: storedSnapshot.nextReminderSlotKey,
                pipStaticState: .done,
                updatedAt: completionDate
            )
            try snapshotStore.write(snapshot)
        } catch {
            snapshotWriteErrorMessage = String(describing: error)
        }
    }

    private func emit(_ haptic: HomeHaptic) {
        hapticEvents.append(haptic)
        guard PipPreferences.hapticsEnabled(in: preferences) else {
            return
        }
        hapticHandler(haptic)
    }

    private static func performDefaultHaptic(_ haptic: HomeHaptic) {
        switch haptic {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        }
    }
}
