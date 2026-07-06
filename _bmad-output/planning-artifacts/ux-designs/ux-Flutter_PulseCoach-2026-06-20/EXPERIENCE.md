---
name: PulseCoach
status: final
updated: 2026-07-06
references: DESIGN.md
sources:
  - {planning_artifacts}/ux-design-specification.md
  - {planning_artifacts}/prd.md
  - {planning_artifacts}/addendum.md
---

# PulseCoach — Experience Spine

> Owns *how it works*. `DESIGN.md` is the visual identity reference; this spine cross-references its tokens with `{token}` syntax. Both spines win on conflict with any mock or import. Scope = distilled **v1** (shipped, free/offline/account-free) + designed **v2** (optional accounts, Pro, calm social). v2 sections marked `[ASSUMPTION]` need Paolo's confirmation. The one-line test governs every decision: **"Open the app and it already tells you what to do — and it always guesses how you feel."**

## Foundation

Multi-surface. **Phone (primary)** — daily driver, single-column, bottom navigation, thumb-zone optimized. **Tablet (secondary)** — coaching dashboard, `NavigationRail` + master-detail. **WearOS (tertiary)** — passive in-session companion, separate Dart target sharing data models only. **Cloud (v2)** — optional backend for accounts/backup/social; the v1 core stays fully offline-first regardless of account or subscription state.

UI system: **Material 3** (`useMaterial3: true`) as structural foundation; custom components carry identity (see `DESIGN.md.Components`). Single responsive breakpoint at **600dp** (`LayoutBuilder` at scaffold level). Dark is the default surface; light is a setting. Locale is currently locked to Italian (`it`).

**Brand-promise floor (non-negotiable, drives every v2 behavior):** the adaptive AI (bandit + state machine + RPE loop) runs **on-device**. Cloud sync is opt-in, own-account-scoped, used only for backup/restore and explicitly-shared social data — never cross-user training. Biometric data is never *required* to leave the device, and when backed up it is end-to-end encrypted with a user-held key.

## Information Architecture

| Surface | Reached from | Tier | Purpose |
|---|---|---|---|
| **Today** | App open (cold), tab (index 1) | Free | Hero session (+ FactorIconRow) + ActiveDaysCard + COMING UP + CompletionRing. The home. Default landing on every open. |
| **Sessions** | Tab | Free | Static catalog by category (Mobility, Cardio, Strength, Breathing). The manual override valve. |
| **Progress** | Tab | Free + Pro | Free: most-recent session + current weekly goal. Pro: full history + all charts. |
| **Social** *(v2)* | Tab (4th) | Free view / Pro create | Friends & requests, activity feed, leaderboard, friend progress comparison (FR67, friends-only, same no-pressure rules — no biometric detail), shared-session CTA. |
| In-Session | Start (overlay) | Free | Full-screen guided session. Not a route — overlay over Today. |
| Onboarding | First launch | Free | 3 carousel screens + 4-field profile + medical disclaimer. |
| Profile / Settings / Privacy / Debug | Drawer | Free | Secondary screens. **v2 FR53:** each provides explicit back to the shell. |
| Account / Backup *(v2)* | Drawer → Settings | Free+account | Sign in/out, password reset, opt-in E2E backup/restore, in-app account deletion (FR77). |
| Pro / Subscription *(v2)* | Locked-feature tap, or Settings | Free→Pro | Plans, purchase, restore, manage/cancel (via store). |

**Nav bar (phone):** `NavigationBar` — **Sessions · Today · Social · Progress**. Today is the **default landing on every open** (home) and remains the experiential center of gravity even though, with the v2 4-tab bar, it sits at index 1 rather than the visual center it held in the v1 3-tab bar. Social is the 4th destination added in v2. Tablet: `NavigationRail` with the same four destinations. Nav bar is hidden during InSessionView, CountdownOverlay, RPE, MiniSummary, and Onboarding.

