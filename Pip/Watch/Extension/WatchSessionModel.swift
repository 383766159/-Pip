import Foundation
import SwiftUI
import WatchKit

public enum WatchSessionStatus: Equatable, Sendable {
    case idle
    case running
    case paused
    case done
}

@MainActor
public final class WatchSessionModel: ObservableObject {
    @Published public private(set) var status: WatchSessionStatus = .idle
    @Published public private(set) var phase: SessionPhase = .idle
    @Published public private(set) var remainingSeconds = SessionConfiguration().totalDuration
    @Published public private(set) var elapsedSecondsInPhase = 0
    @Published public private(set) var currentRepetition = 0
    @Published public private(set) var phaseStartedAt = Date()

    public private(set) var engine = SessionEngine()

    private let hapticsEnabled: () -> Bool
    private var clockTask: Task<Void, Never>?

    public init(hapticsEnabled: @escaping () -> Bool = { true }) {
        self.hapticsEnabled = hapticsEnabled
    }

    public var progress: Double {
        min(1, max(0, Double(engine.activeSeconds) / Double(engine.configuration.totalDuration)))
    }

    public var phaseDuration: Int {
        switch phase {
        case .lift:
            return engine.configuration.liftDuration
        case .release:
            return engine.configuration.releaseDuration
        case .idle, .paused, .completed, .cancelled:
            return 1
        }
    }

    public func start() {
        guard status == .idle || status == .done else { return }
        stopClock()
        engine = SessionEngine()
        status = .running
        phaseStartedAt = Date()
        handle(engine.start())
        sync()
        startClock()
    }

    public func pause() {
        guard status == .running else { return }
        _ = engine.pause()
        status = .paused
        sync()
    }

    public func resume() {
        guard status == .paused else { return }
        _ = engine.resume()
        status = .running
        phaseStartedAt = Date()
        sync()
    }

    public func cancel() {
        guard status == .running || status == .paused else { return }
        _ = engine.cancel()
        stopClock()
        status = .idle
        sync()
        remainingSeconds = engine.configuration.totalDuration
    }

    public func advance(by seconds: Int) {
        guard status == .running, seconds > 0 else { return }
        let previousPhase = phase
        handle(engine.advance(by: seconds))
        sync()
        if phaseBoundaryChanged(from: previousPhase, to: phase) {
            phaseStartedAt = Date()
        }
    }

    public func startClock() {
        guard clockTask == nil else { return }
        clockTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                self?.advance(by: 1)
            }
        }
    }

    public func stopClock() {
        clockTask?.cancel()
        clockTask = nil
    }

    private func handle(_ events: [SessionEngine.Event]) {
        for event in events {
            switch event {
            case let .haptic(haptic):
                play(haptic)
            case .completed:
                status = .done
                stopClock()
            }
        }
    }

    private func sync() {
        phase = engine.phase
        remainingSeconds = max(0, engine.configuration.totalDuration - engine.activeSeconds)
        elapsedSecondsInPhase = engine.elapsedSecondsInPhase
        currentRepetition = engine.currentRepetition
        if engine.phase == .completed {
            status = .done
            remainingSeconds = 0
        }
    }

    private func play(_ haptic: SessionHapticEvent) {
        guard hapticsEnabled() else { return }
        switch haptic {
        case .lift, .release:
            WKInterfaceDevice.current().play(.click)
        case .success:
            WKInterfaceDevice.current().play(.success)
        }
    }

    private func phaseBoundaryChanged(from oldPhase: SessionPhase, to newPhase: SessionPhase) -> Bool {
        switch (oldPhase, newPhase) {
        case (.lift, .release), (.release, .lift):
            return true
        default:
            return false
        }
    }
}
