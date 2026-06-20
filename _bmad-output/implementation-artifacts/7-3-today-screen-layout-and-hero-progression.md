# Story 7.3: Today Screen Layout & Hero Progression

Status: done

## Story

As a user,
I want the Today screen to show my next recommended session as a prominent hero with remaining sessions below,
So that I know exactly what to do without any scanning or deciding.

## Acceptance Criteria

| AC | Given | When | Then |
|---|---|---|---|
| AC1 | A `DailyPlan` with 3 sessions is loaded | The Today screen renders | Layout is top-to-bottom: state bar (StateIndicator + small CompletionRing), hero `HeroSessionCard` (full width, above fold), "COMING UP" section header, 2 `CompactSessionCard` items (FR5, FR15, UX-DR6) |
| AC2 | The Today screen renders on a standard phone | Inspected without scrolling | The hero card, state bar, "Inizia sessione" button, and AI explanation are all visible — no scroll required to see the primary action (UX-DR6) |
| AC3 | Session 1 is completed | The user returns to Today | Session 2 becomes the new hero card; Session 3 moves to the "COMING UP" list with 1 item (UX-DR6) |
| AC4 | All 3 sessions are completed | The hero zone renders | It displays a "Ottimo lavoro! Tutte le sessioni completate per oggi." completion state — no HeroSessionCard (UX-DR6) |
| AC5 | The plan is loading | Inspected | Shimmer placeholders matching the session card layout are displayed — no `CircularProgressIndicator` (ARCH10) |
| AC6 | A `CompactSessionCard` is tapped | The in-page swap occurs | The tapped session becomes the new hero card; the previous hero is moved to the COMING UP list; no navigation occurs |

## Tasks / Subtasks

---

### Task 1: Add `behavioralState` to `DailyPlanState.loaded` (AC1, AC6)

- [x] UPDATE `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
  - [x] Add import: `import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';`
  - [x] Change `DailyPlanState.loaded` factory to:
    ```dart
    const factory DailyPlanState.loaded({
      required DailyPlan plan,
      @Default(BehavioralState.active) BehavioralState behavioralState,
    }) = DailyPlanLoaded;
    ```
  - [x] In `_onGenerateRequested` success branch: read `_db.behavioralStateDao.getLatestState()` and call `_parseState(row?.currentState)` — emit with both `plan` and `behavioralState`
  - [x] In `_onRegenerateRequested` success branch: same behavioral state read + emit
  - [x] Add `_parseState(String? s) → BehavioralState` helper method to `DailyPlanBloc` (copy pattern from `GenerateDailyPlan._parseState` — see Dev Notes below)
  - [x] Add `AppDatabase _db` to bloc constructor and inject via `@injectable`
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `daily_plan_bloc.freezed.dart`

---

### Task 2: Create `TodaySessionCubit` (AC3, AC4, AC6)

- [x] CREATE `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` (NEW)
  - [x] State: plain class (no freezed needed — just int fields):
    ```dart
    class TodaySessionState {
      final int heroIndex;
      final int completedCount;
      final int totalSessions;
      const TodaySessionState({
        this.heroIndex = 0,
        this.completedCount = 0,
        this.totalSessions = 0,
      });
      TodaySessionState copyWith({int? heroIndex, int? completedCount, int? totalSessions}) => TodaySessionState(
        heroIndex: heroIndex ?? this.heroIndex,
        completedCount: completedCount ?? this.completedCount,
        totalSessions: totalSessions ?? this.totalSessions,
      );
    }
    ```
  - [x] Cubit class (NO `@injectable` — created inline at route level):
    ```dart
    class TodaySessionCubit extends Cubit<TodaySessionState> {
      TodaySessionCubit() : super(const TodaySessionState());
      void planLoaded(int totalSessions) =>
          emit(TodaySessionState(heroIndex: 0, completedCount: 0, totalSessions: totalSessions));
      void swapHero(int tappedSessionIndex) =>
          emit(state.copyWith(heroIndex: tappedSessionIndex));
      void markSessionCompleted() {
        final next = state.heroIndex + 1;
        emit(state.copyWith(
          completedCount: state.completedCount + 1,
          heroIndex: next < state.totalSessions ? next : state.heroIndex,
        ));
      }
    }
    ```

---

### Task 3: Create `CompletionRing` static widget (AC1, AC5)

