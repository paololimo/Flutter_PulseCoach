---
date: '2026-06-20'
project: 'Flutter_PulseCoach'
stepsCompleted: ['step-01-document-discovery', 'step-02-prd-analysis', 'step-03-epic-coverage-validation', 'step-04-ux-alignment', 'step-05-epic-quality-review', 'step-06-final-assessment']
documentsSelected:
  prd: '_bmad-output/planning-artifacts/prd.md'
  architecture: '_bmad-output/planning-artifacts/architecture.md'
  epics: '_bmad-output/planning-artifacts/epics.md'
  ux_legacy: '_bmad-output/planning-artifacts/ux-design-specification.md'
  ux_new: '_bmad-output/planning-artifacts/ux-designs/ux-Flutter_PulseCoach-2026-06-20/'
  addendum: '_bmad-output/planning-artifacts/addendum.md'
---

# Implementation Readiness Assessment Report

**Date:** 2026-06-20
**Project:** Flutter_PulseCoach

---

## Step 1: Document Discovery

### PRD Documents Found

**Whole Documents:**
- `prd.md` (65K, modified 2026-06-20 08:57) ← **SELECTED**
- `prd-validation-report.md` (32K, modified 2026-06-05) — validation report, not primary PRD

**Sharded Documents:** None

---

### Architecture Documents Found

**Whole Documents:**
- `architecture.md` (85K, modified 2026-06-20 10:44) ← **SELECTED**

**Sharded Documents:** None

---

### Epics & Stories Documents Found

**Whole Documents:**
- `epics.md` (106K, modified 2026-06-05) ← **SELECTED**

**Sharded Documents:** None

---

### UX Design Documents Found

**Whole Documents:**
- `ux-design-specification.md` (116K, modified 2026-06-05) ← legacy version

**Sharded/Folder Documents:**
- Folder: `ux-designs/ux-Flutter_PulseCoach-2026-06-20/`
  - `DESIGN.md` (16K, 2026-06-20)
  - `EXPERIENCE.md` (24K, 2026-06-20)
  - `review-accessibility.md` (16K, 2026-06-20)
  - `review-brand-ethos.md` (13K, 2026-06-20)
  - `review-coverage.md` (10K, 2026-06-20)
  - `mockups/` (folder)
  - `imports/` (folder)

⚠️ **NOTE: Two UX versions found** — `ux-design-specification.md` (older, Jun 5) and `ux-designs/` folder (newer, Jun 20). Both will be reviewed; the newer folder set takes precedence.

---

### Supplementary Documents Found

- `addendum.md` (1.2K, 2026-06-20) — architecture addendum
- `product-brief-Flutter_PulseCoach.md` (12K, 2026-06-05)
- `product-brief-Flutter_PulseCoach-distillate.md` (12K, 2026-06-05)
- `implementation-readiness-report-2026-03-27.md` (31K) — prior readiness report
- `review-privacy-compliance.md`, `review-rubric.md`, `review-scope-store.md` — recent reviews (2026-06-20)
- `sprint-change-proposal-2026-05-20.md`, `sprint-change-proposal-2026-05-24.md`

---

### Issues Summary

| Issue | Severity | Resolution |
|---|---|---|
| Two UX versions (legacy whole + new folder) | LOW | New folder (2026-06-20) takes precedence; legacy retained as reference |
| No duplicate PRD/Architecture/Epics | ✅ None | — |
| Prior readiness report exists (2026-03-27) | INFO | This is a fresh run; prior report retained |

---

## Step 2: PRD Analysis

**PRD Version:** v2-final (updated 2026-06-20)
**Scope:** v1 (on-device AI, mobile app) + v2 addendum (accounts, subscriptions, social)

---

### Functional Requirements

#### v1 — Onboarding & Profile
- **FR1:** New user can view an animated onboarding flow explaining the app concept, privacy approach, and setup process
- **FR2:** New user can create a profile by specifying fitness level, primary goal, available time per session, and physical constraints
- **FR3:** New user must accept a non-skippable medical disclaimer before accessing any app functionality
- **FR4:** User can view and edit their profile and goals at any time

#### v1 — AI-Powered Daily Planning
- **FR5:** System generates a daily plan of 3 personalized micro-sessions (2-10 minutes each) based on the user's current state
- **FR6:** System incorporates physiological inputs (resting HR, step count, RPE history) into session selection when available
- **FR7:** System incorporates environmental inputs (weather, temperature, precipitation, AQI) into session selection
- **FR8:** System routes sessions indoor or outdoor based on real-time AQI thresholds and weather conditions
- **FR9:** System applies deterministic safety rules that override bandit recommendations (RPE avg >8 for 2 sessions → block high intensity; AtRisk → max low intensity, count=2; AQI>100 → indoor only; resting HR >20% above baseline → intensity reduction)
- **FR10:** System adapts session type, intensity, and duration over time using a contextual bandit learning algorithm
- **FR11:** User can regenerate the daily plan on demand
- **FR12:** System initializes new users with a plan capped at intensity ≤ Low and count=3, derived from onboarding fitness level and goal

#### v1 — Explainability & Trust
- **FR13:** Every session recommendation displays a structured explanation of why the system chose that specific session
- **FR14:** System displays human-readable messages when the behavioral state machine transitions (e.g., entering Recovering state)
- **FR15:** User can view their current behavioral state (Active, Fatigued, AtRisk, Recovering)

#### v1 — Guided Session Execution
- **FR16:** User can start any planned session with a single tap
- **FR17:** System displays a full-screen guided session with timer, current exercise step, and step-by-step instructions
- **FR18:** System provides haptic feedback on exercise step transitions
- **FR19:** System displays live heart rate during active sessions when sensor data is available
- **FR20:** User can complete or abandon a session at any time

#### v1 — Feedback & Adaptation Loop
- **FR21:** User can submit post-session RPE feedback (1-10 scale) after completing or abandoning a session
- **FR22:** System adjusts future session intensity based on RPE feedback, targeting rolling average ≈6.5
- **FR23:** System transitions behavioral state based on missed sessions, RPE trends, and streak patterns
- **FR24:** System reduces session count and intensity when user is in Recovering or AtRisk state
- **FR25:** System preserves bandit learning history across state machine transitions

#### v1 — Exercise Catalog
- **FR26:** System populates session content from an external exercise catalog (ExerciseDB)
- **FR27:** User can browse available sessions filtered by type (mobility, cardio, breathing)
- **FR28:** System caches exercise catalog data locally for offline access

#### v1 — Progress & History
- **FR29:** User can view session history as a timeline of completed sessions
- **FR30:** User can view progress charts: minutes per week, completion rate, RPE trend, session type breakdown
- **FR31:** User can view weekly goal progress (sessions completed vs target)
- **FR32:** Progress charts display with animated transitions

#### v1 — Environmental Context
- **FR33:** System retrieves real-time weather data (temperature, precipitation) from Open-Meteo API
- **FR34:** System retrieves real-time AQI from Open-Meteo API
- **FR35:** System uses approximate city-level location for API calls, not precise GPS
- **FR36:** System defaults to indoor sessions when AQI data is stale (>2h) or unavailable