→ Composition reference: [`mockups/key-screens.html`](mockups/key-screens.html) (Today · In-Session · Social/Leaderboard+Feed · Pro upsell · Shared-lobby) and [`mockups/key-screens-extended.html`](mockups/key-screens-extended.html) (Onboarding · Profile · Progress free/Pro · SignInSheet · Account & Backup · Tablet Today master-detail · WearOS session + shared-mirror). Spine wins on conflict.

## Voice and Tone

Microcopy. Brand voice and aesthetic posture live in `DESIGN.md.Brand & Style`. Copy is Italian (locale-locked). **Warmth over metrics, competence over congratulation, no exclamation marks, no shame.**

| Do | Don't |
|---|---|
| "Sonno breve + HR a riposo elevata. Partiamo piano." | "State: Recovering, intensity cap: Low" |
| "Il tuo corpo ha riposato — ecco cosa gli serve ora." | "Bentornato! Hai saltato 3 giorni." |
| "Fatto. Domani regolo l'intensità." | "GRANDE! Sessione completata! 🎉" |
| "Sto usando i dati salvati." (rare, inline, recessive) | "Errore di rete" / "Qualcosa è andato storto" |
| "Lo storico completo è una funzione Pro." + "non ora" | A persistent "Upgrade!" banner |
| "Adattata per tutti — intensità più bassa, niente carico sul ginocchio." | "Plan downgraded for group" |
| "4 giorni attivi negli ultimi 30." (windowed state, no chain to protect) | "🔥 4 giorni di fila! Non fermarti ora!" |
| Short, complete sentences. State observed, then act. | Streak-guilt, don't-break-the-chain urgency, motivational quotes. |

State-driven tone (Today explanation + StateIndicator): Active = neutral/business-as-usual; Fatigued = observational/factual; AtRisk = caring/protective; Recovering = encouraging/competent.

## Component Patterns

Behavioral. Visual specs live in `DESIGN.md.Components`.

| Component | Use | Behavioral rules |
|---|---|---|
| **HeroSessionCard** | Today | One at a time. Tap Start → CountdownOverlay. On completion, the next session **auto-promotes** to hero. Holds the always-visible {ExplanationLine}. |
| **CompactSessionCard** | Today COMING UP | Tap → in-place {HeroSessionCard} swap (no navigation); previous hero animates down into the list. |
| **StateIndicator** | Today / hero | Reflects behavioral state; always pairs state color with a text label. Read-only. |
| **ExplanationLine** | Hero / cards | The one-line AI reason. Always visible, never behind a tap. |
| **FactorIconRow** | Hero (under {ExplanationLine}) | Shows the decision factors that shaped the recommendation (exercise type, intensity, temperature, precipitation, AQI; humidity excluded). Only factors that actually applied are shown. Each glyph taps to reveal its one-line textual factor; the tap target is a **≥48dp transparent hit-area** around the ~16dp glyph, and the row **wraps** (never truncates) when targets + 2.0× text don't fit. Read-only, never an action. Presentation-only over the existing explainability (FR13/FR14) — introduces no new inference. |
| **ActiveDaysCard** | Today (below hero) | Shows the **windowed** active-days count ("N giorni attivi negli ultimi 30") as calm continuity state — **not a consecutive streak**: a rest day ages out of the rolling window instead of resetting the count to zero, so there is no chain and no guilt event. Reads its current value silently — no reset banner, no "streak lost" copy, no nudge. Single source of truth: the FR23 activity signal already tracked by the behavioral state machine (no parallel counter). Read-only. |
| **MilestoneProgressBar** | InSessionView | Marks each session-step boundary (as a notch in the fill + rail tick) and the end with a distinct, **neutral** finish marker (soft dot/check, not a flag), giving visible checkpoints and a clear end goal. Single-step sessions show only start + finish. On completion the finish marker **settles quietly** (~300–400ms, **no glow**); Reduce-Motion → static. The single emotional close is the {CompletionRing} pulse in {MiniSummary} — the two beats never stack. No confetti, no sound. |
| **JoinCodeCard** *(v2)* | Shared session create | Shows join code + QR for in-person join. No expiry countdown pressure; refreshable. |
| **CompletedSessionCard** | Today | Read-only, stays visible (progress made visible). Excluded from focus order. |
| **RPEInput** | Post-session | One tap = submission. No confirm, no submit. Offered even after abandonment (abandonment is data, not failure). |
| **CompletionRing** | Today + MiniSummary | Informational on Today (n/3); emotional pulse only in MiniSummary at 3/3. |
| **CountdownOverlay** | Session start | 3-2-1, non-interruptible, non-skippable (psychological readiness). |
| **InSessionView** | Session | Linear, zero branching. Auto-advance on timer; haptic on step transition (`HapticFeedback.mediumImpact()`, <200ms, never via Bloc). Progress shown via the {MilestoneProgressBar} (step ticks + finish marker). Only control: recessive "End session". |
| **MiniSummary** | Post-session | Auto-dismiss after 3s → auto-return to Today. No "back", no "what's next" prompt. |
| **SignInSheet** *(v2)* | Account entry | Optional always. Apple / Google / email. Dismissible; never blocks the free core. |
| **ProUpsellSheet** *(v2)* | Locked-feature tap | Appears **only** on tapping a Pro feature. One line + `Scopri Pro` + `non ora`, then resolves. No proactive triggers. |
| **FriendRow** *(v2)* | Social | Add by username / QR / contacts. Send/accept/decline/remove. |
| **ActivityFeedCard** *(v2)* | Social feed | Shows only explicitly-shared completions, no biometric detail. Each share revocable. Supports **light reactions** (single encouragement tap, no free-text comments, no pressure-inducing counts). |
| **LeaderboardRow** *(v2)* | Social | Friends-only ranking + points. Rank number is the primary cue; top-3 add a shape-distinct, labeled medal glyph ({medal-gold}/{medal-silver}/{medal-bronze}). No overtaken alerts, no points-delta toast. Rank **frozen** while the viewer is in AtRisk/Recovering (see Protective-State Social Suppression). |
| **SharedSessionLobby** *(v2)* | Shared session | Shows participants + group-adapted plan + one-line adaptation reason. Shared Start advances all devices. |
| **VisibilityTierSelector** *(v2)* | Profile/share | Defaults to Privato. Friends-only / per-item are explicit opt-ins. |

