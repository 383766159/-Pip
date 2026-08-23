import SwiftUI
import SwiftData

@main
@MainActor
struct PipApp: App {
    private let localStore: LocalStore
    private let snapshotStore: PipSnapshotStore

    init() {
        self.init(localStore: nil, snapshotStore: nil)
    }

    init(
        localStore: LocalStore?,
        snapshotStore: PipSnapshotStore?
    ) {
        if let localStore {
            self.localStore = localStore
        } else {
            do {
                self.localStore = try LocalStore()
            } catch {
                fatalError("Unable to initialize the local Pip store: \(error)")
            }
        }
        self.snapshotStore = snapshotStore ?? PipSnapshotStore()
    }

    var body: some Scene {
        WindowGroup {
            PipRootView(snapshotStore: snapshotStore)
        }
        .modelContainer(localStore.container)
    }
}
