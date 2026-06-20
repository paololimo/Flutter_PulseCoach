# Story 12.1: WearOS Feasibility Spike

Status: done

## Story

As a developer,
I want to validate that `wear_plus` supports the required in-session display on WearOS,
so that we commit to WearOS implementation only if it is technically feasible within the project constraints.

## Acceptance Criteria

**AC1 — Basic WearOS build target created (ARCH13)**
Given `wear_plus` is integrated as a separate build target at `pulse_coach/wear/`
When `flutter build apk --debug` is run from `pulse_coach/wear/`
Then the build succeeds and produces a WearOS APK without errors

**AC2 — Basic Wear UI renders on emulator**
Given the WearOS APK from AC1 is installed on the `Wear_OS_Large_Round` emulator
When the emulator boots and the app launches
Then a screen with at least one text label and one tappable button is visible on the round 454×454 display

**AC3 — Spike outcome document written**
Given the spike is complete
When results are reviewed
Then a spike outcome document is written at `_bmad-output/implementation-artifacts/12-1-spike-outcome.md` covering:
- Feasibility verdict: **confirmed** or **deferred** with reasoning
- Flutter + `wear_plus` version used and any compatibility notes
- Build pipeline observations (build time, APK size, any issues encountered)
- Known gaps and risks for Stories 12.2–12.4 (if feasibility confirmed)
- If deferred: specific blocking reason and recommendation for Stories 12.2–12.4

## Tasks / Subtasks

- [x] **Task 1: Create `pulse_coach/wear/` sub-project** (AC1)
  - [x] Run `flutter create --platforms=android --org com.pulsecoach --project-name pulse_coach_wear pulse_coach/wear` to scaffold the project
  - [x] Add `wear_plus: ^1.2.4` to `pulse_coach/wear/pubspec.yaml` dependencies
  - [x] Delete the generated `test/` folder and boilerplate counter widget (this is a spike)
  - [x] Confirm `applicationId` in `pulse_coach/wear/android/app/build.gradle.kts` is `com.pulsecoach.pulse_coach_wear` (or update accordingly)

- [x] **Task 2: Implement minimal WearOS app** (AC2)
  - [x] Replace `pulse_coach/wear/lib/main.dart` with a minimal app using `WearApp` widget from `wear_plus`
  - [x] Create a single screen displaying: the text `"PulseCoach Wear"` and a `ElevatedButton` labelled `"Tap me"` that prints to debug console
  - [x] Confirm `WearApp` (not `MaterialApp`) is used as the root widget — this is required for proper WearOS round-screen rendering

- [x] **Task 3: Boot emulator and build + install** (AC1, AC2)
  - [x] Launch the `Wear_OS_Large_Round` AVD: `flutter emulators --launch Wear_OS_Large_Round`
  - [x] Poll until booted: `adb -s emulator-5554 shell getprop sys.boot_completed` returns `1`
  - [x] Resolve emulator id dynamically: `adb devices | grep emulator`
  - [x] Build APK: `flutter build apk --debug` from `pulse_coach/wear/`
  - [x] Install: `adb -s <emu_id> install -r pulse_coach/wear/build/app/outputs/flutter-apk/app-debug.apk`
  - [x] Launch: `adb -s <emu_id> shell monkey -p com.pulsecoach.pulse_coach_wear -c android.intent.category.LAUNCHER 1`

- [x] **Task 4: Screenshot and verify** (AC2)
  - [x] Take screenshot: `adb -s <emu_id> shell screencap -p /data/local/tmp/wear_spike_home_<yyyymmdd>.png`
  - [x] Pull: `adb -s <emu_id> pull /data/local/tmp/wear_spike_home_<yyyymmdd>.png /private/tmp/`
  - [x] Read the PNG and verify: text and button are visible; record PASS or FAIL with details
  - [x] Note: **overflow is expected and acceptable** — the main phone app is phone/tablet-oriented; running a wear-specific minimal app on the 454dp round screen should render correctly with `WearApp`

- [x] **Task 5: Write spike outcome document** (AC3)
  - [x] Create `_bmad-output/implementation-artifacts/12-1-spike-outcome.md` following the schema in AC3
  - [x] Record build output, APK size, emulator screenshot path, and feasibility verdict

## Dev Notes

### This is a Spike — Scope Boundaries

