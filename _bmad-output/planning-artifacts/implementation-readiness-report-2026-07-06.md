---
stepsCompleted: ['step-01-document-discovery', 'step-02-prd-analysis', 'step-03-epic-coverage-validation', 'step-04-ux-alignment', 'step-05-epic-quality-review', 'step-06-final-assessment']
documentsInScope:
  prd: '_bmad-output/planning-artifacts/prd.md'
  architecture: '_bmad-output/planning-artifacts/architecture.md'
  epics: '_bmad-output/planning-artifacts/epics.md'
  ux: '_bmad-output/planning-artifacts/ux-designs/ux-Flutter_PulseCoach-2026-06-20/'
documentsExcluded:
  - '_bmad-output/planning-artifacts/ux-design-specification.md (superseded, 2026-06-05 — superseded by newer ux-designs/ folder dated 2026-06-20)'
  - '_bmad-output/planning-artifacts/prd-validation-report.md (review artifact, not a PRD source)'
---

# Implementation Readiness Assessment Report

**Date:** 2026-07-06
**Project:** Flutter_PulseCoach

## Document Inventory

### PRD
**Whole Documents:**
- `prd.md` (71 KB, modified 2026-07-06) — **in scope**
- `prd-validation-report.md` (33 KB, modified 2026-06-05) — review artifact, excluded from scope

**Sharded:** none found.

### Architecture
**Whole Documents:**
- `architecture.md` (87 KB, modified 2026-06-20) — **in scope**

**Sharded:** none found.

### Epics & Stories
**Whole Documents:**
- `epics.md` (194 KB, modified 2026-07-06) — **in scope**

**Sharded:** none found.

### UX Design
**Whole Document:**
- `ux-design-specification.md` (119 KB, modified 2026-06-05) — **superseded, excluded from scope** (user confirmed 2026-07-06)

**Sharded/Folder:**
- `ux-designs/ux-Flutter_PulseCoach-2026-06-20/` (modified 2026-06-20) — **in scope** (authoritative UX source)
  - `DESIGN.md`, `EXPERIENCE.md`, `.decision-log.md`
  - `mockups/key-screens.html`, `mockups/key-screens-extended.html`
  - `review-accessibility.md`, `review-accessibility-polish.md`, `review-brand-ethos.md`, `review-brand-ethos-polish.md`, `review-coverage.md`

## Duplicate Resolution

⚠️ Duplicate UX documents were found: `ux-design-specification.md` (2026-06-05) vs `ux-designs/ux-Flutter_PulseCoach-2026-06-20/` (2026-06-20). User confirmed the `ux-designs/` folder as authoritative; the older whole document is excluded from this assessment.

## PRD Analysis

Source: `_bmad-output/planning-artifacts/prd.md` (status: v2-final, updated 2026-07-06). Contains v1 core PRD, a v1 "Experience Polish" addendum (FR78-82, NFR38-39, added 2026-07-06), and a v2 "Accounts, Subscriptions & Social" extension (added 2026-06-20).

### Functional Requirements

**Onboarding & Profile**
- FR1: New user can view an animated onboarding flow explaining the app concept, privacy approach, and setup process
- FR2: New user can create a profile by specifying fitness level, primary goal, available time per session, and physical constraints
- FR3: New user must accept a non-skippable medical disclaimer before accessing any app functionality
- FR4: User can view and edit their profile and goals at any time

**AI-Powered Daily Planning**
- FR5: System generates a daily plan of 3 personalized micro-sessions (2-10 minutes each) based on the user's current state
- FR6: System incorporates physiological inputs (resting HR, step count, RPE history) into session selection when available
- FR7: System incorporates environmental inputs (weather, temperature, precipitation, AQI) into session selection
- FR8: System routes sessions indoor or outdoor based on real-time AQI thresholds and weather conditions
- FR9: System applies deterministic safety rules that override bandit recommendations (e.g., RPE avg >8 for 2 consecutive sessions → block high intensity)
- FR10: System adapts session type, intensity, and duration over time using a contextual bandit learning algorithm
- FR11: User can regenerate the daily plan on demand
- FR12: System initializes new users with a plan capped at intensity level ≤ Low and session count = 3, derived from their onboarding fitness level and goal

**Explainability & Trust**
- FR13: Every session recommendation displays a structured explanation of why the system chose that specific session
- FR14: System displays human-readable messages when the behavioral state machine transitions (e.g., entering Recovering state)
- FR15: User can view their current behavioral state (Active, Fatigued, AtRisk, Recovering)

**Guided Session Execution**
- FR16: User can start any planned session with a single tap
- FR17: System displays a full-screen guided session with timer, current exercise step, and step-by-step instructions
- FR18: System provides haptic feedback on exercise step transitions
- FR19: System displays live heart rate during active sessions when sensor data is available
- FR20: User can complete or abandon a session at any time

