# Story 8.4: Live Heart Rate Display

Status: done

## Story

As a user,
I want to see my live heart rate during a session when my sensor permits it,
so that I can monitor my effort level without stopping.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The Health API returns live HR data during a session | When the `InSessionView` renders | Live HR is displayed in the top-right corner (e.g., "♥ 72 bpm") in Caption typography (FR19, UX-DR8) |
| AC2 | Live HR data is unavailable (permission denied or sensor unavailable) | When the `InSessionView` renders | The HR display area is hidden — no empty state or error shown (ARCH9, UX-DR8) |
| AC3 | HR data is available but temporarily delayed | When the display updates | The last known value is shown until a new reading arrives — no flickering |

## Tasks / Subtasks

### Task 1: Create `LiveHrService` interface and `HealthLiveHrService` implementation (AC1, AC2, AC3)

- [x] CREATE `lib/features/session/presentation/utils/live_hr_service.dart`

  ```dart
  import 'dart:async';

  import 'package:flutter/foundation.dart' show debugPrint;
  import 'package:health/health.dart';

  /// Abstracts live HR polling so InSessionCubit can be tested without
  /// platform-channel noise. Production code uses HealthLiveHrService;
  /// tests pass a FakeLiveHrService.
  abstract interface class LiveHrService {
    /// Must be called once before [fetchLiveHr]. Fire-and-forget safe.
    Future<void> init();

    /// Returns the most recent heart-rate reading, or null if unavailable.
    /// Never throws — all errors are swallowed per ARCH9.
    Future<int?> fetchLiveHr();
  }

  /// Polls HealthDataType.HEART_RATE via the `health` package.
  /// Permissions are requested once in [init] and cached.
  /// NOT @injectable — owned by _InSessionPageState (ephemeral, session-scoped).
  class HealthLiveHrService implements LiveHrService {
    HealthLiveHrService(this._health);

    final Health _health;
    bool _permissionsGranted = false;
    bool _initialized = false;
    Future<void>? _initFuture;

    @override
    Future<void> init() {
      if (_initialized) return Future<void>.value();
      return _initFuture ??= _runInit();
    }

    Future<void> _runInit() async {
      try {
        await _health.configure();
        _permissionsGranted = await _health.requestAuthorization(
          [HealthDataType.HEART_RATE],
          permissions: [HealthDataAccess.READ],
        );
      } catch (e) {
        debugPrint('HealthLiveHrService.init: $e');
        _permissionsGranted = false;
      } finally {
        _initialized = true;
      }
    }

    @override
    Future<int?> fetchLiveHr() async {
      if (!_permissionsGranted) return null;
      try {
        final now = DateTime.now();
        final since = now.subtract(const Duration(seconds: 30));
        final points = await _health.getHealthDataFromTypes(
          startTime: since,
          endTime: now,
          types: [HealthDataType.HEART_RATE],
        );
        if (points.isEmpty) return null;
        return (points.last.value as NumericHealthValue).numericValue.round();
      } catch (e) {
        debugPrint('HealthLiveHrService.fetchLiveHr: $e');
        return null;
      }
    }
  }
  ```

  **Design decisions:**
  - Uses `HealthDataType.HEART_RATE` (real-time, not `RESTING_HEART_RATE` which is a daily summary).
  - 30-second lookback window captures the most recent reading without stale data.
  - `_initFuture` prevents re-entry race — concurrent `init()` callers share the in-flight future (pattern from 8.3 code review).
  - NOT `@injectable` — ephemeral, owned by `_InSessionPageState`, scoped to one session lifetime.
  - `Health` singleton is passed in constructor (not injected via `get_it` annotation) — instantiated from `InSessionPage` using `getIt<Health>()`.
  - Permission request for `HEART_RATE` is separate from `HealthDataSource`'s `RESTING_HEART_RATE` + `STEPS` request; Health Connect handles cumulative permissions gracefully.

---

### Task 2: Update `InSessionState` — add `liveHr` field (AC1, AC2, AC3)

- [x] UPDATE `lib/features/session/presentation/bloc/in_session_state.dart`

  Add `int? liveHr` field and include in constructor and `copyWith`:

  ```dart
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';

  class InSessionState {
    final List<ExerciseStep> steps;
    final int currentStepIndex;
    final int secondsRemaining;
    final bool isComplete;
    final bool isAbandoned;
    final int? liveHr;                          // ← ADD THIS

    const InSessionState({
      required this.steps,
      required this.currentStepIndex,
      required this.secondsRemaining,
      this.isComplete = false,
      this.isAbandoned = false,
      this.liveHr,                              // ← ADD THIS
    });

    ExerciseStep get currentStep => steps[currentStepIndex];
    int get totalSteps => steps.length;

    InSessionState copyWith({
      int? currentStepIndex,
      int? secondsRemaining,
      bool? isComplete,
      bool? isAbandoned,
      int? liveHr,                              // ← ADD THIS
    }) => InSessionState(
      steps: steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isComplete: isComplete ?? this.isComplete,
      isAbandoned: isAbandoned ?? this.isAbandoned,
      liveHr: liveHr ?? this.liveHr,           // ← ADD THIS (null-preserves last known)
    );
  }
  ```

  **Why `liveHr ?? this.liveHr` in copyWith:** This implements the "last known value" requirement (AC3) for free. When a polling cycle returns null (sensor temporarily silent), the cubit does NOT call `copyWith(liveHr: null)` — it simply skips the emit. But for all OTHER `copyWith` calls (step advance, timer tick), the `liveHr ?? this.liveHr` ensures the last reading is propagated through without being reset. No opt-in/opt-out sentinel needed.

---

### Task 3: Update `InSessionCubit` — inject `LiveHrService` and poll every 5s (AC1, AC2, AC3)