This story creates a **separate Flutter sub-project** at `pulse_coach/wear/` and validates the build pipeline. It does **not**:
- Modify any file in `pulse_coach/lib/` (zero phone-side changes)
- Add WearOS communication to the phone app (deferred to Story 12.2)
- Write unit tests (the deliverable is a running APK on the emulator + a written outcome)
- Create the full `wear/` architecture (just `main.dart` + `pubspec.yaml`)

The architecture specifies the full `pulse_coach/wear/` structure (with `session_display_page.dart`, `rest_display_page.dart`, `summary_display_page.dart`, `communication/phone_bridge.dart`) — these are targets for Stories 12.2–12.3, not this spike.

### `wear_plus` Package — What It Provides

`wear_plus` 1.2.4 (already in `pulse_coach/pubspec.yaml` line 57–58) provides:
- `WearApp` — root widget replacing `MaterialApp` for WearOS round-screen optimization
- `SwipeDismissPage` — swipe-to-dismiss navigation pattern for watch UIs
- `AmbientMode` — always-on display support

For the spike, only `WearApp` is needed. The `wear/` sub-project has its **own** `pubspec.yaml` and its own `wear_plus` dependency — the phone-side `pubspec.yaml` entry is for future bidirectional communication (Stories 12.2–12.4).

### Sub-Project vs. Module

The architecture spec (`architecture.md` line 820) shows `wear/` as a sibling of `lib/` and `test/`, i.e., `pulse_coach/wear/`. This is a separate Flutter project (own `pubspec.yaml`, own `android/` manifest), not a module inside the phone project. The spike creates this sub-project with `flutter create`.

### Emulator: Already Available

The `Wear_OS_Large_Round` AVD was created as part of **E11R-PREP** (done 2026-06-02 — recorded in CLAUDE.md Autonomous Emulator Testing section and action-item-ledger). Key facts:
- AVD id: `Wear_OS_Large_Round`
- Screen: 454×454 round, API 36 (Android 16), arm64
- `ro.build.characteristics = emulator,nosdcard,watch`
- After boot, emulator id is typically `emulator-5554` — **always resolve dynamically** via `adb devices | grep emulator`
- Use `/data/local/tmp` for screenshots (not `/sdcard` — `nosdcard` AVD)

Emulator first boot can take 1–2 minutes. Use a background poll:
```
adb -s emulator-5554 shell getprop sys.boot_completed
```
Loop until it returns `1`.

### Expected Overflow on Round Screen

CLAUDE.md notes explicitly: "the app is phone/tablet-oriented; running it as-is on this round 454dp watch is expected to overflow." This applies to the **phone app** — not to the `wear/` sub-project. The wear sub-project uses `WearApp` from `wear_plus`, which is designed for round-screen rendering. The minimal spike UI (single text + button) should render fine at 454×454. Document any overflow in the spike outcome.

### Build Pipeline Note

Run all `flutter` commands from `pulse_coach/wear/`, not from `pulse_coach/`:
```bash
cd pulse_coach/wear
flutter pub get
flutter build apk --debug
```

If the build fails with a minSdkVersion error, WearOS requires `minSdk 25` (Wear OS 2) or `minSdk 30` (Wear OS 3+). Update `pulse_coach/wear/android/app/build.gradle.kts` accordingly. The `Wear_OS_Large_Round` AVD runs API 36 so any minSdk ≤ 36 will work.

### E9-K1 Fire-Check (Ongoing Process Rule — Category B)

Triggered at story-creation for this story:
- **DI/lifecycle/cross-cutting review-patches**: Not applicable — zero phone-side code changes. Not fired.
- **Category A deliverable-debt with relative trigger**: `E11R-3` (tablet on-device verification) is hardware-gated and unrelated. `E10R-2` (non-UTC regression test) is triggered on Progress stories. `E10R-1` (release-build observability for DAO writes) is triggered on persistence stories. None fired for this spike.
- **Cubit/BLoC collection-index pre-flight (E7-P2)**: No Cubit/BLoC introduced. Not fired.

**E7.5-P1 fire-check** (Flutter deprecation pre-check for SDK-sensitive specs): **TRIGGERED.** This story touches plugin registration (`wear_plus` in a new sub-project pubspec) and a new build target. Checked: `wear_plus` 1.2.4 is compatible with Flutter 3.41.6 / Dart 3.11.4. No known deprecated APIs in the `WearApp` entry point as of the locked version.

### Category A Snapshot at Epic 12 Kickoff

Active (4/5): `E6-T7`, `E6-T8`, `E10R-1`, `E10R-2`. `E11R-3` (tablet verification) is hardware-gated and parked per the Epic 11 retro triage note. `CR112-002` (hardcoded cardio accent) remains a candidate but not yet formally added. This spike does not open or close any Category A items.

