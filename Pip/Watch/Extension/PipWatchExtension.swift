import SwiftUI

struct PipWatchRootView: View {
    @StateObject private var session = WatchSessionModel()
    @State private var snapshot: PipSnapshot?

    private let snapshotReader = WatchSurfaceSnapshotReader()

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Pip")
                    .font(.headline)
                    .foregroundStyle(PipTheme.ink)

                if let snapshot {
                    Text("Today \(snapshot.todayCompletedCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Snapshot unavailable")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                ProgressView(value: session.progress)
                    .progressViewStyle(.circular)
                    .tint(PipTheme.mint)
                    .frame(width: 88, height: 88)
                    .overlay {
                        Text("\(session.remainingSeconds)s")
                            .font(.caption2.monospacedDigit())
                    }
                    .accessibilityLabel("Session progress")
                    .accessibilityValue("\(session.remainingSeconds) seconds remaining")

                Text(statusTitle)
                    .font(.caption)
                    .multilineTextAlignment(.center)

                Button(action: primaryAction) {
                    Label(primaryActionTitle, systemImage: primaryActionIcon)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(primaryActionTitle)

                if session.status == .running || session.status == .paused {
                    Button("Cancel", role: .destructive) {
                        session.cancel()
                    }
                    .accessibilityLabel("Cancel session")
                }
            }
            .padding()
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
        case .idle: return "Ready for an independent 48-second session"
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
}

@main
struct PipWatchExtension: App {
    var body: some Scene {
        WindowGroup {
            PipWatchRootView()
        }
    }
}
