# Story 12.4: WearOS Disconnect Resilience

Status: done

## Story

As a user,
I want the phone session to continue independently if my watch disconnects mid-session,
So that a connectivity hiccup never interrupts my workout.

## Acceptance Criteria

**AC1 — Phone session unaffected by watch disconnection**
Given a session is active and the WearOS companion disconnects
When disconnection is detected (sendMessage throws)
Then the phone session continues without interruption — no error state, no pause (NFR22)

**AC2 — Companion resumes on reconnect during active session**
Given a session is active and the watch disconnected mid-session
When the watch reconnects
Then the companion display resumes showing the current session state within the next tick (~1 second)

**AC3 — Companion shows post-session summary when watch reconnects after session ends**
Given the session ends while the watch is disconnected (summary message was missed)
When the watch reconnects within 60 seconds of session end
Then the watch receives the summary payload and shows the post-session summary screen

**AC4 — Late active frames do not override terminal state on the watch**
Given the watch has received a summary or end message
When a late active-session frame arrives (timing edge case)
Then the watch continues to display the summary (or idle) — it does not revert to SessionDisplayPage

## Tasks / Subtasks

- [x] **Task 1: Add `WatchReachabilityClient` interface and reconnect poller to `WearBridgeService`** (AC1, AC3)
  - [x] In `pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart`:
    - Add `abstract interface class WatchReachabilityClient { Future<bool> get isReachable; }` at top of file, alongside existing `WatchMessagingClient`
    - Add `class WatchConnectivityReachabilityClient implements WatchReachabilityClient` that wraps `WatchConnectivity().isReachable`
    - Add `WatchReachabilityClient _reachabilityClient` field to `WearBridgeService`; update constructor: `WearBridgeService({WatchMessagingClient? client, WatchReachabilityClient? reachabilityClient})`; default `reachabilityClient ?? WatchConnectivityReachabilityClient()`
    - Add `Map<String, dynamic>? _terminalPayload` and `Timer? _reconnectPoller` fields
    - In `_handleState`, after setting `_ended = true` and before returning, store `_terminalPayload = payload` (where `payload` is the map just passed to `_sendToWatch`), then call `_startReconnectPoller()`
    - Add `void _startReconnectPoller()`:
      ```dart
      void _startReconnectPoller() {
        _reconnectPoller?.cancel();
        bool _active = true;
        final cancelTimer = Timer(const Duration(seconds: 60), () {
          _active = false;
          _reconnectPoller?.cancel();
          _reconnectPoller = null;
        });
        _reconnectPoller = Timer.periodic(const Duration(seconds: 5), (_) async {
          if (!_active) return;
          final reachable = await _reachabilityClient.isReachable;
          if (!_active) return;
          if (reachable) {
            _active = false;
            cancelTimer.cancel();
            _reconnectPoller?.cancel();
            _reconnectPoller = null;
            final payload = _terminalPayload;
            if (payload != null) unawaited(_sendToWatch(payload));
          }
        });
      }
      ```
      Note: `_active` flag prevents racing between the 60-second cancel timer and the periodic timer.
    - In `stop()`: add `_reconnectPoller?.cancel(); _reconnectPoller = null;` before the existing `_sendEnd()` call
    - In `dispose()`: add `_reconnectPoller?.cancel(); _reconnectPoller = null;` before the existing subscription cancel

