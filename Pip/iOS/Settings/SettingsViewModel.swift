import Foundation
import SwiftUI

@MainActor
public final class SettingsViewModel: ObservableObject {
    @Published public var hapticsEnabled: Bool {
        didSet {
            preferences.set(hapticsEnabled, forKey: PipPreferences.hapticsEnabledKey)
        }
    }

    private let preferences: UserDefaults

    public init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        self.hapticsEnabled = PipPreferences.hapticsEnabled(in: preferences)
    }
}