#### v1 — Multi-Device Experience
- **FR37:** Phone displays bottom tab navigation (Today, Sessions, Progress) with drawer menu
- **FR38:** Tablet displays side NavigationRail with master-detail layouts and dashboard grid
- **FR39:** All key screens support both portrait and landscape orientation
- **FR40:** WearOS companion displays current exercise step, session timer, and live HR during active sessions
- **FR41:** WearOS companion displays post-session summary

#### v1 — Sensor Integration
- **FR42:** System reads resting heart rate and daily step count from device Health API when permissions granted
- **FR43:** System detects activity via accelerometer when available
- **FR44:** System operates in RPE-only mode when sensor permissions are denied, with full functionality preserved

#### v1 — Offline & Data
- **FR45:** All core features (plan generation, session execution, RPE feedback, progress viewing) function without network connectivity
- **FR46:** System caches weather/AQI data with TTL and exercise catalog data locally
- **FR47:** System syncs data via deferred event queue when connectivity returns

#### v1 — Settings & Configuration
- **FR48:** User can toggle dark mode or follow system theme
- **FR49:** User can view privacy and data information
- **FR50:** User can access device and sync settings

#### v1 — MVP If Time Permits
- **FR51:** User can view an AI Decision Log showing bandit decision history (state vector → action → reward)
- **FR52:** User can export session history and AI decisions as CSV/JSON

#### v2 — Navigation Fix
- **FR53:** Every secondary screen reached from the drawer provides an explicit affordance to return to primary screens without restarting the app

#### v2 — Accounts & Authentication
- **FR54:** User can create a cloud account using email + password, Sign in with Apple, or Google Sign-In
- **FR55:** User can sign in, sign out, and reset a forgotten password (email flow)
- **FR56:** App remains fully usable without an account; account required only for backup, social, and Pro features
- **FR57:** When signed in, user can opt in to back up/restore profile, session history, and personalization state (E2E encrypted with user-held key)

#### v2 — Subscriptions (Pro)
- **FR58:** User can view subscription plans and purchase a Pro subscription via platform store IAP
- **FR59:** System gates Pro-only features; free tier retains full v1 core
- **FR60:** User can restore purchases and manage/cancel subscription via platform store
- **FR61:** Free tier limits Progress to most recent session + current weekly goal; Pro unlocks full history; v1 users grandfathered (pre-v2 installs keep full history free)
- **FR62:** Social features (FR64–FR75) require active Pro; username setup (FR63) and leaderboard viewing (FR76) are free

#### v2 — Social — Friends
- **FR63:** User can set a unique username/handle and shareable profile (private by default)
- **FR64:** User can add friends by username, QR code/invite link, or contacts
- **FR65:** User can send, accept, decline friend requests, and remove friends
- **FR66:** User can share completed-session progress with friends and view a friends activity feed
- **FR67:** User can compare their progress against friends'

#### v2 — Social — Co-Located Live Shared Sessions
- **FR68:** User can create a shared live session and invite co-located friends via join code/QR
- **FR69:** A friend joins a shared session by entering join code/QR; momentary location check for co-location confirmation (non-blocking)
- **FR70:** System generates a single shared session plan safe for all participants via deterministic group rules (intensity ceiling = minimum safety cap; fitness level = lowest; movement exclusion = union of constraints; duration = shortest preference; v1 safety rules still apply per-participant)
- **FR71:** During shared session, all participants see synchronized session state (step + timer) in real time
- **FR72:** Each participant submits their own post-session RPE feeding only their own personalization
- **FR73:** Shared sessions require: Pro subscription, registered account, participants in friends list, location enabled, all participants meet minimum age
- **FR77:** User can delete their account and all associated server data from within the app (GDPR right-to-erasure + App Store Guideline 5.1.1(v))

#### v2 — Leaderboard & Scoring
- **FR74:** System awards points for completed sessions and maintains a friends leaderboard
- **FR75:** Shared (co-located) sessions award more points than solo sessions
- **FR76:** User can view the friends leaderboard ranking

**Total FRs: 52 (v1) + 25 (v2, FR53–FR77) = 77**

---

### Non-Functional Requirements

#### v1 — Performance
- **NFR1:** Daily plan generation completes in < 30 seconds from app open, AI on background Isolate, never blocking UI
- **NFR2:** UI maintains ≥60fps / ≤16ms frame budget during AI computation
- **NFR3:** Session timer accuracy within ±1 second over session duration
- **NFR4:** Haptic feedback on step transitions fires within 200ms of step change
- **NFR5:** Weather/AQI cached data served in < 500ms when offline
- **NFR6:** App cold start to Today screen in < 3 seconds on mid-range Android (2022+)

#### v1 — Security & Privacy
- **NFR7:** All health/biometric data stored exclusively on-device; zero transmission for personalization
- **NFR8:** Location data sent to Open-Meteo is approximate city-level only; no precise GPS transmitted
- **NFR9:** Health API permissions requested with clear explanation; denial handled gracefully (RPE-only fallback)
- **NFR10:** Medical disclaimer acceptance persisted locally; app inaccessible until accepted
- **NFR11:** No user account, no email, no authentication — profile data is local-only (v1)
- **NFR12:** GDPR Art. 9 compliance: biometric data (HR) classified as sensitive; processed locally with explicit consent, never shared

#### v1 — Reliability & Data Integrity
- **NFR13:** All core features function without network connectivity
- **NFR14:** API data cached with TTL: weather/AQI = 1 hour, exercise catalog = 24 hours; stale cache served when API unreachable
- **NFR15:** Local on-device database survives app backgrounding, force-close, and device restart without data loss
- **NFR16:** Bandit learning state and session history persist across app updates
- **NFR17:** Data loss on uninstall/reinstall accepted for v1; CSV/JSON export (FR52) is the manual backup
- **NFR18:** Deferred sync queue processes events in order; failed sync retries with increasing delay (capped at 1 hour)

#### v1 — Integration Resilience
- **NFR19:** Open-Meteo API failure → cached data used; indoor sessions if cache stale >2h
- **NFR20:** ExerciseDB API failure → locally cached exercise catalog; generation continues
- **NFR21:** Health API unavailable or permissions denied → RPE-only mode; no degradation of core AI
- **NFR22:** WearOS disconnection during session → phone continues independently; watch reconnects and resumes
- **NFR23:** All external API integrations must fail fast, serve cached data immediately, retry automatically

#### v1 — Accessibility (Minimum MVP)
- **NFR24:** All interactive elements meet minimum touch target size (48×48dp)
- **NFR25:** Color contrast ratios meet WCAG 2.1 AA (4.5:1 normal text, 3:1 large text) in light and dark mode
- **NFR26:** Full semantic accessibility (VoiceOver/TalkBack) deferred to Growth phase

#### v2 — Authentication & Account Security
- **NFR27:** Authentication uses industry-standard secure practices — passwords hashed, OAuth/OIDC for Apple/Google, secure token storage, TLS transport
- **NFR28:** On-device personalization preserved; cloud sync opt-in, own-account-scoped, backup/social only; never centralized training; biometric data not required to leave device