## State Patterns

| State | Surface | Treatment |
|---|---|---|
| Cold open | Today | Plan already generated (on-device, <1s). Shimmer matching layout if not ready — never a spinner, never "generating…". |
| Loading (any async) | Any | Shimmer placeholder matching content. Bloc emits `loading` first. |
| Empty (day 1 Progress) | Progress | One line: "Completa la prima sessione per vedere i progressi." No illustration, no CTA. |
| Sensor/API unavailable | Any | Silent degradation. At most a recessive inline "Sto usando i dati salvati." Never modal, never red, never a retry button. |
| Return after absence | Today | Empathetic state message (Fatigued/AtRisk/Recovering). No welcome banner, no missed-day counter, no streak-reset drama. The {ActiveDaysCard} simply reflects fewer active days in its rolling window — a gentle lower number, never a snap-to-zero reset or "streak lost" copy. AtRisk reduces to 2 sessions. |
| Error (genuine) | Repository → state | `Left(Failure)` → Bloc `error` state → quiet UI. No exception reaches the UI. |
| Offline (v2 cloud) | Social / Account | v1 core fully usable. Social/cloud degrade gracefully; sync on next foreground. Surface sync issues only in Settings → Account, never blocking. |
| Signed-out (v2) | Social / Backup | Calm prompt to sign in at the point of need; never forced. Free core unaffected. |
| Locked (Pro feature, v2) | Progress history / Social create | Tap → {ProUpsellSheet}. **No persistent lock glyph or badge anywhere** (a quiet badge-of-absence still nags — "silence is a feature"). After `non ora`, a **cooldown** suppresses the sheet for the rest of the session/day so it never nags. |
| Pre-v2 grandfathered user | Progress | Full history stays free; the Pro history gate applies only to post-v2 installs (system distinguishes the two). |
| Co-location inconclusive (v2) | Shared session join | **Non-blocking** — friend can still join (NFR33). No error. |
| Participant drops (v2) | Shared session | Others' session continues uninterrupted (NFR31). |

