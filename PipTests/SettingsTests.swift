import XCTest
import SwiftUI
@testable import Pip

@MainActor
final class SettingsTests: XCTestCase {
    func testHapticsDefaultToEnabledAndPersistUserChoice() {
        let suiteName = "Pip.SettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let viewModel = SettingsViewModel(preferences: defaults)
        XCTAssertTrue(viewModel.hapticsEnabled)

        viewModel.hapticsEnabled = false

        XCTAssertFalse(PipPreferences.hapticsEnabled(in: defaults))
        XCTAssertFalse(SettingsViewModel(preferences: defaults).hapticsEnabled)
    }

    func testCompletedSessionInvariantRequiresExactly48ActiveSeconds() {
        let date = Date(timeIntervalSince1970: 1_750_000_000)
        let dayKey = PipDateKey.make(from: date)
        let record = SessionRecord(
            status: .completed,
            startedAt: date,
            completedAt: date,
            startDayKey: dayKey,
            completionDayKey: dayKey,
            completedCycles: 8,
            activeSeconds: 49,
            createdAt: date,
            updatedAt: date
        )

        XCTAssertFalse(record.satisfiesCompletionInvariant)
    }

    func testThemeInkPreservesLightValueAndUsesContrastingDarkValue() {
        XCTAssertEqual(PipTheme.ink(for: .light), PipTheme.ink)
        XCTAssertNotEqual(PipTheme.ink(for: .dark), PipTheme.ink)
    }
}