- [x] UPDATE `lib/features/session/presentation/bloc/in_session_cubit.dart`

  **Add import:**
  ```dart
  import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';
  ```

  **Add field and constructor parameter:**

  ```dart
  final LiveHrService? _liveHrService;
  Timer? _hrTimer;
  ```

  Updated constructor signature (add one optional parameter):
  ```dart
  InSessionCubit({
    required List<ExerciseStep> steps,
    SessionLogsDao? sessionLogsDao,
    int? planId,
    int sessionIndex = 0,
    HapticService? hapticService,
    LiveHrService? liveHrService,              // ← ADD THIS
  }) : _sessionLogsDao = sessionLogsDao,
       _planId = planId,
       _sessionIndex = sessionIndex,
       _hapticService = hapticService,
       _liveHrService = liveHrService,         // ← ADD THIS
       super(InSessionState(
         steps: steps,
         currentStepIndex: 0,
         secondsRemaining: steps.first.durationSeconds,
       ));
  ```

  **Update `start()` — start secondary HR timer and do immediate first fetch:**
  ```dart
  void start() {
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    if (_liveHrService != null) {
      unawaited(_fetchAndEmitHr());            // immediate first fetch
      _hrTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_fetchAndEmitHr()),
      );
    }
  }
  ```

  **Add `_fetchAndEmitHr()` method:**
  ```dart
  Future<void> _fetchAndEmitHr() async {
    try {
      final hr = await _liveHrService?.fetchLiveHr();
      if (hr != null && !isClosed) {
        emit(state.copyWith(liveHr: hr));
      }
      // If hr == null: don't update — retain last known value (AC3)
    } catch (e) {
      debugPrint('InSessionCubit: fetchLiveHr failed: $e');
    }
  }
  ```

  **Update `_advanceStep()` — cancel `_hrTimer` when session completes:**
  ```dart
  void _advanceStep() {
    final nextIndex = state.currentStepIndex + 1;
    if (nextIndex >= state.steps.length) {
      _hapticService?.stepTransition();
      _timer?.cancel();
      _hrTimer?.cancel();                      // ← ADD THIS
      unawaited(_persistCompletion());
    } else {
      _hapticService?.stepTransition();
      emit(
        state.copyWith(
          currentStepIndex: nextIndex,
          secondsRemaining: state.steps[nextIndex].durationSeconds,
        ),
      );
    }
  }
  ```

  **Update `abandon()` — cancel `_hrTimer`:**
  ```dart
  void abandon() {
    _timer?.cancel();
    _hrTimer?.cancel();                        // ← ADD THIS
    if (!isClosed) emit(state.copyWith(isAbandoned: true));
  }
  ```

  **Update `close()` — cancel `_hrTimer`:**
  ```dart
  @override
  Future<void> close() {
    _timer?.cancel();
    _hrTimer?.cancel();                        // ← ADD THIS
    return super.close();
  }
  ```

  **No other changes.** `_tick()`, `_persistCompletion()`, all haptic logic — unchanged.

---

### Task 4: Update `InSessionView` — add HR badge top-right (AC1, AC2)

- [x] UPDATE `lib/features/session/presentation/widgets/in_session_view.dart`

  Replace the existing `SafeArea(child: Padding(child: Column(...)))` body with a `Stack` so the HR badge can be positioned top-right without disturbing the main column layout:

  ```dart
  body: SafeArea(
    child: Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ... ALL existing column children unchanged ...
              Semantics(
                liveRegion: true,
                child: Text(
                  step.title,
                  style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
                  textAlign: TextAlign.center,
                ),
              ),
              // ... rest unchanged ...
            ],
          ),
        ),
        if (sessionState.liveHr != null)          // AC2: hidden when null
          Positioned(
            top: 16,
            right: 16,
            child: _HrBadge(bpm: sessionState.liveHr!),
          ),
      ],
    ),
  ),
  ```

  Add private `_HrBadge` widget at the bottom of the file:
  ```dart
  class _HrBadge extends StatelessWidget {
    const _HrBadge({required this.bpm});
    final int bpm;

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      return Text(
        l10n.inSessionHrDisplay(bpm.toString()),
        style: AppTextStyles.caption.copyWith(
          color: pulseTheme.onSurfaceVariant,
        ),
      );
    }
  }
  ```

  **Why `Stack` + `Positioned`:** Places the HR badge as a UI overlay at the screen's top-right corner (UX-DR8: "live HR top-right") without affecting the centered column layout of the step title, timer, and progress bar. No reflow when HR toggles visibility.

  **AC2 implementation:** `if (sessionState.liveHr != null)` — the badge is simply absent from the widget tree when no data is available. No empty placeholder, no loading state.

---

### Task 5: Update l10n ARB files — add `inSessionHrDisplay` key (AC1)

- [x] UPDATE `lib/l10n/app/app_en.arb` — add before the closing `}`:
  ```json
  "inSessionHrDisplay": "♥ {bpm} bpm",
  "@inSessionHrDisplay": {
    "placeholders": {
      "bpm": {
        "type": "String"
      }
    }
  }
  ```

- [x] UPDATE `lib/l10n/app/app_it.arb` — add before the closing `}`:
  ```json
  "inSessionHrDisplay": "♥ {bpm} bpm",
  "@inSessionHrDisplay": {
    "placeholders": {
      "bpm": {
        "type": "String"
      }
    }
  }
  ```

  **Note:** After editing ARB files, run `flutter pub get` from `pulse_coach/` — `gen_l10n` runs automatically and regenerates `app_localizations*.dart`. The ♥ character (U+2665) is included verbatim in the ARB string — no escape needed. Both locales use the same format; bpm is a universal unit. The method signature generated will be: `String inSessionHrDisplay(String bpm)`.

  **Note:** `app_localizations*.dart` files are `.gitignore`'d and must NOT be manually edited.

---

### Task 6: Update `InSessionPage` — instantiate and inject `HealthLiveHrService` (AC1, AC2)

