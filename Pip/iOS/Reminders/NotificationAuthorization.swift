import Foundation
import UserNotifications

public extension Notification.Name {
    static let pipSessionCompleted = Notification.Name("Pip.Session.completed")
}

public protocol NotificationAuthorizationClient: AnyObject {
    func requestAuthorization(
        options: UNAuthorizationOptions,
        completionHandler: @escaping @Sendable (Bool, Error?) -> Void
    )
}

extension UNUserNotificationCenter: NotificationAuthorizationClient {}

@MainActor
public final class NotificationAuthorization: ObservableObject {
    public static let didRequestAuthorizationKey = "Pip.Notifications.didRequestAuthorization"

    @Published public private(set) var didRequestAuthorization: Bool
    @Published public private(set) var isAuthorized = false
    @Published public private(set) var lastError: String?

    private let center: any NotificationAuthorizationClient
    private let preferences: UserDefaults
    private var observer: NSObjectProtocol?

    public init(
        center: any NotificationAuthorizationClient = UNUserNotificationCenter.current(),
        preferences: UserDefaults = .standard
    ) {
        self.center = center
        self.preferences = preferences
        self.didRequestAuthorization = preferences.bool(forKey: Self.didRequestAuthorizationKey)
    }

    public func start() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: .pipSessionCompleted,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.requestAuthorizationIfNeeded()
            }
        }
    }

    public func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }

    public func requestAuthorizationIfNeeded() {
        guard !didRequestAuthorization else { return }

        didRequestAuthorization = true
        preferences.set(true, forKey: Self.didRequestAuthorizationKey)
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            let errorMessage = error.map { String(describing: $0) }
            Task { @MainActor [weak self] in
                self?.isAuthorized = granted
                self?.lastError = errorMessage
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
