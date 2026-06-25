# Claude Notes

## Project Layout

- Flutter app root: `pulse_coach/`.
- Repository/workspace root: `Flutter_PulseCoach/`.
- Run Flutter commands from `pulse_coach/` unless a task explicitly concerns root-level docs or BMad artifacts.

## Code Search

Use `semble search` (via `uvx --from "semble[mcp]" semble`) to find code by intent rather than by keyword:

```bash
# Semantic / intent queries — no need to know the exact symbol name
uvx --from "semble[mcp]" semble search "how hero session index is selected" ./pulse_coach
uvx --from "semble[mcp]" semble search "session completion persistence" ./pulse_coach --top-k 5

# Once you have a promising chunk, discover related implementations
uvx --from "semble[mcp]" semble find-related lib/features/today/presentation/cubit/today_session_cubit.dart 1 ./pulse_coach
```

### When to use each tool

| Situation | Tool |
|---|---|
| Don't know the file/symbol name — describe the behaviour | `semble search` |
| Exploring an unfamiliar feature area | `semble search` |
| Find tests and related code for a known file | `semble find-related` |
| Replacing an `Explore` agent for a focused question | `semble search` |
| Confirm all usages of an exact symbol | `grep -r` |
| Already know the file path | `Read` directly |

**Note:** `find-related` paths must be relative to the directory argument (e.g. `lib/...`, not `pulse_coach/lib/...`). First run downloads ~10 MB of dependencies; subsequent runs are fast.

## Test And Build Baseline

- Test command: `flutter test` from `pulse_coach/`.
- Android debug build command: `flutter build apk --debug` from `pulse_coach/`.

## Manual Verification Notes

- App installed and launched successfully on the physical Android device.
- Disclaimer screen rendered correctly and accepted successfully.
- Onboarding carousel rendered and advanced correctly.
- Profile setup screen was reachable and selectable.
- Full onboarding completion was verified on device: selecting Beginner/Cardio/2-5 min/None enabled `Start My Plan`, which navigated to the main shell.
- Bottom tabs were manually verified on device: Today, Sessions, and Progress all navigated without crash. As of Epic 6.5.1, tab order is now `Sessions, Today, Progress` (matching UX spec) — Today is index 1, Sessions is index 0.
- Drawer opened correctly and showed Profile, Settings, Privacy, and Debug entries.
- Force-stop + relaunch after onboarding completed returned directly to Today, confirming onboarding/profile persistence and router redirect behavior.
- Visual issue found on Android 8 / 1080x1920: in the profile form, `Strength` wraps awkwardly as `Strengt` / `h` inside the `Primary Goal` segmented control.
- Today screen now renders the full Epic 7 layout: state bar with `StateIndicator` + animated `CompletionRing`, `HeroSessionCard` with regenerate `IconButton`, `CompletedSessionCard` stack, "COMING UP" list of `CompactSessionCard`s, shimmer loading, in-page hero swap via `AnimatedSwitcher`. Real `DailyPlanBloc` + `TodaySessionCubit` wired at the route level (no `getIt` in `TodayPage.build`).
- **E7-F1 closed (2026-05-17, via Story 8.2 code review).** Session completion now persists through the `SessionLogs` table (Story 8.0) AND surfaces live in the Today UI: `SessionLogsDao.watchLogsForPlan(int)` exposes a Drift-native stream, and `TodaySessionCubit.planLoaded` subscribes (with `.skip(1)`) to reconcile `completedIndices`/`heroIndex` whenever any writer touches the table — including `InSessionCubit._persistCompletion`. Single source of truth = the DB; no manual signal required across cubits.
- Sessions tab now renders the real catalog browsing screen (Epic 6.3): filter chips, shimmer skeletons, detail sheet. Progress still renders the placeholder `Progress - Story 10.x`.
- There was no Android emulator configured at that time; Flutter listed only `iOS Simulator`.

## Feature Context