#### v2 — Privacy & Compliance (cloud)
- **NFR29:** Social sharing via defined visibility tiers (private default, friends-only, per-item); no friend-of-friend visibility; each share opt-in and revocable
- **NFR30:** GDPR for cloud data — user can export data (JSON) and delete account (FR77); deletion cascades (visible removal immediate, full purge ≤30 days)
- **NFR33:** Co-location check is momentary at session start, not stored, not continuously tracked, not exposed to others; non-blocking
- **NFR35:** Each cloud data purpose has distinct lawful basis and granular consent; user can withdraw any single consent independently; published privacy policy covers all server-side processing
- **NFR36:** Cloud data residency — EU user data stored in EU region (`[ASSUMPTION]` provider/region TBD)
- **NFR37:** Minimum account age (`[ASSUMPTION]` 16, GDPR Art. 8); confirmed at registration; co-location/friend features unavailable below minimum age

#### v2 — Real-Time & Reliability
- **NFR31:** Shared-session state stays synchronized across participants within ~1 second; participant dropout does not interrupt others
- **NFR34:** Social/cloud features degrade gracefully offline; v1 core experience remains fully offline-first

#### v2 — Store & Billing Compliance
- **NFR32:** Subscription billing complies with App Store and Play Store policies — platform IAP; Sign in with Apple offered; required privacy disclosures provided

**Total NFRs: 26 (v1) + 11 (v2, NFR27–NFR37) = 37**

---

### Additional Requirements & Constraints

**Technical Constraints:**
- Sensor noise/degradation: system must function with graceful degradation when biometric data absent
- iOS background sensor access: explicit permission handling with fallback when denied
- RPE subjectivity: rolling 3-day average smoothing; outlier detection for RPE jumps >3 points

**Architecture Constraints:**
- Flutter SDK 3.41.x, flutter_bloc, drift, freezed, get_it, go_router
- Clean Architecture / MVVM, feature-first folder structure
- Platform targets: Android API 26+, iOS 15+, Wear OS 3.0+

**Test Campaign Requirement:**
- 150–200 automated tests: domain (~60), data (~50), bloc (~40), widget (~30), integration (~20)

**Open Items (v2 assumptions flagged `[ASSUMPTION]`):**
- FR75: Exact leaderboard point formula and anti-abuse rules deferred
- FR71: WearOS as full participant vs mirror-only TBD
- NFR36: Backend provider/region TBD
- NFR37: Final minimum age value per market TBD
- v2 Pro price/tier structure TBD

### PRD Completeness Assessment

**Strengths:**
- Thorough and well-structured; v1 FRs and NFRs are clearly numbered and traceable
- All 5 user journeys mapped to capability matrix
- Safety rules layer formally specified (FR9, FR70)
- v2 addendum is explicit about conflicts with v1 and how they are resolved
- Risk mitigations documented for all major technical, market, and resource risks

**Gaps/Concerns:**
- FR51/FR52 (AI Decision Log, CSV export) are "MVP if time permits" — their epic/story coverage may be incomplete or absent
- v2 section contains several `[ASSUMPTION]` tags that are unresolved design decisions
- No explicit error-message or empty-state UX requirements in the PRD (will need to check architecture/UX docs)
- FR47 (deferred sync) and NFR18 (retry logic) are lightly specified — test coverage may be thin

---

## Step 3: Epic Coverage Validation

**Epics document status:** v1-complete (last updated 2026-06-05). Covers FRs 1–52 and NFRs 1–26 only.
**Note:** The epics document predates the PRD v2 update (2026-06-20). v2 requirements (FR53–FR77, NFR27–NFR37) have no epic or story coverage yet.

---

### FR Coverage Matrix — v1 (FR1–FR52)

| FR # | Epic Coverage | Stories | Status |
|---|---|---|---|
| FR1 | Epic 2 | 2.2 | ✅ Covered |
| FR2 | Epic 2 | 2.3 | ✅ Covered |
| FR3 | Epic 2 | 2.1 | ✅ Covered |
| FR4 | Epic 2 | 2.4 | ✅ Covered |
| FR5 | Epic 5, 7 | 5.5, 7.3 | ✅ Covered |
| FR6 | Epic 5 | 5.5 (StateVector includes HR/steps/RPE) | ✅ Covered |
| FR7 | Epic 5 | 5.5 (StateVector includes weather/AQI) | ✅ Covered |
| FR8 | Epic 5 | 5.3 (safety rule: AQI>100 → indoor) | ✅ Covered |
| FR9 | Epic 5 | 5.3 | ✅ Covered |
| FR10 | Epic 5 | 5.4 | ✅ Covered |
| FR11 | Epic 5, 7 | 7.4 | ✅ Covered |
| FR12 | Epic 5 | 2.3 + 5.5 | ✅ Covered |
| FR13 | Epic 5, 7 | 5.6, 7.2 | ✅ Covered |
| FR14 | Epic 5, 7 | 5.2, 5.6, 7.1 | ✅ Covered |
| FR15 | Epic 5, 7 | 7.1, 7.3, 7.4 | ✅ Covered |
| FR16 | Epic 7 | 7.2, 7.3 | ✅ Covered |
| FR17 | Epic 8 | 8.2 | ✅ Covered |
| FR18 | Epic 8 | 8.3 | ✅ Covered |
| FR19 | Epic 8 | 8.4 | ✅ Covered |
| FR20 | Epic 8 | 8.5 | ✅ Covered |
| FR21 | Epic 9 | 9.1 | ✅ Covered |
| FR22 | Epic 5, 9 | 5.4, 9.3 | ✅ Covered |
| FR23 | Epic 5, 9 | 5.2, 9.3 | ✅ Covered |
| FR24 | Epic 5, 9 | 5.2, 5.3 | ✅ Covered |
| FR25 | Epic 5, 9 | 5.4, 9.3 | ✅ Covered |
| FR26 | Epic 6 | 6.1, 6.2 | ✅ Covered |
| FR27 | Epic 6 | 6.3 | ✅ Covered |
| FR28 | Epic 6 | 6.1 | ✅ Covered |
| FR29 | Epic 10 | 10.1 | ✅ Covered |
| FR30 | Epic 10 | 10.2 | ✅ Covered |
| FR31 | Epic 10 | 10.3 | ✅ Covered |
| FR32 | Epic 10 | 10.2 | ✅ Covered |
| FR33 | Epic 4 | 4.1 | ✅ Covered |
| FR34 | Epic 4 | 4.1 | ✅ Covered |
| FR35 | Epic 4 | 4.1, 4.3 | ✅ Covered |
| FR36 | Epic 4 | 4.2, 4.3 | ✅ Covered |
| FR37 | Epic 1, 11 | 1.7, 11.1 | ✅ Covered |
| FR38 | Epic 11 | 11.1, 11.2 | ✅ Covered |
| FR39 | Epic 11 | 11.3 | ✅ Covered |
| FR40 | Epic 12 | 12.2 | ✅ Covered |
| FR41 | Epic 12 | 12.3 | ✅ Covered |
| FR42 | Epic 3 | 3.1 | ✅ Covered |
| FR43 | Epic 3 | 3.2 | ✅ Covered |
| FR44 | Epic 3 | 3.3 | ✅ Covered |
| FR45 | Epic 13 | 13.1 | ✅ Covered |
| FR46 | Epic 13 | 13.1 | ✅ Covered |
| FR47 | Epic 13 | 13.2 | ✅ Covered |
| FR48 | Epic 14 | 14.1 | ✅ Covered |
| FR49 | Epic 14 | 14.2 | ✅ Covered |
| FR50 | Epic 14 | 14.3 | ✅ Covered |
| FR51 | Epic 14 | 14.4 (MVP-if-time) | ✅ Covered (conditional) |
| FR52 | Epic 14 | 14.5 (MVP-if-time) | ✅ Covered (conditional) |

