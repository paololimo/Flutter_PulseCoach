# Story 12.2: In-Session WearOS Display

Status: done

## Story

As a user with a WearOS watch,
I want my watch to display the current exercise step, session timer, and live HR during an active session,
so that I can follow the session without holding my phone.

## Acceptance Criteria

**AC1 — In-session state displayed on watch**
Given the WearOS companion is installed and a session is active on the phone
When the in-session state is broadcast via `wear_plus`
Then the WearOS display shows: current step name, session countdown timer, and live HR (when available) (FR40)

**AC2 — Timer syncs within 1 second**
Given the WearOS display is showing an active session
When the step timer counts down on the phone
Then the timer on the watch updates in sync with the phone timer (within 1 second accuracy)

**AC3 — Step transition reflected within 1 second**
Given the WearOS companion is connected
When a step transition occurs on the phone
Then the watch display updates to the new step within 1 second of the transition

**AC4 — Silent degradation when watch not connected**
Given the phone session is active but no WearOS device is connected
When the phone attempts to send session state
Then the phone session continues without error — no crash, no error state, no visible disruption

**AC5 — Session end clears watch display**
Given the WearOS companion is connected and showing an active session
When the session completes or is abandoned on the phone
Then the watch display returns to its idle/home state

## Tasks / Subtasks

- [x] **Task 1: Pin minSdk in wear build.gradle.kts** (AC1, pre-requisite)
  - [x] Open `pulse_coach/wear/android/app/build.gradle.kts`
  - [x] Set `minSdk = 30` (Wear OS 3+ minimum; API 36 AVD already above this)
  - [x] Verify build still passes: `flutter build apk --debug` from `pulse_coach/wear/`

- [x] **Task 2: Implement phone-side `WearBridgeService`** (AC1, AC2, AC3, AC4, AC5)
  - [x] Create `pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart`
  - [x] Implement `WearBridgeService` with:
    - `start(Stream<InSessionState> stateStream)` — subscribes to cubit stream, pushes updates to watch
    - `stop()` — cancels subscription, sends `/pulsecoach/session/end` to watch
    - Private `_sendToWatch(String path, Map<String, dynamic> payload)` — discovers nodes via `Wear.instance.getNodes()`, sends JSON-encoded `Uint8List` to each node; swallows all `Exception`s (silent degradation)
  - [x] Message paths:
    - `/pulsecoach/session` — periodic state updates: `{"step":"<title>","secs":<int>,"hr":<int?>}` (omit `hr` key if null)
    - `/pulsecoach/session/end` — session terminated: `{"done":true}`
  - [x] Send on every `InSessionState` emission (covers AC2 + AC3: 1-second timer tick + step transition both emit state → watch receives within 1 second)
  - [x] When `isComplete` or `isAbandoned` becomes true, call `stop()` (sends end message)
  - [x] Add `wear_plus: ^1.2.4` to `pulse_coach/pubspec.yaml` dependencies if not already present (check line 57)

- [x] **Task 3: Wire `WearBridgeService` into `InSessionPage`** (AC1–AC5)
  - [x] In `InSessionPage._InSessionPageState`, declare `WearBridgeService? _wearBridge`
  - [x] In `_onCountdownComplete()`, after `cubit` is created: `_wearBridge = WearBridgeService()..start(cubit.stream)`
  - [x] In `dispose()`, call `_wearBridge?.stop()` before `_cubit?.close()`

- [x] **Task 4: Implement `phone_bridge.dart` on the watch** (AC1, AC2, AC3, AC5)
  - [x] Create `pulse_coach/wear/lib/communication/phone_bridge.dart`
  - [x] Expose a `Stream<SessionWearState>` via `PhoneBridge.states` (singleton or static getter)
  - [x] `SessionWearState` is a plain Dart class with `stepName`, `secondsRemaining`, `heartRate` (nullable), `isEnded`
  - [x] Listen to `Wear.instance.receiveMessages()`, parse JSON payload by path:
    - `/pulsecoach/session` → emit active `SessionWearState`
    - `/pulsecoach/session/end` → emit `SessionWearState.ended()`
  - [x] Ignore unknown paths silently
  - [x] Expose `void dispose()` to cancel the subscription