### `flutter analyze` Zero-Tolerance

The `wear/` sub-project is a new codebase — `flutter analyze` must pass with 0 issues before the story is marked done. The phone-project `flutter analyze` must also remain clean (it is not touched, so no regression risk, but verify with `flutter analyze` from `pulse_coach/`).

### Project Structure Notes

| Action | Path |
|---|---|
| CREATE new sub-project | `pulse_coach/wear/` (via `flutter create`) |
| CREATE wear app entry | `pulse_coach/wear/lib/main.dart` |
| CREATE wear pubspec | `pulse_coach/wear/pubspec.yaml` |
| NO CHANGES | Any file under `pulse_coach/lib/` |
| CREATE spike outcome | `_bmad-output/implementation-artifacts/12-1-spike-outcome.md` |

### References

- [Source: epics.md lines 1714–1728] Story 12.1 ACs and Epic 12 goal
- [Source: architecture.md lines 74, 249] WearOS via `wear_plus`, phone pushes session state to watch, early spike required
- [Source: architecture.md line 820] `pulse_coach/wear/` folder structure (separate target)
- [Source: project-context.md line 26] `wear_plus: latest pub.dev — WearOS companion (medium technical risk; spike required early)`
- [Source: project-context.md line 170] "WearOS spike: validate `wear_plus` feasibility before building session features that depend on watch sync"
- [Source: CLAUDE.md Autonomous Emulator Testing section] `Wear_OS_Large_Round` AVD facts, screenshot flow, emulator id resolution
- [Source: CLAUDE.md Autonomous Emulator Testing section] "the app is phone/tablet-oriented; running it as-is on this round 454dp watch is expected to overflow"
- [Source: pulse_coach/pubspec.yaml lines 57–58] `wear_plus: ^1.2.4` already present
- [Source: action-item-ledger.md Epic 11 Category B Sunset Review] E11R-PREP done (AVD created), Category A = 4/5 at Epic 11 retro

## Dev Agent Record

### Agent Model Used

Codex GPT-5

### Implementation Plan

- Scaffold a separate Android-only Flutter project at `pulse_coach/wear/` with its own dependency graph.
- Add `wear_plus 1.2.4`, replace the generated counter app with a minimal Wear-specific root, and keep phone-side `pulse_coach/lib/` untouched.
- Validate the spike through analyzer, debug APK build, emulator install/launch, screenshot inspection, and full phone-project regression tests.
- Record the feasibility verdict and compatibility findings in the spike outcome document.

### Debug Log References

- `flutter create --platforms=android --org com.pulsecoach --project-name pulse_coach_wear pulse_coach/wear` completed successfully.
- `flutter pub add wear_plus:^1.2.4` resolved `wear_plus 1.2.4`.
- `flutter analyze` from `pulse_coach/wear/` passed with no issues.
- `flutter build apk --debug` from `pulse_coach/wear/` passed; final rebuild time `real 22.37s`, APK at `pulse_coach/wear/build/app/outputs/flutter-apk/app-debug.apk`.
- `Wear_OS_Large_Round` launched successfully via direct Android SDK emulator binary after `flutter emulators --launch Wear_OS_Large_Round` returned without leaving a process running.
- `adb -s emulator-5554 shell getprop sys.boot_completed` returned `1`.
- `adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk` passed.
- `adb -s emulator-5554 shell monkey -p com.pulsecoach.pulse_coach_wear -c android.intent.category.LAUNCHER 1` launched the app.
- Screenshot `/private/tmp/wear_spike_home_20260603.png` visually verified `PulseCoach Wear` text and `Tap me` button on a 454x454 round display.
- `flutter analyze` from `pulse_coach/` passed with no issues.
- `flutter test` from `pulse_coach/` passed: 759/759 tests.

### Completion Notes List

- Created the separate WearOS spike sub-project at `pulse_coach/wear/`.
- Added `wear_plus: ^1.2.4` to the Wear sub-project and confirmed the resolved version is `1.2.4`.
- Replaced the generated counter app with a minimal Wear UI showing `PulseCoach Wear` and a tappable `Tap me` button.
- Confirmed `applicationId = "com.pulsecoach.pulse_coach_wear"`.
- Verified debug APK build, install, launch, and screenshot on `Wear_OS_Large_Round`.
- Wrote `_bmad-output/implementation-artifacts/12-1-spike-outcome.md` with confirmed feasibility and known risks for Stories 12.2-12.4.
- Compatibility note: `wear_plus 1.2.4` does not export a package-provided `WearApp`; the spike uses a local `WearApp` root wrapper backed by `WatchShape` and `AmbientMode` from `wear_plus`.