---

### NFR Coverage Matrix — v1 (NFR1–NFR26)

| NFR # | Epic Coverage | Status |
|---|---|---|
| NFR1 | Epic 5, 9 | ✅ Covered |
| NFR2 | Epic 1, 5, 8 | ✅ Covered |
| NFR3 | Epic 8 (Story 8.2) | ✅ Covered |
| NFR4 | Epic 8 (Story 8.3) | ✅ Covered |
| NFR5 | Epic 4 (Story 4.2) | ✅ Covered |
| NFR6 | Epic 7 (Story 5.5, 7.3) | ✅ Covered |
| NFR7 | Epic 3, 5 | ✅ Covered |
| NFR8 | Epic 4 | ✅ Covered |
| NFR9 | Epic 2, 3 | ✅ Covered |
| NFR10 | Epic 2 (Story 2.1) | ✅ Covered |
| NFR11 | Epic 14 | ✅ Covered |
| NFR12 | Epic 2 | ✅ Covered |
| NFR13 | Epic 13 | ✅ Covered |
| NFR14 | Epic 4, 6, 13 | ✅ Covered |
| NFR15 | Epic 1, 13 | ✅ Covered |
| NFR16 | Epic 1, 13 | ✅ Covered |
| NFR17 | None — intentionally accepted ("data loss on uninstall is accepted for v1") | ✅ N/A — by design |
| NFR18 | Epic 13 (Story 13.2) | ✅ Covered |
| NFR19 | Epic 4 | ✅ Covered |
| NFR20 | Epic 6 | ✅ Covered |
| NFR21 | Epic 3 | ✅ Covered |
| NFR22 | Epic 12 (Story 12.4) | ✅ Covered |
| NFR23 | Epic 4, 6, 13 | ✅ Covered |
| NFR24 | Epic 11 | ✅ Covered |
| NFR25 | Epic 11 | ✅ Covered |
| NFR26 | Epic 14 (acknowledged deferred) | ✅ Covered (deferred to Growth) |

---

### FR Coverage Matrix — v2 (FR53–FR77)

| FR # | Epic Coverage | Status |
|---|---|---|
| FR53 | **NOT FOUND** | ❌ MISSING |
| FR54 | **NOT FOUND** | ❌ MISSING |
| FR55 | **NOT FOUND** | ❌ MISSING |
| FR56 | **NOT FOUND** | ❌ MISSING |
| FR57 | **NOT FOUND** | ❌ MISSING |
| FR58 | **NOT FOUND** | ❌ MISSING |
| FR59 | **NOT FOUND** | ❌ MISSING |
| FR60 | **NOT FOUND** | ❌ MISSING |
| FR61 | **NOT FOUND** | ❌ MISSING |
| FR62 | **NOT FOUND** | ❌ MISSING |
| FR63 | **NOT FOUND** | ❌ MISSING |
| FR64 | **NOT FOUND** | ❌ MISSING |
| FR65 | **NOT FOUND** | ❌ MISSING |
| FR66 | **NOT FOUND** | ❌ MISSING |
| FR67 | **NOT FOUND** | ❌ MISSING |
| FR68 | **NOT FOUND** | ❌ MISSING |
| FR69 | **NOT FOUND** | ❌ MISSING |
| FR70 | **NOT FOUND** | ❌ MISSING |
| FR71 | **NOT FOUND** | ❌ MISSING |
| FR72 | **NOT FOUND** | ❌ MISSING |
| FR73 | **NOT FOUND** | ❌ MISSING |
| FR74 | **NOT FOUND** | ❌ MISSING |
| FR75 | **NOT FOUND** | ❌ MISSING |
| FR76 | **NOT FOUND** | ❌ MISSING |
| FR77 | **NOT FOUND** | ❌ MISSING |

### NFR Coverage Matrix — v2 (NFR27–NFR37)

| NFR # | Epic Coverage | Status |
|---|---|---|
| NFR27 | **NOT FOUND** | ❌ MISSING |
| NFR28 | **NOT FOUND** | ❌ MISSING |
| NFR29 | **NOT FOUND** | ❌ MISSING |
| NFR30 | **NOT FOUND** | ❌ MISSING |
| NFR31 | **NOT FOUND** | ❌ MISSING |
| NFR32 | **NOT FOUND** | ❌ MISSING |
| NFR33 | **NOT FOUND** | ❌ MISSING |
| NFR34 | **NOT FOUND** | ❌ MISSING |
| NFR35 | **NOT FOUND** | ❌ MISSING |
| NFR36 | **NOT FOUND** | ❌ MISSING |
| NFR37 | **NOT FOUND** | ❌ MISSING |

---

### Missing Requirements

#### Critical Missing — v2 (Expected, Not Yet Planned)

The entire v2 scope (accounts, subscriptions, social suite, co-located shared sessions, leaderboard) has no epic or story coverage in `epics.md`. This is expected because the epics document was finalized on 2026-06-05, and the v2 PRD section was added on 2026-06-20.

**FR53 — Navigation Fix (v2.0):**
- Impact: Standing UX defect — drawer secondary screens have no back path to primary tabs. PRD prioritizes this as the first v2 phase (v2.0, ship immediately).
- Recommendation: Add to next sprint as a story in the existing Epic 14 or as a micro-epic v2.0.

**FR54–FR57 — Accounts & Authentication (v2.1):**
- Impact: Foundation for all v2 social and backup features; E2E encrypted backup, Apple/Google Sign-In required for App Store.
- Recommendation: New Epic 15: Accounts & Authentication.

**FR58–FR62 — Pro Subscription (v2.2):**
- Impact: Monetization; gates Progress history (FR61 grandfathering logic is complex — must distinguish pre-v2 vs post-v2 installs).
- Recommendation: New Epic 16: Subscriptions & Paywall.

**FR63–FR67 — Social Friends (v2.3):**
- Impact: Social graph foundation; privacy-by-default + visibility tiers (NFR29) are architecturally significant.
- Recommendation: New Epic 17: Social — Friends & Progress Sharing.

**FR68–FR73 — Co-Located Shared Sessions (v2.4):**
- Impact: Headline v2 capability; requires multi-participant real-time state synchronization (FR71, NFR31) which is net-new infra (NOT inherited from phone↔WearOS bridge). High complexity.
- Recommendation: New Epic 18: Co-Located Shared Sessions (split into 18a: real-time transport, 18b: group difficulty engine).