- [x] **Task 5: Implement `SessionDisplayPage` on the watch** (AC1, AC2, AC3)
  - [x] Create `pulse_coach/wear/lib/session_display_page.dart`
  - [x] `SessionDisplayPage` takes no constructor args; uses `StreamBuilder<SessionWearState>` on `PhoneBridge.states`
  - [x] Layout (round-screen aware via `WatchShape`):
    - Top section: step name (`Text`, max 2 lines, center-aligned, overflow ellipsis, `textScaler: TextScaler.noScaling` to prevent burn-in clip)
    - Center: countdown timer formatted as `MM:SS` (JetBrains Mono or monospace font fallback)
    - Bottom: HR label `"♥ <value> bpm"` if available, else invisible `SizedBox`
  - [x] Padding: `EdgeInsets.all(shape == WearShape.round ? 40 : 24)` (extra inset for round bezel; 32 used in spike caused clipping — use 40 for text-heavy content)
  - [x] When `isEnded`, widget signals caller to pop (via a `VoidCallback onSessionEnded` passed in or via navigator key)

- [x] **Task 6: Create `rest_display_page.dart` placeholder** (Architecture compliance ARCH13)
  - [x] Create `pulse_coach/wear/lib/rest_display_page.dart`
  - [x] Minimal implementation: same layout structure as `SessionDisplayPage` but with a distinct "REST" heading; used when step name contains "riposo" or "recupero" (Italian) — OR left as a stub for Story 12.3/12.4 to populate
  - [x] The file must exist per architecture spec; full styling deferred to 12.3

- [x] **Task 7: Update `main.dart` to route to session display** (AC1, AC5)
  - [x] Update `pulse_coach/wear/lib/main.dart`
  - [x] Replace static `PulseCoachWearHome` as `home` with a `_WearRoot` `StatefulWidget`
  - [x] `_WearRoot` listens to `PhoneBridge.states` stream via `StreamBuilder`
  - [x] When latest state is active (not ended and not null) → show `SessionDisplayPage`
  - [x] Otherwise → show `PulseCoachWearHome` (existing idle screen)
  - [x] Initialize `PhoneBridge` in `_WearRoot.initState`, dispose in `_WearRoot.dispose`

- [x] **Task 8: Tests** (project testing standards)
  - [x] Unit test for message serialization: `WearBridgeService` emits correct JSON for a given `InSessionState` (mock `Wear.instance` via dependency injection or constructor injection of a `WearMessagingClient` abstraction)
  - [x] Unit test for `PhoneBridge` message parsing: valid `/pulsecoach/session` JSON → correct `SessionWearState`; unknown path → no emission; malformed JSON → no crash
  - [x] Widget test for `SessionDisplayPage`: given a fake `Stream<SessionWearState>` with one active state, verify step name, MM:SS timer, and HR label render correctly
  - [x] Widget test: when `isEnded` state received, verify callback fires (or navigate back to home)
  - [x] `flutter analyze` from `pulse_coach/wear/` must pass with 0 issues
  - [x] `flutter test` from `pulse_coach/` must pass (regression guard; wear has no test suite of its own)

- [x] **Task 9: Emulator verification** (AC1–AC5)
  - [x] Launch `Wear_OS_Large_Round`: use direct SDK binary (not `flutter emulators --launch` which exits immediately) — see Dev Notes
  - [x] Build + install wear APK
  - [x] Launch phone app (`flutter run -d 5200b2255ab59429` or phone emulator)
  - [x] Start a session on the phone; confirm watch shows step/timer/HR
  - [x] Wait for step transition; confirm watch updates within 1 second (AC3)
  - [x] Complete session; confirm watch returns to idle (AC5)
  - [x] Screenshot each state; pull to `/private/tmp/`

## Dev Notes

### `wear_plus 1.2.4` Compatibility — Critical Caveat from Spike

`wear_plus 1.2.4` does **NOT** export a `WearApp` widget (documented in 12.1 spike outcome). Use:
- `WatchShape` — shape-aware layout builder (gives `WearShape.round` or `WearShape.rectangle`)
- `AmbientMode` — ambient display mode (gives `WearMode.active` or `WearMode.ambient`)
- `Wear.instance` — Wearable Message API for phone↔watch communication

The existing `pulse_coach/wear/lib/main.dart` already uses this pattern correctly — extend it, do not replace with a `WearApp` root.

### `Wear.instance` Communication API