- [x] **Task 2: Fix late-frame routing in `_WearRoot` (watch side)** (AC4)
  - [x] In `pulse_coach/wear/lib/main.dart`:
    - Make `_WearRoot` into a public `WearRoot` widget (rename `_WearRoot` → `WearRoot` and `_WearRootState` → `_WearRootState`) to allow widget testing; keep `_WearRootState` private
    - Add optional `PhoneBridge? bridge` constructor parameter to `WearRoot` (for injection in tests; if null, creates internally)
    - In `_WearRootState`, add fields: `late final PhoneBridge _phoneBridge; StreamSubscription<SessionWearState>? _statesSub; SessionWearState? _state; bool _sawSummary = false;`
    - In `initState`: `_phoneBridge = widget.bridge ?? PhoneBridge(); _statesSub = _phoneBridge.states.listen(_onState);`
    - In `dispose`: add `await _statesSub?.cancel();` before the existing `unawaited(_phoneBridge.dispose());`
    - Add `void _onState(SessionWearState state)`:
      ```dart
      void _onState(SessionWearState state) {
        if (!mounted) return;
        if (state.isEnded) {
          setState(() { _sawSummary = false; _state = state; });
          return;
        }
        if (state.isSummary) {
          setState(() { _sawSummary = true; _state = state; });
          return;
        }
        if (_sawSummary) return; // ignore late active frame after summary
        setState(() => _state = state);
      }
      ```
    - Replace `StreamBuilder` widget tree in `build()` with direct render using `_state`:
      ```dart
      @override
      Widget build(BuildContext context) {
        final state = _state;
        if (state?.isSummary == true) {
          return SummaryDisplayPage(initialState: state!);
        }
        if (state != null && !state.isEnded) {
          return SessionDisplayPage(bridge: _phoneBridge, initialState: state);
        }
        return PulseCoachWearHome(isAmbient: widget.isAmbient, shape: widget.shape);
      }
      ```
    - Update `WearApp` to use `WearRoot` (capital R) instead of `_WearRoot`
    - Add `import 'dart:async' show StreamSubscription;` if not already present

- [x] **Task 3: Tests for reconnect poller (phone side)** (AC3, AC1)
  - [x] In `pulse_coach/test/widget/session_wear_bridge_service_test.dart`:
    - Add `class _FakeReachabilityClient implements WatchReachabilityClient` with configurable `isReachable` response list (returns from a `Queue<bool>`, defaults `true` when queue is empty)
    - Add test `'reconnect poller re-sends terminal payload when watch becomes reachable'`:
      - `reachabilityClient` returns `false` on first call, `true` on second
      - Start service, emit complete state with sessionType; verify summary sent once (tick 1)
      - Advance fake timers (or `pumpEventQueue()` multiple times to trigger periodic); verify summary re-sent
      - Note: use `fake_async` to control `Timer.periodic` in tests
    - Add test `'reconnect poller stops after re-send — does not keep re-sending'`:
      - `reachabilityClient` always returns `true`
      - Start service, emit complete; advance time past 2+ poller intervals; verify summary sent exactly twice (once on completion, once on first reachable poll)
    - Add test `'reconnect poller is cancelled on dispose — no re-send after dispose'`:
      - `reachabilityClient` always returns `true`
      - Start service, emit complete, call `dispose()` immediately; advance timers; verify no additional re-send after dispose
    - Add test `'reconnect poller auto-cancels after 60 seconds without reachable'`:
      - `reachabilityClient` always returns `false`
      - Start service, emit complete; advance fake time by 65 seconds; verify no extra send and poller is stopped (check via reachabilityClient call count stops increasing after 60s)

    Implementation note: these tests require `fake_async` (already a dev dependency). Use `fakeAsync(() { ... addTime(Duration(seconds: ...)); })` to control Timer firing.