**FR74–FR76 — Leaderboard & Scoring (v2.5):**
- Impact: Gamification layer; counter-metrics (must not push AtRisk users to over-train) require proactive monitoring.
- Recommendation: New Epic 19: Leaderboard & Scoring.

**FR77 — In-App Account Deletion (v2.1):**
- Impact: Store-blocking (App Store Guideline 5.1.1(v)); must ship simultaneously with accounts (FR54–FR57).
- Recommendation: Include in Epic 15 (Accounts & Authentication) as a non-optional story.

#### NFR Gaps — v2 (Same root cause)

NFR27–NFR37 are all v2 cloud/social NFRs. No coverage expected in current epics. Key risks:
- NFR28 (on-device AI preserved with cloud sync) — architectural constraint; must be enforced in Epic 15 design.
- NFR30 (GDPR cascading deletion) — complex; requires careful data residency and SLA design.
- NFR31 (~1 second shared-session sync) — high infra challenge; net-new relay infrastructure.
- NFR35 (granular consent per data purpose) — requires GDPR consent management layer.
- NFR36 (EU data residency) — open infrastructure decision.

---

### Coverage Statistics

**v1 Requirements:**
- Total PRD FRs (v1): 52
- FRs covered in epics: 52
- v1 FR coverage: **100%** ✅

- Total PRD NFRs (v1): 26
- NFRs covered in epics: 26 (NFR17 is intentionally "accepted behavior", not an implementation gap)
- v1 NFR coverage: **100%** ✅

**v2 Requirements:**
- Total PRD FRs (v2): 25 (FR53–FR77)
- FRs covered in epics: 0
- v2 FR coverage: **0%** ⚠️ (expected — epics predate v2 PRD)

- Total PRD NFRs (v2): 11 (NFR27–NFR37)
- NFRs covered in epics: 0
- v2 NFR coverage: **0%** ⚠️ (expected — epics predate v2 PRD)

---

## Step 4: UX Alignment Assessment

### UX Document Status

**Two UX document sets found:**
1. `ux-design-specification.md` (116K, 2026-06-05) — v1 legacy specification, complete and used as source for epics UX-DRs
2. `ux-designs/ux-Flutter_PulseCoach-2026-06-20/` — new authoritative spines (2026-06-20):
   - `DESIGN.md` — visual identity, color tokens, typography, components (18 components listed including v2)
   - `EXPERIENCE.md` — behavioral patterns, flows, IA, interaction primitives (v1 + v2)
   - `review-coverage.md` — v2 FR/NFR coverage review (self-validated)
   - `review-accessibility.md`, `review-brand-ethos.md`

**Assessment:** UX documentation is thorough and well-structured. The new 2026-06-20 spines supersede the legacy spec and extend coverage to v2.

---

### UX ↔ PRD Alignment (v1)

| Area | Status | Notes |
|---|---|---|
| Color tokens (UX-DR1 vs DESIGN.md) | ✅ Aligned | New DESIGN.md adds `accent-cardio (#F0A1B0)`, `on-primary (#06231D)`, light-mode tokens — extensions, no conflicts |
| Typography scale (UX-DR2 vs DESIGN.md) | ✅ Aligned | New DESIGN.md adds `timer-secondary (24sp Mono)` — additive, no conflict |
| Spacing tokens (UX-DR3 vs DESIGN.md) | ✅ Aligned | Identical 6-token scale |
| Shape tokens (UX-DR17 vs DESIGN.md) | ✅ Aligned | DESIGN.md adds `rounded/full` (RPE buttons, avatars) — additive |
| Animation constants (UX-DR18 vs EXPERIENCE.md) | ✅ Aligned | Same timing values |
| SessionCard variants (UX-DR5 vs DESIGN.md) | ✅ Aligned | DESIGN.md adds `CompletedSessionCard` (muted, read-only) — v1 feature not in original UX-DRs |
| Today layout rhythm (UX-DR6 vs EXPERIENCE.md) | ✅ Aligned | EXPERIENCE.md confirms: State bar → Hero → COMING UP → ring |
| InSessionView (UX-DR8 vs DESIGN.md) | ✅ Aligned | |
| RPEInput (UX-DR9 vs DESIGN.md) | ✅ Aligned | Two-row degrade at ~516dp documented in both |
| Animated charts (UX-DR19 vs EXPERIENCE.md) | ✅ Aligned | |
| Dark mode default (UX-DR20 vs DESIGN.md) | ✅ Aligned | |

**New v1 UX item not in original UX-DRs:**
- `CompletedSessionCard` — read-only, muted card staying visible in Today after session completion. Behavioral rule: excluded from focus order. Low risk; additive to the existing spec.

---

### UX ↔ PRD Alignment (v2)

The new UX spines (DESIGN.md + EXPERIENCE.md) cover all 25 v2 FRs with the following notes:

| Area | Status | Notes |
|---|---|---|
| FR53 navigation fix | ✅ Covered | EXPERIENCE.md IA: "v2 FR53: each [drawer screen] provides explicit back to the shell" |
| FR54–FR57 Accounts | ✅ Covered | `SignInSheet` component, Account/Privacy patterns, FR56 "optional and additive" |
| FR58–FR62 Pro subscription | ✅ Covered | `ProUpsellSheet`, Pro Gating patterns, contextual-and-silent paywall |
| FR63–FR67 Social friends | ✅ Covered | `FriendRow`, `ActivityFeedCard`, `VisibilityTierSelector`; FR67 (compare progress) partially — leaderboard is the comparison surface, no explicit head-to-head |
| FR68–FR73 Shared sessions | ✅ Covered | `SharedSessionLobby`, `JoinCodeCard`, Shared Session Patterns |
| FR74–FR76 Leaderboard | ✅ Covered | `LeaderboardRow`, Protective-State Social Suppression rules |
| FR77 In-app deletion | ✅ Covered | Account Patterns: "initiated, confirmed, cascades (NFR30)… destructive-action pattern" |
| NFR28 on-device AI preserved | ✅ Covered | EXPERIENCE.md "Brand-promise floor" |
| NFR29 visibility tiers | ✅ Covered | `VisibilityTierSelector` component, privacy-by-default |
| NFR30 GDPR export + cascade | ✅ Covered | Account Patterns |
| NFR31 ~1s sync | ✅ Covered | Shared Session Patterns |
| NFR33 co-location momentary | ✅ Covered | Account Patterns, State Patterns |
| NFR34 offline-first preserved | ✅ Covered | Foundation "Brand-promise floor" |
| NFR35 granular consent | ✅ Covered | Account Patterns |
| NFR36 EU data residency | ❌ Not covered | Correctly out of UX scope — pure backend/infra decision |
| NFR37 min age 16 | ✅ Covered | Account Patterns, Shared Session gating |

---

### New v2 UX Requirement: Protective-State Social Suppression

EXPERIENCE.md introduces a significant new behavioral requirement not explicitly stated in the PRD (but implied by counter-metrics). This must become explicit AC in the v2 social epics:

