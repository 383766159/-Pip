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
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 15.0, paused: reduceMotion || isPaused)) { context in
            let progress = visualProgress(at: context.date)
            let pulse = reduceMotion ? 0.0 : 0.5 + 0.5 * sin(context.date.timeIntervalSinceReferenceDate * 2.2)
            let asset = stage.animationAsset(progress: progress, reduceMotion: reduceMotion)

            ZStack {
                if homeState == .done && !reduceMotion {
                    PipSparkles(pulse: pulse)
                }

                Image(asset)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .id(asset)
                    .transition(.opacity)
                    .scaleEffect(idleScale(pulse: pulse))
                    .offset(x: liftShake(at: context.date), y: idleBob(pulse: pulse))
                    .animation(
                        reduceMotion ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.16),
                        value: asset
                    )

                if stage == .lift, homeState == .session, !reduceMotion {
                    PipSweatDrops(pulse: pulse)
                        .opacity(isPaused ? 0.35 : 1)
                }
            }
            .frame(width: size, height: size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func visualProgress(at date: Date) -> Double {
        let duration = max(Double(phaseDuration), 0.001)
        if isPaused || reduceMotion || homeState != .session {
            return min(1, Double(elapsedSecondsInPhase) / duration)
        }

        let elapsed = date.timeIntervalSince(phaseStartedAt)
        return min(max(elapsed / duration, 0), 0.999)
    }

    private func idleScale(pulse: Double) -> CGFloat {
        guard !reduceMotion, homeState == .idle || (homeState == .session && isPaused) else {
            return homeState == .done && !reduceMotion ? 1.04 : 1
        }
        return 1.0 + 0.028 * pulse
    }

    private func idleBob(pulse: Double) -> CGFloat {
        guard !reduceMotion, homeState == .idle else {
            return 0
        }
        return -4 * pulse
    }

    private func liftShake(at date: Date) -> CGFloat {
        guard !reduceMotion, !isPaused, stage == .lift, homeState == .session else {
            return 0
        }
        return CGFloat(sin(date.timeIntervalSinceReferenceDate * 18) * 1.6)
    }
}