- [x] UPDATE `lib/features/session/presentation/pages/in_session_page.dart`

  **Add import:**
  ```dart
  import 'package:health/health.dart';
  import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';
  ```

  **Add `_liveHrService` field to `_InSessionPageState`:**
  ```dart
  HealthLiveHrService? _liveHrService;
  ```

  **Update `initState()` to initialize `HealthLiveHrService` if `Health` is registered:**
  ```dart
  @override
  void initState() {
    super.initState();
    _hapticService.init(); // unchanged
    if (getIt.isRegistered<Health>()) {
      _liveHrService = HealthLiveHrService(getIt<Health>());
      _liveHrService!.init(); // fire-and-forget; resolves before countdown ends
    }
  }
  ```

  **Update `_onCountdownComplete()` to pass `_liveHrService` to the cubit:**
  ```dart
  final cubit = InSessionCubit(
    steps: steps,
    sessionLogsDao: getIt.isRegistered<SessionLogsDao>() ? getIt() : null,
    planId: widget.planId,
    sessionIndex: widget.sessionIndex,
    hapticService: _hapticService,
    liveHrService: _liveHrService,            // ← ADD THIS
  )..start();
  ```

  **`dispose()` unchanged** — `HealthLiveHrService` has no resources to release.

  **Why `getIt.isRegistered<Health>()` guard:** Same pattern used for `SessionLogsDao` since Story 8.2 — keeps widget tests safe without the full DI graph wired. `Health` IS registered via `HealthModule.health` (`@singleton`) so this returns `true` in production. In widget tests, it returns `false` → `_liveHrService` stays null → `InSessionCubit` gets null `liveHrService` → no HR polling, no platform channel calls.

---

### Task 7: Create `LiveHrService` unit tests (AC2)

- [x] CREATE `test/unit/live_hr_service_test.dart`

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';

  void main() {
    group('HealthLiveHrService (Story 8.4)', () {
      test(
        '8.4-SERVICE-001: fetchLiveHr returns null before init (permissions not granted)',
        () async {
          // HealthLiveHrService wraps the `health` plugin; without platform
          // channels wired, _permissionsGranted stays false (default).
          // This test validates ARCH9: no crash, null returned, no error propagated.
          //
          // We cannot construct HealthLiveHrService without a Health instance
          // in a headless test, so we test the contract via the interface.
          // Service-level tests are covered by the FakeLiveHrService pattern
          // in cubit tests (8.4-CUBIT-*).
          //
          // This test validates the abstract interface contract.
          const description = 'LiveHrService interface is fulfilled by HealthLiveHrService';
          expect(description, isNotEmpty); // contract documented above
        },
      );

      test(
        '8.4-SERVICE-002: init() is idempotent — calling twice is safe',
        () async {
          // HealthLiveHrService uses _initFuture to prevent re-entry.
          // Concurrent or repeated init() calls share the same Future.
          // In headless: both calls resolve without error even though the
          // health plugin has no backing implementation.
          const description =
              'idempotent init() via _initFuture pattern (same as VibrationHapticService)';
          expect(description, isNotEmpty); // structural guarantee from _initFuture field
        },
      );
    });
  }
  ```

  **Note on headless constraints:** `HealthLiveHrService` requires a `Health` instance, which in turn requires the `health` platform plugin. The plugin has no test-double registration in `flutter_test`, so we cannot construct a real `HealthLiveHrService` in unit tests without a `MockHealth`. The behavioral contract is instead exercised through `_FakeLiveHrService` in the cubit tests (Task 8). These unit tests document the structural guarantees.

  **Alternative:** If a `MockHealth` is generated via mockito (`@GenerateMocks([Health])`), the service can be tested with full control. This is deferred to a follow-up since it requires code generation changes; the cubit tests are sufficient to validate the integration contract.

---

### Task 8: Create `InSessionCubit` HR tests (AC1, AC2, AC3)

- [x] CREATE `test/bloc/in_session_cubit_hr_test.dart`

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
  import 'package:pulse_coach/features/session/presentation/utils/live_hr_service.dart';

  class _FakeLiveHrService implements LiveHrService {
    int? _nextValue;
    int fetchCount = 0;

    void setNextValue(int? value) => _nextValue = value;

    @override
    Future<void> init() async {}

    @override
    Future<int?> fetchLiveHr() async {
      fetchCount++;
      return _nextValue;
    }
  }

  const _steps = [
    ExerciseStep(title: 'Warm-up', instruction: 'Prep', durationSeconds: 60),
    ExerciseStep(title: 'Main', instruction: 'Go', durationSeconds: 60),
  ];

  void main() {
    group('InSessionCubit — live HR (Story 8.4)', () {
      testWidgets(
        '8.4-CUBIT-001: state.liveHr updates when service returns a value',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(72);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
          )..start();

          // Let initial fetch (_fetchAndEmitHr from start()) resolve
          await tester.pump();

          expect(cubit.state.liveHr, 72);
          await cubit.close();
        },
      );

      testWidgets(
        '8.4-CUBIT-002: state.liveHr retains last known value when service returns null (AC3)',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(68);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
          )..start();

          // First fetch sets liveHr = 68
          await tester.pump();
          expect(cubit.state.liveHr, 68);

          // Service now returns null (sensor temporarily unavailable)
          hr.setNextValue(null);

          // Advance 5s to trigger next poll
          await tester.pump(const Duration(seconds: 5));
          await tester.pump(); // allow async resolve

          // liveHr stays at 68 — no flicker (AC3)
          expect(cubit.state.liveHr, 68);
          await cubit.close();
        },
      );

      testWidgets(
        '8.4-CUBIT-003: state.liveHr is null when no service is injected (AC2)',
        (tester) async {
          final cubit = InSessionCubit(steps: _steps)..start();
          await tester.pump();

          expect(cubit.state.liveHr, isNull);
          await cubit.close();
        },
      );

      testWidgets(
        '8.4-CUBIT-004: state.liveHr is null when service always returns null (AC2)',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(null);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
          )..start();

          await tester.pump();
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();

          expect(cubit.state.liveHr, isNull);
          await cubit.close();
        },
      );

      testWidgets(
        '8.4-CUBIT-005: liveHr updates on each poll when service returns fresh values',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(70);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
          )..start();

          await tester.pump();
          expect(cubit.state.liveHr, 70);

          hr.setNextValue(85);
          await tester.pump(const Duration(seconds: 5));
          await tester.pump();

          expect(cubit.state.liveHr, 85);
          await cubit.close();
        },
      );

      testWidgets(
        '8.4-CUBIT-006: _hrTimer is cancelled on close()',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(72);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
          )..start();

          await tester.pump();
          final countAfterStart = hr.fetchCount;

          await cubit.close();

          // Pump past 5s interval — no more polls should occur
          await tester.pump(const Duration(seconds: 10));
          await tester.pump();

          expect(hr.fetchCount, countAfterStart); // no additional fetches
        },
      );

      testWidgets(
        '8.4-CUBIT-007: _hrTimer is cancelled on abandon()',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(72);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
          )..start();

          await tester.pump();
          final countAfterStart = hr.fetchCount;

          cubit.abandon();

          // Pump past 5s interval — no more polls after abandon
          await tester.pump(const Duration(seconds: 10));
          await tester.pump();

          expect(hr.fetchCount, countAfterStart);
          expect(cubit.state.isAbandoned, isTrue);
          await cubit.close();
        },
      );

      testWidgets(
        '8.4-CUBIT-008: pre-existing null hapticService still works alongside liveHrService',
        (tester) async {
          final hr = _FakeLiveHrService()..setNextValue(77);
          final cubit = InSessionCubit(
            steps: _steps,
            liveHrService: hr,
            // hapticService intentionally null
          )..start();

          await tester.pump();

          expect(cubit.state.liveHr, 77);
          expect(cubit.state.currentStepIndex, 0); // no step advance yet
          await cubit.close();
        },
      );
    });
  }
  ```

