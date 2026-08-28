import SwiftUI

public struct PrivacyView: View {
    private let privacyPolicyURL = URL(string: "https://github.com/383766159/-Pip/blob/master/Docs/Store/PrivacyPolicy.md")!
    private let niddkKegelURL = URL(string: "https://www.niddk.nih.gov/health-information/urologic-diseases/kegel-exercises")!
    private let nhsPelvicFloorURL = URL(string: "https://www.nhs.uk/conditions/urinary-incontinence/10-ways-to-stop-leaks/")!

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
                    "Health notice",
                    text: "Pip is a general wellness reminder, not a medical device. It does not provide medical advice, diagnosis, or treatment. Stop if you have pain or concerns and consult a qualified healthcare professional."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Educational sources")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Text("These independent resources provide general information about Kegel and pelvic floor exercises. Pip does not reproduce their medical guidance or make health claims.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Link("NIDDK: Kegel Exercises", destination: niddkKegelURL)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PipTheme.mintDeep)

                    Link("NHS: Pelvic floor exercises", destination: nhsPelvicFloorURL)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PipTheme.mintDeep)
                }
                .accessibilityElement(children: .contain)

                privacySection(
                    "Your choices",
                    text: "You can manage notification permission in iOS Settings. Removing Pip from your device removes its local app data, subject to iOS system behavior."
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("Full privacy policy")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    Link("Read the full Pip Privacy Policy", destination: privacyPolicyURL)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(PipTheme.mintDeep)
                        .accessibilityHint("Opens the full privacy policy in your browser.")
                }
                .accessibilityElement(children: .combine)
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