**Feedback & Adaptation Loop**
- FR21: User can submit post-session RPE feedback (1-10 scale) after completing or abandoning a session
- FR22: System adjusts future session intensity based on RPE feedback, targeting rolling average ≈6.5
- FR23: System transitions behavioral state based on missed sessions, RPE trends, and streak patterns
- FR24: System reduces session count and intensity when user is in Recovering or AtRisk state
- FR25: System preserves bandit learning history across state machine transitions

**Exercise Catalog**
- FR26: System populates session content from an external exercise catalog (ExerciseDB)
- FR27: User can browse available sessions filtered by type (mobility, cardio, breathing)
- FR28: System caches exercise catalog data locally for offline access

**Progress & History**
- FR29: User can view session history as a timeline of completed sessions
- FR30: User can view progress charts: minutes per week, completion rate, RPE trend, session type breakdown
- FR31: User can view weekly goal progress (sessions completed vs target)
- FR32: Progress charts display with animated transitions

**Environmental Context**
- FR33: System retrieves real-time weather data (temperature, precipitation) from Open-Meteo API
- FR34: System retrieves real-time air quality index from Open-Meteo API
- FR35: System uses approximate city-level location for API calls, not precise GPS coordinates
- FR36: System defaults to indoor sessions when AQI data is stale (>2h) or unavailable

**Multi-Device Experience**
- FR37: Phone displays bottom tab navigation (Today, Sessions, Progress) with drawer menu
- FR38: Tablet displays side NavigationRail with master-detail layouts and dashboard grid
- FR39: All key screens support both portrait and landscape orientation
- FR40: WearOS companion displays current exercise step, session timer, and live HR during active sessions
- FR41: WearOS companion displays post-session summary

**Sensor Integration**
- FR42: System reads resting heart rate and daily step count from device Health API when permissions granted
- FR43: System detects activity via accelerometer when available
- FR44: System operates in RPE-only mode when sensor permissions are denied, with full functionality preserved

**Offline & Data**
- FR45: All core features (plan generation, session execution, RPE feedback, progress viewing — per NFR13) function without network connectivity
- FR46: System caches weather/AQI data with TTL and exercise catalog data locally
- FR47: System syncs data via deferred event queue when connectivity returns

**Settings & Configuration**
- FR48: User can toggle dark mode or follow system theme
- FR49: User can view privacy and data information
- FR50: User can access device and sync settings

**MVP-If-Time Capabilities**
- FR51: User can view an AI Decision Log showing bandit decision history (state vector → action → reward)
- FR52: User can export session history and AI decisions as CSV/JSON

**v2 — Navigation Fix**
- FR53: Every secondary screen reached from the drawer (Settings, Profile, Privacy, Debug) provides an explicit affordance to return to the primary screens (Today, Sessions, Progress) without restarting the app

**v2 — Accounts & Authentication**
- FR54: User can create a cloud account using email + password, Sign in with Apple, or Google Sign-In
- FR55: User can sign in, sign out, and reset a forgotten password (email flow)
- FR56: The app remains fully usable without an account — the v1 free, offline, local-only experience is preserved; an account is optional and required only to unlock backup, social, and Pro features
- FR57: When signed in, the user can opt in to back up and restore their profile, session history, and personalization state to/from their own cloud account, end-to-end encrypted with a user-held key

**v2 — Subscriptions (Pro)**
- FR58: User can view subscription plans and purchase a Pro subscription via platform store billing (App Store / Play Store IAP)
- FR59: System gates Pro-only features behind an active subscription; the free tier retains the full v1 core
- FR60: User can restore purchases and manage or cancel the subscription via the platform store
- FR61: Free tier limits Progress to the most recent session + current weekly goal; Pro unlocks the full historical timeline and all progress charts. Grandfathering: pre-v2 installs retain full Progress history for free
- FR62: Social features (FR64-75) require an active Pro subscription. Setting a username/handle (FR63) and viewing the friends leaderboard ranking (FR76) are free; creating social content is Pro

**v2 — Social: Friends**
- FR63: User can set a unique username/handle and a shareable profile; new profile and activity are private by default until the user opts into a visibility tier
- FR64: User can add friends by username, QR code/invite link, or from phone contacts (with contacts permission)
- FR65: User can send, accept, decline friend requests, and remove friends
- FR66: User can share completed-session progress with friends and view a friends activity feed
- FR67: User can compare their progress against friends'

**v2 — Social: Co-Located Live Shared Sessions**
- FR68: User can create a shared live session and invite co-located friends via a join code / QR
- FR69: A friend joins a shared session by entering the join code / scanning the QR in person; device location is a soft, momentary confirmation of co-location
- FR70: System generates a single shared session plan safe for every participant via deterministic group rules (intensity ceiling = min of all caps; fitness level = lowest present; movement exclusion = union of all constraints; duration = shortest preference)
- FR71: During a shared live session, all participants see a synchronized session state (current step + timer) in real time. `[ASSUMPTION]` WearOS mirrors the owning participant's synchronized view
- FR72: Each participant submits their own post-session RPE; each rating feeds only that participant's own personalization
- FR73: Shared sessions require: active Pro subscription, registered account, other participants in the user's friends list, location enabled for co-location confirmation, all participants meet minimum age
- FR77: User can delete their account and all associated server data from within the app (Apple Guideline 5.1.1(v) + GDPR right-to-erasure); deletion cascades per NFR30

