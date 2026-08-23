import SwiftUI

public struct SettingsView: View {
    @AppStorage(PipPreferences.hapticsEnabledKey)
    private var hapticsEnabled = true

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Reminders") {
                    NavigationLink {
                        ReminderSettingsView()
                    } label: {
                        Label("Reminder schedule", systemImage: "bell")
                    }
                    .accessibilityHint("Choose up to three local reminder times.")
                }

                Section {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Session haptics", systemImage: "hand.tap")
                    }
                    .accessibilityHint("Turns Pip session haptics on or off.")
                } footer: {
                    Text("When enabled, Pip can use haptics for lift, release, and completion.")
                }

                Section("Accessibility") {
                    NavigationLink {
                        AccessibilityView()
                    } label: {
                        Label("Accessibility", systemImage: "accessibility")
                    }

                    Label {
                        Text(reduceMotion ? "Reduce Motion is on" : "Reduce Motion follows your device setting")
                    } icon: {
                        Image(systemName: reduceMotion ? "figure.walk.motion" : "accessibility")
                    }
                    .accessibilityLabel(reduceMotion ? "Reduce Motion is on" : "Reduce Motion follows your device setting")
                    .accessibilityHint("Change this preference in iOS Accessibility settings.")
                }

                Section("About") {
                    NavigationLink {
                        PrivacyView()
                    } label: {
                        Label("Privacy", systemImage: "hand.raised")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health notice")
                            .font(.body.weight(.semibold))
                        Text("Pip is not a medical device and does not provide medical advice, diagnosis, or treatment. Stop if you have pain or concerns and consult a qualified healthcare professional.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)

                    LabeledContent("Version", value: PipAccessibilitySupport.versionDescription())
                        .accessibilityLabel("Pip version \(PipAccessibilitySupport.versionDescription())")
                }
            }
            .scrollContentBackground(.hidden)
            .background(PipTheme.background(for: colorScheme).ignoresSafeArea())
            .tint(PipTheme.mintDeep)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
            }
        }
    }
}