- [x] **Task 4: Widget tests for `WearRoot` late-frame routing (watch side)** (AC4)
  - [x] Create `pulse_coach/wear/test/wear_root_test.dart`:
    - Test `'does not revert to SessionDisplayPage after summary state'`:
      - Create `StreamController<SessionWearState>` + `FakePhoneBridge`
      - Inject bridge into `WearRoot(bridge: fakeBridge, isAmbient: false, shape: WearShape.square)`
      - Pump widget; emit active state → verify `SessionDisplayPage` shown
      - Emit `SessionWearState.summary(...)` → verify `SummaryDisplayPage` shown
      - Emit active state (late frame) → verify still `SummaryDisplayPage` (not reverted)
    - Test `'returns to idle after end message clears summary'`:
      - Emit active → summary → `SessionWearState.ended()` → verify `PulseCoachWearHome` shown
    - Test `'shows new session after end'`:
      - Emit active → end → active (new session) → verify `SessionDisplayPage` shown again

    Note: `WearShape` is from `wear_plus`. Tests run on Flutter test surface (no real WearOS). Mock `WatchShape` by wrapping `WearRoot` in a `MaterialApp`. `WearRoot.shape` is used only in `PulseCoachWearHome` padding and `SessionDisplayPage` padding — it is safe to pass `WearShape.square` in tests.

    `FakePhoneBridge` implementation:
    ```dart
    class _FakePhoneBridge extends PhoneBridge {
      _FakePhoneBridge(StreamController<SessionWearState> controller)
        : super(client: _NullPhoneMessagingClient()) {
        _statesController = controller;
      }
    }
    ```
    Wait — `PhoneBridge` sets up its own subscription in the constructor. We need a different approach: expose `states` from a controller directly. Since `PhoneBridge.states` is a getter on a private `_statesController`, we cannot override it without subclassing.

    Alternative: create a separate `FakePhoneBridge` that DOES NOT extend `PhoneBridge` but exposes the same `states` interface. But `WearRoot` expects `PhoneBridge` (concrete class). We'd need to extract a `PhoneBridgeInterface` abstract class.

    Simpler: pass a `PhoneBridge` with a `_FakePhoneMessagingClient` that forwards a controlled stream, and call `_phoneBridge.states`. Since `_FakePhoneMessagingClient` is already defined in `phone_bridge_test.dart`, we can reuse the pattern.

    Actually the simplest approach: inject `PhoneBridge(client: _FakePhoneMessagingClient(controller))` as the bridge parameter. When states need to be emitted, we add to the underlying message controller — but this means converting raw messages into `SessionWearState` (adding message dicts). That's clean enough:
    ```dart
    controller.add({'_path': PhoneBridge.sessionPath, 'step': 'Squat', 'secs': 30}); // active
    controller.add({'_path': PhoneBridge.summaryPath, 'sessionType': 'cardio', ...}); // summary
    ```
    This exercises the real `PhoneBridge` parsing and the `WearRoot` routing together. This is a proper integration test.

- [x] **Task 5: Emulator verification** (AC1–AC4)
  - [x] Launch `Wear_OS_Large_Round` emulator (direct SDK binary — see Dev Notes)
  - [x] Build + install phone and wear debug APKs
  - [x] Pair phone to emulator (companion APK at `/Users/paololimonta/Downloads/com.google.android.wearable.app_2.66.107.587544675.gms.apk`)
  - [x] **AC1/AC2**: Start a session on the phone; mid-session, kill the watch app (`adb shell am force-stop com.pulsecoach.pulse_coach_wear`); verify phone session continues uninterrupted; relaunch watch app; verify session display resumes on watch within ~1 second (AC2 in-session reconnect)
  - [x] **AC3**: Start a session; kill the watch app; complete the session on the phone (natural completion); wait for reconnect poller window (~5s); relaunch watch app and verify watch shows `SummaryDisplayPage` (reconnect-after-end scenario)
  - [x] **AC4**: Verify no revert to SessionDisplayPage by checking that after summary is displayed, any subsequent active-session phase doesn't flip the watch back to SessionDisplayPage (test via completing session and checking summary stays until RPE submitted)
  - [x] Screenshot each state; pull to `/private/tmp/`
  - [x] `flutter analyze` from `pulse_coach/` must pass with 0 issues
  - [x] `flutter analyze` from `pulse_coach/wear/` must pass with 0 issues
  - [x] `flutter test` from `pulse_coach/` must pass (regression guard — 766 baseline; expect ~770 with new poller tests)
  - [x] `flutter test` from `pulse_coach/wear/` must pass (9 baseline; expect ~12 with new WearRoot routing tests)

## Dev Notes

### AC1 — Already Implemented (No Phone Logic Changes Needed)

AC1 is already satisfied by the silent degradation in `WearBridgeService._sendToWatch()`:

```dart
Future<void> _sendToWatch(Map<String, dynamic> payload) async {
  try {
    await _client.sendMessage(payload);
  } catch (_) {
    // Silent degradation: the watch is optional and must not affect session UX.
  }
}
```

Every outbound message — active ticks, end, summary — goes through `_sendToWatch`. If the watch is disconnected and `sendMessage` throws, the exception is swallowed. The `InSessionCubit` timer continues unaffected. No phone-side changes are needed for AC1.

### AC2 — Already Handled by Tick Stream (No Extra Logic)

