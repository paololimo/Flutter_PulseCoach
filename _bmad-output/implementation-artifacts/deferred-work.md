# Deferred Work

## Triage — Epic 22 pre-v3 consolidation (2026-07-07)

v1 is complete (Epic 22 closed). This is a non-destructive reconciliation pass over the deferral log: entries below are **retained verbatim as historical record**; this header records dispositions rather than deleting rows.

**Verified CLOSED against current code:**
- *"`weather_cache` table grows unbounded"* (from the 4-1 review) → **resolved.** `WeatherCacheDao.replaceCache` deletes-then-inserts inside a transaction (`weather_cache_dao.dart:23-29`); the single-entry cache never accumulates rows.

**Reconciled with the action-item ledger — formally KILLED (won't-do) at the Epic 17 kickoff triage (2026-06-22), so no longer actionable here:**
- *"AssetBundle JSON re-parsed on every `loadFallbackExercisesByType` call — memoize the decoded list"* (from the 6-2 review) = ledger **E6-T8**. Killed: premature optimization; no measured cold-start issue across 22 epics on the SM-A520F.
- *"Substring-matching false positives in `_deriveSessionType` / ExerciseDB remote mapping revisit"* (from the 6-1 review) = ledger **E6-T7**. Killed: heuristic mapping shipped through 22 epics with no reported defect; bundled fallback covers offline; no v2/v3 epic touches exercise mapping. Paolo-vetoable — reopen if a mapping defect is reported.
- *AI Decision Log query perf* = ledger **E14R-4a**. Killed: the Decision Log is a `kDebugMode`-only screen, never in the release path.

**New findings logged this session (NOT fixed — out of E22R-2's auth/social/leaderboard scope):**
- Raw `failure.message` / `e.toString()` still reaches the UI (English in both locales) at four non-scoped sites: `onboarding_page.dart:51`, `profile_page.dart:74`, `disclaimer_screen.dart:29` (all `OnboardingError.message`, fed by `CacheFailure(e.toString())` in `onboarding_repository_impl.dart`), and `rpe_page.dart:164` (`error.failure.message`). Same defect class as **E22R-2**; deferred to a future i18n pass under the standing Cat-B rule **E18R-CB2** (localized-IT on every backend-failure path). Per the Epic 22 retro Cat-B lesson, closing this systemic i18n debt in-session vs. storizing it is the Project Lead's call.

**Scope note:** the ~75 remaining entries are legitimately-deferred conditional code-review findings (triggers: measured perf, future schema change, a11y pass, RTL/locale unlock, etc.). They are intentionally retained and NOT force-closed.

---

## Deferred from: code review of story-21.1 (2026-07-02)

- EntitlementGate defaults to `accountFree` until first `refresh()` → a genuine Pro user's award is silently dropped (no queue entry, no retry) if RPE is submitted before `refresh()` populates the cache on a cold/offline start. **[Defer — pre-existing gate-wide behavior, consistent with every other gating call site; not introduced by this change.]** [core/cloud/entitlement_gate.dart:16,40 · award_session_points_use_case.dart:19]
- Solo `sessionLogId` can resolve null via cross-cubit write ordering (`InSessionCubit` writes the `SessionLog` on a separate async path) → award skipped with no retry. **[Defer — best-effort-by-design; spec's degraded-mode null handling is intentional.]** [rpe_feedback_cubit.dart:70-107 · rpe_page.dart:109-119]
- Permanently-failing RPC (expired auth / RLS denial) is retried 10× then dead-lettered → award lost silently, no dead-letter table or user signal. **[Defer — inherent `SyncManager` behavior reused verbatim per ARCH26; out of this story's scope.]** [core/sync/sync_manager.dart:154-166]
- `ScoringConstants.intensityWeightFor` maps any unknown armKey suffix to the max weight 2.0 (wrong-direction default for an anti-gaming score). **[Defer — currently unreachable (all producers emit low/medium/high) and spec-sanctioned `_high` default.]** [domain/scoring_constants.dart:19-23]

## Deferred from: code review of story-20.4 (2026-06-26)

- Host abandon is recorded identically to a completed session (`abandoned: false`) — same `sessionEnded` → RPE path serves both genuine completion and host abandon. **[Defer — spec AC8 prescribes `abandoned: false`; `planId: null` disables persistence/bandit so the flag has no consumer until Story 20.5.]** [shared_session_lobby_page.dart:54-68]
- `sessionEnded` reached while still in `lobby` (no `inSession` render) navigates to RPE with `durationMinutes: 0` for a session never run — `_lastSteps` is still `const []`. **[Defer — low-probability path; spec accepts "from last inSession snapshot".]** [shared_session_lobby_page.dart:54-68]
- Host `_ParticipantBadge` at `Positioned(top:16)` overlays full-screen `InSessionView` with no reserved space — may overlap its top content. **[Defer — visual only; 360×640 widget tests pass without exception; verify on device.]** [shared_session_lobby_page.dart:_buildHostView]
- `sharedSessionParticipantCount` has no plural handling → "1 partecipanti" / "1 participants". **[Defer — spec deliberately chose `{count}` String over ICU plural; Story 20.5 may upgrade.]** [app_it.arb/app_en.arb]
- AC6 haptic (`HapticFeedback.mediumImpact()`) fire is implemented in `didUpdateWidget` but not asserted by any test. **[Defer — coverage gap, not in Task 6 scope; static call hard to assert.]**
- AC7 follower `Timer.periodic(1s)` display tick is implemented but no test advances the clock to assert it. **[Defer — coverage gap, not in Task 6 scope.]**

## Deferred from: code review of story-18.3 (2026-06-24)

- `getFeed` `.limit(50)` has no pagination — beyond the 50 newest entries, a user's own older shared entries become invisible and un-revokable through the feed UI [pulse_coach/lib/features/social/feed/data/datasources/feed_remote_data_source.dart]. **[Product call — MVP/exam scope acceptable; revisit if feed volume grows.]**
- Inconsistent row-degradation: a malformed `completed_at`/`created_at` errors the whole feed rather than dropping one row — `DateTime.parse` runs in `FeedEntryDtoMapper.toDomain()`, outside the `_rowToDto` try/catch, so a bad timestamp throws past the per-row guard and is caught only by the outer `getFeed` catch [pulse_coach/lib/features/social/feed/data/models/feed_entry_dto.dart; feed_repository_impl.dart `_rowToDto`]. **[Low — server always emits valid ISO timestamps; harden the per-row guard if a serialization drift ever appears.]**
- `_shareEnabled` not re-checked against Pro status at share time — if the subscription lapses between toggling the share on and the `MiniSummaryFading` event, the share still fires for a now-non-Pro user [pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart]. **[Low — negligible real-world timing window.]**

## Deferred from: code review of story-18.0 (2026-06-23)

- Backup restore lacks a format-version guard and defensive parsing of legacy/malformed blobs — non-nullable casts (`as bool`/`as int`), `DateTime.parse`, and `snapshot[key] as List` throw on an absent/null key; deletes run before inserts in the restore transaction, so a malformed or pre-schema backup can wipe the DB then abort mid-restore [pulse_coach/lib/features/auth/data/datasources/backup_local_data_source.dart:restoreDriftSnapshot]. **[KEEP — pre-existing; this story only added the nullable `installCohort` field (backward-compat confirmed by 16.3-DS-005b). A defensive-parse + version-field hardening pass is a separate, broader change.]**
- Real Supabase `deleteAccount` path (`_defaultInvokeDeleteAccount`: `functions.invoke` + status≠200 throw) has no direct test — 18.0-DS-001/002 override both seams, so the shipped status-check branch is uncovered [pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart:_defaultInvokeDeleteAccount]. **[KEEP — by-design seam pattern consistent with `cloudCohortReader/Writer`; the branch is a trivial status compare. Add a Supabase-functions integration test only if this path regresses.]**
- Account deleted server-side but local session retained if `performSignOut()` throws after a 200 — no rollback/retry of local sign-out [pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart:deleteAccount]. **[KEEP — pre-existing (identical to the pre-refactor code) and out of AC2 scope, which only governs the non-200 → no-signOut property.]**
- `signOut()` duplicates the `_defaultPerformSignOut` one-liner — two sources of truth that could silently drift [pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart:signOut]. **[KEEP — Low: both are a single `_supabase.client.auth.signOut()` call; cosmetic cleanup.]**

## Deferred from: code review of story-17.2 (2026-06-22)

- User-facing strings hardcoded as Italian literals bypass the gen_l10n/ARB pipeline — locked banner, ProUpsellSheet buttons/fact string, `Cronologia`/`Grafici` tab labels [pulse_coach/lib/features/progress/presentation/pages/progress_page.dart:108,143; pulse_coach/lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart]. **[KEEP — matches pre-existing ProgressPage style; spec mandated literal copy; app is locale-locked to `it`. Fold into the standing i18n/ARB debt (E7.5-T1), not a one-story fix.]**
- `ProgressGatingCubit` does not recover from a transient load error within a session — an entitled grandfathered user hitting a one-time DB read error is locked out until the cubit is rebuilt [pulse_coach/lib/features/progress/presentation/bloc/progress_gating_cubit.dart:18-20]. **[KEEP — Low: by-design "never grant on error" safe default; a single-row local read failing is low probability. Add a retry/refresh seam only if this regresses.]**
- Test SYNC-003 asserts only `result isA<Right>`, not the swallow path's actual effect on the local DB / that the cloud write was skipped [pulse_coach/test/features/auth/auth_repository_impl_sync_test.dart]. **[KEEP — Low test-quality follow-up; the meaningful behavior (sign-in still succeeds when cloud throws) is covered.]**

## Deferred from: code review of 16-4-in-app-account-deletion-and-data-export (2026-06-21)

- `delete_account_cascade` discards the `storage.remove` result entirely, swallowing all errors rather than only not-found [supabase/functions/delete_account_cascade/index.ts:19]. On a genuine storage failure the encrypted backup blob is orphaned. **[KEEP — Low: E2E-encrypted blob, key device-only, auth user (cascade root) still deleted. Block-on-error would contradict the spec author's explicit "ignore errors" decision and would let a transient storage outage block account deletion — needs a human design call before changing.]**
- No automated test asserts `signOut()` runs only after a 200 from the Edge Function (the AC2/AC4 "no partial state" safety property lives in the datasource and is untested) [pulse_coach/lib/features/auth/data/datasources/auth_remote_data_source.dart:71]. **[KEEP — Low: Task 9 only specified bloc/cubit tests; add a datasource test if this path regresses.]**
- New ARB keys `deleteAccountErrorGeneric`/`exportDataErrorGeneric` were added per the spec but are unused; SnackBars display the raw `Exception(...)` string instead [pulse_coach/lib/features/auth/presentation/pages/account_page.dart:34,45]. The `AuthError` listener is shared with sign-out, so the delete-specific generic copy cannot be cleanly wired there. **[KEEP — Low/cosmetic: raw-exception SnackBars are the app-wide convention; revisit as an app-wide error-copy pass, not a one-story fix.]**

## Deferred from: code review of 16-3-e2e-encrypted-backup-and-restore (2026-06-21)

- `exportDriftSnapshot` loads all backup tables fully into memory, JSON-encodes, AES-encrypts, then base64-encodes (~1.33x twice) in one shot [pulse_coach/lib/features/auth/data/datasources/backup_local_data_source.dart:16-39]. No streaming/chunking or size bound. **[KEEP — spec mandates a full-snapshot design and the dataset is bounded (30-day daily plans); re-evaluate if Supabase object-size limits or OOM become a real risk for heavy users]**

## Deferred from: code review of 13-3-data-persistence-guarantees (2026-06-04)

- Partial-v8 idempotency branch (`hasSessionLogId` already-present case in the `from < 8` rpe_feedback migration step) has zero coverage [pulse_coach/lib/core/database/app_database.dart]. PERSIST-006 exercises the table-exists-without-column path but not the already-migrated path. **[KEEP — out of this story's scope; re-evaluate when adding a dedicated partial-migration-edge test]**
- TTL tests 007–010 read live `DateTime.now()` at both insert and assert (no injected clock) [pulse_coach/test/core/database/data_persistence_test.dart:217-313]. **[KEEP — low flakiness risk given generous 30min/2h and 12h/26h margins; full fix needs clock injection]**

## Deferred from: code review of 13-1-offline-first-core-features (2026-06-04)

- Release `dev.log` branch in `AppLogger.error` (pulse_coach/lib/core/logging/app_logger.dart:78) is structurally untestable under the debug `flutter test` harness (`kReleaseMode == false`). `13.1-E10R1-001` verifies the `debugSink` seam (`level == 1000`), not the real release path. Consider renaming/commenting the test so it does not overclaim "release-level" verification. **[KEEP — test-harness limitation; re-evaluate if a release-mode integration check or platform-log assertion becomes feasible]**
- AC1's "RPE history" generation input is not exercised by the offline suite — the AI engine is mocked, so RPE-history reads inside generation are bypassed. Any real coverage lives in the existing `generate_daily_plan` tests. **[KEEP — pre-existing / out of suite scope; re-evaluate when AI-engine generation is integration-tested end-to-end]**

## Deferred from: code review of 11-3-portrait-and-landscape-orientation-support (2026-05-29)

- `totalSteps == 0` → division-by-zero in `LinearProgressIndicator.value` `(currentStepIndex + 1) / totalSteps` plus `RangeError` on `currentStep` accessor [pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart; pulse_coach/lib/features/session/presentation/bloc/in_session_state.dart:27] **[KEEP — re-evaluate: if any plan source can yield an empty step list (`SessionStepGenerator` currently always returns 3); pre-existing, carried verbatim into both orientation branches]**
- HR badge `Positioned(top: 8, right: 8)` may overlap the vertically-centered content in very short landscape heights — no reserved gutter [pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart `_landscapeBody`] **[KEEP — re-evaluate: if HR overlap is observed on a real device in landscape]**
- No landscape widget test exercises a long `step.title`/`step.instruction` to validate the `maxLines`/overflow boundary; all fixtures use short strings [pulse_coach/test/widget/in_session_view_test.dart] **[KEEP — re-evaluate: when adding a long-content regression test or if title length grows]**
- Progress bar treats the current in-progress step as already complete via `(currentStepIndex + 1) / totalSteps` [pulse_coach/lib/features/session/presentation/widgets/in_session_view.dart] **[KEEP — pre-existing product-decision behavior, not introduced by this change]**

## Deferred from: code review of 9-3-bandit-reward-update-and-state-machine-re-evaluation (2026-05-22)

- `_parseState` is duplicated across three files (`update_bandit_reward.dart`, `daily_plan_bloc.dart`, `generate_daily_plan.dart`). Casing is mathematically safe today (all readers `.toLowerCase()` and pin `BehavioralState.name` round-trip via the new 9.3-UC-010 test), but a single shared helper would prevent future drift [pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart:213-219; pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:142-156; pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:330-338] **[KEEP — re-evaluate: any time a fourth consumer is added or `BehavioralState` gets a new value]**
- `_calculateStreak` and the missed-sessions date-window in `UpdateBanditReward` are timezone-naïve (local `DateTime.now()` + local-formatted `_dateStr`), duplicating the identical pre-existing pattern in `GenerateDailyPlan`. Crossing midnight / DST can off-by-one the streak and tip the `missed >= 2` rule. Fix must touch both call sites coherently [pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart:221-244; pulse_coach/lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:344-362] **[KEEP — re-evaluate: when timezone correctness becomes a measured bug, or as part of a Date/Time normalization pass]**
- `compute()` overhead vs O(1) bandit/state-machine work — isolate hop likely dominates the actual computation; AC4 still satisfied because work runs off the UI thread [pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart `_computeRewardUpdate`] **[KEEP — re-evaluate: when post-RPE latency becomes a measured problem]**
- Single `ServerFailure('bandit_reward_update_failed')` taxonomy collapses every failure mode; granular categories blocked until a UI consumer exists [pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart:138-148] **[KEEP — re-evaluate: when Decision-Needed "Surface PostRpeAdaptationError to UI?" is resolved]**
- `_kDummyProfile` in `_computeRewardUpdate` — `StateVector` is documented as profile-aware; current `BehavioralStateMachine` rules don't read profile so safe today, but adding any profile-keyed rule silently diverges the RPE-driven write from the plan-pipeline write [pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart:479-484] **[KEEP — re-evaluate: any time a `BehavioralStateMachine` rule starts reading `UserProfile`]**
- `PostRpeAdaptationCubit`'s `Either` channel doesn't cover synchronous throw before the first `await` in `_useCase.call` — hypothetical only with mocks; production use case is `async` and wraps its body in try/catch [pulse_coach/lib/features/session/presentation/bloc/post_rpe_adaptation_cubit.dart] **[KEEP — re-evaluate: if a mock-injection path is ever added]**
- `compute()` payload schema fragility on future `BanditState` changes — no serialization smoke test; a future non-transferable field would surface as opaque `ServerFailure` [pulse_coach/lib/features/session/domain/usecases/update_bandit_reward.dart `BanditRewardInput`/`BanditRewardOutput`] **[KEEP — re-evaluate: next time `BanditState` schema changes]**

## Deferred from: code review of 8-2-insessionview-timer-and-step-display (2026-05-17)

- Test suite uses `tester.pump(Duration)` instead of spec-mandated `fakeAsync` / `async.elapse(...)` — contradicts Story 8.2 Anti-Patterns table but tests pass and timer semantics are equivalent in the widget-test clock [pulse_coach/test/bloc/in_session_cubit_test.dart:14-89] **[KEEP — re-evaluate: next time cubit timer tests need maintenance]**
- `SessionStepGenerator` min-clamp can exceed `totalSeconds` for short sessions — `durationMinutes == 2` (120s) sums three `max(60, …)` clamps to 180s (50% over budget); acceptable for alpha [pulse_coach/lib/features/session/presentation/utils/session_step_generator.dart:14-18] **[KEEP — re-evaluate: before user-configurable durations land or in beta hardening]**
- Timer drift under Android Doze / app backgrounding — `Timer.periodic` does not survive backgrounding; NFR3 (±1s over full session) at risk on physical devices; mitigate with `DateTime.now()` anchor [pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart:35-37] **[KEEP — re-evaluate: Story 8.5 or a dedicated timer-anchoring story]**
- No `PopScope` / back-gesture guard in `InSessionPage` — system back swipe pops the route, dispose closes the cubit, no SessionLog is written, plan stays silently incomplete; reuse the Abandon confirmation Story 8.5 will add [pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:32-91] **[KEEP — re-evaluate: Story 8.5]**
- Service-locator inside widget — `getIt.isRegistered<SessionLogsDao>() ? getIt() : null` couples presentation to DI and complicates widget tests; consistent with existing codebase pattern [pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:36-45] **[KEEP — re-evaluate: broader DI cleanup]**
- `SessionStartArgs.sessionIndex` defaults to `0` — a forgotten parameter silently logs every session as index 0; make it `required` once all call sites pass it explicitly [pulse_coach/lib/features/session/domain/entities/session_start_args.dart:12] **[KEEP — re-evaluate: next time the route handoff is touched]**
- `_persistCompletion` swallows DAO failures via `debugPrint` — consistent with `TodaySessionCubit.markSessionCompleted`'s pattern, but no telemetry hook [pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart:75-77] **[KEEP — re-evaluate: project-wide observability work]**
- `insertLog` idempotency under replay — second completion of the same `(planId, sessionIndex)` may hit a UNIQUE constraint; current `catch` masks it; once `markSessionCompleted` wiring lands use `InsertMode.insertOrIgnore` [pulse_coach/lib/features/session/presentation/bloc/in_session_cubit.dart:67-74] **[KEEP — re-evaluate: when D1 decision is implemented]**
- `app_router.dart` fallback `extra as PlannedSession?` throws TypeError on unknown extra types (e.g. deep-link with `String`) — low risk in current navigation surface [pulse_coach/lib/core/routing/app_router.dart:73-82] **[KEEP — re-evaluate: when deep-link surface expands]**

## Deferred from: code review of 7.5-2-migrate-epic7-italian-strings-to-arb (2026-05-16)

- `BehavioralStateMachine` still hardcodes 6 Italian transition strings — the 7 `transition*` ARB keys added in Story 7.5.2 are currently unwired at the consumer side: `StateIndicator.transitionMessage` receives the raw literal from `BehavioralTransition`, never the ARB value. Explicitly out of scope per Story 7.5.2 spec but must be the next i18n follow-up to prevent the new keys from rotting [pulse_coach/lib/ai/state_machine/behavioral_state_machine.dart:35,44,53,68,81,94] **[KEEP — re-evaluate: next i18n story or before EN locale is enabled]**
- ARB invariant test `_stateMessagesArb()` reads via CWD-relative `File('lib/l10n/app/app_it.arb')` — fragile to invocation from outside `pulse_coach/`. Pre-existing hazard inherited from the old `state_messages.it.arb` path [pulse_coach/test/widget/state_indicator_test.dart] **[KEEP — re-evaluate: next time the test is touched]**
- Test `7.1-ARB-003` implicit scope creep — the loop now scans every user-facing value (semantic labels, headers, buttons), not just state-graph copy. Substring guards (`'active'`/`'fatigued'`/etc.) currently clean, but a future legitimate string containing `"active"` would fail spuriously [pulse_coach/test/widget/state_indicator_test.dart:237-257] **[KEEP — re-evaluate: when test 7.1-ARB-003 next needs a guard adjustment]**
- Hero card semantic label duplicate-period risk — when `session.explanation` ends with `.`, appending `'. ${l10n.heroCardSemanticCta}'` produces `..`. Pre-existing pattern; affects screen-reader output only [pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart] **[KEEP — re-evaluate: when explanation copy is finalized]**

## Deferred from: code review of 7-4-completionring-component-and-plan-regeneration (2026-05-16)

- `CompletionRing` drain animation when `total` shrinks mid-flight — if `didUpdateWidget` fires while the arc is animating (e.g. 2/3 tweening to 3/3 in flight, new plan emits 0/3), the arc visually drains from ~0.66 → 0.0 over 400ms while the text already reads "0/0". UX choice deferred: skip-on-total-change, skip-on-zero, or accept drain — needs visual verification on physical device during a real regenerate [pulse_coach/lib/features/today/presentation/widgets/completion_ring.dart:58-79] **[KEEP — re-evaluate: after manual regenerate test on Samsung A520F]**
- `_HeroZone` empty-sessions guard is unreachable dead code — `_buildLoaded` short-circuits to `_AllDoneWidget` when `total == 0 || allDone`, so the `SizedBox.shrink()` branch in `_HeroZone.build` is never hit. Pre-existing from Story 7.3 [pulse_coach/lib/features/today/presentation/pages/today_page.dart:192-194] **[KEEP — re-evaluate: next time `_HeroZone` is touched]**
- `_isSamePlan` collision risk — two distinct plans with identical `generatedAt` millisecond and same `sessions.length` won't trigger `planLoaded`, leaving `TodaySessionCubit` with stale completed indices. Exposed by the regenerate flow wired in Story 7.4 but the equality check itself is pre-existing from 7.3 [pulse_coach/lib/features/today/presentation/pages/today_page.dart:45-46] **[KEEP — re-evaluate: if regenerate UX regressions surface or in Story 8.x in-session flow]**

## Deferred from: code review of 7-0-failure-equality-bloc-regression (2026-05-15)

- Concurrent event race on `state` read in DailyPlanBloc — `on<GenerateRequested>` and `on<RegenerateRequested>` are separate handlers without a `transformer:`; if interleaved, the second handler reads `state == Loading` (not `Error`), resetting `retryAttempts` to 0 non-monotonically. Pre-existing BLoC handler pattern, not caused by Story 7.0 [pulse_coach/lib/features/daily_plan/presentation/bloc/daily_plan_bloc.dart:42, 71] **[KEEP — re-evaluate: when retry semantics become visible in UI (Story 7.1 StateIndicator)]**
- `Failure` equality vulnerable to intra-subclass field drift — `6.5-EQ-BLOC-003` locks cross-subclass distinction (CacheFailure vs ServerFailure), but a future `Failure` subclass adding fields (e.g., `statusCode`, `endpoint`) without overriding `==` would silently coalesce two semantically distinct failures. Pre-existing Story 6.5.3 design [pulse_coach/lib/core/error/failures.dart] **[KEEP — re-evaluate: next time a Failure subclass is added or modified]**

## Deferred from: code review of story-7.1b-pre (2026-05-15)

- Read-side query for `MissedSessionsCalculator` missing — `DailyPlansDao` exposes `markCompleted` (write side) but no `countUncompletedInRange` / `getPlansInRange`; `DailyPlanRepositoryImpl.getPlanForDate` rebuilds the domain entity from `planJson` only and discards the new `is_completed` column. Required for AC2–AC5 of story-7.1b but belongs to the main 7.1b story (where the calculator lives), not the pre-task [pulse_coach/lib/core/database/daos/daily_plans_dao.dart; pulse_coach/lib/features/daily_plan/data/repositories/daily_plan_repository_impl.dart:26-35] **[PROMOTE → Story 7.1b main]**
- v1 raw migration fixture in `app_database_test.dart` diverges from the real v1 schema (sessions/rpe_feedback/bandit_state/etc. omitted; comment claims "all v1 onCreate tables" but only `user_profile` and `daily_plans` are present). Pre-existing pattern, not caused by 7.1b-pre, but ongoing drift makes the migration test increasingly misleading [pulse_coach/test/core/database/app_database_test.dart:191-242] **[KEEP — re-evaluate: next time the migration test is touched, or before any v4→v5 migration]**

## Deferred from: code review of story-6.5.1 (2026-05-15)

- Tab-order ripple in `AppShell._currentIndex` fallback — fallback path `idx < 0 → 0` now lands unknown routes on Sessions (was Today). No current consumers, but audit analytics/deep-link/first-run telemetry when Epic 7 adds new routes outside `/today|/sessions|/progress` [pulse_coach/lib/shared/widgets/app_shell.dart:17-20] **[KEEP — re-evaluate: when Epic 7 adds routes outside /today|/sessions|/progress]**
- `Failure` subclasses lack `operator ==` — after const-promotion (`const CacheFailure(...)`, `const LocationFailure(...)`), two literally-equal failures share identity. Latent trap for any future code de-duping failures by reference. Recommend adding `Equatable` to `Failure` base before further `const` rollouts [pulse_coach/lib/core/error/failures.dart] **[PROMOTE → Story 6.5.3]**
- `plan()` helper shadowed by `fold` lambda param `(plan) {...}` at lines 48, 119, 130 — future edits intending to call the factory inside the closure will silently receive the bound `DailyPlan` value. Rename helper or lambda params [pulse_coach/test/features/daily_plan/daily_plan_repository_impl_test.dart:13] **[KEEP — re-evaluate: next time daily_plan_repository_impl_test.dart is edited]**
- `bloc()` helper shadowed by `blocTest`'s `act: (bloc) => …` param — same shadowing pattern as above [pulse_coach/test/bloc/daily_plan_bloc_test.dart:39] **[KEEP — re-evaluate: next time daily_plan_bloc_test.dart is edited]**

## Deferred from: code review round 2 of story 6-3-session-browsing-screen (2026-05-15)

- Cubit filter `.where((e) => e.sessionType == sessionType)` silently drops case/whitespace variants without telemetry [sessions_catalog_cubit.dart] **[CLOSE — addressed by Story 6.5.2 normalization in ExerciseLocalDataSource]**
- `Semantics` label "{n} minutes" is non-singular ("1 minutes") in `SessionCatalogCard` [session_catalog_card.dart] **[KEEP — re-evaluate: when accessibility audit is scheduled (pre-exam)]**
- `pumpPage` in widget tests does not `addTearDown(cubit.close)` — open cubit stream subscriptions leak per test [test/widget/sessions_page_test.dart] **[KEEP — re-evaluate: next time sessions_page_test.dart is modified]**
- `6.3-WIDGET-006` compares logical pixels (`tester.getRect`) to physical pixels (`tester.view.physicalSize`) — works at devicePixelRatio 1 but semantically wrong [test/widget/sessions_page_test.dart] **[KEEP — re-evaluate: if flaky test failures appear on non-1.0 DPR devices]**
- `AppTheme.lightTheme` uses `ThemeData().textTheme` (implicit-light) asymmetrically vs `ThemeData(brightness: Brightness.dark).textTheme` for dark [lib/core/theme/app_theme.dart] — theme-refactor scope, not story 6.3 **[KEEP — re-evaluate: when theme refactor epic is created]**

## Deferred from: code review of story 6-3-session-browsing-screen (2026-05-15)

- Concurrent `loadCatalog()` calls have no in-flight guard (no current retry path triggers it) [sessions_catalog_cubit.dart] **[KEEP — re-evaluate: if retry/refresh UX added in Epic 7]**
- Filter chip taps during the loading state are silently dropped [sessions_catalog_cubit.dart:selectCategory] **[KEEP — re-evaluate: when cubit receives external reload trigger]**
- `durationMinutes = 0` / negative displayed verbatim on card/sheet and Semantics label [session_catalog_card.dart, session_catalog_detail_sheet.dart] **[KEEP — re-evaluate: when UI validation is added in Epic 7 card design]**
- Empty `description` renders a zero-height blank in detail sheet [session_catalog_detail_sheet.dart] **[KEEP — re-evaluate: Epic 7 detail sheet implementation]**
- Richer Semantics: filter chips as radio group, category headers `header: true`, `ExcludeSemantics` for decorative difficulty dots [sessions_page.dart, session_catalog_card.dart] **[KEEP — re-evaluate: pre-exam accessibility audit]**
- Widget test 6.3-WIDGET-003 relies on sequential category-load ordering of the Cubit [test/widget/sessions_page_test.dart] **[KEEP — re-evaluate: if Cubit loading order changes]**
- `app_shell_test.dart` constructs a fresh `SessionsCatalogCubit` on each `GoRouter` navigation [test/widget/app_shell_test.dart] **[KEEP — re-evaluate: if lazySingleton lifecycle tests added]**
- 6.3-WIDGET-002 taps the "Cardio" chip without `ensureVisible` [test/widget/sessions_page_test.dart] **[KEEP — re-evaluate: if test becomes flaky on smaller virtual screens]**
- `groupedExercises` map reference is shared across emitted states (built mutably, exposed without defensive copy) [sessions_catalog_cubit.dart, sessions_catalog_state.dart] **[KEEP — re-evaluate: if state mutation bugs surface in Epic 7 interactions]**

## Deferred from: code review of story 6-1-exercisedb-api-integration-and-cache (2026-05-15)

- `getCachedExercisesByType` reads all rows and JSON-decodes them on every call; should query by an indexed `sessionType` column once the schema is reshaped in Story 6.2/6.3 [exercise_local_data_source.dart:21] **[KEEP — re-evaluate: when session load times are measured in Epic 7 integration tests]**
- Substring-matching false positives in `_deriveSessionType` / `_deriveCompatibility` (e.g. "running form drill" → cardio+outdoor; "pull up" vs ExerciseDB's "pull-up") [exercise_model.dart]; curated catalog in Story 6.2 supersedes the heuristics **[CLOSE — superseded by curated fallback catalog introduced in Story 6.2]**
- `_difficultyForIntensity` accepts out-of-range intensity silently (negative or >max) [generate_daily_plan.dart]; pre-existing **[KEEP — re-evaluate: Story 5.3 safety-rules integration test pass]**
- `_buildDescription` interpolates raw API strings into user-visible text without sanitization [exercise_model.dart]; hardening pass once UI consumes descriptions **[KEEP — re-evaluate: when UI renders description strings to users in Epic 7]**
- `developer.log(..., error: e)` for corrupt `BanditState` JSON may include user behavioral data in production logs [generate_daily_plan.dart:263-268]; pre-existing, outside Story 6.1 scope **[KEEP — re-evaluate: before production release / security audit]**
- Concurrent miss-and-refresh single-flight for `getExercisesByType` across types; subsumed by the planned single-`fetchAll()` patch **[CLOSE — subsumed by the `syncCatalog()` single-fetchAll patch in ExerciseRepositoryImpl]**
- Fallback `durationMinutes` not clamped at the `Exercise.fromJson` boundary; author-controlled JSON, revisit when Story 6.2 expands the fallback set **[KEEP — re-evaluate: when non-curated JSON entries are added]**
- `exerciseDbBaseUrl` has no env override [api_constants.dart]; project policy uses compile-time constants for v1 **[KEEP — re-evaluate: if staging/prod environment split needed before exam]**
- `_selectExerciseForSession` returns `candidates.first` and is non-deterministic in selection order [generate_daily_plan.dart]; marginal until Today UI is wired in Epic 7 **[KEEP — re-evaluate: Story 7.x Today screen wiring]**
- Stale cache served indefinitely without a freshness signal to UI [exercise_repository_impl.dart:106-125]; observability work, no UI consumer yet **[KEEP — re-evaluate: when cache-status UI is designed in Epic 7]**
- Test `6.1-UNIT-006` conflates "no session-type match" with "malformed" [exercise_remote_data_source_test.dart]; test quality, revisit with curated mapper in Story 6.2 **[KEEP — re-evaluate: when exercise mapper is rewritten for curated catalog]**
- Domain `Exercise` carries `toJson`/`fromJson` used as the cache schema [exercise.dart + exercise_local_data_source.dart]; architectural separation between domain entity and cache DTO **[KEEP — re-evaluate: when a separate CacheDto is warranted by schema divergence]**
- An `Exercise` with `indoorCompatible: false && outdoorCompatible: false` is not excluded on load [exercise.dart fromJson]; structurally unreachable from the remote mapper, defend in depth later **[CLOSE — defense-in-depth deduplication and normalization in Story 6.5.2 covers this class of gaps; the specific case is structurally unreachable from both the remote mapper and curated fallback JSON]**

## Deferred from: code review of story 1-1-project-initialization-and-repository-setup (2026-03-27)

- No error handling in `main()` around `configureDependencies()` — when Story 1.3 implements real DI registration, an unhandled throw will produce a black screen with no error feedback. Add try/catch with fallback error screen or `FlutterError.onError` hook. **[KEEP — re-evaluate: when DI registration registers real async services (Epic 3+)]**

## Deferred from: code review of story 1-2-core-dependencies-and-pubspec-setup (2026-03-28)

- Missing Android/iOS platform permissions for `health`, `geolocator`, `vibration`, `sensors_plus` — AndroidManifest permissions, iOS Info.plist usage descriptions, and HealthKit entitlements needed (Epic 3/4 scope) **[KEEP — re-evaluate: Epic 3 health integration]**
- iOS deployment target too low for `health` v12.x — Podfile platform line commented out at default; needs iOS 16+ for full HealthKit API. Configure when health features are implemented (Epic 3) **[KEEP — re-evaluate: Epic 3 health integration]**
- `dartz` package unmaintained since 2022 — `fpdart` is the community successor. Evaluate migration if Dart SDK compatibility issues arise **[KEEP — re-evaluate: if Dart SDK compatibility issue arises]**
- `wear_plus` requires Android WearOS module configuration — needs dedicated WearOS activity and manifest entries (Story 12.1) **[KEEP — re-evaluate: Story 12.1]**
- Android `minSdk` may be too low for Health Connect (requires API 28+) — configure when health features are implemented (Epic 3) **[KEEP — re-evaluate: Epic 3]**
- `sqlite3_flutter_libs` resolved to EOL-tagged version — transitive dep of `drift_flutter`, monitor for future drift updates **[KEEP — re-evaluate: next drift update]**
- `Podfile.lock` not committed — consider committing after first `pod install` for reproducible iOS builds **[KEEP — re-evaluate: before first iOS build/test]**

## Deferred from: code review of story 1-5-core-error-handling-and-either-pattern (2026-03-28)

- Failure classes lack equality/hashCode overrides — two `ServerFailure('same')` instances are not equal by value. Spec explicitly defers to v1. Add `Equatable` when BLoC states depend on Failure comparison **[CLOSE — promoted to active work in Story 6.5.3 (see above)]**
- `rightOrNull`/`leftOrNull` returns `null` for both Left and Right-with-null — callers cannot distinguish failure from success when `R` is nullable. Document limitation or prefer `fold()` for nullable types **[KEEP — re-evaluate: when a nullable R return type is actually used]**

## Deferred from: code review of story 1-4-drift-database-setup-and-schema (2026-03-28)

- AC3: migration test does not simulate actual upgrade — at schemaVersion 1, no real migration exists to test. Add a proper migration simulation test when schemaVersion is incremented to 2 **[KEEP — re-evaluate: when schemaVersion increments to 2]**
- SyncQueue.getPendingEntries() has no nextRetryAt filter — entries scheduled for future retry are returned immediately. Add `WHERE nextRetryAt IS NULL OR nextRetryAt <= now()` filter when sync feature is implemented (Epic 13) **[KEEP — re-evaluate: Epic 13 sync]**
- Domain value CHECK constraints missing — rpeValue (1-10), sessionType (enum), intensity (1-10), currentState (enum), intensityPreference (enum), environmentPreference (enum) accept arbitrary values at DB level. Validation belongs at application/domain layer in v1 **[KEEP — re-evaluate: domain validation pass before Epic 9]**
- No @disposeMethod on AppDatabase for GetIt disposal — getIt.reset() won't call db.close(). Nice-to-have for test hygiene **[KEEP — re-evaluate: if test isolation failures surface]**
- RpeFeedback.sessionId has no index — add when query patterns filtering by sessionId are established **[KEEP — re-evaluate: when query patterns filtering by sessionId exist]**
- SyncQueue.retryCount has no upper bound — implement application-level retry cap in sync feature (Epic 13) **[KEEP — re-evaluate: Epic 13]**

## Deferred from: code review of story 1-7-app-shell-and-navigation-scaffold-phone (2026-03-28)

- Async redirect fires on every navigation — GoRouter's global `redirect` queries DB via `getProfile()` on every route change. Negligible with in-memory SQLite, but consider caching or `refreshListenable` when perf matters **[KEEP — re-evaluate: when GoRouter perf is profiled in Epic 7]**
- No test coverage for onboarding redirect logic (AC 2/3) — redirect behavior described in AC but not in Task 5 test requirements. Add redirect tests when onboarding flow is implemented (Epic 2) **[KEEP — re-evaluate: Epic 2 integration test infra]**
- Test teardown race with async redirect — theoretical race between DB close in tearDown and in-flight async redirect. Safe with `NativeDatabase.memory()` but fragile; consider awaiting router disposal before DB close **[KEEP — re-evaluate: if flaky test detected]**

## Deferred from: code review of story 2-1-medical-disclaimer-screen (2026-04-01)

- Router redirect queries DB on every navigation event — `_redirect` calls `getProfile()` unconditionally on each route change. Cache onboarding-complete status in memory and invalidate on profile change. Pre-existing issue, not introduced by Story 2.1 **[KEEP — re-evaluate: GoRouter perf pass in Epic 7]**

## Deferred from: code review of story 2-2-animated-onboarding-flow (2026-04-01)

- `OnboardingPage` BlocBuilder fallthrough renders `DisclaimerScreen` for `loading` and `error` states — pre-existing from Story 2.1, error state loses checkbox and snackbar context **[KEEP — re-evaluate: UX polish pass before exam]**
- No `Semantics` labels on page indicator dots — screen readers cannot announce page position. Add when accessibility pass is scheduled **[KEEP — re-evaluate: pre-exam accessibility audit]**
- No `Semantics` labels on Lottie animation / fallback icons — decorative content should have content descriptions for assistive technology **[KEEP — re-evaluate: pre-exam accessibility audit]**
- `AppTextStyles.body` is 15sp vs layout spec's 16sp — pre-existing token value defined in Story 1.6, should be reconciled at design-token level **[KEEP — re-evaluate: design-token reconciliation before exam]**
- Manual cubit lifecycle in `OnboardingPage` (`getIt` + manual close) — `BlocProvider(create:)` with auto-close would be more robust for hot reload. Pre-existing from Story 2.1 **[KEEP — re-evaluate: if hot reload lifecycle issues surface]**
- Router test `2.1-UNIT-006` uses hardcoded `pump(Duration)` values instead of deterministic waits — Lottie looping ticker prevents `pumpAndSettle`, documented workaround **[KEEP — re-evaluate: if Lottie upgrade changes ticker behavior]**

## Deferred from: code review of story 2-3-profile-setup-screen (2026-04-02)

- No validation of string values in UserProfile entity — domain entity accepts arbitrary strings, only UI constrains values via SegmentedButton. Consider enums or constructor validation when domain layer matures **[KEEP — re-evaluate: before domain layer hardens (post Epic 9)]**
- Domain entity field names don't match DB column names — fitnessLevel→intensityPreference, goal→fitnessGoal. Intentional per spec value mapping but confusing for future developers. Document or reconcile at schema level **[KEEP — re-evaluate: schema reconciliation pass]**
- OnboardingCarousel._goToNextPage has no bounds check — method relies on caller to prevent out-of-bounds call. Add guard when carousel is next modified **[KEEP — re-evaluate: next carousel modification]**
- Test helpers buildCarousel/buildCarouselWithBrokenAssets don't dispose cubit — BlocProvider.value does not auto-close. Add addTearDown(cubit.close) pattern **[KEEP — re-evaluate: next time onboarding tests are edited]**
- Raw exception e.toString() surfaces in snackbar via CacheFailure — pre-existing pattern from story 2-1, use user-friendly messages **[KEEP — re-evaluate: UX polish pass]**
- No widget-level test for navigation to /today on onboardingComplete — requires GoRouter test infrastructure, add when integration test infra is established **[KEEP — re-evaluate: integration test infra]**

## Deferred from: code review of story 2-4-profile-view-and-edit (2026-04-02)

- Race condition on rapid segment taps without debounce/cancellation — concurrent `updateProfile` calls in `ProfileCubit` can interleave and emit stale state. Low risk for local DB. [profile_cubit.dart:updateProfile] **[KEEP — re-evaluate: if UI debounce added in profile edit flow]**
- Listener guard prevents re-sync after error recovery — `_fitnessLevel == null` guard in `ProfilePage` listener means subsequent `ProfileLoaded` emissions after first load are ignored. No current code path triggers re-load, latent only. [profile_page.dart:listener] **[KEEP — re-evaluate: if error-recovery UX is designed]**
- UserProfile has no ==/hashCode — Bloc deduplication relies on equality; `UserProfile` uses identity equality. Pre-existing entity, not introduced by this story. [user_profile.dart] **[KEEP — re-evaluate: when Bloc state deduplication depends on UserProfile equality]**
- Raw error messages leaked to UI — `e.toString()` passed through `CacheFailure` to Snackbar. Pre-existing project-wide pattern. [onboarding_repository_impl.dart] **[KEEP — re-evaluate: UX polish pass]**
- Read-then-write without transaction in updateProfile — `getProfile()` and `updateProfile()` are two separate DB operations with no enclosing transaction. Low risk for single-user local DB. [onboarding_repository_impl.dart:updateProfile] **[KEEP — re-evaluate: if multi-user or concurrent write scenario emerges]**

## Deferred from: code review of story 3-1-health-api-integration-hr-and-steps (2026-04-03)

- F1: `saveHealthData` failure silently swallowed in `GetHealthData.call()` — Epic 5 AI engine definirà la strategia di error handling per la persistenza; decidere ora anticipa logica non ancora progettata [get_health_data.dart:21] **[KEEP — re-evaluate: Epic 5 AI engine error strategy wiring]**
- F3: `hrPoints.last` does not guarantee most recent data point if health package returns unsorted results — spec-prescribed code pattern, revisit if data ordering issues observed [health_data_source.dart:51] **[KEEP — re-evaluate: if out-of-order health data is observed]**
- F4: `configure()` called on every `fetchHealthData()` invocation; benign but suboptimal on Android — spec-prescribed code pattern, consider lazy init flag [health_data_source.dart:23] **[KEEP — re-evaluate: if Android battery impact measured]**

## Deferred from: code review of story 3-2-accelerometer-activity-detection (2026-04-04)

- Boundary value tests missing — no tests at exact classification thresholds (stdDev == 0.3, == 1.5); current tests use values clearly within each band. Nice-to-have for regression safety [accelerometer_data_source_test.dart] **[KEEP — re-evaluate: pre-exam regression safety sweep]**

## Deferred from: code review of story 3-3-rpe-only-fallback-mode (2026-04-04)

- F4: No concurrency guard on accelerometer stream subscriptions — multiple concurrent `fetchActivityLevel()` calls open parallel platform channel subscriptions. No concurrent callers exist today; theoretical risk only [accelerometer_data_source.dart:30-37] **[KEEP — re-evaluate: when concurrent callers are introduced]**
- F5: `SensorContext` has no `==`/`hashCode`/`Equatable` — spec mandates plain class; equality needed only when Epic 5 StateVector consumes it [sensor_context.dart] **[KEEP — re-evaluate: when Epic 5 StateVector equality is needed]**

## Deferred from: code review of story 4-1-open-meteo-api-integration (2026-04-05)

- Singleton `Dio` shared globally — no isolation between APIs. Becomes relevant when ExerciseDB API added in Story 6.1 [network_module.dart] **[KEEP — re-evaluate: after ExerciseDB Dio instance is analyzed for interference]**
- `requestPermission()` called from data layer (`LocationService`) — permission dialogs should be triggered from presentation layer. No weather UI exists yet; refactor when weather UI is built [location_service.dart:23] **[KEEP — re-evaluate: when weather UI is built (Epic 7 or later)]**
- `weather_cache` table grows unbounded — `insertOnConflictUpdate` with autoIncrement PK never replaces rows. Story 4.2 TTL management should add cleanup [weather_cache_dao.dart] **[KEEP — re-evaluate: added cleanup in Story 4.2? Verify and CLOSE if already fixed]**

## Deferred from: code review of story 4-2-weather-cache-and-ttl-management (2026-04-06)

- Cache served for wrong location after user moves — no lat/lon comparison between cached and current coordinates. Single-entry cache design trade-off acknowledged in spec [weather_repository_impl.dart:39] **[KEEP — re-evaluate: multi-city UX design pass]**
- DateTime.now() in _isCacheValid — no clock injection for deterministic testing. Pre-existing architectural pattern, tests use wide margins (30min/2h) [weather_repository_impl.dart:79] **[KEEP — re-evaluate: if TTL-sensitive flaky tests surface]**
- Drift DateTime UTC round-trip inconsistency — isUtc flag differs between fresh fetch (true) and DB read (false). Epoch arithmetic correct, cosmetic inconsistency [weather_local_data_source.dart:23] **[KEEP — re-evaluate: if date comparison bugs surface]**
- AC3 2h AQI indoor-default logic — deferred to Story 5.1. Indoor-forcing on stale AQI > 2h belongs to StateVector builder. Repository returns stale data with cachedAt intact as input for 5.1 [weather_repository_impl.dart:70] **[KEEP — re-evaluate: verify this is handled in StateVector builder (5.5); CLOSE if confirmed]**

## Deferred from: code review of story 4-3-city-level-location-resolution (2026-04-07)

- Enum `unableToDetermine` not handled in permission flow — falls through to `getCurrentPosition` which may throw; caught by generic catch but produces misleading error message [location_service.dart:23-31] **[KEEP — re-evaluate: Epic 4 location permission UX pass]**
- `on LocationServiceDisabledException` catch is near-dead code with no test — only triggers in narrow race between service check and position request [location_service.dart:45] **[KEEP — re-evaluate: when location service toggle tested on device]**
- No timeout on `isLocationServiceEnabled()`, `checkPermission()`, `requestPermission()` — `requestPermission()` can block indefinitely on Android if system dialog never dismissed [location_service.dart:18-25] **[KEEP — re-evaluate: UX polish pass with real device testing]**
- `catch (e)` swallows all exceptions including programmer errors (`TypeError`, `RangeError`) — turns bugs into generic "Location unavailable" message [location_service.dart:47] **[KEEP — re-evaluate: error telemetry pass before exam]**
- Cache-hit path ignores location change within TTL window — user moves to different city but stale weather returned. Already noted in Story 4.2 review [weather_repository_impl.dart:39] **[KEEP — re-evaluate: duplicate of 4-2 item]**

## Deferred from: code review of 5-1-domain-models-and-statevector (2026-04-21)

- `BanditState` name collision with existing drift table class `BanditState` — any future DAO/repo importing both needs `as` prefix or one side must be renamed [lib/core/database/tables/bandit_state_table.dart vs lib/ai/bandit/bandit_state.dart]. Address in Story 5.4 when wiring the persistence layer. **[KEEP — re-evaluate: Story 9.3 bandit persistence wiring]**
- `UserProfile.physicalConstraints` is a single enum-string: cannot co-express "indoor preference" and an injury constraint (`knee`/`back`). Downstream safety filtering (Story 5.3) loses a dimension. Pre-existing onboarding shape, outside Story 5.1 scope — reconsider in a future onboarding iteration. **[KEEP — re-evaluate: onboarding iteration post-exam]**
- `BanditState` lacks a canonical `BanditState.initial()` factory that constructs all 9 arms at 1.0 using `banditArmKeys`. The 9-arm invariant is only documented, not enforced. Address in Story 5.4 alongside reward-update logic. **[KEEP — re-evaluate: Story 9.3]**

## Deferred from: code review of 5-2-behavioral-state-machine (2026-04-21)

- `StateVector.rpeHistory` has no range validation (expected 1–10 per FR). Negative or OOR RPE would silently trigger wrong transitions (e.g. `recovering→active` via negative average). Add invariant in StateVector or at construction site. Pre-existing from Story 5.1. **[KEEP — re-evaluate: StateVector builder validation pass (5.5 done — verify or add)]**
- `missedSessions` decay/reset logic undefined: a user who was `fatigued` with `missed≥2` transitions to `atRisk`, and if the StateVector builder doesn't reset `missedSessions` after resumed activity, the user is permanently stuck in `atRisk` even with 2 low-RPE sessions. Responsibility of the StateVector builder in Story 5.5. **[KEEP — re-evaluate: Story 9.3 reward update]**
- Story 5.2 AC7 wording says "transition is written to behavioral_state table" but Dev Notes explicitly defer persistence to Story 5.5. Text tension is intentional but should be reworded in future spec revisions. **[CLOSE — intentional spec ambiguity acknowledged in prior retro; no code change needed]**
- Product/spec review (Epic 5): state-graph asymmetries worth discussing — (a) `active + missed≥2` never escalates to `atRisk`, (b) `recovering` has no demotion path for high-RPE or missed sessions, (c) `atRisk→recovering` requires only 2 low RPEs with no streak/missed guard, asymmetric vs `recovering→active`. All spec-compliant but may be unsafe in practice. Revisit when Story 5.3 SafetyRules lands or before Epic 5 retro. **[KEEP — re-evaluate: Epic 9 safety rules validation session]**

## Deferred from: code review of 5-3-safety-rules-override-system (2026-04-22)

- RPE range validation (negative / >10) in `safety_rules.dart` `_lastTwoAvg` — no bounds check. Corrupt DB rows would silently skew safety constraints. Already overlaps with pre-existing Story 5.1 defer; fix location is StateVector builder in Story 5.5. **[KEEP — re-evaluate: StateVector builder Story 5.5 (verify if addressed)]**
- RPE staleness / recency — `rpeHistory` has no timestamp, so `_lastTwoAvg` cannot distinguish between "RPE 10 yesterday" and "RPE 10 three weeks ago". Can over-restrict (stale high RPE) and under-restrict (stale low RPE after recent high). Structural: requires schema change or upstream time-window filtering in Story 5.5. **[KEEP — re-evaluate: when RPE timestamps are added (Epic 9)]**

## Deferred from: code review of 5-4-contextual-bandit-algorithm (2026-04-29)

- `_toPlannedSession` 2-part armKey contract not enforced (`contextual_bandit.dart:139-150`) — `parts.first` / `parts.last` assume a 2-segment key. Latent only if `banditArmKeys` evolves to multi-segment keys (e.g., `cardio_medium_outdoor`). **[KEEP — re-evaluate: if banditArmKeys grows to 3-segment keys]**
- `outdoorAllowed=false` doesn't filter outdoor-only arms (`contextual_bandit.dart:148`) — bandit returns "indoor cardio_high" without validating that an indoor variant exists in the session catalog. Depends on Story 6.x catalog model. **[KEEP — re-evaluate: Story 9.3 catalog integration]**
- Map iteration order brittle to `banditArmKeys` reorder for seeded-RNG reproducibility (`contextual_bandit.dart:79-83`) — historical reproducibility tests with seeded RNG would break silently if the const list is reordered. Low risk. **[KEEP — re-evaluate: if bandit determinism tests are added]**
- `isIndoor` derived from `!constraints.outdoorAllowed` placeholder (`contextual_bandit.dart:148`) — indoor/outdoor semantics belong to the exercise catalog (Story 6.x), not the bandit. Current logic is a documented placeholder; revisit when the catalog model lands. **[KEEP — re-evaluate: Story 9.3 catalog integration]**

## Deferred from: code review of 5-5-daily-plan-generation-and-ai-isolation (2026-04-29)

- `_decayedEpsilon` uses arm-weight proxy for session count (`ai_engine_isolate.dart:59-67`) — documented heuristic per spec Dev Notes ("revisit in Story 9.3"). Accepted as-is during 5.5 review; Story 9.3 will replace with `SessionsDao.length` once RPE feedback wires bandit reward updates. **[KEEP — re-evaluate: Story 9.3]**
- `_exploit` `reduce` on empty list throws `Bad state: No element` (`contextual_bandit.dart:147-155`) — currently guarded by `selectSessions`'s `if (eligible.isEmpty) return []` and the loop's `remaining.isNotEmpty` check, but `_exploit` itself has no precondition. A future bypass caller would crash. Fragile contract; not exercised by 5.5 or 9.x. **[KEEP — re-evaluate: add precondition assertion in Story 9.3]**
- `RewardCalculator.updateWeight` silent no-op on unknown armKey (`reward_calculator.dart`) — typo or stale arm key returns state unchanged with no log/assert; learning silently lost. Address when Story 9.3 wires up RPE feedback. **[KEEP — re-evaluate: Story 9.3]**
- `precipitationProbability == NaN` bypasses safety check (`generate_daily_plan.dart:115-118`) — `NaN > 50.0 → false`, treated as "no precipitation". Depends on weather repo guarantees from Epic 4; revisit if weather repo's contract is loosened. **[KEEP — re-evaluate: when weather repo contract is documented]**
- `_calculateStreak` unbounded loop (`generate_daily_plan.dart:186-199`) — walks back through every consecutive completed-day; no upper cap. Unrealistic to hit but worth a max-streak constant for defense. **[KEEP — re-evaluate: add max-streak constant in Epic 9]**
- Bandit selection observability gap (`contextual_bandit.dart:64-73`) — `Random()` is non-seeded, no logging of which arm was chosen and why. Debug aid for reproducing user complaints; not correctness. **[KEEP — re-evaluate: when debug logging pass is done pre-exam]**
- 5.4 cold-start exploit determinism patch (alphabetical tiebreak via `>` instead of `>=`) lacks a regression test (`contextual_bandit_test.dart` 5.4-UNIT-016) — implementation correct, but no test asserts the tiebreak behavior. Add when revisiting bandit tests. **[KEEP — re-evaluate: when bandit tests are extended in Epic 9]**
- `initialBanditState()` cold-start sentinel uses `updatedAt.year == 1970` (`bandit_state.dart`) — a device with broken clock returning 1970-01-01 from `DateTime.now()` would falsely classify a real updated state as cold-start. Edge case for misconfigured devices. **[KEEP — re-evaluate: device testing phase]**

## Deferred from: code review of 5-6-ai-explanation-generation (2026-05-07)

- HR band 61–75 has no biometric explanation (`explanation_generator.dart:50,58`) — `>75` and `<=60` are matched, but the "normal" band falls through with no biometric message even when present. Intentional but undocumented; readers will assume HR=75 triggers something. **[KEEP — re-evaluate: explanation copy pass with Alice before Epic 7 Today screen]**
- "Resting HR looks solid" requires `streak >= 1` (`explanation_generator.dart:58`) — first-time users (streak=0) with great resting HR (e.g. 55) skip this branch and land in the generic session-type fallback. The most positive biometric signal is suppressed for the cohort that needs encouragement most. **[KEEP — re-evaluate: same copy pass]**
- RPE band asymmetric boundaries (`explanation_generator.dart:65,68`) — `<= 6.5` (inclusive) vs `> 7.5` (exclusive). Users at avg=7.0 get "Staying in your comfort zone" message; avg=7.5 exactly falls to generic. Boundary symmetry worth revisiting. **[KEEP — re-evaluate: same copy pass]**
- "Consistent this week" claim fires without minimum `rpeHistory` length (`explanation_generator.dart:65`) — `avg <= 6.5 && streak >= 2` ignores how many RPE entries exist; a single low RPE entry plus streak=2 produces the "consistent this week" message — semantically weak. **[KEEP — re-evaluate: same copy pass]**
- `stepCount < 3000` threshold ignores time-of-day (`explanation_generator.dart:54`) — at 8 AM most users have <3000 steps; "Low step count today" message is meaningless until late in the day. Revisit when timestamp signals exist. **[KEEP — re-evaluate: when timestamp signals exist (Epic 9+)]**
- `_todayDate()` local time vs `generatedAt` UTC skew (`ai_engine_isolate.dart:65,67`) — pre-existing from Story 5.5; plans generated near midnight may show a `planDate` that mismatches the UTC `generatedAt` date. Not introduced by 5.6. **[KEEP — re-evaluate: when midnight-boundary plan generation tested]**
- Tests use weak OR-chain substring matching (`explanation_generator_test.dart` 5.6-UNIT-008/009/010/011/012/014/015) — assertions like `text.contains('hr') || text.contains('gentle') || text.contains('elevated')` pass even if the wrong branch fires (e.g., 'gentle' appears in the welcome-back message). Coverage illusion; tighten to direct branch assertions. **[KEEP — re-evaluate: when explanation tests are strengthened in Epic 9]**

## Deferred from: code review of 6-2-bundled-fallback-exercise-catalog (2026-05-15)

- Catalog uniqueness not enforced at load time in `_loadFallback` (`exercise_local_data_source.dart:108-128`) — duplicate IDs in a future JSON edit would surface duplicates to the UI and break `Key`-based list rendering. Tests guard the shipped JSON only. **[CLOSE — addressed by Story 6.5.2 dedup guard in `loadFallbackExercisesByType`]**
- Unknown/case-variant `sessionType` silently returns empty list with no normalization or logging (`exercise_local_data_source.dart:115`) — typos like `"mobilty"` or wrong-case `"Mobility"` collapse to `Left(CacheFailure)` indistinguishable from "no asset". **[CLOSE — addressed by Story 6.5.2 normalization]**
- `Exercise.fromJson` accepts any string for `difficulty`/`sessionType` (`exercise.dart:6-22`) — no enum validation, no defense in depth if catalog data drifts from the contract. **[KEEP — re-evaluate: when Exercise model validation is added in Epic 7]**
- Empty-asset vs missing-asset failure paths produce identical user-facing messages (`exercise_repository_impl.dart:136-138`) — asset-missing diagnostic is swallowed; only the remote error message reaches the user. **[KEEP — re-evaluate: when diagnostic logging is added for asset errors]**
- Stale-cache recovery short-circuits the expanded fallback entirely when any stale row exists (`exercise_repository_impl.dart:114-118`) — by design from Story 6.1, but now hides 10 curated rows per category behind a single stale row. **[KEEP — re-evaluate: Epic 7 cache-staleness UX]**
- AssetBundle JSON re-parsed on every `loadFallbackExercisesByType` call (`exercise_local_data_source.dart:96`) — three categories on cold start = three parses of the same 30-entry payload. Consider memoizing the decoded list per session. **[KEEP — re-evaluate: when cold-start perf measurement is done in Epic 7]**

## Deferred from: code review of story-6.5.2 (2026-05-15)

- Asymmetric normalization in `ExerciseLocalDataSource` — read path lowercases input but cached rows and fallback asset JSON are not normalized on the write side; today's invariant (callers pass lowercase constants, curated JSON stores lowercase) holds but is undocumented (`exercise_local_data_source.dart:49,149`). **[KEEP — re-evaluate: when non-curated/external catalog sources are introduced or when asset authors are not the engineering team]**
- Dedup bypassed by id case-variants or whitespace-padded ids — `seen.add(exercise.id)` uses the raw id, so `"x"` vs `"x "` or `"X"` survive as distinct (`exercise_local_data_source.dart:142-156`). **[KEEP — re-evaluate: if a fallback authoring incident occurs or when an id-format lint is added to the JSON]**
- Empty-id record treated as a single dedup key — first entry with `id: ""` wins; later empty-id entries are silently dropped as "duplicates" and risk a downstream DAO PK collision (`exercise_local_data_source.dart:148-150`). **[KEEP — re-evaluate: when `Exercise.fromJson` validation is added in Epic 7 (already a tracked KEEP item)]**
- Empty `sessionType` produces user-visible message with double space — `CacheFailure('No exercises available for  (offline and no fallback)')` in repository when the data source returns the new empty-list path (`exercise_repository_impl.dart`). **[KEEP — re-evaluate: when a guard against empty sessionType is added at the cubit/router layer in Epic 7]**
- Test `6.5-UNIT-004` does not assert the `developer.log` warning is emitted on duplicate detection — if a refactor silently drops the log, the only diagnostic channel for catalog corruption disappears without test failure (`exercise_local_data_source_test.dart`). **[KEEP — re-evaluate: when a log-capture helper is introduced for the test suite]**
- No unit test covers the empty-string early-return branch in either `getCachedExercisesByType` or `loadFallbackExercisesByType` — new code added in 6.5.2 without coverage (`exercise_local_data_source_test.dart`). **[KEEP — re-evaluate: next time the file is edited]**

## Deferred from: code review of 6.5-3-process-action-item-ledger (2026-05-15)

- Latent risk: future `Failure` subclass with extra fields would inherit base equality (only `runtimeType` + `message`) and silently treat instances with diverging field values as equal (`pulse_coach/lib/core/error/failures.dart`). **[Defer — intentional per spec design (subclass identity via `runtimeType`); re-evaluate when first subclass adds fields]**
- Downstream value-semantics shift for `Map<SessionsCatalogCategory, Failure>` and other freezed-state fields holding `Failure` — two `loaded` states whose degraded entries differ only by `Failure` identity (same type+message) are now structurally equal, possibly suppressing BLoC re-emission (`pulse_coach/lib/features/exercise_catalog/.../sessions_catalog_state.dart`). **[Defer — observable only when callers assert per-failure identity; re-evaluate when Today screen (Epic 7) consumes catalog/error states]**
- No explicit lint or test guard preserving `const` constructibility on `Failure` subclasses — implicitly enforced today by `const` usage in tests, but no analyzer rule catches future removal (`pulse_coach/lib/core/error/failures.dart`). **[Defer — re-evaluate when adding `prefer_const_constructors` policy or a new Failure subclass]**
- BLoC error-state re-emission may be suppressed by `Failure` structural equality — two consecutive failures with identical message now collapse into a single emission across `daily_plan_bloc.dart`, `sessions_catalog_state.dart`, etc. **[Defer to Epic 7 — error states have no UI consumer yet; re-evaluate when Today screen consumes them and the desired re-notify behavior is observable in product context]**

## Deferred from: code review of 6.5-4-dependency-major-version-upgrades (2026-05-15)

- Remove unused `fl_chart` and `google_fonts` direct dependencies from `pulse_coach/pubspec.yaml` — both packages have zero imports under `lib/` or `test/`. Listed in pubspec as preemptive deps for future epics (Progress charts in Epic 10; on-the-fly Google Fonts loading currently bypassed via locally-bundled `assets/fonts/`). Re-evaluate when those features land or as a `chore(deps): prune unused` follow-up.

## Deferred from: code review of 7-1b-missed-sessions-decay-and-reset (2026-05-15)

- DST / local-vs-UTC date boundary risk in `generate_daily_plan.dart:257-260` — `windowStart = DateTime.now().subtract(Duration(days: 6))` uses wall-clock arithmetic; across Italian DST transitions the window can shift by ±1 calendar day. Same pattern is already established across other date code paths in the file. **[Defer pending project-wide date-utility cleanup — needs injectable clock + UTC normalization across `_dateStr`, `_todayDate`, and all `planDate` write sites]**
- `isCompleted` is the sole source of truth for missed-session count — orphan / abandoned-plan semantics unverified. Old `_calculateMissedSessions` excluded `Session.abandoned == true`; new logic reads only `daily_plans.isCompleted`. If a session is abandoned mid-flow without the daily plan being marked completed, the user is permanently penalized as disengaged. **[Defer — needs separate audit of `markCompleted` call sites and abandon-flow contract; likely surfaces during Epic 9 (Feedback & Adaptation Loop)]**
- Italian transition message in `behavioral_state_machine.dart:35` stands alone among English messages — pre-existing localization debt across Rule 2/3/4/5 placeholder strings. Spec locks the exact Italian text for Rule 1, so isolated fix is not possible. **[Defer to a dedicated i18n extraction story]**
- GDP integration tests in `generate_daily_plan_test.dart` are timezone-fragile near midnight — tests use real `DateTime.now()` for both window math and inserted `planDate` values; CI in a different TZ or a build straddling midnight could produce off-by-one window inclusion. Pre-existing pattern in the file. **[Defer pending injectable clock for the whole suite]**

## Deferred from: code review of 7-1-stateindicator-component (2026-05-15)

- Rule 5 priority guard wins over Rule 6 — user in `recovering` with `streak >= 3` and last RPE 9–10 sees `"Sei di nuovo in forma!"` instead of de-load. Matches `ai-state-graph-product-decisions-2026-05-15.md` "Final Rule Set"; flagged by reviewers for product reconsideration. **[Defer — intentional per decision doc; reconsider in Epic 9 feedback loop]**
- Rule 4 3-RPE window can include a recent overload (e.g. `[9, 6, 6]` avg=7.0 → `recovering`). Q3 decision didn't address residual-overload-in-window. **[Defer — would require state-graph decision doc update]**
- State-machine source hardcodes Italian transition strings duplicating `state_messages.it.arb`; AC8 invariant test only protects the ARB side. Pre-existing per spec Dev Notes (gen_l10n not wired). **[Defer to dedicated i18n extraction story — overlaps existing deferred i18n debt]**
- a11y: `_StateIcon` returns plain `Container` dots for `active`/`fatigued` with no `Semantics`; screen readers get only the text label. No AC requirement. **[Defer to a11y pass]**
- `BehavioralStateMachine.evaluate()` idempotency under repeated calls with unchanged inputs is not test-covered. No current bug; contract risk for the `DailyPlanGenerationPipeline` caller. **[Defer to a follow-up test hardening task]**
- ARB-loading tests use relative path `File('lib/l10n/state_messages.it.arb')` — fragile to non-`pulse_coach/` CWDs (IDE runners, future CI step variants). **[Defer — baseline CWD documented in CLAUDE.md]**
- Coverage gaps in Story 7.1 tests: exact boundary `_lastNAvg(rpe,3) == 7.0`; `missed >= 2` with Rule 4; `AppTextStyles.h3.height=1.35` regression guard; `_StateIcon` `BoxShape.circle` shape assertion; ARB duplicate-key detection. **[Defer — low-risk gaps, can be bundled into a single hardening pass]**
- Test helper fragility: `_text`/`testerText` use `.single` (crashes obscurely on duplicate labels); `7.1-WIDGET-007` indexes icons positionally by tree-walk order. **[Defer — no current bug]**
- Magic alpha `0.70` for `recovering` color duplicated between widget and test. **[Defer — micro-nit, fold into next theming touch]**

## Deferred from: code review of 7-2-sessioncard-component (2026-05-15)

- Release-mode NPE risk if `PulseCoachTheme` extension absent — `assert(...); pulseThemeOrNull!` pattern strips in release. Cross-cutting with `StateIndicator` and any future extension-dependent widget. **[Defer — follows spec verbatim; promote to a hardening story across all extension-dependent widgets]**
- Hero card body not tappable but Semantics says "Tocca per iniziare" — Story 7.3 wires the full Today screen and may add a hero-level tap surface. **[Defer — Story 7.3 scope]**
- `sessionAccentColor`/`sessionDisplayName`/`sessionIcon` are case- and whitespace-sensitive — no normalization in the helper layer; Epic 6.5 normalizes upstream. **[Defer — upstream-normalized; reconsider if a new data source bypasses the read-path layer]**
- `durationMinutes` rendered as `"$x min"` with no clamping, plural, or `>60` handling. **[Defer — i18n/intl is out-of-scope for Epic 7]**
- Brittle widget-test selectors in `session_card_test.dart` — `find.byType(Container).first` and `.evaluate().single`; prefer `Key`s. **[Defer — tests pass, low impact]**
- WCAG contrast on coral-tinted gradient — body text in top-left gradient corner ~3.7:1; intensity coral on coral-tinted bg <3:1. Colors and 12% alpha are spec-mandated. **[Defer — spec-driven]**
- Tests only exercise `AppTheme.darkTheme`; cardio's hardcoded `#F0A1B0` won't theme-switch — no regression guard. **[Defer — dark-first project]**
- No test for `sessionType = ''` empty-string input — renders empty H2 and degenerate Semantics. **[Defer — low-probability input; pairs with the empty-explanation patch]**
- Hero `onStart` has no debouncing/double-tap guard. **[Defer — Story 7.3 wires the actual handler and can add busy-state]**

## Deferred from: code review of 7-3-today-screen-layout-and-hero-progression (2026-05-15)

- `heroTag` on `HeroSessionCard`/`CompactSessionCard` wraps only the icon and serves no in-page animation (AnimatedSwitcher is used instead). It is scaffolding for Epic 8 page-to-page Hero flight. Revisit when Epic 8 wires the route push. **[Defer — Epic 8 scaffolding]**
- AC2 "above the fold on a standard phone" is not asserted by any test (no golden/viewport infra). **[Defer — missing test infrastructure]**
- Italian UI strings hard-coded across `today_page.dart`, `completion_ring.dart`, `completed_session_card.dart`; "COMING UP" stays English. No i18n hook. **[Defer — project-wide i18n decision pending]**

## Deferred from: code review of 7.5-1-wire-flutter-localizations-gen-l10n (2026-05-16)

- No `localeResolutionCallback` in `MaterialApp.router`. Latent issue: when the hardcoded `locale: const Locale('it')` is removed in a future Epic 7.5+ story, Flutter's default `basicLocaleListResolution` falls back to the **first** entry of `supportedLocales` — which is `Locale('en')`, not `Locale('it')`. Italian-speaking users on non-Italian system locales would silently get English. Fix when the hardcode is lifted. **[Defer — activates only when `locale:` override is removed]**

## Deferred from: code review of 8-0-sessionlog-dao-and-per-session-completion (2026-05-17)

- Day-boundary / TZ leak in `SessionLogsDao.getLogsForPlan` — currently inert because `daily_plans.planDate` is UNIQUE per day, so logs scoped to a `dailyPlanId` are inherently same-day. Revisit if plan rows ever span days or if `DateTime` storage moves to UTC. **[Defer — currently inert]**
- `DailyPlanBloc` runs `getLatestState` and `getPlanForDate` as two sequential awaits — `Future.wait` would halve latency. Micro-perf. **[Defer — perf-only]**
- Layering smell: `DailyPlanBloc` re-queries `getPlanForDate` for a row the `GenerateDailyPlan` / `RegenerateDailyPlan` usecase just wrote. The usecase should return the persisted plan id (or the full row) so the BLoC doesn't need an extra DB round trip and doesn't leak `dailyPlansDao` knowledge. **[Defer — refactor candidate]**
- `_TestingTodaySessionCubit` copy-pasted across `test/widget/app_shell_test.dart:131-147` and `test/widget/pages_smoke_test.dart:228-243`. Extract a shared test helper. **[Defer — DRY cleanup]**
- Empty plan (`sessions.length == 0`) renders as "all done" with `CompletionRing` at 0/0. No telemetry signal, acceptable for v1. **[Defer — low priority]**
- No `provideDummy<SessionLog>` in `today_session_cubit_test.dart` — latent fragility when a third DAO method (e.g. `deleteLogsForPlan`) is exercised in a future test. **[Defer — test-suite hygiene]**
- `SessionLogsDao` registered as `@singleton` while `TodaySessionCubit` is `@injectable` (factory). Fine now, but if `TodaySessionCubit` is ever promoted to singleton, `_currentPlanId` becomes shared mutable state across navigation. **[Defer — latent footgun]**

## Deferred from: code review of 8-1-countdownoverlay (2026-05-17)

- Deep-link / hot-restart to `/session/active` with null `state.extra` strands the user on the Story 8.2 placeholder (no back affordance, no nav bar, no exit). Defer to Story 8.2 which owns the real session view and the exit affordances. [app_router.dart:71]

## Deferred from: code review of 8-3-haptic-feedback-on-step-transitions (2026-05-17)

- `start()` called twice leaks a `Timer.periodic` (no `_timer?.cancel()` guard before the second `Timer.periodic` assignment). Phantom haptics become user-visible with 8.3. [in_session_cubit.dart:39-41]
- Empty `steps` list crashes `InSessionCubit` constructor at `steps.first.durationSeconds`. Upstream `SessionStepGenerator` invariant; consider an assert. [in_session_cubit.dart:34]
- `abandon()` after natural completion can cause double navigation: `BlocListener` (`listenWhen: current.isComplete && !previous.isComplete`) still fires `context.go(sessionRpe)` even after `onAbandon` already navigated to `today`. No `isComplete || isAbandoned` guard in `abandon()` or in `_persistCompletion`'s final emit. Tracked for Story 8.5. [in_session_cubit.dart:92-95]
- No `Vibration.cancel()` on page dispose — 200ms buzz may bleed into the next route on rapid navigation / app background. Minor hygiene. [in_session_page.dart:62-66]

## Deferred from: code review of 8-4-live-heart-rate-display (2026-05-17)

- RTL not handled in `Positioned(right: 16)` — use `PositionedDirectional(end: 16)`. Latent until locale lock relaxed. [in_session_view.dart]
- `getIt.isRegistered<Health>()` racy with async DI registration patterns — same shape as 8.2's `SessionLogsDao` guard. [in_session_page.dart]
- Concurrent in-flight HR polls can complete out of order — older poll emits after newer one if `fetchLiveHr` ever exceeds 5s. [in_session_cubit.dart]
- HR badge can overlap step title at narrow viewports (< 360 dp) when title wraps to 2-3 lines. Design refinement. [in_session_view.dart]
- HR badge has no background pill / contrast guarantee — relies on `onSurfaceVariant` over `surface`; safe today but fragile to theme changes. [in_session_view.dart]
- Test timing race: `pump(Duration(seconds: 5))` + async emit — currently passing with trailing `pump()`, but `pumpAndSettle` or `fake_async` rewrite would be more robust. [test/bloc/in_session_cubit_hr_test.dart]
- First-poll race during `init()` cold start — first 1-2 polls return null on slow devices; retries every 5s so effect is brief. [live_hr_service.dart, in_session_cubit.dart]
- Test mock import couples `live_hr_service_test.dart` to `health_data_source_test.mocks.dart` — fragile; move to local `@GenerateMocks([Health])`. [test/unit/live_hr_service_test.dart:5]

## Deferred from: code review of 8-5-session-abandon-flow (2026-05-17)

- ARB key count assertion `expect(userFacingKeys, hasLength(50))` is brittle — any future ARB key addition will break it for no semantic reason. Pre-existing pattern, not introduced by Story 8.5. [`pulse_coach/test/widget/state_indicator_test.dart`]
- `addColumn` cannot retroactively apply the `CHECK ("abandoned" IN (0,1))` constraint that fresh installs get from the generated `CREATE TABLE`. Migrated v6→v7 databases will lack the CHECK invariant. Low-severity schema drift; no current consumer depends on it. [`pulse_coach/lib/core/database/app_database.dart` onUpgrade]

## Deferred from: code review of 9-1-rpeinput-component (2026-05-21)

- DF1 — textScaler ≥ 2.0 may clip the '10' glyph inside the 48dp RPE circle [pulse_coach/lib/features/session/presentation/widgets/rpe_input_widget.dart]
- DF2 — Pointer events on a different RPE button during the ~16ms rebuild lag may flicker an extra `AnimatedScale` before disable propagates; `_submitted` guard catches the double-tap [pulse_coach/lib/features/session/presentation/widgets/rpe_input_widget.dart]
- DF3 — `selectedRpe` visually deselects during brief `RpeFeedbackSubmitted` state before navigation [pulse_coach/lib/features/session/presentation/pages/rpe_page.dart]
- DF4 — `find.text('10')` smoke-test assertion is brittle (matches any literal "10") [pulse_coach/test/widget/pages_smoke_test.dart:185]
- DF5 — `Semantics(selected: true)` lacks `liveRegion: true` — TalkBack/VoiceOver may not re-announce on submit [pulse_coach/lib/features/session/presentation/widgets/rpe_input_widget.dart]
- DF6 — RTL: horizontal scroll origin not reversed for RTL locales [pulse_coach/lib/features/session/presentation/widgets/rpe_input_widget.dart]
- DF7 — `_submitTimer` reference not nulled on error reset; rapid re-submit can leave two timers in flight (latency only matters with long animation durations) [pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:34]
- DF8 — Smoke-test getIt registration is teardown-order-dependent [pulse_coach/test/widget/pages_smoke_test.dart]
- DF9 — Retry-after-close race; cubit is already disposing [pulse_coach/lib/features/session/presentation/bloc/rpe_feedback_cubit.dart:50-55]

## Deferred from: code review of 9-2-minisummary-and-completionring-animation (2026-05-21)

- DF10 — Plain `Timer` instances (MiniSummary hold/fade, and pattern-wide across cubits) are not paused on app lifecycle. Backgrounded app keeps wall-clock ticking → MiniSummary auto-dismisses while user is in a call/notification; on resume they land on Today instead of the summary. Affects multiple cubits, not just MiniSummary. Track as a cross-cutting lifecycle-observer story.
- DF11 — `RpeSubmitArgs.durationMinutes = 0` silent default is a future footgun. Only one call site wires it today (`in_session_page.dart`). Safe now, dangerous if a second producer is added. Tighten when a second call site appears, or remove the default.
- DF12 — `armKey.split('_').first` is fragile to future `armKey` format changes / unknown session types; falls through to raw key on unknown values. Tie to E7.5-T1 / future i18n hardening when `BehavioralStateMachine` consumer wiring lands.

## Deferred from: code review of story-10.0 (2026-05-24)

- **Sticky `persistenceError` across reconciliation stream ticks.** Once set on a failed DAO write, `TodaySessionCubit._onLogsChanged` emits `copyWith(...)` without `persistenceError`, so the sentinel preserves a stale error from one session into a later session's successful-completion display; it clears only on the next full `planLoaded`. In `InSessionState` the clear path is dead within an instance. No live impact today (no UI consumer reads the field). One-line fix: explicitly clear `persistenceError` in `_onLogsChanged`'s emit. Tie this to the future `persistenceError` UI-surfacing story. [today_session_cubit.dart:108, in_session_cubit.dart:145]

## Deferred from: code review of story-10.1 (2026-05-24)

- **N+1 query pattern in `ProgressLocalDataSource.getSessionHistory`** — per-log `getPlanById` + `jsonDecode` + `getBySessionLogId`, no memoization by `dailyPlanId`, no `LIMIT`/pagination. Performance only; history is small at this milestone. Optimize alongside Story 10.2 charts if it surfaces.
- **`completedAt` rendered without `.toLocal()`** (`session_history_tile.dart:_formatDate`) — sessions near midnight may show the wrong calendar date depending on timezone. Systemic: no widget in the app uses `toLocal()`/`intl` yet; fix app-wide when `intl` date formatting lands.
- **No retry affordance on `ProgressHistoryError`** (`progress_page.dart:_ErrorState`) — user is stuck on the error text with no in-tab reload. UX enhancement, not in AC5.

## Deferred from: code review of 10-3-weekly-goal-progress (2026-05-27)

- Weekly indicator shows a perpetual shimmer on `ProgressStatsError` (`progress_page.dart:44-57`). The `BlocBuilder` only special-cases `ProgressStatsLoaded`; error/initial/loading all render the shimmer slot, so a failed stats load shows an indefinite loading shimmer rather than an error or empty affordance. Spec-sanctioned (Task 5: "Loading / initial / error: compact shimmer row") but a UX smell — consider a distinct error/empty state for the weekly slot in a future polish pass.

## Deferred from: code review of 11-1-responsive-scaffold-and-navigationrail-tablet (2026-05-28)

- Breakpoint uses `constraints.maxWidth` (not `shortestSide`): a large phone in landscape (>=600dp wide) flips to the tablet `NavigationRail` (`app_shell.dart:30`). By design per Story 11.1 AC1/example; orientation handling (FR39) is scoped to Story 11.3. Re-evaluate when 11.3 lands.
- NavigationRail label overflow unverified in the 600–700dp band: `labelType.all` + long Italian labels ("Sessioni"/"Progressi") at `minWidth: 80`; widget tests only exercise 800dp. Confirm via the mandatory on-device UI verification protocol at a ~600–700dp width before story sign-off.

## Deferred from: code review of story 11.2 (2026-05-29)

Items identified during the Story 11.2 code review, deferred (not blocking; not reachable under current invariants or pre-existing).

- **CR112-001 — Tablet `heroIndex` clamp is not completion-aware (optional hardening).** `_TabletTodayLayout` clamps `heroIndex` to `[0, total-1]` but does not re-check `isCompleted(heroIndex)`. If any future state ever placed `heroIndex` on a completed-but-not-all-done session, the left panel would render it as a non-tappable `CompletedSessionCard` while `_TabletSessionDetailPanel` would still show a "Start" CTA for it. Currently UNREACHABLE: `TodaySessionCubit` (`_pickHeroIndex`/`_onLogsChanged`/`swapHero`) guarantees the hero never sits on a completed index unless all sessions are complete (in which case the `allDone` branch shows `_AllDoneWidget`). The phone layout is structurally immune (partitioned lists); the tablet layout depends on the cubit invariant. Optional hardening: add a completion-aware guard/assert in `_TabletTodayLayout`. [today_page.dart `_TabletTodayLayout.build`]
- **CR112-002 — `sessionAccentColor` hardcodes the cardio accent `Color(0xFFF0A1B0)`.** The shared helper hardcodes a color rather than reading a theme token, brushing against the project-context.md "no hardcoded colors" rule. Pre-existing helper, unchanged by Story 11.2 but now also consumed by the tablet detail panel. [session_card_helpers.dart `sessionAccentColor`]

## Deferred from: code review of story 12.1 (2026-06-03)

Items identified during the Story 12.1 WearOS feasibility spike code review. All are follow-up scope for Stories 12.2–12.4, not blocking the spike (build/install/render verified PASS on the `Wear_OS_Large_Round` AVD).

- **CR121-001 — Manifest lacks explicit WearOS watch-feature / standalone declarations.** `pulse_coach/wear/android/app/src/main/AndroidManifest.xml` is a stock phone manifest with no `<uses-feature android:name="android.hardware.type.watch">`, no `<uses-library com.google.android.wearable>`, and no `com.google.android.wearable.standalone` metadata. The watch feature is provided transitively by the `wear_plus` library manifest merge (so the spike still installs as a watch app), but 12.2 should self-declare watch identity and decide standalone-vs-paired. [pulse_coach/wear/android/app/src/main/AndroidManifest.xml]
- **CR121-002 — `minSdk` uses the Flutter default (21) instead of a Wear OS-appropriate floor.** The wear module inherits `flutter.minSdkVersion` (~21); the phone app pins `minSdk = 26`. Build + install on the API 36 AVD passed, but Wear OS 3+ tooling/Play expects `minSdk ≥ 30`. 12.2 must pin minSdk explicitly after deciding the minimum supported Wear OS version. [pulse_coach/wear/android/app/build.gradle.kts]
- **CR121-003 — Minimal UI is not scrollable and has no textScale clamp.** `main.dart`'s `Column(mainAxisSize.min)` of Text + gap + button sits in `Center`+`Padding(32)` with no scroll fallback and no `MediaQuery` textScaler clamp. Static spike labels render fine at 454×454, but real content / large accessibility font scale risks vertical RenderFlex overflow and round-bezel corner clipping (a flat 32px pad is not radius-aware). 12.2–12.4 should use a scrollable Wear container. [pulse_coach/wear/lib/main.dart:55]
- **CR121-004 — Ambient frame is not burn-in / low-bit safe.** In `WearMode.ambient` the only change is `onPressed: null`; the frame still renders a filled `Scaffold` + `ElevatedButton` on a seeded dark surface. Always-on guidance requires a dimmed/black background, no large filled regions, and burn-in-safe content. Note `wear_plus 1.2.4` hardcodes `AmbientDetails(false, false)`, so even reading burn-in/low-bit flags yields false. Ambient correctness is out of spike scope. [pulse_coach/wear/lib/main.dart:33]
- **CR121-005 — `AmbientMode`/`WatchShape` builders discard their `child` → full `MaterialApp` rebuild on every ambient toggle.** Both builders receive a `child` arg that is ignored, so the entire `MaterialApp` subtree rebuilds on each `active↔ambient` transition. Not a correctness bug; low-priority efficiency note for the frequently-toggling always-on path. [pulse_coach/wear/lib/main.dart:15]

## Deferred from: code review of 12-2-in-session-wearos-display (2026-06-03)

- **CR122-001 — Best-effort session-end with no watch-side timeout.** The `/pulsecoach/session/end` message is sent fire-and-forget (`unawaited(stop())` in `_handleState`, `unawaited(_wearBridge?.stop())` in `InSessionPage.dispose`), there is no sequence guard against a late active-frame arriving after `end`, and the watch has no liveness/heartbeat timeout. A dropped `end` message or an ungraceful phone exit can strand the watch UI on a stale active session (its only exit is an `isEnded` state). Squarely the scope of Story 12.4 (WearOS disconnect resilience). [wear_bridge_service.dart `stop`/`_handleState`, in_session_page.dart `dispose`, wear/lib/communication/phone_bridge.dart, wear/lib/main.dart `_WearRoot`]
- **CR122-002 — Empty `steps` crash invariant (pre-existing).** `_onCountdownComplete` constructs `InSessionCubit` (which dereferences `steps.first`) and `WearBridgeService._handleState` reads `state.currentStep` (`steps[currentStepIndex]`); neither guards against an empty step list. Pre-existing assumption that `SessionStepGenerator.generate` never returns empty — not introduced by Story 12.2, which merely adds a second unguarded access on the same invariant. [in_session_cubit.dart, lib/.../utils/wear_bridge_service.dart]

## Deferred from: code review of 12-3-post-session-wearos-summary (2026-06-04)

- **CR123-001 — Empty (non-null) `sessionType` renders a blank-title summary instead of the AC4 end fallback.** `WearBridgeService._handleState` discriminates summary-vs-end on `sessionType != null`; an empty-but-present string is non-null so it routes to the summary path, and `PhoneBridge._parseSummaryState`'s `is! String` guard passes (empty IS a String), so the watch renders an empty title line above the duration. `PlannedSession.sessionType` is `required String` sourced from the AI generator ('mobility'/'cardio'/'breathing'), so empty is not a real input today — edge hardening only. [pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart:62, pulse_coach/wear/lib/communication/phone_bridge.dart `_parseSummaryState`]
- **CR123-002 — `_WearRoot` `StreamBuilder` has no `initialData` and the bridge stream is `.broadcast()` (pre-existing 12.2 architecture).** A summary frame arriving while no listener is attached is dropped with no replay; unlike `SessionDisplayPage` (which seeds `initialData`), `_WearRoot` relies purely on live broadcast events. Low likelihood — `_WearRoot` is the always-mounted root and Task 7 device verification confirmed the summary renders. Not introduced by Story 12.3. [pulse_coach/wear/lib/main.dart `_WearRootState.build`, pulse_coach/wear/lib/communication/phone_bridge.dart `_statesController`]

## Deferred from: code review of 12-4-wearos-disconnect-resilience (2026-06-04)

- **CR124-001 — `_ended`/`_terminalPayload` never reset in `start()`.** A reused `WearBridgeService` instance would, after a terminal state, drop every frame of a second session (`if (_ended) return` in `_handleState`) and could re-send the prior session's stale `_terminalPayload`. Latent only: `InSessionPage._onCountdownComplete` constructs a fresh `WearBridgeService` per session, so reuse does not occur today. Defensive reset would harden against future reuse. [pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart:66-75,91-92,108]
- **CR124-002 — In-flight poller-tick race if `_startReconnectPoller` re-invoked.** The periodic callback is `async` and awaits `_isWatchReachable()`; if the poller were re-armed during that await, the stale tick would resume and cancel the freshly-armed `_reconnectPoller`/`_reconnectDeadlineTimer` via shared instance fields, killing the new poller early. Latent only: the terminal path is `_ended`-guarded so `_startReconnectPoller` runs at most once per instance. [pulse_coach/lib/features/session/presentation/utils/wear_bridge_service.dart:135-158]
- **CR124-003 — Startup application-context hydration drop / duplicate emission.** `_emitReceivedApplicationContexts` fires from the `PhoneBridge` constructor and adds to a `.broadcast()` controller; an event added before a listener attaches is dropped (no replay). Separately, a context delivered via both the `receivedApplicationContexts` snapshot and a `contextStream` event is emitted twice. Low likelihood (the WearRoot listener attaches synchronously before the async hydration future completes; duplicate emission is idempotent for rendering). [pulse_coach/wear/lib/communication/phone_bridge.dart:84-85,94-95,101-109]
- **CR124-004 — Application-context sync path lacks direct test assertions.** ~~`_RecordingWatchMessagingClient` records both `messages` and `contexts`, but no test asserts on `contexts`.~~ **RESOLVED in the same review (D1 ratification):** added "mirrors every outbound payload into application context for reconnect recovery", asserting both active-tick and terminal-summary contexts. [pulse_coach/test/widget/session_wear_bridge_service_test.dart]
- **CR124-005 — "auto-cancels after 60s" poller test under-pins the boundary.** Uses `greaterThan` plus snapshot-equality but does not pin exact behavior at the 60s tick, where the periodic 60s tick races the deadline cancel under `fakeAsync` — an extra boundary send would not be caught. Minor test hardening. [pulse_coach/test/widget/session_wear_bridge_service_test.dart:444-485]

## Deferred from: code review of story-13.2 (2026-06-04)

- **13.2-CR-DEF1 — Handler-registration-vs-`start()` ordering race.** `SyncManager.start()` runs in `main.dart` immediately after DI, before any feature calls `registerHandler`; startup-pending entries hit the no-handler path and sit un-retried until the next connectivity flap. Not actionable in v1: the MVP registers no handlers yet (Dev Notes: "handlers map will be empty in initial wiring"); zero-delete on unknown type is by design and tested (13.2-SYNC-007). [pulse_coach/lib/core/sync/sync_manager.dart `processQueue`] — deferred, MVP has no handlers yet
- **13.2-CR-DEF2 — Unbounded fetch / no `LIMIT` in `getPendingEntries()`.** Selects the entire `sync_queue` table and `processQueue` awaits every handler serially; a large offline backlog is drained in a single pass with no batching or time budget. Scalability concern on the pre-existing DAO, not a regression of this change. [pulse_coach/lib/core/database/daos/sync_queue_dao.dart `getPendingEntries`] — deferred, pre-existing DAO design
- **13.2-CR-DEF3 — Sub-second precision / ordering ties.** Drift's default `DateTimeColumn` stores epoch seconds, so `createdAt` truncates and oldest-first ordering is non-deterministic for entries enqueued within the same second; a `nextRetryAt` of `now + 1 min` can become due ~1s early after round-tripping. Pre-existing schema behavior; the code's own `toUtc()` handling is correct. [pulse_coach/lib/core/database/tables/sync_queue_table.dart] — deferred, pre-existing drift schema behavior
## Deferred from: code review of 14-4-ai-decision-log-mvp-if-time (2026-06-05)

- N+3 sequential DB round-trips per decision with no plan caching (`pulse_coach/lib/features/settings/data/repositories/ai_decision_log_repository.dart:23-32`). Each feedback row sequentially awaits `getLogById` → `getPlanById` → `jsonDecode`+`fromJson`; the same plan is re-decoded when multiple sessions share it. Performance-only, on a debug-only screen — batch the lookups or memoize decoded plans by id if the log ever moves out of debug scope.

## Deferred from: code review of 14-5-data-export-mvp-if-time (2026-06-05)

- Weekly summaries grouped by UTC-Monday, not local week (`pulse_coach/lib/features/settings/data/services/data_export_service.dart:123`). A session completed late Sunday local time (UTC+1/+2) buckets into the next UTC week. Deferred, pre-existing: `_mondayOf` is byte-identical to `ProgressLocalDataSource._mondayOf` (copied per spec), so the export is internally consistent with the rest of the app; switching to local-week boundaries is an app-wide decision, not this story's scope.

## Deferred from: code review of story-17.1 (2026-06-22)

- Double `Purchases.getCustomerInfo()` per check (datasource + `gate.refresh()`). Acceptable — RevenueCat local-cache read <5ms; revisit if it becomes hot. [entitlement_repository_impl.dart:16-21]
- `unawaited(_gate.refresh())` race: `gate.check()` lags the bool returned to the bloc. No synchronous consumer of `check()` exists yet; revisit when gating UI lands. [entitlement_repository_impl.dart:20]
- Non-onboarding profile inserts (restore/import) leave `install_cohort` NULL — neither `pre_v2` nor `post_v2`; column has no table-level default. Needs restore-path audit in a later subscription story. [user_profile_table.dart / onboarding_repository_impl.dart]

## Deferred from: code review of story-17.4 (2026-06-22)

- **purchasePro re-fetches offerings** [`entitlement_repository_impl.dart:55-65`] — on purchase the repo calls `Purchases.getOfferings()` a second time to resolve `packageId → Package`, adding latency and a non-deterministic failure path ("Pacchetto non trovato") if the network blips or offerings rotate between page load and tap. Fix properly by threading the already-loaded `Package` from `PaywallCubit` through to `purchasePro`. Deferred: cross-layer refactor, not surgical; happy path is correct.
- **Hardcoded Italian UI strings bypass gen_l10n/ARB** [`settings_page.dart`, `paywall_page.dart`] — "Abbonamento", "Gestisci abbonamento", "Scopri Pro", "PulseCoach Pro", "Sblocca l'esperienza completa", "Acquista", "Ripristina acquisti" are inline literals while the rest of the app routes copy through `app_it.arb`. Deferred: the spec prescribes these literals and the app is locale-locked to `it`; address in an epic-wide i18n pass.
- **No automated test for AC4 (launchUrl / platform URLs)** [`settings_page_test.dart`] — the Pro-only "Gestisci abbonamento" tile that calls `launchUrl(..., LaunchMode.externalApplication)` is never rendered in tests (stub repo returns free tier), so platform-URL branching is unverified. Pairs with the launchUrl error-handling patch.

## Deferred from: code review of story-18.2-friend-request-flow (2026-06-24)

- `_onSearch` discards the fetched profile and triggers a full reload when state is not `loaded` (`lib/features/social/friends/presentation/bloc/friends_bloc.dart:71-77`) — low real-world impact, page loads before search is possible.
- Sent request only flips a global `requestSent` flag (no reload / no `pendingRequests.sent` update; flag is not per-target) (`lib/features/social/friends/presentation/bloc/friends_bloc.dart:82-91`) — AC3 still satisfied.
- No empty-state when a Pro user has zero friends and zero requests (`lib/features/social/friends/presentation/pages/social_page.dart`) — UX enhancement.
- Rapid accept/decline/remove enqueue multiple `FriendsLoaded`, causing shimmer re-entrancy/flicker with no in-flight guard (`lib/features/social/friends/presentation/bloc/friends_bloc.dart`) — low impact.
- Empty/whitespace handle search queries `display_handle == ''` (`lib/features/social/friends/presentation/bloc/friends_bloc.dart:67`) — handle setup enforces non-empty handles.
- Directional unique constraint allows reciprocal A→B and B→A duplicate friendships (`supabase/migrations/0003_friendships.sql:12`) — acknowledged in Dev Notes ("Unique Constraint Direction").
- BLoC tests rely on state-equality dedup for not-found control flow (`pulse_coach/test/bloc/friends_bloc_test.dart`) — test-quality smell.

## Deferred from: code review of story-18.4 (2026-06-24)

- `_thisWeekMinutes` relies on byte-identical `DD/MM` label coupling between `GetOwnWeeklySummaryUseCase` (get_own_weekly_summary_use_case.dart:188-200) and `ProgressLocalDataSource`. Happy path verified correct; any future format change (adding year, switching to local time) silently zeroes "own minutes" with no error. Extends existing E10R-2 concern — add a non-UTC regression test in `test/domain/social/get_own_weekly_summary_use_case_test.dart`. Not new Category A debt.
- Handle-less friend renders as `@<uuid>` in the comparison list (SQL `COALESCE(display_handle, p.id::text)` in 0007_friends_progress_rpc.sql:37, mirrored by friend_progress_dto.dart fallback). Low-probability since handle setup is enforced in Story 18.1; UX-only, not a data leak. Consider a localized "(senza handle)" fallback if it ever surfaces.

## Deferred from: code review of story-19.0 (2026-06-25)

- Back-fill INSERT in 0008_handle_new_user_trigger.sql lacks `ON CONFLICT (id) DO NOTHING` — marginal in-migration TOCTOU race vs trigger; already applied to prod (0 rows). Add for parity if 0008 re-run on fresh env. [0008:39]
- Invalid-email error taxonomy covers only `email_address_invalid`; sibling GoTrue codes (email_exists, weak_password, signup_disabled, rate-limit) fall through to generic error. Out of AC4 scope — future enhancement. [auth_repository_impl.dart:120]
- Sentinel `'email_address_invalid'` duplicated as magic string across repo + UI; consider extracting a shared const. Story intentionally used the literal. [sign_in_sheet.dart:214]

## Deferred from: code review of story-19.1 (2026-06-25)

- **Late-subscriber stream race** [realtime_gateway.dart:24] — `broadcastEvents`/`presenceUpdates` getters return `const Stream.empty()` before `joinChannel` and a fresh broadcast-controller stream after; no replay/seed. A consumer holding a reference taken before join (or after leave) gets a dead stream; events emitted between `subscribe()` and the first `.listen()` are dropped. Resolve in Story 19.2 when `SharedSessionBloc` wires consumption (consider seed-on-subscribe or a BehaviorSubject-style replay).
- **No error handling / subscribe status unobserved** [realtime_gateway.dart:30] — async Supabase calls (`sendBroadcastMessage`, `track`, `untrack`, `unsubscribe`, `removeChannel`) are unwrapped, and `subscribe()` is called with no status callback, so channel-error/timeout joins look identical to a healthy quiet channel. `RealtimeFailure` exists but is never thrown. Wire error surfacing in Story 19.2 via `Either<RealtimeFailure, ...>` at the bloc boundary (per story spec scope note).
- **Gateway lifecycle untested** — join/leave/presence emission/stream teardown have no coverage; only static `parseBroadcast` + freezed entity equality are tested. Story 19.2 mocks the gateway at the bloc boundary; add integration-level coverage there.
- **Presence id hygiene** [realtime_gateway.dart:94] — `_emitPresenceState` does not filter empty `user_id` (`?? ''`) or de-dup duplicate presences, producing ghost/duplicate participants in the emitted `PresenceState`. Resolve in Story 19.2 presence-lobby UI.

## Deferred from: code review of story-19.2 (2026-06-25)

- Follower that misses the `session_started` broadcast is stuck in `lobby` forever — `StepAdvanced` requires `inSession`, no resync path (19.3 drop-out/resync scope).
- `SessionEnded` emits `initial()` → lobby page renders blank `SizedBox.shrink()` with no navigation pop (19.3 full teardown scope).
- `error` state is a dead-end: `_ErrorView` says "Riprova" but has no retry event/action; join/start failure leaves subscriptions live until `close()` (page not user-reachable until 20.1 wires navigation).
- Route bad/null `extra` → blank `SizedBox.shrink()` (no Scaffold, no escape) — spec-sanctioned; 20.1 owns the navigation entry.
- Presence robustness cluster: presence drops during `inSession` ignored (stale count / solo continuation); unparseable `step_advanced` payloads silently dropped (follower drift); duplicate participant identities can inflate the `>=2` start gate (19.3 drop-out tolerance + presence dedup).
- `_onHostStepAdvanced` swallows broadcast failure with empty `catch (e)` (no log/telemetry) — observability; 19.3 handles persistent failure.
- `_onJoined` subscribes to streams only after `await joinChannel`/`trackPresence` — narrow lost-event window + partial-setup dangling channel on `trackPresence` throw (minor; host subscribes before any start in practice).

## Deferred from: code review of story-19.3 (2026-06-25)

- `droppedHandle` surfaces only one participant on simultaneous multi-drop [shared_session_bloc.dart:120-122] — explicitly accepted in story "Known Post-19.3 Gaps".
- Host's drop note persists across step changes — host ignores its own `step_advanced` echo so never clears `droppedHandle` [shared_session_bloc.dart:120 vs 158-161]; minor UX inconsistency vs follower.
- `SessionEnded` honored in any state can mask an `error` state or skip the lobby [shared_session_bloc.dart:176-182] — semi-per-spec (AC4: any participant receiving sessionEnded emits sessionEnded).
- No dedup of duplicate `user_id` entries in presence mapping [realtime_gateway.dart:137-146] — pre-existing from gateway 19.1.
- Out-of-range `stepIndex`/`elapsedSeconds` stored unclamped in state; clamp lives only in the view [shared_session_bloc.dart:155-172] — pre-existing pattern from 19.2.
- Subscriptions not cancelled on `SessionEnded`, only on `close()` [shared_session_bloc.dart:176-182] — streams complete via `leaveChannel`; leak only on same-bloc re-use.

## Deferred from: code review of story-20.1 (2026-06-25)

- Follower can trigger `DeleteSharedSessionUseCase` via `SharedSessionCancelled` (no `_isHost` guard in `_onCancelled`). Host-guard explicitly assigned to Story 20.3; today's UI cancel is host-only and RLS rejects a non-host delete. [shared_session_bloc.dart:141-158]
- Cancel emits `cancelled()` even when the delete fails or matches 0 rows. Documented design (Task 8.2f: navigate the host back regardless of delete outcome; worst case is a stale, RLS-protected `shared_sessions` row). Pairs with the cleanup item below. [shared_session_bloc.dart:152]
- Stale `waiting` `shared_sessions` rows accumulate and the global UNIQUE `join_code` namespace is never freed (no expiry/cleanup job). Documented future work — cleanup Edge Function or row TTL. [supabase/migrations/0009_shared_sessions.sql]
- Join-code collision detection relies on `e.toString().contains('unique'/'23505')`, which is brittle. Retry path probability is ~10⁻⁶; prefer matching `PostgrestException.code == '23505'` when this datasource is next touched. [shared_session_remote_data_source.dart:42-43,59-61]

## Deferred from: code review of story-20.5 (2026-06-27)

- Reconnect/late-join via `StepAdvanced` snap renders a default `mobility/medium/20` session (plan params are not carried in that event) and leaves `_lastSteps` stale → wrong RPE duration. Reconnect flow out of scope since Story 20.4. [shared_session_bloc.dart `_onBroadcastReceived` + shared_session_lobby_page.dart `inSession:`/`sessionEnded` listener]
- `inSession.steps` field is now vestigial — the page always regenerates steps via `SessionStepGenerator` and never reads `s.steps`. Removal touches `_SharedInSessionView` ctor (out of scope per Task 3.1 note). [shared_session_state.dart]
- `_armKey` is never reset on `SessionEnded`; on a reused bloc instance the follower `??=` path would keep the previous session's arm key. Currently safe — bloc is `@injectable` factory-scoped per route. [shared_session_bloc.dart]
- Only the host's profile (with hardcoded `fitnessLevel: 'medium'`, `movementExclusions: {}`, `availableTimeMinutes: 20`) feeds `GroupConstraintResolver`; followers' safety caps/time constraints are ignored. Documented MVP limitation (dev notes "MVP Limitation: Only Host's Profile"). [shared_session_bloc.dart `_onStartTapped`]

## Deferred from: code review of story-21.0 (2026-07-02)

- **Abandoned shared-session rows report 0 weekly minutes** — `RpeFeedbackCubit._resolveSessionLogId` inserts the shared-session `SessionLog` without `elapsedSeconds`, so `ProgressLocalDataSource.getProgressStats` computes `(elapsedSeconds ?? 0) ~/ 60 == 0` for any abandoned entry. Not reachable today because shared sessions hardcode `abandoned: false`; becomes a live data-quality bug when host-abandon fidelity (a new `session_ended` broadcast field) is wired. Revisit together with that out-of-scope protocol change. [rpe_feedback_cubit.dart, progress_local_data_source.dart:143]

## Deferred from: code review of story-21.2 (2026-07-04)

- **Error/empty/loading states show a non-retryable shimmer** (`pulse_coach/lib/features/social/leaderboard/presentation/pages/leaderboard_page.dart:54`) — on load failure the user sees a transient SnackBar then a permanent loading skeleton; RefreshIndicator is only wired in the non-empty `loaded` branch. Pre-existing feature-wide pattern, identical to `ProgressComparisonPage`. Belongs to a social-wide error-UX pass, not this story.
- **RPC drops own row if viewer has no `profiles` row; `COALESCE` fallback is dead** (`supabase/migrations/0012_friends_leaderboard_rpc.sql:48`) — the final `JOIN profiles p ON p.id = vu.uid` is an INNER join, so the `COALESCE(p.display_handle, vu.uid::text)` fallback can never fire. Theoretical (profiles guaranteed in practice; migration unapplied/untested). Fix later by LEFT-joining the own row.
- **Frozen-rank SharedPreferences key not user-scoped** (`pulse_coach/lib/features/social/leaderboard/data/rank_freeze_store.dart:9`) — single global `leaderboard_frozen_rank` int; on account switch on the same install a stale pin from account A can leak into account B's leaderboard. Depends on the multi-account/sign-out model (21.1's install-id precedent is also install-scoped). Revisit if account-switching becomes supported.

## Deferred from: code review of story-21.3 (2026-07-04)

- Points inflation via client-supplied `arm_key`/`duration_minutes` in `score_shared_session/index.ts` — pre-existing accepted trust model; the shipped solo `award_session_points(p_base_points int)` trusts the client value even more directly. Both bounded identically by the 200/day cap.
- Partial award failure mid-loop after `scored=true` is claimed → participant permanently unpaid (`index.ts:57-71`). `scored=true` is claimed before the award loop; a mid-loop RPC error is swallowed and never retried.
- Last-submitter Edge invoke failure / near-simultaneous read race → session never scored (`leaderboard_remote_data_source.dart:149`). Explicitly documented as an accepted known limitation in the story.
- Unknown/empty `arm_key` falls through to the highest weight 2.0 (`index.ts:12`). Faithfully mirrors Dart `ScoringConstants.intensityWeightFor` else-branch; fixing only TS breaks the documented parity.
- RPE not range-validated; hostile client `p_rpe > 32767` overflows `smallint` (`0013_shared_session_scoring.sql`). Self-harm only, not an inflation vector; matches existing no-server-clamp philosophy.
- Edge Function empty/non-JSON body → uncaught throw → opaque 500 instead of 400 (`index.ts:37`). Cosmetic; internal function.
- Shared flow completing with `sessionId == null` (session ended before join) → session silently unscored (`rpe_page.dart:81-93`). Low-probability, no regression.
- Drop-out / never-submitting participant blocks the entire group's bonus indefinitely (`score_shared_session/index.ts`). Deferred to follow-up Story 21.4 (see epics.md): needs a pg_cron server-side sweep with a grace window that scores active-only participants; not reachable from index.ts alone under the client fire-and-forget trigger.

## Deferred from: code review of story-21.4 (2026-07-04)

- No `LIMIT`/batching on the sweep's candidate query (`0014_shared_session_scoring_sweep.sql:33-37`). A large first-run backlog processes in one long transaction holding per-owner advisory locks + `scored` row locks for the whole batch; a run exceeding the 5-min interval lets pg_cron start an overlapping run that contends on those locks. Spec §"Known, Accepted Limitations" explicitly accepts fixed-interval/no-batching at v2.5 friends-only volumes — revisit if shared-session volume grows.
- `CREATE EXTENSION pg_cron` + `cron.schedule` deployment caveat (`0014_shared_session_scoring_sweep.sql:11,94-98`). pg_cron must be enabled for the target Supabase project, and cron jobs run in pg_cron's home database; verify on apply that `sweep_unscored_shared_sessions()` and the `shared_sessions`/`session_participants` tables are resolvable from the cron worker's execution context. Ops/deployment verification, not a code fix.

## Deferred from: code review of story-22.1 (2026-07-06)

- `trackWidth <= 0` unguarded in `_MilestonePainter.paint` (`milestone_progress_bar.dart:141`). When available width < 16dp (`2 * _finishMarkerRadius`), `trackWidth = size.width - 16` goes negative, producing a negative-width rail `RRect` and a left-of-origin finish marker. No crash (the `fillWidth > 0` guard suppresses the fill path), and unreachable in the current `InSessionView` layout where the bar sits in a padded bounded `Column`/`Expanded`. Robustness-only — add a `trackWidth <= 0` early-return if the widget is ever reused in a tighter container.

## Deferred from: code review of story-22.3 (2026-07-07)

- Live update in `TodaySessionCubit._onLogsChanged` is narrower than "any completion": the `setEquals` early-return precedes the `activeDaysCount` recompute, so a completion that doesn't change the current plan's completed-index set — or a shared-session completion (`dailyPlanId == null`, never observed by `watchLogsForPlan(planId)`) — won't live-refresh the active-days count until the next `planLoaded`. AC5 is satisfied for the specified hero-session-completion scenario. Broadening would require a full-table query on every no-op log event or a new subscription the story explicitly forbids.

## Deferred from: code review of story-22.5 (2026-07-07)

- **Snapshot only written on `AppLifecycleState.paused`** [pulse_coach/lib/features/session/presentation/pages/in_session_page.dart:160] — `didChangeAppLifecycleState` handles only `paused`/`resumed`; an OS fast-kill from `hidden`/`detached`/`inactive` that never passes through `paused` persists no `BackgroundedSessionSnapshot` and posts no notification, so the backgrounded session cannot be reconciled or auto-abandoned on next launch. Pre-existing lifecycle-coverage gap inherited from Story 22.4's notification wiring; low reachability on current Android/iOS paths.
