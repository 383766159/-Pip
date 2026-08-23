import SwiftUI

public struct AccessibilityView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init() {}

    public var body: some View {
        List {
            Section("Supported cues") {
                Label("VoiceOver labels and announcements", systemImage: "speaker.wave.2")
                Label("Dynamic Type", systemImage: "textformat.size")
                Label("Reduce Motion", systemImage: "figure.walk.motion")
                Label("Color-independent status and button labels", systemImage: "circle.lefthalf.filled")
            }

            Section("Current system settings") {
                LabeledContent("Reduce Motion", value: reduceMotion ? "On" : "Off")
                LabeledContent("Text Size", value: String(describing: dynamicTypeSize))
            }

            Section {
                Text("Pip keeps the session timer available through text, VoiceOver descriptions, visual progress, and optional haptics. Turn on the accessibility features you prefer in iOS Settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Accessibility")
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pip accessibility information")
    }
}