- [x] CREATE `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart` (NEW)
  - [x] Stateless widget: `CompletionRing({required int completed, required int total, Key? key})`
  - [x] Layout: `SizedBox(width: 48, height: 48, child: CustomPaint(painter: _RingPainter(...), child: Center(child: Text('$completed/$total', style: JetBrains Mono 11sp))))`
  - [x] `_RingPainter` extends `CustomPainter`:
    - Background arc: full circle, strokeWidth 4dp, color `theme.onSurfaceVariant.withOpacity(0.2)`
    - Foreground arc: proportional to `completed/total`, color `theme.primaryColor`
    - Both arcs drawn via `canvas.drawArc`, `Paint()..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round`
    - If `total == 0`: render only background arc (no foreground)
  - [x] `Semantics(label: 'Progressione giornaliera: $completed di $total sessioni completate', child: ...)`
  - [x] **NO animation** — Story 7.4 adds the pulse animation. This is the static variant.
  - [x] Font for center text: `TextStyle(fontFamily: 'JetBrains Mono', fontSize: 11, fontWeight: FontWeight.w500)`
  - [x] Use `Theme.of(context).extension<PulseCoachTheme>()!` for colors — same assert pattern as `StateIndicator`

---

### Task 4: Create `CompletedSessionCard` widget (AC3, AC4)

- [x] CREATE `pulse_coach/lib/features/today/presentation/widgets/completed_session_card.dart` (NEW)
  - [x] Widget signature: `CompletedSessionCard({required PlannedSession session, Key? key})`
  - [x] Layout: `Semantics(label: 'Completata: $displayName, $durationLabel.', excludeSemantics: false, child: Container(...))`
    - Container: `BoxDecoration(color: theme.surfaceContainer.withOpacity(0.6), borderRadius: BorderRadius.circular(16))`
    - `Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(...))`
    - Row children:
      1. `Icon(Icons.check_circle_outline, size: 24, color: theme.primaryColor)`
      2. `SizedBox(width: 12)`
      3. `Expanded(child: Text(displayName, style: bodyMedium.copyWith(color: theme.onSurfaceVariant), overflow: TextOverflow.ellipsis))`
      4. `Text(durationLabel, style: bodySmall.copyWith(color: theme.onSurfaceVariant))`
  - [x] Uses `sessionDisplayName()` and `sessionIcon()` from `session_card_helpers.dart` — import that file
  - [x] **Non-interactive**: no `InkWell`, no `GestureDetector` — completed sessions are informational only
  - [x] Opacity 0.6 is applied to the Container's background color (not the whole widget), keeping text readable
  - [x] No `@injectable` — pure stateless widget

---

### Task 5: Create `ShimmerPlaceholder` shared widget (AC5)

- [x] CREATE `pulse_coach/lib/shared/widgets/shimmer_placeholder.dart` (NEW)
  - [x] Widget: `ShimmerPlaceholder({required double height, double? width, double borderRadius = 8, Key? key})`
  - [x] Uses `shimmer` package (already in pubspec at `^3.0.0`): `import 'package:shimmer/shimmer.dart';`
  - [x] Implementation:
    ```dart
    Shimmer.fromColors(
      baseColor: theme.surfaceContainer,
      highlightColor: theme.onSurfaceVariant.withOpacity(0.1),
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: theme.surfaceContainer,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    )
    ```
  - [x] Get `theme` via `Theme.of(context).extension<PulseCoachTheme>()!`

---

