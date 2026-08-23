# Pip — v1 Plan

A cute kegel reminder with a 48-second guided squeeze.

This file is the frozen product plan from `/grill-me`. It is **not** an implementation. Do not write Swift, generate assets, or open Xcode until this plan is executed on purpose.

**Working directory:** Windows (this machine). **Compile / Simulator / App Store:** later, on a Mac.

---

## 1. Product freeze

| Item | Decision |
|------|----------|
| What it is | Daily habit tool, not medical / rehab. No efficacy claims. No HealthKit. |
| Platform | Native iOS SwiftUI + watchOS. Paid App Store download **USD 0.99**. No IAP, ads, account, or network. |
| Storefront | All regions **except mainland China**. English only. American copy, UI, animation, mascot. |
| Category | Health & Fitness, age **4+**. |
| Brand | App **Pip**. Mascot **Pip**. Subtitle *Kegel reminders*. |
| Public words | Lead with **Kegels**. Explain with *pelvic floor*. Never anal / 提肛 on notifications, widgets, watch, or store listing. |
| Voice | Unisex. Friendly, lightly playful. No dirty jokes. Not clinical. |
| iPhone home | One-screen state machine: idle → session → done. Settings as sheet. Calendar is a pushed page, not a tab. |
| Session | Lift 3s → release 3s × 8 ≈ 48s. No hold phase in v1. Silent by default. |
| Haptics | Light on lift/release, success on complete. Reduce Motion: fade instead of character cycle; haptics stay. |
| First launch | No multi-page onboarding. One short sheet before first Start. Ask notification permission **after** the first completed round. |
| Reminders | Local only. Weekdays 9:00 AM / 1:00 PM / 8:00 PM (device TZ). Three slots, editable, weekend optional. Respect Focus. |
| Stats | Today’s count on home. Month calendar + **streak**. Tap a day for that day’s count. No share. |
| Watch | Independent 48s haptic round + ring. Complications: today’s count / next reminder. **No** character frame animation. |
| Widget | Home-screen **small** only: count + next reminder + Pip. Tap opens app. No start button. No lock-screen widget. No Live Activity. Pip uses 2–3 stills (idle / waiting / done today). |
| Look | Clean, light, slightly funny. Mint + warm apricot. Pip = round droplet with a simple face; squeezes taller/thinner on lift. |
| iPhone motion | 8–12 looping frames, SwiftUI swaps on the metronome. |
| Engineering | iOS 17+, watchOS 10. SwiftUI + Observation. One Xcode project, three targets (iPhone, Watch, Widget). App Group snapshot. On-device only. |
| Paid app | Paid upfront. StoreKit IAP is **out of v1**. Privacy policy URL required for review. |

### Explicit defaults (accepted unless changed later)

1. Portrait only. iPad runs the iPhone layout (no iPad UI).
2. Leaving mid-session pauses. Incomplete rounds do not mark the calendar.
3. No iCloud. No migrate-to-new-phone story in v1.
4. Short English privacy page (on-device data only). Host a public URL before submit.
5. Watch complications: circular + rectangular first.
6. App Icon: mint field + Pip face.
7. Dark Mode supported; frames still read.

### Out of v1

Account, cloud, leaderboards, HealthKit, Live Activity, medium widget start button, lock-screen widget, spoken cues, default metronome sound, multi-page onboarding, unlimited reminder slots, anatomy art, medical claims, mainland China store, Chinese UI, subscriptions, IAP, ads, social share, backend/API.

---

## 2. Why there is no backend

v1 is a local metronome + local notifications + App Group snapshot.

Do **not** install chat SDKs, REST/client skills, CloudKit, or auth skills for this version. They would pull the design toward a server the product explicitly does not have.

If a later version adds accounts or sync, then revisit: `ios-networking`, `cloudkit`, `authentication` (Sign in with Apple). Not before.

---

## 3. Skills already on this Grok (global)

These live under `~/.grok/skills/` or bundled Grok skills. Use them; do not reinstall.

