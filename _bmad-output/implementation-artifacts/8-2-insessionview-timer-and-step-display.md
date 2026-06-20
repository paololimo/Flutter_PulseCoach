# Story 8.2: InSessionView — Timer & Step Display

Status: done

## Story

As a user,
I want a full-screen, focused session view with a large timer and clear step instructions,
So that I can follow the session without any navigation or decisions.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | The `InSessionView` is rendered | When inspected | It shows: JetBrains Mono 48sp session timer counting down (MM:SS), current exercise step name (H2 typography), step instructions (Body typography), and a `LinearProgressIndicator` showing step position within the session (UX-DR8) |
| AC2 | The timer is running | When measured against NFR3 | Timer accuracy is within ±1 second over the full session duration; `Timer.periodic(Duration(seconds: 1), ...)` drives the countdown |
| AC3 | A session step completes (step timer reaches 0) | When the next step begins | The UI transitions to the next step automatically — no user action required (FR17); live-region Semantics announces the new step name |
| AC4 | The `InSessionView` is active | When the user inspects the screen | No navigation elements are visible except a recessive "Abbandona" `TextButton` at the bottom (On Surface Variant color, not prominent) (UX-DR8); no `AppBar`, no bottom nav bar |
| AC5 | The final step timer reaches zero | When the session ends | `InSessionCubit` persists a `SessionLog` entry (via `SessionLogsDao`) then emits `isComplete = true`; the page immediately navigates to `AppRouter.sessionRpe` via `context.go(...)` |
| AC6 | The `InSessionView` layout is inspected | When rendered on a 360dp+ viewport | Layout uses 24dp horizontal padding, 32dp top padding, single-column centered layout — no grid (UX-DR8) |
| AC7 | The new navigation extra type (`SessionStartArgs`) is wired | When `flutter test` and `flutter analyze` run | Zero-tolerance baseline preserved; `8.1-WIDGET-007` updated; new `8.2-*` tests added; test count ≥ 548 + new tests |

## Tasks / Subtasks

### Task 1: Create `SessionStartArgs` data class (AC5)

- [x] CREATE `pulse_coach/lib/features/session/domain/entities/session_start_args.dart`

  ```dart
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';

  /// Navigation contract for the /session/active route.
  /// Carries session data plus persistence context so InSessionPage
  /// can write the SessionLog on completion without reaching into Today's cubit.
  class SessionStartArgs {
    final PlannedSession? session;
    final int? planId;
    final int sessionIndex;

    const SessionStartArgs({
      this.session,
      this.planId,
      this.sessionIndex = 0,
    });
  }
  ```

  **No freezed / injectable** — lightweight plain Dart class; not persisted beyond a navigation call.

---

### Task 2: Create `ExerciseStep` domain entity (AC1, AC3)

- [x] CREATE `pulse_coach/lib/features/session/domain/entities/exercise_step.dart`

  ```dart
  /// A single phase within an in-session exercise sequence.
  /// Derived at runtime from a PlannedSession by SessionStepGenerator.
  class ExerciseStep {
    final String title;
    final String instruction;
    final int durationSeconds;

    const ExerciseStep({
      required this.title,
      required this.instruction,
      required this.durationSeconds,
    });
  }
  ```

  **No freezed / injectable** — simple immutable value class; not DB-persisted in this story.

---

### Task 3: Create `SessionStepGenerator` (presentation layer) (AC1, AC3)

- [x] CREATE `pulse_coach/lib/features/session/presentation/utils/session_step_generator.dart`

  **Purpose:** Converts a `PlannedSession` into a 3-phase `List<ExerciseStep>` (warm-up → main → cool-down) using localized strings. Lives in presentation (not domain) because it depends on `AppLocalizations`.

  ```dart
  import 'dart:math' show max;
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  abstract class SessionStepGenerator {
    /// Returns a 3-step list: warm-up (20%), main phase (60%), cool-down (20%).
    /// Each phase is at least 60 seconds. Remainder goes to the main phase.
    static List<ExerciseStep> generate(
      PlannedSession? session,
      AppLocalizations l10n,
    ) {
      final totalSeconds = (session?.durationMinutes ?? 5) * 60;
      final phaseMin = 60; // absolute minimum 1 min per phase
      final warmup = max(phaseMin, totalSeconds ~/ 5);
      final cooldown = max(phaseMin, totalSeconds ~/ 5);
      final main = max(phaseMin, totalSeconds - warmup - cooldown);

      final mainTitle = _mainTitle(session?.sessionType ?? 'mobility', l10n);
      final mainInstruction = _mainInstruction(session?.sessionType ?? 'mobility', l10n);

      return [
        ExerciseStep(
          title: l10n.inSessionWarmupTitle,
          instruction: l10n.inSessionWarmupInstruction,
          durationSeconds: warmup,
        ),
        ExerciseStep(
          title: mainTitle,
          instruction: mainInstruction,
          durationSeconds: main,
        ),
        ExerciseStep(
          title: l10n.inSessionCooldownTitle,
          instruction: l10n.inSessionCooldownInstruction,
          durationSeconds: cooldown,
        ),
      ];
    }

    static String _mainTitle(String sessionType, AppLocalizations l10n) =>
        switch (sessionType) {
          'cardio' => l10n.sessionNameCardio,
          'breathing' => l10n.sessionNameBreathing,
          _ => l10n.sessionNameMobility,
        };

    static String _mainInstruction(String sessionType, AppLocalizations l10n) =>
        switch (sessionType) {
          'cardio' => l10n.inSessionMainCardioInstruction,
          'breathing' => l10n.inSessionMainBreathingInstruction,
          _ => l10n.inSessionMainMobilityInstruction,
        };
  }
  ```

  **Import note:** `dart:math` for `max()`. `abstract class` prevents instantiation; all members are static.

---

### Task 4: Create `InSessionState` and `InSessionCubit` (AC2, AC3, AC5)

