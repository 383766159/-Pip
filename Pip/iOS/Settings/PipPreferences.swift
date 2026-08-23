import Foundation

public enum PipPreferences {
    public static let hapticsEnabledKey = "Pip.Preferences.hapticsEnabled"

    public static func hapticsEnabled(in defaults: UserDefaults = .standard) -> Bool {
        guard defaults.object(forKey: hapticsEnabledKey) != nil else {
            return true
        }
        return defaults.bool(forKey: hapticsEnabledKey)
    }
}