During an active session, `InSessionCubit` emits a new state every second. Each state tick triggers `_handleState`, which calls `_sendToWatch`. When the watch reconnects, it starts receiving the next tick automatically (within 1 second). The `PhoneBridge.states` stream is broadcast, so the re-subscribed `_WearRoot` receives the next emission and routes to `SessionDisplayPage`. No special reconnect detection is needed for the in-session case.

### AC3 — Reconnect Poller (New Phone Logic)

The post-session gap: the summary is sent **once**. If the watch is disconnected at that moment, it misses the summary. When it reconnects, it sees no new messages and shows idle.

Fix: After sending the terminal payload (summary or end), start a `Timer.periodic(5s)` that polls `WatchConnectivity().isReachable`. When reachable, re-send `_terminalPayload`. Stop polling after the first successful re-send, or after 60 seconds (session is clearly over by then).

`watch_connectivity` does not provide a native reachability-change stream — only a one-shot `Future<bool> isReachable`. Polling is the correct approach given the package API.

### AC4 — Late Active Frames on Watch (New Watch Logic)

Deferred from Story 12.2 code review: "No sequence guard against late active-frame after end — full resilience is Story 12.4".

Problem: after the watch receives a summary (`isSummary == true`), if a late active-session frame arrives (e.g., a tick sent before the phone knew the session ended), the current `StreamBuilder` routing routes it to `SessionDisplayPage`, overriding the summary.

Root cause is in `_WearRoot.build()`:
```dart
// BEFORE (12.3):
if (state != null && state.isSummary) → SummaryDisplayPage
if (state != null && !state.isEnded)  → SessionDisplayPage  // late active hits this!
```

Fix: replace `StreamBuilder` with a manual subscription and `_sawSummary` flag:
- Once `isSummary` is seen, block all subsequent active frames
- Only `isEnded` clears the flag (RPE submitted → watch returns to idle)
- After `isEnded`, a new active frame (new session) is allowed through

### `WearBridgeService` State Machine After Story 12.4

```
start()          → _subscription active, _ended = false
                       ↓
_handleState     → sends /session ticks every ~1s
                       ↓ (isComplete || isAbandoned)
_handleState     → _ended = true
                   send summary or end (AC4-fallback)
                   _terminalPayload = that payload
                   _startReconnectPoller()
                       ↓
_reconnectPoller → every 5s: isReachable?
                   if true → re-send _terminalPayload → cancel poller
                   if still false → try again (up to 60s total)
                       ↓
stop()/dispose() → _reconnectPoller?.cancel()
                   (stop also calls _sendEnd if !_ended — irrelevant here since _ended = true)
```

### `_WearRoot` Routing State Machine After Story 12.4

```
_state == null           → PulseCoachWearHome (idle)
_state.isSummary == true → SummaryDisplayPage (_sawSummary = true)
_state.isEnded == true   → PulseCoachWearHome (idle), _sawSummary = false
_state (active)          → if !_sawSummary → SessionDisplayPage
                           if _sawSummary  → IGNORE (no setState)
```

### `fake_async` Usage for Poller Tests

Tests that verify `Timer.periodic` behavior require `fake_async`. Pattern:

```dart
import 'package:fake_async/fake_async.dart';

test('reconnect poller re-sends terminal payload', () {
  fakeAsync((async) {
    final reachabilityClient = _FakeReachabilityClient([false, true]);
    final messagingClient = _RecordingWatchMessagingClient();
    final controller = StreamController<InSessionState>();
    final service = WearBridgeService(
      client: messagingClient,
      reachabilityClient: reachabilityClient,
    );

    service.start(controller.stream, sessionType: 'mobility', durationMinutes: 20);
    controller.add(const InSessionState(steps: steps, currentStepIndex: 0,
        secondsRemaining: 0, isComplete: true));
    async.flushMicrotasks();

    // First send: summary at completion
    expect(messagingClient.messages.length, 1);

    // Advance 5 seconds to trigger first poll (reachable: false → no re-send)
    async.elapse(const Duration(seconds: 5));
    async.flushMicrotasks();
    expect(messagingClient.messages.length, 1); // no re-send yet

    // Advance 5 more seconds to trigger second poll (reachable: true → re-send)
    async.elapse(const Duration(seconds: 5));
    async.flushMicrotasks();
    expect(messagingClient.messages.length, 2);
    expect(messagingClient.messages[1], {
      '_path': WearBridgeService.summaryPath,
      'sessionType': 'mobility',
      'durationMinutes': 20,
      'abandoned': false,
    });

    controller.close();
    service.dispose();
  });
});
```

