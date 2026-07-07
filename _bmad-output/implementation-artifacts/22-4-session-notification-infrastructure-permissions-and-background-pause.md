---
baseline_commit: ee1fbcf918d7ce994fcd54b86c05897163c5f819
---

# Story 22.4: Session Notification — Infrastructure, Permissions and Background Pause

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user who backgrounds the app mid-session,
I want the timer to pause and a notification to show the session and paused time,
So that I know a session is still open and can get back to it.

## Context

**Epic 22, fourth story.** First of the epic's two notification stories (22.4 infrastructure/pause, 22.5 timeout/resume/deep-link) and the epic's **net-new dependency**: no notification stack exists in this codebase today. Unlike Stories 22.1–22.3, this feature has **no ratified UX component spec** — `DESIGN.md`/`EXPERIENCE.md`'s 2026-07-06 UX pass explicitly **parked** the notification feature as "primarily a PRD/architecture concern" (`.decision-log.md:75`), so there is no `DESIGN.md` component entry to follow here. The binding specs are `prd.md` (FR79/FR80/NFR39), `addendum.md`'s "Ongoing session notification" mechanism note, and `review-delta-notification.md` (the PASS-WITH-FIXES gate review whose fixes are already folded into the current FR79/FR80/NFR39 text — cited below only where a fix explains *why* the requirement reads the way it does).

### ⚠️ Scope boundary vs. Story 22.5 — read this before touching resume/timeout logic

Story 22.4's title is literally "Infrastructure, Permissions and **Background Pause**" — it does **not** include résumé-on-return, the inactivity timeout, notification-tap deep-linking, or auto-abandon. Those are Story 22.5's ACs verbatim (`epics.md:3035-3061`, "Inactivity Auto-Abandon, Resume and Deep-Link Reconciliation"). Concretely, **in this story**:

- **Do** post a notification and pause the in-session timer when the app backgrounds during an active session.
- **Do not** resume the timer when the app returns to the foreground. **Do not** implement the 5-minute inactivity timeout, the `backgroundedAt` persistence, the auto-abandon-through-FR20 flow, or any notification-tap handling/deep link.
- **Consequence (intentional, not a bug):** after this story ships alone, backgrounding a session freezes it until the app is restarted or Story 22.5 ships (which owns resuming it). Both stories are queued back-to-back in this sprint (epic-22 is `in-progress`, 22.5 is the next backlog item), so this interim state is short-lived by design — do not "fix" it by adding resume logic here; that would duplicate/conflict with 22.5's reconcile-on-resume machinery (which needs a persisted `backgroundedAt`, not just in-memory widget state, to survive process death per `review-delta-notification.md` 4d).
- The plugin's notification-tap callback (`onDidReceiveNotificationResponse`, registered once at `initialize()`) must exist in this story (the plugin API requires it at init time) but should be a **no-op / log-only** stub — Story 22.5 replaces it with real routing. Do not build routing logic against it now.

### What already exists (reuse, do not rebuild)