### Task 6: Update `HeroSessionCard` and `CompactSessionCard` with `heroTag` parameter (Story 7.2 deferred item)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
  - [x] Add optional parameter `String? heroTag` to constructor
  - [x] Wrap the session icon `Icon(icon, size: 32, color: accentColor)` conditionally:
    ```dart
    heroTag != null
        ? Hero(tag: heroTag!, child: Icon(icon, size: 32, color: accentColor))
        : Icon(icon, size: 32, color: accentColor)
    ```
  - [x] Existing tests remain green (heroTag defaults to null → no Hero widget added)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`
  - [x] Add optional parameter `String? heroTag` to constructor
  - [x] Same conditional Hero wrapping on the icon (`Icon(icon, size: 24, color: accentColor)`)

---

### Task 7: Implement real `TodayPage` (AC1–AC6)

- [x] UPDATE `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
  - [x] Replace the one-line placeholder with the full layout below
  - [x] `TodayPage` remains a `StatelessWidget` — state is in `DailyPlanBloc` + `TodaySessionCubit`
  - [x] **Import list** (all package-relative):
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
    import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
    import 'package:pulse_coach/features/daily_plan/domain/entities/daily_plan.dart';
    import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
    import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
    import 'package:pulse_coach/features/today/presentation/widgets/completed_session_card.dart';
    import 'package:pulse_coach/features/today/presentation/widgets/compact_session_card.dart';
    import 'package:pulse_coach/features/today/presentation/widgets/completion_ring.dart';
    import 'package:pulse_coach/features/today/presentation/widgets/hero_session_card.dart';
    import 'package:pulse_coach/features/today/presentation/widgets/session_card_helpers.dart';
    import 'package:pulse_coach/features/today/presentation/widgets/state_indicator.dart';
    import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';
    ```
  - [x] `build` method — outer `BlocConsumer<DailyPlanBloc, DailyPlanState>`:
    - `listener`: when state is `DailyPlanLoaded`, call `context.read<TodaySessionCubit>().planLoaded(state.plan.sessions.length)`
    - `builder`: pattern-match on state:
      - `DailyPlanInitial` / `DailyPlanLoading` → `_buildShimmer(context)`
      - `DailyPlanLoaded` → `BlocBuilder<TodaySessionCubit, TodaySessionState>` → `_buildLoaded(context, state, sessionState)`
      - `DailyPlanError` → `_buildError(context, state)`
  - [x] `_buildShimmer(context)` → `Padding(padding: EdgeInsets.all(16), child: Column(children: [ShimmerPlaceholder(height: 80), SizedBox(height: 16), ShimmerPlaceholder(height: 180), SizedBox(height: 16), ShimmerPlaceholder(height: 56), SizedBox(height: 8), ShimmerPlaceholder(height: 56)]))`
  - [x] `_buildLoaded(context, DailyPlanLoaded loaded, TodaySessionState sessionState)`:
    - Compute layout (see Dev Notes for full algorithm)
    - Return `SingleChildScrollView` → `Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...]))`
    - Items in order:
      1. **State bar**: `Row(children: [Expanded(child: StateIndicator(state: loaded.behavioralState)), SizedBox(width: 12), CompletionRing(completed: sessionState.completedCount, total: sessionState.totalSessions)])`
      2. `SizedBox(height: 16)`
      3. **CompletedSession cards** (for sessions before `heroIndex`): each session at index < `sessionState.heroIndex` that is within `completedCount` → `CompletedSessionCard(session: session)`
      4. **Hero card** OR **All done** state (see AC4)
      5. `SizedBox(height: 16)` (if upcoming sessions exist)
      6. **COMING UP section** (if upcoming sessions exist): label + `CompactSessionCard` list
  - [x] Hero card: `HeroSessionCard(session: sessions[sessionState.heroIndex], heroTag: 'session-hero-${sessions[sessionState.heroIndex].sessionType}', onStart: () => context.read<TodaySessionCubit>().markSessionCompleted())`
    - Note: `onStart` calls `markSessionCompleted()` for now. Epic 8 replaces this with navigation to InSession.
  - [x] **All done state** (when `sessionState.completedCount >= sessionState.totalSessions && sessionState.totalSessions > 0`):
    ```dart
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 64, color: theme.primaryColor),
        SizedBox(height: 16),
        Text('Ottimo lavoro!', style: AppTextStyles.h2),
        SizedBox(height: 8),
        Text('Tutte le sessioni completate per oggi.', style: AppTextStyles.bodySmall.copyWith(color: theme.onSurfaceVariant), textAlign: TextAlign.center),
      ],
    )
    ```
  - [x] **COMING UP section**: upcoming sessions are sessions at index `> sessionState.heroIndex` (not yet completed). For each, render `CompactSessionCard(session: sessions[i], heroTag: 'session-compact-${sessions[i].sessionType}-$i', onTap: () => context.read<TodaySessionCubit>().swapHero(i))`
  - [x] `_buildError(context, DailyPlanError error)` → minimal error display: `Center(child: Column(children: [Icon(Icons.warning_amber_outlined, size: 48, color: theme.tertiary), SizedBox(height: 8), Text('Impossibile caricare il piano.', style: bodySmall)]))`
  - [x] Use `AnimatedSwitcher(duration: Duration(milliseconds: 300), child: ...)` to wrap the hero zone for smooth swap transition — see Dev Notes

---

### Task 8: Update `app_router.dart` to provide BLoC + Cubit (AC1–AC6)

- [x] UPDATE `pulse_coach/lib/core/routing/app_router.dart`
  - [x] Add imports:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/core/di/injection.dart';
    import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
    import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
    ```
  - [x] Change Today route builder from:
    ```dart
    GoRoute(
      path: today,
      builder: (context, state) => const TodayPage(),
    ),
    ```
    to:
    ```dart
    GoRoute(
      path: today,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<DailyPlanBloc>()..add(DailyPlanGenerateRequested()),
          ),
          BlocProvider(create: (_) => TodaySessionCubit()),
        ],
        child: const TodayPage(),
      ),
    ),
    ```
  - [x] `TodaySessionCubit` is not `@injectable` — created with `TodaySessionCubit()` directly (no `getIt`)

---

### Task 9: Write widget and page tests (AC1–AC6)

- [x] CREATE `pulse_coach/test/widget/today_page_test.dart` (NEW)
  - [x] See Dev Notes for full test specs (7.3-PAGE-001 through 7.3-PAGE-010)

- [x] CREATE `pulse_coach/test/widget/completed_session_card_test.dart` (NEW)
  - [x] See Dev Notes for full test specs (7.3-COMPLETED-001 through 7.3-COMPLETED-005)