```dart
// Phone: discover paired watch nodes
final nodes = await Wear.instance.getNodes();  // List<WearNode> — may be empty
// Phone: send a message
await Wear.instance.sendMessage(node.id, '/pulsecoach/session', utf8.encode(jsonString));

// Watch: receive messages
Wear.instance.receiveMessages().listen((MessageReceivedEvent event) {
  // event.path, event.data (Uint8List)
  final payload = jsonDecode(utf8.decode(event.data));
});
```

`WearNode` exposes `.id` (String) and `.displayName`. If `getNodes()` returns empty, no watch is connected — skip the send silently (AC4).

### Message Protocol

All messages use JSON-encoded UTF-8 `Uint8List`.

| Path | Direction | Payload |
|---|---|---|
| `/pulsecoach/session` | Phone → Watch | `{"step":"<title>","secs":<int>,"hr":<int>}` — `hr` key omitted if null |
| `/pulsecoach/session/end` | Phone → Watch | `{"done":true}` |

Send on **every `InSessionState` emission** — the 1-second `Timer.periodic` tick produces one emission per second, satisfying AC2. Step transitions also produce an emission, satisfying AC3. No extra timer needed.

### Silent Degradation (AC4)

Wrap **all** `Wear.instance` calls in `try/catch`. Never propagate exceptions to the caller. The `WearBridgeService` must not affect the phone session lifecycle — treat it as a best-effort side channel. Pattern:

```dart
Future<void> _sendToWatch(String path, Map<String, dynamic> payload) async {
  try {
    final nodes = await Wear.instance.getNodes();
    if (nodes.isEmpty) return;
    final data = utf8.encode(jsonEncode(payload)) as Uint8List;
    for (final node in nodes) {
      await Wear.instance.sendMessage(node.id, path, data);
    }
  } catch (_) {
    // Silent degradation — watch is optional
  }
}
```

### `wear_plus` on the Phone Side

`pulse_coach/pubspec.yaml` already contains `wear_plus: ^1.2.4` (line 57–58 per 12.1 dev notes). Do **not** add it again. Import it in `wear_bridge_service.dart` with `import 'package:wear_plus/wear_plus.dart';`.

### Timer Format

`secondsRemaining` is an `int`. Format as `MM:SS`:
```dart
String _formatTime(int secs) {
  final m = secs ~/ 60;
  final s = secs % 60;
  return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
}
```

### Round-Screen Padding

From the spike: `shape == WearShape.round ? 32 : 24` was used for the minimal single-line home. For `SessionDisplayPage` with multi-line text content, use `40` for round to avoid bezel clipping at the corners. The 454×454 display with ~55dp corner radius starts clipping content at ~32dp from the edge.

### `WearBridgeService` Architecture

`WearBridgeService` lives in `lib/features/session/presentation/utils/` (alongside `haptic_service.dart`, `live_hr_service.dart`) because it is a presentation-layer side effect — no domain logic, no repository, just a fire-and-forget channel. It does not need `@injectable` registration; `InSessionPage` instantiates it directly (same pattern as `VibrationHapticService`).

### Emulator Launch — Critical Note

`flutter emulators --launch Wear_OS_Large_Round` exits without leaving a process. Use the direct Android SDK binary instead:

```bash
/Users/paololimonta/Library/Android/sdk/emulator/emulator -avd Wear_OS_Large_Round -no-snapshot -no-audio &
```

Then poll: `adb -s emulator-5554 shell getprop sys.boot_completed` until `1`. Always resolve the emulator id dynamically: `adb devices | grep emulator`.

### WearOS Integration Testing Constraints

Full phone+watch integration testing requires both devices to be paired (Wearable API enforces pairing). On emulators, Android Emulator Pairing Assistant is needed. For Story 12.2, the emulator verification (Task 9) is the integration check. Unit/widget tests cover logic; emulator covers the live channel.

Screenshots: use `/data/local/tmp` (not `/sdcard` — the AVD is `nosdcard`).

### Phone App: `wear_plus` Registration

Check whether `wear_plus` needs initialization on the phone side before `getNodes()` is called. `wear_plus` is a plugin — it auto-registers its `MethodChannel` via Flutter's plugin system. No explicit `Wear.instance.init()` call is needed in `wear_plus 1.2.4`.

### E9-K1 Fire-Check

Triggered at story-creation for 12.2:

**DI/lifecycle/cross-cutting review-patches:** `WearBridgeService` is presentation-layer, instantiated directly in `InSessionPage` (not via `getIt`) — same pattern as `VibrationHapticService`. No DI registration needed. `PhoneBridge` on watch side is a singleton-lite using a static stream — no container involved. Not fired.

