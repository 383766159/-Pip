import Foundation

public enum WidgetSnapshotEmptyReason: Equatable, Sendable {
    case missing
    case corrupt
    case unknownSchema
    case expired
    case staleDay
}

public enum WidgetSurfaceSnapshot: Equatable, Sendable {
    case valid(PipSnapshot)
    case empty(WidgetSnapshotEmptyReason)

    public var snapshot: PipSnapshot? {
        guard case let .valid(snapshot) = self else { return nil }
        return snapshot
    }
}

public struct PipWidgetSnapshotReader {
    public static let expirationInterval: TimeInterval = 24 * 60 * 60

    private let store: PipSnapshotStore

    public init(store: PipSnapshotStore = PipSnapshotStore()) {
        self.store = store
    }

    public func read(
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> WidgetSurfaceSnapshot {
        guard let fileURL = store.fileURL,
              let data = try? Data(contentsOf: fileURL) else {
            return .empty(.missing)
        }

        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let schemaVersion = object["schemaVersion"] as? Int,
           schemaVersion > PipSnapshot.supportedSchemaVersion {
            return .empty(.unknownSchema)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let snapshot = try decoder.decode(PipSnapshot.self, from: data)
            let age = now.timeIntervalSince(snapshot.updatedAt)
            let currentDayKey = PipDateKey.make(from: now, calendar: calendar, timeZone: timeZone)
            guard age >= 0, age <= Self.expirationInterval else {
                return .empty(.expired)
            }
            guard snapshot.deviceDayKey == currentDayKey else {
                return .empty(.staleDay)
            }
            return .valid(snapshot)
        } catch {
            return .empty(.corrupt)
        }
    }
}