Note: `fake_async` is already a transitive dev dependency via `flutter_test`. Import as `package:fake_async/fake_async.dart`.

### `WearRoot` Widget Test Pattern

Since `WearShape` comes from `wear_plus`, and the test surface is not a real WearOS device, the widget under test must be wrapped in a test-friendly tree. `WatchShape` (used inside `SessionDisplayPage` and `SummaryDisplayPage`) uses a method channel and may need mocking. Use a minimal approach:

```dart
// Wrap in MaterialApp only; WearShape.square for non-adaptive padding
testWidgets('...', (tester) async {
  final messageController = StreamController<Map<String, dynamic>>();
  final bridge = PhoneBridge(client: _FakePhoneMessagingClient(messageController));

  await tester.pumpWidget(MaterialApp(
    home: WearRoot(
      bridge: bridge,
      isAmbient: false,
      shape: WearShape.square,
    ),
  ));

  // Emit active session message
  messageController.add({
    '_path': PhoneBridge.sessionPath, 'step': 'Squat', 'secs': 30,
  });
  await tester.pumpAndSettle();
  expect(find.byType(SessionDisplayPage), findsOneWidget);

  // Emit summary
  messageController.add({
    '_path': PhoneBridge.summaryPath,
    'sessionType': 'cardio', 'durationMinutes': 15, 'abandoned': false,
  });
  await tester.pumpAndSettle();
  expect(find.byType(SummaryDisplayPage), findsOneWidget);

  // Late active frame — should NOT revert
  messageController.add({
    '_path': PhoneBridge.sessionPath, 'step': 'Late', 'secs': 5,
  });
  await tester.pumpAndSettle();
  expect(find.byType(SummaryDisplayPage), findsOneWidget); // still summary ✓

  await bridge.dispose();
  await messageController.close();
});
```

Note: `WatchShape` is only used in sub-widgets of `SessionDisplayPage` and `SummaryDisplayPage`. If it uses a method channel that throws in tests, wrap those sub-widgets with a `MethodChannel` mock or restructure the test to check for the page type without pumping the full widget. In prior stories (12.2, 12.3), watch-side widget tests used `WearShape.square` successfully.

### Emulator Launch (Same as Stories 12.2/12.3)

```bash
/Users/paololimonta/Library/Android/sdk/emulator/emulator -avd Wear_OS_Large_Round -no-snapshot -no-audio &
```

Poll: `adb -s emulator-5554 shell getprop sys.boot_completed` until `1`. Resolve emulator ID dynamically: `adb devices | grep emulator`.

Pairing: companion APK at `/Users/paololimonta/Downloads/com.google.android.wearable.app_2.66.107.587544675.gms.apk` (already sideloaded in 12.2). If not present: `adb -s emulator-5554 install <path>`, then enable `Wear OS` companion on the phone and pair.

Screenshots use `/data/local/tmp` (AVD is `nosdcard`).

Kill the watch app (for AC3 test): `adb -s emulator-5554 shell am force-stop com.pulsecoach.pulse_coach_wear`.

### `WatchReachabilityClient` Interface — Why Separate From `WatchMessagingClient`

`WatchMessagingClient` is the send-side interface (injected at construction for testability). `WatchReachabilityClient` is the poll-side interface (also injected for testability). Keeping them separate:
- Follows single-responsibility (send ≠ query)
- Allows test doubles to independently control message success vs reachability
- Mirrors how `WatchConnectivity` API is used: `sendMessage` vs `isReachable` are separate concerns

Both default to wrapping `WatchConnectivity()` in production.

### E9-K1 Fire-Check

**DI/lifecycle/cross-cutting review-patches:**
- `WearBridgeService` is still instantiated directly in `InSessionPage` (not via `getIt`). Adding `WatchReachabilityClient` follows the same constructor-injection pattern already used for `WatchMessagingClient`. No new DI registrations needed. Not fired.
- `WearRoot` changes are in the watch sub-project (`wear/`) which has no `injectable` setup. Not fired.