**v2 — Social: Leaderboard & Scoring**
- FR74: System awards points for completed sessions and maintains a friends leaderboard
- FR75: Shared (co-located) sessions award more points than solo sessions. `[ASSUMPTION]` Exact point formula and anti-abuse rules deferred to design
- FR76: User can view the friends leaderboard ranking

**v1 — Experience Polish (added 2026-07-06)**
- FR78: The guided-session progress bar displays intermediate milestone markers at each session-step boundary and a distinct final "finish" marker (checkered flag), with a celebratory animation on completion. Single-step sessions show only start/finish markers
- FR79: When backgrounded during an active session, the system posts a session notification showing session name and paused timer; tapping returns to the paused session (or Today if auto-abandoned per FR80). Dismissal does not abandon the session. Android: live/ongoing notification; iOS: one-shot informational post (platform capability difference, decision not assumption)
- FR80: On backgrounding, the session timer pauses; if not resumed within a configurable inactivity timeout (default 5 minutes), the session is auto-abandoned via FR20 and the notification cancelled, reconciled on next resume. Rapid background/foreground toggling does not accumulate timeouts
- FR81: The Today tab displays a calm "active-days" indicator — count of days within the trailing 30-day window with ≥1 completed session, windowed not consecutive (no streak-reset semantics). `[ASSUMPTION]` reuses the behavioral-state-machine activity signal (FR23) rather than a second source of truth
- FR82: Session explanations (FR13/FR14) are reinforced with animated icons/glyphs for exercise type, intensity, and environmental decision factors (temperature, precipitation, AQI). Humidity explicitly excluded (decided 2026-07-06)

**Total FRs: 82** (FR1-FR82, all numbers accounted for, no gaps)

### Non-Functional Requirements

**Performance**
- NFR1: Daily plan generation completes in < 30 seconds from app open, including AI computation on a background thread
- NFR2: UI maintains ≥ 60fps / ≤ 16ms frame budget during AI computation — UI thread must never block
- NFR3: Session timer accuracy within ±1 second over the session duration
- NFR4: Haptic feedback on exercise step transitions fires within 200ms of step change
- NFR5: Weather/AQI API response cached and served from local DB in < 500ms when offline
- NFR6: App cold start to Today screen in < 3 seconds on mid-range Android device (2022+)

**Security & Privacy**
- NFR7: All health and biometric data stored exclusively on-device — zero transmission to external servers for personalization
- NFR8: Location data sent to Open-Meteo API is approximate city-level only — no precise GPS coordinates transmitted
- NFR9: Health API permissions requested with clear user-facing explanation; denial handled gracefully with RPE-only fallback
- NFR10: Medical disclaimer acceptance state persisted locally; app inaccessible until accepted
- NFR11: No user account, no email, no authentication required — profile data is local-only *(superseded/extended by v2 NFR28 — see Reconciliation table)*
- NFR12: GDPR Art. 9 compliance: biometric data (heart rate) classified as sensitive data; processed locally with explicit user consent, never shared

**Reliability & Data Integrity**
- NFR13: All core features function without network connectivity
- NFR14: API data cached with TTL: weather/AQI = 1 hour, exercise catalog = 24 hours; stale cache served when API unreachable
- NFR15: Local on-device database survives app backgrounding, force-close, and device restart without data loss
- NFR16: Bandit learning state and session history persist across app updates
- NFR17: Data loss on app uninstall/reinstall is accepted for v1; CSV/JSON export (FR52) serves as manual backup *(superseded/extended by v2 FR57 cloud backup for signed-in users)*
- NFR18: Deferred sync queue processes events in order when connectivity returns; failed sync retries with increasing delay (capped at 1 hour)

**Integration Resilience**
- NFR19: Open-Meteo API failure → cached weather/AQI data used; defaults to indoor sessions if cache stale >2 hours
- NFR20: ExerciseDB API failure → locally cached exercise catalog used; session generation continues
- NFR21: Health API unavailable/denied → system operates in RPE-only mode with no degradation of core AI functionality
- NFR22: WearOS companion disconnection during active session → phone continues session independently; watch reconnects and resumes display when available
- NFR23: All external API integrations must fail fast when unreachable, serve cached data immediately, and retry automatically when connectivity returns