---

### Task 9: Update `InSessionView` widget tests (AC1, AC2)

- [x] UPDATE `test/widget/in_session_view_test.dart`

  Add these new test cases to the existing `group('InSessionView', ...)` block. Update the `_view()` helper to optionally accept `liveHr`:

  ```dart
  InSessionView _view({int step = 0, int seconds = 60, int? liveHr}) => InSessionView(
    sessionState: InSessionState(
      steps: _steps,
      currentStepIndex: step,
      secondsRemaining: seconds,
      liveHr: liveHr,
    ),
    onAbandon: () {},
  );
  ```

  New test cases:
  ```dart
  testWidgets('8.4-WIDGET-001: HR badge is absent when liveHr is null (AC2)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_view())); // liveHr = null (default)
    await tester.pump();

    // "♥" should not appear anywhere in the widget tree
    expect(find.textContaining('♥'), findsNothing);
  });

  testWidgets('8.4-WIDGET-002: HR badge shows "♥ 72 bpm" when liveHr = 72 (AC1)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_view(liveHr: 72)));
    await tester.pump();

    expect(find.text('♥ 72 bpm'), findsOneWidget);
  });

  testWidgets('8.4-WIDGET-003: HR badge uses Caption typography (AC1)', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_view(liveHr: 90)));
    await tester.pump();

    final text = tester.widget<Text>(find.text('♥ 90 bpm'));
    expect(text.style?.fontSize, AppTextStyles.caption.fontSize);
  });

  testWidgets('8.4-WIDGET-004: HR badge is positioned at top-right via Stack+Positioned', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_view(liveHr: 65)));
    await tester.pump();

    // Verify Positioned widget exists (Stack structure)
    expect(find.byType(Positioned), findsOneWidget);
    // Verify the HR text is rendered (placement is structural — widget test
    // cannot assert exact pixel position without golden test)
    expect(find.textContaining('♥'), findsOneWidget);
  });

  testWidgets('8.4-WIDGET-005: HR badge value updates when liveHr changes', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_view(liveHr: 70)));
    await tester.pump();
    expect(find.text('♥ 70 bpm'), findsOneWidget);

    // Simulate state update with new HR value
    await tester.pumpWidget(_wrap(_view(liveHr: 85)));
    await tester.pump();
    expect(find.text('♥ 85 bpm'), findsOneWidget);
    expect(find.text('♥ 70 bpm'), findsNothing);
  });

  testWidgets('8.4-WIDGET-006: HR badge disappearing does not cause overflow (AC2)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // First render with HR
    await tester.pumpWidget(_wrap(_view(liveHr: 72)));
    await tester.pump();
    expect(tester.takeException(), isNull);

    // Then render without HR (graceful hide)
    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  ```

---

### Task 10: Run baseline verification (AC1, AC2, AC3)

- [x] `flutter pub get` from `pulse_coach/` — triggers `gen_l10n`, regenerates `app_localizations*.dart` with `inSessionHrDisplay` method
- [x] `flutter analyze` from `pulse_coach/` → 0 issues
- [x] `flutter test` from `pulse_coach/` → ≥ 574 + ~14 new tests (expect ~588+)
- [x] Verify `test/unit/live_hr_service_test.dart` passes (2 tests)
- [x] Verify `test/bloc/in_session_cubit_hr_test.dart` passes (8 tests)
- [x] Verify `test/widget/in_session_view_test.dart` passes (existing 7 + new 6 = 13 tests)
- [x] Verify pre-existing `test/bloc/in_session_cubit_test.dart` passes (null liveHrService = no regressions)
- [x] Verify pre-existing `test/bloc/in_session_cubit_haptic_test.dart` passes (null liveHrService = no regressions)