- Recent Epic 5 changes cover daily plan generation, AI isolate execution, daily plan persistence, regeneration, and AI explanations.
- Epic 6 shipped the Exercise Catalog: ExerciseDB integration + cache + 24h TTL, 30-exercise bundled fallback (10 mobility / 10 cardio / 10 breathing, all indoor-compatible), and the Sessions browsing screen (first real non-placeholder primary screen).
- Epic 6.5 (interstitial Foundation Hardening, closed 2026-05-15) closed `flutter analyze` to 0, aligned AppShell tab order with UX spec, added catalog defense-in-depth (read-path normalization, fallback ID dedup), introduced `Failure` structural equality via `Object.hash(runtimeType, message)`, created the action-item ledger at `_bmad-output/implementation-artifacts/action-item-ledger.md`, and bumped six dependency major-version clusters.
- Epic 7 product reviews closed on 2026-05-15 and were consumed by Epic 7 stories: state-graph decisions implemented in Stories 7.1 (Q2 + Q3) and 7.1b (Q1); explanation copy decisions shipped as the 15 canonical Italian keys (originally in `state_messages.it.arb`, now folded into `pulse_coach/lib/l10n/app/app_it.arb` via Epic 7.5). `BehavioralStateMachine` now carries its final 6-rule shape. Story 7.0 closed the `Failure` equality BLoC re-emission regression test before any consumer mounted.
- Epic 7 closed on 2026-05-16. Retrospective at `_bmad-output/implementation-artifacts/epic-7-retro-2026-05-16.md`. Two scope insertions decided in retro:
  - **Epic 7.5 — i18n / `gen_l10n` migration (interstitial)** — **CLOSED 2026-05-16**. Cap of 2 stories honored. Both stories shipped; ARB pipeline live; `"COMING UP"` translated to `"PROSSIME"`. Retro at `_bmad-output/implementation-artifacts/epic-7.5-retro-2026-05-16.md`.
  - **Story 8.0 — SessionLog DAO + per-session completion persistence** before Story 8.1. Closes E7-F1; folds in `_isSamePlan` heuristic refactor (Story 7.3 deferred item).
- `gen_l10n` is **wired** (closed by Epic 7.5). `flutter_localizations` is a direct dependency; ARB inputs live under `pulse_coach/lib/l10n/app/` (`app_en.arb`, `app_it.arb`); generated `app_localizations*.dart` files are `.gitignore`'d and regenerated on every `flutter pub get`. (Reconciliation note: through 2026-05-17 these files were accidentally tracked in git despite this rule. Closed by Story 8.4 code review P8 — added to `pulse_coach/.gitignore` and removed from the index via `git rm --cached`.) The legacy `state_messages.it.arb` was deleted as part of Story 7.5.2. **i18n is now user-selectable IT/EN (2026-06-25):** `LocaleCubit` (`lib/features/settings/presentation/bloc/locale_cubit.dart`, `@lazySingleton`, persists `app_locale` in SharedPreferences, defaults to `it`) drives `MaterialApp.locale` reactively via a `BlocBuilder<LocaleCubit, Locale>` in `lib/app.dart` (the old hardcoded `locale: const Locale('it')` is gone). A "Lingua" `SegmentedButton` (Italiano/English) in `settings_page.dart` switches it live. The Epic-2 onboarding module (onboarding carousel, disclaimer, profile setup form + profile edit page) and the Epic-6 session catalog detail sheet were hardcoded English (they predated the Epic 7.5 migration, which only covered Epic 7/Today) — all migrated to ARB with both `it`+`en` translations in the same change. Note `intensityLow`/`intensityMedium`/`intensityHigh` are shared keys (Leggera/Moderata/Intensa · Light/Moderate/Intense) used by BOTH the Today hero card RPE label and the catalog detail difficulty pill — do not duplicate them. Widget/router tests that mount `PulseCoachApp` or `SettingsPage` must now also provide/register `LocaleCubit`.
- 7 `transition*` ARB keys are present in `app_it.arb` / `app_en.arb` but are **dead at the consumer**: `BehavioralStateMachine` (`lib/ai/state_machine/behavioral_state_machine.dart:35,44,53,68,81,94`) still emits hardcoded Italian literals into `BehavioralTransition.message`. Tracked as deferred item **E7.5-T1** with target Epic 9.x (re-targeted from Epic 8.x at Epic 8 Kickoff Triage 2026-05-17, Option B — keep Epic 8 thematically focused on in-session experience); do not delete the keys without consumer wiring.
- `vibration: ^3.1.8` is already present in `pulse_coach/pubspec.yaml` (line 50). Story 8.3 prerequisite already satisfied.
- **Deferred Items Budget — Epic 8 kickoff triage completed (2026-05-17).** Rule was rewritten to split Category A (Deliverable Debt, capped at 5) from Category B (Ongoing Process Rules, uncapped + sunset-reviewed). Post-triage state: Category A = 5 at cap; E7-F1 closed (Story 8.0/8.2 shipped); Category B = 5 ongoing protocols retained. Epic 8 sprint cleared to open. See "Epic 8 Kickoff Triage - 2026-05-17" section in `action-item-ledger.md`.