**Accessibility (Minimum — MVP)**
- NFR24: All interactive elements meet minimum touch target size (48x48dp)
- NFR25: Color contrast ratios meet WCAG 2.1 AA minimum (4.5:1 normal text, 3:1 large text) in both light and dark mode
- NFR26: Full semantic accessibility (VoiceOver/TalkBack) deferred to Growth phase; NFR24-25 are the MVP minimum

**v2 — Authentication & Account Security**
- NFR27: Authentication uses industry-standard secure practices — hashed passwords, OAuth/OIDC for Apple/Google, secure token storage, TLS transport
- NFR28: On-device personalization preserved — adaptive AI runs on-device; cloud sync opt-in, own-account-scoped, backup/social only, never centralized cross-user training

**v2 — Privacy & Compliance (cloud)**
- NFR29: Social sharing via defined visibility tiers (private default / friends-only / per-item); never friend-of-friend visible; leaderboard shows ranking+points only, not biometric detail; shares revocable
- NFR30: GDPR for cloud data — user can export server data (JSON) and delete account (FR77); deletion cascades (profile, friendships, shared content, feed, leaderboard) within SLA (immediate visible removal, ≤30 days full purge)
- NFR33: Co-location confirmation uses location only momentarily at session start; not stored, not continuously tracked, never exposed to other users (boolean result only); non-blocking check
- NFR35: Each cloud personal-data purpose has a distinct lawful basis and granular, unbundled consent, independently withdrawable
- NFR36: Cloud data residency — EU users' server-side personal data stored in an EU region. `[ASSUMPTION]` exact provider/region open
- NFR37: Accounts and social suite have a minimum age (`[ASSUMPTION]` 16, GDPR Art. 8 default, configurable per market); confirmed at registration

**v2 — Real-Time & Reliability**
- NFR31: Shared-session state stays synchronized across participants within ~1 second; a dropped participant does not interrupt others
- NFR34: Social/cloud features degrade gracefully offline; v1 core remains fully offline-first regardless of account/subscription state

**v2 — Store & Billing Compliance**
- NFR32: Subscription billing complies with App Store/Play Store policies — platform IAP, Sign in with Apple offered, required privacy disclosures (nutrition labels)

**v1 — Experience Polish (added 2026-07-06)**
- NFR38: New animated elements (FR78 milestone markers/finish animation, FR82 decision-factor icons) honor NFR2 60fps budget and respect OS "reduce motion", degrading to static equivalents. FR81 active-days indicator excluded (no bespoke animation)
- NFR39: The session notification (FR79) exposes only non-sensitive content (session name + timer), never biometric/HR data; notification permission requested with rationale on both platforms; if denied, session still pauses per FR80 with no notification. Lock-screen shows full session name (generic category labels, low sensitivity, decided 2026-07-06)

**Total NFRs: 39** (NFR1-NFR39, all numbers accounted for except NFR11/NFR17 which are v1 values reconciled/extended — not superseded/removed — by v2; no true gaps)

### Additional Requirements / Constraints

- **Domain compliance:** No FDA/HIPAA obligations; GDPR Art. 9 applies to biometric data (v1: on-device only; v2: cloud-scoped consent per NFR35)
- **Safety layer (deterministic overrides):** RPE>8 for 2 sessions → block high intensity; AtRisk state → cap intensity Low + reduce to 2 sessions; AQI>100 → block outdoor; resting HR >20% above baseline → reduce intensity automatically
- **Medical disclaimer:** mandatory, non-skippable, first-launch, before onboarding
- **Platform targets:** Android (API 26+) phone+tablet, iOS 15+ iPhone+iPad, WearOS 3.0+ companion
- **Framework decisions (confirmed):** flutter_bloc, drift, go_router, Clean Architecture/MVVM feature-first
- **Threading model:** AI plan generation + RPE reward calc on Dart Isolate; network/DB async; UI on main isolate
- **Contingency sacrifice order** (if time-constrained): 1) Lottie → native animations, 2) animated onboarding → static, 3) AI Decision Log + CSV export (FR51-52), Never: WearOS, tablet layout, rotation, 2 external APIs, test campaign, dark mode, custom look & feel
- **v2 reconciliation table** (PRD explicitly resolves 5 v1/v2 conflicts): NFR11, NFR7, NFR17, NFR8/FR35, Growth/Vision items — each has a documented resolution preserving v1 free/offline/on-device posture
- **v2 phasing** (build order, each phase independently shippable): v2.0 nav fix → v2.1 accounts+deletion+backup → v2.2 Pro+gating → v2.3 social graph → v2.4a realtime transport → v2.4b group-adapted difficulty → v2.5 leaderboard
- **Open items explicitly flagged non-blocking in PRD:** backend tech + data residency region, exact Pro price/tier, point formula + anti-abuse rules, WearOS full-participant-vs-mirror-only in shared sessions, final minimum-age per market

### PRD Completeness Assessment

