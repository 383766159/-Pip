import Foundation
import SwiftData

@MainActor
public final class LocalStore {
    public let container: ModelContainer

    public var context: ModelContext {
        container.mainContext
    }

    public init(container: ModelContainer) {
        self.container = container
    }

    public convenience init(isStoredInMemoryOnly: Bool = false) throws {
        let configuration = ModelConfiguration(
            schema: Self.schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: Self.schema, configurations: [configuration])
        self.init(container: container)
    }

    public static func makeInMemoryForTesting() throws -> LocalStore {
        try LocalStore(isStoredInMemoryOnly: true)
    }

    public static let schema = Schema([
        SessionRecord.self,
        ReminderSlot.self,
        CalendarDayStat.self,
        StreakState.self
    ])
}
