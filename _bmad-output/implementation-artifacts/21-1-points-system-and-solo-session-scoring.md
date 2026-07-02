---
baseline_commit: beee4d5862475f6ccaa3c70ad4fc70cb7dac5600
---

# Story 21.1: Points System and Solo Session Scoring

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user,
I want to earn points for completing sessions so they appear on the leaderboard,
So that I have a low-pressure record of my activity relative to friends.

## Context

**Epic 21 — Leaderboard & Scoring (v2.5), second story.** Story 21.0 (`done`) closed the hard-block prerequisite: shared sessions now persist a local `SessionLog` and the current user's `@handle` resolves in the lobby. This story adds the **write path** only — a `leaderboard_entries` Supabase table + scoring RPC, and the client hook that fires it when a **solo** session's RPE is submitted. It does **not** build the leaderboard viewing UI (Story 21.2) or the shared-session bonus (Story 21.3).

**E21-K1 fire-check confirmed (this story does NOT touch shared sessions' scoring):** per the Epic 21 Prerequisites note, Story 21.3 awards shared-session points via a **server-side Edge Function** reading a signal that doesn't exist yet. If this story's client-side write also fired for shared sessions, 21.3 would double-award or need to distinguish/undo this story's entries later. **This story's write path is explicitly solo-only** — gated on `RpeSubmitArgs.planId != null` (see Task 3).

### What already exists (DO NOT REBUILD)

- **`RpeSubmitArgs`** (`lib/features/session/domain/entities/rpe_submit_args.dart`) already carries everything the points formula needs, for both solo and shared sessions: `armKey` (`'{sessionType}_{low|medium|high}'`), `durationMinutes`, `planId` (non-null only for solo), `abandoned`.
- **Intensity bucketing** is `low`/`medium`/`high` (int intensity 1–10 → bucket, see `in_session_page.dart:150` and `shared_session_bloc.dart:441`), **not** epics.md's literal `minimal`/`low`/`moderate` wording — see the "Resolved Ambiguity" note below.
- **`SyncManager`** (`lib/core/sync/sync_manager.dart`, `@singleton`) is fully built — `enqueue(eventType, payloadJson)`, opportunistic drain when online, exponential backoff, dead-letter after 10 attempts — but **`registerHandler` has never been called anywhere in the codebase**. This story is the **first real consumer**. `enqueue()` already attempts an immediate drain if online (`_isOnline` check → `processQueue()`), so routing every award through `enqueue()` (never a separate "try direct, then queue on failure" branch) satisfies both AC1 (online → looks instant) and AC3 (offline → replays on reconnect) with **one code path**. Started in `main.dart:50` (`getIt<SyncManager>().start()`); handlers must be registered **before** that call.
- **`EntitlementGate`** (`lib/core/cloud/entitlement_gate.dart`, `@singleton`) exposes `currentTier` (`SubscriptionTier.accountFree|signedInFree|pro`, synchronous, cached). `Feature.leaderboardScore` already exists in `lib/features/subscription/domain/entities/feature.dart` but is **never referenced anywhere** — `EntitlementGate.check(Feature)` is a stub that ignores its argument. **Do not build a new Feature→tier mapping table** (no such thing exists for any other social feature either — gating today is done ad hoc at call sites, e.g. `social_page.dart` checking `currentTier` directly). Just read `_entitlementGate.currentTier == SubscriptionTier.pro` directly (PRD FR62: "creating social content... scoring participation is Pro").
- **`feed_remote_data_source.dart`** is the exact pattern to mirror for a new Supabase remote datasource: `@injectable`, constructor takes `SupabaseClientProvider`, public methods delegate to `@visibleForTesting late Future<...> Function(...)` fields (so tests override the field, no `SupabaseClient` mocking needed) initialized in the constructor.
- **`0005_activity_feed.sql`** is the exact migration pattern to mirror: RLS `SELECT` policy scoped to self + accepted friendships (`friendships.status = 'accepted'`, `requester_id`/`addressee_id`), and a `SECURITY DEFINER` RPC (`increment_feed_reaction`) for a write that must not trust a client-computed value.
- **`PostRpeAdaptationCubit`** (`lib/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart`) and `WearBridgeService.sendEndMessage()` are the two existing patterns for "fire a side effect from the RPE-submitted listener in `rpe_page.dart`, without blocking navigation to the summary screen." This story's points award follows the simpler `WearBridgeService` shape (`unawaited(...)` call directly in the listener) — no new Cubit needed, since the Social tab (not this screen) is the only place points are ever displayed (AC4), so there is no local state to react to.

### Resolved Ambiguity — Intensity Weight Bucket Names

Epics.md's FR74 AC literally says `minimal=1, low=1.5, moderate=2`, but this codebase's only intensity vocabulary is the 3-bucket `low`/`medium`/`high` embedded in every `armKey` (`_intensityName()` in both `in_session_page.dart` and `shared_session_bloc.dart`, and the `intensityLow`/`intensityMedium`/`intensityHigh` ARB keys). There is no 4th bucket and no `minimal`/`moderate` vocabulary anywhere in code. **Decision: map by ordinal position, not by name** — `low → 1.0`, `medium → 1.5`, `high → 2.0`. This preserves the exact weight progression the epic specifies while reusing the existing bucket names. Implement as `ScoringConstants.intensityWeightFor(armKey)` keyed on the `armKey` suffix (`_low`/`_medium`/`_high`).

### Resolved Ambiguity — Where "the session is saved to drift" Fires From

AC1 says the upsert fires "when the session is saved to drift." The actual solo-session write sequence is: `InSessionCubit._persistCompletion()` writes the `SessionLogs` row (no `armKey`/`durationMinutes`/`intensity` available there — those live on the in-memory `PlannedSession`, not persisted denormalized for solo sessions) → user navigates to `RpePage` → `RpeFeedbackCubit._persist()` submits RPE and resolves the existing log's id via `_resolveSessionLogId()`. **The points formula's inputs (`armKey`, `durationMinutes`) are only available together, for both solo and shared sessions uniformly, in `RpeSubmitArgs`** — passed into `RpePage` as nav `extra`. Hooking here (RPE submission, not raw completion) is therefore both the pragmatic and the architecturally consistent choice (mirrors `PostRpeAdaptationCubit`'s bandit-reward hook, which fires from the exact same listener for the exact same reason). Awarding at RPE-submit time, not raw completion time, is an intentional interpretation of AC1 — flag if product disagrees, but do not attempt to move this into `InSessionCubit` (which lacks `armKey`/duration entirely for solo sessions).

### Resolved Ambiguity — Daily Points Cap Value

No numeric cap value exists anywhere in the PRD/epics/addendum (`addendum.md:13`: "anti-abuse rules TBD downstream"). **Decision: 200 points/day**, comfortably above a legitimate max day (`SafetyConstraints.maxSessionCount` caps at 3 sessions/day; 3 × ~30 min × 2.0 high-intensity weight = 180) while still bounding volume-gaming. This is a single named constant (`ScoringConstants.dailyPointsCap` client-side, `v_daily_cap` in the RPC — **keep both in sync**, referenced in both places via a comment) and should be treated as PM-tunable, not load-bearing logic.

### Resolved Ambiguity — Cap Enforcement Location (server-side, not client-side)

Architecture rule (`architecture.md` v2 Enforcement Guidelines #10): "Enforce visibility via RLS at the DB; client checks are convenience only, never the security boundary." A client-only cap check could be bypassed by a modified client calling the REST API directly. **The per-day cap is enforced inside a `SECURITY DEFINER` Postgres function** (`award_session_points`) that sums the caller's own already-awarded points for the day and clamps the new award — the client-supplied `base_points` value is never inserted verbatim. There is **no direct client `INSERT` policy** on `leaderboard_entries` — all writes go through the RPC.

## Acceptance Criteria

**AC1 — Solo session completion awards points:**
Given a user completes a solo session (not abandoned, `RpeSubmitArgs.planId != null`)
When RPE is submitted and `RpeFeedbackCubit` successfully resolves a non-null `sessionLogId`
Then the app calls Supabase RPC `award_session_points` with `base_points = round(durationMinutes * intensityWeight(armKey))` where `intensityWeight` is `low=1.0, medium=1.5, high=2.0`; on success a `leaderboard_entries` row exists for that session, owned by the current user.

**AC2 — Per-day cap enforced server-side:**
Given a user has already been awarded `N` points today (UTC calendar day) via `leaderboard_entries`
When a new award would push the cumulative total for that day above 200
Then the RPC clamps the newly-inserted row's `points` to `max(0, 200 - N)` — never more — regardless of the `base_points` value the client sent.

**AC3 — Offline-safe via the existing sync queue:**
Given the points award is attempted while offline (or the RPC call throws for any reason)
When `SyncManager.enqueue('leaderboard_points_award', payload)` is called
Then the write is queued in `sync_queue` and is **not lost**; when connectivity returns, `SyncManager`'s existing connectivity-change listener drains the queue and the registered handler retries the RPC call — no story-specific retry logic is written (reuse `SyncManager` verbatim, per ARCH26).

**AC4 — Scoring is Social-tab-only, invisible elsewhere:**
Given any screen other than the Social tab (Today, Sessions, Progress, In-Session, RPE, Mini-Summary)
When that screen renders
Then it shows no points total, points delta, toast, or rank number — this story adds **zero new UI**; the only observable surface is the (pre-existing, no-op-until-now) Social tab, unaffected by this story until Story 21.2 builds the leaderboard view. This AC is satisfied by *not adding any UI* — do not add a confirmation toast or SnackBar for a successful award.

**AC5 — Solo-only; never fires for shared sessions:**
Given `RpeSubmitArgs.planId == null` (a shared session, per Story 21.0)
When RPE is submitted
Then `award_session_points` is never called (guarded before any network attempt) — shared-session scoring is Story 21.3's server-side responsibility, not this story's.

**AC6 — Pro-gated; never fires for non-Pro users:**
Given `EntitlementGate.currentTier != SubscriptionTier.pro`
When a solo session's RPE is submitted
Then no `SyncManager.enqueue` call happens for the points award (checked before enqueueing, so account-free/signed-in-free users never even queue a doomed write) — per PRD FR62, scoring participation is a Pro feature.

**AC7 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all pre-existing tests pass (baseline: confirm exact count via `flutter test` before starting — 1259 recorded at Story 21.0 close) plus all new tests pass; analyzer reports 0 issues.

## Tasks / Subtasks

---

### Task 1 — Supabase migration: `leaderboard_entries` table + scoring RPC (AC1, AC2)

- [x] **1.1** Create `supabase/migrations/0011_leaderboard.sql` (next sequence number after `0010_shared_sessions_public_read.sql`):

  ```sql
  -- Leaderboard points ledger. Rows are written exclusively via the
  -- award_session_points RPC below — there is no direct client INSERT policy,
  -- because the per-day cap (UX-DR31 anti-gaming guardrail) must be enforced
  -- server-side, not trusted from a client-computed value (ARCH v2 rule #10).
  CREATE TABLE leaderboard_entries (
    id             uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id       uuid        NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    session_log_id text        NOT NULL, -- client-side SessionLog.id (local int, stringified) — idempotency key, not an FK (session_logs is a local-only drift table)
    points         int         NOT NULL,
    awarded_on     date        NOT NULL, -- UTC calendar day used for the daily cap sum
    created_at     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (owner_id, session_log_id)
  );

  ALTER TABLE leaderboard_entries ENABLE ROW LEVEL SECURITY;

  -- Friends-only visibility, identical shape to activity_feed's policy
  -- (0005_activity_feed.sql) — reused here even though Story 21.2 (the
  -- viewing UI) hasn't landed yet, so the RLS story is complete in one place.
  CREATE POLICY "leaderboard_select_self_and_friends"
    ON leaderboard_entries FOR SELECT
    USING (
      auth.uid() = owner_id
      OR EXISTS (
        SELECT 1 FROM friendships f
        WHERE f.status = 'accepted'
          AND (
            (f.requester_id = auth.uid() AND f.addressee_id = leaderboard_entries.owner_id)
            OR (f.addressee_id = auth.uid() AND f.requester_id = leaderboard_entries.owner_id)
          )
      )
    );

  -- No INSERT/UPDATE/DELETE policy for clients on purpose — all writes go
  -- through this SECURITY DEFINER function, which enforces the per-day cap
  -- (v_daily_cap) regardless of the caller-supplied p_base_points. Keep
  -- v_daily_cap in sync with ScoringConstants.dailyPointsCap (Dart, Task 2).
  CREATE OR REPLACE FUNCTION award_session_points(
    p_session_log_id text,
    p_base_points int,
    p_awarded_on date
  ) RETURNS int LANGUAGE plpgsql SECURITY DEFINER AS $$
  DECLARE
    v_owner uuid := auth.uid();
    v_already_awarded int;
    v_daily_cap CONSTANT int := 200;
    v_awarded int;
  BEGIN
    IF v_owner IS NULL THEN
      RAISE EXCEPTION 'not authenticated';
    END IF;

    -- Idempotent no-op on replay (offline queue may call this more than once
    -- for the same session_log_id if a prior attempt's queue-entry deletion
    -- raced with a retry — see SyncManager.processQueue).
    IF EXISTS (
      SELECT 1 FROM leaderboard_entries
      WHERE owner_id = v_owner AND session_log_id = p_session_log_id
    ) THEN
      RETURN 0;
    END IF;

    SELECT COALESCE(SUM(points), 0) INTO v_already_awarded
    FROM leaderboard_entries
    WHERE owner_id = v_owner AND awarded_on = p_awarded_on;

    v_awarded := GREATEST(0, LEAST(p_base_points, v_daily_cap - v_already_awarded));

    INSERT INTO leaderboard_entries (owner_id, session_log_id, points, awarded_on)
    VALUES (v_owner, p_session_log_id, v_awarded, p_awarded_on)
    ON CONFLICT (owner_id, session_log_id) DO NOTHING;

    RETURN v_awarded;
  END;
  $$;
  ```

- [x] **1.2** Note: this migration only needs to be applied to the local/dev Supabase project (`supabase migration up` / `supabase db push` per the team's existing workflow) — do not attempt to run it as part of `flutter test`; no Dart test talks to a real Supabase instance (see Task 5, mocking pattern).

---

### Task 2 — `ScoringConstants`: pure-Dart weight + cap constants (AC1, AC2)

- [x] **2.1** Create `pulse_coach/lib/features/social/leaderboard/domain/scoring_constants.dart`:

  ```dart
  /// Points-system constants for solo session scoring (Story 21.1, FR74).
  ///
  /// `dailyPointsCap` MUST match `v_daily_cap` in
  /// supabase/migrations/0011_leaderboard.sql — the Postgres value is the
  /// real enforcement point (server-side, per ARCH v2 rule #10); this
  /// constant only lets the client display/reason about the same number
  /// later (Story 21.2) without a second source of truth drifting apart.
  class ScoringConstants {
    const ScoringConstants._();

    static const int dailyPointsCap = 200;

    /// Maps an `armKey` (`'{sessionType}_{low|medium|high}'`) to its point
    /// weight. Bucket names come from the codebase's existing intensity
    /// vocabulary (`_intensityName()` in `in_session_page.dart` /
    /// `shared_session_bloc.dart`), not epics.md's literal
    /// minimal/low/moderate wording — mapped by ordinal position to
    /// preserve the specified 1 / 1.5 / 2 progression.
    static double intensityWeightFor(String armKey) {
      if (armKey.endsWith('_low')) return 1.0;
      if (armKey.endsWith('_medium')) return 1.5;
      return 2.0; // '_high'
    }
  }
  ```

- [x] **2.2** Test: `test/domain/social/leaderboard/scoring_constants_test.dart` — pure-Dart, no mocks:
  ```
  [21.1-SCORE-001] intensityWeightFor('mobility_low') == 1.0
  [21.1-SCORE-002] intensityWeightFor('cardio_medium') == 1.5
  [21.1-SCORE-003] intensityWeightFor('breathing_high') == 2.0
  ```

---

### Task 3 — `LeaderboardRemoteDataSource` + `LeaderboardRepository` (AC1, AC2, AC3)

- [x] **3.1** Create `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart`, mirroring `feed_remote_data_source.dart`'s `@visibleForTesting` function-field pattern exactly:

  ```dart
  import 'dart:convert';

  import 'package:dartz/dartz.dart';
  import 'package:flutter/foundation.dart' show visibleForTesting;
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/cloud/supabase_client.dart'
      show SupabaseClientProvider;
  import 'package:pulse_coach/core/error/failures.dart';

  @injectable
  class LeaderboardRemoteDataSource {
    /// SyncManager event type this datasource's [replayAward] is registered
    /// under (main.dart, before SyncManager.start()).
    static const String awardEventType = 'leaderboard_points_award';

    final SupabaseClientProvider _supabase;

    LeaderboardRemoteDataSource(this._supabase) {
      callAwardRpc = _defaultCallAwardRpc;
    }

    @visibleForTesting
    late Future<void> Function(
      String sessionLogId,
      int basePoints,
      String awardedOnIso,
    )
    callAwardRpc;

    Future<void> _defaultCallAwardRpc(
      String sessionLogId,
      int basePoints,
      String awardedOnIso,
    ) async {
      await _supabase.client.rpc(
        'award_session_points',
        params: {
          'p_session_log_id': sessionLogId,
          'p_base_points': basePoints,
          'p_awarded_on': awardedOnIso,
        },
      );
    }

    Future<void> awardPoints({
      required String sessionLogId,
      required int basePoints,
      required String awardedOnIso,
    }) => callAwardRpc(sessionLogId, basePoints, awardedOnIso);

    /// Registered with [SyncManager.registerHandler] under [awardEventType].
    /// Decodes the JSON payload built by [LeaderboardRepositoryImpl] and
    /// replays the same RPC call — this is the ONLY retry path; SyncManager
    /// owns backoff/dead-lettering, this method just attempts once per call.
    Future<Either<Failure, Unit>> replayAward(String payload) async {
      try {
        final map = jsonDecode(payload) as Map<String, dynamic>;
        await callAwardRpc(
          map['sessionLogId'] as String,
          map['basePoints'] as int,
          map['awardedOn'] as String,
        );
        return const Right(unit);
      } catch (e) {
        return Left(ServerFailure('award_session_points RPC failed: $e'));
      }
    }
  }
  ```

  **Critical — `p_awarded_on` is a plain `'YYYY-MM-DD'` string, not ISO-datetime:** Postgres `date` params accept `'YYYY-MM-DD'` directly over PostgREST/RPC JSON; do not pass a full `toIso8601String()` (which includes a time component and `Z` suffix).

- [x] **3.2** Create `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart`:
  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:pulse_coach/core/error/failures.dart';

  abstract class LeaderboardRepository {
    Future<Either<Failure, Unit>> awardSessionPoints({
      required int sessionLogId,
      required int basePoints,
      required DateTime awardedOnUtc,
    });
  }
  ```

- [x] **3.3** Create `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart`:
  ```dart
  import 'dart:convert';

  import 'package:dartz/dartz.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/core/sync/sync_manager.dart';
  import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';

  @Injectable(as: LeaderboardRepository)
  class LeaderboardRepositoryImpl implements LeaderboardRepository {
    final SyncManager _syncManager;

    const LeaderboardRepositoryImpl(this._syncManager);

    @override
    Future<Either<Failure, Unit>> awardSessionPoints({
      required int sessionLogId,
      required int basePoints,
      required DateTime awardedOnUtc,
    }) async {
      try {
        final awardedOn = awardedOnUtc.toIso8601String().substring(0, 10);
        final payload = jsonEncode({
          'sessionLogId': sessionLogId.toString(),
          'basePoints': basePoints,
          'awardedOn': awardedOn,
        });
        // Always enqueue (never call the RPC directly here): enqueue()
        // opportunistically drains immediately when online, so this single
        // path covers both the "online, looks instant" case (AC1) and the
        // "offline, replays later" case (AC3) — see SyncManager.enqueue.
        await _syncManager.enqueue(
          LeaderboardRemoteDataSource.awardEventType,
          payload,
        );
        return const Right(unit);
      } catch (e) {
        return Left(SocialFailure('Failed to enqueue points award: $e'));
      }
    }
  }
  ```

  **Critical — do NOT call `LeaderboardRemoteDataSource` directly from this repository.** Routing exclusively through `SyncManager.enqueue` is the whole design: one code path handles online + offline, and `LeaderboardRemoteDataSource.replayAward` (Task 3.1) is the only place the RPC is actually invoked, registered once in `main.dart` (Task 4).

---

### Task 4 — `AwardSessionPointsUseCase` + wiring into the RPE-submit listener (AC1, AC4, AC5, AC6)

- [x] **4.1** Create `pulse_coach/lib/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart`:
  ```dart
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/cloud/entitlement_gate.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/repositories/leaderboard_repository.dart';
  import 'package:pulse_coach/features/social/leaderboard/domain/scoring_constants.dart';
  import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';

  @injectable
  class AwardSessionPointsUseCase {
    final LeaderboardRepository _repository;
    final EntitlementGate _entitlementGate;

    AwardSessionPointsUseCase(this._repository, this._entitlementGate);

    /// No-op (never enqueues) for shared sessions, non-Pro users, or a
    /// zero/negative computed award — call sites do not need to pre-check
    /// these; this is the single guard point (AC5, AC6).
    Future<void> call({
      required int sessionLogId,
      required String armKey,
      required int durationMinutes,
    }) async {
      if (_entitlementGate.currentTier != SubscriptionTier.pro) return;
      final weight = ScoringConstants.intensityWeightFor(armKey);
      final basePoints = (durationMinutes * weight).round();
      if (basePoints <= 0) return;
      await _repository.awardSessionPoints(
        sessionLogId: sessionLogId,
        basePoints: basePoints,
        awardedOnUtc: DateTime.now().toUtc(),
      );
    }
  }
  ```

  **Note on `awardedOnUtc: DateTime.now().toUtc()`:** the exact `SessionLog.completedAt` (session-completion timestamp) is not surfaced past `RpeFeedbackCubit._resolveSessionLogId()` — only the resolved `sessionLogId` int is. Using "now" (RPE-submission time) as a proxy for the calendar day is a deliberate simplification: session completion and RPE submission happen seconds apart in the same flow, so the only divergence is a session finishing in the last seconds before UTC midnight — negligible for a daily-cap heuristic. Do not add a DAO round-trip to fetch the log's `completedAt` just for this.

- [x] **4.2** Edit `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_state.dart` — add `sessionLogId` to `RpeFeedbackSubmitted` (the page needs it to call the use case):
  ```dart
  class RpeFeedbackSubmitted extends RpeFeedbackState {
    final int rpeValue;
    final int? sessionLogId;

    const RpeFeedbackSubmitted({required this.rpeValue, this.sessionLogId});
  }
  ```

- [x] **4.3** Edit `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart` — pass the already-resolved `resolvedLogId` through (no new DAO calls):
  ```dart
  final resolvedLogId = await _resolveSessionLogId();
  // ... unchanged insertFeedbackIdempotent call using resolvedLogId ...
  if (!isClosed) {
    emit(RpeFeedbackSubmitted(rpeValue: rpe, sessionLogId: resolvedLogId));
  }
  ```

- [x] **4.4** Edit `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart` — in the existing `BlocListener<RpeFeedbackCubit, RpeFeedbackState>` on `RpeFeedbackSubmitted` (the same listener that calls `_adaptationCubit?.triggerUpdate(...)` and `WearBridgeService.sendEndMessage()`), add:
  ```dart
  final args = widget.args;
  if (args != null && args.planId != null && !args.abandoned) {
    final logId = submitted.sessionLogId;
    if (logId != null) {
      unawaited(
        getIt<AwardSessionPointsUseCase>().call(
          sessionLogId: logId,
          armKey: args.armKey,
          durationMinutes: args.durationMinutes,
        ),
      );
    }
  }
  ```
  Place this alongside the existing `_adaptationCubit?.triggerUpdate(...)` call, before `context.go(AppRouter.sessionSummary, ...)` — it must not block navigation (fire-and-forget, matches the existing `unawaited(...sendEndMessage())` pattern immediately below it).

  **Critical — `args.planId != null` is the AC5 guard (solo-only).** Shared sessions always pass `planId: null` (Story 20.4/20.5/21.0 convention, confirmed in `shared_session_lobby_page.dart`). Do not use `args.armKey.isNotEmpty` or any other proxy — `planId` is the one field that reliably distinguishes solo from shared.

  Add the import: `import 'package:pulse_coach/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart';`

---

### Task 5 — Register the SyncManager handler at boot (AC3)

- [x] **5.1** Edit `pulse_coach/lib/main.dart` — register the handler **before** `SyncManager.start()`:
  ```dart
  try {
    await configureDependencies();
    getIt<SyncManager>().registerHandler(
      LeaderboardRemoteDataSource.awardEventType,
      getIt<LeaderboardRemoteDataSource>().replayAward,
    );
    unawaited(getIt<SyncManager>().start());
  } catch (e, st) {
    // ... unchanged ...
  }
  ```
  Add the import: `import 'package:pulse_coach/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart';`

  **Critical — ordering matters.** `SyncManager.start()` may call `processQueue()` synchronously if online (line 117 of `sync_manager.dart`); if the handler isn't registered yet, any pre-existing queued entry from a prior app session would log "no handler" and stay queued instead of draining — registering first avoids this race entirely.

---

### Task 6 — Regenerate DI (AC7)

- [x] **6.1** From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected: `lib/core/di/injection.config.dart` gains factory registrations for `LeaderboardRemoteDataSource` (`@injectable`), `LeaderboardRepositoryImpl` (`@Injectable(as: LeaderboardRepository)`), `AwardSessionPointsUseCase` (`@injectable`). No `.g.dart`/`.freezed.dart` changes expected (no new Drift tables, no new freezed classes).

---

### Task 7 — Tests (AC1–AC7)

- [x] **7.1** `test/domain/social/leaderboard/scoring_constants_test.dart` — see Task 2.2.

- [x] **7.2** `test/domain/social/leaderboard/award_session_points_use_case_test.dart` (mock `LeaderboardRepository` + `EntitlementGate`, no Supabase):
  ```
  [21.1-USECASE-001] tier == pro, armKey 'cardio_medium', duration 20 → repository.awardSessionPoints called with basePoints == 30 (20 * 1.5, rounded)
  [21.1-USECASE-002] tier == signedInFree → repository.awardSessionPoints NEVER called (AC6)
  [21.1-USECASE-003] tier == accountFree → repository.awardSessionPoints NEVER called (AC6)
  [21.1-USECASE-004] tier == pro, durationMinutes: 0 → basePoints computes to 0 → repository.awardSessionPoints NEVER called (degenerate-input guard)
  ```

- [x] **7.3** `test/data/social/leaderboard/leaderboard_repository_impl_test.dart` (mock `SyncManager`):
  ```
  [21.1-REPO-001] awardSessionPoints(...) → SyncManager.enqueue called once with eventType 'leaderboard_points_award' and a JSON payload containing sessionLogId (as string), basePoints, awardedOn ('YYYY-MM-DD' only, no time component)
  [21.1-REPO-002] SyncManager.enqueue throws → returns Left(SocialFailure)
  ```

- [x] **7.4** `test/data/social/leaderboard/leaderboard_remote_data_source_test.dart` (mirror `feed_remote_data_source_test.dart`'s `@visibleForTesting` override pattern — no `SupabaseClientProvider` mocking needed for `replayAward`):
  ```
  [21.1-DS-001] awardPoints(...) → callAwardRpc invoked with the exact (sessionLogId, basePoints, awardedOnIso) args
  [21.1-DS-002] replayAward('{"sessionLogId":"42","basePoints":30,"awardedOn":"2026-07-02"}') → callAwardRpc invoked with ('42', 30, '2026-07-02'); returns Right(unit)
  [21.1-DS-003] replayAward(...) where callAwardRpc throws → returns Left(ServerFailure)
  [21.1-DS-004] replayAward(malformed JSON) → returns Left(ServerFailure), does not throw
  ```

- [x] **7.5** `test/bloc/rpe_feedback_cubit_test.dart` — extend existing suite:
  ```
  [21.1-RPE-001] successful submit → RpeFeedbackSubmitted.sessionLogId equals the resolved log id (non-null, solo path)
  [21.1-RPE-002] successful submit, sessionLogsDao null (degraded mode) → RpeFeedbackSubmitted.sessionLogId is null
  ```

- [x] **7.6** `test/widget/rpe_page_test.dart` (**confirmed existing file** — extend it, do not create a new one; it already covers `9.1-PAGE-001`/`9.2-PAGE-002` and uses `tearDown(() { ... await getIt.reset(); })` + `getIt.registerSingleton<T>(...)` per-test, with a real in-memory `AppDatabase.forTesting(NativeDatabase.memory())`):
  ```
  [21.1-PAGE-001] solo args (planId: 1, abandoned: false), RPE submitted → AwardSessionPointsUseCase.call invoked with the resolved sessionLogId/armKey/durationMinutes (register a mock/fake AwardSessionPointsUseCase via getIt.registerSingleton in the test, same convention as the existing RpeFeedbackDao/UpdateBanditReward registrations)
  [21.1-PAGE-002] shared args (planId: null) → AwardSessionPointsUseCase.call NEVER invoked (AC5)
  [21.1-PAGE-003] abandoned: true → AwardSessionPointsUseCase.call NEVER invoked
  [21.1-PAGE-004] sessionLogId resolves to null (degraded mode — no SessionLogsDao registered) → AwardSessionPointsUseCase.call NEVER invoked (nothing to key the award on)
  ```
  Reuse the file's existing `_router()`/`_wrap()` helpers; only the `_args` constant needs per-test variants (`planId: null`, `abandoned: true`, etc.) — do not duplicate the router/navigation scaffolding.

- [x] **7.7** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; all pre-existing tests + all new tests pass.

---

## Dev Notes

### Why the RPE-submit Listener, Not a New Cubit

`PostRpeAdaptationCubit` exists because the bandit-reward update has observable async state worth exposing (`PostRpeAdaptationRunning`/`Done`/`Error`) — nothing currently reads it, but the shape was deliberate. Points awarding has **no UI to react to it at all** (AC4: never visible outside the Social tab), so introducing a Cubit here would be state machinery with no consumer — exactly the "no abstractions beyond what's needed" trap. `WearBridgeService.sendEndMessage()` is the closer precedent: a `unawaited()` fire-and-forget call directly in the listener.

### Why Always `enqueue()`, Never a Direct RPC Call from the Repository

`SyncManager.enqueue()` already probes connectivity and calls `processQueue()` immediately if online (`sync_manager.dart:44-48`). This means enqueue-always naturally satisfies both the "looks instant when online" AC1 and the "queued and replayed when offline" AC3 with a single code path, and reuses 100% of `SyncManager`'s existing backoff/dead-letter logic. Do not add a "try direct, catch, then enqueue" branch — it would duplicate retry semantics `SyncManager` already owns.

### `SyncManager.registerHandler` Has Zero Existing Callers

Grep confirms `registerHandler` is defined (`sync_manager.dart:30`) but invoked nowhere in the current codebase — `SyncManager` has been running since Epic 13 with an empty handler map, silently logging "no handler" for anything ever enqueued (nothing has been). This story is the first real integration. There is no existing "register all handlers" bootstrap function to extend — Task 5 adds the one-line registration directly in `main.dart`, which is the only place `SyncManager.start()` is called.

### `Feature.leaderboardScore` Exists but Is Deliberately Not Used Here

The enum value is a pre-placed hook (`feature.dart`) but `EntitlementGate.check(Feature)` is a stub returning the cached tier regardless of the argument — no Feature→minimum-tier mapping exists anywhere in the codebase for *any* feature (friends/feed/shared-session gating is all done ad hoc at call sites via `currentTier` directly, e.g. `social_page.dart`). Building a generic mapping table is out of scope for this story; `AwardSessionPointsUseCase` reads `currentTier == SubscriptionTier.pro` directly, consistent with every other existing gating call site.

### File Size Check

- `rpe_feedback_cubit.dart`: 111 → +~3 lines ≈ 114 lines.
- `rpe_feedback_state.dart`: 27 → +2 lines ≈ 29 lines.
- `rpe_page.dart`: 179 → +~12 lines ≈ 191 lines.
- `main.dart`: 69 → +~5 lines ≈ 74 lines.
- New `leaderboard/` files are all small (single-responsibility datasource/repository/use-case/constants), well under the 200–400 line guideline.

### Project Structure Notes

**New production files:**
- `supabase/migrations/0011_leaderboard.sql`
- `pulse_coach/lib/features/social/leaderboard/domain/scoring_constants.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart`
- `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart`
- `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart`

**Modified production files:**
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_state.dart` (`sessionLogId` on `RpeFeedbackSubmitted`)
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart` (pass `resolvedLogId` into the emitted state)
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart` (fire `AwardSessionPointsUseCase` from the existing RPE-submitted listener)
- `pulse_coach/lib/main.dart` (register the `SyncManager` handler before `.start()`)

**Auto-regenerated:**
- `pulse_coach/lib/core/di/injection.config.dart`

**New/modified test files:**
- `pulse_coach/test/domain/social/leaderboard/scoring_constants_test.dart`
- `pulse_coach/test/domain/social/leaderboard/award_session_points_use_case_test.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.dart`
- `pulse_coach/test/bloc/rpe_feedback_cubit_test.dart` (extended)
- `pulse_coach/test/widget/rpe_page_test.dart` (extended)

**Out of scope for this story (explicitly deferred):**
- Leaderboard viewing UI, medal glyphs, rank freeze in AtRisk/Recovering (Story 21.2).
- Shared-session point bonus + server-visible completion signal (Story 21.3).
- Any Feature→tier generic gating abstraction (not built anywhere yet; not this story's job to introduce it).

### References

- [Source: epics.md#Story 21.1 lines ~2771–2794 — full ACs, FR74, UX-DR31]
- [Source: epics.md#Epic 21 Prerequisites lines ~2742–2745 — 21.3's server-side dependency, hard-block already closed by 21.0]
- [Source: architecture.md v2 Enforcement Guidelines #10 — RLS at DB, client checks convenience-only]
- [Source: architecture.md "Format Patterns — v2" — Supabase naming conventions, RPC verb-phrase naming]
- [Source: prd.md FR62 — "scoring participation is Pro"]
- [Source: prd.md FR74/FR75 — points formula, shared-session bonus deferred to 21.3]
- [Source: addendum.md line 13 — anti-abuse rules "TBD downstream" (this story resolves the cap value)]
- [Source: lib/features/session/domain/entities/rpe_submit_args.dart — armKey/durationMinutes/planId/abandoned, the data contract this story consumes]
- [Source: lib/features/session/presentation/pages/in_session_page.dart:118-154 — armKey construction + `_intensityName` bucketing for solo sessions]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart:196,441-444 — identical armKey/`_intensityName` construction for shared sessions]
- [Source: lib/core/sync/sync_manager.dart — `enqueue`/`registerHandler`/`processQueue`, confirmed zero existing `registerHandler` callers]
- [Source: lib/core/cloud/entitlement_gate.dart — `currentTier`, `SubscriptionTier` enum]
- [Source: lib/features/subscription/domain/entities/feature.dart — `Feature.leaderboardScore` (unused placeholder)]
- [Source: lib/features/social/feed/data/datasources/feed_remote_data_source.dart — `@visibleForTesting` function-field mock pattern to mirror]
- [Source: lib/features/social/feed/data/repositories/feed_repository_impl.dart — Either<SocialFailure,Unit> repository pattern to mirror]
- [Source: supabase/migrations/0005_activity_feed.sql — RLS + SECURITY DEFINER RPC pattern to mirror]
- [Source: lib/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart — precedent for a single-shot side-effect triggered from the RPE-submitted listener]
- [Source: lib/features/session/presentation/pages/rpe_page.dart:99-124 — the exact listener this story extends]
- [Source: lib/main.dart:48-50 — SyncManager.start() call site, handler registration must precede it]
- [Source: _bmad-output/implementation-artifacts/21-0-shared-session-persistence-and-handle-wiring.md — prior story's `RpeSubmitArgs`/`RpeFeedbackCubit` context, confirms `planId == null` is the reliable solo/shared discriminator]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- Baseline `flutter test` run before starting: 1259 passed, 1 skipped — matches story's recorded baseline.
- `flutter analyze lib/ test/` initially reported 2 `comment_references` info issues (doc-comment `[SyncManager.registerHandler]` / `[LeaderboardRepositoryImpl]` links unresolved outside their libraries) — fixed by switching those doc-comment mentions to plain code-font backticks; final run: 0 issues.
- Final `flutter test` run: 1278 passed, 1 skipped (1259 baseline + 19 new tests), 0 failures.

### Completion Notes List

- Implemented the full write path per the story spec verbatim: `supabase/migrations/0011_leaderboard.sql` (leaderboard_entries table + `award_session_points` SECURITY DEFINER RPC with server-side daily cap enforcement), `ScoringConstants` (pure-Dart weight/cap constants), `LeaderboardRemoteDataSource` + `LeaderboardRepository`/`LeaderboardRepositoryImpl` (mirroring the `feed_remote_data_source.dart` `@visibleForTesting` function-field pattern; repository routes exclusively through `SyncManager.enqueue`), `AwardSessionPointsUseCase` (single guard point for AC5/AC6), and wiring into the RPE-submitted listener in `rpe_page.dart` (fire-and-forget, does not block navigation).
- Followed strict red-green-refactor for every Dart behavior change: `scoring_constants_test.dart`, `award_session_points_use_case_test.dart`, `leaderboard_repository_impl_test.dart`, `leaderboard_remote_data_source_test.dart` were all written and confirmed failing (compile error against not-yet-created production classes) before the corresponding production file was created. `rpe_feedback_state.dart`/`rpe_feedback_cubit.dart` (`sessionLogId` on `RpeFeedbackSubmitted`) and `rpe_page.dart` (use-case wiring) were each preceded by extended tests in `rpe_feedback_cubit_test.dart` and `rpe_page_test.dart`, confirmed RED, then made GREEN.
- `main.dart`'s handler registration (Task 5) and the SQL migration (Task 1) have no dedicated test coverage in this codebase's existing conventions (no `main_test.dart` exists anywhere in the repo; the migration's own note, subtask 1.2, states it is applied via the Supabase CLI workflow, not exercised by `flutter test`) — applied directly as pure wiring/infra changes, consistent with story guidance.
- `dart run build_runner build --delete-conflicting-outputs` regenerated `injection.config.dart` with factory registrations for `LeaderboardRemoteDataSource`, `LeaderboardRepositoryImpl` (as `LeaderboardRepository`), and `AwardSessionPointsUseCase`, plus the new mockito mock files for the added tests. No `.freezed.dart` changes were needed (no new freezed classes).
- All 7 Acceptance Criteria verified: AC1 (award RPC call with correct `base_points` formula), AC2 (server-side cap clamp in the RPC, no client-side enforcement), AC3 (always routes through `SyncManager.enqueue`, verified via `leaderboard_repository_impl_test.dart`), AC4 (zero new UI — no toast/SnackBar added), AC5 (`args.planId != null` guard in `rpe_page.dart`, covered by 21.1-PAGE-002), AC6 (Pro-tier guard in `AwardSessionPointsUseCase`, covered by 21.1-USECASE-002/003), AC7 (`flutter test` 1278/1278 passing, `flutter analyze lib/ test/` 0 issues).

### File List

**New production files:**
- `supabase/migrations/0011_leaderboard.sql`
- `pulse_coach/lib/features/social/leaderboard/domain/scoring_constants.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/repositories/leaderboard_repository.dart`
- `pulse_coach/lib/features/social/leaderboard/domain/usecases/award_session_points_use_case.dart`
- `pulse_coach/lib/features/social/leaderboard/data/datasources/leaderboard_remote_data_source.dart`
- `pulse_coach/lib/features/social/leaderboard/data/repositories/leaderboard_repository_impl.dart`

**Modified production files:**
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_state.dart`
- `pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart`
- `pulse_coach/lib/features/session/presentation/pages/rpe_page.dart`
- `pulse_coach/lib/main.dart`

**Auto-regenerated:**
- `pulse_coach/lib/core/di/injection.config.dart`

**New/modified test files:**
- `pulse_coach/test/domain/social/leaderboard/scoring_constants_test.dart`
- `pulse_coach/test/domain/social/leaderboard/award_session_points_use_case_test.dart`
- `pulse_coach/test/domain/social/leaderboard/award_session_points_use_case_test.mocks.dart` (generated)
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_repository_impl_test.mocks.dart` (generated)
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.dart`
- `pulse_coach/test/data/social/leaderboard/leaderboard_remote_data_source_test.mocks.dart` (generated)
- `pulse_coach/test/bloc/rpe_feedback_cubit_test.dart` (extended)
- `pulse_coach/test/widget/rpe_page_test.dart` (extended)

## Review Findings

_Code review 2026-07-02 (adversarial 3-layer: Blind Hunter + Edge Case Hunter + Acceptance Auditor). All 7 ACs pass; findings below are correctness/robustness issues beyond AC scope._

- [x] [Review][Patch] **Local-int `session_log_id` as cross-install/cross-device idempotency key → silent permanent 0-award** (was Decision → Patch) — `session_log_id` was the local Drift autoincrement id (stringified). The RPC treats `(owner_id, session_log_id)` as the idempotency key and `RETURN 0`s on `EXISTS`. After a reinstall / clear-data / DB reset the local counter restarts at 1, and on a second device it starts independently at 1 — so new sessions reused ids already present server-side, were treated as duplicate replays, and awarded nothing. **FIXED:** the client now namespaces the key with a stable per-install random id (`LeaderboardRepositoryImpl._installId()`, 128-bit `Random.secure()`, persisted in `SharedPreferences` under `leaderboard_install_id`) → `session_log_id = '{installId}:{localId}'`. Idempotent for replays within one install, globally unique across installs/devices. New test `21.1-REPO-003` asserts install-id stability. Raised by Blind + Edge (High). [supabase/migrations/0011_leaderboard.sql:8 · leaderboard_repository_impl.dart:28-37,50]
- [x] [Review][Patch] **Daily-cap SUM is read-then-insert with no lock → concurrent cross-device awards can exceed 200/day** (was Decision → Patch) — `v_already_awarded` was computed with a plain `SELECT SUM(...)` then clamped then inserted, no lock. Concurrent awards for different `session_log_id`s on the same UTC day (two devices, or a burst of queued offline drains across clients) each read the same pre-insert sum and each grant the full remaining headroom, overshooting `v_daily_cap`. **FIXED:** added `PERFORM pg_advisory_xact_lock(hashtextextended(v_owner::text, 0));` right after the auth check — serializes awards per owner for the transaction, without blocking other owners. Raised by Blind + Edge (Medium). [supabase/migrations/0011_leaderboard.sql:58-66]
- [x] [Review][Patch] **SECURITY DEFINER `award_session_points` missing `SET search_path` — regression against established hardening** — the function was `SECURITY DEFINER` without a pinned `search_path`, the exact issue `0006_activity_feed_reaction_hardening.sql` was created to close on `0005`'s RPC (and `0007`/`0008` both pin `SET search_path = public`). Object-shadowing / privilege-escalation vector (Supabase advisor "Function Search Path Mutable"). **FIXED:** added `SET search_path = public` to the function definition. Raised by Blind (High). [supabase/migrations/0011_leaderboard.sql:42-47] [supabase/migrations/0011_leaderboard.sql:42]
- [x] [Review][Defer] **EntitlementGate defaults to `accountFree` until first `refresh()` → genuine Pro user's award silently dropped (no queue entry, no retry) if RPE submitted before refresh on cold/offline start** — pre-existing gate-wide behavior, consistent with every other gating call site; the use case guards before `enqueue`, so nothing is queued. [core/cloud/entitlement_gate.dart:16,40 · award_session_points_use_case.dart:19] — deferred, pre-existing gate design (not introduced by this change)
- [x] [Review][Defer] **Solo `sessionLogId` can resolve null via cross-cubit write ordering → award skipped, no retry** — `InSessionCubit` owns the `SessionLog` write on a separate async path; if uncommitted when `_persist` runs, `getLogFor` returns null and the `if (logId != null)` guard skips the award. [rpe_feedback_cubit.dart:70-107 · rpe_page.dart:109-119] — deferred, best-effort-by-design (spec's degraded-mode null handling is intentional)
- [x] [Review][Defer] **Permanently-failing RPC (expired auth / RLS) retried 10× then dead-lettered → award lost silently** — inherent `SyncManager` behavior reused verbatim per ARCH26; no dead-letter table or user-visible signal. [core/sync/sync_manager.dart:154-166 · leaderboard_remote_data_source.dart:39-41] — deferred, reused infra (out of this story's scope)
- [x] [Review][Defer] **`intensityWeightFor` maps any unknown armKey suffix to the max weight 2.0 (wrong-direction default for an anti-gaming score)** — only `_low`/`_medium` are explicit; the `else` returns `_high`'s 2.0. Currently safe (all producers emit low/medium/high) and spec-sanctioned. [domain/scoring_constants.dart:19-23] — deferred, currently unreachable + spec-designed default

## Change Log

- 2026-07-02: Story 21.1 implemented — solo-session points award write path (Supabase migration, `ScoringConstants`, `LeaderboardRepository`/`LeaderboardRemoteDataSource`, `AwardSessionPointsUseCase`, RPE-submit listener wiring, `SyncManager` handler registration). All 7 tasks and 7 ACs complete; 19 new tests added (1278/1278 passing); `flutter analyze` 0 issues. Status → review.
- 2026-07-02: Code review (adversarial 3-layer). 3 patches applied: (1) install-namespaced idempotency key `'{installId}:{localId}'` via a per-install `SharedPreferences` random id — fixes cross-reinstall/second-device collision silently awarding 0; (2) `pg_advisory_xact_lock` per owner in the RPC — fixes the daily-cap read-then-insert race that could overshoot 200/day; (3) `SET search_path = public` on the SECURITY DEFINER function — closes the search_path-mutable vector, matching 0006/0007/0008 hardening. 4 items deferred (EntitlementGate pre-refresh, sessionLogId cross-cubit null, SyncManager dead-letter, weight default) — see `deferred-work.md`. `flutter analyze` 0 issues; `flutter test` 1279 passing, 1 skipped. Status → done.
