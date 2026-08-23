import SwiftUI
import SwiftData
import UIKit

@MainActor
public struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isCalendarPresented = false
    @State private var isSettingsPresented = false

    public init(snapshotStore: PipSnapshotStore) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(snapshotStore: snapshotStore))
    }

    public init(snapshotStore: PipSnapshotStore, modelContext: ModelContext) {
        _viewModel = StateObject(
            wrappedValue: HomeViewModel(snapshotStore: snapshotStore, modelContext: modelContext)
        )
    }

    public init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let layout = HomeLayout(for: proxy.size)

                ZStack {
                    PipBackdrop(colorScheme: colorScheme)

                    VStack(spacing: 0) {
                        header
                            .padding(.horizontal, 20)
                            .frame(height: layout.headerHeight)

                        characterStage(size: layout.pipSize)
                            .frame(height: layout.stageHeight)
                            .frame(maxWidth: .infinity)

                        statusBlock
                            .padding(.horizontal, 24)
                            .padding(.top, 2)

                        chipRow
                            .padding(.horizontal, 24)
                            .padding(.top, 10)

                        Spacer(minLength: 8)

                        controls
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                            .padding(.bottom, 10)
                    }
                    .frame(maxWidth: 430)
                    .frame(maxWidth: .infinity)
                }
            }
            .tint(PipTheme.mintDeep)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $isCalendarPresented) {
                CalendarView()
            }
        }
        .sheet(isPresented: explanationBinding) {
            StartExplanationSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView()
        }
        .task {
            viewModel.startClock()
        }
        .onDisappear {
            viewModel.pauseForLeaving()
            viewModel.stopClock()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase != .active else {
                return
            }
            viewModel.pauseForLeaving()
        }
        .onChange(of: viewModel.accessibilityAnnouncement) { _, announcement in
            guard !announcement.isEmpty else {
                return
            }
            UIAccessibility.post(notification: .announcement, argument: announcement)
        }
    }

    private var explanationBinding: Binding<Bool> {
        Binding(
            get: { viewModel.isExplanationPresented },
            set: { viewModel.isExplanationPresented = $0 }
        )
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Pip")
                .font(.title2.weight(.bold))
                .foregroundStyle(PipTheme.ink(for: colorScheme))

            Spacer()

            PipHeaderButton(systemName: "calendar") {
                viewModel.pauseForLeaving()
                isCalendarPresented = true
            }
            .accessibilityLabel("Calendar")
            .accessibilityHint("Opens the calendar page.")

            PipHeaderButton(systemName: "gearshape") {
                viewModel.pauseForLeaving()
                isSettingsPresented = true
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings in a sheet.")
        }
    }

    private func characterStage(size: CGFloat) -> some View {
        let ringSize = size + 36

        return ZStack {
            Circle()
                .fill(PipTheme.mint.opacity(colorScheme == .dark ? 0.10 : 0.16))
                .frame(width: ringSize + 28, height: ringSize + 28)
                .blur(radius: 18)

            if viewModel.state == .session {
                TimelineView(
                    .animation(
                        minimumInterval: reduceMotion ? 1 : 1.0 / 120.0,
                        paused: reduceMotion || viewModel.isPaused
                    )
                ) { context in
                    PipSessionRing(
                        progress: ringProgress(at: context.date),
                        isLift: viewModel.stage == .lift
                    )
                    .frame(width: ringSize, height: ringSize)
                }
            }

            PipCharacterView(
                stage: viewModel.stage,
                homeState: viewModel.state,
                isPaused: viewModel.isPaused,
                reduceMotion: reduceMotion,
                phaseStartedAt: viewModel.phaseStartedAt,
                phaseDuration: viewModel.phaseDuration,
                elapsedSecondsInPhase: viewModel.elapsedSecondsInPhase,
                size: size
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(viewModel.voiceOverLabel)
            .accessibilityHint(viewModel.voiceOverHint)

            if viewModel.state == .session {
                VStack {
                    PipEffortBubble(
                        title: viewModel.isPaused ? "Paused" : viewModel.stage.effortTitle,
                        subtitle: viewModel.isPaused
                            ? "\(viewModel.remainingSeconds) seconds left"
                            : viewModel.stage.effortSubtitle,
                        isLift: viewModel.stage == .lift && !viewModel.isPaused
                    )
                    Spacer()
                }
                .offset(y: -12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func ringProgress(at date: Date) -> Double {
        let total = Double(max(viewModel.totalSessionSeconds, 1))
        return 1 - (viewModel.visualRemainingSeconds(at: date) / total)
    }

    private var statusBlock: some View {
        VStack(spacing: 6) {
            Text(statusTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(PipTheme.ink(for: colorScheme))

            Text(statusSubtitle)
                .font(.body)
                .foregroundStyle(PipTheme.mutedInk(for: colorScheme))
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.voiceOverLabel)
    }

    private var statusTitle: String {
        if viewModel.state == .session {
            return viewModel.isPaused ? "Paused" : viewModel.stage.accessibilityTitle
        }
        if viewModel.state == .done {
            return "Nice work"
        }
        return "Ready when you are"
    }

    private var statusSubtitle: String {
        if viewModel.state == .session {
            if viewModel.currentRepetition > 0 {
                return "Round \(viewModel.currentRepetition) of 8 · \(viewModel.remainingSeconds)s left"
            }
            return "\(viewModel.remainingSeconds) seconds remaining"
        }
        if viewModel.state == .done {
            return "Added to today's count"
        }
        return "A 48-second guided kegel"
    }

    private var chipRow: some View {
        HStack(spacing: 10) {
            PipChip(title: "Today", value: "\(viewModel.todayCompletedCount)")
            if viewModel.state == .session {
                PipChip(title: "Round", value: "\(max(viewModel.currentRepetition, 1))/8")
                PipChip(title: "Left", value: "\(viewModel.remainingSeconds)s")
            } else {
                PipChip(title: "Session", value: "48s")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var controls: some View {
        Group {
            if viewModel.state == .session {
                HStack(spacing: 12) {
                    PipSecondaryButton(
                        title: viewModel.isPaused ? "Resume" : "Pause",
                        systemImage: viewModel.isPaused ? "play.fill" : "pause.fill"
                    ) {
                        if viewModel.isPaused {
                            viewModel.resumeSession()
                        } else {
                            viewModel.pauseSession()
                        }
                    }
                    .accessibilityLabel(viewModel.isPaused ? "Resume session" : "Pause session")

                    PipSecondaryButton(
                        title: "Cancel",
                        systemImage: "xmark",
                        role: .destructive
                    ) {
                        viewModel.cancelSession()
                    }
                    .accessibilityLabel("Cancel session")
                }
            } else {
                PipPrimaryButton(
                    title: viewModel.primaryActionTitle,
                    systemImage: "play.fill"
                ) {
                    viewModel.start()
                }
                .accessibilityIdentifier("home.start")
                .accessibilityLabel(viewModel.state == .done ? "Start again" : "Start session")
            }
        }
    }
}

private struct HomeLayout {
    let pipSize: CGFloat
    let headerHeight: CGFloat
    let stageHeight: CGFloat

    init(for size: CGSize) {
        headerHeight = size.height < 700 ? 48 : 54
        let chrome = headerHeight + 210
        let proposed = min(size.width - 48, size.height - chrome)
        pipSize = min(max(proposed, 176), 340)
        stageHeight = pipSize + 52
    }
}

private struct StartExplanationSheet: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                PipMascotCanvas(pose: .rest, size: 120)

                Text("A short Pip session")
                    .font(.title2.weight(.semibold))

                Text("Follow Pip's gentle lift and release rhythm for 48 seconds. You can pause or cancel at any time.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                PipPrimaryButton(title: "Start session", systemImage: "play.fill") {
                    viewModel.confirmStartExplanation()
                }
                .accessibilityLabel("Start session")
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PipTheme.background(for: .light))
            .navigationTitle("Before you begin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") {
                        viewModel.dismissStartExplanation()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
