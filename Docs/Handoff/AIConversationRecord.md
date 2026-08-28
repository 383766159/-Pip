# Pip AI Development Record

**Project:** Pip: Kegel Reminder
**Repository:** `github.com/383766159/-Pip`
**Record date:** 2026-08-29

This document consolidates the available AI-assisted development history into a project record. It is a technical summary, not a verbatim transcript. Credentials, verification codes, and private account-session data are intentionally excluded.

## Product Direction

- Pip is a small, local-first Kegel habit and reminder app.
- A session is eight lift-and-release cycles lasting about 48 seconds.
- The app has no account, cloud sync, network service, advertising, analytics, HealthKit, StoreKit, in-app purchases, or third-party tracking.
- iOS and Apple Watch are supported. iPad uses the iOS layout.
- Mac App Store and Apple Vision Pro availability were disabled before submission.
- The App Store price was configured as USD 0.99, with automatic release selected after approval.

## Animation Evolution

The project moved through several animation implementations during the AI-assisted iterations:

1. Early frame-based mascot animation was used to validate the session state machine.
2. The animation was changed to a continuous pose model after the requested motion became smooth and uninterrupted rather than frame-blended.
3. The approved final iOS presentation uses a baked 2.5D knot body with continuously calculated deformation, bend, twist, face, shadow, glow, and guide-orb values.
4. The Metal warp is implemented in `Pip/iOS/Home/PipKnotWarp.metal`; the Swift motion and rendering orchestration is in `Pip/iOS/Home/PipMobiusSceneView.swift`.
5. The Watch uses a lightweight baked 2.5D body and separate animated face, shadow, and guide-orb layers so the small display remains readable and responsive.

## Final Source of Truth

### iOS

- `Pip/iOS/Home/PipMobiusSceneView.swift`: continuous 2.5D pose model and SwiftUI renderer.
- `Pip/iOS/Home/PipKnotWarp.metal`: Metal deformation kernel used by the iOS visual pipeline.
- `Pip/iOS/Home/PipCharacterView.swift`: 60 Hz timeline presentation, session ring, and motion timing.
- `Pip/iOS/Home/HomeView.swift`: home layout, start explanation, and user actions.
- `Pip/iOS/Home/HomeViewModel.swift`: idle, session, pause, resume, cancel, and completion state.
- `Pip/iOS/Resources/Assets.xcassets/PipSoftKnotBody.imageset/`: approved 2.5D body asset.

### Apple Watch

- `Pip/Watch/Extension/PipWatchCharacterView.swift`: watchOS 2.5D rendering and continuous phase motion.
- `Pip/Watch/Extension/WatchSessionModel.swift`: independent Watch session engine integration.
- `Pip/Watch/Extension/PipWatchExtension.swift`: Watch layout and equal-sized primary/cancel controls.
- `Pip/Watch/Resources/WatchAssets.xcassets/`: Watch extension visual resources.
- `Pip/Watch/Resources/WatchAppAssets.xcassets/`: Watch app icon resources, including `CFBundleIconFiles` support.

### Release and privacy configuration

- `Pip.xcodeproj/project.pbxproj`: iOS, Widget, Watch, asset, and privacy-resource membership.
- `Pip/Resources/PrivacyInfo.xcprivacy`, `Pip/Widget/Resources/PrivacyInfo.xcprivacy`, and `Pip/Watch/Resources/PrivacyInfo.xcprivacy`.
- `Docs/Store/PrivacyPolicy.md`, `Docs/Store/PipV1StoreCopy.md`, and `Docs/AppStore/EnglishStoreCopy.md`.
- `QA/PipV1AcceptanceReport.md`, `QA/PipV1TestMatrix.md`, and `QA/PipUIIntegrityReview.md`.

## Verification Record

- Release archive completed with valid Apple Distribution signing: `Pip-preflight-20260828.xcarchive`.
- App, Widget, Watch App, and Watch Extension version/build values were aligned to `1.0 (17)`.
- Watch app icon metadata includes `CFBundleIconFiles`, addressing the earlier missing-icons validation failure.
- Privacy manifests are included in the app, Widget, and Watch targets.
- The latest local automated test run passed 48/48 XCTest methods with zero failures.
- Static privacy, dependency, and forbidden-API checks passed. Physical Watch/system-state checks remain environment-dependent.

## App Store Connect Submission

- App: `Pip: Kegel Reminder`
- App ID: `6805331065`
- Version: `1.0`
- Build: `17`
- iPhone, iPad, and Apple Watch screenshots were updated to the final 2.5D model version.
- Mac and Apple Vision Pro availability were closed.
- The iOS version was submitted for review on 2026-08-28 and reached **Waiting for Review**.
- Apple indicated that review can take up to 48 hours and will send the result by email.

## Follow-up Notes

- A successful submission means the build is in Apple's review queue; it does not mean approval has been granted.
- Any future binary change must increment the build number, rebuild, revalidate, and update the matching App Store Connect build before resubmission.
- The generated `build/` directory and Xcode user-state files are local artifacts and are intentionally excluded from GitHub.
