---
baseline_commit: a58f24643dec900c7b9a6517bbcb05ce949229aa
---

# Story 22.2: Decision-Factor Iconography (FactorIconRow)

Status: done

<!-- Note: Validation is optional. Run validate-create-story for quality check before dev-story. -->

## Story

As a user reading a session recommendation,
I want to see quiet icons for the factors that drove it,
So that the reasoning behind the recommendation is visible at a glance.

## Context

**Epic 22, second story.** Second story of "Experience Polish (v1)"; no direct code dependency on 22.1 (`MilestoneProgressBar`, a different screen), but both are presentation/platform-layer polish over the existing v1 core. This story adds a `FactorIconRow` beneath `HeroSessionCard`'s `ExplanationLine` on the **Today** screen, showing which decision factors (exercise type, intensity, temperature, precipitation, AQI — **never humidity**) shaped today's recommendation.

### ⚠️ Read this before writing any "influence" logic — a real data gap exists

The epic's own framing says this story is **presentation-only... surfaces existing `WeatherContext` fields... introduces no new inference** (epics.md line 2893). Taken literally, however, AC2's wording ("the decision factors that **actually influenced** the recommendation") does not match what the codebase actually does today:

- `GenerateDailyPlan._buildStateVector()` (`lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:253-266`) computes `temperature` and `precipitation` and stuffs them into `StateVector`, but **grep confirms no consumer reads either field** anywhere in `lib/ai/` — `SafetyRules.apply()` (`lib/ai/safety/safety_rules.dart`) only reads `stateVector.aqiLevel` (via `WeatherContext.isAqiHigh`, `aqiValue >= 100`) to gate `outdoorAllowed`. Temperature and precipitation are **dead fields today** — they do not influence session selection, intensity, or indoor/outdoor routing in any way.
- Only **AQI** has a real, traceable causal path to the recommendation (via `SafetyRules` → `outdoorAllowed` → the AI engine's session routing).
- `exercise type` and `intensity` aren't "influences" in the same sense — they ARE the recommendation (`PlannedSession.sessionType` / `.intensity`), always present.

**Decision baked into this story (documented so Paolo can override before dev-story runs if he disagrees):**
- `exerciseType` and `intensity` are **always** shown (they describe the session itself, not a conditional signal).
- `aqi` is shown **only** when `WeatherContext.isAqiHigh` is true — this is the one factor with genuine causal weight today (reuses the exact existing FR8 rule, no new threshold).
- `temperature` and `precipitation` are surfaced as **informational context from the same cached `WeatherContext` used to generate today's plan**, using simple presentation-only display thresholds (below), **not** because they altered the AI's choice — because today they don't. Precipitation reuses the exact literal `precipitationProbability > 50.0` already written (but unused) in `generate_daily_plan.dart:265`. Temperature has no existing threshold anywhere in the codebase; this story introduces one purely for display (`<= 10.0°C` or `>= 28.0°C`) — call this out in your PR/commit as a new constant, not a rule change.
- **Do not** attempt to thread `WeatherContext` through `PlannedSession`/`DailyPlan`/Drift persistence to capture "what was true at generation time" — that's a real schema change (new freezed fields, JSON version bump, migration) far beyond what "presentation-only" implies. Instead, fetch the **current** cached `WeatherContext` independently in the Today UI layer via the already-injectable `GetWeatherContext` use case (`lib/features/weather/domain/usecases/get_weather_context.dart`) — same cache-first, 1h-TTL repository the AI pipeline itself uses, so this reads the same "as of today" snapshot without any schema change (mirrors Story 22.3's "single source of truth, no parallel counter" principle applied to *not duplicating storage*, not to the AQI counter itself).
- If wiring temperature/precipitation into an actual behavioral decision is ever wanted, that's a separate future story/deferred item — do not attempt it here.

### What already exists (DO NOT REBUILD)

