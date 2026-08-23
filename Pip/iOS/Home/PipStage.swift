import Foundation

public enum PipStage: String, CaseIterable, Sendable {
    case idle
    case lift
    case release
    case done

    public static let staticFrameAssetNames: [String] = [
        "idle", "idle",
        "lift", "lift", "lift",
        "release", "release", "release",
        "done", "done"
    ]

    public static var staticFrameCount: Int {
        staticFrameAssetNames.count
    }

    public var assetName: String {
        rawValue
    }

    public var frameCount: Int {
        switch self {
        case .idle, .done:
            return 2
        case .lift, .release:
            return 3
        }
    }

    public var accessibilityTitle: String {
        switch self {
        case .idle:
            return "Ready"
        case .lift:
            return "Lift"
        case .release:
            return "Release"
        case .done:
            return "Complete"
        }
    }

    public static func stage(for phase: SessionPhase) -> PipStage {
        switch phase {
        case .idle, .cancelled:
            return .idle
        case .lift:
            return .lift
        case .release:
            return .release
        case .paused:
            return .idle
        case .completed:
            return .done
        }
    }

    public func frameIndex(
        elapsedSecondsInPhase: Int,
        phaseDuration: Int,
        reduceMotion: Bool
    ) -> Int {
        guard !reduceMotion, frameCount > 1 else {
            return 0
        }

        let safeDuration = max(1, phaseDuration)
        let safeElapsed = max(0, min(elapsedSecondsInPhase, safeDuration - 1))
        let progress = Double(safeElapsed) / Double(safeDuration)
        return min(frameCount - 1, Int(progress * Double(frameCount)))
    }

    public func scale(for frameIndex: Int) -> CGFloat {
        switch self {
        case .idle:
            return [1.0, 1.02][min(max(frameIndex, 0), 1)]
        case .lift:
            return [1.0, 1.04, 1.08][min(max(frameIndex, 0), 2)]
        case .release:
            return [1.08, 1.04, 1.0][min(max(frameIndex, 0), 2)]
        case .done:
            return [1.0, 1.06][min(max(frameIndex, 0), 1)]
        }
    }
}