- **`InSessionCubit.pauseTimers()` / `resumeTimers()`** (`lib/features/session/presentation/bloc/in_session_cubit.dart:69-88`) — already cancels/restarts the 1s tick + HR poll timers, already used by the abandon-confirmation-sheet flow in `in_session_page.dart:159,189`. **Reuse `pauseTimers()` directly for the background-pause path** — do not write a second pause mechanism. (Do *not* call `resumeTimers()` on foreground return — see scope boundary above.)
- **`InSessionState.secondsRemaining`** (`in_session_state.dart`, current step's frozen countdown) is exactly the "paused timer" value already rendered on-screen via `in_session_view.dart:73` (`_formatTime(sessionState.secondsRemaining)`). Reuse this value verbatim for the notification body — it is already what the user was looking at the instant they backgrounded, so no new time-tracking is needed for this story's AC2 ("posted showing the session name and the frozen/paused timer").
- **`sessionDisplayName(sessionType, l10n)`** (`lib/features/today/presentation/widgets/session_card_helpers.dart:18-28`) — already maps `PlannedSession.sessionType` → the localized generic label ("Mobility"/"Cardio"/"Breathing"). This is the exact "generic exercise-category label" NFR39's lock-screen decision calls for — reuse it for the notification title, do not invent a new label.
- **Service-object pattern for platform plugins** (`HapticService`/`VibrationHapticService` in `haptic_service.dart`, `LiveHrService`/`HealthLiveHrService` in `live_hr_service.dart`) — an `abstract interface class` + one concrete implementation, constructed manually in `_InSessionPageState` (not via `get_it`/`injectable` — these are per-page, test-swappable objects, not app-wide singletons), with every platform call wrapped in `try/catch` → log + no-op so a missing/failing plugin channel (e.g. in `flutter test`'s headless binding) never throws past the service boundary. **Follow this exact pattern** for the new notification service — do not register it in `injection.config.dart`.
- **`WidgetsBindingObserver` + `didChangeAppLifecycleState`** (`lib/features/settings/presentation/pages/device_settings_page.dart:16-35`) — the only existing lifecycle-observer usage in the codebase. Mirror its `addObserver`/`removeObserver` in `initState`/`dispose` shape.
- **`_AbandonConfirmSheet`** (`in_session_page.dart:194-253`) is the closest existing "in-app confirmation dialog" precedent for the permission-rationale prompt (AC5) — a simple `showModalBottomSheet`/`AlertDialog` with title + body + two actions, no bespoke visual system to invent.

### Judgment calls made (flagged, not silently decided)

1. **Rationale prompt UI has no precedent to reuse verbatim.** The existing Health-permission flow (`device_settings_cubit.dart:53-58`, `health_data_source.dart:82-90`) calls `Health().requestAuthorization(...)` directly with **no custom pre-rationale dialog** — the OS/HealthKit/Health-Connect system prompt supplies its own copy. Android's `POST_NOTIFICATIONS` and iOS's notification-authorization system prompts have **no customizable body text**, so NFR39/AC5's "requested with a clear rationale" can only be satisfied by a custom in-app dialog shown *before* the OS prompt. This story adds one (`SessionNotificationRationaleDialog`, plain `AlertDialog`, two new ARB keys) — reusing `_AbandonConfirmSheet`'s visual weight (title + body + two `FilledButton`/`TextButton` actions), not inventing a new visual language. If Paolo wants a different treatment, this is an isolated, easily-swapped dialog.
2. **Rationale prompt trigger point = when the countdown finishes and the cubit starts** (`_onCountdownComplete`, `in_session_page.dart:57-80`), not at `initState`/route-entry. This is the literal reading of AC5's "the user first starts a session" — the countdown overlay is pre-session ceremony, not "the session" itself; gating on cubit-start also means the dialog never appears if the user backs out during the countdown. Only shown once per app run if permission status is `undetermined` (Android: not yet requested; iOS: `.notDetermined`) — an already-granted or already-permanently-denied status skips the dialog silently (AC6).
3. **`flutter_local_notifications` latest stable is `21.0.0`** (verified via pub.dev, 2026-07-07) — pin `^21.0.0`, not "latest pub.dev" verbatim, because this version introduced the `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>().requestNotificationsPermission()` API this story's AC5 depends on (older versions used a different method name). iOS/macOS settings classes are now unified under `DarwinInitializationSettings`/`DarwinNotificationDetails` (not the deprecated `IOSInitializationSettings`) — **verify the exact class/method names against the installed version's API docs at implementation time** (`dart pub deps` / package docs), since this plugin's iOS API surface has been renamed across majors more than once.
4. **Notification channel importance = `Importance.low`** (Android) — this is a status notification, not an alert; it should not visibly heads-up/pop over other apps or make sound. `Importance.low` shows silently in the shade/status bar without a heads-up banner, which best matches "I know a session is still open" (ambient awareness) rather than an urgent alert. If Paolo wants heads-up behavior, this is a one-line `Importance` change.
5. **Lock-screen visibility = `NotificationVisibility.public`** — per the 2026-07-06 decision baked into `prd.md`'s NFR39 ("the full session name is shown on the lock screen... low disclosure sensitivity"). This is not a judgment call, it's already decided — listed here only so the Android `AndroidNotificationDetails(visibility: ...)` field isn't left at its `private` default by oversight.

## Acceptance Criteria

**AC1 — `flutter_local_notifications` integrated, no foreground service:**
Given no notification stack exists in the project
When the notification capability is added
Then `flutter_local_notifications` is integrated with **no foreground service** — no `foregroundServiceType` declaration and no Play Console FGS justification (the timer pauses on background, so nothing runs) (addendum, review-delta-notification 1b).

**AC2 — Backgrounding pauses the timer and posts a notification:**
Given an active session
When the app is backgrounded
Then the session timer pauses (freezes at the current time) and a session notification is posted showing the session name and the frozen/paused timer, using a single fixed notification ID (FR79, FR80, review-delta-notification 4d).

**AC3 — Android: best-effort ongoing notification, tolerant of dismissal:**
Given the platform is Android
When the notification is posted
Then it is an ongoing notification (best-effort non-dismissible; on Android 14+ the OS permits user swipe-dismissal) — and dismissing it does NOT abandon the session (the FR80 timeout governs abandonment independently, out of scope here) (FR79, review-delta-notification 1a).

**AC4 — iOS: one-shot informational notification:**
Given the platform is iOS
When the notification is posted
Then it is a one-shot informational local notification with no guaranteed live-updating timer (the session still pauses reliably); a continuously updating pinned timer is explicitly out of scope (Live Activities deferred) (FR79).

**AC5 — Contextual permission prompt with rationale:**
Given notification permission has not yet been granted
When the user first starts a session (contextual prompt, not at app launch)
Then permission is requested with a clear rationale (Android 13+ `POST_NOTIFICATIONS`, iOS `UNUserNotificationCenter` authorization) (NFR39, review-delta-notification 1d/2b).

**AC6 — Denied permission degrades gracefully:**
Given notification permission is denied
When the app is backgrounded mid-session
Then the session still pauses in-app with no notification posted — graceful degradation, no error surfaced (NFR9, NFR39).

**AC7 — Lock-screen content is minimal and never biometric:**
Given the notification renders on the lock screen
When its content is shown
Then it exposes only the session name (a generic exercise-category label) and the paused timer, and **never** biometric/HR data (NFR39, NFR7).

## Tasks / Subtasks

---

### Task 1 — Add `flutter_local_notifications` dependency and platform config (AC1, AC3, AC7)

- [x] **1.1** Add `flutter_local_notifications: ^21.0.0` to `pubspec.yaml` dependencies (alphabetical position near `share_plus`/`url_launcher` per the file's existing loose grouping — see `pubspec.yaml:44-49`). Run `flutter pub get`.
- [x] **1.2** `android/app/src/main/AndroidManifest.xml`: add `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` alongside the existing permission block (`AndroidManifest.xml:2-6`). Do **not** add `foregroundServiceType` or any `<service>` declaration (AC1 — explicitly no FGS). `minSdk = 26` (`android/app/build.gradle.kts:28`) already satisfies the plugin's requirements; no SDK bump needed.
- [x] **1.3** iOS: no `Info.plist` key is required for local-notification runtime authorization (unlike Health/Location, `UNUserNotificationCenter` has no customizable usage-description string) — do not add one speculatively.

---

### Task 2 — `SessionNotificationService` (AC1–AC4, AC6, AC7)

- [x] **2.1** Create `lib/features/session/presentation/utils/session_notification_service.dart` following the `HapticService`/`VibrationHapticService` interface+impl shape exactly:
  ```dart
  enum NotificationPermissionStatus { granted, denied, undetermined }

  abstract interface class SessionNotificationService {
    Future<void> init();
    Future<NotificationPermissionStatus> permissionStatus();
    Future<bool> requestPermission();
    Future<void> showSessionPaused({
      required String sessionName,
      required int secondsRemaining,
    });
    Future<void> cancel();
  }
  ```
- [x] **2.2** Implement `LocalSessionNotificationService implements SessionNotificationService` wrapping a single `FlutterLocalNotificationsPlugin` instance:
  - `init()`: idempotent (guard with an internal bool, mirroring `VibrationHapticService._initialized`), calls `plugin.initialize(InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'), iOS: DarwinInitializationSettings()), onDidReceiveNotificationResponse: _onTap)` where `_onTap` is a **no-op / `AppLogger.info` stub** (see scope-boundary note — Story 22.5 replaces this). Wrap in `try/catch` → `AppLogger.warning` + no-op (must not throw in `flutter test`'s headless binding, which has no real plugin channel).
  - `permissionStatus()` / `requestPermission()`: resolve `AndroidFlutterLocalNotificationsPlugin`/`DarwinFlutterLocalNotificationsPlugin` via `plugin.resolvePlatformSpecificImplementation<...>()` — **verify exact method names against the installed `flutter_local_notifications: ^21.0.0` API docs** (judgment call #3 above); wrap every call in `try/catch` returning `false`/`denied` on failure, never throwing.
  - `showSessionPaused(...)`: builds `AndroidNotificationDetails(channelId: 'session_status', channelName: ..., importance: Importance.low, priority: Priority.low, ongoing: true, autoCancel: false, visibility: NotificationVisibility.public, showWhen: false)` + `DarwinNotificationDetails(presentAlert: true, presentBadge: false, presentSound: false)`, formats `secondsRemaining` as `mm:ss` (reuse/duplicate the tiny `_formatTime` helper already private to `in_session_view.dart:233` — it's a 3-line pure function, not worth exporting a shared util for), and calls `plugin.show(_notificationId, sessionName, formattedTime, details)` with **`static const int _notificationId = 1001;`** (AC2's "single fixed notification ID"). Wrap in `try/catch` → log + no-op (AC6: a plugin failure must never surface as an error to the user).
  - `cancel()`: `plugin.cancel(_notificationId)`, wrapped the same way.
- [x] **2.3** `permissionStatus()`/`requestPermission()` must return `denied`/`false` (never throw) when the plugin channel is unavailable — this is what makes AC6 hold structurally, not just by convention.

---

### Task 3 — Wire lifecycle observation into `InSessionPage` (AC2, AC3, AC4, AC7)

- [x] **3.1** In `lib/features/session/presentation/pages/in_session_page.dart`, add `with WidgetsBindingObserver` to `_InSessionPageState` (mirroring `device_settings_page.dart:16-35`): `WidgetsBinding.instance.addObserver(this)` in `initState`, `WidgetsBinding.instance.removeObserver(this)` in `dispose` (before the existing `_wearBridge?.stop()`/`_cubit?.close()` calls).
- [x] **3.2** Add a `SessionNotificationService _notificationService` field (constructed unconditionally in `initState`, e.g. `LocalSessionNotificationService()`, then `unawaited(_notificationService.init())` — mirror the existing `_hapticService.init()` fire-and-forget pattern at `in_session_page.dart:50`).
- [x] **3.3** Implement `didChangeAppLifecycleState(AppLifecycleState state)`:
  ```dart
  if (state == AppLifecycleState.paused) {
    final cubit = _cubit;
    final session = widget.session;
    if (cubit == null || session == null) return;
    if (cubit.state.isComplete || cubit.state.isAbandoned) return;
    cubit.pauseTimers();
    final l10n = AppLocalizations.of(context)!;
    unawaited(_notificationService.showSessionPaused(
      sessionName: sessionDisplayName(session.sessionType, l10n),
      secondsRemaining: cubit.state.secondsRemaining,
    ));
  }
  ```
  Do **not** branch on `AppLifecycleState.resumed`/`inactive`/`detached`/`hidden` in this story (scope boundary above). Guard on `cubit.state.isComplete`/`isAbandoned` so backgrounding *after* the session already ended (e.g. during the RPE-navigation transition) cannot post a stale notification for a session that no longer exists.
- [x] **3.4** Only wire this observer/service when `_countdownDone && _cubit != null` (i.e., there's an actual running session to pause) — during the pre-session `CountdownOverlay` phase there is nothing to pause, so `initState`/`dispose` registration is fine even before `_onCountdownComplete`, but `didChangeAppLifecycleState`'s early `cubit == null` return already makes the countdown phase a safe no-op; no separate guard needed beyond what's shown above.

---

### Task 4 — Contextual permission-rationale prompt (AC5, AC6)

- [x] **4.1** In `_onCountdownComplete` (`in_session_page.dart:57-80`), after constructing and starting the cubit, check `await _notificationService.permissionStatus()`; if `undetermined`, show a rationale dialog (new `SessionNotificationRationaleDialog`, plain `AlertDialog` with title/body/two actions — mirror `_AbandonConfirmSheet`'s structure, not its `showModalBottomSheet` mechanics) before/without blocking the already-started session; on "Allow", call `_notificationService.requestPermission()`; on "Not now"/dismiss, do nothing further (no repeat prompting this session — OS-level re-ask rules apply on subsequent sessions, matching how Health permission already behaves).
- [x] **4.2** Add two new ARB keys to both `lib/l10n/app/app_it.arb` and `lib/l10n/app/app_en.arb` (placement + metadata-block shape per the `heroCardSemanticPreamble` precedent, `app_it.arb:24-33`): `sessionNotificationRationaleTitle` / `sessionNotificationRationaleBody` (plain strings, no placeholders) and reuse existing generic `Consenti`/`Allow` + `Non ora`/`Not now` copy if such keys already exist in the ARB files (grep before adding new button-label keys — do not duplicate an existing "Not now"/"Allow" pair).
- [x] **4.3** Run `flutter gen-l10n` (or `flutter pub get`) so `AppLocalizations` exposes the new getters — not `build_runner` (separate pipeline, per Story 22.1–22.3 precedent).
- [x] **4.4** Denial path: if the user taps "Not now" or the OS prompt returns denied, `requestPermission()` resolving to `false` requires **no further action** — AC6 is satisfied structurally because `showSessionPaused` is itself wrapped in try/catch and `permissionStatus()`/OS-level denial simply means later `plugin.show(...)` calls silently no-op or throw-and-get-caught. Do not add a separate "permission denied → skip notification" branch in `didChangeAppLifecycleState`; the notification call is unconditional there and safe to attempt regardless of permission state (the plugin itself is the source of truth for whether the OS actually shows anything).

---

### Task 5 — Tests (AC1–AC7)

- [x] **5.1** `test/unit/session_notification_service_test.dart` (mirror `test/unit/haptic_service_test.dart`'s headless-binding style — no real plugin channel is available under `flutter test`):
  ```
  [22.4-SVC-001] LocalSessionNotificationService.init() does not throw with no platform channel present (returnsNormally)
  [22.4-SVC-002] permissionStatus()/requestPermission() resolve to denied/false (not throw) with no platform channel present
  [22.4-SVC-003] showSessionPaused(...) does not throw with no platform channel present (post-init)
  [22.4-SVC-004] cancel() does not throw with no platform channel present
  ```
- [x] **5.2** `test/widget/in_session_page_background_pause_test.dart` (new — mirror `test/widget/in_session_page_abandon_test.dart`'s `_wrap`/`_router`/`_pumpPastCountdown` helpers):
  ```
  [22.4-VIEW-001] pumping the widget past countdown, then dispatching AppLifecycleState.paused via
                  TestWidgetsFlutterBinding.instance.handleAppLifecycleStateChanged(...) (or the
                  equivalent public test API for the installed Flutter version — verify the exact
                  call at implementation time) → InSessionCubit's timer stops advancing
                  (pump additional seconds, assert secondsRemaining is unchanged)
  [22.4-VIEW-002] the same trigger when the session is already isComplete/isAbandoned → no exception,
                  no notification-service call (verify via a fake/mock SessionNotificationService
                  injected in place of the real one — may require a test-only constructor param on
                  InSessionPage/factoring the service out to an injectable field; do this the same
                  way _liveHrService is already nullable/injectable if a seam is needed)
  [22.4-VIEW-003] widget.session == null → AppLifecycleState.paused is a no-op (no crash)
  ```
  If `InSessionPage` has no existing seam to inject a fake `SessionNotificationService` for widget tests, add one (an optional constructor parameter defaulting to `null` → falls back to constructing the real `LocalSessionNotificationService`, exactly like `sessionLogsDao`/`hapticService`/`liveHrService` already work in `InSessionCubit`'s constructor) — do not skip this; without it, AC2/AC3/AC6 are only verifiable at the service-unit level, not the integration level.
- [x] **5.3 — check for fallout beyond these two new files.** `InSessionPage`'s constructor is unlikely to change shape (the new service defaults internally), but if a test seam is added per 5.2, re-run the full suite to confirm no existing `InSessionPage` construction site (`in_session_page_abandon_test.dart`, `app_router_test.dart` if it routes through `sessionActive`) breaks.
- [x] **5.4** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Confirm 0 analyzer issues and no regressions against the current baseline (1355 passed / 1 skipped as of Story 22.3).

---

## Dev Notes

### Why this story has no `DESIGN.md` entry to follow (unlike 22.1–22.3)

See `.decision-log.md:75`: the 2026-07-06 UX pass was explicitly redirected to only the three presentation-polish components; the notification feature was "parked" as a PRD/architecture concern. This means the permission-rationale dialog (Task 4) and the notification's Android channel/importance choices (Task 2) are this story's own reasonable defaults, not violations of an existing ratified spec — they are flagged individually above as judgment calls rather than presented as settled fact.

### This is not the "zero push" EXPERIENCE.md rule being violated

`EXPERIENCE.md:112` bans "notification re-engagement (v1 has zero push)" — that rule targets *marketing/engagement* pushes (come-back-and-train nudges), which this app has none of. FR79/FR80's session notification is a **system-status** notification (a paused-timer status indicator while a session the user themselves started is open), functionally analogous to a music-player's "now playing" notification, not a re-engagement push. Do not read `EXPERIENCE.md:112` as blocking this story — the PRD (FR79/FR80/NFR39, written and gate-reviewed after that EXPERIENCE.md rule existed) is the controlling spec here, and the two are not in conflict once "push" is read as "marketing," not "any system notification."

### Why `pauseTimers()`/no `resumeTimers()` wiring here

`pauseTimers()` already exists and is already exercised by the abandon-sheet flow — reusing it means this story adds zero new pause-mechanics code to `InSessionCubit` itself, only a new caller. Deliberately **not** calling `resumeTimers()` on `AppLifecycleState.resumed` is the load-bearing scope decision in this story (see "Scope boundary" above) — Story 22.5 owns the full reconcile-on-resume state machine (persisted `backgroundedAt`, timeout comparison, cold-start reconciliation), and a naive "just call `resumeTimers()` on resume" here would work for the simple case but would need to be *removed or heavily reworked* once 22.5 lands its timeout logic, since 22.5's resume path must first check "did the timeout already elapse" before deciding to resume vs. abandon — a decision this story's cubit-state alone cannot make (it has no persisted timestamp to compare against).

### Why a new service class instead of extending `HapticService`/`LiveHrService`

Each existing service wraps exactly one platform capability (vibration, live HR) with its own permission/capability model; notifications have a materially different lifecycle (persistent init + a global tap-callback registered once, vs. simple stateless calls). Following the same *pattern* (interface + concrete impl, manually constructed, try/catch-everywhere) without conflating it into an existing class keeps each service single-purpose, consistent with this codebase's existing structure.

### File Size Check

- New `session_notification_service.dart`: expect ~90–130 lines (interface + one impl class with 5 methods, each with error handling).
- New `session_notification_rationale_dialog.dart` (or inlined as a private widget in `in_session_page.dart` if small enough — judgment call, keep `in_session_page.dart` under ~350 lines total; currently 254): expect ~30–50 lines either way.
- `in_session_page.dart`: current 254 lines → +~35–50 lines (`WidgetsBindingObserver` mixin, service field, `didChangeAppLifecycleState`, rationale-check call in `_onCountdownComplete`). If this pushes the file past ~300 lines, extract the rationale dialog to its own file rather than inlining it as a private class (per this project's 200–400-line file-size convention).

### Project Structure Notes

**New production files:**
- `pulse_coach/lib/features/session/presentation/utils/session_notification_service.dart`
- `pulse_coach/lib/features/session/presentation/widgets/session_notification_rationale_dialog.dart` (or a private class in `in_session_page.dart` — see File Size Check)

**Modified production files:**
- `pulse_coach/pubspec.yaml` (new `flutter_local_notifications: ^21.0.0` dependency)
- `pulse_coach/android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS` permission)
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` (`WidgetsBindingObserver`, notification service field, lifecycle handler, rationale-check wiring)
- `pulse_coach/lib/l10n/app/app_it.arb`, `app_en.arb` (2 new rationale-dialog keys, possibly 0 if existing Allow/Not-now keys are reused)

**Auto-regenerated:**
- `.dart_tool/flutter_gen/...` generated `app_localizations*.dart` (via `flutter gen-l10n`/`pub get`, gitignored)

**New/modified test files:**
- `pulse_coach/test/unit/session_notification_service_test.dart` (new)
- `pulse_coach/test/widget/in_session_page_background_pause_test.dart` (new)
- Possibly `pulse_coach/test/widget/in_session_page_abandon_test.dart` — only if a constructor seam is added per Task 5.2 and that file's existing `InSessionPage` construction needs an explicit `null`/default passed for the new parameter (should be a no-op if the new param defaults correctly).

**Explicitly out of scope for this story:**
- Any resume-on-foreground logic, the inactivity timeout, `backgroundedAt` persistence, auto-abandon-through-FR20, and notification-tap deep-linking — all Story 22.5 (see Scope Boundary section above).
- A custom Android notification icon (uses the existing `@mipmap/ic_launcher` launcher icon) — a bespoke small-icon asset is a one-line follow-up if Paolo wants one later.
- Live Activities (iOS) — explicitly deferred per FR79/AC4.

### References

- [Source: epics.md#Story 22.4, lines 2991-3025 — full BDD ACs]
- [Source: epics.md#Epic 22, lines 2885-2893 — epic goal; net-new `flutter_local_notifications` dependency note, no-FGS rationale]
- [Source: epics.md#Story 22.5, lines 3027-3061 — the immediately-following story that owns resume/timeout/deep-link, defining this story's scope boundary]
- [Source: prd.md lines 643-644 — FR79/FR80 canonical text, incl. the Android-primary/iOS-best-effort platform-scope decision and the "rapid toggling does not accumulate" rule (owned by 22.5, not this story)]
- [Source: prd.md line 694 — NFR39 canonical text, incl. the 2026-07-06 lock-screen-visibility decision (full session name shown, low disclosure sensitivity)]
- [Source: prd.md lines 577,661,663,672 — FR20 (existing abandon flow, referenced but not touched here), NFR7 (biometric never leaves device), NFR9 (graceful permission-denial precedent), NFR15 (DB survives backgrounding — relevant to 22.5, not this story)]
- [Source: addendum.md lines 17-26 — "Ongoing session notification (FR79/FR80/NFR39)" mechanism note: Android ongoing notification + POST_NOTIFICATIONS, iOS one-shot/no-FGS rationale, reconcile-on-resume framing (22.5), Android 14+ dismissibility, iOS authorization]
- [Source: review-delta-notification.md — full PASS-WITH-FIXES gate review; fixes 1a/1b/1d/2a/3a/4d already folded into current FR79/FR80/NFR39 text; 1c/2b/2c/4a/4b/4c are Story 22.5's territory]
- [Source: .decision-log.md line 75 — UX pass explicitly parked the notification feature; no `DESIGN.md` component spec exists for it]
- [Source: ux-designs/.../EXPERIENCE.md line 112 — the "zero push" banned-pattern rule; see Dev Notes for why this story does not conflict with it]
- [Source: lib/features/session/presentation/bloc/in_session_cubit.dart:25,47,69-88 — `pauseTimers()`/`resumeTimers()` to reuse; injectable `DateTime Function() _now` clock precedent, not directly needed here but confirms the codebase's existing testable-time pattern]
- [Source: lib/features/session/presentation/bloc/in_session_state.dart, lib/features/session/presentation/widgets/in_session_view.dart:73,233 — `secondsRemaining` value and `_formatTime` helper to reuse/mirror for the notification body]
- [Source: lib/features/today/presentation/widgets/session_card_helpers.dart:18-28 — `sessionDisplayName()`, reused verbatim for the notification title/lock-screen text]
- [Source: lib/features/session/presentation/utils/haptic_service.dart, live_hr_service.dart — the service-object pattern (interface + concrete impl, manual construction, try/catch-everywhere) this story's `SessionNotificationService` follows]
- [Source: lib/features/settings/presentation/pages/device_settings_page.dart:16-35 — the only existing `WidgetsBindingObserver` usage in the codebase, mirrored for `_InSessionPageState`]
- [Source: lib/features/session/presentation/pages/in_session_page.dart — full current file (254 lines); every modification point cited above by line]
- [Source: lib/features/session/data/datasources/health_data_source.dart:82-90, lib/features/settings/presentation/bloc/device_settings_cubit.dart:53-58 — existing permission-request precedent (Health), confirming no custom rationale dialog exists yet for any permission in this codebase, hence judgment call #1]
- [Source: pubspec.yaml:1-90 — current dependency list; `vibration: ^3.1.8` already present (irrelevant to this story but confirms the haptic-service precedent's dependency); confirms `flutter_local_notifications` is genuinely net-new]
- [Source: android/app/src/main/AndroidManifest.xml, android/app/build.gradle.kts:28 — current permission block and `minSdk = 26`, confirming no SDK bump is needed]
- [Source: pub.dev `flutter_local_notifications` (web-verified 2026-07-07) — latest stable `21.0.0`; `AndroidFlutterLocalNotificationsPlugin.requestNotificationsPermission()` requires Android 13+/compileSdk 33+ (already satisfied by this project's Flutter SDK config); iOS/macOS settings unified under `Darwin*` classes, superseding the deprecated `IOSInitializationSettings`/`IOSFlutterLocalNotificationsPlugin` naming — verify exact current names against the installed version at implementation time, as this plugin's API has been renamed across majors before]
- [Source: 22-3-today-active-days-indicator-activedayscard.md — precedent for this story's format: exhaustive judgment-call documentation, explicit scope-boundary flagging against an adjacent story, file-size budgeting]

## Dev Agent Record

### Agent Model Used

claude-sonnet-5

### Debug Log References

- Verified installed `flutter_local_notifications: 21.0.0` API surface directly against package source (`~/.pub-cache/hosted/pub.dev/flutter_local_notifications-21.0.0`) before writing the service, per judgment call #3's instruction to confirm exact names at implementation time. Found the story's assumed `DarwinFlutterLocalNotificationsPlugin` type does not exist in this version — `resolvePlatformSpecificImplementation` only supports `AndroidFlutterLocalNotificationsPlugin`/`IOSFlutterLocalNotificationsPlugin`/`MacOSFlutterLocalNotificationsPlugin` individually (no unified Darwin plugin-resolution type; `DarwinInitializationSettings`/`DarwinNotificationDetails` value classes do exist and are used as documented). Implemented against `IOSFlutterLocalNotificationsPlugin` for iOS permission calls.
- Confirmed `DarwinInitializationSettings` defaults (`requestAlertPermission`/`requestBadgePermission`/`requestSoundPermission` all `true`) would auto-trigger the OS permission prompt at `init()` time on iOS, before the contextual rationale dialog — set all three to `false` at `init()` so `requestPermission()` (called only after the rationale dialog's "Allow" tap) is the sole iOS permission trigger, preserving AC5's "rationale before permission request" ordering.
- `AndroidNotificationDetails(channelId, channelName, ...)` and `FlutterLocalNotificationsPlugin.show(...)`/`.cancel(...)` all use named `id`/`title`/`body`/`notificationDetails` (not positional) — verified against source before writing calls.

### Completion Notes List

- All 5 tasks / 7 ACs complete via ATDD (failing test first, then implementation): `SessionNotificationService`/`LocalSessionNotificationService` (AC1–AC4, AC6, AC7), `WidgetsBindingObserver`-based lifecycle wiring in `InSessionPage` reusing `InSessionCubit.pauseTimers()` (AC2, AC3, AC4, AC7), and the contextual `SessionNotificationRationaleDialog` gated on `permissionStatus() == undetermined` at cubit-start (AC5, AC6).
- `permissionStatus()` maps to a best-effort tri-state: Android's `areNotificationsEnabled()` and iOS's `checkPermissions().isEnabled` are both booleans at the plugin API level (no true "not yet asked" vs "permanently denied" distinction is exposed by this plugin version) — `true` maps to `granted`, everything else (including no resolvable platform implementation, e.g. under `flutter test`'s headless binding) maps to `undetermined`/`denied` and never throws. This is a pragmatic reading of judgment call #1/#2, not a full three-way native check; re-prompting on an already-denied status is harmless since the OS gates the actual system dialog.
- `in_session_page.dart` grew from 254 to 298 lines (within the story's ~300-line budget) by extracting `SessionNotificationRationaleDialog` to its own widget file rather than inlining it, per the story's File Size Check guidance.
- Added a test seam (`InSessionPage.notificationService`, optional, defaults to `null` → constructs the real `LocalSessionNotificationService`) — no existing `InSessionPage` construction site needed updating (full suite green with zero fallout), so `in_session_page_abandon_test.dart` was not modified.
- Added a 4th widget test (`22.4-VIEW-004`) beyond the story's minimum 3, exercising the rationale-dialog path directly (undetermined status → dialog shown → Allow tap → `requestPermission()` called) since the other 3 tests all default the fake service to `granted` and never exercise Task 4's code path.
- `flutter analyze lib/ test/`: 0 issues. `flutter test`: 1363 passed / 1 skipped (baseline 1355/1 + 8 new: 4 unit + 4 widget), no regressions.

### File List

**New:**
- `pulse_coach/lib/features/session/presentation/utils/session_notification_service.dart`
- `pulse_coach/lib/features/session/presentation/widgets/session_notification_rationale_dialog.dart`
- `pulse_coach/test/unit/session_notification_service_test.dart`
- `pulse_coach/test/widget/in_session_page_background_pause_test.dart`

**Modified:**
- `pulse_coach/pubspec.yaml` (new `flutter_local_notifications: ^21.0.0` dependency)
- `pulse_coach/pubspec.lock` (regenerated by `flutter pub get`)
- `pulse_coach/android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS` permission)
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` (`WidgetsBindingObserver`, notification service field + test seam, lifecycle handler, rationale-check wiring)
- `pulse_coach/lib/l10n/app/app_it.arb`, `pulse_coach/lib/l10n/app/app_en.arb` (4 new rationale-dialog keys: title, body, allow, not-now — no existing generic Allow/Not-now keys found to reuse)

## Review Findings

_Code review 2026-07-07 (3-layer adversarial: Blind Hunter / Edge Case Hunter / Acceptance Auditor, Opus 4.8). All 7 ACs verified SATISFIED by the Acceptance Auditor; scope boundary vs. Story 22.5 confirmed clean._

- [x] [Review][Decision] Permission status collapses `denied`→`undetermined`; rationale dialog re-prompts every session — On Android `areNotificationsEnabled()==false` and iOS `checkPermissions().isEnabled==false` both map to `NotificationPermissionStatus.undetermined` (`session_notification_service.dart:75,86`), so a user who already declined is re-prompted on every session start. Deviated from judgment call #2. **Resolved (Paolo, option 2):** added a persisted `notification_rationale_shown` flag in `_maybeShowNotificationRationale` (read/write via `getIt<SharedPreferences>()`, guarded by `isRegistered` so headless tests are unaffected) — once the dialog has been shown (any answer), it is never re-shown. Doc comment on `SessionNotificationRationaleDialog` corrected to match. Covered by new test VIEW-007. Raised by blind+edge.
- [x] [Review][Patch] Add `mounted` guard before `AppLocalizations.of(context)!` in `didChangeAppLifecycleState` [`in_session_page.dart`] — added `if (!mounted) return;` after the `paused` check. Raised by blind+edge.
- [x] [Review][Patch] Add widget tests for the rationale-dialog deny path and status-based suppression [`in_session_page_background_pause_test.dart`] — added VIEW-005 (deny → `requestPermission` uncalled), VIEW-006 (granted suppresses dialog), VIEW-007 (persisted flag suppresses dialog). Raised by edge.

_Resolution 2026-07-07: all 3 findings fixed. `flutter analyze` 0 issues; `flutter test` 1366 passed / 1 skipped (baseline 1363/1 + 3 new tests), no regressions._

_Dismissed (7): no-resume-on-foreground + ongoing-notification-never-cancelled (both intentional, owned by Story 22.5 — confirmed by Acceptance Auditor; **22.5 must wire `resumeTimers()` and `cancel()`**); `showSessionPaused` fires regardless of permission (per Task 4.4, plugin is source of truth, try/catch-wrapped); `init()` fire-and-forget (all methods try/catch-guarded); `hidden`/`detached` unhandled (spec scopes to `paused` only); `AppLogger.debug` vs `info` on tap stub (cosmetic); iOS over-requests badge/sound scopes (harmless)._

## Change Log

- 2026-07-07: Story 22.4 created via create-story workflow. This is the epic's net-new-dependency story (`flutter_local_notifications`) and has no ratified `DESIGN.md` component spec (2026-07-06 UX pass explicitly parked the notification feature as a PRD/architecture concern). Scoped deliberately narrow — background-pause + notification infrastructure + permission prompt only — with resume/timeout/deep-link explicitly deferred to Story 22.5 (already queued next in the sprint) to avoid building resume logic that 22.5's reconcile-on-resume machinery would then have to rework. Flagged 5 judgment calls (rationale-dialog UI, prompt trigger point, exact plugin version/API surface, notification importance, and confirmed the already-decided lock-screen visibility) since no existing codebase precedent or ratified UX spec covers a custom permission-rationale dialog. Reuses `InSessionCubit.pauseTimers()`, `sessionDisplayName()`, and the existing `HapticService`/`LiveHrService` service-object pattern rather than introducing new mechanisms.
- 2026-07-07: dev-story implementation complete, moved to review. All 5 tasks/7 ACs done via ATDD (failing test first). Verified the installed `flutter_local_notifications: 21.0.0` API surface directly against package source before implementing — found the story's assumed `DarwinFlutterLocalNotificationsPlugin` resolvable type does not exist in this version (only per-platform `AndroidFlutterLocalNotificationsPlugin`/`IOSFlutterLocalNotificationsPlugin`), and set `DarwinInitializationSettings`'s permission-request flags to `false` at init so the contextual rationale dialog (not plugin `init()`) is the sole iOS permission trigger, preserving AC5's ordering. 8 new tests (4 unit + 4 widget, including one beyond the story's minimum to directly exercise the rationale-dialog path). `flutter analyze` 0 issues; `flutter test` 1363 passed/1 skipped (baseline 1355/1 + 8 new), no regressions. No existing `InSessionPage` construction site required changes despite the new optional `notificationService` test seam.
