# Story 9.2: MiniSummary & CompletionRing Animation

Status: done

## Story

As a user,
I want a brief summary after submitting RPE that auto-dismisses,
so that I feel acknowledged without needing to take any action.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | RPE is submitted | When the `MiniSummary` screen renders | It shows: session type name (localized), duration completed ("X min"), RPE recorded ("X/10"), and one-line system feedback ("Registrato. Aggiustiamo l'intensità domani.") (UX-DR10) |
| AC2 | The `MiniSummary` is visible | When the `CompletionRing` within it renders | The ring starts at `previousCompletedCount / totalSessions` and animates forward to `newCompletedCount / totalSessions` (e.g., 1/3 → 2/3) during the 3-second display window (UX-DR10, UX-DR12) |
| AC3 | This was the final session (completedCount == totalSessions) | When the ring reaches 100% | The ring closes with the existing gentle pulse animation (`_pulseController.forward()` in `CompletionRing` — 400ms ease-in-out) (UX-DR12) |
| AC4 | "Reduce Motion" is enabled in the OS | When the `MiniSummary` renders | The ring updates without arc animation; the overlay still appears, displays for 3 seconds, then fades and navigates to Today (UX-DR18) |
| AC5 | The auto-dismiss timer completes (3000ms hold + 300ms fade) | When the overlay fades out | The user is returned to the Today screen with the completed session marked (UX-DR10) |
| AC6 | An abandoned session completes RPE | When MiniSummary renders | `previousCompletedCount == newCompletedCount` (no ring increment for abandoned sessions); the header reads "Sessione finita" not "Fatto!" |
| AC7 | `MiniSummaryCubit` lifecycle — **E8-P1 Cubit-lifecycle invariants** | When spec is executed | (a) auto-dismiss timer is cancelled on `close()`; (b) no state emitted after `close()`; (c) DB read failures in `_loadPlanData` emit an explicit `MiniSummaryError(Failure)` — NOT `debugPrint`-only (E8-T1 convergence); (d) at least one test covers each invariant |
| AC8 | Test guardrails — **E7.5-P2 invariant pattern** | When ARB-key assertions are written | Use presence/subset invariants only — no `expect(userFacingKeys, hasLength(N))` magnitude-based assertions; verify: no key removed, all keys load, new keys for this story are present |
| AC9 | `RpeFeedbackSubmitted` state carries `rpeValue` | When the dev reads the spec | `RpeFeedbackSubmitted` is updated to hold `final int rpeValue`, emitted from `RpeFeedbackCubit._persist(rpe)` so that `RpePage`'s listener can extract the submitted RPE without a separate local variable |

## Tasks / Subtasks

### Task 1: Add `rpeValue` to `RpeFeedbackSubmitted` state (AC9)

- [x] UPDATE `lib/features/session/presentation/bloc/rpe_feedback_state.dart`
  - Change `RpeFeedbackSubmitted` from a no-data class to carry `rpeValue`:
    ```dart
    class RpeFeedbackSubmitted extends RpeFeedbackState {
      final int rpeValue;
      const RpeFeedbackSubmitted(this.rpeValue);
    }
    ```