| When | Skill | Job for Pip |
|------|--------|-------------|
| Now (done) | `grill-me` / `grilling` | Requirement tree. This plan is the output. |
| After this plan | `design` (`/design`) | SwiftUI architecture doc + PR plan. |
| After design | `/plan` | Implementation plan against the empty repo. |
| Visuals | `imagine` | Canonical Pip still. |
| Visuals | `game-asset-core` | Isolated subject, flat keyable background, engine-ready defaults. |
| Visuals | `game-character-consistency` | Same Pip across idle / lift / release / done / wait. |
| Visuals | `game-animation-frames` | Video-first 8–12 frame squeeze cycle. |
| Visuals | `game-ui-icons` | App Icon set, start/done glyphs. No lettering on icons. |
| Code (Mac) | `implement` (`/implement`) | Implement → review → fix. |
| Code (Mac) | `review` | Diff / PR review. |
| Optional | `execute-plan` | If `/design` emits a PR DAG. |
| Optional | `create-skill` | Only if we later wrap a Pip-specific workflow. |

Do not use: `game-tilesets`, Lingxing, SellerSprite, VOC, WeCom.

---

## 4. Skills to install globally (internet, Agent Skills format)

Install into the **user** Grok skill root so every project can see them:

`C:\Users\bonsen\.grok\skills\`
(or `$GROK_HOME/skills` if set)

Third-party skills are not endorsements. Read `SKILL.md` before installing. Prefer MIT / Apache. Do **not** dump an 86-skill pack into context — install only the rows below.

Directory of Apple skills: [twostraws/Swift-Agent-Skills](https://github.com/twostraws/swift-agent-skills).

### 4.1 Install in this order (v1)

```text
# SwiftUI (Paul Hudson — Hacking with Swift)
npx skills add https://github.com/twostraws/swiftui-agent-skill --skill swiftui-pro

# SwiftData (local store; no CloudKit)
npx skills add https://github.com/twostraws/SwiftData-Agent-Skill --skill swiftdata-pro

# Swift Testing (metronome + reminder scheduler)
npx skills add https://github.com/twostraws/Swift-Testing-Agent-Skill --skill swift-testing-pro

# Native-feeling custom views (session ring, Pip stage)
npx skills add https://github.com/alexanderwe/swiftui-native-component-design-skill --skill swiftui-native-component-design

# WidgetKit + watch complications
npx skills add https://github.com/n0an/Widgets-Agent-Skill --skill widgets
npx skills add https://github.com/dpearson2699/swift-ios-skills --skill widgetkit
npx skills add https://github.com/rshankras/claude-code-apple-skills --skill watchOS

# Local notifications (not APNs)
npx skills add https://github.com/dpearson2699/swift-ios-skills --skill push-notifications

# Haptics
npx skills add https://github.com/Prisma-Labs-Dev/apple-skills --skill corehaptics

# Accessibility + App Store nutrition labels (Reduce Motion, VoiceOver, Larger Text)
npx skills add https://github.com/PasqualeVittoriosi/swift-accessibility-skill --skill swift-accessibility-skill

# HIG (iPhone + Watch)
npx skills add https://github.com/Prisma-Labs-Dev/apple-skills --skill hig
npx skills add https://github.com/rshankras/claude-code-apple-skills --skill ui-review

# App Store listing / review / ASO (English, US habits)
npx skills add https://github.com/TimBroddin/skills --skill app-store-aso
npx skills add https://github.com/dpearson2699/swift-ios-skills --skill app-store-optimization
npx skills add https://github.com/dpearson2699/swift-ios-skills --skill app-store-review
npx skills add https://github.com/JustinPerea/app-store-review-skill --skill app-store-review-skill