- [x] UPDATE `pulse_coach/test/bloc/daily_plan_bloc_test.dart`
  - [x] Existing tests call `DailyPlanState.loaded(plan: plan)` — these continue to compile because `behavioralState` has a default value
  - [x] Add one test asserting that `DailyPlanState.loaded(plan: plan)` defaults to `BehavioralState.active`
  - [x] Update any mock setup that requires `AppDatabase` injection in the bloc

---

### Task 10: Gate verification

- [x] `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` — required after freezed changes
- [x] `flutter test` from `pulse_coach/` — must pass (target ≈ 472 + ~18 new = ~490)
- [x] `flutter analyze` from `pulse_coach/` — must show **0 issues**

---

## Dev Notes

---

### What This Story Is

Story 7.3 wires `DailyPlanBloc` into `TodayPage` and implements the full Today screen layout: state bar, hero card, upcoming list, completion state, shimmer loading, and the in-page hero swap interaction.

**Do NOT:**
- Navigate anywhere when "Inizia sessione" is tapped — Epic 8 replaces the stub `onStart` callback with real navigation to `AppRouter.sessionActive`
- Build the animated `CompletionRing` pulse — this is Story 7.4's scope (add the static version only)
- Build the "Regenerate" button — this is Story 7.4's scope (wires `DailyPlanRegenerateRequested`)
- Build `today_page_tablet.dart` — this is Story 11.2's scope (responsive layout)
- Use `CircularProgressIndicator` anywhere on this page
- Call `getIt<DailyPlanBloc>()` inside `TodayPage.build` — the bloc is provided at the router level

---

### `DailyPlanBloc` Changes Required

**Current `DailyPlanState.loaded`:**
```dart
const factory DailyPlanState.loaded({required DailyPlan plan}) = DailyPlanLoaded;
```

**New `DailyPlanState.loaded` (add behavioralState with default):**
```dart
const factory DailyPlanState.loaded({
  required DailyPlan plan,
  @Default(BehavioralState.active) BehavioralState behavioralState,
}) = DailyPlanLoaded;
```

**Why the default matters:** Existing tests call `DailyPlanState.loaded(plan: plan)` — the `@Default` annotation makes `behavioralState` optional, so they continue to compile and pass without modification.

**`DailyPlanBloc` constructor update** (add `AppDatabase _db`):
```dart
@injectable
class DailyPlanBloc extends Bloc<DailyPlanEvent, DailyPlanState> {
  final GenerateDailyPlan _generateDailyPlan;
  final RegenerateDailyPlan _regenerateDailyPlan;
  final AppDatabase _db;   // ← ADD THIS

  DailyPlanBloc(this._generateDailyPlan, this._regenerateDailyPlan, this._db)
      : super(const DailyPlanState.initial()) { ... }
```

`AppDatabase` is already a singleton in `get_it` (registered first in the DI chain), so injectable will inject it automatically.

**`_parseState` helper — copy from `GenerateDailyPlan`:**
```dart
BehavioralState _parseState(String? stateStr) {
  return switch (stateStr?.toLowerCase()) {
    'recovering' => BehavioralState.recovering,
    'atrisk'     => BehavioralState.atRisk,
    'fatigued'   => BehavioralState.fatigued,
    _            => BehavioralState.active,
  };
}
```

**Updated `_onGenerateRequested` success branch:**
```dart
result.fold(
  (failure) => emit(DailyPlanState.error(failure: failure, retryAttempts: retryAttempts)),
  (plan) async {
    final stateRow = await _db.behavioralStateDao.getLatestState();
    emit(DailyPlanState.loaded(
      plan: plan,
      behavioralState: _parseState(stateRow?.currentState),
    ));
  },
);
```

Apply the same pattern to `_onRegenerateRequested`.

**Build runner:** After modifying the freezed class, run:
```
dart run build_runner build --delete-conflicting-outputs
```
from `pulse_coach/`. This regenerates `daily_plan_bloc.freezed.dart`.

---

### TodayPage Layout Algorithm

Given `DailyPlanLoaded` with sessions list `S` (length N) and `TodaySessionState` with `heroIndex = H`, `completedCount = C`:

```
completedSessions = S[0..C-1]         (all sessions before the current hero that are done)
heroSession = S[H]                     (current hero, at index H)
upcomingSessions = S[H+1..N-1]        (sessions after the hero, not yet done)

Display order (top to bottom):
  1. State bar (StateIndicator + CompletionRing(completed=C, total=N))
  2. For each s in completedSessions: CompletedSessionCard(session=s)
  3. if C >= N && N > 0:
       All-done state (no hero card)
     else:
       HeroSessionCard(session=heroSession, heroTag='session-hero-${heroSession.sessionType}', onStart=markSessionCompleted)
  4. if upcomingSessions.isNotEmpty:
       COMING UP header
       for i,s in upcomingSessions: CompactSessionCard(session=s, heroTag='session-compact-${s.sessionType}-${H+1+i}', onTap=swapHero(H+1+i))
```

