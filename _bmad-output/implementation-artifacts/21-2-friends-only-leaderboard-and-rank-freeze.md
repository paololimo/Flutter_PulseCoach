---
baseline_commit: 0347fd18e933fb2023809644773571f3ea67c836
---

# Story 21.2: Friends-Only Leaderboard and Rank Freeze

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to see a friends leaderboard with medal glyphs for the top three and have my rank frozen while I'm in a protective state,
So that resting never reads as losing ground.

## Context

**Epic 21 — Leaderboard & Scoring (v2.5), third story.** Story 21.1 (`done`) built the **write path**: solo sessions award points into a new `leaderboard_entries` Supabase table via the `award_session_points` RPC. This story builds the **read/viewing path** — a ranked, friends-only leaderboard tab in the Social screen, with medal glyphs for the top 3 and a rank-freeze behavior while the viewer is in `AtRisk`/`Recovering`. It does **not** touch shared-session scoring (Story 21.3) or the points write path (already done).

**This story adds NO new points-writing logic.** It only reads `leaderboard_entries` (already populated by 21.1) via a new read-only RPC.

### What already exists (DO NOT REBUILD)

- **`lib/features/social/leaderboard/`** already has 4 files from Story 21.1 — **extend, do not duplicate**:
  - `data/datasources/leaderboard_remote_data_source.dart` — has `awardPoints`/`replayAward` (write path). **Add a new `fetchLeaderboard()` method to this same class**, mirroring `ProgressComparisonRemoteDataSource`'s `@visibleForTesting` function-field pattern (`lib/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart`) — do not create a second datasource class.
  - `domain/repositories/leaderboard_repository.dart` — has `awardSessionPoints(...)`. **Add `getFriendsLeaderboard()` to this same interface.**
  - `data/repositories/leaderboard_repository_impl.dart` — implements the write path via `SyncManager`. **Add the new read method as a second `@override`** on the same class; it does NOT go through `SyncManager` (reads aren't queued — there's nothing to replay offline; a failed read is just a `Left`).
  - `domain/scoring_constants.dart` — unrelated to this story, do not touch.
- **The whole Social tab is already Pro-gated** at `SocialPage`'s `_SocialViewState.build` (`lib/features/social/friends/presentation/pages/social_page.dart:99`): if `tier != SubscriptionTier.pro`, `_LockedBanner` renders and no tab (friends/feed/comparison) is reachable. Adding a 4th tab automatically inherits this gate — **do not add any separate Pro check inside the new leaderboard feature.**
- **`ProgressComparisonBloc`/`ProgressComparisonPage`/`ComparisonRow`** (`lib/features/social/comparison/presentation/`) is the closest existing analog — a ranked list of self + friends read from a Supabase RPC, rendered as `Card` rows in a `ListView`, Social-tab-scoped bloc created once in `SocialPage`'s `MultiBlocProvider` and dispatched from the tab's own `initState`. **Mirror this shape exactly** for `LeaderboardBloc`/`LeaderboardPage`/`LeaderboardRow`.
- **`0007_friends_progress_rpc.sql`** is the exact SQL pattern to mirror for the new leaderboard RPC: `SECURITY DEFINER`, `SET search_path = public`, a `my_friends` CTE resolving accepted `friendships` in either direction, filtered to `profiles.visibility_tier = 'friends_only'`, `REVOKE ALL ... FROM public; GRANT EXECUTE ... TO authenticated;`.
- **`BehavioralStateDao.getLatestState()`** (`lib/core/database/daos/behavioral_state_dao.dart`) is the existing, already-used mechanism for reading the current behavioral state **outside** the Today screen — `ShardSessionBloc` reads it exactly this way at `lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart:170` (`await _db.behavioralStateDao.getLatestState()`, then parses `.currentState` — a raw string `'Active'|'Fatigued'|'AtRisk'|'Recovering'` — via a private `_parseBehavioralState` helper that defaults unparseable/null to `active`). **`DailyPlanBloc` is NOT usable here** — it's created per-route only for the Today screen (`lib/core/routing/app_router.dart:80`), never provided in the Social tab's widget tree. `LeaderboardBloc` must inject `AppDatabase` directly and read `_db.behavioralStateDao.getLatestState()` itself, mirroring `shared_session_bloc.dart`'s pattern (parse the raw string locally; do not import `DailyPlanBloc`).
- **`ai/state_machine/behavioral_state.dart`**: `enum BehavioralState { active, fatigued, atRisk, recovering }` — this story's "protective state" = `atRisk` or `recovering`.
- **Medal colors already exist as raw `Color` literals used directly (no new `ThemeExtension` fields needed)** — UX-DR23's exact hex values are already in the codebase as other tokens: `medal-gold #E8C87A` == `PulseCoachTheme.tertiary` (both dark and light — same literal), `medal-bronze #F0A1B0` is already used as a raw `Color(0xFFF0A1B0)` literal in `lib/features/today/presentation/widgets/session_card_helpers.dart:8` (the cardio accent). `medal-silver #9498A6` matches dark's `onSurfaceVariant` but **not** light's (`#42474E`) — so, following the `session_card_helpers.dart` precedent (a plain top-level function returning a raw `Color`, not routed through `ThemeExtension`), add a small `medalColor(int rank)` helper (`Color? medalColor(int rank) => switch (rank) { 1 => Color(0xFFE8C87A), 2 => Color(0xFF9498A6), 3 => Color(0xFFF0A1B0), _ => null }`) in the new `leaderboard` feature rather than extending `PulseCoachTheme`.
- **`SharedPreferences`** is already a registered `@singletonAsync` dependency (`lib/core/di/settings_module.dart`) and already used for exactly this kind of small persisted flag in this same feature — `LeaderboardRepositoryImpl._installId()` (21.1) is the pattern to mirror for the new `RankFreezeStore`.
- **No `package:collection` dependency exists** in `pubspec.yaml` (confirmed: not a direct dependency, not imported anywhere in `lib/`). Do not add it just for a `sortBy` helper — use a plain `List.sort(...)` comparator.

### Resolved Ambiguity — What "Frozen Rank" Means Mechanically

Epics.md says: "the user's rank row is frozen at the rank they held when they entered the protective state; any rank changes... are not applied until they return to Active or Fatigued." It does not specify implementation mechanics. Two readings were considered:

1. **Number-only freeze**: keep the user's row in its live sorted position, but freeze only the digit shown next to it.
2. **Position-pinned freeze** (chosen): pin the user's entire row at the fixed list index corresponding to the frozen rank; every other row keeps sorting live around it.