The PRD is unusually mature and internally rigorous for this stage:
- FR and NFR numbering is fully sequential and complete across three additive layers (v1 core, v1 Experience Polish, v2) with no missing numbers.
- The document proactively surfaces its own conflicts (v1 vs v2) in an explicit reconciliation table rather than leaving them implicit — this is a strong signal for traceability but must be checked against epics/stories to confirm each resolution actually landed in scoped work.
- Several requirements are explicitly tagged `[ASSUMPTION]` (FR71, FR75, NFR36, NFR37) and one open-items list is called out as "non-blocking" — these need explicit epic/story coverage decisions, not silent adoption.
- FR61's grandfathering clause (pre-v2 vs post-v2 install detection) is a nontrivial technical requirement embedded in a business rule — worth confirming it has explicit story coverage, not just a footnote.
- v2 phasing table (v2.0-v2.5) gives a natural epic boundary — will check epics.md alignment against these phase boundaries in the next step.

## Epic Coverage Validation

Source: `_bmad-output/planning-artifacts/epics.md` (3065 lines, 22 epics). The document contains an explicit **FR Coverage Map** (epics.md:261) mapping each epic to its FR/NFR/UX-DR/ARCH references — unusually good traceability discipline for this stage.

### Coverage Matrix (by epic)

| Epic | Stories | FRs Covered | NFRs Covered |
|---|---|---|---|
| Epic 1: Foundation | 1.1-1.7 | — | NFR2, NFR15-16 |
| Epic 2: Onboarding | 2.1-2.4 | FR1-4 | NFR9-12 |
| Epic 3: Sensor Integration | 3.1-3.3 | FR42-44 | NFR7-9, NFR21 |
| Epic 4: Environmental Context | 4.1-4.3 | FR33-36 | NFR5, NFR8, NFR14, NFR19, NFR23 |
| Epic 5: AI Engine & Daily Planning | 5.1-5.6 | FR5-15, FR22-25 | NFR1-2, NFR7 |
| Epic 6: Exercise Catalog | 6.1-6.3 | FR26-28 | NFR14, NFR20, NFR23 |
| Epic 7: Today Screen | 7.1-7.4 | FR5, FR11, FR15-16 | NFR6 |
| Epic 8: In-Session Experience | 8.1-8.5 | FR17-20 | NFR2-4 |
| Epic 9: Feedback & Adaptation | 9.1-9.3 | FR21-24 | NFR1 |
| Epic 10: Progress & History | 10.1-10.3 | FR29-32 | — |
| Epic 11: Responsive Layout | 11.1-11.3 | FR37-39 | NFR24-25 |
| Epic 12: WearOS Companion | 12.1-12.4 | FR40-41 | NFR22 |
| Epic 13: Offline & Data Sync | 13.1-13.3 | FR45-47 | NFR13-16, NFR18, NFR23 |
| Epic 14: Settings & Extras | 14.1-14.5 | FR48-52 | NFR11, NFR26 |
| Epic 15: Navigation Fix (v2.0) | 15.1 | FR53 | — |
| Epic 16: Accounts & Auth (v2.1) | 16.1-16.4 | FR54-57, FR77 | NFR27-28, NFR30, NFR35-37 |
| Epic 17: Pro Subscription (v2.2) | 17.1-17.4 | FR58-62 | NFR32, NFR34 |
| Epic 18: Social Graph (v2.3) | 18.1-18.4 | FR63-67 | NFR29-30, NFR34-35 |
| Epic 19: Realtime Transport (v2.4a) | 19.1-19.3 | FR71 | NFR31, NFR34 |
| Epic 20: Shared Sessions (v2.4b) | 20.1-20.5 | FR68-70, FR72-73 | NFR31, NFR33-34 |
| Epic 21: Leaderboard & Scoring (v2.5) | 21.1-21.3 | FR74-76 | NFR34 |
| Epic 22: Experience Polish (v1) | 22.1-22.4 (est.) | FR78-82 | NFR38-39 |

*(Epic 22 is not in the original coverage-map table at epics.md:261-286 — added later in the same document; its FR/NFR coverage is confirmed instead from its epic description at epics.md:319 and story acceptance criteria at epics.md:2887-3025.)*

### FR Coverage Check (FR1-FR82)