- [x] UPDATE `lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
  - In `_persist(int rpe)`, change `emit(const RpeFeedbackSubmitted())` to `emit(RpeFeedbackSubmitted(rpe))`
  - All other cubit logic stays unchanged.

- [x] UPDATE `test/bloc/rpe_feedback_cubit_test.dart`
  - Update `isA<RpeFeedbackSubmitted>()` matchers to verify `rpeValue` is correct:
    ```dart
    expect: () => [isA<RpeFeedbackAnimating>(), isA<RpeFeedbackSubmitted>().having((s) => s.rpeValue, 'rpeValue', 7)],
    ```
  - Compile check only — no new test functions required; this is a refinement of existing tests.

### Task 2: Add `durationMinutes` to `RpeSubmitArgs` (prerequisite for MiniSummaryArgs)

- [x] UPDATE `lib/features/session/domain/entities/rpe_submit_args.dart`
  - Add a required field `int durationMinutes` with a default of `0` via a named param default:
    ```dart
    const RpeSubmitArgs({
      this.planId,
      required this.sessionIndex,
      required this.abandoned,
      required this.armKey,
      this.sessionLogId,
      this.durationMinutes = 0, // new — Story 9.2
    });
    ```
  - Keep `sessionLogId` as-is. Do NOT change any existing fields.

- [x] UPDATE `lib/features/session/presentation/pages/in_session_page.dart`
  - In the `BlocListener` where `RpeSubmitArgs` is constructed, add:
    ```dart
    durationMinutes: widget.session?.durationMinutes ?? 0,
    ```
  - Locate the existing construction site at approximately line 97-112 (the `context.go(AppRouter.sessionRpe, extra: RpeSubmitArgs(...))` call).

### Task 3: Create `MiniSummaryArgs` navigation contract

- [x] CREATE `lib/features/session/domain/entities/mini_summary_args.dart`
  ```dart
  /// Navigation contract for the /session/summary route.
  ///
  /// Carries everything MiniSummaryPage needs to render the post-session
  /// recap without reaching into upstream Cubits.
  class MiniSummaryArgs {
    final int rpeValue;
    /// 'mobility' | 'cardio' | 'breathing'
    final String sessionType;
    final int durationMinutes;
    final bool abandoned;
    final int? planId;

    const MiniSummaryArgs({
      required this.rpeValue,
      required this.sessionType,
      required this.durationMinutes,
      required this.abandoned,
      this.planId,
    });
  }
  ```
  - Model after `RpeSubmitArgs` and `SessionStartArgs` — plain Dart value object, no freezed, no JSON.
  - `sessionType` is extracted from `RpeSubmitArgs.armKey.split('_').first` in `RpePage`.

### Task 4: Add `getPlanById` to `DailyPlansDao` (AC2 — needed for `totalSessions`)

- [x] UPDATE `lib/core/database/daos/daily_plans_dao.dart`
  - Add one method:
    ```dart
    /// Returns the raw DB row for [id], or null when not found.
    Future<DailyPlan?> getPlanById(int id) =>
        (select(dailyPlans)..where((t) => t.id.equals(id))).getSingleOrNull();
    ```
  - `DailyPlan` here is the Drift-generated data class (from `app_database.dart`), NOT the domain entity.
  - No codegen needed — this is a plain `select` query with no new annotations.

### Task 5: Create `MiniSummaryCubit` and states (AC2–AC7)

- [x] CREATE `lib/features/session/presentation/bloc/mini_summary_state.dart`
  ```dart
  import 'package:pulse_coach/core/error/failures.dart';

  sealed class MiniSummaryState {
    const MiniSummaryState();
  }

  class MiniSummaryInitial extends MiniSummaryState {
    const MiniSummaryInitial();
  }

  /// Data loaded; ring can start animating.
  class MiniSummaryLoaded extends MiniSummaryState {
    final int previousCompletedCount;
    final int newCompletedCount;
    final int totalSessions;
    const MiniSummaryLoaded({
      required this.previousCompletedCount,
      required this.newCompletedCount,
      required this.totalSessions,
    });
  }

  /// 300ms fade-out in progress; triggered after the 3000ms hold.
  class MiniSummaryFading extends MiniSummaryState {
    const MiniSummaryFading();
  }

  /// Dismiss complete — navigate to Today.
  class MiniSummaryDone extends MiniSummaryState {
    const MiniSummaryDone();
  }

  class MiniSummaryError extends MiniSummaryState {
    final Failure failure;
    const MiniSummaryError(this.failure);
  }
  ```

- [x] CREATE `lib/features/session/presentation/bloc/mini_summary_cubit.dart`
  ```dart
  import 'dart:async';
  import 'dart:convert';

  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
  import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
  import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_state.dart';

  class MiniSummaryCubit extends Cubit<MiniSummaryState> {
    final MiniSummaryArgs _args;
    final SessionLogsDao _sessionLogsDao;
    final DailyPlansDao _dailyPlansDao;
    final Duration _holdDuration;
    final Duration _fadeDuration;
    Timer? _holdTimer;
    Timer? _fadeTimer;

    MiniSummaryCubit({
      required MiniSummaryArgs args,
      required SessionLogsDao sessionLogsDao,
      required DailyPlansDao dailyPlansDao,
      Duration holdDuration = const Duration(milliseconds: 3000),
      Duration fadeDuration = const Duration(milliseconds: 300),
    })  : _args = args,
          _sessionLogsDao = sessionLogsDao,
          _dailyPlansDao = dailyPlansDao,
          _holdDuration = holdDuration,
          _fadeDuration = fadeDuration,
          super(const MiniSummaryInitial());

    Future<void> init() async {
      try {
        final (completedCount, totalSessions) = await _loadPlanData();
        if (isClosed) return;
        final newCompletedCount = completedCount;
        final previousCompletedCount =
            newCompletedCount - (_args.abandoned ? 0 : 1);
        emit(MiniSummaryLoaded(
          previousCompletedCount: previousCompletedCount.clamp(0, totalSessions),
          newCompletedCount: newCompletedCount.clamp(0, totalSessions),
          totalSessions: totalSessions,
        ));
        _scheduleAutoDismiss();
      } catch (e) {
        if (!isClosed) emit(MiniSummaryError(ServerFailure(e.toString())));
      }
    }

    Future<(int completedCount, int totalSessions)> _loadPlanData() async {
      final planId = _args.planId;
      if (planId == null) return (0, 0);

      final logs = await _sessionLogsDao.getLogsForPlan(planId);
      final completedCount = logs.where((l) => !l.abandoned).length;

      final planRow = await _dailyPlansDao.getPlanById(planId);
      int totalSessions = 0;
      if (planRow != null) {
        try {
          final domain = DailyPlan.fromJson(
            jsonDecode(planRow.planJson) as Map<String, dynamic>,
          );
          totalSessions = domain.sessions.length;
        } catch (_) {
          // Malformed JSON: default to 0 — ring shows 0/0 rather than crashing.
        }
      }
      return (completedCount, totalSessions);
    }

    void _scheduleAutoDismiss() {
      _holdTimer = Timer(_holdDuration, () {
        if (!isClosed) {
          emit(const MiniSummaryFading());
          _fadeTimer = Timer(_fadeDuration, () {
            if (!isClosed) emit(const MiniSummaryDone());
          });
        }
      });
    }

    @override
    Future<void> close() {
      _holdTimer?.cancel();
      _fadeTimer?.cancel();
      return super.close();
    }
  }
  ```

  **E8-P1 invariants honoured:**
  - `close()` cancels both timers → no `MiniSummaryDone` after close.
  - `_loadPlanData` failures emit `MiniSummaryError(Failure)` — NOT `debugPrint`-only.
  - `isClosed` checked before every emit.

### Task 6: Replace `SessionSummaryPage` placeholder with `MiniSummaryPage` (AC1–AC6)

- [x] UPDATE `lib/features/session/presentation/pages/session_summary_page.dart`
  - Rename the class from `SessionSummaryPage` to `MiniSummaryPage` and accept `MiniSummaryArgs`:
  
  ```dart
  import 'dart:async';

  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:go_router/go_router.dart';
  import 'package:pulse_coach/core/database/daos/daily_plans_dao.dart';
  import 'package:pulse_coach/core/database/daos/session_logs_dao.dart';
  import 'package:pulse_coach/core/di/injection.dart';
  import 'package:pulse_coach/core/routing/app_router.dart';
  import 'package:pulse_coach/core/theme/app_text_styles.dart';
  import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
  import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_cubit.dart';
  import 'package:pulse_coach/features/session/presentation/bloc/mini_summary_state.dart';
  import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  class MiniSummaryPage extends StatefulWidget {
    final MiniSummaryArgs? args;
    const MiniSummaryPage({this.args, super.key});
    @override
    State<MiniSummaryPage> createState() => _MiniSummaryPageState();
  }

  class _MiniSummaryPageState extends State<MiniSummaryPage>
      with SingleTickerProviderStateMixin {
    MiniSummaryCubit? _cubit;
    late AnimationController _fadeController;
    late Animation<double> _fadeAnimation;

    @override
    void initState() {
      super.initState();
      _fadeController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
        value: 1.0, // starts fully visible
      );
      _fadeAnimation = _fadeController;
      final args = widget.args;
      if (args == null) {
        // Guard: no args = bad deep-link, bounce to Today immediately
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(AppRouter.today);
        });
        return;
      }
      _cubit = MiniSummaryCubit(
        args: args,
        sessionLogsDao: getIt<SessionLogsDao>(),
        dailyPlansDao: getIt<DailyPlansDao>(),
      )..init();
    }

    @override
    void dispose() {
      _cubit?.close();
      _fadeController.dispose();
      super.dispose();
    }

    @override
    Widget build(BuildContext context) {
      final cubit = _cubit;
      final args = widget.args;
      if (cubit == null || args == null) {
        return const Scaffold(backgroundColor: Colors.transparent,
            body: SizedBox.shrink());
      }
      return PopScope(
        canPop: false,
        child: BlocProvider.value(
          value: cubit,
          child: BlocListener<MiniSummaryCubit, MiniSummaryState>(
            listenWhen: (_, current) =>
                current is MiniSummaryFading || current is MiniSummaryDone,
            listener: (context, state) {
              if (state is MiniSummaryFading) {
                _fadeController.reverse(); // fade from 1.0 → 0.0 over 300ms
              }
              if (state is MiniSummaryDone) {
                if (context.mounted) context.go(AppRouter.today);
              }
            },
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContent(context, args),
            ),
          ),
        ),
      );
    }

    Widget _buildContent(BuildContext context, MiniSummaryArgs args) {
      final theme = Theme.of(context);
      final pulseTheme = theme.extension<PulseCoachTheme>()!;
      final l10n = AppLocalizations.of(context)!;
      final sessionTypeName = _localizedSessionType(l10n, args.sessionType);
      final header = args.abandoned
          ? l10n.miniSummaryAbandonedHeader
          : l10n.miniSummaryHeader;

      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  header,
                  style: AppTextStyles.h1.copyWith(
                    color: pulseTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                // CompletionRing — driven by cubit state
                BlocBuilder<MiniSummaryCubit, MiniSummaryState>(
                  builder: (context, state) {
                    final (completed, total) = switch (state) {
                      MiniSummaryLoaded(
                        newCompletedCount: final c,
                        totalSessions: final t
                      ) =>
                        (c, t),
                      _ => (0, 0),
                    };
                    return CompletionRing(completed: completed, total: total);
                  },
                ),
                const SizedBox(height: 32),
                // Stats row
                _StatRow(
                  label: sessionTypeName,
                  value: '${args.durationMinutes} min',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: l10n.miniSummaryRpeLabel,
                  value: '${args.rpeValue}/10',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 24),
                // System feedback line
                Text(
                  l10n.miniSummaryFeedback,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: pulseTheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    static String _localizedSessionType(AppLocalizations l10n, String type) {
      return switch (type) {
        'mobility' => l10n.sessionNameMobility,
        'cardio' => l10n.sessionNameCardio,
        'breathing' => l10n.sessionNameBreathing,
        _ => type,
      };
    }
  }

  class _StatRow extends StatelessWidget {
    final String label;
    final String value;
    final TextStyle style;
    const _StatRow({required this.label, required this.value, required this.style});

    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      );
    }
  }
  ```

  **Architecture notes:**
  - `_fadeController.reverse()` drives `FadeTransition` from 1.0 → 0.0 when `MiniSummaryFading` fires (300ms).
  - `PopScope(canPop: false)` — user cannot back out; the auto-dismiss resolves to Today.
  - No AppBar — headless post-session flow (matches `RpePage`).
  - `Scaffold` background: `theme.colorScheme.surface` — calm, consistent with RPE screen.
  - The `CompletionRing` widget handles its own arc animation internally via `didUpdateWidget`; no additional orchestration needed. Initially rendered with `(0,0)`, then `MiniSummaryLoaded` state delivers the real `(newCompletedCount, totalSessions)`. The ring's `didUpdateWidget` detects the change and animates.
  - For "Reduce Motion": `CompletionRing` internally respects `MediaQuery.disableAnimationsOf(context)` via its `didUpdateWidget` logic (already implemented in Story 7.4). No extra handling needed in `MiniSummaryPage`.
  - The `_FadeTransition.reverse()` approach does NOT animate when Reduce Motion is enabled because `AnimationController` checks `disableAnimations` on creation — but `AnimationController` does NOT auto-disable for Reduce Motion. Add a check: if `MediaQuery.disableAnimationsOf(context)`, call `_fadeController.value = 0` directly and then navigate.

  **IMPORTANT — Reduce Motion fade handling**: Replace the `listener` fade logic with:
  ```dart
  if (state is MiniSummaryFading) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations) {
      _fadeController.value = 0.0; // instant
    } else {
      _fadeController.reverse();
    }
  }
  ```

### Task 7: Update `RpePage` to navigate to `/session/summary` on success (AC5)

- [x] UPDATE `lib/features/session/presentation/pages/rpe_page.dart`
  - Import `mini_summary_args.dart`.
  - Change the `RpeFeedbackSubmitted` BlocListener to navigate to summary instead of Today:
    ```dart
    BlocListener<RpeFeedbackCubit, RpeFeedbackState>(
      listenWhen: (previous, current) =>
          current is RpeFeedbackSubmitted &&
          previous is! RpeFeedbackSubmitted,
      listener: (context, state) {
        if (!context.mounted) return;
        final submitted = state as RpeFeedbackSubmitted;
        final a = widget.args;
        final summaryArgs = a == null
            ? null
            : MiniSummaryArgs(
                rpeValue: submitted.rpeValue,
                sessionType: a.armKey.split('_').first,
                durationMinutes: a.durationMinutes,
                abandoned: a.abandoned,
                planId: a.planId,
              );
        context.go(
          AppRouter.sessionSummary,
          extra: summaryArgs,
        );
      },
    ),
    ```
  - The `RpeFeedbackError` listener is unchanged — still navigates to Today.
  - `a.armKey.split('_').first` safely extracts session type from `'{sessionType}_{intensity}'` (e.g. `'mobility_low'` → `'mobility'`). If armKey is empty (edge case guarded in Story 9.1 P7), `split('_').first` returns `''` which `_localizedSessionType` falls back to the raw string.

### Task 8: Update `AppRouter` for `sessionSummary` route

- [x] UPDATE `lib/core/routing/app_router.dart`
  - Add import for `MiniSummaryArgs` and `MiniSummaryPage`:
    ```dart
    import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
    import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
    ```
  - Update the `sessionSummary` GoRoute builder (currently at approximately line 93-94):
    ```dart
    GoRoute(
      path: sessionSummary,
      builder: (context, state) {
        final extra = state.extra;
        return MiniSummaryPage(
          args: extra is MiniSummaryArgs ? extra : null,
        );
      },
    ),
    ```
  - `MiniSummaryPage` is still exported from `session_summary_page.dart` — same file, renamed class.

### Task 9: Add l10n keys for MiniSummary screen (AC1, AC6)

- [x] UPDATE `lib/l10n/app/app_it.arb`
  ```json
  "miniSummaryHeader": "Fatto!",
  "miniSummaryAbandonedHeader": "Sessione finita",
  "miniSummaryRpeLabel": "Sforzo",
  "miniSummaryFeedback": "Registrato. Aggiustiamo l'intensità domani.",
  "miniSummarySemanticLabel": "Sessione completata. {duration} minuti, sforzo {rpe}.",
  "@miniSummarySemanticLabel": {
    "placeholders": {
      "duration": {"type": "String"},
      "rpe": {"type": "String"}
    }
  }
  ```

- [x] UPDATE `lib/l10n/app/app_en.arb`
  ```json
  "miniSummaryHeader": "Done!",
  "miniSummaryAbandonedHeader": "Session ended",
  "miniSummaryRpeLabel": "Effort",
  "miniSummaryFeedback": "Got it. Adjusting intensity tomorrow.",
  "miniSummarySemanticLabel": "Session complete. {duration} minutes, effort {rpe}.",
  "@miniSummarySemanticLabel": {
    "placeholders": {
      "duration": {"type": "String"},
      "rpe": {"type": "String"}
    }
  }
  ```

- [x] Run `flutter pub get` to trigger `gen_l10n` — confirm new getters (`miniSummaryHeader`, `miniSummaryAbandonedHeader`, `miniSummaryRpeLabel`, `miniSummaryFeedback`, `miniSummarySemanticLabel`) appear in `AppLocalizations`.

### Task 10: Unit tests — `MiniSummaryCubit` (AC5, AC7, E8-P1)

- [x] CREATE `test/bloc/mini_summary_cubit_test.dart`

  **9.2-CUBIT-001: init() emits Loaded with correct completedCount and totalSessions**
  - Fake DAO returns 2 non-abandoned logs; plan JSON has 3 sessions.
  - Assert `MiniSummaryLoaded(previousCompletedCount: 1, newCompletedCount: 2, totalSessions: 3)`.

  **9.2-CUBIT-002: auto-dismiss fires Fading → Done after hold + fade durations**
  - Use injected durations of 50ms + 50ms.
  - Assert sequence: `[MiniSummaryLoaded(...), MiniSummaryFading(), MiniSummaryDone()]`.

  **9.2-CUBIT-003: Reduce Motion — cubit still fires Fading/Done; animation is the UI's responsibility**
  - Cubit emits the same state sequence regardless of OS setting.
  - The UI handles Reduce Motion in the BlocListener (tested in widget test).

  **9.2-CUBIT-004: close() before timer fires → no Done emitted after close**
  - Start init() with 500ms hold; call close() after 100ms.
  - Assert `MiniSummaryDone` is NOT emitted.
  - Verify no `StateError` (emit after close).

  **9.2-CUBIT-005: abandoned=true → previousCompletedCount == newCompletedCount**
  - `args.abandoned = true`, DB returns 1 non-abandoned log.
  - Assert `Loaded(previousCompletedCount: 1, newCompletedCount: 1, totalSessions: 3)`.

  **9.2-CUBIT-006: DB failure in _loadPlanData → emits MiniSummaryError (E8-T1)**
  - Fake `SessionLogsDao.getLogsForPlan` throws `Exception('db error')`.
  - Assert `isA<MiniSummaryError>()`.
  - Verify `failure.message` is non-empty.

  **9.2-CUBIT-007: planId==null → emits Loaded(0,0,0), still auto-dismisses**
  - `args.planId = null` — no DB calls.
  - Assert `Loaded(previousCompletedCount: 0, newCompletedCount: 0, totalSessions: 0)` then timer sequence.

  ```dart
  // Fake stubs (add at top of test file):
  class _FakeSessionLogsDao extends Fake implements SessionLogsDao {
    List<SessionLog> logs = [];
    bool shouldThrow = false;
    @override
    Future<List<SessionLog>> getLogsForPlan(int planId) async {
      if (shouldThrow) throw Exception('db error');
      return logs;
    }
  }

  class _FakeDailyPlansDao extends Fake implements DailyPlansDao {
    DailyPlan? planRow;
    @override
    Future<DailyPlan?> getPlanById(int id) async => planRow;
  }
  ```
  Note: `DailyPlan` used in fakes is the Drift-generated data class from `app_database.dart`, NOT the domain entity. The fake returns a row with `planJson` set to a valid JSON string `'{"planDate":"2026-05-21","sessions":[...],"generatedAt":"..."}'`.

### Task 11: Widget tests — `MiniSummaryPage` (AC1–AC6)

- [x] CREATE `test/widget/mini_summary_page_test.dart`

  **9.2-PAGE-001: Renders header, session type, duration, RPE, feedback text**
  - Provide `MockMiniSummaryCubit` in `MiniSummaryLoaded` state.
  - `args = MiniSummaryArgs(rpeValue: 7, sessionType: 'mobility', durationMinutes: 12, abandoned: false, planId: null)`.
  - Verify: `l10n.miniSummaryHeader` present, `'Mobilità'` present, `'12 min'` present, `'7/10'` present, `l10n.miniSummaryFeedback` present.

  **9.2-PAGE-002: Abandoned session shows correct header**
  - `args.abandoned = true` → verify `l10n.miniSummaryAbandonedHeader` present.

  **9.2-PAGE-003: MiniSummaryDone navigates to Today**
  - Emit `MiniSummaryDone()`; verify `context.go(AppRouter.today)` called (use GoRouter observer pattern from existing tests).

  **9.2-PAGE-004: MiniSummaryFading triggers fade controller reverse**
  - Emit `MiniSummaryFading()`; pump; verify `FadeTransition` opacity < 1.0.

  **9.2-PAGE-005: CompletionRing receives correct completed/total from Loaded state**
  - Emit `MiniSummaryLoaded(previousCompletedCount: 1, newCompletedCount: 2, totalSessions: 3)`.
  - Find `CompletionRing` widget; verify `completed: 2, total: 3`.

  **9.2-PAGE-006: null args → no crash, bounces to Today**
  - `MiniSummaryPage(args: null)` → post-frame callback → `context.go(AppRouter.today)`.

### Task 12: E7.5-P2 invariant-style ARB test (AC8)

- [x] UPDATE `test/widget/state_indicator_test.dart` (the canonical ARB invariant test file established in Story 9.1):
  - Add assertions for the 5 new Story 9.2 keys:
    ```dart
    expect(allKeys, contains('miniSummaryHeader'));
    expect(allKeys, contains('miniSummaryAbandonedHeader'));
    expect(allKeys, contains('miniSummaryRpeLabel'));
    expect(allKeys, contains('miniSummaryFeedback'));
    expect(allKeys, contains('miniSummarySemanticLabel'));
    ```
  - Do NOT add a new `hasLength(N)` assertion — invariant-only per E7.5-P2.

### Task 13: Baseline verification

- [x] Run `flutter pub get` — confirm gen_l10n produces new getters.
- [x] Run `flutter test` from `pulse_coach/` — expect all existing 636 tests to pass plus the new ones.
- [x] Run `flutter analyze` — expect 0 issues.
- [x] Manual smoke on device (when available):
  - Start session → complete → RPE tap → MiniSummary appears → ring animates (e.g., 0/3 → 1/3) → auto-dismisses after ~3s → Today shows completed session card.
  - Abandon session → RPE tap → MiniSummary shows "Sessione finita" → ring does NOT increment → Today shows no new completion.

## Dev Notes

### Navigation Flow Change: RPE → MiniSummary → Today

**Story 9.1 flow (current):** InSessionPage → `/session/rpe` → (on submit) → `/today`
**Story 9.2 flow (new):** InSessionPage → `/session/rpe` → (on submit) → `/session/summary` → (after 3.3s) → `/today`

The only change in `RpePage` is the navigation target on `RpeFeedbackSubmitted`. The `RpeFeedbackError` path still goes directly to `/today`.

### `RpeFeedbackSubmitted.rpeValue` — Backward Compatibility

`RpeFeedbackSubmitted` gains `rpeValue`. All existing tests that assert on `isA<RpeFeedbackSubmitted>()` continue to compile (the field is new, not a breaking change to the `is`-check). Tests that `expect: () => [..., const RpeFeedbackSubmitted()]` will fail because the const constructor is gone — update them per Task 1.

### `SessionSummaryPage` Class Name

The file `session_summary_page.dart` retains its name for routing consistency. The class inside is renamed from `SessionSummaryPage` to `MiniSummaryPage`. Update all references (there is exactly one: `app_router.dart` line 94).

### `CompletionRing` Integration — No Code Change to Widget

The existing `CompletionRing` widget (`lib/features/today/presentation/widgets/completion_ring.dart`) already:
- Handles arc animation in `didUpdateWidget` (Tween from `currentValue` to `newProgress`)
- Handles pulse on final-session completion (`!wasCompleted && isCompleted`)
- Respects `MediaQuery.disableAnimationsOf(context)` for Reduce Motion
- Accepts `completed` and `total` as inputs

**No changes needed to `CompletionRing`**. The `MiniSummaryPage` simply:
1. Initially renders with `completed: 0, total: 0` (while cubit is loading)
2. When `MiniSummaryLoaded` arrives, passes `completed: newCompletedCount, total: totalSessions`
3. `CompletionRing.didUpdateWidget` triggers the arc animation automatically

For the "animates FROM previous TO new" AC: `CompletionRing` starts from the progress value currently displayed. Since on initial render `completed=0`, then the state update sets `completed=newCompletedCount`, the ring will animate from 0 to `newCompletedCount/total`. This may not match AC2 literally ("1/3 → 2/3"). To get precise start-from-previous animation:
- Initialize `CompletionRing(completed: previousCompletedCount, total: totalSessions)` in the initial render, then let `MiniSummaryLoaded` update to `newCompletedCount`.
- This requires `BlocBuilder` to pass the RIGHT initial value from `MiniSummaryLoaded.previousCompletedCount` as the `CompletionRing`'s first `completed` value, then immediately follow up with `newCompletedCount`.

**Implementation detail:** Use a two-step render driven by `MiniSummaryLoaded`:
```dart
BlocBuilder<MiniSummaryCubit, MiniSummaryState>(
  builder: (context, state) {
    return switch (state) {
      MiniSummaryLoaded(:final previousCompletedCount, :final newCompletedCount, :final totalSessions) =>
        _AnimatedRingTransition(
          key: ValueKey('ring-$newCompletedCount'),
          previousCount: previousCompletedCount,
          newCount: newCompletedCount,
          total: totalSessions,
        ),
      _ => CompletionRing(completed: 0, total: 0),
    };
  },
),
```

Where `_AnimatedRingTransition` is a private StatefulWidget that in `initState` initializes `CompletionRing` with `previousCount`, then post-frame sets it to `newCount` — triggering the arc animation.

OR: simpler — just pass `newCount` directly and accept that the ring animates from 0 to `newCount` (e.g. 0/3 → 2/3 rather than 1/3 → 2/3). The AC says "progresses from previous to new" but since the MiniSummary is a full-screen overlay, users won't have the previous ring state visible for comparison. The simpler approach is acceptable for MVP.

**Decision for this story: Use the simple approach** (ring starts from 0, animates to `newCompletedCount`). The previous-count animation is a nice-to-have, not a functional requirement. If PM wants the precise 1/3 → 2/3 behavior, it can be a follow-up.

### `MiniSummaryCubit` - DI Registration

`MiniSummaryCubit` is NOT registered with `@injectable` — it is constructed inline in `MiniSummaryPage.initState()` with `getIt<SessionLogsDao>()` and `getIt<DailyPlansDao>()`. This follows the same pattern as `RpeFeedbackCubit` and `InSessionCubit`.

### `DailyPlansDao.getPlanById` — Return Type Clarification

The return type is `Future<DailyPlan?>` where `DailyPlan` is the **Drift-generated data class** (the DB row), NOT `pulse_coach/features/daily_plan/domain/entities/daily_plan.dart`. The domain entity is only created by `jsonDecode(row.planJson)` inside `_loadPlanData`. The two classes have the same name but different import paths — use the Drift one in the DAO method:
- DAO method: returns `package:pulse_coach/core/database/app_database.dart`'s `DailyPlan`
- Domain entity: `package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart`

This naming collision means `mini_summary_cubit.dart` must use a hide/as import to disambiguate:
```dart
import 'package:pulse_coach/core/database/app_database.dart' hide DailyPlan;
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart' as DomainPlan;
// Then: final domain = DomainPlan.DailyPlan.fromJson(...)
```

OR: more idiomatically — rename the local variable in `_loadPlanData`:
```dart
import 'package:pulse_coach/core/database/app_database.dart' as db;
import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
// In DAO method: Future<db.DailyPlan?> getPlanById(int id)
// In cubit: final planRow = await _dailyPlansDao.getPlanById(planId); // type: db.DailyPlan?
//           final domain = DailyPlan.fromJson(jsonDecode(planRow!.planJson) as Map<String, dynamic>);
```

**This import ambiguity MUST be handled explicitly or it will cause a compile error.** Use the `as db` approach for clarity.

### `MiniSummaryPage` — Nav Bar Visibility

`/session/summary` is outside the `ShellRoute`, so `AppShell` is NOT rendered. The nav bar is not visible on this screen, which is correct per UX spec (UX-DR: "Nav bar hidden during MiniSummary").

### Import: `SchedulerBinding`

`MiniSummaryPage.initState()` uses `SchedulerBinding.instance.addPostFrameCallback` for the null-args guard. Add `import 'package:flutter/scheduler.dart';` — same as `RpePage`.

### Previous Story (9.1) Learnings Applied

- **No confirm button, no dialog**: MiniSummary is fully auto-dismissing — `PopScope(canPop: false)`.
- **`getIt` never in `build()`**: All `getIt` calls stay in `initState()`.
- **`isClosed` guard before every emit**: Applied in all Timer callbacks in `MiniSummaryCubit`.
- **Single-shot after error**: `MiniSummaryError` is terminal — no retry.
- **Generated ARB files gitignored**: Never stage `app_localizations*.dart`.
- **E7.5-T1 still pending**: Do NOT touch `BehavioralStateMachine` in this story.

### E7.5-T1 Status (Dead ARB transition* keys)

Still pending — NOT touched in Story 9.2. Re-targeted to Story 9.3 as stretch goal per action-item-ledger.md.

### References

- Epic 9 Story 9.2 spec: `_bmad-output/planning-artifacts/epics.md` (lines 1464–1491)
- UX-DR10 (MiniSummary timing + content): `_bmad-output/planning-artifacts/ux-design-specification.md` line 388, 494–499, 1158–1178
- UX-DR12 (CompletionRing pulse): `ux-design-specification.md` line 1447
- UX-DR18 (Reduce Motion): `ux-design-specification.md` line 1460
- E8-P1 Cubit lifecycle invariants: `action-item-ledger.md` line 129
- E8-T1 logger replacement: `action-item-ledger.md` line 132
- E7.5-P2 invariant-based test guardrails: `action-item-ledger.md` line 120
- E7.5-T1 dead ARB keys: `action-item-ledger.md` (re-targeted to Story 9.3)
- `RpeFeedbackState` (to update): `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_state.dart`
- `RpeFeedbackCubit` (to update): `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
- `RpeSubmitArgs` (to update): `pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart`
- `RpePage` (to update): `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart:74-87`
- `InSessionPage` (to update): `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:97-115`
- `SessionSummaryPage` placeholder: `pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart`
- `AppRouter` (to update): `pulse_coach/lib/core/routing/app_router.dart:93-94`
- `DailyPlansDao` (to update): `pulse_coach/lib/core/database/daos/daily_plans_dao.dart`
- `CompletionRing` (no change needed): `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart`
- `AppTextStyles`: `pulse_coach/lib/core/theme/app_text_styles.dart`
- `PulseCoachTheme`: `pulse_coach/lib/core/theme/pulse_coach_theme.dart`
- `SessionLogsDao`: `pulse_coach/lib/core/database/daos/session_logs_dao.dart`
- Previous story 9.1: `_bmad-output/implementation-artifacts/9-1-rpeinput-component.md`
- Sprint status: `_bmad-output/implementation-artifacts/sprint-status.yaml`
- ARB source files: `pulse_coach/lib/l10n/app/app_it.arb`, `app_en.arb`
- Story 9.1 cubit tests (pattern reference): `pulse_coach/test/bloc/rpe_feedback_cubit_test.dart`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- 2026-05-21: `flutter test test/bloc/rpe_feedback_cubit_test.dart` failed before implementation because `RpeFeedbackSubmitted.rpeValue` did not exist.
- 2026-05-21: `flutter test test/bloc/rpe_feedback_cubit_test.dart` passed after adding `rpeValue`.
- 2026-05-21: `flutter test` passed with 636/636 tests after Task 1.
- 2026-05-21: `flutter test test/bloc/mini_summary_cubit_test.dart` failed before implementation because MiniSummary cubit/state files did not exist.
- 2026-05-21: `flutter test test/bloc/mini_summary_cubit_test.dart test/bloc/rpe_feedback_cubit_test.dart test/widget/in_session_page_abandon_test.dart test/widget/rpe_page_test.dart test/widget/mini_summary_page_test.dart test/widget/state_indicator_test.dart` passed after implementation.
- 2026-05-21: `flutter test` failed once because `pages_smoke_test.dart` still referenced renamed `SessionSummaryPage`; updated smoke test to `MiniSummaryPage`.
- 2026-05-21: `flutter test` passed with 649/649 tests.
- 2026-05-21: `flutter analyze` passed with no issues.
- 2026-05-21: `flutter devices` found macOS, Chrome, and wireless iPhone; the known Android device was not available, so Android manual smoke was not executed.