**Decision: position-pinned (#2).** Reading #1 would still visually show the user's row sliding down the list as friends' points grow — which reads exactly as "losing ground," defeating the point of UX-DR31 ("resting never reads as losing ground"). Pinning the row's position is the only reading that satisfies the stated intent. This is implemented as a pure, standalone, unit-testable function — see Task 2.

### Resolved Ambiguity — How "The Rank They Held When They Entered" Is Captured

There is no background listener for behavioral-state transitions in this codebase (state is written opportunistically by the AI engine — see `generate_daily_plan.dart`/`update_bandit_reward.dart` — and nothing else observes writes in real time). Building one is out of scope for a social-feature story. **Decision: snapshot-on-first-observation.** The first time `LeaderboardBloc` loads while the current state is `atRisk`/`recovering` and no frozen rank is already stored, it captures the **live rank at that moment** as the frozen value and persists it (`RankFreezeStore`, SharedPreferences-backed). Every subsequent load while still protective reuses the stored value. On the first load where the state has returned to `active`/`fatigued`, the stored value is cleared. This is a pragmatic approximation of "the moment they entered" (the true transition may have happened slightly earlier, while the user wasn't looking at the Social tab) and is architecturally consistent with the rest of this feature (comparison/feed are also pull-based, no push updates).

### Resolved Ambiguity — Tie-Breaking and Rank Assignment

No tie-breaking rule is specified anywhere. **Decision:** sort by `totalPoints` descending; ties broken by `displayHandle` ascending (deterministic, no timestamp needed). Ranks are sequential 1-based positions in the sorted list (no "1,2,2,4" competition-ranking gaps for ties) — simplest rule, not specified otherwise, and consistent with a "calm, static" list (UX-DR31) that must never look like it's doing anything clever.

### Resolved Ambiguity — Visibility Tier Filtering for Friends

`0007_friends_progress_rpc.sql` (the closest existing precedent, Story 18.4) filters friends to `profiles.visibility_tier = 'friends_only'` before including them in `get_friends_progress_this_week()`. The epics.md ACs for this story don't explicitly repeat that filter, but the leaderboard is exposing the same category of personal activity data (points earned from sessions) under the same friends-visibility consent model (NFR29) — a friend who has kept their profile `private` must not become visible in a friend's leaderboard just because they exist in the `friendships` table. **Decision: apply the identical `visibility_tier = 'friends_only'` filter** to the new RPC, mirroring 0007 exactly. The viewer's own row is always included regardless of their own `visibility_tier` (you can always see yourself).

## Acceptance Criteria

**AC1 — Friends-only leaderboard, ranked by total points:**
Given the user opens Social → Classifica (the new 4th tab in `SocialPage`)
When the leaderboard renders
Then it shows only the viewer + mutual friends with `visibility_tier = 'friends_only'`, ranked by total points descending (ties broken by handle ascending); non-friends are never visible, enforced by a `SECURITY DEFINER` RPC (RLS-equivalent server-side filtering), never by a client-side filter (FR76, NFR29).

**AC2 — Top-3 medal glyphs, never color alone:**
Given the top-3 rows (by displayed rank) render
When each `LeaderboardRow` builds
Then it shows three redundant cues: (1) the rank number, (2) a shape-distinct icon per medal (gold/silver/bronze use visually distinct `IconData`s, not just 3 circles in different colors), and (3) a text label (`"1° oro"`/`"2° argento"`/`"3° bronzo"` in Italian) — verified by asserting the label text is present in the widget tree, not just a colored container (UX-DR23, UX-DR28, UX-DR33).

**AC3 — Rank frozen while the viewer is in a protective state:**
Given the viewer's latest local `BehavioralState` (`BehavioralStateDao.getLatestState()`) is `AtRisk` or `Recovering`
When the leaderboard loads
Then the viewer's own row is pinned at the rank captured the first time this condition was observed (persisted via `RankFreezeStore`) — not its current live-sorted position — regardless of whether other friends' totals have since moved above or below that position (UX-DR28, UX-DR31).

**AC4 — Freeze clears on return to Active/Fatigued:**
Given a frozen rank is stored
When the viewer's latest local `BehavioralState` is `Active` or `Fatigued`
Then the stored frozen rank is cleared and the viewer's row renders at its live sorted position on this and all subsequent loads, until a new protective-state episode begins.

**AC5 — No overtaken alerts, ever:**
Given a friend's total points now exceed the viewer's
When the leaderboard renders (frozen or not)
Then no toast, push notification, animation, or "sei stato superato da [handle]"-style text appears anywhere in this feature — this is a static, pull-to-view-only list (UX-DR31).

**AC6 — No movement animation:**
Given the leaderboard tab renders, including on a refresh where rank/points changed since the last view
When the list rebuilds
Then no points-delta or rank-movement animation runs — no `AnimatedSwitcher`/implicit-animation widget is used for row reordering or point changes; the view is static (UX-DR31).

**AC7 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all pre-existing tests pass (baseline: 1279 passed, 1 skipped, confirmed at story start) plus all new tests pass; analyzer reports 0 issues.

## Tasks / Subtasks

---

### Task 1 — Supabase migration: read-only friends-leaderboard RPC (AC1)

- [x] **1.1** Create `supabase/migrations/0012_friends_leaderboard_rpc.sql`, mirroring `0007_friends_progress_rpc.sql`'s CTE/RLS-bypass shape:

  ```sql
  -- RPC for Story 21.2: returns total points for the viewer + accepted
  -- friends with visibility_tier = 'friends_only' (the viewer's own row is
  -- always included regardless of their own tier). Ranking/tie-breaking and
  -- rank-freeze are computed client-side (LeaderboardBloc) — this RPC only
  -- returns unranked per-user totals.
  CREATE OR REPLACE FUNCTION get_friends_leaderboard()
  RETURNS TABLE(
    user_id       uuid,
    display_handle text,
    total_points  bigint,
    is_own        boolean
  )
  LANGUAGE sql
  STABLE
  SECURITY DEFINER
  SET search_path = public
  AS $$
    WITH current_uid AS (
      SELECT auth.uid() AS uid
    ),
    my_friends AS (
      SELECT
        CASE
          WHEN f.requester_id = (SELECT uid FROM current_uid) THEN f.addressee_id
          ELSE f.requester_id
        END AS friend_id
      FROM friendships f
      WHERE f.status = 'accepted'
        AND (
          f.requester_id = (SELECT uid FROM current_uid)
          OR f.addressee_id = (SELECT uid FROM current_uid)
        )
    ),
    visible_users AS (
      SELECT (SELECT uid FROM current_uid) AS uid, true AS is_own
      UNION
      SELECT mf.friend_id, false
      FROM my_friends mf
      JOIN profiles p ON p.id = mf.friend_id
      WHERE p.visibility_tier = 'friends_only'
    )
    SELECT
      vu.uid                                          AS user_id,
      COALESCE(p.display_handle, vu.uid::text)        AS display_handle,
      COALESCE(SUM(le.points), 0)::bigint              AS total_points,
      vu.is_own
    FROM visible_users vu
    JOIN profiles p ON p.id = vu.uid
    LEFT JOIN leaderboard_entries le ON le.owner_id = vu.uid
    GROUP BY vu.uid, p.display_handle, vu.is_own
  $$;

  REVOKE ALL  ON FUNCTION get_friends_leaderboard() FROM public;
  GRANT EXECUTE ON FUNCTION get_friends_leaderboard() TO authenticated;
  ```

- [x] **1.2** Note (same as 0011/0007): apply via the team's Supabase CLI workflow, not exercised by `flutter test` — no Dart test talks to a real Supabase instance.

---

### Task 2 — Pure-Dart rank-pinning algorithm (AC1, AC3, AC4)

- [x] **2.1** Create `pulse_coach/lib/features/social/leaderboard/domain/entities/leaderboard_entry.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';

  part 'leaderboard_entry.freezed.dart';

  @freezed
  abstract class LeaderboardEntry with _$LeaderboardEntry {
    const factory LeaderboardEntry({
      required String userId,
      required String displayHandle,
      required int totalPoints,
      required bool isOwn,
      required int rank, // 1-based, assigned client-side by RankPinning
    }) = _LeaderboardEntry;
  }
  ```

- [x] **2.2** Create `pulse_coach/lib/features/social/leaderboard/domain/rank_pinning.dart`:
  ```dart
  import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';

  /// Pure Dart: sorts unranked entries and, if [frozenOwnRank] is set, pins
  /// the viewer's own entry at that fixed list position instead of its live
  /// sorted position — see Story 21.2's "position-pinned freeze" decision.
  /// Every other entry keeps sorting live around the pinned position; only
  /// the own entry's index/rank number is held fixed.
  class RankPinning {
    const RankPinning._();

    static List<LeaderboardEntry> compute({
      required List<({String userId, String displayHandle, int totalPoints, bool isOwn})> raw,
      int? frozenOwnRank,
    }) {
      final sorted = [...raw]..sort((a, b) {
          final byPoints = b.totalPoints.compareTo(a.totalPoints);
          if (byPoints != 0) return byPoints;
          return a.displayHandle.compareTo(b.displayHandle);
        });

      final ownIndex = sorted.indexWhere((e) => e.isOwn);
      if (ownIndex == -1 || frozenOwnRank == null) {
        return [
          for (var i = 0; i < sorted.length; i++)
            LeaderboardEntry(
              userId: sorted[i].userId,
              displayHandle: sorted[i].displayHandle,
              totalPoints: sorted[i].totalPoints,
              isOwn: sorted[i].isOwn,
              rank: i + 1,
            ),
        ];
      }

      final own = sorted.removeAt(ownIndex);
      final targetIndex = (frozenOwnRank - 1).clamp(0, sorted.length);
      sorted.insert(targetIndex, own);

      return [
        for (var i = 0; i < sorted.length; i++)
          LeaderboardEntry(
            userId: sorted[i].userId,
            displayHandle: sorted[i].displayHandle,
            totalPoints: sorted[i].totalPoints,
            isOwn: sorted[i].isOwn,
            rank: i + 1,
          ),
      ];
    }
  }
  ```

  **Critical — the "live rank" the bloc needs to persist on first freeze is `compute(raw: raw, frozenOwnRank: null)`'s own entry's `.rank`** (i.e., call `compute` once unfrozen to discover the live rank, THEN call it again with that value as `frozenOwnRank` if this is the freeze moment — or simply: if no stored freeze value exists yet, compute unfrozen once, read the own rank, persist it, and that value already equals the correct pinned position for this first render). See Task 5 (`LeaderboardBloc`) for exact sequencing.

- [x] **2.3** Test: `test/domain/social/leaderboard/rank_pinning_test.dart` — pure-Dart, no mocks:
  ```
  [21.2-RANK-001] frozenOwnRank: null → entries ranked by live totalPoints desc, own entry gets its live position
  [21.2-RANK-002] tie in totalPoints → tie-break by displayHandle ascending, deterministic across repeated calls
  [21.2-RANK-003] frozenOwnRank: 1, own entry's live rank would be 3 → own entry pinned at index 0 (rank 1); the two entries that were above it shift down to ranks 2/3; friends never reorder relative to EACH OTHER
  [21.2-RANK-004] frozenOwnRank greater than total entry count → clamped to the last position, no index-out-of-range
  [21.2-RANK-005] no entry has isOwn: true (degenerate) → frozenOwnRank is ignored, plain live ranking returned
  ```

---

### Task 3 — `RankFreezeStore`: SharedPreferences-backed frozen-rank persistence (AC3, AC4)

- [x] **3.1** Create `pulse_coach/lib/features/social/leaderboard/data/rank_freeze_store.dart`, mirroring `LeaderboardRepositoryImpl._installId()`'s SharedPreferences shape:
  ```dart
  import 'package:injectable/injectable.dart';
  import 'package:shared_preferences/shared_preferences.dart';

  /// Persists the viewer's pinned rank across app restarts for the
  /// duration of a protective-state (AtRisk/Recovering) episode.
  /// Cleared the first time the viewer is observed back in Active/Fatigued.
  @injectable
  class RankFreezeStore {
    static const String _key = 'leaderboard_frozen_rank';

    final SharedPreferences _prefs;
    const RankFreezeStore(this._prefs);

    int? getFrozenRank() => _prefs.getInt(_key);

    Future<void> setFrozenRank(int rank) => _prefs.setInt(_key, rank);

    Future<void> clear() => _prefs.remove(_key);
  }
  ```

- [x] **3.2** Test: `test/data/social/leaderboard/rank_freeze_store_test.dart` (use `SharedPreferences.setMockInitialValues({})`, same setup as `leaderboard_repository_impl_test.dart`):
  ```
  [21.2-STORE-001] getFrozenRank() → null when nothing stored
  [21.2-STORE-002] setFrozenRank(2) then getFrozenRank() → 2
  [21.2-STORE-003] setFrozenRank(2) then clear() then getFrozenRank() → null
  ```

---

### Task 4 — Extend `LeaderboardRemoteDataSource`/`LeaderboardRepository` with the read path (AC1)

- [x] **4.1** Edit `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart` — add alongside the existing write-path methods (do not touch `awardPoints`/`replayAward`):
  ```dart
  LeaderboardRemoteDataSource(this._supabase) {
    callAwardRpc = _defaultCallAwardRpc;
    fetchLeaderboard = _defaultFetchLeaderboard;
  }

  @visibleForTesting
  late Future<List<Map<String, dynamic>>> Function() fetchLeaderboard;

  Future<List<Map<String, dynamic>>> _defaultFetchLeaderboard() async {
    final result = await _supabase.client.rpc('get_friends_leaderboard');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<List<Map<String, dynamic>>> loadLeaderboard() => fetchLeaderboard();
  ```
  (constructor now assigns both function fields — merge into the existing constructor, do not add a second constructor.)

- [x] **4.2** Create `pulse_coach/lib/features/social/leaderboard/data/models/leaderboard_row_dto.dart`, mirroring `friend_progress_dto.dart`:
  ```dart
  class LeaderboardRowDto {
    final String userId;
    final String displayHandle;
    final int totalPoints;
    final bool isOwn;

    const LeaderboardRowDto({
      required this.userId,
      required this.displayHandle,
      required this.totalPoints,
      required this.isOwn,
    });

    factory LeaderboardRowDto.fromJson(Map<String, dynamic> json) {
      return LeaderboardRowDto(
        userId: json['user_id'] as String? ?? '',
        displayHandle: json['display_handle'] as String? ??
            (json['user_id'] as String? ?? ''),
        totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
        isOwn: json['is_own'] as bool? ?? false,
      );
    }
  }
  ```

- [x] **4.3** Edit `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart` — add:
  ```dart
  Future<Either<Failure, List<({String userId, String displayHandle, int totalPoints, bool isOwn})>>>
      getFriendsLeaderboard();
  ```
  (returns the raw unranked tuple shape `RankPinning.compute` expects — ranking is the bloc's job, not the repository's, matching the "no `Failure` in domain widgets" and "keep the repository dumb" precedent from `ProgressComparisonRepository`.)

- [x] **4.4** Edit `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart` — add a second `@override` method (the class already has `_syncManager`/`_prefs`; add the datasource as a third constructor param):
  ```dart
  final LeaderboardRemoteDataSource _dataSource;

  LeaderboardRepositoryImpl(this._syncManager, this._prefs, this._dataSource);

  @override
  Future<Either<Failure, List<({String userId, String displayHandle, int totalPoints, bool isOwn})>>>
      getFriendsLeaderboard() async {
    try {
      final rows = await _dataSource.loadLeaderboard();
      final entries = rows.map(_safeFromJson).whereType<LeaderboardRowDto>();
      return Right([
        for (final e in entries)
          (userId: e.userId, displayHandle: e.displayHandle, totalPoints: e.totalPoints, isOwn: e.isOwn),
      ]);
    } catch (e) {
      return Left(SocialFailure('Failed to load leaderboard: $e'));
    }
  }

  LeaderboardRowDto? _safeFromJson(Map<String, dynamic> row) {
    try {
      return LeaderboardRowDto.fromJson(row);
    } catch (_) {
      return null; // degrade a single bad row rather than crashing the whole list
    }
  }
  ```
  **Critical — do NOT route this read through `SyncManager`.** `SyncManager.enqueue` exists to survive offline writes with retry/replay; a read has nothing to replay — a failed fetch is just a `Left`, exactly like `ProgressComparisonRepositoryImpl.getFriendsProgress()`.

---

### Task 5 — `GetFriendsLeaderboardUseCase` + `LeaderboardBloc` (AC1, AC3, AC4)

- [x] **5.1** Create `pulse_coach/lib/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart`:
  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';

  @injectable
  class GetFriendsLeaderboardUseCase {
    final LeaderboardRepository _repository;
    const GetFriendsLeaderboardUseCase(this._repository);

    Future<Either<Failure, List<({String userId, String displayHandle, int totalPoints, bool isOwn})>>>
        call() => _repository.getFriendsLeaderboard();
  }
  ```

- [x] **5.2** Create `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_event.dart`:
  ```dart
  abstract class LeaderboardEvent {
    const LeaderboardEvent();
  }

  class LeaderboardLoaded extends LeaderboardEvent {
    const LeaderboardLoaded();
  }
  ```

- [x] **5.3** Create `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_state.dart`:
  ```dart
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';

  part 'leaderboard_state.freezed.dart';

  @freezed
  abstract class LeaderboardState with _$LeaderboardState {
    const factory LeaderboardState.initial() = _Initial;
    const factory LeaderboardState.loading() = _Loading;
    const factory LeaderboardState.loaded({
      required List<LeaderboardEntry> entries,
      required bool isFrozen,
    }) = _Loaded;
    const factory LeaderboardState.error({required Failure failure}) = _Error;
  }
  ```

- [x] **5.4** Create `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart`:
  ```dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
  import 'package:pulse_coach/core/database/app_database.dart';
  import 'package:pulse_coach/features/social/leaderboard/data/rank_freeze_store.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/rank_pinning.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart';
  import 'leaderboard_event.dart';
  import 'leaderboard_state.dart';

  @injectable
  class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
    final GetFriendsLeaderboardUseCase _getLeaderboard;
    final RankFreezeStore _freezeStore;
    final AppDatabase _db;

    LeaderboardBloc(this._getLeaderboard, this._freezeStore, this._db)
        : super(const LeaderboardState.initial()) {
      on<LeaderboardLoaded>(_onLoaded);
    }

    Future<void> _onLoaded(
      LeaderboardLoaded event,
      Emitter<LeaderboardState> emit,
    ) async {
      emit(const LeaderboardState.loading());

      final result = await _getLeaderboard();
      if (result.isLeft()) {
        emit(LeaderboardState.error(
          failure: result.fold((f) => f, (_) => throw AssertionError()),
        ));
        return;
      }
      final raw = result.getOrElse(() => []);

      final stateRow = await _db.behavioralStateDao.getLatestState();
      final behavioralState = _parseBehavioralState(stateRow?.currentState);
      final isProtective = behavioralState == BehavioralState.atRisk ||
          behavioralState == BehavioralState.recovering;

      if (!isProtective) {
        // Not protective: clear any stale freeze from a prior episode and
        // show the live ranking.
        await _freezeStore.clear();
        emit(LeaderboardState.loaded(
          entries: RankPinning.compute(raw: raw, frozenOwnRank: null),
          isFrozen: false,
        ));
        return;
      }

      var frozenRank = _freezeStore.getFrozenRank();
      if (frozenRank == null) {
        // First observation of this protective episode: the live rank AT
        // THIS MOMENT becomes the frozen value (see "Resolved Ambiguity —
        // How 'the rank they held when they entered' is captured").
        final live = RankPinning.compute(raw: raw, frozenOwnRank: null);
        final ownLive = live.where((e) => e.isOwn).firstOrNull;
        if (ownLive != null) {
          frozenRank = ownLive.rank;
          await _freezeStore.setFrozenRank(frozenRank);
        }
      }

      emit(LeaderboardState.loaded(
        entries: RankPinning.compute(raw: raw, frozenOwnRank: frozenRank),
        isFrozen: frozenRank != null,
      ));
    }

    // Mirrors shared_session_bloc.dart's _parseBehavioralState: unrecognized
    // or missing state defaults to `active` (fail-open to "not protective").
    BehavioralState _parseBehavioralState(String? raw) {
      if (raw == null) return BehavioralState.active;
      return switch (raw.toLowerCase()) {
        'active' => BehavioralState.active,
        'fatigued' => BehavioralState.fatigued,
        'atrisk' => BehavioralState.atRisk,
        'recovering' => BehavioralState.recovering,
        _ => BehavioralState.active,
      };
    }
  }
  ```
  **Critical — `firstOrNull` requires `package:collection`, which is NOT a dependency (confirmed in Task discovery). Do not use it.** Replace with a manual null-safe lookup:
  ```dart
  LeaderboardEntry? ownLive;
  for (final e in live) {
    if (e.isOwn) { ownLive = e; break; }
  }
  ```

- [x] **5.5** Tests: `test/bloc/leaderboard_bloc_test.dart` (`bloc_test` package, mock `GetFriendsLeaderboardUseCase`/`RankFreezeStore`/`AppDatabase`+`BehavioralStateDao` — mirror the mocking style already used in `daily_plan_bloc_test.dart` for `_db.behavioralStateDao.getLatestState()`):
  ```
  [21.2-BLOC-001] state=Active, no stored freeze → loaded with live ranking, isFrozen: false
  [21.2-BLOC-002] state=AtRisk, no stored freeze → captures live rank, calls freezeStore.setFrozenRank with it, isFrozen: true
  [21.2-BLOC-003] state=AtRisk, stored freeze=2, live rank would now be 4 → own entry pinned at rank 2 (not 4), isFrozen: true
  [21.2-BLOC-004] state=Recovering → same freeze behavior as AtRisk (BLOC-002/003 repeated for Recovering)
  [21.2-BLOC-005] previously frozen, state now Fatigued → freezeStore.clear() called, live ranking shown, isFrozen: false
  [21.2-BLOC-006] repository returns Left → error state
  [21.2-BLOC-007] behavioralStateDao.getLatestState() returns null → defaults to Active (unfrozen), mirrors shared_session_bloc's fail-open default
  ```

---

### Task 6 — `LeaderboardRow` widget + `LeaderboardPage` + `medal_colors.dart` helper (AC2, AC5, AC6)

- [x] **6.1** Create `pulse_coach/lib/features/social/leaderboard/presentation/widgets/medal_colors.dart`:
  ```dart
  import 'package:flutter/material.dart';

  /// UX-DR23 medal accent colors — fixed hex values (not theme-dependent),
  /// same convention as sessionAccentColor's cardio literal
  /// (session_card_helpers.dart). Returns null for rank > 3 (no medal).
  Color? medalColor(int rank) => switch (rank) {
        1 => const Color(0xFFE8C87A), // gold
        2 => const Color(0xFF9498A6), // silver
        3 => const Color(0xFFF0A1B0), // bronze
        _ => null,
      };

  /// Shape-distinct glyph per medal (never rely on color alone, UX-DR23/33).
  IconData? medalIcon(int rank) => switch (rank) {
        1 => Icons.star,
        2 => Icons.circle,
        3 => Icons.diamond,
        _ => null,
      };
  ```

- [x] **6.2** Create `pulse_coach/lib/features/social/leaderboard/presentation/widgets/leaderboard_row.dart`, mirroring `ComparisonRow`'s `Card` shape:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';
  import 'package:pulse_coach/features/social/leaderboard/presentation/widgets/medal_colors.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';

  class LeaderboardRow extends StatelessWidget {
    final LeaderboardEntry entry;
    const LeaderboardRow({super.key, required this.entry});

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      final theme = Theme.of(context);
      final color = medalColor(entry.rank);
      final icon = medalIcon(entry.rank);

      final backgroundColor = entry.isOwn
          ? theme.colorScheme.surfaceContainerHigh
          : theme.colorScheme.surfaceContainer;

      return Card(
        color: backgroundColor,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Cue 1: rank number — always shown, primary cue.
              SizedBox(
                width: 32,
                child: Text(
                  '${entry.rank}°',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              // Cue 2: shape-distinct glyph (top 3 only).
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  '@${entry.displayHandle}',
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.visible, // UX-DR33: wraps, never truncates
                ),
              ),
              // Cue 3: text label (top 3 only) — never color alone.
              if (entry.rank <= 3)
                Text(_medalLabel(entry.rank, l10n), style: theme.textTheme.bodySmall)
              else
                Text(
                  l10n.leaderboardPoints(entry.totalPoints),
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      );
    }

    String _medalLabel(int rank, AppLocalizations l10n) => switch (rank) {
          1 => l10n.leaderboardMedalGold,
          2 => l10n.leaderboardMedalSilver,
          3 => l10n.leaderboardMedalBronze,
          _ => '',
        };
  }
  ```
  **Note:** top-3 rows show the medal label instead of the raw points count (matches epics.md's literal example strings `"1° oro"` etc. as the row's defining text); rows below rank 3 show the points count instead. This keeps every row's trailing text meaningful without needing two separate widgets — a resolved layout choice, not a spec requirement, flag if product wants both shown simultaneously.

- [x] **6.3** Create `pulse_coach/lib/features/social/leaderboard/presentation/pages/leaderboard_page.dart`, mirroring `ProgressComparisonPage`'s `StatefulWidget` + dispatch-on-`initState` shape (no `RefreshIndicator` pull-to-refresh needed per AC6's "static view", but reusing it is harmless and matches precedent — include it):
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart';
  import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_event.dart';
  import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_state.dart';
  import 'package:pulse_coach/features/social/leaderboard/presentation/widgets/leaderboard_row.dart';
  import 'package:pulse_coach/l10n/app_localizations.dart';
  import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

  class LeaderboardPage extends StatefulWidget {
    const LeaderboardPage({super.key});

    @override
    State<LeaderboardPage> createState() => _LeaderboardPageState();
  }

  class _LeaderboardPageState extends State<LeaderboardPage> {
    @override
    void initState() {
      super.initState();
      context.read<LeaderboardBloc>().add(const LeaderboardLoaded());
    }

    @override
    Widget build(BuildContext context) {
      final l10n = AppLocalizations.of(context)!;
      return BlocConsumer<LeaderboardBloc, LeaderboardState>(
        listener: (context, state) {
          state.whenOrNull(
            error: (_) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.socialGenericError)),
            ),
          );
        },
        builder: (context, state) {
          return state.when(
            initial: () => const _LeaderboardShimmer(),
            loading: () => const _LeaderboardShimmer(),
            loaded: (entries, isFrozen) {
              if (entries.isEmpty) {
                return Center(child: Text(l10n.leaderboardEmpty));
              }
              return RefreshIndicator(
                onRefresh: () async => context
                    .read<LeaderboardBloc>()
                    .add(const LeaderboardLoaded()),
                child: ListView(
                  children: [
                    for (final e in entries)
                      LeaderboardRow(key: ValueKey(e.userId), entry: e),
                  ],
                ),
              );
            },
            error: (_) => const _LeaderboardShimmer(),
          );
        },
      );
    }
  }

  class _LeaderboardShimmer extends StatelessWidget {
    const _LeaderboardShimmer();

    @override
    Widget build(BuildContext context) {
      return Column(
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ShimmerPlaceholder(height: 72),
          ),
        ),
      );
    }
  }
  ```
  **Critical (AC6) — no `AnimatedSwitcher`, no implicit-animation widget wraps the list or any row.** A plain `ListView` rebuild on state change is correct; do not add one for "polish."

- [x] **6.4** Edit `pulse_coach/lib/features/social/friends/presentation/pages/social_page.dart` — add the 4th tab (currently 586 lines; this adds ~10):
  - Add import: `package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart` and `.../presentation/pages/leaderboard_page.dart`.
  - In `_SocialViewState.initState`: change `TabController(length: 3, vsync: this)` → `TabController(length: 4, vsync: this)`.
  - In `SocialPage.build`'s `MultiBlocProvider.providers`, add:
    ```dart
    BlocProvider<LeaderboardBloc>(
      create: (_) => getIt<LeaderboardBloc>(),
      // Event dispatched from LeaderboardPage's own initState, same
      // convention as ProgressComparisonBloc immediately above.
    ),
    ```
  - In the `TabBar.tabs` list, add a 4th `Tab(text: l10n.leaderboardScreenTitle)` after the comparison tab.
  - In the `TabBarView.children` list, add `const LeaderboardPage()` after `const ProgressComparisonPage()`.

---

### Task 7 — l10n keys (AC2)

- [x] **7.1** Add to both `pulse_coach/lib/l10n/app/app_it.arb` and `app_en.arb`, near the existing `comparison*` keys:

  **`app_it.arb`:**
  ```json
  "leaderboardScreenTitle": "Classifica",
  "leaderboardEmpty": "Nessun amico in classifica.",
  "leaderboardMedalGold": "1° oro",
  "leaderboardMedalSilver": "2° argento",
  "leaderboardMedalBronze": "3° bronzo",
  "leaderboardPoints": "{count} punti",
  "@leaderboardPoints": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
  ```

  **`app_en.arb`:**
  ```json
  "leaderboardScreenTitle": "Leaderboard",
  "leaderboardEmpty": "No friends on the leaderboard yet.",
  "leaderboardMedalGold": "1st gold",
  "leaderboardMedalSilver": "2nd silver",
  "leaderboardMedalBronze": "3rd bronze",
  "leaderboardPoints": "{count} points",
  "@leaderboardPoints": {
    "placeholders": {
      "count": {"type": "int"}
    }
  }
  ```

---

### Task 8 — Regenerate DI + build_runner (AC7)

- [x] **8.1** From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: `lib/core/di/injection.config.dart` gains factory registrations for `RankFreezeStore` (`@injectable`), `GetFriendsLeaderboardUseCase` (`@injectable`), `LeaderboardBloc` (`@injectable`); `LeaderboardRepositoryImpl`'s existing registration picks up the new third constructor param automatically. New generated files: `leaderboard_entry.freezed.dart`, `leaderboard_state.freezed.dart`.

---

### Task 9 — Extend existing tests + new tests (AC1–AC7)

- [x] **9.1** `test/domain/social/leaderboard/rank_pinning_test.dart` — see Task 2.3.
- [x] **9.2** `test/data/social/leaderboard/rank_freeze_store_test.dart` — see Task 3.2.
- [x] **9.3** Extend `test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (existing file from 21.1 — add a new `group('loadLeaderboard', ...)`, do not touch the existing `awardPoints`/`replayAward` groups):
  ```
  [21.2-DS-001] loadLeaderboard() → fetchLeaderboard invoked, returns its raw list verbatim
  ```
