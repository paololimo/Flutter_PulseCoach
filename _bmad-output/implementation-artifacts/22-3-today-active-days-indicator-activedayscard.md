---
baseline_commit: 239b33f2a37707eba4b1076a878a1479b38cf278
---

# Story 22.3: Today Active-Days Indicator (ActiveDaysCard)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user opening Today,
I want a calm record of how active I've recently been,
So that I see gentle continuity without any pressure to protect a streak.

## Context

**Epic 22, third story.** Third story of "Experience Polish (v1)"; no direct code dependency on 22.1 (`MilestoneProgressBar`, in-session screen) or 22.2 (`FactorIconRow`, `HeroSessionCard`), but all three are presentation-layer polish over the existing v1 core, and all three touch the **Today** screen family. This story adds an `ActiveDaysCard` directly below `HeroSessionCard` showing a rolling 30-day count of days with ≥1 completed session — explicitly **not** a consecutive-day streak (no reset-to-zero, no flame glyph, no chain to protect).

### ⚠️ Read this before wiring the count — the epic's "reuse FR23" hint points at dead code

The epic's prerequisite note says: *"the active-days count reads the FR23 activity signal already computed by `BehavioralStateMachine`; do NOT introduce a parallel counter"* (epics.md:2892), and the addendum repeats this as an explicit `[ASSUMPTION]` (`.decision-log.md:85,116`: *"FR23 single-source `[ASSUMPTION]` retained"* — i.e. never confirmed against the actual codebase). Taken literally, this points at `StateVector.streak` / the `Sessions` Drift table (`lib/core/database/tables/sessions_table.dart`) that `GenerateDailyPlan._calculateStreak()` and `UpdateBanditReward` read from. **Do not use either of those.** Two independent problems make this the wrong source:

1. **`streak` is the wrong shape.** `_calculateStreak()` (`lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:369-386`) computes *consecutive* calendar days ending today, breaking to `0` the first day with no completed session. That is **exactly** the reset-to-zero streak mechanic this story's own ACs (AC3) and DESIGN.md's "Streak-counter vs. active-days" section explicitly reject. A windowed 30-day count and a consecutive streak are different computations — you cannot derive one from the other's stored int.
2. **The `Sessions` table is dead in practice.** Grep confirms **no call site anywhere in `lib/` inserts into it** except `backup_local_data_source.dart` (backup/restore round-trip only). Real session completion has gone through the `SessionLogs` table (`lib/core/database/tables/session_logs_table.dart`, Story 8.0) via `SessionLogsDao.upsertCompletion()` since Epic 8 — called from `InSessionCubit._persistCompletion()` (`lib/features/session/presentation/bloc/in_session_cubit.dart:121-153`). `_calculateStreak()`/`update_bandit_reward.dart`'s streak computation read from a table that is **never populated by the live app** — `StateVector.streak` is silently always `0` today. This is a pre-existing latent bug in Epic 5/9's bandit code, **out of scope to fix here** — flagging it only so you don't anchor this story's metric to a signal that doesn't reflect real activity.

**Resolution used by this story (the correct reading of "single source of truth, no parallel counter"):** reuse the **same underlying completed-session data** that already exists and is already the real source of truth for "was a session completed" — `SessionLogsDao` — the same DAO `TodaySessionCubit` and `InSessionCubit` already write through, and the same one Epic 10's `ProgressLocalDataSource.getSessionHistory()` (`lib/features/progress/data/datasources/progress_local_data_source.dart:24-97`) already reads for its own windowed weekly stats. This is not "introducing a parallel counter" — it's reading the one table that actually tracks completions, and computing a *different aggregation* (distinct active calendar days in a 30-day window) than the existing `streak`/`missedSessions` fields compute. If Paolo disagrees with this reading, it's an isolated one-function change (see Task 2).

### What already exists (DO NOT REBUILD)