### Implementation Plan

- Follow task order with focused red-green-refactor checkpoints.
- Keep RPE submission as the source of truth for the submitted value, carrying it through `RpeFeedbackSubmitted` so navigation can build `MiniSummaryArgs` without page-local state.
- Construct `MiniSummaryCubit` in `MiniSummaryPage.initState()` with DAO dependencies from `getIt`, keeping `getIt` out of build and preserving route-local lifecycle ownership.
- Keep `CompletionRing` unchanged; drive the previous-to-new transition from MiniSummary with a private two-frame wrapper so Story 9.2 owns the post-RPE animation behavior.

### Completion Notes List

- Task 1 complete: `RpeFeedbackSubmitted` now carries the submitted RPE value and cubit tests verify the emitted value.
- Added `durationMinutes` to `RpeSubmitArgs` and passed planned session duration from `InSessionPage`.
- Added `MiniSummaryArgs`, `MiniSummaryCubit`, and MiniSummary states for post-RPE summary data loading, auto-dismiss, explicit error state, and close-safe timer cancellation.
- Replaced the summary placeholder with `MiniSummaryPage`, including localized content, Reduce Motion fade handling, non-poppable flow, completion ring handoff, and Today navigation after hold/fade.
- Updated RPE success navigation to pass `MiniSummaryArgs` to `/session/summary`; persistence errors still return to Today.
- Added Italian/English ARB keys and invariant-style ARB coverage for the MiniSummary copy.
- Added cubit/widget tests for MiniSummary and updated related RPE, InSession, and smoke tests.