**In-page swap animation:** Wrap the hero zone (step 3) in `AnimatedSwitcher`:
```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 300),
  child: completedAll
      ? _AllDoneWidget(key: const ValueKey('all-done'))
      : HeroSessionCard(
          key: ValueKey('hero-${heroSession.sessionType}-$H'),
          session: heroSession,
          heroTag: 'session-hero-${heroSession.sessionType}',
          onStart: () => context.read<TodaySessionCubit>().markSessionCompleted(),
        ),
)
```

The `ValueKey` on `HeroSessionCard` is critical — `AnimatedSwitcher` needs a unique key change to trigger the animation when the hero changes.

**Why `SingleChildScrollView`:** The layout should be scrollable to support phones with very small screens or unusual aspect ratios (NFR24). The requirement "all visible without scrolling" applies to standard phones (>600dp height) — the layout is designed to fit above the fold on standard sizes.

---

### `AppTextStyles.h2` Usage

`StateIndicator` uses `AppTextStyles.h3`. The "All done" state uses `AppTextStyles.h2`. Import from:
```dart
import 'package:pulse_coach/core/theme/app_text_styles.dart';
```

Check `app_text_styles.dart` for the exact h2 definition before using — it should be Plus Jakarta Sans SemiBold 20sp (same as used in `HeroSessionCard`).

---

### `CompletionRing` CustomPainter Details

```dart
class _RingPainter extends CustomPainter {
  final int completed;
  final int total;
  final Color trackColor;
  final Color progressColor;

  const _RingPainter({
    required this.completed,
    required this.total,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 4) / 2;  // 4 = strokeWidth
    const startAngle = -math.pi / 2;       // start at top

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (total > 0 && completed > 0) {
      final sweepAngle = 2 * math.pi * (completed / total);
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.completed != completed || old.total != total;
}
```

Add `import 'dart:math' as math;` at the top of `completion_ring.dart`.

---

### Hero Animation Tags — Purpose

The `heroTag` parameter added to `HeroSessionCard` and `CompactSessionCard` in Task 6 is **for future navigation Hero transitions** (Today → InSession in Epic 8), NOT for the in-page swap. The in-page swap uses `AnimatedSwitcher` (Task 7).

When Epic 8 wires InSession navigation:
```dart
// In TodayPage's onStart callback (Epic 8 replaces the stub):
context.go(AppRouter.sessionActive, extra: {'heroTag': 'session-hero-${session.sessionType}'});
```
The InSessionView then uses the same `heroTag` in its `Hero` widget to produce the page-to-page animation.

---

### Widget Test Specifications

#### `today_page_test.dart`

Setup helper:
```dart
Widget _wrap({required DailyPlanState planState, TodaySessionState? sessionState}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider<DailyPlanBloc>(
            create: (_) => MockDailyPlanBloc()..mockState(planState),
          ),
          BlocProvider<TodaySessionCubit>(
            create: (_) => TodaySessionCubit()
              ..planLoaded(sessionState?.totalSessions ?? 0),
          ),
        ],
        child: const TodayPage(),
      ),
    ),
  );
}
```

Use `bloc_test` / `MockBloc` pattern per project convention. For `DailyPlanBloc`, use `mockito` `@GenerateMocks([DailyPlanBloc])`.

| ID | Description |
|---|---|
| 7.3-PAGE-001 | Loading state: `ShimmerPlaceholder` visible, no `HeroSessionCard` |
| 7.3-PAGE-002 | Loaded state (1 session): `HeroSessionCard` visible, no COMING UP section |
| 7.3-PAGE-003 | Loaded state (3 sessions): `HeroSessionCard` + COMING UP label + 2 `CompactSessionCard`s |
| 7.3-PAGE-004 | `StateIndicator` visible in state bar when plan is loaded |
| 7.3-PAGE-005 | `CompletionRing` visible in state bar when plan is loaded |
| 7.3-PAGE-006 | `CircularProgressIndicator` is never present (check `findsNothing`) |
| 7.3-PAGE-007 | All done (completedCount=3, total=3): no `HeroSessionCard`, "Ottimo lavoro!" text visible |
| 7.3-PAGE-008 | Error state: warning icon visible, no crash |
| 7.3-PAGE-009 | Initial state: shimmer visible (same as loading) |
| 7.3-PAGE-010 | Tap CompactSessionCard: `swapHero` updates heroIndex (verify second session becomes hero) |

#### `completed_session_card_test.dart`

```dart
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme,
  home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
);
```