All 82 FRs cross-checked against the matrix above (range notations expanded, e.g. Epic 5's "FR5-15" verified to include FR6-FR14 individually):

**Result: 82/82 FRs covered. Zero gaps.** Spot-verified FR6 (physiological inputs into `StateVector`) directly in Story 5.1's acceptance criteria (epics.md:757-777): `StateVector` explicitly contains `restingHR`, `stepCount`, `rpeHistory` — confirming the range claim isn't just a table artifact.

### NFR Coverage Check (NFR1-NFR39)

All 39 NFRs cross-checked. **37/39 explicitly mapped to an epic; 2 are accepted risk/constraint statements rather than build items:**

- **NFR17** ("Data loss on app uninstall/reinstall is accepted for v1") — this is a PRD-level *risk acceptance*, not a feature to implement. No epic references it, which is correct — nothing to build. Not a gap.
- NFR38-39 (Experience Polish) are covered by Epic 22 but only appear in the requirements inventory (epics.md:186-187) and the epic's own description/stories — not in the original FR Coverage Map table, since that table predates the 2026-07-06 delta. Confirmed present via direct grep of Epic 22's stories (epics.md:2925, 2961, 2989, 3017-3025).

### Missing Requirements

**None found.** No critical or high-priority missing FR/NFR coverage identified.

### Coverage Statistics

- Total PRD FRs: 82 — Covered: 82 — **Coverage: 100%**
- Total PRD NFRs: 39 — Covered: 37 (2 are non-build risk-acceptance items, correctly uncovered) — **Effective coverage: 100%**

## UX Alignment Assessment

### UX Document Status

**Found.** Authoritative source: `ux-designs/ux-Flutter_PulseCoach-2026-06-20/` (`DESIGN.md` = look, `EXPERIENCE.md` = flows/interaction), per the user's discovery-step confirmation.

### UX ↔ PRD Alignment

- **Design tokens verified against epics.md's "UX Design Requirements" (UX-DR1-33):** color hex values, spacing scale, and typography in UX-DR1/UX-DR22 match `DESIGN.md` exactly (`#0F1119`, `#7DD3C0`, etc. — cross-checked directly, not just by name). The requirements-inventory abstraction in `epics.md` is a faithful distillation of the current DESIGN.md/EXPERIENCE.md, not a stale carryover from the superseded `ux-design-specification.md`.
- **FR81 (active-days indicator) — now aligned, but via a live correction.** `DESIGN.md:132` carries a note flagging that FR81 originally specified a *consecutive*-day streak (reset-to-zero), which the UX spine deliberately reframed to a *windowed* 30-day count to preserve the "no guilt mechanic" brand ethos, and asked for "a matching PRD correct-course." Checking `prd.md` (read in Step 2): **FR81 already reads as windowed, not consecutive** — the correction has landed. No outstanding contradiction, but this is a good example of UX driving a PRD change after the fact; worth confirming the correction is reflected in Epic 22's stories too (spot-checked: it is — epics.md:2989 uses windowed framing).
- **✅ UX review findings on the newest PRD delta (FR78/FR81/FR82) — verified RESOLVED, not outstanding.** Two dated 2026-07-06 review artifacts in the UX folder (`review-accessibility-polish.md`, 1 BLOCKER + 3 HIGH; `review-brand-ethos-polish.md`, 1 HIGH + 2 MED + 1 LOW) both gated at **PASS-WITH-FIXES**. At first read these looked like open defects, but **file timestamps confirm the fixes already landed same-day**: both review files were written at 12:41-12:42, while `DESIGN.md`/`EXPERIENCE.md`/`.decision-log.md` were saved afterward at 12:56-13:01. Cross-checking current spec text confirms every flagged item is fixed: `FactorIconRow` now specifies "tap target is a ≥48dp transparent hit-area... wraps to a second line" (DESIGN.md:215); `MilestoneProgressBar`'s finish marker is now "a soft filled dot / check, not a checkered flag" with shape-based (not hue-based) reached/unreached distinction and explicit non-stacking with the CompletionRing pulse (DESIGN.md:209); `ActiveDaysCard` is windowed, not consecutive (DESIGN.md:216). **Epic 22's story-level acceptance criteria (epics.md Stories 22.1-22.3) already encode every one of these fixes verbatim** — good evidence the PRD→UX→Epics chain absorbed the review feedback correctly in one pass, same day. No outstanding UX spec defect found.

### UX ↔ Architecture Alignment

- Responsive layout (UX-DR15-16), theming (UX-DR1,UX-DR17,UX-DR20), and shimmer-loading (UX-DR system) are backed by concrete architecture decisions: ARCH15 (600dp breakpoint), ARCH16 (`ThemeExtension`), ARCH10 (shimmer, no spinners). Alignment is solid for v1 core and v2 social/Pro UI (ARCH17-27 cover the Supabase-backed screens UX-DR21-33 imply).
- **⚠️ Minor gap: architecture.md itself has no formal entry for the Epic 22 notification mechanism, though the decision has in fact been made.** `architecture.md` (1557 lines) has zero mentions of `flutter_local_notifications` or background-execution strategy. The PRD-delta review (`review-delta-notification.md`) flagged the FR79/FR80 background-timeout mechanism as a HIGH-severity open question (Android 14+ ongoing-notification dismissal, scheduled-vs-reconcile-on-resume tradeoff) — **but this has since been resolved at the epic level**: Story 22.4/22.5's acceptance criteria (epics.md, Epic 22 prerequisites + Stories 22.4-22.5) explicitly specify "no foreground service," "reconcile-on-resume" for the authoritative abandon decision, and a "scheduled notification cancel/replace... at the timeout instant" for the visual dismissal — directly adopting the review's recommended pattern. The only residual gap is bookkeeping: this decision isn't mirrored into `architecture.md` as a numbered ARCH entry (unlike v2's ARCH17-27), so a future reader of architecture.md alone would miss it. Recommend adding one ARCH entry (e.g. ARCH28) purely for documentation consistency — not a blocker.