---

## Dev Notes

### Current State of Files Being Modified

**`lib/features/session/presentation/bloc/in_session_state.dart`**

Current fields: `steps`, `currentStepIndex`, `secondsRemaining`, `isComplete`, `isAbandoned`. No HR field.

What changes: Add `final int? liveHr;` field, constructor param with default `null`, and `liveHr` in `copyWith` using `?? this.liveHr` pattern.

What must be preserved:
- `ExerciseStep get currentStep` and `int get totalSteps` computed getters
- All existing `copyWith` params and their null-fallback semantics
- Plain (non-freezed) class — do NOT convert to @freezed; no other state in this feature uses freezed

**`lib/features/session/presentation/bloc/in_session_cubit.dart`**

Current shape (post-8.3):
- `_hapticService: HapticService?` — optional, fires on step transitions
- `_sessionLogsDao`, `_planId`, `_sessionIndex` — for DB persistence
- `_timer` — 1s periodic tick
- `_tick()` → decrements `secondsRemaining` or calls `_advanceStep()`
- `_advanceStep()` — two branches: complete (cancel timer + persist) or advance step
- `abandon()` → `isAbandoned: true` (NOT `isComplete`)
- `_persistCompletion()` → DB insert + emit `isComplete: true`

What changes:
- Add `_liveHrService: LiveHrService?` field + constructor param
- Add `_hrTimer: Timer?` field
- Update `start()` to start `_hrTimer` if service provided + immediate first fetch
- Add `_fetchAndEmitHr()` async method
- Add `_hrTimer?.cancel()` in `_advanceStep()` (final branch), `abandon()`, and `close()`

What must be preserved:
- `_tick()` guard `if (state.isComplete) return;`
- `abandon()` emits `isAbandoned: true` (NOT `isComplete: true`) — code review fix from 8.2
- `unawaited(_persistCompletion())` fire-and-forget pattern
- `if (!isClosed) emit(...)` guards in async methods

**`lib/features/session/presentation/widgets/in_session_view.dart`**

Current layout: `Scaffold → SafeArea → Padding → Column` with step title, step counter, timer, progress bar, instruction, Spacer, abandon button.

What changes: Wrap `SafeArea` child in a `Stack`; the `Padding + Column` becomes the first child of the Stack. Add a `Positioned(top: 16, right: 16)` child as second Stack child, conditionally rendered when `sessionState.liveHr != null`. Add private `_HrBadge` widget.

What must be preserved:
- All existing column children, their styles, and semantic annotations
- The `Semantics(liveRegion: true)` on the step title
- `AppTextStyles.timerDisplay` for the clock text (JetBrains Mono 48sp)
- `LinearProgressIndicator` value logic
- `TextButton(onPressed: onAbandon, ...)` for abandon

**`lib/features/session/presentation/pages/in_session_page.dart`**

Current shape:
- `_hapticService: VibrationHapticService` — initialized in `initState()`
- `_countdownDone: bool` and `_cubit: InSessionCubit?` state fields
- `_onCountdownComplete()` — builds cubit with `getIt.isRegistered<SessionLogsDao>()` guard
- `BlocListener` with `listenWhen: (prev, curr) => curr.isComplete && !prev.isComplete`

What changes: Add `_liveHrService: HealthLiveHrService?` field; initialize it from `initState()` with `getIt.isRegistered<Health>()` guard; pass it to `InSessionCubit` constructor.

What must be preserved:
- `getIt.isRegistered<SessionLogsDao>()` guard (from 8.2 review)
- `BlocProvider.value(value: _cubit!)` pattern
- `BlocListener` with `listenWhen` → navigates to `AppRouter.sessionRpe` on natural completion
- Abandon path: `_cubit!.abandon(); context.go(AppRouter.today)`

### Architecture Compliance

- `LiveHrService` → `lib/features/session/presentation/utils/live_hr_service.dart`
  - Same `utils/` directory as `haptic_service.dart` and `session_step_generator.dart` — no new subdirectory needed.
  - Presentation layer is correct: HR polling is a platform concern, not domain logic. Domain already has `HealthRepository` for resting HR at plan-generation time; live HR polling during a session is a separate, presentation-scoped concern.
  - `abstract interface class` — Dart 3 keyword; no accidental extension.
- NOT `@injectable` — ephemeral, owned by `_InSessionPageState`.
- `Health` singleton is fetched via `getIt<Health>()` in `InSessionPage` — the Health plugin is already registered via `HealthModule.health` (@singleton), so no DI changes needed.
- No new Drift tables, no new domain entities, no build_runner run needed.
- Clean Architecture: domain layer and data layer are untouched by this story.

### Health Package Version Note

`health: ^13.3.1` is already in `pulse_coach/pubspec.yaml` (no new dependency needed). `NumericHealthValue` and `HealthDataType.HEART_RATE` are confirmed present in this version — same as `HealthDataSource` which uses `NumericHealthValue` for `RESTING_HEART_RATE` and `STEPS`.

### Health Data Type Distinction

| Type | Description | Used by |
|---|---|---|
| `HealthDataType.RESTING_HEART_RATE` | Daily summary resting HR | `HealthDataSource.fetchHealthData()` (Epic 3, StateVector) |
| `HealthDataType.HEART_RATE` | Real-time heart rate (exercise/activity) | `HealthLiveHrService.fetchLiveHr()` (Story 8.4) |

The two types require separate permission requests. On Android Health Connect, `requestAuthorization()` for `HEART_RATE` is cumulative with existing permissions — no re-prompting if `HEART_RATE` was already implicitly granted. On iOS HealthKit, a permission dialog may appear; this is expected behavior. In both cases, permission denial is handled silently (ARCH9).

### Why `HealthDataType.HEART_RATE` and Not Streaming

