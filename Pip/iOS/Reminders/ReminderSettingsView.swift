import SwiftUI
import SwiftData

@MainActor
public struct ReminderSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: ReminderSettingsViewModel

    public init() {
        _viewModel = StateObject(wrappedValue: ReminderSettingsViewModel())
    }

    public init(viewModel: ReminderSettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        Group {
            if viewModel.isLoaded {
                Form {
                    Section {
                        Text("Choose up to three local reminders. Notifications follow your device time zone and system Focus settings.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.slots, id: \.slotKey) { slot in
                        Section(slotTitle(slot.slotKey)) {
                            DatePicker(
                                "Time",
                                selection: timeBinding(for: slot.slotKey),
                                displayedComponents: .hourAndMinute
                            )
                            .accessibilityLabel("\(slotTitle(slot.slotKey)) reminder time")

                            Toggle(
                                "Include weekends",
                                isOn: weekendBinding(for: slot.slotKey)
                            )

                            Toggle(
                                "Reminder enabled",
                                isOn: enabledBinding(for: slot.slotKey)
                            )
                        }
                    }

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .accessibilityLabel(errorMessage)
                    }

                    Button(viewModel.isSaving ? "Saving…" : "Save reminders") {
                        viewModel.save()
                    }
                    .disabled(viewModel.isSaving)
                    .accessibilityHint("Replaces Pip's previous local reminders.")
                }
            } else {
                ProgressView("Loading reminders…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            viewModel.load(context: modelContext)
        }
        .navigationTitle("Reminders")
    }

    private func slotTitle(_ slotKey: String) -> String {
        switch slotKey {
        case "morning": return "Morning"
        case "afternoon": return "Afternoon"
        case "evening": return "Evening"
        default: return slotKey.capitalized
        }
    }

    private func timeBinding(for slotKey: String) -> Binding<Date> {
        Binding(
            get: { viewModel.time(for: slotKey) },
            set: { viewModel.updateTime(for: slotKey, date: $0) }
        )
    }

    private func weekendBinding(for slotKey: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.isWeekendEnabled(for: slotKey) },
            set: { viewModel.setWeekendEnabled($0, for: slotKey) }
        )
    }

    private func enabledBinding(for slotKey: String) -> Binding<Bool> {
        Binding(
            get: { viewModel.slot(for: slotKey)?.isEnabled ?? false },
            set: { viewModel.setEnabled($0, for: slotKey) }
        )
    }
}
