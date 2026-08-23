import Foundation
import SwiftData

public enum SessionStatus: String, Codable, Sendable {
    case paused
    case completed
    case incomplete
}

@Model
public final class SessionRecord {
    @Attribute(.unique) public var id: UUID
    public var statusRaw: String
    public var startedAt: Date
    public var lastResumedAt: Date?
    public var completedAt: Date?
    public var startDayKey: String
    public var completionDayKey: String?
    public var completedCycles: Int
    public var activeSeconds: Int
    public var pauseCount: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        status: SessionStatus = .paused,
        startedAt: Date,
        lastResumedAt: Date? = nil,
        completedAt: Date? = nil,
        startDayKey: String,
        completionDayKey: String? = nil,
        completedCycles: Int = 0,
        activeSeconds: Int = 0,
        pauseCount: Int = 0,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        let now = Date()
        self.id = id
        self.statusRaw = status.rawValue
        self.startedAt = startedAt
        self.lastResumedAt = lastResumedAt
        self.completedAt = completedAt
        self.startDayKey = startDayKey
        self.completionDayKey = completionDayKey
        self.completedCycles = completedCycles
        self.activeSeconds = activeSeconds
        self.pauseCount = pauseCount
        self.createdAt = createdAt ?? now
        self.updatedAt = updatedAt ?? now
    }

    public var status: SessionStatus {
        SessionStatus(rawValue: statusRaw) ?? .incomplete
    }

    public var satisfiesCompletionInvariant: Bool {
        guard (0...8).contains(completedCycles),
              (0...48).contains(activeSeconds),
              pauseCount >= 0,
              PipDateKey.isValid(startDayKey),
              updatedAt >= createdAt else {
            return false
        }

        switch status {
        case .completed:
            return completedCycles == 8 &&
                activeSeconds == 48 &&
                completedAt != nil &&
                completionDayKey.map(PipDateKey.isValid) == true
        case .paused, .incomplete:
            return completedAt == nil && completionDayKey == nil
        }
    }
}

public typealias PipSession = SessionRecord
