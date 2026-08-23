import Foundation
import WidgetKit

public struct PipWidgetProvider: TimelineProvider {
    private let snapshotReader: PipWidgetSnapshotReader

    public init(snapshotReader: PipWidgetSnapshotReader = PipWidgetSnapshotReader()) {
        self.snapshotReader = snapshotReader
    }

    public func placeholder(in context: Context) -> PipWidgetEntry {
        PipWidgetEntry(date: Date(), surface: .empty(.missing))
    }

    public func getSnapshot(in context: Context, completion: @escaping (PipWidgetEntry) -> Void) {
        let now = Date()
        completion(PipWidgetEntry(date: now, surface: snapshotReader.read(now: now)))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<PipWidgetEntry>) -> Void) {
        let now = Date()
        let entry = PipWidgetEntry(date: now, surface: snapshotReader.read(now: now))
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: now)
            ?? now.addingTimeInterval(15 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }
}
