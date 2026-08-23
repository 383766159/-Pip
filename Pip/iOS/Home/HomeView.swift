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
                let layout = HomeLayout(for: proxy.size.height)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                            .frame(maxWidth: 430)
                            .frame(minHeight: layout.headerHeight)
                            .padding(.horizontal, 24)

                        VStack(spacing: layout.spacing) {
                            todayCount
                            pipStage(size: layout.pipSize)
                            statusText
                            controls
                        }
                        .frame(maxWidth: 430)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .frame(
                            minHeight: max(0, proxy.size.height - layout.headerHeight),
                            alignment: .center
                        )
                    }
                    .frame(maxWidth: .infinity)
                }
                .background(PipTheme.background(for: colorScheme).ignoresSafeArea())
            }
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
        HStack {
            Text("Pip")
                .font(.largeTitle.weight(.bold))

            Spacer()

            Button {
                viewModel.pauseForLeaving()
                isCalendarPresented = true
            } label: {
                Image(systemName: "calendar")
                    .font(.title3.weight(.semibold))
            }
            .accessibilityLabel("Calendar")
            .accessibilityHint("Opens the calendar page.")

            Button {
                viewModel.pauseForLeaving()
                isSettingsPresented = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.title3.weight(.semibold))
            }
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens settings in a sheet.")
        }
        .foregroundStyle(PipTheme.ink(for: colorScheme))
    }

    private var todayCount: some View {
        VStack(spacing: 4) {
            Text("TODAY")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(.secondary)

            Text("\(viewModel.todayCompletedCount)")
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .contentTransition(.numericText())

            Text("completed sessions")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today \(viewModel.todayCompletedCount) completed sessions")
    }

    private func pipStage(size: CGFloat) -> some View {
        PipFrameView(
            stage: viewModel.stage,
            frameIndex: viewModel.frameIndex(reduceMotion: reduceMotion),
            reduceMotion: reduceMotion
        )
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.voiceOverLabel)
        .accessibilityHint(viewModel.voiceOverHint)
    }

    private var statusText: some View {
        VStack(spacing: 8) {
            Text(viewModel.stage.accessibilityTitle)
                .font(.title2.weight(.semibold))

            if viewModel.state == .session {
                Text("\(viewModel.remainingSeconds) seconds remaining")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            } else if viewModel.state == .done {
                Text("Nice work")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ready when you are")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.voiceOverLabel)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            if viewModel.state == .session {
                HStack(spacing: 12) {
                    Button {
                        if viewModel.isPaused {
                            viewModel.resumeSession()
                        } else {
                            viewModel.pauseSession()
                        }
                    } label: {
                        Label(viewModel.isPaused ? "Resume" : "Pause", systemImage: viewModel.isPaused ? "play.fill" : "pause.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(viewModel.isPaused ? "Resume session" : "Pause session")

                    Button(role: .destructive) {
                        viewModel.cancelSession()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Cancel session")
                }
            } else {
                Button {
                    viewModel.start()
                } label: {
                    Label(viewModel.primaryActionTitle, systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("home.start")
                .accessibilityLabel(viewModel.state == .done ? "Start again" : "Start session")
            }
        }
    }
}

private struct HomeLayout {
    let spacing: CGFloat
    let pipSize: CGFloat
    let headerHeight: CGFloat

    init(for height: CGFloat) {
        if height < 1_100 {
            spacing = 16
            pipSize = 144
            headerHeight = 56
        } else {
            spacing = 24
            pipSize = 220
            headerHeight = 64
        }
    }
}

private struct PipFrameView: View {
    let stage: PipStage
    let frameIndex: Int
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            Image(stage.assetName)
                .resizable()
                .scaledToFit()
                .scaleEffect(reduceMotion ? 1 : stage.scale(for: frameIndex))
                .id("\(stage.rawValue)-\(frameIndex)")
                .transition(
                    reduceMotion
                        ? .opacity
                        : .scale(scale: 0.9).combined(with: .opacity)
                )
        }
        .animation(
            reduceMotion ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.35),
            value: "\(stage.rawValue)-\(frameIndex)"
        )
    }
}

private struct StartExplanationSheet: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 44))
                    .foregroundStyle(PipTheme.mint)

                Text("A short Pip session")
                    .font(.title2.weight(.semibold))

                Text("Follow Pip's gentle lift and release rhythm for 48 seconds. You can pause or cancel at any time.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                Button("Start session") {
                    viewModel.confirmStartExplanation()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Start session")
            }
            .padding(24)
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
