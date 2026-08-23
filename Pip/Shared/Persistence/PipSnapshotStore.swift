import Foundation

public enum PipSnapshotStoreError: Error, Equatable {
    case unavailable
    case cannotCreateDirectory(URL)
    case cannotReplace(URL)
}

public final class PipSnapshotStore {
    public static let appGroupIdentifier = "group.com.pip.app"
    public static let fileName = "PipSnapshot.json"

    public let fileURL: URL?

    private let fileManager: FileManager
    private let lock = NSLock()

    public init(fileURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.fileURL = fileURL ?? Self.defaultFileURL(fileManager: fileManager)
    }

    public func read(
        now: Date = Date(),
        calendar: Calendar = Calendar(identifier: .gregorian),
        timeZone: TimeZone = .current
    ) -> PipSnapshot {
        lock.lock()
        defer { lock.unlock() }

        guard let fileURL,
              let data = try? Data(contentsOf: fileURL) else {
            return .empty(now: now, calendar: calendar, timeZone: timeZone)
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(PipSnapshot.self, from: data)
        } catch {
            return .empty(now: now, calendar: calendar, timeZone: timeZone)
        }
    }

    public func write(_ snapshot: PipSnapshot) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let fileURL else {
            throw PipSnapshotStoreError.unavailable
        }

        let directory = fileURL.deletingLastPathComponent()
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw PipSnapshotStoreError.cannotCreateDirectory(directory)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(snapshot)
        let temporaryURL = directory.appendingPathComponent(".PipSnapshot-\(UUID().uuidString).tmp")

        do {
            try data.write(to: temporaryURL, options: [.atomic])
            if fileManager.fileExists(atPath: fileURL.path) {
                _ = try fileManager.replaceItemAt(
                    fileURL,
                    withItemAt: temporaryURL,
                    backupItemName: nil,
                    options: []
                )
            } else {
                try fileManager.moveItem(at: temporaryURL, to: fileURL)
            }
        } catch {
            if fileManager.fileExists(atPath: temporaryURL.path) {
                try? fileManager.removeItem(at: temporaryURL)
            }
            throw PipSnapshotStoreError.cannotReplace(fileURL)
        }
    }

    private static func defaultFileURL(fileManager: FileManager) -> URL? {
        guard let baseURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else {
            return nil
        }
        return baseURL.appendingPathComponent(fileName, isDirectory: false)
    }
}