# Connect / TestFlight / metadata (when a Mac + Apple Developer account exist)
npx skills add https://github.com/rorkai/app-store-connect-cli-skills
```

If `npx skills` does not target Grok, copy each skill folder to `~/.grok/skills/<name>/` (must contain `SKILL.md`). Same pattern as `grill-me`.

### 4.2 What each extra skill is for (Pip mapping)

**SwiftUI / front-end**

| Skill | Source | Use on Pip |
|-------|--------|------------|
| `swiftui-pro` | [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) | Navigation, `@Observable`, animation, VoiceOver, deprecated API. Primary SwiftUI skill. |
| `swiftui-native-component-design` | [alexanderwe/…](https://github.com/alexanderwe/swiftui-native-component-design-skill) | Design `PipStage`, session ring, start button like system controls. |
| `swiftui-animation` | [dpearson2699/swift-ios-skills](https://github.com/dpearson2699/swift-ios-skills) | Optional extra: springs / `PhaseAnimator` if we add non-frame motion. |
| `swiftui-patterns` | same pack | State ownership for the home state machine. |
| `hig` | [Prisma-Labs-Dev/apple-skills](https://github.com/Prisma-Labs-Dev/apple-skills) | US-familiar layout, typography, Watch glanceability. |
| `ui-review` | [rshankras/claude-code-apple-skills](https://github.com/rshankras/claude-code-apple-skills) | HIG + Dynamic Type pass before screenshots. |
| `writing-for-interfaces` | [andrewgleave/skills](https://github.com/andrewgleave/skills) | Optional: English microcopy (Start, Next kegel, Streak). |

**Watch / widget / notifications / haptics**

| Skill | Source | Use on Pip |
|-------|--------|------------|
| `watchOS` | rshankras | Independent Watch session, Watch Connectivity, complications. **Do not** follow HealthKit workout paths. |
| `widgets` | [n0an/Widgets-Agent-Skill](https://github.com/n0an/Widgets-Agent-Skill) | Small family, App Group snapshot, tinted Home Screen, **no** Live Activity, **no** interactive start button. |
| `widgetkit` | dpearson2699 | Timeline provider; still-frame Pip states. |
| `push-notifications` | dpearson2699 | **Local** `UNCalendarNotificationTrigger` only. Ignore APNs chapters. |
| `corehaptics` | Prisma-Labs-Dev | Map lift / release / done to `CHHapticPattern`; Watch uses `WKInterfaceDevice` / SwiftUI sensory feedback. |

**Data / tests / architecture (still “front-end app”, no server)**

| Skill | Source | Use on Pip |
|-------|--------|------------|
| `swiftdata-pro` | [twostraws/SwiftData-Agent-Skill](https://github.com/twostraws/SwiftData-Agent-Skill) | On-device models: sessions, reminder slots, streak. **Disable CloudKit**. |
| `swift-testing-pro` | [twostraws/Swift-Testing-Agent-Skill](https://github.com/twostraws/Swift-Testing-Agent-Skill) | Metronome phases, streak math, next-fire time. |
| `swift-architecture` | dpearson2699 | Confirm MV + `@Observable`. Do **not** adopt TCA. |
| `ios-simulator` | dpearson2699 or [conorluddy/ios-simulator-skill](https://github.com/conorluddy/ios-simulator-skill) | Mac-only: simctl, notification simulation. |

**App Store (listing is “front of house”, not a backend)**

| Skill | Source | Use on Pip |
|-------|--------|------------|
| `app-store-aso` | [TimBroddin/skills](https://github.com/TimBroddin/skills) | Name 30 / subtitle 30 / keyword 100, English ASO. Keywords: kegel, pelvic floor, reminder, habit — never anal. |
| `app-store-optimization` | dpearson2699 | Screenshot story: home Pip → 48s session → Watch → widget. |
| `app-store-review` | dpearson2699 | Guideline 1.4 / 5.1.1: wellness not medical; privacy manifest; permission strings. |
| `app-store-review-skill` | [JustinPerea/app-store-review-skill](https://github.com/JustinPerea/app-store-review-skill) | Scan project for ITMS-91053 (`PrivacyInfo.xcprivacy`), vague purpose strings. |
| `swift-accessibility-skill` | [PasqualeVittoriosi/…](https://github.com/PasqualeVittoriosi/swift-accessibility-skill) | Nine Accessibility Nutrition Labels. Pip must pass Reduce Motion + VoiceOver + Larger Text. |
| `app-store-connect-cli-skills` | [rorkai/…](https://github.com/rorkai/app-store-connect-cli-skills) | Create app record, metadata, screenshots, TestFlight, submit. Needs Apple Developer Program + Mac. |
| Paid price | App Store Connect price tier | **USD 0.99 paid app**, not StoreKit. Skip `storekit` until IAP exists. |

### 4.3 Matt Pocock chain (optional, after this `plan.md`)

Already have `grill-me`. If we want his full build chain instead of Grok `/design` + `/implement`:

```text
npx skills add mattpocock/skills --skill to-spec
npx skills add mattpocock/skills --skill to-tickets
npx skills add mattpocock/skills --skill tdd
npx skills add mattpocock/skills --skill code-review
```

Pip mapping: metronome + streak + reminder scheduling are the TDD seams. UI animation is a poor TDD seam — test the engine, not the frames.

### 4.4 Do not install for v1

| Skill | Why not |
|-------|---------|
| `healthkit` | Frozen: not a medical app. |
| `storekit` / RevenueCat | Paid download, not IAP. |
| `activitykit` | No Live Activity. |
| `cloudkit` / `ios-networking` / Stream chat | No backend. |
| `authentication` / Sign in with Apple | No account. |
| `ios-localization` | English-only v1. Revisit for Spanish. |
| Capacitor / site-to-app packs | Native SwiftUI only. |

---

## 5. Work sequence (still not executing)

### Phase A — this Windows machine

1. Keep this `plan.md` as source of truth.
2. Install §4.1 skills into `~/.grok/skills/` (global).
3. `/design` from this file → architecture + PR plan.
4. Visual pipeline (Grok Imagine skills):
   - Canonical Pip (front), mint/apricot, face, keyable background.
   - Consistency set: idle, lift, release, done, widget-wait.
   - `game-animation-frames`: in-place squeeze loop, locked camera, 8–12 frames.
   - Widget stills (3) + App Icon (no text).
5. English store draft via `app-store-aso` (do not submit): name, subtitle, keywords, description, privacy copy, medical disclaimer.

### Phase B — Mac + Apple Developer Program ($99/year, separate from the $0.99 price)

6. Xcode project: iOS App + watchOS App + Widget Extension + App Group.
7. `/implement` in slices, with `swiftui-pro` + `widgets` + `watchOS` loaded:
   1. Metronome engine (Swift Testing).
   2. Home state machine + Pip frames.
   3. Local notifications + three slots.
   4. Calendar + streak.
   5. Watch haptic session + complications.
   6. Small widget + App Group.
   7. Settings, disclaimer, Reduce Motion.
   8. `PrivacyInfo.xcprivacy` + accessibility nutrition.
8. Simulator: session, Reduce Motion, VoiceOver, widget three states, Watch haptics, Focus.
9. `app-store-review-skill` scan → TestFlight → App Review.

### Suggested module cut (for `/design`)

```
App
 ├─ Home/          state machine + Pip stage
 ├─ Exercise/      metronome (pure Swift)
 ├─ Reminder/      auth, schedule, deep link
 ├─ Calendar/      month + streak
 ├─ Watch/         session + complications
 ├─ Widget/        small family + 3 stills
 ├─ Settings/      slots, haptics, disclaimer, privacy
 └─ DesignSystem/  color, type, haptics, motion tokens
```

---

## 6. App Store notes (English / US)

- Listing sentence: *A cute kegel reminder with a 48-second guided squeeze.*
- Category Health & Fitness is correct; copy must stay habit, not treatment.
- 4+: no sexual content, no medical device language.
- Permission string example: “Pip sends reminders for your kegel sessions.” Ask after first success.
- Paid app still needs a **privacy policy URL** (data stays on device).
- Exclude mainland China in App Store Connect availability.
- Screenshots should look like a US wellness habit app (pastel, Pip, short session), not a clinic.

---

## 7. Next action

1. Install the §4.1 skill set globally.
2. Run `/design` against this file.
3. Only then generate Pip art / Swift.

Do not start Xcode or Imagine until those two steps are requested.