**Category A deliverable-debt with relative triggers:**
- `E10R-1` (release-build observability for DAO write failures) — not triggered (no new DAO writes)
- `E10R-2` (non-UTC regression for `_mondayOf`) — not triggered (no Progress feature touches)
- `E6-T7`, `E6-T8` — not triggered (no exercise catalog changes)

Not fired.

**Cubit/BLoC collection-index pre-flight (E7-P2):** `WearBridgeService` carries no index-based state. `WearRoot` carries `_state: SessionWearState?` (a value, not an index). Not fired.

### Category A Snapshot

Active at story-creation for 12.4 (4/5): `E6-T7`, `E6-T8`, `E10R-1`, `E10R-2`. Story 12.4 does not open or close any Category A items. `E11R-3` (tablet verification) remains hardware-gated and parked per Epic 12 kickoff triage rationale.

### Application-Context Sync (Ratified Deviation — added during code review 2026-06-04)

Story-creation Tasks 1–4 prescribed a `sendMessage` + `isReachable`-poll design and marked `phone_bridge.dart` as NO CHANGES. During Task 5 emulator/device verification the Dev found that `sendMessage` + `isReachable` alone did **not** deterministically recover the post-session summary when the watch process had been restarted — a re-sent message is lost if no live listener is attached at delivery time. To make terminal recovery deterministic the Dev added a `watch_connectivity` **application-context** sync/hydration path:

- Phone side (`wear_bridge_service.dart`): `WatchMessagingClient.updateApplicationContext`, mirrored on every active tick and every terminal/poller send via `_updateWatchContext` / `_sendTerminalToWatch`. Application context persists across reconnect, so the last state (active or summary) is always retrievable.
- Watch side (`phone_bridge.dart`): `PhoneMessagingClient.contextStream` + `receivedApplicationContexts`, with `PhoneBridge._emitReceivedApplicationContexts()` hydrating the latest persisted context on startup.

This deviates from the prescribed scope and touches a NO-CHANGES file, but is **ratified** (code-review decision D1, 2026-06-04) because it is the mechanism that actually satisfies AC3 on real hardware. Assertion-level test coverage for the context path was added to `session_wear_bridge_service_test.dart` as part of the ratification.

### Existing Test Regression Guard

- `flutter test` from `pulse_coach/`: must pass with ≥ 766 tests (12.3 baseline); expect ~770 after poller tests are added
- `flutter test` from `pulse_coach/wear/`: must pass with ≥ 9 tests (12.3 baseline); expect ~12 after WearRoot routing tests are added

### Project Structure Notes

| Action | Path |
|---|---|
| UPDATE | `pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart` |
| UPDATE | `pulse_coach/wear/lib/main.dart` |
| UPDATE | `pulse_coach/test/widget/session_wear_bridge_service_test.dart` |
| CREATE | `pulse_coach/wear/test/wear_root_test.dart` |
| UPDATE | `pulse_coach/wear/lib/communication/phone_bridge.dart` (was "NO CHANGES" at story-creation; ratified during code review — see "Application-Context Sync (Ratified Deviation)" below) |
| NO CHANGES | `pulse_coach/wear/lib/session_display_page.dart` |
| NO CHANGES | `pulse_coach/wear/lib/summary_display_page.dart` |
| NO CHANGES | Any other `pulse_coach/lib/` file |

### References