- [x] CREATE `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart`

  ```dart
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';

  class InSessionState {
    final List<ExerciseStep> steps;
    final int currentStepIndex;
    final int secondsRemaining;
    final bool isComplete;

    const InSessionState({
      required this.steps,
      required this.currentStepIndex,
      required this.secondsRemaining,
      this.isComplete = false,
    });

    ExerciseStep get currentStep => steps[currentStepIndex];
    int get totalSteps => steps.length;

    InSessionState copyWith({
      int? currentStepIndex,
      int? secondsRemaining,
      bool? isComplete,
    }) => InSessionState(
      steps: steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isComplete: isComplete ?? this.isComplete,
    );
  }
  ```

- [x] CREATE `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart`

  ```dart
  import 'dart:async';
  import 'package:drift/drift.dart' show Value;
  import 'package:flutter/foundation.dart' show debugPrint;
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:pulse_coach/core/database/app_database.dart' show SessionLogsCompanion;
  import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';

  class InSessionCubit extends Cubit<InSessionState> {
    final SessionLogsDao? _sessionLogsDao;
    final int? _planId;
    final int _sessionIndex;
    Timer? _timer;

    InSessionCubit({
      required List<ExerciseStep> steps,
      SessionLogsDao? sessionLogsDao,
      int? planId,
      int sessionIndex = 0,
    })  : _sessionLogsDao = sessionLogsDao,
          _planId = planId,
          _sessionIndex = sessionIndex,
          super(InSessionState(
            steps: steps,
            currentStepIndex: 0,
            secondsRemaining: steps.first.durationSeconds,
          ));

    /// Starts the 1-second countdown tick. Call once from State.initState equivalent.
    void start() {
      _timer = Timer.periodic(const Duration(seconds: 1), _tick);
    }

    void _tick(Timer _) {
      if (state.isComplete) return;
      if (state.secondsRemaining > 1) {
        emit(state.copyWith(secondsRemaining: state.secondsRemaining - 1));
      } else {
        _advanceStep();
      }
    }

    void _advanceStep() {
      final nextIndex = state.currentStepIndex + 1;
      if (nextIndex >= state.steps.length) {
        _timer?.cancel();
        _persistCompletion();
      } else {
        emit(state.copyWith(
          currentStepIndex: nextIndex,
          secondsRemaining: state.steps[nextIndex].durationSeconds,
        ));
      }
    }

    Future<void> _persistCompletion() async {
      if (_sessionLogsDao != null && _planId != null) {
        final now = DateTime.now();
        try {
          await _sessionLogsDao!.insertLog(
            SessionLogsCompanion(
              dailyPlanId: Value(_planId!),
              sessionIndex: Value(_sessionIndex),
              completedAt: Value(now),
              createdAt: Value(now),
            ),
          );
        } catch (e) {
          debugPrint('InSessionCubit: insertLog failed: $e');
        }
      }
      if (!isClosed) emit(state.copyWith(isComplete: true));
    }

    /// Called by the Abandon button. Stops the timer.
    /// Story 8.5 adds confirmation + partial session log write.
    void abandon() {
      _timer?.cancel();
      if (!isClosed) emit(state.copyWith(isComplete: true));
    }

    @override
    Future<void> close() {
      _timer?.cancel();
      return super.close();
    }
  }
  ```

  **Key decisions:**
  - NOT `@injectable` — constructed dynamically in `InSessionPage` with runtime `steps` data.
  - `SessionLogsDao?` is nullable so tests can pass `null` and skip DB calls.
  - `abandon()` also emits `isComplete = true` so the listener in the page navigates away cleanly. Story 8.5 will replace this with a confirmation bottom sheet before calling `abandon()`.
  - `_tick` guards `if (state.isComplete) return;` to prevent double-emission if `abandon()` and a final tick race.

---

### Task 5: Create `InSessionView` widget (AC1, AC3, AC4, AC6)

- [x] CREATE `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/core/theme/app_text_styles.dart';
  import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  class InSessionView extends StatelessWidget {
    final InSessionState sessionState;
    final VoidCallback onAbandon;

    const InSessionView({
      required this.sessionState,
      required this.onAbandon,
      super.key,
    });

    @override
    Widget build(BuildContext context) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      final l10n = AppLocalizations.of(context)!;
      final step = sessionState.currentStep;

      return Scaffold(
        backgroundColor: pulseTheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Step name — H2
                Semantics(
                  liveRegion: true,
                  label: step.title,
                  child: Text(
                    step.title,
                    style: AppTextStyles.h2.copyWith(color: pulseTheme.onSurface),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                // Step position indicator
                Text(
                  l10n.inSessionStepLabel(
                    (sessionState.currentStepIndex + 1).toString(),
                    sessionState.totalSteps.toString(),
                  ),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                // Timer — JetBrains Mono 48sp
                Text(
                  _formatTime(sessionState.secondsRemaining),
                  style: AppTextStyles.timerDisplay.copyWith(
                    color: pulseTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                // Linear progress bar
                LinearProgressIndicator(
                  value: (sessionState.currentStepIndex + 1) /
                      sessionState.totalSteps,
                  backgroundColor: pulseTheme.surfaceContainerHigh,
                  color: pulseTheme.primaryColor,
                ),
                const SizedBox(height: 32),
                // Step instruction — Body
                Text(
                  step.instruction,
                  style: AppTextStyles.body.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Abandon button — muted TextButton, bottom of screen (UX-DR8)
                TextButton(
                  onPressed: onAbandon,
                  child: Text(
                    l10n.inSessionAbandonButton,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: pulseTheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    static String _formatTime(int seconds) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }
  ```

  **Layout contract (UX-DR8):**
  - 24dp horizontal padding ✓
  - 32dp top padding ✓
  - No AppBar ✓
  - Single-column centered layout ✓
  - `Spacer()` pushes abandon button to the bottom ✓

  **Typography tokens used:**
  - Step name: `AppTextStyles.h2` (Plus Jakarta Sans, 20sp, w600)
  - Timer: `AppTextStyles.timerDisplay` (JetBrains Mono, 48sp, h1.0) — already defined, DO NOT redefine
  - Step instruction: `AppTextStyles.body` (Plus Jakarta Sans, 15sp, w400)
  - Step position / abandon: `AppTextStyles.bodySmall` (Plus Jakarta Sans, 13sp, w400)

  **Accessibility:** `Semantics(liveRegion: true)` on the step name so screen readers announce step changes automatically (UX-DR8, matches pattern in `countdown_overlay.dart`).

