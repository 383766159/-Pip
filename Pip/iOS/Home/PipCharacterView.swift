import SwiftUI

struct PipCharacterView: View {
    let stage: PipStage
    let homeState: HomeState
    let isPaused: Bool
    let reduceMotion: Bool
    let phaseStartedAt: Date
    let phaseDuration: Int
    let elapsedSecondsInPhase: Int
    let remainingSeconds: Int
    let totalSessionSeconds: Int
    let sessionEntryPose: PipMobiusPose?
    let size: CGFloat
    let ringSize: CGFloat

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 60.0,
                paused: reduceMotion || (isPaused && homeState == .session)
            )
        ) { context in
            characterContent(at: context.date)
        }
        .frame(width: ringSize, height: ringSize)
        .accessibilityHidden(true)
    }

    private func characterContent(at date: Date) -> some View {
        let progress = visualProgress(at: date)
        let localTime = max(0, date.timeIntervalSince(phaseStartedAt))
        let targetPose = PipMobiusMotion.pose(
            stage: stage,
            homeState: homeState,
            progress: progress,
            time: localTime,
            reduceMotion: reduceMotion
        )
        let pose: PipMobiusPose
        if !reduceMotion,
           stage == .lift,
           homeState == .session,
           let sessionEntryPose {
            pose = sessionEntryPose.blended(
                to: targetPose,
                progress: localTime / 0.34
            )
        } else {
            pose = targetPose
        }

        return ZStack {
            if homeState == .session {
                PipSessionRing(
                    progress: sessionProgress(at: date),
                    isLift: stage == .lift
                )
                .frame(width: ringSize, height: ringSize)
            }

            PipMobiusSceneView(pose: pose, size: size)
                .frame(width: size, height: size)
        }
    }

    private func visualProgress(at date: Date) -> Double {
        let duration = max(Double(phaseDuration), 0.001)
        if isPaused || reduceMotion || homeState != .session {
            return min(1, Double(elapsedSecondsInPhase) / duration)
        }

        return min(max(date.timeIntervalSince(phaseStartedAt) / duration, 0), 1)
    }

    private func sessionProgress(at date: Date) -> Double {
        let duration = Double(max(totalSessionSeconds, 1))
        let remaining: Double

        if isPaused || reduceMotion {
            remaining = Double(remainingSeconds)
        } else {
            let fractionalElapsed = max(
                0,
                date.timeIntervalSince(phaseStartedAt) - Double(elapsedSecondsInPhase)
            )
            remaining = max(0, Double(remainingSeconds) - fractionalElapsed)
        }

        return min(max(1 - remaining / duration, 0), 1)
    }
}