- [Source: epics.md lines 1766–1783] Story 12.4 ACs and NFR22
- [Source: architecture.md line 510] "WearOS disconnected — handled silently" — principle already encoded in `_sendToWatch`
- [Source: 12-3 Dev Notes, Review Findings: Defer] "No sequence guard against late active-frame after end — full resilience is Story 12.4" — AC4 addresses this deferred item
- [Source: 12-3 Dev Notes, References: Defer] "[Defer] `_WearRoot` `StreamBuilder` has no `initialData` and bridge stream is broadcast — summary frame arriving while no listener could be dropped" — mitigated by this story's reconnect poller (phone re-sends within 60s)
- [Source: watch_connectivity 0.2.8 — `watch_connectivity_base.dart`] `isReachable` is `Future<bool>`; no native stream for reachability changes → polling is the correct approach
- [Source: wear_bridge_service.dart] Current `_sendToWatch` catch-all for silent degradation (AC1 already satisfied)
- [Source: phone_bridge.dart] `_statesController` is `broadcast()`; `_FakePhoneMessagingClient` pattern reuse for `wear_root_test.dart`
- [Source: wear/lib/main.dart] Current `_WearRoot` `StreamBuilder` routing that needs replacing
- [Source: session_wear_bridge_service_test.dart] Existing test helpers (`_RecordingWatchMessagingClient`, `_ThrowingWatchMessagingClient`) available for reuse/extension
- [Source: project-context.md line 26] `watch_connectivity: ^0.2.8` — confirmed version
- [Source: 12-2 Dev Notes] Emulator launch via direct SDK binary; pairing procedure; companion APK path

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter test test/widget/session_wear_bridge_service_test.dart` from `pulse_coach/`: passed, `12/12`.
- Targeted WearOS tests from `pulse_coach/wear/` (`phone_bridge_test.dart`, `wear_root_test.dart`): passed, `9/9`.
- `flutter analyze` from `pulse_coach/`: passed with no issues.
- `flutter analyze` from `pulse_coach/wear/`: passed with no issues.
- `flutter test` from `pulse_coach/`: passed, `771/771`.
- `flutter test` from `pulse_coach/wear/`: passed, `13/13`.
- `flutter build apk --debug` from `pulse_coach/`: passed and produced `pulse_coach/build/app/outputs/flutter-apk/app-debug.apk`.
- `flutter build apk --debug` from `pulse_coach/wear/`: passed and produced `pulse_coach/wear/build/app/outputs/flutter-apk/app-debug.apk`.
- Installed phone debug APK on physical device `5200b2255ab59429` using non-streaming install after one streaming digest/certificate failure.
- Installed wear debug APK on Wear emulator `emulator-5554`.
- Manual AC1/AC2 verification: started a phone session, force-stopped the watch app, confirmed the phone session continued, relaunched the watch, and confirmed active session display resumed. Screenshots: `/private/tmp/pulsecoach_phone_session_active.png`, `/private/tmp/pulsecoach_wear_session_active.png`, `/private/tmp/pulsecoach_phone_after_wear_kill.png`, `/private/tmp/pulsecoach_wear_after_relaunch_active.png`.
- Manual AC3 verification: ended/abandoned a session while the watch app was stopped, relaunched the watch within the reconnect window, and confirmed the summary screen rendered from recovered context. Screenshot: `/private/tmp/pulsecoach_wear_reconnect_summary_context.png`.
- Manual AC4 verification: confirmed summary stayed stable after display and widget test covered late active frame suppression. Screenshot: `/private/tmp/pulsecoach_wear_summary_stable.png`.
- Device finding: `sendMessage` plus `isReachable` alone did not recover the post-session summary on the tested phone/emulator pairing; application context sync/hydration was added to make terminal recovery deterministic after watch process restart.

### Completion Notes List

- Added a reachability interface, reconnect poller, terminal payload retention, and route-dispose preservation in `WearBridgeService`.
- Added application context sync on the phone side and latest context hydration on the watch side so a relaunched companion can recover missed terminal payloads.
- Added `WearRoot` injection and summary-state routing guard so late active frames cannot override a summary.
- Added phone-side poller/context tests and wear-side bridge/routing tests.
- Verified AC1-AC4 on a physical Android phone plus WearOS emulator, including reconnect-after-end summary recovery.

### File List

- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart`
- `pulse_coach/pubspec.yaml`
- `pulse_coach/pubspec.lock`
- `pulse_coach/test/widget/in_session_page_abandon_test.dart`
- `pulse_coach/test/widget/session_wear_bridge_service_test.dart`
- `pulse_coach/wear/lib/communication/phone_bridge.dart`
- `pulse_coach/wear/lib/main.dart`
- `pulse_coach/wear/test/phone_bridge_test.dart`
- `pulse_coach/wear/test/wear_root_test.dart`

### Change Log

2026-06-04: Implemented WearOS disconnect resilience and reconnect summary recovery.

### Review Findings

