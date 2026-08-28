import SwiftUI

struct PipWatchRootView: View {
    @StateObject private var session = WatchSessionModel()
    @State private var snapshot: PipSnapshot?
    @Environment(\.colorScheme) private var colorScheme

    private let snapshotReader = WatchSurfaceSnapshotReader()

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                HStack {
                    Text("Pip")
                        .font(.headline)
                        .foregroundStyle(PipTheme.ink(for: colorScheme))
                    Spacer(minLength: 4)
                    Text("Today \(snapshot?.todayCompletedCount ?? 0)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 6) {
                    PipWatchCharacterView(
                        status: session.status,
                        phase: session.phase,
                        phaseStartedAt: session.phaseStartedAt,
                        elapsedSecondsInPhase: session.elapsedSecondsInPhase,
                        phaseDuration: session.phaseDuration,
                        size: 82
                    )
                    .frame(width: 82, height: 82)

                    ProgressView(value: session.progress)
                        .progressViewStyle(.circular)
                        .tint(PipTheme.mint)
                        .frame(width: 58, height: 58)
                        .overlay {
                            Text("\(session.remainingSeconds)s")
                                .font(.caption2.monospacedDigit())
                        }
                        .accessibilityLabel("Session progress")
                        .accessibilityValue("\(session.remainingSeconds) seconds remaining")
                }

                Text(statusTitle)
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, minHeight: 18)

                if session.status == .running || session.status == .paused {
                    HStack(spacing: 6) {
                        primaryActionButton
                        cancelButton
                    }
                } else {
                    primaryActionButton
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .tint(PipTheme.mint)
        .task {
            snapshot = snapshotReader.read()
            session.startClock()
        }
        .onDisappear {
            session.stopClock()
        }
    }

    private var statusTitle: String {
        switch session.status {
        case .idle: return "Ready"
        case .running: return phaseTitle
        case .paused: return "Paused"
        case .done: return "Session complete"
        }
    }

    private var phaseTitle: String {
        switch session.phase {
        case .lift: return "Lift"
        case .release: return "Release"
        case .paused: return "Paused"
        case .completed: return "Complete"
        case .cancelled, .idle: return "Ready"
        }
    }

    private var primaryActionTitle: String {
        switch session.status {
        case .idle, .done: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        }
    }

    private var primaryActionIcon: String {
        switch session.status {
        case .running: return "pause.fill"
        case .paused, .idle, .done: return "play.fill"
        }
    }

    private func primaryAction() {
        switch session.status {
        case .idle, .done: session.start()
        case .running: session.pause()
        case .paused: session.resume()
        }
    }

    private var primaryActionButton: some View {
        Button(action: primaryAction) {
            actionLabel(title: primaryActionTitle, systemImage: primaryActionIcon)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
        .accessibilityLabel(primaryActionTitle)
    }

    private var cancelButton: some View {
        Button {
            session.cancel()
        } label: {
            actionLabel(title: "Cancel", systemImage: "xmark")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.red)
        .controlSize(.small)
        .frame(maxWidth: .infinity, minHeight: 34, maxHeight: 34)
        .accessibilityLabel("Cancel session")
    }

    private func actionLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: systemImage)
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .allowsTightening(true)
        }
        .font(.caption.weight(.semibold))
        .lineLimit(1)
    }
}

@main
struct PipWatchExtension: App {
    var body: some Scene {
        WindowGroup {
            PipWatchRootView()
        }
    }
}