1. **Rank freeze during AtRisk/Recovering** — leaderboard rank/points frozen while user is in protective state; rest never reads as a lost position
2. **No shared-session nudges in protective states** — app never surfaces "start a shared session" invitations to AtRisk/Recovering users
3. **No social pressure on Today** — Today never shows leaderboard standing, friend comparisons, or points goals
4. **Per-day points cap** — prevents extra sessions from gaming the board; protects the ≈6.5 RPE counter-metric
5. **Reactions never feed score, never push** — light reactions are receive-only, no notifications, no pressure-inducing counts

These rules are testable (behavioral state is on-device first-class signal) and MUST be captured in v2 social epic AC.

---

### UX ↔ Architecture Alignment

| UX Requirement | Architecture Support | Status |
|---|---|---|
| Shimmer loading (UX-DR10/EXPERIENCE) | ARCH10 (`shimmer` package) | ✅ Supported |
| Dart Isolate for AI (EXPERIENCE Foundation) | ARCH7 | ✅ Supported |
| Haptic <200ms (UX-DR8/EXPERIENCE) | Direct `HapticFeedback.mediumImpact()`, never via Bloc | ✅ Supported |
| `fl_chart` animated charts (UX-DR19) | Epic 10 | ✅ Supported |
| Reduce Motion support (UX-DR13/18) | Not explicitly in ARCH specs | ⚠️ Gap — `MediaQuery.disableAnimations` not called out in architecture or epics |
| Text scale support up to 2.0× (DESIGN.md) | Not in ARCH | ⚠️ Gap — `textScaleFactor` cap not in architecture or epics |
| Light-mode contrast table (DESIGN.md `[NOTE FOR UX]`) | Not yet completed | ⚠️ Open UX action item — required before light mode ships |
| v2 Real-time session sync (NFR31) | Not in architecture (predates v2) | ❌ Gap — relay infrastructure not designed |
| v2 E2E encrypted backup (FR57/NFR28) | Not in architecture | ❌ Gap — requires key management design |
| v2 Cloud data residency (NFR36) | Not in architecture | ❌ Gap — backend provider/region TBD |

---

### Alignment Warnings Summary

| Warning | Severity | Action Needed |
|---|---|---|
| `Reduce Motion` (`MediaQuery.disableAnimations`) not in architecture or epics | MEDIUM | Add to Epic 1 or 8 story AC |
| `textScaleFactor` cap (2.0×) not in architecture or epics | MEDIUM | Add as NFR or story AC in responsive epic |
| Light-mode contrast table marked as `[NOTE FOR UX]` — incomplete | MEDIUM | Complete before light mode ships (post-exam scope) |
| FR67 (compare progress vs friends) — leaderboard is the only comparison surface | LOW | Confirm with Paolo: is leaderboard sufficient? Or need separate screen? |
| NFR36 (EU data residency) — no architecture decision | HIGH (v2) | Architecture decision needed before v2.1 backend design |
| Nav bar "Today as center of gravity" vs 4-tab layout (index 1) | INFO | Self-description tension in UX; not a blocker |
| `{Hero}` token in EXPERIENCE.md should be `{HeroSessionCard}` | INFO | Minor naming mismatch; intent clear |
| `JoinCodeCard`, `StateIndicator`, `ExplanationLine` missing from EXPERIENCE Component Patterns table | INFO | Additive cleanup pass on EXPERIENCE.md |

---

## Step 5: Epic Quality Review

Validating all 14 epics (+ 3 interstitial) against BMAD create-epics-and-stories best practices.

---

### Epic Structure Validation

#### User Value Focus

| Epic | Title | User Value? | Assessment |
|---|---|---|---|
| Epic 1 | Foundation & Project Infrastructure | ❌ Pure technical | Unavoidable for greenfield Flutter. CI/CD + schema + DI deliver developer confidence but zero user value. Acceptable as bootstrapping epic with explicit trade-off documented. |
| Epic 2 | Onboarding & Profile | ✅ | User can set up and enter the app. Direct value. |
| Epic 3 | Sensor Integration | ✅ Partial | Enables better AI recommendations; user sees RPE-only fallback explicitly. Technical delivery but user-visible outcome. |
| Epic 4 | Environmental Context | ✅ | User gets indoor/outdoor routing based on real-time weather/AQI. |
| Epic 5 | AI Engine & Daily Planning | ✅ | Core product value: user receives a calibrated daily plan with explanations. |
| Epic 6 | Exercise Catalog | ✅ | User can browse sessions; catalog is the content layer. |
| Epic 6.5 | Foundation Hardening (Interstitial) | ❌ Pure technical | Zero user-facing output. Addresses analyzer debt, dependency upgrades, catalog defense. Necessary but not user-value. |
| Epic 7 | Today Screen | ✅ | The home screen — the product's primary interface. |
| Epic 7.5 | i18n Migration (Interstitial) | ❌ Pure technical | Zero user-visible output (strings were already Italian in UX). Developer-infrastructure migration. |
| Epic 8 | In-Session Experience | ✅ | Guided execution, timer, haptic, live HR. Core ritual. |
| Epic 9 | Feedback & Adaptation Loop | ✅ | RPE input, system response, adaptation. |
| Epic 10 | Progress & History | ✅ | Charts, history, weekly goals. |
| Epic 11 | Responsive Layout & Navigation | ✅ | Tablet support, rotation. Multi-device requirement. |
| Epic 12 | WearOS Companion | ✅ | WearOS display during session. |
| Epic 13 | Offline & Data Sync | ✅ Partial | Offline guarantee is user-facing; sync queue is background. |
| Epic 14 | Settings & Extras | ✅ | Theme toggle, privacy info, AI Decision Log, export. |

**Verdict:** 3 epics (1, 6.5, 7.5) are technical epics. Epic 1 is a necessary bootstrapping epic (acceptable for greenfield). Epics 6.5 and 7.5 are interstitial technical hardening epics — these violate the "user value" rule strictly but are accepted industry practice for managing technical debt between product epics. They are explicitly labeled "Interstitial" and limited in scope (cap of 2 stories for 7.5). The pattern is consistent with BMAD's acknowledgment of technical epics when unavoidable.

---

#### Epic Independence Validation

| Epic | Can function using only prior epics? | Status |
|---|---|---|
| Epic 1 | Standalone ✅ | Foundation; no dependencies |
| Epic 2 | Needs Epic 1 only ✅ | Onboarding builds on scaffold + DB |
| Epic 3 | Needs Epic 1 ✅ | Sensor reading + DI independent of features |
| Epic 4 | Needs Epic 1 ✅ | API integration + caching independent |
| Epic 5 | Needs Epic 1 (schema, DI); uses Epic 3/4 data as nullable ✅ | StateVector fields are nullable → graceful degradation if sensors/weather not yet wired |
| Epic 6 | Needs Epic 1 ✅ | Catalog API + cache independent of AI |
| Epic 7 | Needs Epics 1, 5, 6 ✅ | Today screen requires DailyPlan + Exercise data |
| Epic 8 | Needs Epic 7 ✅ | Session execution flows from Today selection |
| Epic 9 | Needs Epics 5, 8 ✅ | RPE → bandit update requires session completion + bandit state |
| Epic 10 | Needs Epic 8, 9 ✅ | Progress data comes from session history + RPE |
| Epic 11 | Needs Epic 7 (scaffold exists) ✅ | Responsive layout wraps existing screens |
| Epic 12 | Needs Epic 8 ✅ | WearOS mirrors in-session state |
| Epic 13 | Needs Epic 1 (sync queue schema) ✅ | Offline/persistence guarantees build on DB |
| Epic 14 | Needs Epics 1, 2, 5 ✅ | Settings screens exist; AI log + export depend on data |