---

### Task 6: Update `InSessionPage` — wire cubit + replace placeholder (AC1–AC7)

- [x] UPDATE `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`

  Full replacement:

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';
  import 'package:pulse_coach/core/di/injection.dart';
  import 'package:pulse_coach/core/routing/app_router.dart';
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
  import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
  import 'package:pulse_coach/features/session/presentation/widgets/countdown_overlay.dart';
  import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
  import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  class InSessionPage extends StatefulWidget {
    final PlannedSession? session;
    final int? planId;
    final int sessionIndex;

    const InSessionPage({
      this.session,
      this.planId,
      this.sessionIndex = 0,
      super.key,
    });

    @override
    State<InSessionPage> createState() => _InSessionPageState();
  }

  class _InSessionPageState extends State<InSessionPage> {
    bool _countdownDone = false;
    InSessionCubit? _cubit;

    void _onCountdownComplete() {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final steps = SessionStepGenerator.generate(widget.session, l10n);
      final cubit = InSessionCubit(
        steps: steps,
        sessionLogsDao: getIt(),
        planId: widget.planId,
        sessionIndex: widget.sessionIndex,
      )..start();
      setState(() {
        _cubit = cubit;
        _countdownDone = true;
      });
    }

    @override
    void dispose() {
      _cubit?.close();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      if (!_countdownDone || _cubit == null) {
        final l10n = AppLocalizations.of(context)!;
        final sessionTitle = widget.session != null
            ? sessionDisplayName(widget.session!.sessionType, l10n)
            : null;

        return CountdownOverlay(
          sessionTitle: sessionTitle,
          onCountdownComplete: _onCountdownComplete,
        );
      }

      return BlocProvider.value(
        value: _cubit!,
        child: BlocListener<InSessionCubit, InSessionState>(
          listenWhen: (prev, curr) => curr.isComplete && !prev.isComplete,
          listener: (context, state) => context.go(AppRouter.sessionRpe),
          child: BlocBuilder<InSessionCubit, InSessionState>(
            builder: (context, state) => InSessionView(
              sessionState: state,
              onAbandon: () {
                _cubit!.abandon();
                // Story 8.5 replaces this direct navigation with a
                // confirmation bottom sheet; keeping navigate-to-today
                // ensures the user is never stranded in this story's scope.
                // go() is used (not push) so the session route is replaced
                // and Android back cannot return mid-session.
                context.go(AppRouter.today);
              },
            ),
          ),
        ),
      );
    }
  }
  ```

  **Key decisions:**
  - `getIt()` typed inference resolves to `SessionLogsDao` (registered as singleton via health_module).
  - `_cubit?.close()` in `dispose()` cancels the `Timer` — no timer leak after page pop.
  - `BlocProvider.value()` (not `BlocProvider(create:)`) — cubit is owned by the State, not by the provider.
  - `BlocListener` navigates on `isComplete` — single-fire guard via `listenWhen`.
  - Abandon taps `context.go(AppRouter.today)` (not `push`): abandoning a session returns cleanly to Today; Story 8.5 will intercept before `abandon()` to show confirmation.

---

### Task 7: Expose `currentPlanId` getter on `TodaySessionCubit` (AC5)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`

  Add the following getter after the class declaration (between the `_currentPlanId` field and `planLoaded` method):

  ```dart
  /// Exposes the active plan ID for navigation handoff to InSessionPage.
  int? get currentPlanId => _currentPlanId;
  ```

  **No other changes.** This getter is read-only and does not break existing tests.

---

### Task 8: Update `today_page.dart` — pass `SessionStartArgs` on navigate (AC5)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/pages/today_page.dart`

  Add import at the top:
  ```dart
  import 'package:pulse_coach/features/session/domain/entities/session_start_args.dart';
  ```

  In `_HeroZone.build()`, change the `onStart` callback (currently around line 239):

  **Before:**
  ```dart
  onStart: () => context.go(AppRouter.sessionActive, extra: session),
  ```

  **After:**
  ```dart
  onStart: () => context.go(
    AppRouter.sessionActive,
    extra: SessionStartArgs(
      session: session,
      planId: context.read<TodaySessionCubit>().currentPlanId,
      sessionIndex: heroIndex,
    ),
  ),
  ```

  **`heroIndex` is already available** as a field of `_HeroZone` (passed in from `_buildLoaded`).  
  **`TodaySessionCubit` is accessible** via `context.read<>()` because `_HeroZone` is inside the `BlocBuilder<TodaySessionCubit, TodaySessionState>` subtree.

---

### Task 9: Update `app_router.dart` — unpack `SessionStartArgs` (AC5)

- [x] UPDATE `pulse_coach/lib/core/routing/app_router.dart`

  Add import:
  ```dart
  import 'package:pulse_coach/features/session/domain/entities/session_start_args.dart';
  ```

  Replace the `sessionActive` GoRoute builder:

  **Before:**
  ```dart
  GoRoute(
    path: sessionActive,
    builder: (context, state) {
      final session = state.extra as PlannedSession?;
      return InSessionPage(session: session);
    },
  ),
  ```

  **After:**
  ```dart
  GoRoute(
    path: sessionActive,
    builder: (context, state) {
      final extra = state.extra;
      if (extra is SessionStartArgs) {
        return InSessionPage(
          session: extra.session,
          planId: extra.planId,
          sessionIndex: extra.sessionIndex,
        );
      }
      // Deep-link / hot-restart fallback: no planId available.
      return InSessionPage(session: extra as PlannedSession?);
    },
  ),
  ```

  **The fallback branch** handles hot-restart and future deep-link scenarios where `extra` is null or a bare `PlannedSession?`. Both paths remain safe because `InSessionPage` fields are nullable.

---

### Task 10: Add ARB localization keys (AC1, AC3, AC4)