- **`SessionLogsDao.getAllLogsOrderedByDate()`** (`lib/core/database/daos/session_logs_dao.dart:37-42`) — returns all `SessionLog` rows across all plans (both solo, `dailyPlanId != null`, and shared sessions from Story 21.0, `dailyPlanId == null`), most-recent-first. Already used by `ProgressLocalDataSource.getSessionHistory()` for Epic 10's windowed stats. **Reuse this exact method** — do not write a new DAO query; the dataset is small (personal-use app) and in-Dart filtering is the established pattern (mirrors `ProgressLocalDataSource.getProgressStats()`'s own week-bucketing).
- **`SessionLog.abandoned`** — `bool`, `false` by default. `ProgressLocalDataSource` filters `!entry.abandoned` for "completed" (`progress_local_data_source.dart:114`); `TodaySessionCubit._completedFromLogs` does the same (`!log.abandoned`). Follow the identical convention: an abandoned session does not count as "active" for this card.
- **Local-timezone convention** — `_calculateStreak()` (`generate_daily_plan.dart:378`) calls `s.completedAt!.toLocal()` before bucketing into calendar days; this is the existing precedent for "device-local calendar day" in this codebase. **Note:** `ProgressLocalDataSource` uses `.toUtc()` for its week-bucketing (`progress_local_data_source.dart:167,171,187`) — that is a *different* feature with a different (UTC-week) contract; do **not** copy that convention here. AC2 is explicit: "device-local timezone." Use `.toLocal()`, matching `_calculateStreak`'s existing pattern, not `ProgressLocalDataSource`'s.
- **`TodaySessionCubit`** (`lib/features/today/presentation/cubit/today_session_cubit.dart`) — the correct, existing seam (Story 22.2 added `weatherContext` here the same way; follow that precedent exactly). Add a new `activeDaysCount` field to `TodaySessionState`, computed inside `planLoaded`'s `planId != null` branch, running **concurrently** with the existing `_fetchWeather()` future (same "kick off both futures before awaiting either" pattern already established in Task 4 of Story 22.2). **Do not create a new Cubit** — this project's Bloc/Cubit split rule (project-context.md) reserves new Cubits for genuinely separate UI-only concerns; `TodaySessionCubit` is already the Today-page-scoped state holder and this is one more derived field on it, exactly like `weatherContext` was.
- **The `planId == null` fast-path invariant** — `planLoaded`'s null-`planId` branch must stay synchronous (no `await` before `emit`), per the documented invariant at `today_session_cubit.dart:87-91` and Story 22.2's Dev Notes. **Do not fetch the active-days count in that branch** — same rule Story 22.2 applied to `weatherContext`. `activeDaysCount` simply stays at its default (`0`) in that branch; this is graceful degradation, consistent with how `weatherContext` behaves there too.
- **Live update on completion** — `_onLogsChanged` (`today_session_cubit.dart:133-143`) already fires whenever `SessionLogs` changes for the current plan (via `watchLogsForPlan(planId).skip(1)`). Recompute `activeDaysCount` there too (re-fetch `getAllLogsOrderedByDate()` — cheap, small table) so completing a session updates the card without waiting for the next `planLoaded` round-trip. This mirrors exactly how `completedIndices`/`heroIndex` already refresh live.
- **48dp-safe non-interactive card pattern** — `CompletedSessionCard` (`lib/features/today/presentation/widgets/completed_session_card.dart`) is the closest existing template: `Semantics(label: ..., child: Container(decoration: BoxDecoration(color: pulseTheme.surfaceContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)), child: Padding(...)))`. `ActiveDaysCard` is **not interactive** (AC4: "no animation beyond the standard card reveal", it's a passive readout) — simpler than `FactorIconRow`, no tap-reveal, no `_FactorGlyph`-style stateful widget needed.
- **Single-semantics-node pattern** — `FactorIconRow`'s `_FactorGlyph` (Story 22.2) pairs an outer `Semantics(label: ..., child: ExcludeSemantics(child: <visual row>))` so screen readers get exactly one node reading the composed label rather than each inner `Text` being independently announced. AC5 requires the same here: "exposed as a single semantics node reading its count as text." Use the identical `Semantics(...) > ExcludeSemantics(...)` pairing, not `CompletedSessionCard`'s bare `Semantics(excludeSemantics: false, ...)` (that one still lets the `Icon`/`Text` children merge in as part of the same node's *value*, which is fine there but riskier to reason about for an exact-string semantics assertion here — be explicit with `ExcludeSemantics`).
- **Mono font for the count** — `AppTextStyles` (`lib/core/theme/app_text_styles.dart`) reserves `JetBrains Mono` for "data/metrics only" but has no small-size mono style suited to a compact card count (`rpeNumbers` is 20sp display-weight, `timerSecondary` is 24sp). DESIGN.md just says "Mono count" without a size. Reuse `AppTextStyles.rpeNumbers` (20sp, mono, `height: 1.0`) for the count — it's the closest existing "small mono metric" style and avoids inventing a new `TextStyle` constant for one card. If Paolo wants a distinct size, that's an isolated one-line style change.
- **ARB placement** — new key goes in both `lib/l10n/app/app_it.arb` and `lib/l10n/app/app_en.arb`, following the exact metadata-block shape already used for `heroCardSemanticPreamble` (`app_it.arb:24-33`) and the parameterized-key precedent from Story 22.2's `factorLabelTemperature` (`int` placeholder).

## Acceptance Criteria

**AC1 — `ActiveDaysCard` renders directly below `HeroSessionCard` on Today (phone):**
Given the Today screen renders on a phone-width layout (`< 600dp`)
When the layout is built and a hero session is showing (not the `allDone` state)
Then an `ActiveDaysCard` (small `surface-container`, `rounded/card`) is placed directly below the `_HeroZone`/`HeroSessionCard` and above the "COMING UP" section, showing a Mono count and the caption **"N giorni attivi negli ultimi 30"** (FR81, DESIGN.md ActiveDaysCard, Today vertical rhythm).

**AC2 — Windowed, device-local, non-consecutive count:**
Given the active-days metric
When the count is computed
Then it is the number of **distinct calendar days** (device-local timezone, via `.toLocal()`) within the trailing 30-day rolling window (today + the preceding 29 days) that have **at least one** non-abandoned `SessionLog.completedAt` — **windowed, not consecutive**: a day with no session simply is not in the set; it never zeroes out the count for other days still inside the window (FR81).

**AC3 — Reuses the real completion-tracking source; no parallel counter, no reset messaging:**
Given the source of the activity signal
When the count is derived
Then it reads `SessionLogsDao.getAllLogsOrderedByDate()` — the same table `TodaySessionCubit`/`InSessionCubit`/`ProgressLocalDataSource` already use as the single real source of truth for session completion — rather than the legacy, unpopulated `Sessions` table/`StateVector.streak` (see Context above) (FR81, addendum). The user returning after an absence simply sees a lower value: no "streak lost" message, no reset banner, no flame glyph, no glowing hero number, no progress-to-next chip; a low count renders identically to any other value, without commentary (FR81, EXPERIENCE.md, DESIGN.md Do's and Don'ts).

**AC4 — No bespoke animation; single semantics node; ≥ Caption 11sp:**
Given the card is on screen
When it appears
Then it carries no animation beyond the standard card reveal (excluded from NFR38's animated set), and is exposed as a **single** semantics node (via `Semantics` + `ExcludeSemantics` pairing) reading its count as text **"N giorni attivi negli ultimi 30"** at ≥ Caption 11sp (NFR38, EXPERIENCE.md Accessibility Floor).

**AC5 — Live update on session completion, without a new subscription:**
Given the user completes the hero session while Today is open
When the completion is persisted (`SessionLogsDao.upsertCompletion` fires, already observed by `TodaySessionCubit._onLogsChanged`)
Then the `ActiveDaysCard` count updates to reflect the new completion without requiring the screen to be re-entered (FR81, mirrors the existing `completedIndices` live-update behavior).

**AC6 — Graceful degradation when no plan is loaded:**
Given `planLoaded` is called with `planId == null` (no persisted plan — e.g. fresh-install race or ephemeral preview)
When the state is emitted
Then `activeDaysCount` is **not** fetched in that branch (preserves the documented synchronous no-`await`-before-`emit` invariant on that fast path) and simply renders at its default (`0`) — consistent with how `weatherContext` already degrades in the same branch (Story 22.2).

## Tasks / Subtasks

---

### Task 1 — ARB caption key (AC1, AC4)

- [x] **1.1** Add one new key to both `lib/l10n/app/app_it.arb` and `lib/l10n/app/app_en.arb` (placed near `comingUpHeader`/`allDoneTitle`, following the `heroCardSemanticPreamble` metadata-block shape at `app_it.arb:24-33` for the `@key` block):
  - `activeDaysCaption` — parameterized by an `int` placeholder `count`. IT: `"{count} giorni attivi negli ultimi 30"`. EN: `"{count} active days in the last 30"`. Add the matching `@activeDaysCaption` metadata block with `placeholders: {"count": {"type": "int"}}`.
  - Keep `it`/`en` parity (same key, same placeholder, both files).
- [x] **1.2** Run `flutter gen-l10n` (or `flutter pub get`) so `AppLocalizations` exposes `activeDaysCaption(int count)` — **not** `build_runner` (separate pipeline, per Story 22.1/22.2 precedent).

---

### Task 2 — Windowed active-days computation in `TodaySessionCubit` (AC2, AC3, AC5, AC6)

- [x] **2.1** In `TodaySessionCubit`, add a private helper:
  ```dart
  Future<int> _fetchActiveDaysCount() async {
    final logs = await _sessionLogsDao.getAllLogsOrderedByDate();
    return _countActiveDaysInWindow(logs, _now());
  }

  static int _countActiveDaysInWindow(List<SessionLog> logs, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final windowStart = today.subtract(const Duration(days: 29)); // 30-day window inclusive of today
    final activeDays = <DateTime>{};
    for (final log in logs) {
      if (log.abandoned) continue;
      final local = log.completedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (!day.isBefore(windowStart) && !day.isAfter(today)) {
        activeDays.add(day);
      }
    }
    return activeDays.length;
  }
  ```
  Add a `DateTime Function() _now` constructor field (default `DateTime.now`), mirroring `InSessionCubit`'s existing `DateTime Function() _now` injectable-clock pattern (`in_session_cubit.dart:25,47`) — this is what makes the 30-day window boundary deterministically testable without real-clock flakiness.
- [x] **2.2** Add `int activeDaysCount` to `TodaySessionState` (default `0`), with a plain `??`/direct-value `copyWith` parameter (no sentinel needed — same reasoning Story 22.2 used for `weatherContext`: this is a derived snapshot recomputed wholesale on each fetch, never explicitly reset to a sentinel value).
- [x] **2.3** In `planLoaded(int totalSessions, int? planId)`:
  - `planId == null` branch: **no change** — do not fetch active-days count here (AC6; mirrors the existing `weatherContext` rule from Story 22.2).
  - `planId != null` branch: kick off `final activeDaysFuture = _fetchActiveDaysCount();` alongside the existing `final weatherFuture = _fetchWeather();` (both **before** `await`-ing `_sessionLogsDao.getLogsForPlan(planId)`, so all three run concurrently), then after the existing logs/staleness-guard logic, `final activeDaysCount = await activeDaysFuture;` (plus the same `if (_currentPlanId != planId) return;` staleness re-check already used for `weather`), then include `activeDaysCount: activeDaysCount` in the emitted `TodaySessionState`.
- [x] **2.4** In `_onLogsChanged(int planId, int totalSessions, List<SessionLog> logs)`: after computing `completed`, also `await`-fetch and include an updated `activeDaysCount` in the `emit(state.copyWith(...))` call (AC5) — this method is already `Future<void>`-compatible via its call site (a stream `.listen` callback); if converting it to `async` changes its signature, verify the `.listen(...)` call site still compiles (Dart allows an `async` function as a `void Function(T)` listener callback, so this should be a drop-in change, but confirm with `flutter analyze`).

---

### Task 3 — `ActiveDaysCard` widget (AC1, AC4)

- [x] **3.1** Create `pulse_coach/lib/features/today/presentation/widgets/active_days_card.dart`:
  ```dart
  class ActiveDaysCard extends StatelessWidget {
    final int count;
    const ActiveDaysCard({super.key, required this.count});

    @override
    Widget build(BuildContext context) {
      final pulseTheme = Theme.of(context).extension<PulseCoachTheme>()!;
      final l10n = AppLocalizations.of(context)!;
      final caption = l10n.activeDaysCaption(count);

      return Semantics(
        label: caption,
        child: ExcludeSemantics(
          child: Container(
            decoration: BoxDecoration(
              color: pulseTheme.surfaceContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text('$count', style: AppTextStyles.rpeNumbers.copyWith(color: pulseTheme.onSurfaceVariant)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      caption,
                      style: AppTextStyles.caption.copyWith(color: pulseTheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
  ```
  No `AnimatedSwitcher`, no reduce-motion branch — AC4 explicitly excludes this from NFR38's animated set ("no animation beyond the standard card reveal"), so there is nothing to gate on `MediaQuery.disableAnimationsOf`. Keep the file small (~30-45 lines).
- [x] **3.2** Do not use `Semantics(excludeSemantics: false, ...)` (the `CompletedSessionCard` pattern) — use the explicit `Semantics(label: ...) > ExcludeSemantics(child: ...)` pairing from Story 22.2's `_FactorGlyph`, so the visual `Text` children cannot be independently announced and the tree exposes exactly one semantics node with the exact caption string (AC4's "single semantics node" requirement).

---

### Task 4 — Wire `ActiveDaysCard` into `TodayPage` phone layout (AC1)

- [x] **4.1** In `today_page.dart`'s `_buildLoaded` phone-layout branch (`else` branch starting at `today_page.dart:153`, after the `_HeroZone` `AnimatedSwitcher` block and before the `if (upcomingEntries.isNotEmpty)` "COMING UP" section), insert:
  ```dart
  const SizedBox(height: 16),
  ActiveDaysCard(count: sessionState.activeDaysCount),
  ```
  This places the card directly below the hero and above "COMING UP," matching DESIGN.md's vertical rhythm (`State bar → Hero card → ActiveDaysCard → COMING UP list`).
- [x] **4.2 — explicit scope boundary:** DESIGN.md's vertical-rhythm note is captioned **"Today (phone) vertical rhythm"** specifically. `_TabletTodayLayout`/`_TabletLeftPanel` (`today_page.dart:273-375`) render an entirely different master-detail layout with no equivalent placement specified anywhere in the epic or DESIGN.md. **Do not** add `ActiveDaysCard` to the tablet layout in this story — leave it phone-only, mirroring the exact same scope boundary Story 22.2 drew around `_TabletSessionDetailPanel` (Task 5.4 in that story). If Paolo wants tablet parity, that's a one-line follow-up once a tablet placement is actually specified.
- [x] **4.3 — `allDone` branch:** the card is only inserted in the non-`allDone` branch (where `_HeroZone` renders) — AC1 is scoped to "directly below `HeroSessionCard`," and when `allDone` is true there is no hero card on screen (the `Expanded`/`_AllDoneWidget` takes over the whole remaining space). Do not add the card to the `allDone` branch; this is a deliberate, in-scope reading of AC1's wording, not an oversight.

---

### Task 5 — Tests (AC1–AC6)

- [x] **5.1** Create `test/widget/active_days_card_test.dart` covering, at minimum:
  ```
  [22.3-CARD-001] count=0 → renders without exception, single Semantics node with caption "0 giorni attivi negli ultimi 30" (verify via find.bySemanticsLabel or the SemanticsController — not by asserting on internal Text widgets independently)
  [22.3-CARD-002] count=17 → caption reads "17 giorni attivi negli ultimi 30"; no "reset"/"lost"/flame iconography present (assert find.byIcon(Icons.local_fire_department) or similar finds nothing, guarding the Do's-and-Don'ts constraint)
  [22.3-CARD-003] the rendered subtree exposes exactly one semantics node for the card's content (assert the inner Text widgets are not independently reachable via find.bySemanticsLabel with a partial string)
  ```
  Follow existing widget test conventions (`MaterialApp` + `AppLocalizations` delegates + `AppTheme.darkTheme`, per `test/widget/session_card_test.dart`'s `_wrap()` helper).
- [x] **5.2** Add unit tests for the pure windowing logic in `test/bloc/today_session_cubit_test.dart` (via `TodaySessionCubit`'s public behavior, injecting a fixed `now` — add the `now` param to `buildCubit()`'s construction in that test file):
  ```
  [22.3-CUBIT-001] getAllLogsOrderedByDate returns logs on 3 distinct days within the last 30, all non-abandoned → planLoaded(n, planId) emits activeDaysCount == 3
  [22.3-CUBIT-002] two logs on the SAME calendar day (different times) → counted once, not twice
  [22.3-CUBIT-003] a log exactly 29 days before "now" (device-local) → included in the window; a log 30 days before → excluded (boundary test for the trailing-30-day window)
  [22.3-CUBIT-004] an abandoned log on an otherwise-inactive day → does not count toward activeDaysCount
  [22.3-CUBIT-005] planLoaded(n, null) → getAllLogsOrderedByDate is never called (verifyNever), activeDaysCount stays 0 (AC6, mirrors 22.2-CUBIT-003's pattern for weatherContext)
  [22.3-CUBIT-006] a session completes via a simulated _onLogsChanged trigger (or by exercising markSessionCompleted() with an updated getAllLogsOrderedByDate stub) → the newly emitted state's activeDaysCount reflects the change (AC5)
  ```
  Add `when(sessionLogsDao.getAllLogsOrderedByDate()).thenAnswer((_) async => [...])` stubs per test case in `setUp`/per-test overrides, following the existing `when(sessionLogsDao.getLogsForPlan(any)).thenAnswer(...)` convention already in that file.
- [x] **5.3 — check for `MissingStubError` fallout beyond this file.** `TodaySessionCubit` will now call `_sessionLogsDao.getAllLogsOrderedByDate()` inside `planLoaded`'s non-null-`planId` branch. Story 22.2's equivalent change (adding a new dependency call) required updating 5 other test files that construct `TodaySessionCubit`/mock `SessionLogsDao` directly and exercise a non-null `planLoaded`: `test/core/routing/app_router_test.dart`, `test/offline/offline_core_features_test.dart`, `test/widget/app_shell_test.dart`, `test/widget/pages_smoke_test.dart`, `test/widget/today_page_test.dart`. Constructor **arity doesn't change this time** (no new constructor dependency, just a new DAO method call), but any of those files with an unstubbed `MockSessionLogsDao` will throw `MissingStubError` the first time `planLoaded` is called with a real `planId` post-this-story. Run the full suite and add `when(mockSessionLogsDao.getAllLogsOrderedByDate()).thenAnswer((_) async => [])` (or equivalent fake) to whichever of these files actually fail.
- [x] **5.4** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Result: 0 analyzer issues; **1355 passed, 1 skipped** (baseline 1346/1 + 9 new: 3 widget + 6 cubit), no regressions.

---

## Dev Notes

### Why the "single source of truth" instruction is honored by using `SessionLogsDao`, not `StateVector.streak`

See the "⚠️ Read this before wiring the count" section under Context above — this is the single most important judgment call in this story and is spelled out in full there rather than repeated here. Short version: the epic's hint text points at a signal (`Sessions` table / `streak`) that is dead code in the live app since Epic 8 moved real completion-tracking to `SessionLogs`. Reusing the *actual* completion data (via the DAO every other Today/Progress code path already reads) is the reading that satisfies both "single source of truth" (one real table, not a second one) and the DESIGN.md-mandated windowed/non-resetting behavior (which `streak`'s consecutive-day semantics cannot produce). This divergence is flagged in the PRD's own decision log as an unconfirmed `[ASSUMPTION]` (`.decision-log.md:85,116`), so this is not overriding a locked decision — it's resolving an open one the way the actual codebase requires.

### Why `.toLocal()`, not the Progress feature's `.toUtc()` convention

`ProgressLocalDataSource.getProgressStats()` buckets by UTC week (`_mondayOf`, `progress_local_data_source.dart:186-189`) for its own weekly-minutes chart — a different feature with a different, already-shipped contract nobody asked to change. AC2 here is explicit about "device-local timezone" (this is also the exact language the `review-delta-rubric.md` review flagged as previously missing from the PRD and the 2026-07-06 correct-course closed). `_calculateStreak()`'s existing `.toLocal()` call is the right precedent to follow, not Progress's `.toUtc()`.

### Why this doesn't need a new Cubit

`TodaySessionCubit` already holds derived, ephemeral, Today-page-scoped state (`heroIndex`, `completedIndices`, `weatherContext` as of Story 22.2). `activeDaysCount` is one more field of the same shape (fetched once per plan load, refreshed on live completion). Introducing a second Cubit purely to hold one `int` would violate this codebase's own Bloc/Cubit-split guidance (reserve new Cubits for genuinely separate UI concerns) and would need its own wiring into `TodayPage`'s `BlocBuilder` tree for no benefit.

### File Size Check

- New `active_days_card.dart`: expect ~35-45 lines.
- `today_session_cubit.dart`: current 254 lines (post-22.2) → +~20-25 lines (`_now` field, `_fetchActiveDaysCount`/`_countActiveDaysInWindow` helpers, wiring in `planLoaded`/`_onLogsChanged`, new state field).
- `today_page.dart`: current 561 lines (post-22.2) → +~3 lines (one insertion point in the phone layout).

### Project Structure Notes

**New production files:**
- `pulse_coach/lib/features/today/presentation/widgets/active_days_card.dart`

**Modified production files:**
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` (new `_now` clock field, `activeDaysCount` state field, `_fetchActiveDaysCount`/`_countActiveDaysInWindow`, wiring in `planLoaded` and `_onLogsChanged`)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (insert `ActiveDaysCard` in the phone-layout branch, after `_HeroZone`)
- `pulse_coach/lib/l10n/app/app_it.arb`, `app_en.arb` (1 new `activeDaysCaption` key)

**Auto-regenerated:**
- `.dart_tool/flutter_gen/...` generated `app_localizations*.dart` (via `flutter gen-l10n`/`pub get`, gitignored)

**New/modified test files:**
- `pulse_coach/test/widget/active_days_card_test.dart` (new)
- `pulse_coach/test/bloc/today_session_cubit_test.dart` (extended)
- Possibly `test/core/routing/app_router_test.dart`, `test/offline/offline_core_features_test.dart`, `test/widget/app_shell_test.dart`, `test/widget/pages_smoke_test.dart`, `test/widget/today_page_test.dart` — only if `flutter test` surfaces a `MissingStubError` on `getAllLogsOrderedByDate()` (see Task 5.3).

**Explicitly out of scope for this story:**
- Fixing the pre-existing dead-`Sessions`-table bug in `GenerateDailyPlan._calculateStreak()`/`UpdateBanditReward` (StateVector.streak silently always 0) — flagged for awareness only; a separate deferred item if Paolo wants it fixed.
- Tablet layout placement of `ActiveDaysCard` (DESIGN.md's vertical rhythm is phone-scoped only; see Task 4.2).
- Placing the card in the `allDone` (all-sessions-complete) branch (see Task 4.3).
- Any bespoke reveal/entrance animation beyond the standard card mount (AC4 explicitly excludes this from NFR38's animated set).

### References

- [Source: epics.md#Story 22.3, lines 2963-2989 — full BDD ACs, FR81, DESIGN.md/EXPERIENCE.md cross-refs]
- [Source: epics.md#Epic 22, lines 2885-2893 — epic goal; "Single source of truth (Story 22.3)" prerequisite note]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 184 — Today (phone) vertical rhythm placement]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 216 — full ActiveDaysCard visual/behavior spec]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md lines 128,132,243 — "Streak-counter vs. active-days" brand distinction, Do's and Don'ts]
- [Source: addendum.md lines 32-34 — FR81 mechanism note, windowed-30-day clarification, FR23 single-source note]
- [Source: .decision-log.md lines 69-122 — full FR81 decision history, including the 2026-07-06 correct-course from consecutive-streak to windowed-30-day, and the retained `[ASSUMPTION]` status of the FR23-reuse note]
- [Source: prd.md — FR81 canonical text (windowed, non-consecutive, non-resetting)]
- [Source: lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:281-282,369-386 — `_calculateStreak()`, confirms consecutive/resetting semantics and the `Sessions` table read]
- [Source: lib/core/database/tables/sessions_table.dart, lib/core/database/daos/sessions_dao.dart — the legacy `Sessions` table/DAO; grep-confirmed no live insert call site except backup restore]
- [Source: lib/features/session/presentation/bloc/in_session_cubit.dart:121-153 — `_persistCompletion()`, confirms `SessionLogsDao.upsertCompletion` is the real, live completion-write path]
- [Source: lib/core/database/daos/session_logs_dao.dart:37-42 — `getAllLogsOrderedByDate()`, the method this story reuses]
- [Source: lib/features/progress/data/datasources/progress_local_data_source.dart:24-97,186-189 — existing precedent for windowed aggregation over `SessionLogs`; UTC-week convention explicitly NOT to be copied here]
- [Source: lib/features/today/presentation/cubit/today_session_cubit.dart:53-131 — `TodaySessionCubit`/`TodaySessionState` current shape (post-Story-22.2), `planLoaded`'s null-`planId` synchronous invariant, `_onLogsChanged` live-update wiring, `_fetchWeather`/weatherFuture concurrent-fetch pattern to mirror]
- [Source: lib/features/session/presentation/bloc/in_session_cubit.dart:25,47 — injectable `DateTime Function() _now` clock pattern to mirror for deterministic window-boundary testing]
- [Source: lib/features/today/presentation/widgets/completed_session_card.dart — surface-container/rounded-16/Padding card template]
- [Source: lib/features/today/presentation/widgets/factor_icon_row.dart (Story 22.2) — `Semantics`+`ExcludeSemantics` single-node pairing precedent]
- [Source: lib/core/theme/app_text_styles.dart:18-22,67-72 — `rpeNumbers` (mono, reused for the count) and `caption` (11sp minimum) styles]
- [Source: lib/l10n/app/app_it.arb:19,24-33 — `comingUpHeader`/`heroCardSemanticPreamble` placement and metadata-block shape precedent]
- [Source: lib/features/today/presentation/pages/today_page.dart:82-207 — `_buildLoaded` phone-layout structure, `_HeroZone` insertion point (line ~153-198), `_TabletTodayLayout`/`_TabletLeftPanel` (lines 273-375, explicitly out of scope)]
- [Source: test/bloc/today_session_cubit_test.dart — `@GenerateMocks([SessionLogsDao, GetWeatherContext])` pattern, `buildCubit()`/`setUp` stub conventions to extend]
- [Source: 22-2-decision-factor-iconography-factoriconrow.md — Story 22.2's precedent for extending `TodaySessionCubit` with a new derived field, the 5-test-files `MissingStubError`/arity-fallout pattern, and the `Semantics`/`ExcludeSemantics` pairing this story reuses]
- [Source: review-delta-rubric.md lines 11,19,49 — the PRD delta review's own flag that FR81's streak/timezone/reset semantics needed exactly the clarification this story's AC2/AC3 now encode]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

None — no blocking issues encountered. `flutter analyze` was clean on first pass after implementation; `flutter test` passed on first full run after wiring.

### Completion Notes List

- Followed ATDD (red-green): wrote `test/widget/active_days_card_test.dart` and the 6 new `today_session_cubit_test.dart` cases first (confirmed failing to compile/run), then implemented `ActiveDaysCard` and the `TodaySessionCubit` wiring to make them pass.
- `_countActiveDaysInWindow` computes the windowed, device-local, non-consecutive count exactly per the Dev Notes spec (`.toLocal()`, 30-day inclusive window, abandoned logs excluded).
- `_onLogsChanged` was converted to `async Future<void>` to re-fetch `activeDaysCount` on every live `SessionLogs` change (AC5); the existing `.listen(...)` call site compiled unchanged, confirming the story's prediction that this is a drop-in signature change.
- Task 5.3 fallout check: of the 5 files flagged in the story as needing review, only `test/offline/offline_core_features_test.dart`'s `_ThrowingTodaySessionLogsDao` (a `Fake` exercising `planLoaded` with a non-null `planId`) required a new `getAllLogsOrderedByDate()` override; the other 4 files only ever call `planLoaded` with `planId == null` or use a real in-memory `AppDatabase`, so no `MissingStubError` risk existed there.
- Final verification: `flutter analyze lib/ test/` → 0 issues. `flutter test` → 1355 passed, 1 skipped (baseline 1346/1 + 9 new: 3 `active_days_card_test.dart` + 6 `today_session_cubit_test.dart`), no regressions.

### File List

**New:**
- `pulse_coach/lib/features/today/presentation/widgets/active_days_card.dart`
- `pulse_coach/test/widget/active_days_card_test.dart`

**Modified:**
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/test/bloc/today_session_cubit_test.dart`
- `pulse_coach/test/offline/offline_core_features_test.dart`

**Auto-regenerated (gitignored):**
- `pulse_coach/lib/l10n/app_localizations.dart`, `app_localizations_it.dart`, `app_localizations_en.dart`

## Change Log

- 2026-07-07: Story 22.3 implemented (dev-story). Added `activeDaysCaption` ARB key (IT/EN); added `ActiveDaysCard` widget; extended `TodaySessionCubit` with an injectable clock, `_fetchActiveDaysCount`/`_countActiveDaysInWindow`, and `activeDaysCount` state wired into both `planLoaded` (non-null-`planId` branch, concurrently with `weatherContext`) and `_onLogsChanged` (live update); wired `ActiveDaysCard` into `TodayPage`'s phone-layout branch below the hero card. 9 new tests (3 widget + 6 cubit), all following red-green ATDD. `flutter analyze` 0 issues; `flutter test` 1355 passed/1 skipped (baseline 1346/1 + 9 new), no regressions. Status moved to review.
- 2026-07-06: Story 22.3 created via create-story workflow. Flagged a real, pre-existing latent bug: `StateVector.streak`/the legacy `Sessions` Drift table are never populated by the live app since Epic 8 moved real completion-tracking to `SessionLogs` — the epic's "reuse the FR23 signal" hint (itself an unconfirmed `[ASSUMPTION]` per the PRD decision log) would have anchored this story to dead data and a consecutive-streak shape directly contradicted by this story's own ACs. Story instead reuses `SessionLogsDao.getAllLogsOrderedByDate()` (the same table Epic 10's Progress feature and Story 22.2's weather-wiring precedent already treat as Today's real state), computing a genuinely windowed, device-local, non-resetting 30-day distinct-active-days count. Extends `TodaySessionCubit` (no new Cubit) following the exact concurrent-fetch pattern Story 22.2 established for `weatherContext`.

### Review Findings

_Code review 2026-07-07 (bmad-code-review, Opus 4.8, 3-layer adversarial: Blind Hunter / Edge Case Hunter / Acceptance Auditor). All 6 ACs verified SATISFIED by the Acceptance Auditor. 1 decision-needed (resolved → patch), 3 patches, 1 deferred, 6 dismissed as noise._

- [x] [Review][Patch] Active-days value was rendered twice on screen (Mono numeral + caption that already embeds the count) [active_days_card.dart:36] — resolved via review decision 2026-07-07 (Paolo, option 2): **drop the leading Mono `Text('$count')`** (and its `SizedBox`/`Row`/`Expanded` scaffolding) so the caption `"N giorni attivi negli ultimi 30"` is the sole on-screen carrier of the value. Semantics node (single, reads the caption once) unchanged; the widget-test assertions (`bySemanticsLabel('0 …')`/`'17 …'`, and `'17'` findsNothing) all stay green.
- [x] [Review][Patch] `_fetchActiveDaysCount` DB failure aborts the entire Today render (asymmetric with `_fetchWeather`) [today_session_cubit.dart:98] — `_fetchWeather` is deliberately `try/catch → null` (documented: "can't take down heroIndex/completedIndices or leave planLoaded's future rejecting unhandled"); `_fetchActiveDaysCount` has no such guard. If `getAllLogsOrderedByDate()` throws, `await activeDaysFuture` re-throws before the `emit`, so the core session UI never renders — and on the staleness/`isClosed` early-return paths the still-pending future rejects as an unhandled async error. Fix: mirror `_fetchWeather` — wrap the body in `try/catch → return 0` with `AppLogger.error`. (Merged: Blind Hunter High + Edge High + the two unhandled-async-error findings.)
- [x] [Review][Patch] `activeDaysCaption` ARB key lacks ICU plural → "1 giorni attivi" / "1 active days" at count == 1 [app_it.arb:23, app_en.arb:23] — plain `{count}` int placeholder. The project already uses ICU `plural` (`deviceSettingsSyncPending`, both ARB files:227). Fix: `"{count, plural, one{1 giorno attivo negli ultimi 30} other{{count} giorni attivi negli ultimi 30}}"` (IT) and `one{1 active day in the last 30} other{{count} active days in the last 30}` (EN); the widget-test caption assertions ("0 …" and "17 …") stay green since only count == 1 changes wording.
- [x] [Review][Defer] Live update in `_onLogsChanged` is narrower than "any completion" [today_session_cubit.dart:167] — the `setEquals(completed, state.completedIndices)` early-return fires BEFORE the new `activeDaysCount` recompute, so a completion that doesn't change the current plan's completed-index set (or a shared-session completion with `dailyPlanId == null`, which never fires `watchLogsForPlan(planId)`) won't live-refresh the count until the next `planLoaded`. AC5's literal scenario ("user completes the hero session") IS satisfied because that changes the set. Deferred: AC5 met as written; broadening would require either a full-table query on every no-op log event or a new subscription the story explicitly forbids.