**Category A deliverable-debt with relative triggers:**
- `E10R-1` (release-build observability for DAO writes) — not triggered by this story (no new DAO writes)
- `E10R-2` (non-UTC regression for progress buckets) — not triggered (no Progress feature touches)
- `E6-T7`, `E6-T8` — not triggered (no exercise catalog changes)

Not fired.

**Cubit/BLoC collection-index pre-flight (E7-P2):** `WearBridgeService` observes `InSessionCubit.stream` but has no index-based state of its own. `SessionDisplayPage` is a simple display widget with no collection index. Not fired.

### `minSdk` Fix (12.1 Review Defer)

Story 12.1 code review deferred: "pin `minSdk` to ≥ 30 (Wear OS 3+)" to 12.2. Task 1 closes this defer. The `Wear_OS_Large_Round` AVD runs API 36; any `minSdk ≤ 36` installs. Setting `minSdk = 30` is safe.

### Category A Snapshot

Active at Epic 12 start (4/5): `E6-T7`, `E6-T8`, `E10R-1`, `E10R-2`. Story 12.2 does not open or close any Category A items.

### Project Structure Notes

| Action | Path |
|---|---|
| CREATE | `pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart` |
| UPDATE | `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` |
| CREATE | `pulse_coach/wear/lib/communication/phone_bridge.dart` |
| CREATE | `pulse_coach/wear/lib/session_display_page.dart` |
| CREATE | `pulse_coach/wear/lib/rest_display_page.dart` (placeholder per ARCH13) |
| UPDATE | `pulse_coach/wear/lib/main.dart` |
| UPDATE | `pulse_coach/wear/android/app/build.gradle.kts` (minSdk = 30) |
| NO CHANGES | `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart` |
| NO CHANGES | `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart` |
| NO CHANGES | Any other `pulse_coach/lib/` file |

### References

- [Source: epics.md lines 1730–1748] Story 12.2 ACs and FR40
- [Source: architecture.md line 74] `wear_plus` for WearOS — phone pushes session state, watch sends HR back
- [Source: architecture.md line 249] WearOS Communication: `wear_plus` (primary), Kotlin Message API (fallback)
- [Source: architecture.md lines 820–828] `wear/lib/` structure: `session_display_page.dart`, `rest_display_page.dart`, `summary_display_page.dart`, `communication/phone_bridge.dart`
- [Source: architecture.md line 925] WearOS boundary file: `phone_bridge.dart` (wear target) — bidirectional
- [Source: 12-1-spike-outcome.md] `wear_plus 1.2.4` does not export `WearApp`; uses `WatchShape`, `AmbientMode`, `Wear.instance`
- [Source: 12-1-spike-outcome.md] Emulator: `Wear_OS_Large_Round`, API 36, `nosdcard`, use `/data/local/tmp` for screenshots
- [Source: 12-1-wearos-feasibility-spike.md line 237] Defer 12.1 review: pin `minSdk ≥ 30` — closed by Task 1
- [Source: 12-1-wearos-feasibility-spike.md line 193] Compatibility caveat: no `WearApp` from package; use local wrapper pattern
- [Source: pulse_coach/pubspec.yaml lines 57–58] `wear_plus: ^1.2.4` already in phone pubspec
- [Source: project-context.md line 26] `wear_plus: latest pub.dev — WearOS companion (medium technical risk; spike required early)` — spike confirmed feasible
- [Source: in_session_state.dart] `InSessionState` fields: `steps`, `currentStepIndex`, `secondsRemaining`, `isComplete`, `isAbandoned`, `liveHr`
- [Source: in_session_cubit.dart] Emits state on every 1-second tick and every step advance — drives timer sync (AC2) and step transition (AC3) without extra polling

## Dev Agent Record

### Agent Model Used

{{agent_model_name_version}}

### Debug Log References

