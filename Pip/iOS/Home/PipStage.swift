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

    public var animationAssetNames: [String] {
        switch self {
        case .idle:
            return ["idle"]
        case .lift:
            return ["lift1", "lift2", "lift3", "lift4"]
        case .release:
            return ["release1", "release2", "release3"]
        case .done:
            return ["done"]
        }
    }

    public var frameCount: Int {
        animationAssetNames.count
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

    public var effortTitle: String {
        switch self {
        case .idle:
            return "Ready"
        case .lift:
            return "Squeeze"
        case .release:
            return "Release"
        case .done:
            return "Nice work"
        }
    }

    public var effortSubtitle: String {
        switch self {
        case .idle:
            return "A short guided kegel"
        case .lift:
            return "Lift and hold"
        case .release:
            return "Let it go"
        case .done:
            return "48 seconds complete"
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

    public func animationAsset(
        progress: Double,
        reduceMotion: Bool
    ) -> String {
        if reduceMotion {
            return assetName
        }

        let names = animationAssetNames
        guard names.count > 1 else {
            return names[0]
        }

        let clamped = min(max(progress, 0), 0.999)
        let index = min(names.count - 1, Int(clamped * Double(names.count)))
        return names[index]
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