## Interaction Primitives

- **Tap to act.** One required input per session: the RPE tap. Everything else is automated (selection, sequencing, transitions, summary, return).
- **In-place transformation** over navigation: hero swap, regenerate, completion all happen on Today with the context (state bar, ring, nav) visible. Core-loop navigation count: **0**.
- **Self-resolving flows:** session → RPE → summary → Today resolves itself; onboarding auto-advances; regenerate settles with a one-line reason.
- **Swipe** reserved for secondary actions only (dismiss summary, onboarding advance). No long-press for critical functions.
- **Haptics** on step transitions only; direct, <200ms.
- **QR scan / join code** (v2) for friends and shared-session join — in-person, calm, no countdown.
- **Banned:** streak *mechanics* (flame glyphs, don't-break-the-chain, reset-shame — the calm active-days count in {ActiveDaysCard} is explicitly *not* this), badges, notification re-engagement (v1 has zero push), success toasts, error modals during normal use, "Are you sure?" for non-destructive actions, confetti / celebration theater (the one restrained finish-marker micro-animation in {MilestoneProgressBar} is the sole sanctioned exception), global leaderboards, "you've been overtaken" alerts, persistent paywall banners.

## Account, Privacy & Consent Patterns *(v2)* `[ASSUMPTION]`

- **Account is optional and additive.** The free, offline, account-free experience is preserved (FR56). Sign-in is offered at the point of need (backup, social, Pro), never as a wall.
- **Privacy by default.** A new social profile and its activity are private (visible to no one) until the user opts into a visibility tier (NFR29). No data is public by default.
- **Granular, unbundled consent** (NFR35): authentication, backup, social sharing, co-location check, and leaderboard each have a distinct toggle; any single consent is withdrawable without deleting the account.
- **Backup is E2E-encrypted** with a user-held key (FR57/NFR28) — biometric-derived personalization is never readable server-side. Present this plainly, not as fine print.
- **In-app account deletion** (FR77): initiated, confirmed, cascades (NFR30). Visible removal immediate; full purge ≤30 days. Reachable in-app, not only via web. Uses the destructive-action pattern (Dialog confirm; Cancel is the dominant button).
- **Data export** (NFR30): user can export server data as portable JSON from Settings.
- **Co-location** (NFR33): location used only momentarily at session start to confirm proximity; not stored, not tracked, never exposed to others — only a boolean result. Non-blocking.
- **Minimum age** (NFR37) **16** (GDPR Art. 8 default, configurable per market): accounts/social gated; confirmed at registration.

## Pro Gating Patterns *(v2)* `[ASSUMPTION]`

- **Free tier keeps the whole v1 core**: AI daily plan, sessions, in-session experience, explainability, last-session progress, weekly goal (FR59).
- **Pro unlocks**: full Progress history + all charts (FR61), and *creating* social content — friends, sharing, shared sessions, scoring participation (FR62). **Free**: setting a username and *viewing* the leaderboard ranking.
- **The seam is contextual and silent.** No upsell appears until the user reaches for a Pro capability; then {ProUpsellSheet} states the one fact and offers `Scopri Pro` / `non ora`. This is the only place the paywall speaks. **No persistent lock/badge** on Free screens; **a `non ora` cooldown** prevents re-prompting within the same session/day.
- **Counter-metric guardrail:** gating must never pressure. No "you're missing out" framing, no scarcity timers, no badge nags. Conversion comes from value reached, not anxiety induced.

## Shared Session & Real-Time Patterns *(v2)* `[ASSUMPTION]`

- **Group-adapted plan via deterministic rules** (FR70, analogous to the v1 FR9 safety layer, fully testable): intensity ceiling = **min** of participants' caps; fitness level = **lowest** present; movement exclusion = **union** of constraints; duration = **shortest** preference. Each participant's individual v1 safety rules still apply on top; if any would block the group plan, the group plan reduces accordingly. Always shown with a one-line plain-language reason.
- **Real-time sync** (FR71/NFR31): all participants see the same step + timer within ~1s; a drop-out doesn't interrupt others. **WearOS mirrors the owning participant's synchronized view** (reuses the existing 1:1 phone↔watch bridge — no new N-device transport on the watch). **Group-driven step advances must fire a `Semantics(liveRegion: true)` announcement** so screen-reader users aren't silently left behind when the group moves on (the solo countdown/step live regions don't cover group-pushed transitions).
- **Per-participant RPE** (FR72): each rates their own effort; each rating feeds only that person's on-device learning.
- **Gating** (FR73): active Pro + account + the others in your friends list + location enabled + minimum age.