## Deferred Items Budget (process rule)

Introduced after the Epic 6.5 retro (2026-05-15) to break the recurring pattern of deferred items accumulating without an observable limit. Revised at Epic 8 Kickoff Triage (2026-05-17) to distinguish ongoing-process protocols from deliverable debt — the original single-cap form produced false positives by counting standing SOPs against the same budget as concrete work-to-be-done. This is a **process** control, not a technical one.

### Two categories, two caps

**Category A — Deliverable Debt** (capped: max **5 open**)

Concrete pieces of work that one day must either be done or formally killed. They have a finite life: shipping the work closes them.

What counts:
1. `TODO` / `FIXME` markers in code that carry an identified owner.
2. Action-ledger items describing specific tasks, refactors, fixes, or follow-ups with a target deliverable (e.g. "wire dead ARB keys", "memoize JSON decode", "add golden test infra").
3. Stories that have been created but are not yet scheduled into a sprint.
4. Product decisions explicitly deferred (e.g. pending reviews blocking an epic).

If the count exceeds 5, **no new stories enter the sprint** until triage brings it back to ≤ 5 (close, drop with rationale, or promote to a scheduled story). "Defer again" is not an option.

**Category B — Ongoing Process Rules** (uncapped, sunset-reviewed)

Standing protocols that fire on a trigger condition and live as long as the trigger remains useful. They are not work-to-be-done; they are how-we-work. Counting them against a deliverable cap creates pressure to silently drop SOPs, which is the wrong incentive.

What counts:
- Action-ledger items whose target is `Ongoing process` or whose description starts with "every time / whenever / triggered when…".
- Code-review skill rules, story-creation pre-flight checks, retro-template additions.

Sunset review: every 2 epics the PM walks Category B and asks, for each item, "still useful / now automated / safe to retire?". Items retired with a recorded rationale.

### Owner and cadence

- **Owner:** PM (John). Counted at **epic kickoff** and reviewed in every **retrospective**.
- **Visibility:** PM reports current Category A count plus the Category B sunset-review pass at kickoff and retros. Sprint-status artifacts may surface the numbers, but this CLAUDE.md rule is the source of truth for the cap.

### Historical note

The original single-cap form (2026-05-15 → 2026-05-17) tripped at Epic 8 kickoff with 11 items vs cap of 5. Triage classified the 11 as 5 ongoing-process protocols + 5 deliverable-debt items (+ 1 already-shipped item to close as `done`). The rewrite formalizes the split rather than dropping protocols just to fit the number. Triage decisions are recorded in `_bmad-output/implementation-artifacts/action-item-ledger.md` under the "Epic 8 Kickoff Triage - 2026-05-17" section.