_Code review 2026-06-04 (3-layer adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor). AC coverage: AC1 Satisfied, AC2 Satisfied, AC4 Satisfied, AC3 Satisfied functionally but via an out-of-spec mechanism (see Decision items). 2 decision-needed, 0 patch, 5 defer, 5 dismissed._

- [x] [Review][Decision→Resolved] Scope deviation — application-context sync added and `phone_bridge.dart` modified despite the spec's "NO CHANGES" mark — Tasks 1–4 never mention application-context sync, yet the as-built design adds `PhoneMessagingClient.contextStream` / `receivedApplicationContexts`, `PhoneBridge._emitReceivedApplicationContexts` startup hydration, `WatchMessagingClient.updateApplicationContext`, and `_updateWatchContext` (called on every active tick + every terminal/poller send). `phone_bridge.dart` is marked NO CHANGES in the Project Structure Notes table (+26 lines added). The deviation is justified by a documented device finding (Dev Agent Record: "sendMessage plus isReachable alone did not recover the post-session summary; application context sync/hydration was added to make terminal recovery deterministic"). **Resolved (D1 = accept + ratify): spec updated** (Project Structure Notes table + new "Application-Context Sync (Ratified Deviation)" Dev Note), **and assertion-level test coverage added** for the context path (`session_wear_bridge_service_test.dart` "mirrors every outbound payload into application context…"). [wear_bridge_service.dart:9,28-30,124,199-205; phone_bridge.dart:8-10,84-85,101-109]
- [x] [Review][Decision→Resolved] Watch can flip back to the summary screen after the user already dismissed it via RPE — The reconnect poller re-sends the terminal summary (message + persisted application context) every 5s for up to 60s. On RPE submission `rpe_page.dart:112` calls `WearBridgeService.sendEndMessage()`, which sends `end` and returns the watch to idle. But that `end` is sent by a *static* call decoupled from the running `WearBridgeService` instance, whose poller is NOT cancelled: `InSessionPage.dispose` calls only `stop()` (never `dispose()`), and `stop()` deliberately early-returns before `_cancelReconnectTimers()` when `_ended && _terminalPayload != null`. So after RPE the lingering poller re-sends the summary and flips the watch from idle back to `SummaryDisplayPage`. Root tension: the poller cannot distinguish "watch missed the summary" (AC3 intent) from "watch saw it and moved on". **Resolved (D2 = gate on no-end-observed): added a `WearBridgeService._endMessageSent` sentinel** set by both the static `sendEndMessage` (RPE path) and `_sendEnd`, reset in `start()` when a new session begins. The reconnect poller now short-circuits and cancels itself once an end has been sent, so it preserves the AC3 re-send window *before* RPE yet never flips an already-dismissed watch back to the summary. Covered by the new test "reconnect poller stops re-sending once an end message has been sent". [wear_bridge_service.dart:56-62,72,128-132,135-163,175-183; rpe_page.dart:112]
- [x] [Review][Defer] `_ended`/`_terminalPayload` never reset in `start()` — instance reuse for a second session would drop all frames [wear_bridge_service.dart:66-75,91-92] — deferred, latent (InSessionPage creates a fresh service per session)
- [x] [Review][Defer] In-flight poller-tick race if `_startReconnectPoller` were re-invoked (stale tick cancels freshly-armed timers via shared fields) [wear_bridge_service.dart:135-158] — deferred, latent (terminal path is `_ended`-guarded, poller starts at most once per instance)
- [x] [Review][Defer] Startup application-context hydration can be dropped on the `.broadcast()` states stream / duplicate emission when the same context arrives via both snapshot and `contextStream` [phone_bridge.dart:84-85,101-109] — deferred, low likelihood (listener attaches before the async hydration completes; duplicate emission is idempotent)
- [x] [Review][Defer→Resolved] Application-context sync path has no direct test assertions — resolved as part of D1: added "mirrors every outbound payload into application context for reconnect recovery" asserting both active-tick and terminal-summary contexts [session_wear_bridge_service_test.dart]
- [x] [Review][Defer] "auto-cancels after 60s" test under-pins the boundary — uses `greaterThan` + snapshot-equality but does not assert exact behavior at the 60s tick (periodic-60s tick races the deadline) [session_wear_bridge_service_test.dart:444-485] — deferred, minor test hardening
