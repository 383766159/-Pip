import SwiftUI

struct PipCharacterView: View {
    let stage: PipStage
    let homeState: HomeState
    let isPaused: Bool
    let reduceMotion: Bool
    let phaseStartedAt: Date
    let phaseDuration: Int
    let elapsedSecondsInPhase: Int
    let size: CGFloat

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: reduceMotion ? 1 : 1.0 / 120.0,
                paused: reduceMotion || (isPaused && homeState == .session)
            )
        ) { context in
            let progress = visualProgress(at: context.date)
            let pose = PipMascotMotion.pose(
                stage: stage,
                homeState: homeState,
                progress: progress,
                time: context.date.timeIntervalSinceReferenceDate,
                reduceMotion: reduceMotion
            )

            PipMascotCanvas(pose: pose, size: size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func visualProgress(at date: Date) -> Double {
        let duration = max(Double(phaseDuration), 0.001)
        if isPaused || reduceMotion || homeState != .session {
            return min(1, Double(elapsedSecondsInPhase) / duration)
        }

        return min(max(date.timeIntervalSince(phaseStartedAt) / duration, 0), 1)
    }
}
