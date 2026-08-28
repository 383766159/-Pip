import SwiftUI
import WidgetKit

struct PipWidgetEntryView: View {
    let entry: PipWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image("PipSoftKnotBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .accessibilityHidden(true)
                Text("Pip")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PipTheme.ink)
                Spacer(minLength: 0)
            }

            switch entry.surface {
            case let .valid(snapshot):
                Text("\(snapshot.todayCompletedCount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(PipTheme.ink)
                Text(stateTitle(snapshot.pipStaticState))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(PipTheme.mintDeep)
                if let nextReminderAt = snapshot.nextReminderAt {
                    Text("Next \(nextReminderAt, style: .time)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No reminder")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            case .empty:
                Text("No data yet")
                    .font(.headline)
                    .foregroundStyle(PipTheme.ink)
                Text("Open Pip to refresh this snapshot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            PipTheme.background(for: .light)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch entry.surface {
        case let .valid(snapshot):
            return "Pip. Today \(snapshot.todayCompletedCount) completed sessions. \(stateTitle(snapshot.pipStaticState))."
        case .empty:
            return "Pip snapshot unavailable. Open Pip to refresh."
        }
    }

    private func stateTitle(_ state: PipStaticState) -> String {
        switch state {
        case .idle: return "Idle"
        case .waiting: return "Waiting"
        case .done: return "Done today"
        }
    }
}

struct PipWidget: Widget {
    let kind = "PipWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PipWidgetProvider()) { entry in
            PipWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pip")
        .description("See today's Pip status and next reminder.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct PipWidgetBundle: WidgetBundle {
    var body: some Widget {
        PipWidget()
    }
}