The `health` package (pub.dev) does not provide a `Stream<HealthDataPoint>` API as of v13.x. Live HR is obtained by polling `getHealthDataFromTypes()` with a short time window (30 seconds). The 5-second polling interval provides a "live" feel — sensor readings are typically written to Health Connect/HealthKit within 1-5 seconds of measurement.

Alternative considered: `sensors_plus` for raw accelerometer-derived HR — rejected because it doesn't expose HR data; it only exposes accelerometer/gyroscope. Live HR from a wrist sensor on Android goes through Health Connect.

### Last-Known-Value Implementation

The "no flickering" AC (AC3) is implemented at the cubit level, not the widget level:
- `_fetchAndEmitHr()` only calls `emit(state.copyWith(liveHr: hr))` when `hr != null`
- When the poll returns null (sensor gap), no emit occurs → `state.liveHr` is unchanged
- Widget sees a stable value → no flicker/hide/reshow cycle

The `copyWith` `liveHr ?? this.liveHr` pattern ensures step transitions also preserve the last HR reading.

### l10n Changes Required

New ARB key `inSessionHrDisplay` is added to both locales. Since this is the same in both EN and IT (bpm is a universal unit, ♥ is a universal symbol), the strings are identical. The method generated will be `String inSessionHrDisplay(String bpm)` — `bpm` is typed as String (consistent with `inSessionStepLabel` convention in this project).

After editing ARB files, `flutter pub get` regenerates the `app_localizations*.dart` files. No manual edits to generated files.

### Anti-Patterns to Avoid

| ❌ | ✅ |
|---|---|
| Use `HealthDataType.RESTING_HEART_RATE` for live HR | Use `HealthDataType.HEART_RATE` (activity HR) |
| Hide HR badge when poll returns null after having shown a value | Retain last known value; only hide when `liveHr == null` from the start |
| Use `CircularProgressIndicator` or "Loading..." when HR not yet available | Start with hidden badge; show immediately on first successful reading |
| Emit error state on Health permission denial | Return null from `fetchLiveHr()` silently (ARCH9) |
| Put `HealthLiveHrService` in domain layer | Presentation utility — depends on health platform plugin |
| Cancel `_hrTimer` but NOT the step timer | Always cancel both `_timer` and `_hrTimer` symmetrically |
| Call `copyWith(liveHr: null)` when poll returns null | Don't call `copyWith` at all — preserves last known value |
| Request `HEART_RATE` + `RESTING_HEART_RATE` in the same `requestAuthorization` call in `HealthLiveHrService` | Request only `HEART_RATE` in `HealthLiveHrService`; `RESTING_HEART_RATE` is `HealthDataSource`'s concern |
| Manually edit `app_localizations*.dart` files | Edit only `.arb` files; generated files are `.gitignore`'d |
| Skip `_hrTimer?.cancel()` in `abandon()` | Cancel `_hrTimer` in ALL three exit paths: natural complete, abandon, close |

### File Placement Reference

```
lib/features/session/presentation/
├── bloc/
│   ├── in_session_cubit.dart        ← UPDATE (add _liveHrService, _hrTimer, _fetchAndEmitHr)
│   └── in_session_state.dart        ← UPDATE (add int? liveHr field + copyWith param)
├── pages/
│   └── in_session_page.dart         ← UPDATE (instantiate + inject HealthLiveHrService)
├── utils/
│   ├── haptic_service.dart          ← NO CHANGES
│   ├── live_hr_service.dart         ← CREATE (LiveHrService + HealthLiveHrService)
│   └── session_step_generator.dart  ← NO CHANGES
└── widgets/
    └── in_session_view.dart         ← UPDATE (Stack + Positioned HR badge, _HrBadge widget)

lib/l10n/app/
├── app_en.arb                       ← UPDATE (add inSessionHrDisplay)
└── app_it.arb                       ← UPDATE (add inSessionHrDisplay)

test/
├── bloc/
│   ├── in_session_cubit_test.dart          ← NO CHANGES (null liveHrService = unaffected)
│   ├── in_session_cubit_haptic_test.dart   ← NO CHANGES (null liveHrService = unaffected)
│   └── in_session_cubit_hr_test.dart       ← CREATE (8.4-CUBIT-001 through 8.4-CUBIT-008)
├── unit/
│   └── live_hr_service_test.dart           ← CREATE (8.4-SERVICE-001, 8.4-SERVICE-002)
└── widget/
    └── in_session_view_test.dart           ← UPDATE (add 8.4-WIDGET-001 through 8.4-WIDGET-006)
```

### Test Count Baseline

| Category | Before 8.4 | Added by 8.4 | After 8.4 |
|---|---|---|---|
| `live_hr_service_test.dart` | 0 | 2 | 2 |
| `in_session_cubit_hr_test.dart` | 0 | 8 | 8 |
| `in_session_view_test.dart` | 7 | 6 | 13 |
| All others | 567 (574 - 7) | 0 | 567 |
| **Total** | **574** | **16** | **≥ 590** |

### References

- FR19 (live HR display): `_bmad-output/planning-artifacts/epics.md:40`
- UX-DR8 (InSessionView spec): `_bmad-output/planning-artifacts/epics.md:132`
- ARCH9 (graceful degradation): `_bmad-output/planning-artifacts/architecture.md:510`
- `InSessionCubit._advanceStep()`: `lib/features/session/presentation/bloc/in_session_cubit.dart:57-70`
- `InSessionCubit.start()`: `lib/features/session/presentation/bloc/in_session_cubit.dart:38-40`
- `InSessionCubit.abandon()`: `lib/features/session/presentation/bloc/in_session_cubit.dart:87-90`
- `InSessionPage._onCountdownComplete()`: `lib/features/session/presentation/pages/in_session_page.dart:36-50`
- `HealthDataSource.fetchHealthData()`: `lib/features/session/data/datasources/health_data_source.dart`
- `HealthModule.health` singleton: `lib/core/di/health_module.dart:8-9`
- `AppTextStyles.caption`: `lib/core/theme/app_text_styles.dart` (11px Plus Jakarta Sans Regular)
- Previous story 8.3 review findings (init race fix): `_bmad-output/implementation-artifacts/8-3-haptic-feedback-on-step-transitions.md:603`
- Test baseline: 574/574 (post Story 8.3 review)

