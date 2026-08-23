import Foundation

public struct SessionEngine: Sendable {
    public enum Event: Equatable, Sendable {
        case haptic(SessionHapticEvent)
        case completed
    }

    public let configuration: SessionConfiguration

    public private(set) var phase: SessionPhase = .idle
    public private(set) var currentRepetition = 0
    public private(set) var completedRepetitions = 0
    public private(set) var activeSeconds = 0
    public private(set) var elapsedSecondsInPhase = 0

    private enum ActivePhase: Equatable, Sendable {
        case lift
        case release
    }

    private var activePhase: ActivePhase?
    private var pausedPhase: ActivePhase?

    public init() {
        configuration = SessionConfiguration()
    }

    public var isCompleted: Bool {
        phase == .completed
    }

    @discardableResult
    public mutating func start() -> [Event] {
        guard phase == .idle else {
            return []
        }

        currentRepetition = 1
        completedRepetitions = 0
        activeSeconds = 0
        elapsedSecondsInPhase = 0
        activePhase = .lift
        pausedPhase = nil
        phase = .lift(repetition: currentRepetition)

        return [.haptic(.lift)]
    }

    @discardableResult
    public mutating func advance(by seconds: Int = 1) -> [Event] {
        guard seconds > 0, phase.isActive else {
            return []
        }

        var remainingSeconds = seconds
        var events: [Event] = []

        while remainingSeconds > 0, let currentActivePhase = activePhase {
            let phaseDuration: Int
            switch currentActivePhase {
            case .lift:
                phaseDuration = configuration.liftDuration
            case .release:
                phaseDuration = configuration.releaseDuration
            }

            let secondsUntilBoundary = phaseDuration - elapsedSecondsInPhase
            let secondsToAdvance = min(remainingSeconds, secondsUntilBoundary)
            elapsedSecondsInPhase += secondsToAdvance
            activeSeconds += secondsToAdvance
            remainingSeconds -= secondsToAdvance

            guard elapsedSecondsInPhase == phaseDuration else {
                continue
            }

            switch currentActivePhase {
            case .lift:
                activePhase = .release
                elapsedSecondsInPhase = 0
                phase = .release(repetition: currentRepetition)
                events.append(.haptic(.release))

            case .release:
                completedRepetitions += 1

                if completedRepetitions == configuration.repetitionCount {
                    events.append(contentsOf: complete())
                } else {
                    currentRepetition += 1
                    activePhase = .lift
                    elapsedSecondsInPhase = 0
                    phase = .lift(repetition: currentRepetition)
                    events.append(.haptic(.lift))
                }
            }
        }

        return events
    }

    @discardableResult
    public mutating func pause() -> [Event] {
        guard phase.isActive, let activePhase else {
            return []
        }

        pausedPhase = activePhase
        self.activePhase = nil
        phase = .paused
        return []
    }

    @discardableResult
    public mutating func resume() -> [Event] {
        guard phase == .paused, let pausedPhase else {
            return []
        }

        activePhase = pausedPhase
        self.pausedPhase = nil
        phase = makePhase(for: pausedPhase)
        return []
    }

    @discardableResult
    public mutating func cancel() -> [Event] {
        guard phase.isActive || phase == .paused else {
            return []
        }

        activePhase = nil
        pausedPhase = nil
        phase = .cancelled
        return []
    }

    @discardableResult
    public mutating func complete() -> [Event] {
        guard phase != .completed,
              completedRepetitions == configuration.repetitionCount,
              activeSeconds == configuration.totalDuration else {
            return []
        }

        activePhase = nil
        pausedPhase = nil
        phase = .completed
        return [.haptic(.success), .completed]
    }

    private func makePhase(for activePhase: ActivePhase) -> SessionPhase {
        switch activePhase {
        case .lift:
            return .lift(repetition: currentRepetition)
        case .release:
            return .release(repetition: currentRepetition)
        }
    }
}
