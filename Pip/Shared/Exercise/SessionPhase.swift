import Foundation

public enum SessionPhase: Equatable, Sendable {
    case idle
    case lift(repetition: Int)
    case release(repetition: Int)
    case paused
    case completed
    case cancelled

    public var isActive: Bool {
        switch self {
        case .lift, .release:
            return true
        case .idle, .paused, .completed, .cancelled:
            return false
        }
    }
}

public enum SessionHapticEvent: Equatable, Sendable {
    case lift
    case release
    case success
}