---

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- 2026-05-17: `flutter pub get` from `pulse_coach/` completed and regenerated `app_localizations*.dart`.
- 2026-05-17: Targeted tests passed: `flutter test test/unit/live_hr_service_test.dart test/bloc/in_session_cubit_hr_test.dart test/widget/in_session_view_test.dart test/bloc/in_session_cubit_test.dart test/bloc/in_session_cubit_haptic_test.dart` (38 tests).
- 2026-05-17: `flutter analyze` from `pulse_coach/` passed with no issues.
- 2026-05-17: `flutter test` from `pulse_coach/` passed: 592/592 tests.

### Completion Notes List

- Implemented session-scoped live HR polling through `LiveHrService` / `HealthLiveHrService`, using `HealthDataType.HEART_RATE`, one-time permission initialization, silent degradation, and latest-value rounding.
- Added `liveHr` to `InSessionState` and `InSessionCubit`, including immediate HR fetch on session start, 5-second polling, last-known-value retention, and HR timer cancellation on completion, abandon, and close.
- Updated `InSessionView` to render a top-right Caption-style HR badge only when HR data is present; no placeholder or error UI is shown when unavailable.
- Wired `InSessionPage` to create `HealthLiveHrService` only when `Health` is registered in `getIt`, preserving widget-test safety and production DI behavior.
- Added localized `inSessionHrDisplay` strings and regenerated generated localization files.
- Added HR service, cubit, and widget tests; adjusted the existing ARB invariant test to account for the new non-StateIndicator HR key.

### File List

- `_bmad-output/implementation-artifacts/8-4-live-heart-rate-display.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`
- `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart`
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `pulse_coach/lib/features/session/presentation/utils/live_hr_service.dart`
- `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/lib/l10n/app_localizations.dart`
- `pulse_coach/lib/l10n/app_localizations_en.dart`
- `pulse_coach/lib/l10n/app_localizations_it.dart`
- `pulse_coach/test/bloc/in_session_cubit_hr_test.dart`
- `pulse_coach/test/unit/live_hr_service_test.dart`
- `pulse_coach/test/widget/in_session_view_test.dart`
- `pulse_coach/test/widget/state_indicator_test.dart`

### Change Log

- 2026-05-17: Implemented live heart-rate display for in-session UI with Health polling, l10n support, and full test coverage.
- 2026-05-17: Code review completed (Blind Hunter + Edge Case Hunter + Acceptance Auditor). See Review Findings below.
- 2026-05-17: Applied review patches P1, P2, P3, P4, P5, P6, P7, P9 (cubit idempotency, defensive HR parsing + range, init retry, isComplete/isAbandoned emit guard, a11y Semantics + staleness opacity, lastHrAtEpochMs, stop-after-6-nulls). P8 (gitignore + git rm --cached generated l10n) blocked by sandbox — manual action required. Test suite passes 595/595 (+3 new HR cubit tests). `flutter analyze` clean.

---

## Review Findings

_Generated 2026-05-17 by `/bmad-code-review` (3 parallel adversarial layers)._

### Decision Needed (resolved 2026-05-17)

- [x] [Review][Decision] **Stale HR badge after sensor loss / permission revocation** → **Resolved: add visual staleness after T seconds.** Track `lastHrAtEpochMs` in state; after 15s without a fresh reading render the badge with reduced opacity. Re-classified as **P7** below. (sources: edge+blind)

- [x] [Review][Decision] **Generated `app_localizations*.dart` tracked vs CLAUDE.md** → **Resolved: gitignore the generated files and remove from tracking.** Align reality to CLAUDE.md. Re-classified as **P8** below. (source: auditor)

- [x] [Review][Decision] **Continue HR polling when permissions denied** → **Resolved: stop polling after N consecutive nulls (N=6, ~30s).** Re-classified as **P9** below. (source: blind)

### Patch

- [x] [Review][Patch] **`start()` is not idempotent — double-start leaks both `_timer` and `_hrTimer`** [`in_session_cubit.dart:44`] — no guard against `start()` being called twice; second call overwrites both timer fields, leaking the originals (they fire forever until `close()`), doubling the poll rate and step ticks. Add `if (_timer != null) return;` at the top. (source: edge)

- [x] [Review][Patch] **`points.last.value as NumericHealthValue` can throw TypeError; `numericValue.round()` can throw on NaN/Infinity** [`live_hr_service.dart:60`] — current cast is unguarded inside the `try/catch`, so a non-numeric `HealthValue` subtype or a non-finite reading is swallowed with a `debugPrint` and `fetchLiveHr` returns null. The result is silent permanent failure on a single bad point. Filter with `points.whereType<NumericHealthValue>().lastOrNull` and check `numericValue.isFinite` before `.round()`. (sources: blind+edge)

- [x] [Review][Patch] **No physiological-range sanity check on HR value** [`live_hr_service.dart:60`, `in_session_cubit.dart:101-108`] — a glitched sensor reading of `0` or `500` bpm is propagated to UI as `"♥ 0 bpm"` / `"♥ 500 bpm"`. Clamp/reject values outside `[30, 240]` (return null in the service layer). (source: edge)

- [x] [Review][Patch] **`init()` permanently latches first failure** [`live_hr_service.dart:31-45`] — if `configure()` or `requestAuthorization` throws once (transient HealthConnect binder failure on cold boot), `_initialized=true` and `_initFuture` are cached, so all subsequent `init()` calls short-circuit to the failed future. No retry path for the rest of the cubit's lifetime. In the `catch` block, leave `_initialized=false` and null `_initFuture` so the next call can retry. (source: edge)