- [x] UPDATE `pulse_coach/lib/l10n/app/app_en.arb`

  Add after `"countdownGoAnnounce": "Go"` (no trailing comma on that line — add comma first):

  ```json
  ,
  "inSessionWarmupTitle": "Warm-up",
  "inSessionCooldownTitle": "Cool-down",
  "inSessionWarmupInstruction": "Move slowly to prepare your body.",
  "inSessionCooldownInstruction": "Slow down gradually. Breathe deeply.",
  "inSessionMainMobilityInstruction": "Perform movements smoothly and in control.",
  "inSessionMainCardioInstruction": "Keep the pace with steady breathing.",
  "inSessionMainBreathingInstruction": "Focus on deep, rhythmic breathing.",
  "inSessionAbandonButton": "Abandon",
  "inSessionStepLabel": "{current} of {total}",
  "@inSessionStepLabel": {
    "placeholders": {
      "current": { "type": "String" },
      "total": { "type": "String" }
    }
  }
  ```

- [x] UPDATE `pulse_coach/lib/l10n/app/app_it.arb`

  Add after `"countdownGoAnnounce": "Vai"` (add comma first):

  ```json
  ,
  "inSessionWarmupTitle": "Riscaldamento",
  "inSessionCooldownTitle": "Defaticamento",
  "inSessionWarmupInstruction": "Muoviti lentamente per preparare il corpo.",
  "inSessionCooldownInstruction": "Rallenta gradualmente. Respira profondo.",
  "inSessionMainMobilityInstruction": "Esegui i movimenti con fluidità e controllo.",
  "inSessionMainCardioInstruction": "Mantieni il ritmo con respiro regolare.",
  "inSessionMainBreathingInstruction": "Concentrati sul respiro profondo e ritmico.",
  "inSessionAbandonButton": "Abbandona",
  "inSessionStepLabel": "{current} di {total}",
  "@inSessionStepLabel": {
    "placeholders": {
      "current": { "type": "String" },
      "total": { "type": "String" }
    }
  }
  ```

  **Note:** Main phase step *titles* reuse existing `sessionNameMobility`, `sessionNameCardio`, `sessionNameBreathing` keys — no new title keys needed. Only instructions and control labels are new.

  **After editing:** run `flutter pub get` from `pulse_coach/` to regenerate `app_localizations*.dart`.

---

### Task 11: Create `InSessionCubit` unit tests (AC2, AC3, AC5)

- [x] CREATE `pulse_coach/test/bloc/in_session_cubit_test.dart`

  ```dart
  // fakeAsync is re-exported by flutter_test — no separate fake_async dep needed.
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';

  final _steps = [
    const ExerciseStep(title: 'Warm-up', instruction: 'Prep', durationSeconds: 3),
    const ExerciseStep(title: 'Main', instruction: 'Go', durationSeconds: 2),
    const ExerciseStep(title: 'Cool-down', instruction: 'Rest', durationSeconds: 2),
  ];

  InSessionCubit _cubit() => InSessionCubit(steps: _steps); // no DAO — isolation
  ```

  **Required tests:**

  ```
  8.2-CUBIT-001: Initial state — step 0, secondsRemaining == steps[0].durationSeconds, isComplete false
  8.2-CUBIT-002: After 1-second tick, secondsRemaining decrements by 1
  8.2-CUBIT-003: When step timer hits 0, advances to next step with correct duration
  8.2-CUBIT-004: After all steps complete, emits isComplete = true
  8.2-CUBIT-005: close() cancels timer — no crash, no further state emissions after dispose
  8.2-CUBIT-006: abandon() stops timer and emits isComplete = true
  ```

  **Test detail — use `fakeAsync` from `flutter_test` (no extra package needed):**

  ```dart
  // 8.2-CUBIT-001
  test('8.2-CUBIT-001: initial state', () {
    final c = _cubit();
    expect(c.state.currentStepIndex, 0);
    expect(c.state.secondsRemaining, _steps[0].durationSeconds);
    expect(c.state.isComplete, isFalse);
    c.close();
  });

  // 8.2-CUBIT-002
  test('8.2-CUBIT-002: tick decrements secondsRemaining', () {
    fakeAsync((async) {
      final c = _cubit()..start();
      async.elapse(const Duration(seconds: 1));
      expect(c.state.secondsRemaining, _steps[0].durationSeconds - 1);
      c.close();
    });
  });

  // 8.2-CUBIT-003
  test('8.2-CUBIT-003: step advances when timer reaches 0', () {
    fakeAsync((async) {
      final c = _cubit()..start();
      // Exhaust step 0 (3 seconds)
      async.elapse(Duration(seconds: _steps[0].durationSeconds));
      expect(c.state.currentStepIndex, 1);
      expect(c.state.secondsRemaining, _steps[1].durationSeconds);
      c.close();
    });
  });

  // 8.2-CUBIT-004
  test('8.2-CUBIT-004: all steps complete emits isComplete', () {
    fakeAsync((async) {
      final c = _cubit()..start();
      final total = _steps.fold(0, (s, e) => s + e.durationSeconds);
      async.elapse(Duration(seconds: total));
      expect(c.state.isComplete, isTrue);
      c.close();
    });
  });

  // 8.2-CUBIT-005
  test('8.2-CUBIT-005: close cancels timer without error', () {
    fakeAsync((async) {
      final c = _cubit()..start();
      c.close();
      // Advance past what would have been ticks — no exception
      async.elapse(const Duration(seconds: 10));
    });
  });

  // 8.2-CUBIT-006
  test('8.2-CUBIT-006: abandon emits isComplete and stops timer', () {
    fakeAsync((async) {
      final c = _cubit()..start();
      c.abandon();
      expect(c.state.isComplete, isTrue);
      async.elapse(const Duration(seconds: 10)); // no further state change
      c.close();
    });
  });
  ```

  **Note on `fakeAsync`:** `fakeAsync` is re-exported by `package:flutter_test/flutter_test.dart` (which is already in dev_dependencies). No separate `fake_async` package entry is needed in `pubspec.yaml`.

---

### Task 12: Create `SessionStepGenerator` unit tests (AC1)