## Protective-State Social Suppression *(v2)* — counter-metric guardrail

This is the load-bearing reconciliation between the v2 social/competition layer and the v1 recovery-empathy promise. Without it, a user the on-device AI has placed in **AtRisk/Recovering** would be *punished by the social layer for resting* — the missed-streak shame anti-pattern reborn as a leaderboard drop. The following are non-negotiable:

- **Rank freeze during AtRisk/Recovering.** While the user is in a protective state, their leaderboard rank/points are **frozen** — rest never reads as a lost position. Recovery is never rendered as a ranking penalty.
- **No shared-session nudges in protective states.** The app does not prompt or surface "start a shared session" invitations to a user in AtRisk/Recovering; incoming join codes still work if *they* choose, but the app never pulls them toward training.
- **No social pressure on Today.** Today never shows leaderboard standing, "a friend passed you", or points goals. The Social tab holds all of that; Today stays the calm, state-led core.
- **Points cannot become a volume lever.** A **per-day points cap** ensures extra sessions can't climb the board (protects the "don't push RPE above ≈6.5 / don't increase AtRisk-state starts" counter-metrics). No points-delta toast or animation anywhere.
- **Reactions never feed score, never push.** Light feed reactions are receive-only acknowledgements: zero push notifications, no aggregate counts shown as pressure, no reactor-ranking, and reactions never contribute to points.

These rules are testable (state is already a first-class on-device signal) and should carry into the social epics as acceptance criteria.

## Accessibility Floor

Behavioral. Visual contrast lives in `DESIGN.md`. Target **WCAG 2.1 AA**.

- **Contrast — On Primary (BLOCKER fixed):** the Start button (and any text/icon on aqua `{primary}`) uses `{on-primary}` dark teal (~12:1). White/light-grey on aqua is banned. Behavioral states Fatigued vs Recovering differ only by violet opacity — so the **text label is mandatory** as the disambiguator (never hue alone).
- **Color independence:** session type, behavioral state, completion (n/3 text), RPE values, **podium medals**, and the **FactorIconRow** never rely on color alone. Medals carry three redundant cues — **prominent rank number (primary)** + shape-distinct glyph + text label ("1° oro / 2° argento / 3° bronzo") — because silver collides with the disabled grey and amber↔coral collapse under red-green CVD. Factor icons are shape-distinct Lucide glyphs, each tappable to a text factor and each labeled in the semantics tree; the AQI amber tint is a redundant emphasis, never the sole carrier of the "attention" meaning. On the {MilestoneProgressBar}, step boundaries are notches in the fill (not same-hue ticks that fail contrast on the Primary fill), and reached-vs-unreached on the finish marker is carried by **shape** (outline→filled) with an `{on-primary}` fill ≥3:1, never by hue alone.
- **Calm ≠ inaudible (silent degradation must stay AT-reachable):** the "silent" degradation, AtRisk session reduction, and group-adaptation reason are *visually* recessive but must be present as **readable text** in the semantics tree (e.g. "Sto usando i dati salvati", "Solo 2 sessioni oggi — riavvio dolce", the group-plan reason). Quiet to the eye, never absent to a screen reader.
- **Touch targets ≥ 48dp** — incl. the FactorIconRow glyphs (~16dp visual / ≥48dp transparent hit-area, non-overlapping) and v2 surfaces: LeaderboardRow, FriendRow, feed reaction tap, and the JoinCodeCard QR/code action. RPE 40dp visual / 48dp target, two-row degrade <~516dp width (48dp must hold in the degraded layout). Dense rows (LeaderboardRow/FriendRow) **and the FactorIconRow** wrap rather than truncate at 2.0× text scale (the row spills to a second line before it clips or pushes the Start button off the hero).
- **Screen reader (in-scope for the v2 store launch):** full VoiceOver/TalkBack coverage is a v2 requirement, not deferred. Every custom component wrapped in `Semantics` with explicit labels (see the component semantics map in the source spec); each interactive element labeled with role + state. New v1-polish elements carry labels: each FactorIconRow glyph exposes its textual factor (icon is not the only carrier), the ActiveDaysCard reads its count as text ("N giorni attivi negli ultimi 30"), and the MilestoneProgressBar exposes step position + finish reached; the finish-marker settle animation uses `ExcludeSemantics`. Live regions for CountdownOverlay, in-session step transitions, **and group-pushed step advances in shared sessions** (BLOCKER fixed). Decorative elements (Lottie, shimmer, ring arc) use `ExcludeSemantics`. v2 social/Pro surfaces (SignInSheet, ProUpsellSheet, LeaderboardRow incl. medal rank, SharedSessionLobby) carry labels from the start.
- **Reduce Motion:** all durations → 0; countdown becomes static number swap (timing preserved); hero swap and ring update instant; shimmer → static; Lottie → first frame; the {MilestoneProgressBar} finish-marker settle → static filled state. (NFR38: milestone notches, finish-marker settle, and factor icons all honor the 60fps / ≤16ms budget and degrade to static equivalents under reduce-motion.)
- **Text scale** honored to 2.0× without overflow; Timer numerals capped at 2.0×.
- **Focus traversal** follows reading order on every surface.