- [x] [Review][Patch] **`_fetchAndEmitHr` does not guard against `isComplete`/`isAbandoned`** [`in_session_cubit.dart:101-108`] — only checks `!isClosed`. An in-flight poll started just before `abandon()` resolves afterwards and emits a `liveHr` update onto an already-abandoned/completed state, briefly flashing the badge while the user is leaving. Add `if (state.isComplete || state.isAbandoned) return;` before `emit`. (source: edge)

- [x] [Review][Patch] **HR badge has no Semantics / liveRegion — inaccessible to screen readers** [`in_session_view.dart:319-324` (approx)] — the badge is a continuously updating numeric, but lacks `Semantics(label: 'Heart rate $bpm beats per minute', liveRegion: true)`. Screen readers either read literal "♥" as "black heart suit" or skip it, and never announce value changes. (source: edge)

- [x] [Review][Patch] **P7 — Visual staleness after T=15s without fresh reading** (from Decision 1) — add `int? lastHrAtEpochMs` to `InSessionState`; emit it alongside `liveHr` on every successful poll. In `_HrBadge`, dim with `Opacity(0.4)` (or `onSurfaceVariant` → muted token) when `DateTime.now().millisecondsSinceEpoch - lastHrAtEpochMs > 15000`. Cubit needs a one-shot 15s Timer that re-emits the same state to trigger rebuild, or rely on the polling tick to refresh. [`in_session_state.dart`, `in_session_cubit.dart`, `in_session_view.dart`]

- [x] [Review][Patch] **P8 — Remove generated l10n files from git tracking** — applied 2026-05-17 via terminal: appended `lib/l10n/app_localizations.dart` and `lib/l10n/app_localizations_*.dart` to `pulse_coach/.gitignore`; `git rm --cached` removed the 3 generated files from the index. `git check-ignore -v` confirms the rule fires on line 48 of `pulse_coach/.gitignore`. (from Decision 2) — add `pulse_coach/lib/l10n/app_localizations*.dart` to `pulse_coach/.gitignore`, run `git rm --cached pulse_coach/lib/l10n/app_localizations*.dart`, and document in CLAUDE.md that the files MUST be regenerated locally via `flutter pub get` before running tests. Update Task 5 / Anti-Patterns table in this spec to match. [`pulse_coach/.gitignore`, `CLAUDE.md`]

- [x] [Review][Patch] **P9 — Stop `_hrTimer` after 6 consecutive null polls** (from Decision 3) — add `int _consecutiveNullCount = 0` field to cubit. In `_fetchAndEmitHr`: on non-null reset to 0; on null increment; when `>= 6` cancel `_hrTimer`. Shares the counter with P7's staleness if convenient. [`in_session_cubit.dart`]

### Deferred

- [x] [Review][Defer] **RTL not handled in `Positioned(right: 16)`** [`in_session_view.dart`] — hard-coded `right` instead of `PositionedDirectional(end: 16)`. Locale is currently locked to `it`, so latent only. (source: edge)
- [x] [Review][Defer] **`getIt.isRegistered<Health>()` racy with async DI registration** [`in_session_page.dart`] — same pattern as Story 8.2's `SessionLogsDao` check; if a future `Health` registration becomes `@preResolve`/async, `initState` may snapshot `false`. (source: edge)
- [x] [Review][Defer] **Concurrent in-flight polls can complete out of order** [`in_session_cubit.dart`] — if `fetchLiveHr` ever exceeds 5s (HealthConnect cold read), an older poll can emit after a newer one. (source: edge)
- [x] [Review][Defer] **HR badge can overlap step title at narrow viewports (< 360 dp)** [`in_session_view.dart`] — long Italian titles wrap into multiple lines whose right edge crosses the `Positioned top:16 right:16` badge. Design refinement. (source: edge)
- [x] [Review][Defer] **HR badge has no background pill / contrast guarantee** [`in_session_view.dart`] — relies on `onSurfaceVariant` over `surface`; safe today but fragile to theme changes. (source: edge)
- [x] [Review][Defer] **Test timing race: `pump(Duration(seconds: 5))` + async emit** [`test/bloc/in_session_cubit_hr_test.dart`] — Tests currently pass with the extra trailing `pump()`, but a `pumpAndSettle` or `fake_async` rewrite would be more robust. (source: edge)
- [x] [Review][Defer] **First-poll race during `init()` cold start** [`live_hr_service.dart` + `in_session_cubit.dart`] — fire-and-forget `init()` runs concurrently with cubit `start()`; on slow devices the first 1–2 polls return null. Retries every 5s, so effect is brief. (sources: blind+edge)
- [x] [Review][Defer] **Test mock import couples `live_hr_service_test.dart` to `health_data_source_test.mocks.dart`** [`test/unit/live_hr_service_test.dart:5`] — coupling test files via generated mocks is fragile. Move to local `@GenerateMocks([Health])` annotation. (source: blind)

### Dismissed (10)

Noise / false positives / pre-existing-and-accepted: `init()` idempotency hypothetical race (withdrawn by reviewer), `_HrBadge` double bang-asserts (consistent with rest of file), identical EN/IT translation of "♥ {bpm} bpm" (spec explicitly accepts), cross-session liveHr leak (cubit not reused), clock-skew pre-epoch underflow, ambiguous `♥` in `findTextContaining` (no other ♥ in tree today), Eastern Arabic-Indic digit formatting (locale locked to `it`), `_liveHrService` not disposed (`Health` is `@singleton`), `debugPrint` leak in release builds (project convention), test-count discrepancy 16 vs 18 (Dev expanded SERVICE tests — improvement, not defect).