**Verdict:** Epic ordering is sound. No circular dependencies detected. Epics 3/4 are naturally ordered before Epic 5 (sensors/weather → StateVector) but Epic 5 handles missing data via nullable graceful degradation, making it technically independent.

---

### 🔴 Critical Violations

#### C1: Story 1.4 Creates All 9 Database Tables Upfront

**Location:** Story 1.4 (Epic 1)

**Violation:** Story 1.4 defines and creates all 9 Drift tables (`sessions`, `daily_plans`, `user_profile`, `rpe_feedback`, `bandit_state`, `behavioral_state`, `weather_cache`, `exercise_cache`, `sync_queue`) in the very first epic, before any of the features that use them are built. BMAD best practice: "each story creates tables it needs."

**Context:** This is a pragmatic decision for Drift's centralized schema model. Drift requires `AppDatabase` to declare all tables at schema creation; splitting across epics would require multiple migration versions and makes schema management complex. However, it creates a tight upfront coupling of all feature schemas.

**Impact:** Low in practice (Drift pattern), but the `session_logs` table added in Story 8.0 is inconsistent (it was added mid-project as its own migration) — confirming that the upfront schema approach is imperfect and Story 8.0 itself introduced a schema addition that wasn't in the original schema.

**Recommendation:** Accept the upfront schema approach for Drift; but document explicitly that future tables (e.g., v2 account/social tables) must be added via Drift migrations — the upfront pattern does not scale to v2.

---

### 🟠 Major Issues

#### M1: Story 1.2 Declares All Dependencies Upfront

**Location:** Story 1.2 (Epic 1)

**Issue:** `pubspec.yaml` declares all packages including `wear_plus`, `health`, `sensors_plus`, `geolocator` — packages not needed until Epics 3, 4, 12. This preloads dependencies that:
- Add build time before they're needed
- May fail resolution if platform-specific entitlements aren't set up
- Make it harder to identify which packages are required for which features

**Recommendation:** Acceptable for a project of this size; flag as a technical note. In larger projects this would be a major issue.

#### M2: FR22–FR25 Dual Coverage (Epic 5 + Epic 9) Creates Traceability Ambiguity

**Location:** FR Coverage Map — Epic 5 lists "FR22-25", Epic 9 lists "FR21-24"

**Issue:** FRs 22-24 appear in BOTH Epic 5 and Epic 9. Epic 5 builds the bandit/state machine *algorithms* (the engine); Epic 9 *triggers* them at runtime (post-session). This is architecturally sound but the overlap makes it unclear to a dev implementing Epic 9 whether FR22-24 are "done" from Epic 5 or if they still require Epic 9.

**Recommendation:** Add a comment in the FR Coverage Map clarifying the split: "Epic 5 = algorithm implementation; Epic 9 = runtime trigger after RPE collection."

#### M3: `BehavioralStateMachine` Still Emits Hardcoded Italian Strings (E7.5-T1)

**Location:** `lib/ai/state_machine/behavioral_state_machine.dart:35,44,53,68,81,94`

**Issue:** Deferred item E7.5-T1 — 7 `transition*` ARB keys exist in `app_it.arb` but the `BehavioralStateMachine` still emits hardcoded Italian literals. The ARB keys are dead at the consumer. This creates a maintenance risk: future string changes must be made in two places.

**Severity:** Currently LOW (strings are identical), but escalates if copy changes are needed (e.g., copy review from Paolo or translator).

**Recommendation:** Promote E7.5-T1 to a scheduled story (target Epic 9.x per prior decision) before any string changes are made. The trigger condition is "3+ features consuming state-machine messages directly" — currently not yet met.

#### M4: Epic 8 Sprint Binding Dependencies Are Informal

**Location:** Epic 8 Goal section preamble

**Issue:** Epic 8 contains an inline "Sprint binding" note with three prerequisites:
1. Story 8.0 must merge before Story 8.1
2. `vibration` package must be added before Story 8.3
3. Epic 7.5 must complete before Epic 8 kicks off

These are real sequencing constraints documented in prose rather than as formal story pre-requisites or epic entry criteria. This is informal and could be missed by a developer picking up Story 8.1 without reading the preamble.

**Recommendation:** Convert these to formal `prerequisites` sections in the affected stories, or to an Epic 8 Definition of Ready checklist.

---

### 🟡 Minor Concerns

#### MN1: Story 7.1b Added as Afterthought

**Context:** Story 7.1b ("missedSessions Decay & Reset") was added after the original Story 7.1 shipped. It covers the state machine's `missedSessions` counter reset path that wasn't fully specified in Story 5.2 or 7.1.

**Impact:** Low — the story is now complete and shipped. But it signals that Story 5.2 (Behavioral State Machine) may have had underspecified edge cases, specifically the reset path when a user returns after absence.

#### MN2: "COMING UP" Translation Discrepancy

**Context:** Story 7.5.2 AC says: "proposed: `'PROSSIME'` — Sally to confirm during this story's spec review". CLAUDE.md states this shipped as "PROSSIME". The epics.md has not been updated to remove the "Sally to confirm" provisional note.

**Impact:** Documentation staleness; not a functional issue.

#### MN3: Interstitial Epics Not in Numbered Epic Sequence

**Context:** Epic 6.5 and Epic 7.5 sit in the epic list but are not in the numbered main sequence. This can cause confusion about the total epic count and the build sequence.

**Impact:** Cosmetic/process; no functional impact.

#### MN4: Story 10.0 is Technically-Focused

**Location:** Epic 10

**Issue:** Story 10.0 ("Centralized Logger & Error-Path Convergence") is a technical story within a user-value epic. It delivers no user-visible output. It was likely added during retro to address technical debt.

**Recommendation:** Accept (same pattern as 7.0, 8.0); flag as technical story within a feature epic.

---

### Acceptance Criteria Quality Assessment

**Overall quality: HIGH.** All 14 epics use proper Given/When/Then BDD format. Key observations:

| Criterion | Assessment |
|---|---|
| Given/When/Then format | ✅ Consistent throughout all 50+ stories |
| Testable outcomes | ✅ Most ACs cite specific values (pixel sizes, timing, file names) |
| Error conditions covered | ✅ Good — almost all stories include degradation/failure paths |
| FR/NFR traceability | ✅ AC lines cite FR/NFR numbers consistently |
| Measurable outcomes | ✅ Excellent — NFR1 (< 30s), NFR3 (±1s), NFR4 (200ms) all appear in AC text |

