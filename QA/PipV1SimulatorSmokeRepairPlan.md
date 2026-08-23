# simulator-smoke-repair QA Verification Plan

**Goal:** Independently verify that the repaired iPhone 17 Simulator cold-start home screen exposes the header and Start control, that the first-start explanation and live session countdown work, and that the existing automated/platform checks remain green.

**Architecture:** QA builds the Debug iOS app from the current workspace, removes the installed `com.pip.app`, installs the fresh simulator product, and captures evidence at cold start, first-start explanation, active session, and completion. UI observations are kept separate from the notification-permission state; the latter is recorded as a simulator-state observation unless a clean launch reproduces it.

**Tech Stack:** Xcode 26.6, iOS 26.5 iPhone 17 Simulator, `xcodebuild`, `xcrun simctl`, XCTest, WidgetKit, `plutil`, `rg`.

---

## Baseline and scope

- Device: iPhone 17 Simulator, UDID `8DDD783C-51C9-490A-A6C7-F7466067E382`.
- Bundle: `com.pip.app`.
- Existing failure evidence: `/tmp/Pip-iPhone17-fresh-before-start.png` shows the light home surface vertically cropped; the header is absent and only the top of Start is visible.
- Existing notification evidence: `/tmp/Pip-iPhone17-home.png` shows the system notification prompt. The prompt disappeared after simulator shutdown/boot, so it must be recorded as simulator state and not treated as a home-layout failure.
- Product code is read-only for this QA node. Only QA evidence documents may be updated.

## Independent acceptance items

| ID | Acceptance criterion | Evidence required |
|---|---|---|
| SMR-01 | Cold start has no stale completed count and the home surface is not vertically clipped. | Fresh-install screenshot; `TODAY` count is `0`; background reaches the usable screen; no clipped top/bottom content. |
| SMR-02 | Header is visible and usable. | Cold-start screenshot shows `Pip`, Calendar, and Settings controls. |
| SMR-03 | Start is visible and tappable; first start presents the short explanation exactly once. | Screenshot of the visible Start control and explanation sheet; successful confirmation enters session. |
| SMR-04 | Active session countdown changes at runtime. | Session screenshots at launch and after at least 3 seconds show remaining seconds decreasing and Lift/Release content changing. |
| SMR-05 | Completion is recorded only at the 48-second boundary. | Completion screenshot shows `Nice work`/done state; count changes from 0 to 1; no early count increment. |
| SMR-06 | Notification prompt is not a cold-start side effect. | Clean uninstall/install launch has no prompt before completion; any prompt seen only in a prior simulator state is recorded separately. |
| SMR-07 | Automated iOS regression remains green. | Full `Pip` iPhone 17 test output: 45/45, zero failures. |
| SMR-08 | Release-supporting checks remain green. | Widget build, PrivacyInfo lint, and forbidden dependency scan outputs. Watch build remains separately marked if watchOS SDK is unavailable. |

## Reproducible execution sequence

1. Confirm the frontend repair is present in the checked-out source and record the current source file timestamps; do not alter `Pip/` or `Pip.xcodeproj`.
2. Build a fresh Debug simulator product into an isolated temporary DerivedData directory:

   ```bash
   DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
     -project Pip.xcodeproj -scheme Pip -configuration Debug \
     -destination 'id=8DDD783C-51C9-490A-A6C7-F7466067E382' \
     -derivedDataPath /tmp/Pip-simulator-smoke-repair-deriveddata \
     build CODE_SIGNING_ALLOWED=NO
   ```

3. Shut down and boot the iPhone 17 Simulator, wait for boot completion, uninstall `com.pip.app`, install `.../Build/Products/Debug-iphonesimulator/Pip.app`, launch it, and capture `/tmp/Pip-iPhone17-simulator-smoke-cold.png`.
4. Inspect the cold-start screenshot against SMR-01/02/06. Record the notification prompt state independently.
5. Exercise Start and the first-start explanation. Capture `/tmp/Pip-iPhone17-simulator-smoke-explanation.png` and `/tmp/Pip-iPhone17-simulator-smoke-session-0s.png`.
6. Wait at least 3 seconds, capture `/tmp/Pip-iPhone17-simulator-smoke-session-3s.png`, and compare the remaining-seconds text and Pip stage with the 0-second capture. Continue through the 48-second completion boundary and capture `/tmp/Pip-iPhone17-simulator-smoke-done.png`.
7. Run the full iOS test, Widget generic iOS build, PrivacyInfo lint, and forbidden dependency scan. Record exact exit status and result bundle paths.
8. If the frontend repair is absent or any UI item fails, stop the node as `Blocked`/`Failed` with the screenshot and source location; do not change product code or mark the final delivery gate passed.

## Required reporting

Update `QA/PipV1TestMatrix.md` and `QA/PipV1AcceptanceReport.md` with the exact commands, screenshots, pass/fail state for SMR-01 through SMR-08, and any environment limitation. Do not update `.openteams/plan.md`; the plan owner records the node status.