## Responsive & Platform

- **Phone (320–430dp):** single column, bottom `NavigationBar` (4 tabs). Hero full-width; in-session full-screen overlay. Small-phone (<360dp): tighter hero padding; RPE two-row.
- **Tablet (≥600dp):** `NavigationRail`; Today master-detail (~60/40); Sessions 2-col grid; Progress dashboard grid; Social `[ASSUMPTION]` two-pane (friends/leaderboard list + selected detail). Foldable: unfolded→tablet, folded→phone via the same breakpoint.
- **WearOS (~192dp circular):** separate target. Session Active, Rest, Summary, Idle screens. Passive during session (phone drives flow). No RPE on watch. v2 shared sessions: watch **mirrors the owning participant's view** (1:1 bridge reuse, not a full N-device node).
- **Shared components, different arrangement** — never duplicate widget logic per form factor; `LayoutBuilder` switches at the scaffold.

## Inspiration & Anti-patterns

- **Lifted from Spotify (autoplay):** Today is a ready-to-play queue — trust and start, not browse and choose.
- **Lifted from Oura (one number, one sentence, one action):** behavioral state as a single label + one-line synthesis, not raw metrics.
- **Lifted from Duolingo (linear flow):** in-session has no menus, no branching — step → timer → haptic → next.
- **Lifted from Things 3 (clean resolution):** post-session self-resolves; completion is minimal and final.
- **Lifted from Headspace (calm ritual):** countdown and transitions are thresholds, not interruptions.
- **Rejected — streak *mechanics* / missed-day counters:** flame glyphs, don't-break-the-chain, reset-shame weaponize guilt and break the recovery-empathy promise. Absence is physiological data, not failure. (The calm {ActiveDaysCard} count is continuity made visible — no chain to protect — and is *not* this anti-pattern.)
- **Rejected — celebration theater (confetti/badges/"AMAZING JOB!"):** disproportionate praise patronizes; competence > congratulation. (The single restrained finish-marker micro-animation in {MilestoneProgressBar} is a quiet checkpoint close, not theater.)
- **Rejected — aggressive gym aesthetic & multi-metric dashboards (phone):** conflict with calm energy and warmth-over-metrics.
- **Rejected — push re-engagement nudges:** silence is respect (v1 has none).
- **v2 guardrail — Strava-style competitive pressure:** adopt the *together* of social (shared sessions, friends), reject the *more* of competition. Leaderboard is friends-only, podium medals are restrained, no global boards, no overtaken alerts. Protect the counter-metrics: gamification must not raise AtRisk-state session starts or push RPE above ≈6.5.