**Notable gaps in ACs:**
- Story 7.1b: AC for `atRisk → recovering` decay (return after 1 day in AtRisk) not explicitly stated; only the forward `active → atRisk` path is specified.
- Story 3.1 has no AC for the Android Health Connect permission flow specifically (only HealthKit mentioned by name in AC text).
- Story 11.3 (Portrait & Landscape) is broad — AC says "no data loss, no overflow, no broken layouts" but doesn't enumerate which specific screens are tested. Given the intent is "all key screens," a list would strengthen the AC.

---

### Best Practices Compliance Summary

| Epic | User Value | Independence | Story Sizing | No Forward Deps | Schema Timing | Clear ACs | FR Traceability |
|---|---|---|---|---|---|---|---|
| Epic 1 | ⚠️ Technical | ✅ | ✅ | ✅ | ❌ Upfront all | ✅ | N/A |
| Epic 2 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 3 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 4 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 5 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 6 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 6.5 | ⚠️ Technical | ✅ | ✅ | ✅ | N/A | ✅ | N/A |
| Epic 7 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 7.5 | ⚠️ Technical | ✅ | ✅ | ✅ | N/A | ✅ | N/A |
| Epic 8 | ✅ | ✅ | ✅ | ⚠️ Informal deps | ⚠️ Story 8.0 adds schema | ✅ | ✅ |
| Epic 9 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 10 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 11 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 12 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 13 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Epic 14 | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |

---

## Step 6: Final Assessment

**Report generated:** `_bmad-output/planning-artifacts/implementation-readiness-report-2026-06-20.md`
**Assessment date:** 2026-06-20
**Assessor:** BMad Implementation Readiness Skill

---

### Overall Readiness Status

## ✅ READY FOR v1 IMPLEMENTATION — ⚠️ v2 REQUIRES EPIC PLANNING

**v1 (on-device AI, offline-first mobile app):** Implementation-ready. All 52 FRs and 26 NFRs have full epic and story coverage. ACs are specific, measurable, and in BDD format. No blocking gaps.

**v2 (accounts, Pro, social, shared sessions):** NOT ready for implementation. 25 FRs and 11 NFRs have zero epic or story coverage. The PRD v2 section (added 2026-06-20) has not yet been decomposed into epics. A new epic planning session is required before v2 implementation can begin.

---

### Critical Issues Requiring Immediate Action

**For v1 implementation (if not yet started):**
- None. v1 is ready to implement following the existing 14 epics in order.

**For v2 planning (before v2 implementation begins):**

1. **FR53 (Navigation Fix)** — Drawer back-path defect. PRD prioritizes this as v2.0 (ship immediately). Assign to existing Epic 14 or create micro-epic. 1–2 story effort.

2. **FR77 (In-App Account Deletion)** — Store-blocking (Apple App Store Guideline 5.1.1(v)). MUST ship simultaneously with accounts (v2.1). Zero tolerance; App Store rejection risk.

3. **NFR36 (EU Data Residency)** — Architecture decision required before backend design for v2.1. Provider + region selection blocks v2.1 backend kickoff.

4. **E7.5-T1 (Dead ARB Keys)** — `BehavioralStateMachine` emits hardcoded Italian strings; 7 ARB keys are unused. Currently LOW severity but escalates if any copy change is needed. Schedule as a story in Epic 9.x before any i18n changes.

5. **Protective-State Social Suppression** — The 5-rule behavioral guardrail defined in EXPERIENCE.md (rank freeze during AtRisk/Recovering, per-day points cap, etc.) must be captured as explicit AC in v2 social epics. Currently UX-only; no PRD or epic formal requirement.

---

### Recommended Next Steps

**Immediate (pre-implementation checks for v1):**

1. **Confirm FR67 surface decision:** Is the leaderboard the only "compare progress vs friends" surface? Or should a dedicated comparison screen exist? (Noted in UX review as FR67 partial coverage.)

2. **Add Reduce Motion + textScaleFactor cap to epics:** These accessibility requirements are in the UX spec (DESIGN.md) but not in any epic AC. Add to Epic 11 (Responsive Layout) or Epic 8 (In-Session) ACs before those epics are implemented.

3. **Verify Android Health Connect AC in Story 3.1:** The current AC mentions HealthKit by name but not Health Connect explicitly. Confirm the Android permission flow is tested.

**For v2 planning (new epic creation session needed):**

4. **Run `/bmad-create-epics-and-stories` for v2 scope:** Create Epics 15–19 covering:
   - Epic 15: Accounts & Authentication (FR54–FR57, FR77) — v2.1
   - Epic 16: Pro Subscription & Paywall (FR58–FR62) — v2.2
   - Epic 17: Social — Friends & Progress Sharing (FR63–FR67) + Protective-State Suppression — v2.3
   - Epic 18a: Real-Time Session Transport (FR71, NFR31) — v2.4a
   - Epic 18b: Co-Located Shared Sessions (FR68–FR73) + group-adapted engine — v2.4b
   - Epic 19: Leaderboard & Scoring (FR74–FR76, NFR counter-metrics) — v2.5
   - Micro-task: FR53 navigation fix — v2.0

5. **Architecture addendum for v2 backend:** Plan relay infrastructure (NFR31), key management for E2E backup (FR57/NFR28), backend provider + EU residency (NFR36), GDPR consent management layer (NFR35), account-deletion cascade (NFR30).

6. **Light mode contrast table:** Complete the `[NOTE FOR UX]` gap in DESIGN.md before v2 store launch (light-mode polish explicitly required by the DESIGN.md).

**Ongoing process:**

7. **Formalize Epic 8 sprint binding as story prerequisites:** Convert the inline "Sprint binding" prose in Epic 8 into formal story prerequisites (or Definition of Ready checklist).

8. **Update epics.md coverage map** to reflect v2 epics once created — the FR Coverage Map currently shows only FR1–FR52.

---

### Issue Summary

| Category | Critical | Major | Minor |
|---|---|---|---|
| v1 FR/NFR coverage | 0 | 0 | 0 |
| v2 FR/NFR coverage | 25 FRs + 11 NFRs missing | 0 | 0 |
| UX alignment (v1) | 0 | 2 (Reduce Motion, text scale) | 4 (naming, table gaps) |
| UX alignment (v2) | 1 (NFR36 no design) | 1 (FR67 partial) | 2 (NFR27, NFR32 partial) |
| Epic quality | 1 (C1: upfront schema) | 4 (M1–M4) | 4 (MN1–MN4) |
| **TOTAL** | **27** | **7** | **10** |

**All 27 "critical" items are v2 coverage gaps** — expected and anticipated because the epics document was completed before the v2 PRD section was written. No critical blockers exist for v1 implementation.

---

### Final Note

This assessment identified **44 issues** across **5 categories**. The v1 planning is in excellent shape: 100% FR and NFR coverage, high-quality BDD acceptance criteria, proper epic ordering, and a clean UX-to-architecture alignment. The primary finding is that **v2 requires a dedicated epic planning session** before implementation can begin. The seven major issues (M1–M4, UX medium warnings) are correctable with targeted story AC additions and one sprint-planning housekeeping task. None are implementation blockers for v1.