- **`HeroSessionCard`** (`lib/features/today/presentation/widgets/hero_session_card.dart`) — the `ExplanationLine` is the `Text(session.explanation, ...)` block at lines 133-143, gated by `hasExplanation = session.explanation.trim().isNotEmpty`. `Explanation.text` is **guaranteed non-empty** by `ExplanationGenerator` (Story 5.6 contract, `lib/ai/explainability/explanation_generator.dart`), so `hasExplanation` is always true in real app flow — the `if` is defensive only. Insert `FactorIconRow` **inside that same `if (hasExplanation)` block**, immediately after the explanation `Text`, so it never renders detached from its anchor line.
- **`session_card_helpers.dart`** (`lib/features/today/presentation/widgets/session_card_helpers.dart`) — existing precedent for pure, `AppLocalizations`-driven presentation helpers (`sessionDisplayName`, `intensityLabel`, `sessionAccentColor`). Reuse `sessionDisplayName(session.sessionType, l10n)` for the exercise-type factor's tap-reveal text and `intensityLabel(session.intensity, l10n)` for the intensity factor's — **do not add new ARB keys for these two**, they already exist and are exactly "one-line textual factor" text.
- **48dp tap target on a small visual glyph** — `HeroSessionCard`'s own `onRegenerate` `IconButton` (lines 100-114) already does exactly this: 20dp icon inside `constraints: BoxConstraints(minWidth: 48, minHeight: 48)`. Mirror that sizing approach for each factor glyph's tap box (16dp icon centered in a 48×48 box) rather than inventing new sizing logic.
- **Reduce-motion gating precedent** — every existing animated component in this codebase (`CompletionRing`, `countdown_overlay.dart`, `MilestoneProgressBar` from Story 22.1) explicitly branches on `MediaQuery.disableAnimationsOf(context)` rather than relying on a widget to auto-degrade. Follow the same explicit pattern here (see Task 1 for exactly where).
- **`GetWeatherContext`** (`lib/features/weather/domain/usecases/get_weather_context.dart`) — already `@injectable`, already wraps `WeatherRepository.getWeatherContext()` (`Either<Failure, WeatherContext>`, cache-first with 1h TTL, indoor-safe defaults on failure per project-context.md). Inject this into `TodaySessionCubit` — do not create a new use case or repository call site.
- **`WeatherContext`** (`lib/features/weather/domain/entities/weather_context.dart`) — plain class (not freezed), exposes `temperature` (double, °C), `precipitationProbability` (double, 0–100), `aqiValue` (int) + `isAqiHigh` getter (`aqiValue >= 100`). Use `isAqiHigh` directly — do not re-derive the 100 threshold.
- **`TodaySessionCubit`** (`lib/features/today/presentation/cubit/today_session_cubit.dart`) — already the Today-page-scoped Cubit (not `DailyPlanBloc`) holding UI-only ephemeral state (`heroIndex`, `completedIndices`). This is the correct, existing seam for a new `weatherContext` field — do not add weather state to `DailyPlanBloc` (that Bloc's `DailyPlanLoaded` state already has a broad contract other stories depend on; do not touch it) and do not call `GetWeatherContext` directly from any widget (project rule: "never call use cases directly from widgets — always via Bloc/Cubit").
- **Critical: `planLoaded`'s null-`planId` fast path must stay synchronous.** `TodaySessionCubit.planLoaded()` (lines 58-97) has a documented invariant: on `planId == null` it emits synchronously with **no `await`** before the emit (comment at lines 59-61 explains why — avoids a microtask gap that could let a caller's `seed()` race ahead). **Do not fetch weather in that branch.** Only fetch weather in the `planId != null` branch, run it concurrently with the existing `_sessionLogsDao.getLogsForPlan(planId)` call (kick off both futures before awaiting either), and re-check `_currentPlanId != planId` (the same staleness guard already used at line 76) before folding the weather result into the emitted state.
- **Lucide icon package — two candidates, only one is usable.** DESIGN.md just says "Lucide"; it does not name a pub.dev package. Verified via `pub.dev` API + inspecting the downloaded archive:
  - `lucide_icons` (marchellodev fork) — **do not use**. Its pubspec `environment.sdk` is `>=2.12.0 <3.0.0`, incompatible with this project's `sdk: ^3.11.3` (`pubspec.yaml:8`) — `flutter pub get` will fail to resolve it.
  - `lucide_icons_flutter` — **use this one** (latest `3.1.14+2`, published 2026-05-25, `environment.sdk: ^3.0.0`, compatible). Confirmed exact icon accessors exist by inspecting the package source directly: `LucideIcons.dumbbell300`, `LucideIcons.gauge300`, `LucideIcons.thermometer300`, `LucideIcons.cloudRain300`, `LucideIcons.wind300` — the `300`-suffixed variants render at `stroke-width: 1.500` (verified from the embedded SVG doc-comments in the package source), which is exactly AC1's "1.5px stroke" requirement. The bare (no-suffix) names default to `stroke-width: 2` — **do not use the bare names**, use the `300` suffix.
  - Font registration is automatic (the package declares its own `flutter: fonts:` block) — no manual pubspec font entry needed beyond the dependency itself.

## Acceptance Criteria

**AC1 — FactorIconRow renders beneath ExplanationLine:**
Given a hero session recommendation with its `ExplanationLine`
When `HeroSessionCard` renders
Then a `FactorIconRow` of ~16dp Lucide glyphs (1.5px stroke — `LucideIcons.*300` variants, `onSurfaceVariant`) is shown directly beneath the `ExplanationLine`, reinforcing the existing FR13/FR14 explanation without introducing any new inference (FR82, DESIGN.md FactorIconRow).

**AC2 — Only applicable factors shown; no fixed five-slot row; no humidity:**
Given the decision factors for the current session (see "Decision baked into this story" above for exactly what counts as applicable)
When the row is built
Then only applicable factors are shown from: exercise type (always), intensity (always), temperature (shown when `weather != null && (temperature <= 10.0 || temperature >= 28.0)`), precipitation (shown when `weather != null && precipitationProbability > 50.0`), AQI (shown when `weather != null && weather.isAqiHigh`) — never a fixed five-slot row, and **humidity is never shown** (FR82).

