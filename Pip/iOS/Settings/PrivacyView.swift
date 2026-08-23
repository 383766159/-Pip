import SwiftUI

public struct PrivacyView: View {
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                privacySection(
                    "Your information",
                    text: "Pip stores your completed session count and reminder choices on your device. Its widget and companion surfaces use that local information only to show your Pip status."
                )

                privacySection(
                    "Notifications",
                    text: "If you allow notifications, Pip schedules Kegel and pelvic floor reminders on your device. You can change or turn off reminders in Settings and in iOS Settings."
                )

                privacySection(
                    "What Pip does not do",
                    text: "Pip has no account, cloud sync, analytics, advertising, in-app purchases, HealthKit connection, or third-party data sharing. Pip does not collect or transmit your personal information."
                )

                privacySection(
                    "Your choices",
                    text: "You can manage notification permission in iOS Settings. Removing Pip from your device removes its local app data, subject to iOS system behavior."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
    }

    private func privacySection(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}