| ID | Description |
|---|---|
| 7.3-COMPLETED-001 | Displays session display name (e.g., "Mobilità" for 'mobility') |
| 7.3-COMPLETED-002 | Displays duration label (e.g., "5 min") |
| 7.3-COMPLETED-003 | Shows `Icons.check_circle_outline` |
| 7.3-COMPLETED-004 | No `InkWell` or `FilledButton` — non-interactive |
| 7.3-COMPLETED-005 | No AI explanation text visible |

---

### Test Count Accounting

| Source | Count |
|---|---|
| Baseline (post Story 7.2) | 472 |
| `today_page_test.dart` (PAGE-001..010) | +10 |
| `completed_session_card_test.dart` (COMPLETED-001..005) | +5 |
| `daily_plan_bloc_test.dart` update (1 new test) | +1 |
| Completion ring CustomPainter tests (optional) | +2 |
| **Estimated target** | **~490** |

---

### `flutter analyze` Zero-Tolerance Rules

- `TodaySessionCubit` must NOT use `@injectable` — do not add the annotation (causes DI registration issues for page-scoped state)
- All switch statements on enums must be exhaustive — `BehavioralState` has 4 values; handle all 4 in every switch
- `math.pi` requires `import 'dart:math' as math;` in `completion_ring.dart`
- All imports: package-relative (`package:pulse_coach/...`), never relative (`../`)
- `withOpacity` vs `withValues`: use `.withValues(alpha: x)` for `Color` (project uses modern non-deprecated API — see `state_indicator.dart:97`)

---

### Build Runner Must Run

**Required** for this story because `DailyPlanState.loaded` is a freezed sealed class. After modifying the factory constructor in `daily_plan_bloc.dart`:
1. `dart run build_runner build --delete-conflicting-outputs`
2. Verify `daily_plan_bloc.freezed.dart` is updated (it will have the new `behavioralState` field)
3. Commit generated file alongside source change

---

### Files to Create / Modify