## Key Flows

### Flow 1 — First plan (Luca, just installed) *(v1)*
1. Launch → onboarding carousel ("Move more. Decide less." → privacy + medical-disclaimer checkbox → "Let's set you up").
2. Profile: 4 segmented-control taps (level / goal / time / constraints). No keyboard, no account.
3. AI generates the first plan on an Isolate (<1s) — no spinner.
4. **Climax:** Today opens with a calibrated hero session and "Partiamo piano — imparo le tue preferenze strada facendo." Zero-to-plan under 90s.

### Flow 2 — Daily loop (Marco, a gap between meetings) *(v1)*
1. Open → Today, hero already there with state + explanation; the FactorIconRow beneath quietly shows *why* (e.g. indoor + mild temp + clear air).
2. Tap Start → 3-2-1 countdown → full-screen InSessionView (timer, step, HR, haptics); the MilestoneProgressBar shows step ticks advancing toward the finish flag.
3. Last step completes → the neutral finish marker settles quietly (no glow, no confetti) → RPE tap (one touch).
4. 3s MiniSummary (type + duration + RPE + "Fatto. Domani regolo l'intensità.") → auto-return.
5. **Climax:** the CompletionRing pulse in the MiniSummary is the one emotional close; next session auto-promotes to hero; ring ticks 1/3 and the ActiveDaysCard reads "N giorni attivi negli ultimi 30" as calm state — not a chain to protect. The app resolved itself — Marco did something real in 5 minutes and made no navigation decisions.

### Flow 3 — Return after absence (Marco, 3 days away) *(v1)*
1. Open after absence → state check → AtRisk.
2. Today shows a gentle hero, amber StateIndicator, "Sei stato via 3 giorni — il corpo ha bisogno di un riavvio dolce.", only 2 sessions.
3. **Climax:** no guilt, no counter — just observation + a concretely lighter plan. He completes one; state begins AtRisk → Recovering. Bandit history from before the absence still applies.

### Flow 4 — Going Pro for the storico (Giulia) *(v2)* `[ASSUMPTION]`
1. Giulia (post-v2 install) taps "Storico completo" in Progress.
2. {ProUpsellSheet}: "Lo storico completo è una funzione Pro." + `Scopri Pro` / `non ora`.
3. She taps Scopri Pro → plans → store IAP purchase → restore-aware.
4. **Climax:** the full history + charts unlock in place; no celebration screen, just the content she reached for. No badge appears anywhere else afterward.

### Flow 5 — Co-located shared session (Marco & Giulia, park, Saturday) *(v2)* `[ASSUMPTION]`
1. Marco (Pro) opens Social → "Sessione condivisa" → {JoinCodeCard} (code + QR).
2. Giulia, beside him, scans it; a momentary, non-stored co-location check confirms proximity; both appear in {SharedSessionLobby}.
3. The app generates **one** group-adapted plan (lowest safe level, knee-loading excluded for both, shortest duration) with the line "Adattata per tutti — intensità più bassa comoda, niente carico sul ginocchio."
4. They tap Start together; both phones (and Marco's watch) advance step + timer in real time. Each rates their own RPE (Marco 4, Giulia 6) — each feeds only their own learning.
5. **Climax:** Giulia just trained with her nephew at a level that fit her — something she'd never have done alone. *That* is the payoff: the session became the reason both showed up. The leaderboard quietly reflects it afterward (a shared session is worth a little more than a solo one), but the standing is a footnote in the Social tab, never the point and never surfaced on Today. No pressure, only the pull of doing it *together*.

### Flow 6 — Find back from Settings (any user) *(v2, FR53)* `[ASSUMPTION]`
1. From Today, open drawer → Settings.
2. **Climax:** an explicit AppBar back affordance returns to the primary shell (Today) without restarting — closing the standing v1 defect where secondary drawer screens had no way back.