- [x] CREATE `pulse_coach/test/unit/session_step_generator_test.dart`

  Use a real `AppLocalizations` via the test l10n setup pattern from `countdown_overlay_test.dart`.

  Actually, since `SessionStepGenerator.generate()` requires `AppLocalizations`, which requires a widget tree, these tests are better as widget tests:

  ```dart
  // pulse_coach/test/widget/session_step_generator_test.dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/core/theme/app_theme.dart';
  import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
  import 'package:pulse_coach/features/session/presentation/utils/session_step_generator.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  const _testSession = PlannedSession(
    sessionType: 'cardio',
    intensity: 5,
    durationMinutes: 5,
    isIndoor: true,
  );

  Widget _wrap(Widget w) => MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: w,
      );
  ```

  **Required tests:**

  ```
  8.2-UNIT-001: 5-minute session → 3 steps, total seconds == 300
  8.2-UNIT-002: Each phase ≥ 60 seconds; warmup + cooldown ≤ 40% of total
  8.2-UNIT-003: Main step title matches session type (cardio → "Cardio")
  8.2-UNIT-004: Null session uses default 5-minute duration and mobility type
  ```

---

### Task 13: Create `InSessionView` widget tests (AC1, AC4, AC6)

- [x] CREATE `pulse_coach/test/widget/in_session_view_test.dart`

  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:flutter_test/flutter_test.dart';
  import 'package:pulse_coach/core/theme/app_theme.dart';
  import 'package:pulse_coach/features/session/domain/entities/exercise_step.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_cubit.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/in_session_state.dart';
  import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  const _steps = [
    ExerciseStep(title: 'Riscaldamento', instruction: 'Muoviti lentamente.', durationSeconds: 60),
    ExerciseStep(title: 'Cardio', instruction: 'Mantieni il ritmo.', durationSeconds: 180),
    ExerciseStep(title: 'Defaticamento', instruction: 'Rallenta.', durationSeconds: 60),
  ];

  Widget _wrap(Widget w) => MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: w,
      );

  InSessionView _view({int step = 0, int seconds = 60}) => InSessionView(
        sessionState: InSessionState(
          steps: _steps,
          currentStepIndex: step,
          secondsRemaining: seconds,
        ),
        onAbandon: () {},
      );
  ```

  **Required tests:**

  ```
  8.2-WIDGET-001: InSessionView shows step name with H2 style (fontSize 20)
  8.2-WIDGET-002: Timer shown as MM:SS (e.g. "01:00" for 60s)
  8.2-WIDGET-003: LinearProgressIndicator is present
  8.2-WIDGET-004: Abandon TextButton is present with muted color
  8.2-WIDGET-005: Step instruction text is visible
  8.2-WIDGET-006: Timer style uses JetBrains Mono font family
  ```

  **Test detail:**

  ```dart
  // 8.2-WIDGET-001
  testWidgets('8.2-WIDGET-001: step name in H2 style', (tester) async {
    await tester.pumpWidget(_wrap(_view()));
    await tester.pump();
    final text = tester.widget<Text>(
      find.descendant(of: find.byType(InSessionView), matching: find.text('Riscaldamento')),
    );
    expect(text.style?.fontSize, 20.0);
    expect(text.style?.fontWeight, FontWeight.w600);
  });

  // 8.2-WIDGET-002
  testWidgets('8.2-WIDGET-002: timer shows MM:SS format', (tester) async {
    await tester.pumpWidget(_wrap(_view(seconds: 90)));
    await tester.pump();
    expect(find.text('01:30'), findsOneWidget);
  });

  // 8.2-WIDGET-006
  testWidgets('8.2-WIDGET-006: timer uses JetBrains Mono', (tester) async {
    await tester.pumpWidget(_wrap(_view(seconds: 60)));
    await tester.pump();
    final timerText = tester.widget<Text>(find.text('01:00'));
    expect(timerText.style?.fontFamily, 'JetBrains Mono');
  });
  ```

---

### Task 14: Update `countdown_overlay_test.dart` — fix `8.1-WIDGET-007` (AC7)

- [x] UPDATE `pulse_coach/test/widget/countdown_overlay_test.dart`

  **Problem:** `8.1-WIDGET-007` asserts `find.text('In Session — Story 8.2')` — this placeholder text is gone after Story 8.2 (InSessionPage now shows `InSessionView` after countdown).

  **Replace the body of `8.1-WIDGET-007`:**

  ```dart
  testWidgets(
    '8.1-WIDGET-007: InSessionPage shows InSessionView after countdown',
    (tester) async {
      await tester.pumpWidget(_wrap(const InSessionPage(), disableAnimations: true));
      await tester.pumpAndSettle(const Duration(seconds: 10));
      // After countdown, InSessionView renders (no more Story 8.2 placeholder)
      expect(find.byType(CountdownOverlay), findsNothing);
      expect(find.byType(InSessionView), findsOneWidget);
    },
  );
  ```

  Add import if not already present:
  ```dart
  import 'package:pulse_coach/features/session/presentation/widgets/in_session_view.dart';
  ```

  **Note:** `InSessionPage` is constructed without `planId` or `session` in this test — `SessionStepGenerator.generate(null, l10n)` produces a valid 3-step list using the 5-minute mobility default. The cubit runs with `sessionLogsDao: getIt()` but since GetIt is not configured in widget tests, this will throw if accessed. **To make this test pass:** either mock `getIt<SessionLogsDao>()` in test setup or — simpler — check whether `getIt.isRegistered<SessionLogsDao>()` in `InSessionCubit` and skip the DAO call if not registered. Alternatively, register a mock DAO in the test setUp:

  ```dart
  setUpAll(() {
    // Register a noop SessionLogsDao so InSessionCubit can be created in widget tests
    // without a real DB. Use a mock or a minimal stub.
    // See today_session_cubit_test.dart for pattern using mockito.
  });
  ```

  **Recommended fix:** Pass `null` as `sessionLogsDao` in the test via a constructor override. This requires making `InSessionPage` accept an optional cubit factory parameter — OR — simply check in `_InSessionPageState._onCountdownComplete` whether `getIt.isRegistered<SessionLogsDao>()` before calling `getIt()`. Use whichever approach matches the existing test infrastructure without adding new mocking complexity.

  **Simplest approach:** Check `getIt.isRegistered<SessionLogsDao>()`:
  ```dart
  sessionLogsDao: getIt.isRegistered<SessionLogsDao>() ? getIt() : null,
  ```
  This makes the widget test environment safe without requiring test-side DI setup.

---

### Task 15: Run baseline verification (AC7)

- [x] `flutter pub get` from `pulse_coach/` → regenerates `app_localizations*.dart` with new in-session keys
- [x] `flutter analyze` from `pulse_coach/` → 0 issues
- [x] Verify `app_en.arb` and `app_it.arb` are valid JSON: `python3 -m json.tool lib/l10n/app/app_en.arb`
- [x] `flutter test` from `pulse_coach/` → ≥ 548 + new tests (expect ~564+)
- [x] Verify `InSessionView` renders without overflow in portrait (360×640 dp test equivalent in widget tests)
- [x] Verify `_formatTime(90)` returns `"01:30"` (static method — can be tested inline)

---

## Dev Notes

### Current State of Files Being Modified

**`lib/features/session/presentation/pages/in_session_page.dart`**
- Currently: `StatefulWidget` with `_countdownDone` bool; shows `CountdownOverlay` then a placeholder `Scaffold` with `Text('In Session — Story 8.2')`.
- **Replace entirely** — remove placeholder Scaffold, add cubit lifecycle management and `InSessionView` wire-up.
- The `CountdownOverlay` integration stays; Story 8.2 only replaces what happens AFTER the countdown.

**`lib/features/today/presentation/cubit/today_session_cubit.dart`**
- Add one getter: `int? get currentPlanId => _currentPlanId;`
- `_currentPlanId` is already the private field tracking the active plan ID.
- **No other changes.** All existing tests pass without modification.

**`lib/features/today/presentation/pages/today_page.dart`**
- `onStart` at line 239 changes from `extra: session` to `extra: SessionStartArgs(...)`.
- Add import for `SessionStartArgs`.
- `context.read<TodaySessionCubit>()` is safe here — `_HeroZone` is always inside a `BlocBuilder<TodaySessionCubit, ...>` subtree.
- `heroIndex` is already a field on `_HeroZone`.

**`lib/core/routing/app_router.dart`**
- Add `SessionStartArgs` import and unpack logic in `sessionActive` builder.
- Fallback branch preserves backward compatibility with any code that passes a bare `PlannedSession?`.

### Architecture Compliance

- `ExerciseStep` → `lib/features/session/domain/entities/` — matches architecture.md tree line for `exercise_step.dart`.
- `InSessionCubit` / `InSessionState` → `lib/features/session/presentation/bloc/` — matches architecture.md tree lines for `session_bloc.dart` pattern (using Cubit not Bloc per Story 8 pattern).
- `InSessionView` → `lib/features/session/presentation/widgets/` — matches architecture.md tree line for `exercise_display.dart` / session widgets.
- `SessionStepGenerator` → `lib/features/session/presentation/utils/` — new subdirectory; acceptable for presentation-layer utilities.
- `SessionStartArgs` → `lib/features/session/domain/entities/` — navigation contract data class, domain-appropriate.
- No `@singleton` annotations — `InSessionCubit` is ephemeral (per-session lifecycle).
- No `CircularProgressIndicator` — `LinearProgressIndicator` for step progress.

### Why `InSessionCubit` is NOT `@injectable`

`InSessionCubit` requires `List<ExerciseStep>` at construction time, derived at runtime from `PlannedSession`. Injectable/GetIt is for stateless singletons and scoped services, not objects that carry runtime session state. The cubit is owned by `_InSessionPageState` (created in `_onCountdownComplete`, closed in `dispose()`).

### Timer Implementation Choice

`Timer.periodic(Duration(seconds: 1), _tick)` from `dart:async`:
- ✓ No `TickerProvider` / vsync dependency — decoupled from widget lifecycle.
- ✓ Survives frame drops — ticks at wall-clock intervals, not animation frames.
- ✓ Testable with `fakeAsync` — fake timers advance the zone clock.
- ✓ NFR3 (±1s accuracy) satisfied — one tick per second, accumulating drift < 1s over any session duration ≤ 60 min.

### Session Completion Flow (Cross-Story)

```
Today (TodaySessionCubit)
  └─ Tap "Inizia sessione"
       └─ context.go('/session/active', extra: SessionStartArgs)
            └─ InSessionPage (countdown + InSessionCubit)
                 └─ All steps done → SessionLogsDao.insertLog()
                      └─ InSessionCubit emits isComplete=true
                           └─ BlocListener: context.go('/session/rpe')
                                └─ RpePage placeholder (Story 9.x)
                                     └─ User navigates back to Today
                                          └─ TodaySessionCubit.planLoaded() reads DB → ring updates