**New files:**
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`
- `pulse_coach/lib/features/today/presentation/widgets/completed_session_card.dart`
- `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart`
- `pulse_coach/lib/shared/widgets/shimmer_placeholder.dart`
- `pulse_coach/test/widget/today_page_test.dart`
- `pulse_coach/test/widget/completed_session_card_test.dart`

**Updated files:**
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart` (add `behavioralState` to loaded state + read from DB)
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.freezed.dart` (regenerated — DO NOT hand-edit)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (placeholder → full layout)
- `pulse_coach/lib/core/routing/app_router.dart` (Today route wrapped with MultiBlocProvider)
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart` (add `heroTag` param)
- `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart` (add `heroTag` param)
- `pulse_coach/test/bloc/daily_plan_bloc_test.dart` (add 1 test for default behavioralState)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` (status: backlog → ready-for-dev)

---

### References

- `DailyPlanBloc` current implementation: [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`]
- `DailyPlanState` sealed class (to be updated): [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:14-23`]
- `DailyPlan` entity: [`pulse_coach/lib/features/daily_plan/domain/entities/daily_plan.dart`]
- `PlannedSession` entity: [`pulse_coach/lib/features/daily_plan/domain/entities/planned_session.dart`]
- `BehavioralState` enum: [`pulse_coach/lib/ai/state_machine/behavioral_state.dart`]
- `BehavioralStateDao.getLatestState()`: [`pulse_coach/lib/core/database/daos/behavioral_state_dao.dart`]
- `BehavioralStateData.currentState` string values (`'Active'|'Recovering'|'AtRisk'|'Fatigued'`): [`pulse_coach/lib/core/database/tables/behavioral_state_table.dart`]
- `_parseState` pattern (for string → BehavioralState conversion): [`pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:330-338`]
- `StateIndicator` widget (pattern for PulseCoachTheme + AppTextStyles usage): [`pulse_coach/lib/features/today/presentation/widgets/state_indicator.dart`]
- `HeroSessionCard` (to be updated with heroTag): [`pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`]
- `CompactSessionCard` (to be updated with heroTag): [`pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`]
- `session_card_helpers.dart` (sessionDisplayName, sessionIcon): [`pulse_coach/lib/features/today/presentation/widgets/session_card_helpers.dart`]
- `AppTextStyles` token definitions: [`pulse_coach/lib/core/theme/app_text_styles.dart`]
- `PulseCoachTheme` tokens (primaryColor, secondary, tertiary, onSurfaceVariant, surfaceContainer): [`pulse_coach/lib/core/theme/pulse_coach_theme.dart`]
- `AppTheme.darkTheme` (used in widget test `_wrap`): [`pulse_coach/lib/core/theme/app_theme.dart`]
- `AppRouter.today` route (to be updated): [`pulse_coach/lib/core/routing/app_router.dart:47-50`]
- Architecture directory spec (completion_ring.dart, completed_session_card.dart locations): [`_bmad-output/planning-artifacts/architecture.md:671-676`]
- Architecture shimmer_placeholder.dart location: [`_bmad-output/planning-artifacts/architecture.md:817`]
- UX wireframe (Today screen layout top-to-bottom): [`_bmad-output/planning-artifacts/ux-design-specification.md:692-722`]
- UX Hero card progression table: [`_bmad-output/planning-artifacts/ux-design-specification.md:807`]
- Epic 7 Story 7.3 AC source: [`_bmad-output/planning-artifacts/epics.md:1133-1165`]
- Story 7.2 (SessionCard components, review findings, heroTag deferral): [`_bmad-output/implementation-artifacts/7-2-sessioncard-component.md`]
- `shimmer` package already in pubspec at `^3.0.0`: [`pulse_coach/pubspec.yaml:45`]
- `AppDatabase` DI singleton (for injecting into DailyPlanBloc): [`pulse_coach/lib/core/database/app_database.dart`]
- Existing `daily_plan_bloc_test.dart` (to update with 1 new test): [`pulse_coach/test/bloc/daily_plan_bloc_test.dart`]
- `DailyPlanGenerateRequested` event: [`pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_event.dart`]

---

### Story 7.2 Deferred Items Resolved by This Story

From Story 7.2 code review:
- **Hero body tap area / Semantics**: Story 7.3 adds `onStart` callback from the parent — if needed, refine Semantics `button: true` only when onStart is non-null (already done in 7.2 patches)
- **Hero onStart double-tap guard**: Story 7.3 `onStart` is `markSessionCompleted()` which is idempotent (completedCount is bounded by totalSessions); no debouncing needed for now. Epic 8 can add navigation-level guard.
- **Hero animation tags**: resolved in Task 6 above.

---

## Dev Agent Record

### Agent Model Used

GPT-5 Codex

### Debug Log References

- `dart run build_runner build --delete-conflicting-outputs` (pass; build_runner warns the option is ignored by current version)
- `flutter test test/bloc/daily_plan_bloc_test.dart` (pass)
- `flutter test test/widget/completed_session_card_test.dart test/widget/today_page_test.dart test/widget/session_card_test.dart test/bloc/daily_plan_bloc_test.dart` (pass)
- `flutter test test/widget/app_shell_test.dart test/widget/pages_smoke_test.dart test/core/routing/app_router_test.dart` (pass after updating legacy tests for TodayPage providers)
- `flutter analyze` (pass, 0 issues)
- `flutter test` (pass, 490 tests)

### Completion Notes List

- Task 1 complete: `DailyPlanState.loaded` now carries `BehavioralState`, `DailyPlanBloc` reads the latest persisted behavioral state on generate/regenerate success, and BLoC tests cover the default plus DAO-backed emission.
- Implemented the real Today screen layout with state bar, static completion ring, hero card progression, completed cards, coming-up list, shimmer loading, error state, all-done state, and in-page compact-card hero swaps.
- Wired `/today` through route-level `DailyPlanBloc` and `TodaySessionCubit` providers; no service-locator access is performed inside `TodayPage`.
- Added widget coverage for TodayPage and CompletedSessionCard and updated legacy shell/router smoke tests to mount TodayPage with its required providers.

### File List

- `_bmad-output/implementation-artifacts/7-3-today-screen-layout-and-hero-progression.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/core/routing/app_router.dart`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart`
- `pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.freezed.dart`
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
- `pulse_coach/lib/features/today/presentation/widgets/compact_session_card.dart`
- `pulse_coach/lib/features/today/presentation/widgets/completed_session_card.dart`
- `pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart`
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
- `pulse_coach/lib/shared/widgets/shimmer_placeholder.dart`
- `pulse_coach/test/bloc/daily_plan_bloc_test.dart`
- `pulse_coach/test/core/routing/app_router_test.dart`
- `pulse_coach/test/widget/app_shell_test.dart`
- `pulse_coach/test/widget/completed_session_card_test.dart`
- `pulse_coach/test/widget/pages_smoke_test.dart`
- `pulse_coach/test/widget/today_page_test.dart`
- `pulse_coach/test/widget/today_page_test.mocks.dart`

### Change Log

- 2026-05-15: Implemented Story 7.3 Today screen layout, route wiring, static progress/completed/shimmer widgets, hero swapping, tests, and validation gates.
- 2026-05-15: Code review run (bmad-code-review) — 14 findings recorded (3 decision-needed, 8 patch, 3 defer). Decisions resolved, patches applied (1 dismissed as false positive), 3 items deferred. `flutter test` 492 pass, `flutter analyze` 0 issues. Status: review → done.

### Review Findings

- [x] [Review][Decision] Positional `completedSessions = sessions.take(completedCount)` mismatches reality after `swapHero` — after the user swaps hero to index 2 then presses Start, `completedCount=1` and `sessions[0]` is shown as "completed" even though it was never run; the session actually completed (index 2) disappears from the UI. The spec algorithm itself is positional. Decision needed: track completed by identity (Set of session indices/IDs) or restrict `swapHero` so only the next-in-sequence can become hero. [`pulse_coach/lib/features/today/presentation/pages/today_page.dart:414`, `today_session_cubit.dart:39-52`]
- [x] [Review][Decision] `markSessionCompleted` orphans skipped sessions — same root as above: after `swapHero(2)` + `markSessionCompleted`, sessions 0 and 1 are neither completed nor reachable as hero/upcoming. Tied to the previous decision on completion-tracking semantics. [`today_session_cubit.dart:45-50`]
- [x] [Review][Decision] `CompletionRing` renders `0/0` and semantic label "Progressione giornaliera: 0 di 0 sessioni" on empty plan; the hero zone collapses to a blank screen. No UX defined for empty/no-session plans. Decision needed: hide ring + show "No sessions today" copy, or treat zero-session plan as an error state. [`completion_ring.dart` + `today_page.dart` empty-plan branch]
- [x] [Review][Patch] `emit` after `await _db.behavioralStateDao.getLatestState()` without `isClosed` guard — risk of `StateError` if BLoC is closed during the async DAO read. Add `if (isClosed) return;` (or `if (emit.isDone) return;`) in both `_onGenerateRequested` and `_onRegenerateRequested` success branches. [`daily_plan_bloc.dart:174-188`, `:201-214`]
- [x] [Review][Patch] Hero tag collision when two sessions share `sessionType` — during the 300 ms AnimatedSwitcher cross-fade the previous and the next `HeroSessionCard` are both mounted; if both have the same `sessionType` they collide on `'session-hero-${sessionType}'` and Flutter throws "multiple heroes share the same tag". Include the index in the hero tag (`'session-hero-${sessionType}-$heroIndex'`) — consistent with the CompactSessionCard scheme. [`today_page.dart:537-538`]
- [x] [Review][Patch] `BlocConsumer.listener` wipes `TodaySessionCubit` on every `Loaded→Loaded` — any `DailyPlanLoaded` re-emission (different `behavioralState`, regenerate, etc.) resets `completedCount`/`heroIndex` to 0. Guard `planLoaded` so it only fires when `plan` identity changes (e.g., compare `plan.generatedAt` or use a `previous` parameter in the listener). [`today_page.dart:363-368`]
- [x] [Review][Patch] `app_router_test.dart` registers `DailyPlanBloc` factory without unregistering in `tearDown` — under get_it 9 the next registration throws. Add `if (getIt.isRegistered<DailyPlanBloc>()) getIt.unregister<DailyPlanBloc>();` in setUp, or unregister in `tearDown`. [`test/core/routing/app_router_test.dart:781-786`]
- [x] [Review][Patch] `_parseState` silently coerces unknown DB strings to `BehavioralState.active` — future enum variants or migration leftovers downgrade silently. Log a warning (or assert in debug) when the DAO returns a non-null, non-matching string. [`daily_plan_bloc.dart:118-126`]
- [x] [Review][Patch] `swapHero` accepts negative/out-of-range indices — public API unsafe. Validate `0 <= tappedSessionIndex < state.totalSessions` and ignore otherwise. [`today_session_cubit.dart:36-37`]
- [x] [Review][Patch] Test coverage gap: `'AtRisk'` never exercised through `_parseState` — only `'Fatigued'` is tested. Add a BLoC test that stubs the DAO to return `'AtRisk'` and asserts `BehavioralState.atRisk` is emitted. [`test/bloc/daily_plan_bloc_test.dart`]
- [x] [Review][Patch] No dedicated test for AC3 (Session 1 completed → Session 2 becomes hero, Session 3 in COMING UP) — PAGE-007 covers all-done and PAGE-010 covers manual swap, but the natural mark-complete progression is not asserted. Add `7.3-PAGE-011`. [`test/widget/today_page_test.dart`]
- [x] [Review][Defer] `heroTag` wraps only the icon; in-page swap uses AnimatedSwitcher (not Hero flight) — the `Hero` indirection is scaffolding for Epic 8 navigation and is also the proximate cause of finding #5. Keep, but revisit when Epic 8 wires the route push. — deferred, scaffolding for Epic 8 [`hero_session_card.dart`, `compact_session_card.dart`]
- [x] [Review][Defer] AC2 "above the fold on a standard phone" not verified by any test — no golden / viewport test infra in the project. Add when golden-test infra is introduced. — deferred, missing test infra
- [x] [Review][Defer] Italian UI copy hard-coded across `today_page.dart`, `completion_ring.dart`, `completed_session_card.dart`; "COMING UP" remains English. No i18n hook. — deferred, project-wide i18n decision pending