- 2026-06-03: `flutter build apk --debug` from `pulse_coach/wear/` passed after pinning Wear minSdk to 30.
- 2026-06-03: HALT at Task 2 pre-flight: installed `wear_plus 1.2.4` exposes `WatchShape`, `AmbientMode`, and ambient/shape methods only. It does not expose `Wear.instance.getNodes()`, `sendMessage()`, `receiveMessages()`, `WearNode`, or `MessageReceivedEvent`, so the story's specified phone/watch message implementation cannot compile without adding a native Wearable Message API bridge or changing dependencies.
- 2026-06-03: User approved changing package. Replaced the messaging channel with `watch_connectivity: ^0.2.8` while keeping `wear_plus` for watch shape/ambient widgets.
- 2026-06-03: `flutter test test/widget/session_wear_bridge_service_test.dart` from `pulse_coach/` passed.
- 2026-06-03: `flutter test` from `pulse_coach/wear/` passed.
- 2026-06-03: `flutter analyze` from `pulse_coach/wear/` passed with 0 issues.
- 2026-06-03: `flutter build apk --debug` from `pulse_coach/wear/` passed after adding `watch_connectivity`.
- 2026-06-03: `flutter test` from `pulse_coach/` passed with 763/763 tests.
- 2026-06-03: `flutter analyze` from `pulse_coach/` passed with 0 issues.
- 2026-06-03: `flutter build apk --debug` from `pulse_coach/` passed.
- 2026-06-03: Emulator verification partial: launched `Wear_OS_Large_Round`, boot completed, installed Wear debug APK, launched Wear app, pulled idle screenshot to `/private/tmp/pulsecoach_wear_idle.png`, installed/launched phone debug APK on `5200b2255ab59429`. Full active-session watch display verification is blocked because Wearable API pairing is not configured between the physical phone and Wear AVD; emulator console exposes no pairing command.
- 2026-06-03: Pairing follow-up attempt: launched Android Studio, but macOS blocked AppleScript UI control because `osascript` lacks Accessibility permission. Manual official path was attempted via `adb -d forward tcp:5601 tcp:5601`; phone is Android API 26, Wear OS companion package is not installed, and Play Store opens unauthenticated on the sign-in screen, so companion installation/pairing cannot be completed by the agent.
- 2026-06-03: No-Google-account install attempt: searched APKMirror/APKPure/Softpedia for a compatible Google-signed Wear OS companion APK. APKMirror/APKPure direct downloads returned Cloudflare challenge HTML through CLI; Softpedia blocked CLI access via Cloudflare; `apk.watch` presented an invalid TLS certificate and was not used. Verified the phone has no disabled/uninstalled `com.google.android.wearable.app` package to restore locally.
- 2026-06-03: Accessibility follow-up: after granting Accessibility to VS Code, AppleScript UI automation worked and Android Studio project menus became accessible. Android Studio Device Manager is available, but no direct Wear OS Pairing Assistant action was found in installed plugin/config searches. Official Android Developers documentation confirms the pairing assistant requires Android 11/API 30+ plus Play Store; the connected phone is Android 8/API 26. A compatible-looking APKMirror Wear OS companion APK page was identified, but CLI download again returned Cloudflare challenge HTML rather than an APK, so no sideload was performed.
- 2026-06-03: User provided local Wear OS companion APK `/Users/paololimonta/Downloads/com.google.android.wearable.app_2.66.107.587544675.gms.apk`; installed successfully on phone via `adb -s 5200b2255ab59429 install -r`. Enabled phone Wi-Fi, opened Wear OS companion, used `adb -d forward tcp:5601 tcp:5601`, selected `Accoppia con emulatore`, and confirmed phone showed `Wear_OS_Large_Round` / `Collegato all'emulatore`. Started PulseCoach session on phone and verified watch screenshots: active state (`Riscaldamento`, timer), timer update, step transition to `Mobilità`, and abandoned-session return to idle `PulseCoach Wear`.

### Implementation Plan

- Implement the story strictly in task order: pin Wear minSdk, add phone-side best-effort messaging with injectable test seam, wire it into `InSessionPage`, add watch-side message parsing/display widgets, then validate with targeted tests plus full Flutter regression.
- Package decision: `watch_connectivity` is used for message send/receive because the installed `wear_plus 1.2.4` has no message API. Since `watch_connectivity` transports `Map<String, dynamic>` messages rather than native path+bytes events, the app-level path is carried in `_path` with `/pulsecoach/session` and `/pulsecoach/session/end`. Phone and Wear Android `applicationId` values are aligned to `com.pulsecoach.pulse_coach` because the package documents same-package-name as an Android requirement.

### Completion Notes List

