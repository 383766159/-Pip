# Pip v1 Acceptance Report

**Date:** 2026-08-22
**Overall decision:** **AUTOMATED ACCEPTANCE PASSED; SIMULATOR SMOKE PARTIAL; EXTERNAL SUBMISSION CHECKS PENDING**

This QA closeout modifies only this report and `PipV1TestMatrix.md`; it does not modify product source or `.openteams/plan.md`. The final clean-install evidence (`/tmp/Pip-iPhone17-final-light.png`, plus the light/dark theme captures) confirms a full-screen, balanced home layout; manual Start, first-start explanation, countdown, and completion interaction remain unverified because GUI tap injection is unavailable. The final iPhone 17 run executed 47 XCTest methods with zero failures; App/Widget Release builds and plist lint also passed. Watch verification remains environment-blocked because Xcode lacks the watchOS 26.5 platform.

## Simulator Smoke Repair Closeout

| Acceptance item | Evidence | Decision |
|---|---|---|
| SMR-01: cold-start layout and Today 0 | Initial evidence `/tmp/Pip-iPhone17-reboot-fixed.png`; final clean-install evidence `/tmp/Pip-iPhone17-final-light.png` shows an unobstructed full-screen light home surface with `TODAY 0`, status copy, and Start. | **PASS (SCREENSHOT)** |
| SMR-02: header visible | Final light/dark screenshots show readable `Pip`, Calendar, and Settings with no overlap. | **PASS (SCREENSHOT)** |
| SMR-03: Start tap and first-start explanation | Start is visually present, but no GUI tap could be injected on this machine; explanation confirmation was not independently exercised. | **NOT VERIFIED** |
| SMR-04: countdown changes during a live session | No independent 0-second/3-second runtime screenshots were captured because GUI injection is unavailable; `HomeStateTests` 9/9 is automated state coverage, not manual UI evidence. | **NOT VERIFIED** |
| SMR-05: 48-second completion and count increment | No independent manual completion or done-state screenshot was captured. | **NOT VERIFIED** |
| SMR-06: notification timing/state | A notification prompt was observed in an earlier simulator state and was absent after shutdown/boot; permission state could not be isolated sufficiently to prove the complete fresh-install path. | **NOT VERIFIED (SYSTEM STATE)** |
| SMR-07: automated regression | Initial compact-layout regression was 9/9 and 46/46; the final source/theme run passed **47/47** on iPhone 17 with zero failures. | **PASS (AUTOMATED)** |
| SMR-08: supporting checks | Pip Release generic iOS build, Widget build, PrivacyInfo lint, and forbidden dependency/package scans passed; Watch build remains blocked by missing watchOS 26.5 SDK. | **PASS (IOS/WIDGET/STATIC); WATCH BLOCKED** |

The initial compact-layout evidence used spacing 2, Pip size 88, and zero vertical padding. The final source uses a separate header and a centered main-content container (`Pip/iOS/Home/HomeView.swift`), with scrolling retained for smaller heights and larger text. Static screenshots prove visual layout only; they must not be used as evidence that Start, the explanation sheet, live countdown, or done-state persistence was clicked successfully.

## Actual command results

| Verification | Actual result |
|---|---|
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Pip.xcodeproj -scheme Pip -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' test` | **PASS**. `TEST SUCCEEDED`; **47/47** tests executed with zero failures. Final result bundle: `/tmp/Pip-final-dark-tests/Logs/Test/Test-Pip-2026.08.22_14-49-04-+0800.xcresult`. |
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Pip.xcodeproj -scheme PipWidgetExtension -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO` | **PASS** — `BUILD SUCCEEDED`. |
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Pip.xcodeproj -scheme PipWatch -destination 'generic/platform=watchOS' build CODE_SIGNING_ALLOWED=NO` | **ENVIRONMENT NOT VERIFIED** — Xcode reports no eligible destination because `watchOS 26.5 is not installed`. |
| `plutil -lint Pip/Resources/PrivacyInfo.xcprivacy` | **PASS** — `OK`. |
| `rg` dependency / forbidden-API scans | **PASS (static)** — no SPM, CocoaPods, Carthage, workspace, Pods, or Vendor manifests; no prohibited runtime implementation dependencies found. Matches were reviewed as docs’ explicit exclusions, SwiftData’s `.none` CloudKit setting, or plist DOCTYPE URLs. |
| `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Pip.xcodeproj -scheme Pip -configuration Debug -showBuildSettings` | **PASS (configuration check)** — `CONFIGURATION = Debug`; `SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG`. |

## Risks

- **Environment-blocking:** Watch target build and all Watch hardware checks are unverified until watchOS 26.5 is installed.
- **Simulator smoke partial:** the repaired layout is visually verified, but Start/first-start explanation, live countdown, and 48-second completion remain unverified because GUI tap injection is unavailable; notification prompt behavior also varied with simulator shutdown/boot permission state.
- **Device/system validation pending:** real notification authorization grant/denial recovery, Focus behavior, device time-zone delivery, haptic feel, Widget installation/tap behavior, VoiceOver, largest text size, Reduce Motion, and physical-device Dark Mode remain unverified. Simulator light/dark clean-install screenshots `/tmp/Pip-iPhone17-light-theme-fixed.png` and `/tmp/Pip-iPhone17-dark-theme-fixed.png` both passed at `1206x2622`; no physical Watch or required system states were available.
- **Submission readiness pending:** no Apple Developer/App Store Connect account validation occurred. The privacy policy draft still requires a stable public HTTPS URL and support contact before submission.

## Final-source evidence added in this run

- `LocalStatsRebuilderTests` passed for rebuilding Calendar/streak aggregates from valid completed records and deleting stale aggregates; `HomeStateTests` passed for completion-triggered rebuild.
- `StreakCalculatorTests.testSessionsUsePersistedCompletionDayKeyAcrossTimeZones` passed, confirming completed-session history uses frozen `completionDayKey` rather than reclassifying on a later time-zone change.
- `PipPersistenceTests.testDefaultSnapshotStoreDoesNotUsePrivateApplicationSupportFallback` passed, confirming unavailable production App Group storage does not silently fall back to target-private storage.
- `PipPersistenceTests.testSnapshotRejectsIncompleteOrEmptyReminderPair`, `WidgetSnapshotTests.testIncompleteReminderPairFallsBackToSafeEmptyState`, and `WatchSessionTests.testWatchReaderSafelyRejectsIncompleteReminderPair` passed for the paired `nextReminderAt` / `nextReminderSlotKey` invariant.
- `ReminderSchedulerTests` passed for invalid weekday masks not scheduling and for filling/persisting missing defaults when stored reminder slots are partial.
- The final-source rerun also confirmed the release guard is present in the verified source; no business-code edits were made during this QA pass.

## Exit criteria

1. Install watchOS 26.5, rerun the unsigned generic Watch build, then verify Watch haptics, ring, and complications on hardware.
2. Complete the physical/system test cases and App Store Connect/policy publication actions listed in [PipV1TestMatrix.md](PipV1TestMatrix.md).