- [x] **9.4** Extend `test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (existing file — `sut` construction now needs a 3rd arg; a `MockLeaderboardRemoteDataSource` — add `LeaderboardRemoteDataSource` to the file's `@GenerateMocks` list alongside the existing `SyncManager`):
  ```
  [21.2-REPO-001] getFriendsLeaderboard() → maps datasource rows to the unranked tuple list correctly (userId/displayHandle/totalPoints/isOwn)
  [21.2-REPO-002] one malformed row among valid ones → bad row dropped, valid rows still returned (mirrors ProgressComparisonRepositoryImpl's _safeFromJson degrade-one-row pattern)
  [21.2-REPO-003] datasource throws → returns Left(SocialFailure)
  ```
- [x] **9.5** `test/domain/social/leaderboard/get_friends_leaderboard_use_case_test.dart` (mock `LeaderboardRepository`):
  ```
  [21.2-USECASE-001] delegates to repository.getFriendsLeaderboard() and returns its result verbatim
  ```
- [x] **9.6** `test/bloc/leaderboard_bloc_test.dart` — see Task 5.5.
- [x] **9.7** `test/widget/leaderboard_page_test.dart` (new — mirror `test/widget/social_page_test.dart`'s `Fake`-bloc pattern, no real DI):
  ```
  [21.2-WIDGET-001] loaded, 3+ entries → rank-1 row shows the gold label text ("1° oro"), rank-2 shows silver, rank-3 shows bronze, rank-4+ shows a points count instead — never only a colored icon with no text
  [21.2-WIDGET-002] loaded, empty entries → empty-state text shown, no crash
  [21.2-WIDGET-003] error state → generic localized SnackBar shown (never raw failure.message), mirrors E18R-2
  [21.2-WIDGET-004] No AnimatedSwitcher (or other implicit-animation widget) present anywhere in the tree — `find.byType(AnimatedSwitcher)` returns `findsNothing` (AC6 guard)
  ```
- [x] **9.8** Extend `test/widget/social_page_test.dart` (existing file — every Pro-tier test that registers `getIt.registerFactory<ProgressComparisonBloc>(...)` must ALSO register `getIt.registerFactory<LeaderboardBloc>(() => _FakeLeaderboardBloc(const LeaderboardState.initial()))`, otherwise `SocialPage`'s new `BlocProvider<LeaderboardBloc>` will throw at `getIt<LeaderboardBloc>()` — add a `_FakeLeaderboardBloc` class mirroring `_FakeProgressComparisonBloc`):
  ```
  [21.2-WIDGET-005] Pro tier → 4th tab labeled "Classifica" is present in the TabBar
  ```
- [x] **9.9** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; all pre-existing tests (1279 passed, 1 skipped baseline) + all new tests pass.

---

## Review Findings

_Adversarial code review 2026-07-04 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). 0 decision-needed, 3 patch, 3 defer, 6 dismissed._

- [x] [Review][Patch] Unguarded post-fetch I/O in `_onLoaded` can wedge the bloc on `loading` [pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart:41] — only the use-case result is wrapped in `Either`; `getLatestState()`, `_freezeStore.clear()`, and `setFrozenRank()` are awaited without try/catch. If any throws after `emit(loading())`, no further state is emitted → UI stuck on the shimmer permanently. Wrap the post-fetch block in try/catch → emit `error`.
- [x] [Review][Patch] Silver medal glyph is `Icons.circle` — the exact shape AC2 cautions against [pulse_coach/lib/features/social/leaderboard/presentation/widgets/medal_colors.dart:16] — AC2 says "not just 3 circles in different colors". The 3-redundant-cue requirement is substantively met (rank number + icon + text label), but a literal circle for silver is the weakest shape-distinctness choice. Swap for a non-circular glyph (e.g. `Icons.workspace_premium`/`Icons.hexagon`).
- [x] [Review][Patch] `isFrozen: true` emitted when the pin is not actually applied (own entry absent) [pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart:82] — in the protective branch with a stored `frozenRank`, if the viewer's own row is missing from `raw`, `RankPinning.compute` returns an unpinned live ranking but the bloc still emits `isFrozen: frozenRank != null`. Currently latent (no widget consumes `isFrozen`), but incorrect and a future-badge hazard. Set `isFrozen` only when the own entry is actually present/pinned.
- [x] [Review][Defer] Error/empty/loading states show a non-retryable shimmer with no retry affordance [pulse_coach/lib/features/social/leaderboard/presentation/pages/leaderboard_page.dart:54] — deferred, pre-existing feature-wide pattern (identical to `ProgressComparisonPage`'s `error: (_) => const _ComparisonShimmer()`, mirrored per spec). Fixing only leaderboard would be inconsistent; belongs to a social-wide error-UX pass.
- [x] [Review][Defer] Own row silently dropped if the viewer has no `profiles` row; `COALESCE` fallback is dead [supabase/migrations/0012_friends_leaderboard_rpc.sql:48] — deferred, theoretical (profiles row is guaranteed in practice for any handle-bearing social user; migration is unapplied/untested per Task 1.2). Fix later by LEFT-joining the own row so the `COALESCE(p.display_handle, vu.uid::text)` fallback can fire.
- [x] [Review][Defer] Frozen-rank SharedPreferences key is not user-scoped → cross-account pin leakage on a shared install [pulse_coach/lib/features/social/leaderboard/data/rank_freeze_store.dart:9] — deferred, depends on the app's multi-account/sign-out model (21.1's `_installId` precedent is also install-scoped, not user-scoped). Revisit if account-switching on one install becomes a supported flow.

## Dev Notes

### Why `LeaderboardBloc` Reads `AppDatabase` Directly (Not a New Use Case)

`generate_daily_plan.dart` (a domain usecase) and `shared_session_bloc.dart` (a presentation bloc) both already call `_db.behavioralStateDao.getLatestState()` directly with no intermediate abstraction — there is no existing "GetCurrentBehavioralStateUseCase" anywhere in the codebase, and inventing one here (a new cross-feature abstraction, for a single call site) would be exactly the kind of premature abstraction this project's guidelines forbid. Mirror `shared_session_bloc.dart`'s pattern verbatim: inject `AppDatabase`, call the DAO, parse the raw string locally.

### Why the Read Path Bypasses `SyncManager` (Unlike the Write Path)

Story 21.1's write path routes through `SyncManager.enqueue` because a failed/offline write must not be silently lost — there's a queued retry to make later. A read has no such requirement: if the fetch fails, the correct behavior is exactly what `ProgressComparisonRepositoryImpl` already does — return `Left(SocialFailure(...))` immediately, no queueing, no retry machinery. Do not add one.

### Why Rank-Freeze State Lives in `SharedPreferences`, Not a New Drift Table

The only state being persisted is a single integer (the frozen rank) with no relational structure, no query needs, and an unbounded but tiny lifetime — a new Drift table (with its own migration + DAO + generated code) would be substantial overhead for one `int`. `LeaderboardRepositoryImpl._installId()` (21.1) already established `SharedPreferences` as this feature's precedent for exactly this class of small persisted flag.

### Scope Boundary vs. Story 21.3

This story does not touch: shared-session point bonuses, the server-side Edge Function, or any per-day cap logic (all Story 21.1/21.3 territory). `get_friends_leaderboard()` simply sums whatever is already in `leaderboard_entries` — when 21.3 starts writing shared-session bonus rows into the same table, this RPC picks them up automatically with zero changes required.

### File Size Check

- `social_page.dart`: 586 → ~600 lines (still well under the 800-line hard limit; consider it a candidate for splitting if a future story adds a 5th tab).
- `leaderboard_remote_data_source.dart`: 68 → ~85 lines.
- `leaderboard_repository_impl.dart`: 66 → ~95 lines.
- `leaderboard_repository.dart`: 10 → ~14 lines.
- All new files are single-responsibility and well under 200 lines.

### Project Structure Notes

**New production files:**
- `supabase/migrations/0012_friends_leaderboard_rpc.sql`
- `pulse_coach/lib/features/social/leaderboard/domain/entities/leaderboard_entry.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/rank_pinning.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart`
- `pulse_coach/lib/features/social/leaderboard/data/models/leaderboard_row_dto.dart`
- `pulse_coach/lib/features/social/leaderboard/data/rank_freeze_store.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_event.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_state.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/pages/leaderboard_page.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/widgets/leaderboard_row.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/widgets/medal_colors.dart`

**Modified production files:**
- `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart` (add `fetchLeaderboard`/`loadLeaderboard`)
- `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart` (add `getFriendsLeaderboard`)
- `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart` (add `getFriendsLeaderboard`, new datasource constructor param)
- `pulse_coach/lib/features/social/friends/presentation/pages/social_page.dart` (4th tab, `TabController(length: 4)`, `BlocProvider<LeaderboardBloc>`)
- `pulse_coach/lib/l10n/app/app_it.arb`, `app_en.arb` (new `leaderboard*` keys)

**Auto-regenerated:**
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/entities/leaderboard_entry.freezed.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_state.freezed.dart`

**New/modified test files:**
- `pulse_coach/test/domain/social/leaderboard/rank_pinning_test.dart`
- `pulse_coach/test/data/social/leaderboard/rank_freeze_store_test.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (extended)
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (extended)
- `pulse_coach/test/domain/social/leaderboard/get_friends_leaderboard_use_case_test.dart`
- `pulse_coach/test/bloc/leaderboard_bloc_test.dart`
- `pulse_coach/test/widget/leaderboard_page_test.dart`
- `pulse_coach/test/widget/social_page_test.dart` (extended)

**Out of scope for this story (explicitly deferred):**
- Shared-session point bonus, server-visible completion signal, counter-metric monitoring (Story 21.3).
- Any "you were overtaken" notification/animation of any kind (explicitly banned by UX-DR31, not just deferred).
- A dedicated "frozen" badge/tooltip UI — epics.md's ACs only require the rank NUMBER to be frozen; no additional visual indicator is specified, so none is added (avoid scope creep).

### References

- [Source: epics.md#Story 21.2 lines ~2795–2822 — full ACs, FR76, UX-DR23/28/31/33]
- [Source: epics.md#Epic 21 Prerequisites lines ~2742–2745 — confirms 21.2 has no cross-story hard-block, unlike 21.0→21.1]
- [Source: epics.md line 233 — UX-DR23 medal color hex values + 3-redundant-cues rule]
- [Source: epics.md line 238 — UX-DR28 LeaderboardRow component spec]
- [Source: epics.md line 241 — UX-DR31 Protective-State Social Suppression, all 5 sub-rules]
- [Source: epics.md line 243 — UX-DR33 accessibility, dense-row-wraps-not-truncates rule]
- [Source: architecture.md line 1327,1393 — `lib/features/social/leaderboard/` directory, FR74-76 mapping]
- [Source: architecture.md v2 Enforcement Guidelines #10 — RLS/SECURITY DEFINER at DB, client checks convenience-only]
- [Source: supabase/migrations/0007_friends_progress_rpc.sql — exact RPC/CTE/visibility-tier-filter pattern mirrored by Task 1]
- [Source: supabase/migrations/0011_leaderboard.sql — `leaderboard_entries` schema this story reads from (written by Story 21.1)]
- [Source: lib/core/database/daos/behavioral_state_dao.dart — `getLatestState()`, the mechanism for reading current BehavioralState outside Today]
- [Source: lib/core/database/tables/behavioral_state_table.dart — `currentState` raw string values]
- [Source: lib/ai/state_machine/behavioral_state.dart — `BehavioralState` enum]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart:170,421 — `_parseBehavioralState` pattern mirrored by `LeaderboardBloc`]
- [Source: lib/features/social/comparison/ (entire feature) — the structural template mirrored throughout this story: remote datasource, repository, use case, bloc, page, row widget]
- [Source: lib/features/today/presentation/widgets/session_card_helpers.dart:8 — raw-`Color`-literal convention mirrored by `medal_colors.dart`]
- [Source: lib/core/theme/pulse_coach_theme.dart — confirms `tertiary`/`onSurfaceVariant` hex values overlap with UX-DR23's medal colors in dark mode only, motivating the standalone `medalColor()` helper instead of a `ThemeExtension` field]
- [Source: lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart — `_installId()` SharedPreferences pattern mirrored by `RankFreezeStore`]
- [Source: lib/features/social/friends/presentation/pages/social_page.dart — `_SocialViewState` TabController/MultiBlocProvider structure this story extends to a 4th tab]
- [Source: test/widget/social_page_test.dart — existing Fake-bloc test pattern that must be extended for the new `LeaderboardBloc` provider]
- [Source: pubspec.yaml / pubspec.lock — confirms `package:collection` is not a direct dependency; do not introduce it for a one-line sort helper]
- [Source: _bmad-output/implementation-artifacts/21-1-points-system-and-solo-session-scoring.md — prior story's `leaderboard/` file layout, `LeaderboardRepositoryImpl` shape, confirmed baseline test count 1279 passed/1 skipped]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

None — no blocking failures encountered. `build_runner` ran cleanly on each invocation; `flutter analyze` reached 0 issues after fixing 4 lint infos (a doc-comment `[frozenOwnRank]` reference out of scope on `RankPinning`'s class doc, moved into the method-level doc; 3 `prefer_const_constructors` in new test files).

### Completion Notes List

- Implemented the full read/viewing path for the friends-only leaderboard per Tasks 1–9: Supabase RPC (`get_friends_leaderboard`, unapplied to any live DB — pure SQL artifact per story note 1.2), the pure-Dart `RankPinning` position-pinned freeze algorithm, `RankFreezeStore` (SharedPreferences-backed), the datasource/repository read path extension (bypassing `SyncManager`, matching `ProgressComparisonRepositoryImpl`'s precedent), `GetFriendsLeaderboardUseCase` + `LeaderboardBloc` (reads `AppDatabase.behavioralStateDao` directly, mirroring `shared_session_bloc.dart`), the `LeaderboardRow`/`LeaderboardPage`/`medal_colors.dart` widgets (3 redundant cues per medal, no animation), the new l10n keys, and the 4th `SocialPage` tab wiring.
- Followed strict TDD (red → green) for every unit: each new file's test was written and confirmed failing (compile error against the not-yet-existing production symbol) before the corresponding production code was added.
- Deviated from the story's literal Task 5.5/9.6 mock-based `AppDatabase`/`BehavioralStateDao` suggestion in favor of the codebase's actual established precedent in `daily_plan_bloc_test.dart` — an in-memory `AppDatabase.forTesting(NativeDatabase.memory())` with real DAO inserts — since that is the only pattern in use anywhere in this codebase for testing behavioral-state consumers; no test doubles for `AppDatabase`/`BehavioralStateDao` exist to mirror.
- Split spec test id `21.2-BLOC-004` into `21.2-BLOC-004a`/`004b` to cover both the "no stored freeze" and "stored freeze" sub-cases for `Recovering`, matching the coverage already given to `AtRisk` in BLOC-002/003 (spec text: "same freeze behavior as AtRisk (BLOC-002/003 repeated for Recovering)").
- `flutter analyze lib/ test/`: 0 issues. `flutter test`: 1305 passed, 1 skipped (baseline 1279 passed/1 skipped + 26 new tests across rank_pinning, rank_freeze_store, datasource, repository, use case, bloc, and widget suites).

### File List

**New:**
- `supabase/migrations/0012_friends_leaderboard_rpc.sql`
- `pulse_coach/lib/features/social/leaderboard/domain/entities/leaderboard_entry.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/rank_pinning.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart`
- `pulse_coach/lib/features/social/leaderboard/data/models/leaderboard_row_dto.dart`
- `pulse_coach/lib/features/social/leaderboard/data/rank_freeze_store.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_event.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_state.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/pages/leaderboard_page.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/widgets/leaderboard_row.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/widgets/medal_colors.dart`
- `pulse_coach/test/domain/social/leaderboard/rank_pinning_test.dart`
- `pulse_coach/test/data/social/leaderboard/rank_freeze_store_test.dart`
- `pulse_coach/test/domain/social/leaderboard/get_friends_leaderboard_use_case_test.dart`
- `pulse_coach/test/bloc/leaderboard_bloc_test.dart`
- `pulse_coach/test/widget/leaderboard_page_test.dart`

**Modified:**
- `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart` (added `fetchLeaderboard`/`loadLeaderboard`)
- `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart` (added `getFriendsLeaderboard`)
- `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart` (added `getFriendsLeaderboard`, new datasource constructor param)
- `pulse_coach/lib/features/social/friends/presentation/pages/social_page.dart` (4th tab, `TabController(length: 4)`, `BlocProvider<LeaderboardBloc>`)
- `pulse_coach/lib/l10n/app/app_it.arb`, `pulse_coach/lib/l10n/app/app_en.arb` (new `leaderboard*` keys)
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (extended with `loadLeaderboard` group)
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (extended with `getFriendsLeaderboard` group; added `MockLeaderboardRemoteDataSource`)
- `pulse_coach/test/widget/social_page_test.dart` (extended: `_FakeLeaderboardBloc`, `LeaderboardBloc` fake registration in all Pro-tier tests, new 21.2-WIDGET-005 test)

**Auto-regenerated (build_runner):**
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/entities/leaderboard_entry.freezed.dart`
- `pulse_coach/lib/features/social/leaderboard/presentation/bloc/leaderboard_state.freezed.dart`
- `pulse_coach/lib/l10n/app_localizations.dart`, `app_localizations_it.dart`, `app_localizations_en.dart` (gen_l10n, gitignored)
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.mocks.dart`, `leaderboard_remote_data_source_test.mocks.dart`
- `pulse_coach/test/domain/social/leaderboard/get_friends_leaderboard_use_case_test.mocks.dart`
- `pulse_coach/test/bloc/leaderboard_bloc_test.mocks.dart`

## Change Log

- 2026-07-04: Implemented Story 21.2 (friends-only leaderboard + rank freeze) — Tasks 1–9 complete, all ACs satisfied, 0 analyzer issues, 1305 passed/1 skipped (26 new tests, 0 regressions).