### File List

- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_state.dart`
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
- `pulse_coach/lib/features/session/domain/entities/rpe_submit_args.dart`
- `pulse_coach/lib/features/session/domain/entities/mini_summary_args.dart`
- `pulse_coach/lib/features/session/presentation/bloc/mini_summary_state.dart`
- `pulse_coach/lib/features/session/presentation/bloc/mini_summary_cubit.dart`
- `pulse_coach/lib/features/session/presentation/pages/in_session_page.dart`
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart`
- `pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart`
- `pulse_coach/lib/core/database/daos/daily_plans_dao.dart`
- `pulse_coach/lib/core/routing/app_router.dart`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/test/bloc/rpe_feedback_cubit_test.dart`
- `pulse_coach/test/bloc/mini_summary_cubit_test.dart`
- `pulse_coach/test/widget/in_session_page_abandon_test.dart`
- `pulse_coach/test/widget/rpe_page_test.dart`
- `pulse_coach/test/widget/mini_summary_page_test.dart`
- `pulse_coach/test/widget/state_indicator_test.dart`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `_bmad-output/implementation-artifacts/9-2-minisummary-and-completionring-animation.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`

### Change Log

- 2026-05-21: Story 9.2 created by create-story workflow.
- 2026-05-21: Added `rpeValue` to `RpeFeedbackSubmitted` and updated cubit tests.
- 2026-05-21: Implemented MiniSummary navigation contract, cubit, page, l10n copy, DAO lookup, and tests.
- 2026-05-21: Story implementation completed and marked ready for review.
- 2026-05-21: Code review (bmad-code-review). 2 decisions resolved, 11 patches applied (P1 MiniSummaryError nav-to-Today, P2 cached Loaded snapshot, P3+P5+P7+P8+P10+P11 new tests, P6 deleted tautological CUBIT-003, P8 stable error message + debugPrint, P9 RpeFeedbackSubmitted named param, P10 documented await barrier in InSessionCubit, P11 hard-fail on malformed planJson, P12 Reduce-Motion fade short-circuit). 3 items deferred to DF10–DF12. All tests: 654/654 pass; analyzer: 0 issues. Status → done.

### Review Findings

**Code review run:** 2026-05-21 (bmad-code-review, full mode — diff vs uncommitted changes; layers: Blind Hunter, Edge Case Hunter, Acceptance Auditor).

**Summary:** 0 `decision-needed` (resolved → patch), 11 `patch`, 3 `defer`, 10 dismissed.

**Decisions resolved (2026-05-21):**
- Decision #1 → resolved as **Option 1**: await `_persistCompletion()` in `InSessionCubit` before navigating to RPE (now Patch #10 below). Cross-story scope acknowledged.
- Decision #2 → resolved as **Option 1**: emit `MiniSummaryError` on malformed `planJson` (now Patch #11 below). Coupled to Patch #1 error UX.

#### Patch (fixable now)

- [x] [Review][Patch] **`MiniSummaryError` is terminal but has no UI, no timer, and PopScope blocks back → user permanently stuck on a 0/0 ring** [`session_summary_page.dart:80-95`] — `BlocListener.listenWhen` does not react to `MiniSummaryError`; `_scheduleAutoDismiss` is only called inside the `try` block in `MiniSummaryCubit.init` (after the Loaded emit), so no Done is ever emitted on the error path. Combined with `PopScope(canPop:false)`, the user has no exit. Fix: in the BlocListener, treat `MiniSummaryError` as terminal — auto-navigate to Today (and optionally show a one-line error toast). Add an `MiniSummaryError` widget test.

- [x] [Review][Patch] **`BlocBuilder` default arm renders `CompletionRing(0,0)` for any state ≠ Loaded → ring snaps to 0 during Fading/Done/Error** [`session_summary_page.dart:136-152`] — As soon as `MiniSummaryFading` arrives, the BlocBuilder rebuilds and falls into `_ => CompletionRing(0,0)`. During the 300 ms fade-out the user sees the ring snap down to empty. Fix: persist the last `MiniSummaryLoaded` payload (e.g., via a cached snapshot in state, or by switching to a class-level `late MiniSummaryLoaded _lastLoaded` and showing it during Fading) so the ring keeps its final value while the page fades.

- [x] [Review][Patch] **AC2 test `9.2-PAGE-005` doesn't assert start-from-previous transition** [`test/widget/mini_summary_page_test.dart`] — The test only asserts the final state `completed: 2, total: 3`. AC2's literal "animates from 1/3 to 2/3" is untested. Fix: pump once after `MiniSummaryLoaded` is emitted, assert `CompletionRing.completed == previousCompletedCount` on the first frame; pump again past the post-frame callback, assert `completed == newCompletedCount`.

- [x] [Review][Patch] **AC3 final-session pulse is untested** — No widget test pumps `(N-1)/N → N/N` and verifies the `CompletionRing._pulseController` triggers. Add a widget test under `mini_summary_page_test.dart` that emits `MiniSummaryLoaded(previousCompletedCount: 2, newCompletedCount: 3, totalSessions: 3)` and asserts a pulse-related observable (e.g., `AnimatedBuilder` scale > 1.0, or `find.byKey('completion-ring-pulse')` after the second pump).

- [x] [Review][Patch] **AC4 Reduce Motion path is untested** — `9.2-PAGE-004` runs with default `disableAnimations: false`; there is no test that toggles `MediaQueryData.copyWith(disableAnimations: true)` and verifies the fade is instant (opacity == 0 immediately on Fading) AND that `MiniSummaryDone` still navigates to Today after the cubit fade timer. Add a dedicated Reduce-Motion widget test.

- [x] [Review][Patch] **Cubit test `9.2-CUBIT-003` is tautological** [`test/bloc/mini_summary_cubit_test.dart`] — Name claims "Reduce Motion — cubit fires same sequence regardless of OS setting" but the test never toggles a motion flag. Either delete the test (cubit doesn't read `MediaQuery`) or rename it to clarify it verifies "cubit timer sequence is OS-independent" (effectively the same as CUBIT-002). Recommend deletion to avoid false-positive coverage signal.

- [x] [Review][Patch] **`totalSessions == 0` with `newCompletedCount > 0` → both clamped to 0, hiding inconsistency** [`mini_summary_cubit.dart:67-69`] — Same root as the malformed-JSON decision. Once #8 (decision-needed) is resolved by emitting `MiniSummaryError`, this clamp degenerate-case disappears. Fix-together with the decision outcome.

- [x] [Review][Patch] **`MiniSummaryError(ServerFailure(e.toString()))` leaks raw exception text into a UI-facing Failure** [`mini_summary_cubit.dart:48`] — `e.toString()` from Drift / SQLite exceptions becomes the `failure.message`. Replace with a stable, localized-friendly message (e.g., `ServerFailure('mini_summary_load_failed')` or a sentinel), and log the original exception via `debugPrint` (acceptable here — not a user-facing pathway, just diagnostic).

- [x] [Review][Patch] **`RpeFeedbackSubmitted(this.rpeValue)` is a positional unnamed int** [`rpe_feedback_state.dart`] — Easy to confuse with an index/count at future call sites. Rename to a named required parameter: `RpeFeedbackSubmitted({required this.rpeValue})`. Update the one emit site in `rpe_feedback_cubit.dart` and the test matchers.

- [x] [Review][Patch] **Reduce Motion fade leaves 300 ms invisible page before navigation** [`session_summary_page.dart:84-95` + `mini_summary_cubit.dart:_fadeDuration`] — On Reduce Motion the fade controller snaps to 0 instantly, but the cubit's `_fadeTimer` still waits 300 ms before emitting `MiniSummaryDone`. Result: the page is fully transparent but mounted for 300 ms. Fix: when Reduce Motion is detected (UI side), shorten or skip the fade timer — either pass a flag into the cubit on init, or have the listener cancel/short-circuit and call `context.go(today)` directly.

- [x] [Review][Patch] **(from Decision #1) Await `_persistCompletion()` before RPE navigation** [`in_session_cubit.dart:108`] — Change `unawaited(_persistCompletion())` to `await _persistCompletion()` (or chain the navigation off its completion) so the SessionLog row is committed before RPE/MiniSummary can read it. This fixes the silent AC2 happy-path failure (`previousCompletedCount = -1` clamped to 0). Cross-story scope — touches Epic 8 code; flag in PR description. Update any test that depended on fire-and-forget timing.

- [x] [Review][Patch] **(from Decision #2) Emit `MiniSummaryError` on malformed `planJson`** [`mini_summary_cubit.dart:67-69`] — Replace `catch (_) { totalSessions = 0; }` inside `_loadPlanData` with a rethrow (or `emit(MiniSummaryError(...))` directly) so the outer try/catch in `init()` surfaces it. With Patch #1 (error→nav-to-Today) already shipping, the user no longer gets stuck. Add a `9.2-CUBIT-008` test: stub `planRow.planJson = '{not json'` → expect `MiniSummaryError` emitted.

#### Defer (real but pre-existing / out-of-story scope)

- [x] [Review][Defer] **Plain `Timer` not paused on app lifecycle (backgrounded → premature nav-to-Today)** — Affects all timer-driven flows in the app, not just MiniSummary. Pattern-level fix. Track separately.
- [x] [Review][Defer] **`RpeSubmitArgs.durationMinutes = 0` silent default** — Currently only one call site (`in_session_page.dart`) wires it, so safe today. Becomes a footgun if a second call site forgets. Add a lint or remove the default in a future refactor.
- [x] [Review][Defer] **`armKey.split('_').first` fragile to format changes / unknown session types** [`rpe_page.dart`] — Current `armKey` format is `{type}_{intensity}` and stable. Falls through `_localizedSessionType` to raw key for unknown types. Tie to E7.5-T1 work / future i18n hardening.

#### Dismissed (10 — noise, false positives, or already handled)

`Equatable` on args/states (sealed switch covers); transparent-frame flash on null-args bounce (single 16 ms frame, addressed by post-frame redirect); `planId == 0` edge (Drift autoincrement starts at 1); smoke-test scope intentionally minimal; `getIt` in `initState` is project pattern; `_fadeController.reverse()` during dispose (BlocListener path safe); state dedupe via Equatable (each state emitted at most once); `init()` re-entry (single call site); Dev Notes line 719 "simple approach" paragraph stale (implementation matches AC2 literal — paragraph could be cleaned but it's documentation, not a defect); `_AnimatedRingTransition.didUpdateWidget` "dead branch" (defensive, not actionable).