### File List

- `_bmad-output/implementation-artifacts/12-1-spike-outcome.md`
- `_bmad-output/implementation-artifacts/12-1-wearos-feasibility-spike.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/wear/.gitignore`
- `pulse_coach/wear/.metadata`
- `pulse_coach/wear/README.md`
- `pulse_coach/wear/analysis_options.yaml`
- `pulse_coach/wear/android/.gitignore`
- `pulse_coach/wear/android/app/build.gradle.kts`
- `pulse_coach/wear/android/app/src/debug/AndroidManifest.xml`
- `pulse_coach/wear/android/app/src/main/AndroidManifest.xml`
- `pulse_coach/wear/android/app/src/main/kotlin/com/pulsecoach/pulse_coach_wear/MainActivity.kt`
- `pulse_coach/wear/android/app/src/main/res/drawable-v21/launch_background.xml`
- `pulse_coach/wear/android/app/src/main/res/drawable/launch_background.xml`
- `pulse_coach/wear/android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `pulse_coach/wear/android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `pulse_coach/wear/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `pulse_coach/wear/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `pulse_coach/wear/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `pulse_coach/wear/android/app/src/main/res/values-night/styles.xml`
- `pulse_coach/wear/android/app/src/main/res/values/styles.xml`
- `pulse_coach/wear/android/app/src/profile/AndroidManifest.xml`
- `pulse_coach/wear/android/build.gradle.kts`
- `pulse_coach/wear/android/gradle.properties`
- `pulse_coach/wear/android/gradle/wrapper/gradle-wrapper.properties`
- `pulse_coach/wear/android/settings.gradle.kts`
- `pulse_coach/wear/lib/main.dart`
- `pulse_coach/wear/pubspec.lock`
- `pulse_coach/wear/pubspec.yaml`

### Change Log

- 2026-06-03: Created WearOS spike sub-project, implemented minimal Wear UI, verified build/install/screenshot on `Wear_OS_Large_Round`, and documented confirmed feasibility with `wear_plus 1.2.4` compatibility caveat.

### Review Findings

_Code review 2026-06-03 (3-layer adversarial: Blind Hunter, Edge Case Hunter, Acceptance Auditor). All 3 ACs PASS; the `WearApp`-not-in-`wear_plus-1.2.4` deviation is the expected spike outcome and is documented. 0 decision-needed, 1 patch, 5 defer, 6 dismissed as noise._

- [x] [Review][Patch] Replace `flutter create` boilerplate metadata (pubspec description + launcher label) [pulse_coach/wear/pubspec.yaml:2, pulse_coach/wear/android/app/src/main/AndroidManifest.xml:4] — fixed 2026-06-03: description → "PulseCoach WearOS companion app.", launcher label → "PulseCoach"
- [x] [Review][Defer] Manifest lacks explicit WearOS watch-feature / standalone declarations [pulse_coach/wear/android/app/src/main/AndroidManifest.xml] — deferred to 12.2; `android.hardware.type.watch` is provided transitively by the `wear_plus` library manifest merge, so the spike still installs as a watch app
- [x] [Review][Defer] `minSdk` uses the Flutter default (21) instead of a Wear OS-appropriate floor [pulse_coach/wear/android/app/build.gradle.kts] — deferred to 12.2; build + install on the API 36 AVD verified PASS, but 12.2 should pin minSdk explicitly (Wear OS 3+ expects ≥30)
- [x] [Review][Defer] Minimal UI is not scrollable and has no textScale clamp — overflow + round-bezel clipping risk with real content / large accessibility font [pulse_coach/wear/lib/main.dart:55] — deferred to 12.2–12.4; static spike labels render PASS at 454×454
- [x] [Review][Defer] Ambient frame is not burn-in / low-bit safe [pulse_coach/wear/lib/main.dart:33] — deferred to 12.2–12.4; ambient correctness is out of spike scope (`wear_plus 1.2.4` hardcodes `AmbientDetails(false, false)`)
- [x] [Review][Defer] `AmbientMode`/`WatchShape` builders discard their `child` → full `MaterialApp` rebuild on every ambient toggle [pulse_coach/wear/lib/main.dart:15] — deferred; low-priority efficiency note for the always-on path