```

The DB insert happens INSIDE InSessionCubit before `isComplete` is emitted, so when the user returns to Today and `TodaySessionCubit.planLoaded()` is called, the log already exists and the ring correctly reflects the completed session.

### Abandon Flow (Partial — Story 8.5 Completes It)

In Story 8.2, tapping "Abbandona":
1. Calls `_cubit!.abandon()` — stops timer, emits `isComplete = true`.
2. Calls `context.go(AppRouter.today)` — returns user to Today without recording a session log.

**Behavioral note:** Abandoning in Story 8.2 does NOT record a session log — the ring does not advance. Story 8.5 changes this: abandon records elapsed time and last step, shows RPE input, THEN returns to Today. The Story 8.2 approach is acceptable for alpha.

### `getIt.isRegistered<SessionLogsDao>()` Guard

In `_InSessionPageState._onCountdownComplete`:
```dart
sessionLogsDao: getIt.isRegistered<SessionLogsDao>() ? getIt() : null,
```
This single-line guard makes widget tests safe without requiring test-side DI configuration. In production, GetIt is initialized in `main()` before any route is pushed, so `isRegistered` always returns true.

### Anti-Patterns to Avoid

| ❌ | ✅ |
|---|---|
| Use `AppTextStyles.timerDisplay` with wrong font | `timerDisplay` already = JetBrains Mono 48sp; use as-is |
| Define a new 48sp TextStyle | Reuse `AppTextStyles.timerDisplay` (already exists!) |
| Use `CircularProgressIndicator` for session progress | Use `LinearProgressIndicator` per project rules |
| Add `AppBar` to `InSessionView` scaffold | Full-screen — no AppBar (UX-DR8) |
| `context.push(AppRouter.sessionRpe)` | Use `context.go(...)` — session routes replace, never stack |
| Call `getIt<SessionLogsDao>()` without registration guard in tests | Guard with `getIt.isRegistered<SessionLogsDao>()` |
| Create `InSessionCubit` with `@injectable` | Not injectable — requires runtime `steps` data |
| Use `Timer.periodic` inside a `StatelessWidget` | Cubit owns the timer; widget is stateless |
| Hardcode Italian strings in widget | Use `l10n.inSessionWarmupTitle` etc. via ARB |
| Put `SessionStepGenerator` in domain layer | Presentation layer — it depends on `AppLocalizations` |
| Emit state after `isClosed` | Guard all async resumptions with `if (!isClosed)` |
| Use `pumpAndSettle` for cubit timer tests | Use `fakeAsync` with `async.elapse(...)` |

### `AppTextStyles` Reference (Do Not Redefine)

```
AppTextStyles.timerDisplay  → JetBrains Mono, 48sp, h1.0   ← USE FOR SESSION TIMER
AppTextStyles.timerSecondary → JetBrains Mono, 24sp, h1.0  ← available if needed
AppTextStyles.h2             → Plus Jakarta Sans, 20sp, w600 ← USE FOR STEP NAME
AppTextStyles.body           → Plus Jakarta Sans, 15sp, w400 ← USE FOR STEP INSTRUCTION
AppTextStyles.bodySmall      → Plus Jakarta Sans, 13sp, w400 ← USE FOR STEP COUNTER / ABANDON
```

All defined at: `pulse_coach/lib/core/theme/app_text_styles.dart`

### Test Naming Convention

- Cubit logic: `8.2-CUBIT-001` through `8.2-CUBIT-006`
- Widget tests: `8.2-WIDGET-001` through `8.2-WIDGET-006`
- Generator unit tests: `8.2-UNIT-001` through `8.2-UNIT-004`
- Updated story 8.1 test (keep original ID): `8.1-WIDGET-007`

### References

- `AppTextStyles.timerDisplay` (48sp JetBrains Mono): `pulse_coach/lib/core/theme/app_text_styles.dart:7-10`
- `AppTextStyles.h2` (20sp Plus Jakarta Sans w600): `pulse_coach/lib/core/theme/app_text_styles.dart:37-42`
- `PulseCoachTheme.dark.*`: `pulse_coach/lib/core/theme/pulse_coach_theme.dart:19-30`
- `SessionLogsDao.insertLog()`: `pulse_coach/lib/core/database/daos/session_logs_dao.dart:18-19`
- `SessionLogsCompanion` (for DB insert): generated from `pulse_coach/lib/core/database/app_database.dart`
- `TodaySessionCubit.planLoaded()` (reads logs on plan change): `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart:56-76`
- `CountdownOverlay` (existing, reused): `pulse_coach/lib/features/session/presentation/widgets/countdown_overlay.dart`
- `sessionDisplayName()` helper: `pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart`
- UX-DR8 InSessionView spec: `_bmad-output/planning-artifacts/ux-design-specification.md` (InSessionView section)
- Architecture session feature tree: `_bmad-output/planning-artifacts/architecture.md:678-708`
- Previous story dev notes (8.1): `_bmad-output/implementation-artifacts/8-1-countdownoverlay.md`
- `onStart` target in today_page: `pulse_coach/lib/features/today/presentation/pages/today_page.dart:239`
- `sessionActive` route: `pulse_coach/lib/core/routing/app_router.dart:27, 69-74`
- Test baseline: 548/548 (post Story 8.1 code review)

---

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `flutter pub get` from `pulse_coach/` regenerated localization outputs.
- `python3 -m json.tool lib/l10n/app/app_en.arb` passed.
- `python3 -m json.tool lib/l10n/app/app_it.arb` passed.
- `flutter test test/bloc/in_session_cubit_test.dart test/widget/session_step_generator_test.dart test/widget/in_session_view_test.dart test/widget/countdown_overlay_test.dart` passed: 24/24.
- `flutter test test/widget/state_indicator_test.dart` passed after updating the ARB key-count invariant for the new in-session keys.
- `flutter analyze` passed: no issues found.
- `flutter test` passed: 565/565.

### Implementation Plan

- Add lightweight navigation and step entities for session start handoff and runtime exercise phases.
- Generate localized warm-up, main, and cool-down steps from a `PlannedSession`.
- Own the one-second countdown and completion persistence in an ephemeral `InSessionCubit`.
- Replace the post-countdown placeholder with a full-screen `InSessionView` and route completion to RPE.
- Pass `planId` and `sessionIndex` from Today through `SessionStartArgs` so completed sessions can be persisted.
- Add focused cubit, generator, widget, countdown integration, and ARB guardrail tests.

### Completion Notes List

- Implemented the full-screen in-session experience with JetBrains Mono MM:SS timer, localized step title/instructions, linear progress, live-region semantics, and recessive abandon control.
- Wired session completion persistence through `SessionLogsDao` before emitting completion and navigating to `AppRouter.sessionRpe`.
- Added `SessionStartArgs` routing support and Today handoff of `planId`/`sessionIndex`.
- Added English/Italian in-session localization keys and regenerated `app_localizations*.dart`.
- Added 17 new/updated tests for cubit timing, step generation, in-session rendering, countdown handoff, portrait overflow, and ARB key-count baseline.

### File List

- `pulse_coach/lib/features/session/domain/entities/session_start_args.dart` (NEW)
- `pulse_coach/lib/features/session/domain/entities/exercise_step.dart` (NEW)
- `pulse_coach/lib/features/session/presentation/utils/session_step_generator.dart` (NEW)
- `pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart` (NEW)
- `pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart` (NEW)
- `pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart` (NEW)
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart` (UPDATE — wire cubit + InSessionView)
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` (UPDATE — add currentPlanId getter)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (UPDATE — pass SessionStartArgs)
- `pulse_coach/lib/core/routing/app_router.dart` (UPDATE — unpack SessionStartArgs)
- `pulse_coach/lib/l10n/app/app_en.arb` (UPDATE — in-session keys)
- `pulse_coach/lib/l10n/app/app_it.arb` (UPDATE — in-session keys)
- `pulse_coach/lib/l10n/app_localizations.dart` (UPDATE — generated in-session localization API)
- `pulse_coach/lib/l10n/app_localizations_en.dart` (UPDATE — generated English in-session strings)
- `pulse_coach/lib/l10n/app_localizations_it.dart` (UPDATE — generated Italian in-session strings)
- `pulse_coach/test/bloc/in_session_cubit_test.dart` (NEW)
- `pulse_coach/test/widget/in_session_view_test.dart` (NEW)
- `pulse_coach/test/widget/session_step_generator_test.dart` (NEW)
- `pulse_coach/test/widget/countdown_overlay_test.dart` (UPDATE — fix 8.1-WIDGET-007)
- `pulse_coach/test/widget/state_indicator_test.dart` (UPDATE — ARB key-count baseline includes Story 8.2 keys)

### Change Log

- 2026-05-17: Implemented Story 8.2 InSessionView timer and step display; added session completion persistence handoff and regression tests.

### Review Findings

_Code review 2026-05-17 — Blind Hunter + Edge Case Hunter + Acceptance Auditor. AC1–AC7 all PASS at the spec-compliance level; defects below are integration / UX / robustness issues raised by the adversarial layers._

- [x] [Review][Decision→Patch] Today completion ring stays stale after in-session completion — **Resolved 2026-05-17 via option C (SessionLog stream).** Added `SessionLogsDao.watchLogsForPlan(int)` Drift-native live query; `TodaySessionCubit.planLoaded` now subscribes (with `.skip(1)` to drop the replay) and reconciles `completedIndices`/`heroIndex` whenever any writer touches `sessionLogs` — including `InSessionCubit._persistCompletion`. Subscription is cancelled on plan change and on `close()`. Single source of truth = the DB. Touched: `pulse_coach/lib/core/database/daos/session_logs_dao.dart`, `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`.
- [x] [Review][Patch] Final-step timer never displays `00:00` (off-by-one) — **Resolved.** `InSessionCubit._tick` now decrements while `secondsRemaining > 0` (was `> 1`); each step renders the `00:00` frame for one tick before advancing. Test `8.2-CUBIT-007` added to lock the behavior; `8.2-CUBIT-003`/`004` updated for new `duration+1` tick budget.
- [x] [Review][Patch] Abandon triggers a double navigation (RPE + Today) — **Resolved.** Introduced `isAbandoned` in `InSessionState`; `InSessionCubit.abandon()` now sets `isAbandoned: true` (not `isComplete: true`), so the RPE-bound `BlocListener` no longer fires on abandon. Test `8.2-CUBIT-006` updated to assert `isAbandoned && !isComplete`.
- [x] [Review][Patch] `Semantics(label: step.title, child: Text(step.title))` double-announces step title — **Resolved.** Dropped the explicit `label:` argument; the child `Text` provides the label and `liveRegion: true` is preserved (`pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart:31-38`).
- [x] [Review][Defer] Test suite uses `tester.pump(Duration)` instead of spec-mandated `fakeAsync` / `async.elapse(...)` (`pulse_coach/test/bloc/in_session_cubit_test.dart:14-89`) — deferred, contradicts the Story 8.2 Anti-Patterns table but tests pass and timer semantics are equivalent in the widget-test clock.
- [x] [Review][Defer] `SessionStepGenerator` min-clamp can exceed `totalSeconds` for short sessions (`pulse_coach/lib/features/session/presentation/utils/session_step_generator.dart:14-18`) — for `durationMinutes == 2` (120s) the three `max(60, …)` clamps sum to 180s (50% over budget). Acceptable for alpha; clean up before beta or before user-configurable durations land.
- [x] [Review][Defer] Timer drift under Android Doze / app backgrounding — `Timer.periodic` does not survive backgrounding; long sessions will under-count by seconds-to-minutes. NFR3 (±1s over full session) is at risk on physical devices. Track for Story 8.5 or a dedicated timer-anchoring story (use a `DateTime.now()` anchor instead of pure tick decrement).
- [x] [Review][Defer] No `PopScope` / back-gesture guard — Android system back swipe pops the route, `dispose` closes the cubit, no SessionLog is written, plan stays incomplete silently. Should reuse the Abandon confirmation Story 8.5 will add.
- [x] [Review][Defer] Service-locator inside widget (`pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:36-45`) — `getIt.isRegistered<SessionLogsDao>() ? getIt() : null` couples presentation to DI and complicates widget tests. Consistent with the existing codebase pattern; defer to a broader DI cleanup.
- [x] [Review][Defer] `SessionStartArgs.sessionIndex` defaults to `0` (`pulse_coach/lib/features/session/domain/entities/session_start_args.dart:12`) — a forgotten parameter silently logs every session as index 0. Make it `required` once all call sites pass it explicitly.
- [x] [Review][Defer] `_persistCompletion` swallows DAO failures via `debugPrint` (`in_session_cubit.dart:75-77`) — consistent with `TodaySessionCubit.markSessionCompleted`'s pattern, but there is no telemetry hook. Track as a project-wide observability gap.
- [x] [Review][Defer] `insertLog` idempotency under replay (`in_session_cubit.dart:67-74`) — second completion of the same `(planId, sessionIndex)` may hit a UNIQUE constraint; the current `catch` masks it. Once the markSessionCompleted wiring above lands, behavior should be explicit (`InsertMode.insertOrIgnore`).
- [x] [Review][Defer] `app_router.dart:73-82` falls back to `extra as PlannedSession?` for unknown extra types — throws TypeError on any non-`SessionStartArgs`/non-`PlannedSession?` extra (e.g. deep-link with `String`). Low risk in the current navigation surface.