### Warnings

1. **Minor documentation nit only:** add an ARCH entry (e.g. ARCH28) mirroring the already-decided FR79/FR80 notification mechanism (reconcile-on-resume + scheduled visual dismiss, "no foreground service") into `architecture.md`, matching the pattern used for v2 (ARCH17-27). The decision itself is sound and already encoded in Epic 22's stories — this is purely for a future reader of architecture.md in isolation.
2. `review-delta-rubric.md` (PRD-delta review, not UX, at planning-artifacts root) raised additional lower-severity findings on the FR78-82 delta — streak/timezone/DST rules (now moot, FR81 is windowed), rapid background/foreground toggle semantics, and no explicit default/bound on the inactivity timeout *in the FR text itself* (Story 22.5 does specify "default 5 minutes" as an AC, so this is resolved at the story level even if the bare FR80 sentence in prd.md doesn't state the number). No action required beyond noting the resolution lives in the story, not the FR.

## Epic Quality Review

### Scope of this review

Per `_bmad-output/implementation-artifacts/sprint-status.yaml`, **Epics 1-21 are all marked `done`** (implemented, code-reviewed, and retro'd across multiple prior BMad cycles). **Epic 22 (Experience Polish) is the only epic still in `backlog`.** This review therefore applies full best-practices scrutiny to Epic 22 (the epic actually facing an implementation-readiness decision) and a structural/dependency sanity pass across all 22 epics (cheap to verify, catches drift even in "done" epics' documentation).

### Structural sanity pass (all 22 epics)

- **Dependency direction:** every explicit "depends on Epic N" statement found in the document points backward only (Epic 18 → 16,17; Epic 20 → 16,17,18,19; Epic 21 → 20). No forward dependencies found (`grep` for "depends on/requires Epic" across the full file). ✓
- **v2 phasing fidelity:** Epic 15-21 map 1:1 onto the PRD's v2.0-v2.5 phasing table (Step 2 finding) in the same order. ✓
- **User-value framing — one structural deviation, but pre-existing and consistently applied, not a new defect:** Epic 1 (Foundation & Project Infrastructure), Epic 3 (Sensor Integration), Epic 4 (Environmental Context), Epic 6 (Exercise Catalog), and Epic 13 (Offline & Data Sync) are organized by technical/system layer rather than end-to-end user journey — a deviation from the strict "epics deliver user value" rule (Epic 1 especially: no user-facing value on its own). This is the established organizing pattern across the entire document (all now-`done` epics), consistent with the create-epics-and-stories rubric's own carve-out for greenfield foundation epics (initial project setup, CI/CD early). Flagging as a **documented, pre-existing style choice**, not a new violation to block on — re-litigating it now would contradict 21 epics' worth of prior sign-off.
- **Interstitial epics (6.5, 7.5):** both are retro-driven, capped in scope, and already shipped — consistent with the project's own Deferred Items Budget process (CLAUDE.md). No issue.

### Epic 22 — full quality review (the epic actually pending implementation)

**Epic-level:**
- **User value:** ✓ Goal is user-facing ("visible checkpoints," "quiet icons... reasoning visible," "calm record... no pressure," "know a session is still open"), not a technical milestone.
- **Independence:** ✓ Explicitly declared independent of Epics 15-21 (sprint-status.yaml:312, "No dependency on Epics 15-21"); layers only on the already-`done` v1 core (FR13/14, FR20, FR23).
- **Prerequisites documented up front:** the epic's own "Prerequisites / notes" block (epics.md:2891-2895) flags the one net-new dependency (`flutter_local_notifications`), the single-source-of-truth constraint (Story 22.3 must not duplicate FR23's counter), and the presentation-only boundary (Story 22.2 introduces no new inference/data) — this is exactly the kind of forward-looking scope discipline the rubric wants.

**Story-level (22.1-22.5):**
- **Sizing:** each story maps to exactly one FR (22.1→FR78, 22.2→FR82, 22.3→FR81, 22.4→FR79/NFR39 infra, 22.5→FR80 lifecycle) — no story bundles unrelated capabilities, none looks epic-sized.
- **Independence / dependency direction within the epic:** 22.1-22.3 are fully independent of each other (three different UI surfaces). 22.5 depends on 22.4's notification infrastructure — a backward dependency (later story uses earlier story's output), which is the *correct* direction per the rubric, not a violation.
- **Acceptance criteria quality:** consistently proper Given/When/Then BDD structure; each story covers not just the happy path but explicit edge cases — reduce-motion degradation (22.1, 22.2), screen-reader/semantics (22.1, 22.3), single-step sessions (22.1), permission-denied graceful degradation (22.4), rapid background/foreground toggling and force-kill/cold-start reconciliation (22.5). This is unusually complete for a first-draft epic.
- **One explicitly-flagged open decision, correctly deferred rather than hidden:** Story 22.5's last AC states that whether timeout-abandon should be tagged distinctly from explicit abandon "is resolved during `create-story`... open decision, surface at story creation" (epics.md, Story 22.5) — this is good practice (explicit deferral with a named resolution point), not a gap, but **must actually be resolved when Story 22.5 is created**, not silently dropped.
- **Traceability:** every AC cites its FR/NFR (and often the specific review finding it resolves, e.g. "review-delta-notification 1c/4e") — traceability is exceptionally tight for this epic.

