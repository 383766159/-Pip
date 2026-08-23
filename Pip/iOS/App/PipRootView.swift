import SwiftUI
import SwiftData

struct PipRootView: View {
    let snapshotStore: PipSnapshotStore
    @Environment(\.modelContext) private var modelContext
    @StateObject private var notificationAuthorization: NotificationAuthorization

    init(
        snapshotStore: PipSnapshotStore,
        notificationAuthorization: NotificationAuthorization? = nil
    ) {
        self.snapshotStore = snapshotStore
        _notificationAuthorization = StateObject(
            wrappedValue: notificationAuthorization ?? NotificationAuthorization()
        )
    }

    var body: some View {
        HomeView(snapshotStore: snapshotStore, modelContext: modelContext)
            .task {
                notificationAuthorization.start()
            }
            .onDisappear {
                notificationAuthorization.stop()
            }
    }
}