- Task 1 complete: Wear app `minSdk` pinned to 30 and debug APK build verified.
- Blocked before Task 2 implementation: the story's required `wear_plus` messaging API is absent in the installed dependency. Continuing would require a scope decision, most likely an app-level Kotlin `MethodChannel` bridge backed by `com.google.android.gms:play-services-wearable`, or a different package/version that actually exposes message APIs.
- Task 2 complete after package change: phone-side `WearBridgeService` sends active/end messages through `watch_connectivity`, includes HR only when available, and swallows all send failures for silent degradation.
- Task 3 complete: `InSessionPage` starts the bridge with the active cubit stream and stops it before cubit close.
- Task 4 complete: Wear-side `PhoneBridge` parses active/end messages into `SessionWearState` and ignores unknown/malformed payloads.
- Task 5 complete: Wear `SessionDisplayPage` renders step, `MM:SS` timer, and optional HR with round-screen padding and ended callback/pop behavior.
- Task 6 complete: `RestDisplayPage` placeholder added for ARCH13.
- Task 7 complete: Wear `main.dart` routes active bridge state to `SessionDisplayPage`, otherwise shows existing idle home.
- Task 8 complete: phone bridge tests, watch parser tests, watch widget tests, wear analyze, phone analyze, phone regression tests, and debug builds pass.
- Task 9 complete: local companion APK sideload enabled phone-to-Wear-emulator pairing without Google account login, and live device verification passed for active display, timer update, step transition, and session end clearing the watch display.
- Verification screenshots pulled to `/private/tmp/`: `pulsecoach_phone_pairing.png`, `pulsecoach_phone_session1.png`, `pulsecoach_wear_session1.png`, `pulsecoach_wear_session2.png`, `pulsecoach_wear_session3.png`, `pulsecoach_wear_after_end.png`.

### File List

- pulse_coach/lib/features/session/presentation/pages/in_session_page.dart
- pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart
- pulse_coach/pubspec.lock
- pulse_coach/pubspec.yaml
- pulse_coach/test/widget/session_wear_bridge_service_test.dart
- pulse_coach/wear/android/app/build.gradle.kts
- pulse_coach/wear/lib/communication/phone_bridge.dart
- pulse_coach/wear/lib/main.dart
- pulse_coach/wear/lib/rest_display_page.dart
- pulse_coach/wear/lib/session_display_page.dart
- pulse_coach/wear/pubspec.lock
- pulse_coach/wear/pubspec.yaml
- pulse_coach/wear/test/phone_bridge_test.dart
- pulse_coach/wear/test/session_display_page_test.dart

### Change Log

- 2026-06-03: Added in-session WearOS messaging/display implementation using `watch_connectivity`; completed paired-device active-session emulator verification; story moved to `review`.

### Review Findings

_Code review 2026-06-03 (3-layer: Blind Hunter, Edge Case Hunter, Acceptance Auditor). All five ACs verified genuinely met by the code and live-verified on paired devices. 1 patch, 2 deferred, 15 dismissed as noise (notably the cross-channel numeric-coercion concerns — false positives: `watch_connectivity` Android uses Java object serialization so `int` round-trips as `int`, and `messageStream` already normalizes to `Map<String, dynamic>`)._

- [x] [Review][Patch] Watch timer not monospaced — `JetBrains Mono` is referenced as `fontFamily` but is not bundled in `wear/pubspec.yaml` (no fonts/assets/google_fonts on the wear target), so the MM:SS timer falls back to the default sans-serif and digits jitter each second; spec Task 5 intended monospace. Fix: use a guaranteed-monospace family/fallback (e.g. `fontFamilyFallback: ['monospace']` or `fontFamily: 'monospace'`). [pulse_coach/wear/lib/session_display_page.dart — `_SessionDisplayContent` timer `Text` style]
- [x] [Review][Defer] Best-effort session-end with no watch-side timeout — `end` is sent fire-and-forget (`unawaited`), there is no sequence guard against a late active-frame arriving after `end`, and the watch has no liveness timeout; a dropped `end` or ungraceful phone exit can strand the watch on a stale session screen. Scope of Story 12.4 (WearOS disconnect resilience). [wear_bridge_service.dart `stop`/`_handleState`, in_session_page.dart `dispose`, phone_bridge.dart] — deferred to 12.4
- [x] [Review][Defer] Empty `steps` crash invariant — `_onCountdownComplete` → `InSessionCubit` (`steps.first`) and `WearBridgeService._handleState` (`state.currentStep`) both dereference without an empty-list guard; pre-existing invariant on `SessionStepGenerator.generate` never returning empty, not introduced by this change. [in_session_cubit.dart, wear_bridge_service.dart] — deferred, pre-existing