### Findings by severity

**🔴 Critical Violations:** None found.

**🟠 Major Issues:** None found in Epic 22. (The pre-existing technical-layer epic organization in Epics 1/3/4/6/13 would be a major issue in a fresh review, but is out of scope as already-shipped, previously-accepted structure — see Structural sanity pass above.)

**🟡 Minor Concerns:**
- Epic 22 has no explicit story for "22.0 add `flutter_local_notifications` dependency" as a standalone setup story — it's folded into Story 22.4's first AC instead. Not a violation (the rubric doesn't mandate a separate setup story when the dependency is small and single-purpose), just worth confirming during `create-story` that the pubspec/platform-manifest changes (Android `POST_NOTIFICATIONS`, iOS notification entitlement) get explicit AC coverage, not just implied by "integrated."
- Story 22.5's deferred tagging decision (timeout-abandon vs. explicit-abandon) must be tracked to ensure it's actually decided at story-creation time and not left open through implementation — recommend the create-story step explicitly force this decision rather than let the AC's "TBD" language carry through unresolved.

## Summary and Recommendations

### Overall Readiness Status

**READY** — with two small housekeeping items, neither blocking.

### Critical Issues Requiring Immediate Action

**None.** No critical or major violations were found anywhere in this assessment:
- PRD: 82/82 FR + 39/39 NFR fully numbered, no gaps, self-reconciled v1/v2 conflicts.
- Epics: 100% FR/NFR coverage, correct backward-only epic dependencies, Epic 22 (the only epic not yet built) passes full quality review with no critical/major findings.
- UX: design tokens verified byte-for-byte against the authoritative spec; the one BLOCKER and several HIGH findings that surfaced during discovery were traced via file timestamps to same-day, already-applied fixes — not open defects.

### Non-Blocking Items to Track

1. **Documentation consistency, not a decision gap:** add an `ARCH28`-style entry to `architecture.md` mirroring the already-made FR79/FR80 notification mechanism decision (reconcile-on-resume + scheduled visual dismiss, no foreground service) so a reader of architecture.md alone doesn't miss it. The decision itself is sound and is already in Epic 22's story ACs.
2. **One explicitly-deferred decision to close, not lose:** Story 22.5's open question (should a timeout-triggered auto-abandon be tagged differently from an explicit user abandon, to avoid over-penalizing the behavioral state machine) is correctly flagged in the epic as "resolved during `create-story`" — make sure `bmad-create-story` for 22.5 actually forces this decision rather than letting it silently ride into implementation.
3. **Superseded artifact housekeeping:** `ux-design-specification.md` (2026-06-05) is confirmed superseded by the `ux-designs/` folder — consider renaming/archiving it (e.g. `ux-design-specification.SUPERSEDED.md`) so future readers don't hit the same duplicate-discovery ambiguity this assessment had to resolve manually.

### Recommended Next Steps

1. Run `bmad-create-story` for Epic 22 (Stories 22.1-22.5) — the epic is fully specified and ready; no prerequisite planning work is outstanding.
2. Add the ARCH28 documentation entry (item #1 above) any time before or during Epic 22 dev — cheap, non-blocking, purely for architecture.md completeness.
3. When creating Story 22.5, explicitly resolve and record the timeout-vs-explicit-abandon tagging decision (item #2 above) rather than carrying the "TBD" forward.
4. Optional cleanup: archive/rename the superseded `ux-design-specification.md` (item #3 above) to remove future ambiguity — no functional impact, pure hygiene.

### Final Note

This assessment reviewed PRD (82 FR / 39 NFR), Epics (22 epics, 21 already shipped + Epic 22 in backlog), and UX (`ux-designs/ux-Flutter_PulseCoach-2026-06-20/`) for Flutter_PulseCoach. Zero critical or major issues were found; three minor, non-blocking housekeeping items were identified, none of which should delay starting Epic 22 implementation. This project shows unusually strong requirements-to-story traceability (explicit FR/NFR coverage maps, review-finding citations embedded directly in acceptance criteria) — a level of discipline worth preserving as new epics are added.

---
**Assessed by:** BMad Implementation Readiness workflow · **Date:** 2026-07-06