**AC3 — Tap reveals one-line text; 48dp hit-area, non-overlapping:**
Given each factor glyph
When the user taps it
Then its one-line textual factor is revealed (exercise type → `sessionDisplayName`, intensity → `intensityLabel`, temperature/precipitation/AQI → new ARB strings, see Task 2); the visual glyph is ~16dp but its tap target is a ≥48dp transparent hit-area (mirror `HeroSessionCard`'s existing `onRegenerate` `IconButton` sizing pattern), and hit-areas do not overlap (FR82, NFR24).

**AC4 — Wraps at small width / high text scale, never truncates, never pushes Start button off:**
Given a small phone at 2.0× text scale where 5 targets will not fit the dense hero
When the row lays out
Then it wraps to a second line via a `Wrap` widget (never truncates, never pushes the Start button off the hero) (EXPERIENCE.md Accessibility Floor).

**AC5 — AQI attention tint; color never the sole carrier; per-glyph semantics:**
Given the AQI factor is shown (i.e., `isAqiHigh` is true — it is only ever shown in its attention-worthy state)
When its glyph renders
Then it tints `PulseCoachTheme.tertiary` amber as a redundant emphasis only (color is never the sole carrier — every glyph is shape-distinct via its Lucide icon, exposes its textual factor on tap, and carries a `Semantics` label with that same text) (FR82, NFR25, EXPERIENCE.md color-independence).

**AC6 — Reduce motion + frame budget; purely informational:**
Given the OS "reduce motion" setting is enabled (`MediaQuery.disableAnimationsOf(context) == true`)
When a factor glyph's tap-reveal is shown/hidden
Then the reveal transition is skipped (instant show/hide, no animated size/opacity tween) and the row's paint work honors the NFR2 60fps/≤16ms budget; the row is purely informational and never an action surface (no navigation, no state mutation) (FR82, NFR38).

## Tasks / Subtasks

---

### Task 1 — Add `lucide_icons_flutter` dependency (AC1)

- [x] **1.1** Add `lucide_icons_flutter: ^3.1.14` to `pulse_coach/pubspec.yaml` (place under the existing `# UI` section, after `cupertino_icons` or alongside `google_fonts`/`lottie` — matches existing grouping style). Run `flutter pub get` from `pulse_coach/`. **Do not add `lucide_icons`** (see Context — incompatible SDK constraint).

---

### Task 2 — ARB factor-label keys (AC3)

- [x] **2.1** Add 3 new keys to both `lib/l10n/app/app_it.arb` and `lib/l10n/app/app_en.arb` (placed near the existing `intensityLow`/`intensityMedium`/`intensityHigh` keys, `app_it.arb:74-76`):
  - `factorLabelTemperature` — parameterized by an `int` placeholder (rounded °C), e.g. IT: `"Temperatura: {value}°"`, EN: `"Temperature: {value}°"`. Add matching `@factorLabelTemperature` metadata block with `placeholders: {"value": {"type": "int"}}` (mirror the `@heroCardSemanticPreamble` metadata shape at `app_it.arb:24-33` for the block structure).
  - `factorLabelPrecipitation` — no placeholder, e.g. IT: `"Possibilità di pioggia"`, EN: `"Chance of rain"`.
  - `factorLabelAqi` — no placeholder, e.g. IT: `"Qualità dell'aria non ottimale"`, EN: `"Air quality not ideal"`.
  - Keep `it`/`en` parity (same keys, same placeholders, in both files).
- [x] **2.2** Run `flutter gen-l10n` (or `flutter pub get`, which triggers it via the `l10n.yaml`-configured pipeline) so `AppLocalizations` exposes the new getters — **not** `build_runner` (separate pipeline, confirmed by Story 22.1's Dev Notes and `l10n.yaml`).

---

### Task 3 — `FactorIconRow` widget + pure derivation logic (AC1–AC6)

- [x] **3.1** Create `pulse_coach/lib/features/today/presentation/widgets/factor_icon_row.dart`:
  - `enum DecisionFactor { exerciseType, intensity, temperature, precipitation, aqi }`
  - Pure function `List<DecisionFactor> deriveDecisionFactors(PlannedSession session, WeatherContext? weather)`:
    ```dart
    List<DecisionFactor> deriveDecisionFactors(PlannedSession session, WeatherContext? weather) {
      final factors = <DecisionFactor>[
        DecisionFactor.exerciseType,
        DecisionFactor.intensity,
      ];
      if (weather != null) {
        if (weather.temperature <= 10.0 || weather.temperature >= 28.0) {
          factors.add(DecisionFactor.temperature);
        }
        if (weather.precipitationProbability > 50.0) {
          factors.add(DecisionFactor.precipitation);
        }
        if (weather.isAqiHigh) {
          factors.add(DecisionFactor.aqi);
        }
      }
      return factors;
    }
    ```
    (`session` param is currently unused by the weather branches but keep it in the signature — exercise type/intensity factors are unconditional so the function doesn't strictly need `session` today, but accepting it keeps the signature stable if a future factor becomes session-dependent; if analyzer flags an unused parameter, prefix nothing — `session` IS referenced implicitly as "this row is for this session," but if `flutter analyze` complains about an actually-unused parameter, it's fine to drop it from the signature and pass only `weather` — use your judgement, this is a minor signature detail, not a scope item.)
  - `FactorIconRow` — a `StatelessWidget` taking `session` (`PlannedSession`), `weather` (`WeatherContext?`). Build: call `deriveDecisionFactors`, then render a `Wrap(spacing: 4, runSpacing: 0, children: [for each factor, a _FactorGlyph])` (AC4 — `Wrap`, not `Row`, is what gives you free reflow-to-second-line for narrow width / large text scale, no custom `LayoutBuilder` measuring needed).
  - Private `_FactorGlyph` — a small `StatefulWidget` (needs local `_revealed` boolean for tap-to-show/hide; this is the only state in the whole widget, no `AnimationController` needed):
    ```dart
    class _FactorGlyph extends StatefulWidget {
      final IconData icon;
      final String label;
      final Color color;
      const _FactorGlyph({required this.icon, required this.label, required this.color});
      @override
      State<_FactorGlyph> createState() => _FactorGlyphState();
    }

    class _FactorGlyphState extends State<_FactorGlyph> {
      bool _revealed = false;

      @override
      Widget build(BuildContext context) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 150);
        return Semantics(
          label: widget.label,
          button: true,
          onTap: () => setState(() => _revealed = !_revealed),
          child: ExcludeSemantics(
            child: GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 16, color: widget.color),
                      AnimatedSize(
                        duration: duration,
                        child: _revealed
                            ? Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  widget.label,
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    ```
    Semantics/ExcludeSemantics pairing mirrors the existing `countdown_overlay.dart`/Story 22.1 precedent: the `Semantics` node carries the always-available textual label (screen readers get the factor text regardless of visual reveal state — satisfies AC3's "carries a semantics label" even before/without a tap), the visual reveal itself (decorative motion) is excluded from being independently announced.
  - Icon/color mapping (private helpers in the same file, switch on `DecisionFactor`):
    - `exerciseType` → `LucideIcons.dumbbell300`, color `onSurfaceVariant`, label `sessionDisplayName(session.sessionType, l10n)`.
    - `intensity` → `LucideIcons.gauge300`, color `onSurfaceVariant`, label `intensityLabel(session.intensity, l10n)`.
    - `temperature` → `LucideIcons.thermometer300`, color `onSurfaceVariant`, label `l10n.factorLabelTemperature(weather!.temperature.round())`.
    - `precipitation` → `LucideIcons.cloudRain300`, color `onSurfaceVariant`, label `l10n.factorLabelPrecipitation`.
    - `aqi` → `LucideIcons.wind300`, color `PulseCoachTheme.tertiary` (always tinted — AQI is only ever included when already attention-worthy, see AC5), label `l10n.factorLabelAqi`.
  - If `deriveDecisionFactors` ever returns an empty list (unreachable today since exercise type + intensity are unconditional, but guard defensively), render `const SizedBox.shrink()`.
  - Keep the file within the 200–400 line guideline (expect ~120–160 lines: enum + derivation function + widget + `_FactorGlyph` + icon/color/label switch helpers).

---

### Task 4 — Wire `WeatherContext` into `TodaySessionCubit` (AC2, AC5)

- [x] **4.1** Add `GetWeatherContext` as a constructor dependency to `TodaySessionCubit` (`lib/features/today/presentation/cubit/today_session_cubit.dart`) — it's already `@injectable`, DI wiring regenerates automatically via `build_runner` (do not hand-edit `injection.config.dart`).
- [x] **4.2** Add `WeatherContext? weatherContext` to `TodaySessionState` (nullable, `null` on failure or not-yet-fetched — matches the existing "sensor/weather failures degrade gracefully" pattern already used everywhere else in this codebase, e.g. `generate_daily_plan.dart:253-258`). Add it to `copyWith` following the existing `_sentinel` pattern already used for `persistenceError` (a plain `??` default would prevent ever explicitly resetting it to `null`, but weather is fetch-once-per-load and never explicitly cleared, so a plain `weatherContext ?? this.weatherContext` default is fine here — no sentinel needed for this field specifically, unlike `persistenceError`).
- [x] **4.3** In `planLoaded(int totalSessions, int? planId)`:
  - `planId == null` branch: **no change** — do not fetch weather here (see Context — must stay synchronous).
  - `planId != null` branch: kick off `final weatherFuture = _fetchWeather();` **before** `await`-ing `_sessionLogsDao.getLogsForPlan(planId)` (so they run concurrently, not sequentially), then after the existing logs/staleness-guard logic, `final weather = await weatherFuture;` + one more `if (_currentPlanId != planId) return;` guard, then include `weatherContext: weather` in the emitted `TodaySessionState`.
  - Private helper: `Future<WeatherContext?> _fetchWeather() async { final result = await _getWeatherContext(); return result.fold((_) => null, (w) => w); }`.
  - Do **not** refetch weather in `_onLogsChanged` (live subscription) or `swapHero` — weather is a once-per-plan-load snapshot, shared across whichever session is hero'd.

---

### Task 5 — Wire `FactorIconRow` into `HeroSessionCard` and `TodayPage` (AC1)

- [x] **5.1** Add an optional `WeatherContext? weatherContext` parameter to `HeroSessionCard` (`lib/features/today/presentation/widgets/hero_session_card.dart`), default `null` — **must stay optional/nullable** so the ~15 existing `HeroSessionCard(session: ...)` call sites in `test/widget/session_card_test.dart` keep compiling unchanged.
- [x] **5.2** Inside the existing `if (hasExplanation) [...]` block (lines 133-143), after the explanation `Text`, add:
  ```dart
  const SizedBox(height: 8),
  FactorIconRow(session: session, weather: weatherContext),
  ```
- [x] **5.3** In `today_page.dart`, thread `sessionState.weatherContext` from `TodaySessionState` through `_HeroZone` (add a `weatherContext` field to `_HeroZone`, pass to its `HeroSessionCard(...)` call at line 252) — `_HeroZone` is built at `today_page.dart:155` with `sessionState` already in scope via the enclosing `BlocBuilder<TodaySessionCubit, TodaySessionState>`, so pass `weatherContext: sessionState.weatherContext` at the `_HeroZone(...)` call site (line ~155-171) and store it on the `_HeroZone` widget.
- [x] **5.4 — explicit scope boundary:** `_TabletSessionDetailPanel` (lines 372-472) renders a **hand-built** hero-equivalent layout, not the `HeroSessionCard` widget itself. Epic 22's AC text says "When `HeroSessionCard` renders" — **do not** add `FactorIconRow` to the tablet detail panel; that would be scope creep into a different, unnamed component. Leave tablet layout untouched.

---

### Task 6 — Tests (AC1–AC6)

- [x] **6.1** Create `test/widget/factor_icon_row_test.dart` covering, at minimum:
  ```
  [22.2-FACTOR-001] weather=null → exactly 2 glyphs (exerciseType, intensity), no exception
  [22.2-FACTOR-002] weather with temperature=5.0 (cold), precipitation=20, aqi low → 3 glyphs (exerciseType, intensity, temperature)
  [22.2-FACTOR-003] weather with precipitationProbability=80 → precipitation glyph present
  [22.2-FACTOR-004] weather with isAqiHigh=true (aqiValue>=100) → aqi glyph present, tinted PulseCoachTheme.tertiary
  [22.2-FACTOR-005] weather with temperature=18 (neither cold nor hot), precipitation=10, aqi low → only 2 glyphs (no weather factors shown)
  [22.2-FACTOR-006] tap a glyph → its one-line Semantics label is present in the semantics tree (verify via find.bySemanticsLabel or SemanticsController, not by asserting animated Text visibility timing)
  [22.2-FACTOR-007] reduce motion enabled (MediaQuery(data: MediaQueryData(disableAnimations: true))) + tap → no exception, reveal is instant (single pump, no pumpAndSettle needed across a tween)
  [22.2-FACTOR-008] 5 glyphs shown at 360×640 surface + 2.0 textScaleFactor → no overflow exception, all 5 icons found (Wrap reflows to 2nd line)
  [22.2-FACTOR-009] each glyph's tap target meets 48dp minimum (verify via tester.getSize on the Semantics/GestureDetector ancestor)
  ```
  Follow `test/widget/session_card_test.dart`'s `_wrap()` / `_session()` helper conventions (MaterialApp + AppLocalizations delegates + AppTheme.darkTheme).
- [x] **6.2** Extend `test/widget/session_card_test.dart` with:
  ```
  [22.2-HERO-001] weatherContext passed with isAqiHigh=true → FactorIconRow is present and receives the same WeatherContext (verify via tester.widget<FactorIconRow>(...).weather)
  [22.2-HERO-002] weatherContext: null (existing call sites, no param passed) → HeroSessionCard still renders without exception (regression guard for the ~15 pre-existing call sites)
  ```
- [x] **6.3** Add unit tests for `TodaySessionCubit` in `test/bloc/today_session_cubit_test.dart` (extend the existing `@GenerateMocks([SessionLogsDao])` — add `GetWeatherContext` to the mock list, regenerate mocks via `dart run build_runner build --delete-conflicting-outputs`):
  ```
  [22.2-CUBIT-001] planLoaded(n, planId) with GetWeatherContext returning Right(weatherContext) → emitted state.weatherContext == that context
  [22.2-CUBIT-002] planLoaded(n, planId) with GetWeatherContext returning Left(failure) → emitted state.weatherContext == null (graceful degradation)
  [22.2-CUBIT-003] planLoaded(n, null) → GetWeatherContext is never called (verify via verifyNever) — confirms the null-planId fast path stays untouched
  ```
- [x] **6.4** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  flutter test
  ```
  Expected: 0 analyzer issues; baseline **1331 passed, 1 skipped** (recorded at this story's creation on commit `a58f246`) all still pass, plus all new tests pass.

---

## Review Findings

_Code review 2026-07-06 (3-layer adversarial: Blind Hunter / Edge Case Hunter / Acceptance Auditor, Opus 4.8). All 6 ACs verified satisfied by the Acceptance Auditor. 2 patch findings, 0 decision-needed, 0 deferred, 8 dismissed as per-spec/unreachable._

- [x] [Review][Patch] Weather-fetch exception suppresses the entire Today state emit [pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart:66] — `_fetchWeather` only `.fold`s the `Either`; a *throw* from `GetWeatherContext` (geolocator permission/platform error, or a non-`ServerException`/`FormatException` escaping `WeatherRepositoryImpl.getWeatherContext`) propagates through `await weatherFuture` (line 94) *before* the `emit`, so the core Today update (heroIndex + completedIndices) and the live logs subscription are both skipped, and `planLoaded` being fire-and-forget turns it into an unhandled async error. Weather failure must degrade to "no factors", not kill the emit. Fix: wrap the body of `_fetchWeather` in try/catch returning `null`. Also resolves the orphaned-`weatherFuture`-rejection concern on the staleness early-return path.
- [x] [Review][Patch] `_FactorGlyph` children lack `Key`s — tap-reveal state can mis-associate on factor-set change [pulse_coach/lib/features/today/presentation/widgets/factor_icon_row.dart:66] — positional list of same-typed stateful widgets with no keys; if the derived factor set ever changes a middle element's identity, Flutter matches `_FactorGlyphState._revealed` by index and carries a reveal onto the wrong factor. Not triggerable in the current once-per-load append-only flow, but flagged independently by both adversarial layers; one-line defensive hardening. Fix: `key: ValueKey(factor)` on each `_FactorGlyph`.

## Dev Notes

### Why fetch weather independently instead of persisting it on `PlannedSession`

`WeatherContext` already reaches `GenerateDailyPlan` today (folded into `StateVector`) but is never persisted onto `PlannedSession`/`DailyPlan` — those are `@freezed` classes serialized to `daily_plans_table.planJson`; adding fields would mean a JSON schema version bump, a migration path for previously-persisted plans without the new field, and touching the AI isolate boundary. None of that is warranted for a "presentation-only, no new inference" story. `GetWeatherContext` already reads a cache with a 1h TTL — refetching it independently from the Today UI, on the same day the plan was generated, returns materially the same data with zero schema risk. If this ever needs true point-in-time-of-generation weather (e.g., re-checking a plan generated yesterday), that's a different, larger story.

### Why the reveal is a local `_revealed` bool + `AnimatedSize`, not `Tooltip`

Flutter's built-in `Tooltip(triggerMode: TooltipTriggerMode.tap)` would be the "idiomatic" choice for a tap-to-reveal label, but every other animated component in this codebase (`CompletionRing`, `countdown_overlay.dart`, `MilestoneProgressBar`) explicitly branches on `MediaQuery.disableAnimationsOf(context)` rather than trusting a widget to auto-degrade — and `Tooltip`'s internal fade timing is not something this story's author could verify honors that flag in this Flutter SDK version. A local bool + `AnimatedSize` with an explicit `duration: reduceMotion ? Duration.zero : ...` keeps the reduce-motion contract exactly as verifiable and consistent as the rest of the codebase, at the cost of a few more lines than `Tooltip`.

### Temperature/precipitation thresholds are new presentation-only constants

`10.0`/`28.0`°C for "notable" temperature do not exist anywhere else in the codebase — they're introduced here purely to decide whether to show a glyph, and carry no behavioral weight. `50.0`% for precipitation reuses the exact number already written (but unused) in `generate_daily_plan.dart:265`. If Paolo wants different thresholds, they're isolated to `deriveDecisionFactors` — one function, easy to tune.

### File Size Check

- New `factor_icon_row.dart`: expect ~120–160 lines.
- `hero_session_card.dart`: 161 → +~6 lines (one new param, two new lines in the explanation block).
- `today_session_cubit.dart`: 221 → +~20 lines (new dependency, new state field, `_fetchWeather` helper, concurrent-fetch wiring in `planLoaded`).
- `today_page.dart`: 556 → +~3 lines (thread one new field through `_HeroZone`).

### Project Structure Notes

**New production files:**
- `pulse_coach/lib/features/today/presentation/widgets/factor_icon_row.dart`

**Modified production files:**
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart` (new optional `weatherContext` param + `FactorIconRow` insertion)
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart` (new `GetWeatherContext` dependency, `weatherContext` state field, concurrent fetch in `planLoaded`)
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart` (thread `weatherContext` through `_HeroZone`)
- `pulse_coach/lib/l10n/app/app_it.arb`, `app_en.arb` (3 new factor-label keys)
- `pulse_coach/pubspec.yaml` (new `lucide_icons_flutter` dependency)

**Auto-regenerated:**
- `injection.config.dart` (via `build_runner`, from the new `GetWeatherContext` constructor param on `@injectable TodaySessionCubit`)
- `.dart_tool/flutter_gen/...` generated `app_localizations*.dart` (via `flutter gen-l10n`/`pub get`, gitignored)
- `test/bloc/today_session_cubit_test.mocks.dart` (via `build_runner`, once `GetWeatherContext` is added to `@GenerateMocks`)

**New/modified test files:**
- `pulse_coach/test/widget/factor_icon_row_test.dart` (new)
- `pulse_coach/test/widget/session_card_test.dart` (extended)
- `pulse_coach/test/bloc/today_session_cubit_test.dart` (extended)

**Explicitly out of scope for this story:**
- `_TabletSessionDetailPanel`'s hand-built hero layout (not the `HeroSessionCard` widget — see Task 5.4).
- Any change to `PlannedSession`/`DailyPlan` schema, Drift persistence, or the AI isolate boundary to capture historical weather-at-generation-time.
- Wiring temperature/precipitation into an actual AI/safety decision (they remain dead `StateVector` fields after this story — this story only makes them visible, presentation-only).
- Humidity (not captured by `WeatherContext`, excluded 2026-07-06 per addendum.md).

### References

- [Source: epics.md#Story 22.2, lines 2931-2962 — full BDD ACs, FR82, DESIGN.md/EXPERIENCE.md cross-refs]
- [Source: epics.md#Epic 22, lines 2885-2893 — epic goal, "Presentation-only (Story 22.2)" prerequisite note]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 215 — full FactorIconRow visual spec: 16dp/1.5px Lucide glyphs, 48dp tap targets, wrap behavior, AQI tertiary tint, humidity exclusion]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md line 205 — HeroSessionCard layout, FactorIconRow position (directly beneath ExplanationLine)]
- [Source: ux-designs/ux-Flutter_PulseCoach-2026-06-20/EXPERIENCE.md lines 69, 156, 158-160 — FactorIconRow behavior summary, color-independence, touch-target rules, reduce-motion]
- [Source: addendum.md lines 29-30 — FR82 decision-factor iconography scope, humidity exclusion rationale]
- [Source: prd.md line 646 — FR82 canonical text]
- [Source: lib/features/daily_plan/domain/usecases/generate_daily_plan.dart:253-266 — confirms temperature/precipitation computed but not consumed by any rule; precipitation's existing (unused) `> 50.0` threshold]
- [Source: lib/ai/safety/safety_rules.dart — confirms only `aqiLevel` (via `isAqiHigh`) has a real causal path to `outdoorAllowed`]
- [Source: lib/features/weather/domain/entities/weather_context.dart — `WeatherContext` fields, `isAqiHigh` getter]
- [Source: lib/features/weather/domain/usecases/get_weather_context.dart — existing injectable use case to reuse]
- [Source: lib/features/today/presentation/widgets/hero_session_card.dart:100-114 — 48dp `IconButton` sizing precedent to mirror; lines 133-143 — `ExplanationLine`/`hasExplanation` insertion point]
- [Source: lib/features/today/presentation/widgets/session_card_helpers.dart — `sessionDisplayName`/`intensityLabel` reuse for exercise-type/intensity factor text]
- [Source: lib/features/today/presentation/cubit/today_session_cubit.dart:58-97 — `planLoaded`'s synchronous null-planId fast path invariant (must not be broken), existing staleness-guard pattern to mirror for the weather fetch]
- [Source: lib/features/today/presentation/pages/today_page.dart:155-171,233-266 — `_HeroZone` construction site to thread `weatherContext` through; lines 372-472 — `_TabletSessionDetailPanel`, explicitly out of scope]
- [Source: lib/l10n/app/app_it.arb:24-33,74-76 — ARB metadata block shape and `intensity*` key placement precedent]
- [Source: test/widget/session_card_test.dart — `_wrap()`/`_session()` helper conventions, ~15 existing `HeroSessionCard(session: ...)` call sites requiring the new param to stay optional]
- [Source: test/bloc/today_session_cubit_test.dart — `@GenerateMocks([SessionLogsDao])` pattern to extend]
- [Source: pubspec.yaml:8 — `sdk: ^3.11.3`, the constraint that rules out `lucide_icons` in favor of `lucide_icons_flutter`]
- [Verified via pub.dev API + package archive inspection 2026-07-06: `lucide_icons` env `>=2.12.0 <3.0.0` (incompatible); `lucide_icons_flutter` 3.1.14+2 env `^3.0.0` (compatible); confirmed `LucideIcons.dumbbell300`/`gauge300`/`thermometer300`/`cloudRain300`/`wind300` exist at stroke-width 1.500]
- [Source: Story 22.1 (`22-1-in-session-milestone-progress-bar-and-finish-marker.md`) — reduce-motion + Semantics/ExcludeSemantics pairing precedent this story mirrors; confirms baseline test count 1331 passed/1 skipped on commit `a58f246`]

## Dev Agent Record

### Agent Model Used

Claude Sonnet 5 (claude-sonnet-5)

### Debug Log References

- `flutter analyze lib/ test/` → 0 issues.
- `flutter test` → 1346 passed, 1 skipped (baseline 1331 passed/1 skipped + 15 new tests: 10 in `factor_icon_row_test.dart`, 2 in `session_card_test.dart`, 3 in `today_session_cubit_test.dart`).
- Fixed a real bug surfaced by [22.2-FACTOR-007]: using `AnimatedSize(duration: Duration.zero, ...)` inside a tap handler under `MediaQuery(disableAnimations: true)` throws `RenderAnimatedSize was mutated in its own performLayout implementation` on a single `pump()`. Fixed by skipping `AnimatedSize` entirely (not just zeroing its duration) when `MediaQuery.disableAnimationsOf(context)` is true — the reveal child renders directly instead.
- Extending `TodaySessionCubit`'s constructor with `GetWeatherContext` required updating 5 additional test files beyond the story's listed File List (`app_router_test.dart`, `offline_core_features_test.dart`, `app_shell_test.dart`, `pages_smoke_test.dart`, `today_page_test.dart`) — each had a direct `TodaySessionCubit(dao)` or `_TestingTodaySessionCubit` construction site that needed a `GetWeatherContext`/`WeatherRepository` fake or mock added. Regenerated mocks/DI via `dart run build_runner build --delete-conflicting-outputs`.

### Completion Notes List

- Task 1: Added `lucide_icons_flutter: ^3.1.14` to `pubspec.yaml`; ran `flutter pub get`. Did not add `lucide_icons` (incompatible SDK constraint per Dev Notes).
- Task 2: Added `factorLabelTemperature` (parameterized, `int` placeholder), `factorLabelPrecipitation`, `factorLabelAqi` to both `app_it.arb`/`app_en.arb` near the `intensity*` keys. Ran `flutter gen-l10n`; confirmed new getters generated in `app_localizations*.dart`.
- Task 3: Created `factor_icon_row.dart` with `DecisionFactor` enum, pure `deriveDecisionFactors()`, `FactorIconRow` (`Wrap`-based), and `_FactorGlyph` (StatefulWidget, local `_revealed` bool, `Semantics`/`ExcludeSemantics` pairing, reduce-motion branch that skips `AnimatedSize` entirely rather than zeroing its duration — see Debug Log). File is 168 lines (within the 200–400 guideline, closer to the story's ~120–160 estimate).
- Task 4: Added `GetWeatherContext` to `TodaySessionCubit`'s constructor (DI regenerated via `build_runner`); added `weatherContext` field to `TodaySessionState` (plain `??` default in `copyWith`, no sentinel needed per Dev Notes); wired concurrent fetch in `planLoaded`'s `planId != null` branch (kicks off `_fetchWeather()` before awaiting DAO logs, re-checks staleness guard before emitting). Null-`planId` fast path is untouched and confirmed synchronous/no-fetch via [22.2-CUBIT-003].
- Task 5: Added optional `weatherContext` param to `HeroSessionCard`, inserted `FactorIconRow` inside the existing `hasExplanation` block. Threaded `sessionState.weatherContext` through `_HeroZone` in `today_page.dart`. Left `_TabletSessionDetailPanel` untouched per explicit scope boundary (Task 5.4).
- Task 6: Wrote all specified test IDs across 3 files (`factor_icon_row_test.dart` new, `session_card_test.dart` + `today_session_cubit_test.dart` extended), followed TDD (RED confirmed via compile errors before each implementation, then GREEN). Full suite green at 1346/1 skipped, `flutter analyze` clean.

### File List

**New:**
- `pulse_coach/lib/features/today/presentation/widgets/factor_icon_row.dart`
- `pulse_coach/test/widget/factor_icon_row_test.dart`

**Modified (production):**
- `pulse_coach/pubspec.yaml`
- `pulse_coach/lib/l10n/app/app_it.arb`
- `pulse_coach/lib/l10n/app/app_en.arb`
- `pulse_coach/lib/features/today/presentation/widgets/hero_session_card.dart`
- `pulse_coach/lib/features/today/presentation/cubit/today_session_cubit.dart`
- `pulse_coach/lib/features/today/presentation/pages/today_page.dart`

**Modified (tests):**
- `pulse_coach/test/widget/session_card_test.dart`
- `pulse_coach/test/bloc/today_session_cubit_test.dart`
- `pulse_coach/test/core/routing/app_router_test.dart` (unlisted in original Dev Notes — required to fix `TodaySessionCubit` constructor arity)
- `pulse_coach/test/offline/offline_core_features_test.dart` (unlisted — same reason)
- `pulse_coach/test/widget/app_shell_test.dart` (unlisted — same reason)
- `pulse_coach/test/widget/pages_smoke_test.dart` (unlisted — same reason)
- `pulse_coach/test/widget/today_page_test.dart` (unlisted — same reason)

**Auto-regenerated:**
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/l10n/app_localizations.dart`, `app_localizations_it.dart`, `app_localizations_en.dart`
- `pulse_coach/test/bloc/today_session_cubit_test.mocks.dart`
- `pulse_coach/test/widget/today_page_test.mocks.dart`

## Change Log

- 2026-07-06: Story 22.2 implemented — `FactorIconRow` component, ARB factor-label keys, `TodaySessionCubit` weather wiring, `HeroSessionCard`/`TodayPage` integration. All 6 tasks complete, all 6 ACs satisfied. 15 new tests added; full suite 1346 passed/1 skipped; `flutter analyze` 0 issues. Fixed 5 additional test call sites (outside the story's original File List) whose direct `TodaySessionCubit` construction needed updating for the new `GetWeatherContext` constructor param.
