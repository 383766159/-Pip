import Foundation

public struct WatchSurfaceSnapshotReader {
    public static let expirationInterval: TimeInterval = 24 * 60 * 60

    private let store: PipSnapshotStore

    public init(store: PipSnapshotStore = PipSnapshotStore()) {
        self.store = store
    }

    public func read(
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> PipSnapshot? {
        guard let fileURL = store.fileURL,
              let data = try? Data(contentsOf: fileURL) else { return nil }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(PipSnapshot.self, from: data)
            let age = now.timeIntervalSince(snapshot.updatedAt)
            let currentDayKey = PipDateKey.make(from: now, calendar: calendar, timeZone: timeZone)
            guard age >= 0,
                  age <= Self.expirationInterval,
                  snapshot.deviceDayKey == currentDayKey else {
                return nil
            }
            return snapshot
        } catch {
            return nil
        }
    }
}
