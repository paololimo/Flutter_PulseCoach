---
title: "Product Brief Distillate: Flutter_PulseCoach"
type: llm-distillate
source: "product-brief-Flutter_PulseCoach.md"
created: "2026-03-26"
purpose: "Token-efficient context for downstream PRD creation"
---

# PulseCoach — Brief Distillate

## Academic Context (Critical for All Decisions)

- **Course:** PoliMi DIMA (Sviluppo di Applicazioni Mobili), academic year 2025/2026
- **Team:** Paolo Limonta + Daniel + 1 CRITICAL GAP: third member not yet confirmed; course requires exactly 3 people
- **Exam format:** 10-12 min presentation (live demo on real device + tablet), in person only, official dates only
- **App store publishing:** explicitly forbidden before passing exam
- **Evaluation criteria (weighted order):** novelty of idea, complexity, external services, look & feel, multi-device, test campaign, design/test document, presentation quality
- **No monetization needed:** academic project; no business model required for v1
- **No social networks, maps, cost-splitting, business apps** — all forbidden by professor

## Technical Requirements (Hard Constraints)

- **Framework:** Flutter / Dart — cross-platform, single codebase
- **Navigation:** `go_router` (course-recommended)
- **State management:** `flutter_bloc` or `riverpod` (pick one, be consistent)
- **Two mandatory distinct layouts:** phone (`< 600dp`) and tablet (`≥ 600dp`) — must be visibly different, not just scaled
- **Screen rotation:** `OrientationBuilder` on all key screens — portrait AND landscape tested
- **Multiple threads mandatory:** Dart `Isolate`s for AI computation, `compute()` for heavy ops, async for network/DB — must be documented in Design Doc
- **At least 1 external service beyond Firebase** — PulseCoach has two: Open-Meteo + ExerciseDB
- **Test campaign:** "hundreds" of tests; target 150-200; in `test/` folder by layer

## Architecture Decisions (Confirmed)

- **Clean Architecture / MVVM** in Dart + Flutter
- **Layers:** UI (widgets/pages) → ViewModel/Cubit/Bloc → Domain (entities + use-cases) → Data (repos + local DB + remote datasources + sync manager)
- **Key use-cases:** GenerateDailyPlan, StartSession, SaveFeedback, SyncData
- **Local DB:** `drift` (type-safe, reactive) or `isar` or `sqflite` — not yet chosen
- **Offline-first:** local DB primary, deferred sync via event queue, conflict policy = last-write-wins
- **Feature-first folder structure:** today/, sessions/, progress/, settings/
- **Repository pattern + DTO ↔ Domain mapping**

## AI Engine (Detailed Spec)

- **Layer 1 — Deterministic safety rules:** progressive overload limits, deload triggers, high-RPE safeguards
- **Layer 2 — Contextual bandit:** epsilon-greedy (or UCB) algorithm
  - **State vector:** streak, avg RPE (last 3 days), time since last session, steps (24h), resting HR
  - **Reward signal:** +1 if completed, penalty if RPE too high, penalty if abandoned
  - **Target RPE:** ≈ 6.5; if rolling avg drops → increase load; if avg rises → reduce load
  - **Cold-start:** conservative prior initialized from onboarding profile (fitness level, goal, constraints); epsilon starts high for exploration
- **Behavioral state machine:**
  - States: `Active`, `Fatigued`, `AtRisk`, `Recovering`
  - Transitions: based on missed sessions, RPE trends, streak breaks
  - Each state = different recommendation policy
  - All transitions rule-based and auditable — transition thresholds NOT yet formally defined (gap for Design Doc)
- **Explainability:** every recommendation includes structured reason string (e.g., "Intensity reduced: high RPE yesterday + short recovery + elevated resting HR")
- **Runs on Dart Isolate** — AI computation isolated from UI thread

## External APIs (Both Actively Influence AI)

- **Open-Meteo:** weather (temperature, precipitation) + AQI — determines indoor/outdoor decision and surfaces health risk flags
  - **Privacy design:** uses approximate city-level location, NOT precise GPS coordinates
  - Free, no SLA — acceptable for academic; noted as dependency risk for commercial use
- **ExerciseDB / wger:** exercise catalog (names, muscles, step-by-step instructions) — populates session content
- **All external data cached locally with TTL** — offline-first architecture

## Sensor Access (Flutter Packages)

| Sensor | Package | Usage |
|---|---|---|
| Accelerometer | `sensors_plus` | Step detection, activity classification |
| Pedometer/Steps | `pedometer` | Daily step count for AI state vector |
| Heart Rate | `health` pkg (Google Fit / Apple Health) | Resting HR, in-session HR |
| GPS | `geolocator` | City-level location for weather API (NOT precise tracking) |
| Ambient light | `sensors_plus` | Indoor hint detection (optional) |

- **BLE HR monitor** (`flutter_blue_plus`) explicitly OUT of scope for v1 — Health API used instead
- **iOS limitation:** background sensor access restricted since iOS 14 — must handle gracefully

## WearOS Companion (v1 Scope)

- **Display only:** current exercise step, session timer, live HR during active session, post-session summary
- **All AI logic stays on phone** — watch is a display companion, not a decision-maker
- **Flutter WearOS support caveat:** officially supported but relatively immature; known limitations around complications and always-on display — treat as medium technical risk
- **watchOS (Apple Watch) explicitly OUT of scope for v1**

## Multi-Device UI (Required for Max Grade)

**Phone:**
- Tab 1 — Today: AI plan (3 sessions), "Regenerate" button, quick-start
- Tab 2 — Sessions: catalog with filters (mobility, cardio, breathing), offline cache
- Tab 3 — Progress: charts (min/week, completion rate, RPE trend)
- Drawer: Profile & goals, device settings, offline/sync, privacy & data, debug/export (CSV)
- In-session: full-screen timer, current step, HR, haptic feedback on step transitions

**Tablet (visually distinct, not just scaled):**
- Navigation → side NavigationRail (replaces bottom tabs)
- Today screen → master-detail (plan list + session detail side by side)
- Progress → dashboard grid (multiple charts visible simultaneously)
- Sessions → grid layout with larger cards
- In-session → split view (timer + instructions + HR side panel)

## Testing Strategy (Layer Breakdown)

Target: 150-200 tests total, organized in `test/` by feature layer

| Layer | Focus | Approx Count |
|---|---|---|
| Domain | GenerateDailyPlan, safety rules, state machine transitions, reward calc, bandit convergence | ~60 |
| Data | Repository caching/TTL, offline fallback, sync queue, conflict resolution | ~50 |
| Bloc/Cubit | State emissions on success/failure, sync pending handling | ~40 |
| Widget | Rendering, interaction, responsive layout (phone vs tablet), rotation behavior | ~30 |
| Integration | End-to-end session flow on phone + tablet | ~20 |

**Test tooling:** `flutter_test`, `mockito` (for remote datasources), fake clock for TTL, `bloc_test`, `integration_test`

## Design/Test Document (PDF Deliverable)

**Required contents (no screenshots, no user manual):**
- Software architecture (layers, patterns, data flow diagrams)
- AI model formalization (state vector, reward function, algorithm, convergence analysis)
- State machine diagram with transition rules and thresholds
- Responsive strategy (breakpoints, layout differences phone vs tablet)
- Threading model (what runs on isolates vs async)
- Test campaign (categories, coverage, methodology, results)
- **Recommended:** C4 diagrams, class diagrams, sequence diagrams, state machine diagram

## Demo Scenario (Prepared for Exam)

> "User slept little, resting HR is high, yesterday's workout was intense → system proposes mobility + breathing. Weather is bad, AQI is elevated → cardio moved indoor. After completion, feedback is 'hard' → tomorrow intensity is reduced. Switch to tablet → same data, different layout."

- **Pre-seed DB with 2 weeks of realistic data** before demo — shows AI adaptation curve, not cold start (single highest-impact demo trick)
- Demo both phone and tablet during presentation

## Presentation Structure (10-12 min Timed)

| Segment | Duration | Content |
|---|---|---|
| Problem + concept + novelty | ~2 min | "Sell" the idea |
| Architecture + AI model | ~2 min | Technical depth |
| Multi-device strategy | ~1 min | Phone + tablet + WearOS, rotation, responsive |
| Live demo | ~4 min | Demo scenario, both form factors |
| Test campaign | ~2 min | Summary + key metrics |
| Q&A buffer | ~1 min | — |

## Competitive Intelligence

- **Freeletics:** closest competitor in RPE-feedback adaptation, but cloud-based, sessions 20+ min, no env context
- **Fitbod:** best-in-class strength personalization, cloud, gym-focused, no micro-sessions
- **Nike Training Club:** minimum ~10-15 min sessions, cloud, no sensor adaptation
- **Apple Fitness+:** deep hardware integration, cloud-backed, min ~10 min, no AQI
- **Gentler Streak:** on-device health data, advisory only, no session delivery
- **Zing Coach / BetterMe:** LLM-backed (GPT-4), cloud-dependent, no env context, not micro-session

**Key competitive gaps (validated):**
- No app combines: micro-sessions + on-device AI + RPE loop + weather + AQI
- Air quality integration: zero major fitness apps gate workouts on AQI — genuinely novel
- "Zero planning UX" (open → 30 sec → session) is underserved; closest analogy is Duolingo's zero-friction lesson

## Academic Grounding (for Design Document Citations)

- **JITAI framework:** Nahum-Shani et al. (2018), Annals of Behavioral Medicine — foundational framework for PulseCoach's architecture
- **HeartSteps:** Murphy et al. (Stanford/CMU) — most cited mHealth contextual bandit study; used weather as contextual feature; validates PulseCoach's weather-aware design
- **MyBehavior:** Rabbi et al. (Columbia, UbiComp 2015) — first deployed contextual bandit for physical activity; linear UCB bandit; most directly analogous deployed system
- **Exercise snacks:** Jenkins et al. (2019), Gillen et al. (2024 BJSM meta-analysis) — validate micro-workout benefits
- **RPE auto-regulation:** Murillo-Ortiz et al. (2023) — RPE-based regulation as effective as HR-based for general population

## Out-of-Scope Items (v1 — Do Not Re-propose Without User Approval)

- BLE HR monitor external pairing — using Health API instead
- Home screen widget — deferred to post-exam
- Push notification reminders — deferred
- watchOS (Apple Watch) — WearOS only for v1
- App store publishing — course-prohibited pre-exam
- Federated learning — Vision item only, not v1

## Open Questions / Risks to Resolve

1. **CRITICAL: Third team member** — not confirmed; exam requires exactly 3 or written professor exception
2. **State machine transition thresholds** — Active→Fatigued, Fatigued→AtRisk transition rules not yet formally specified; needed for Design Document
3. **Local DB choice** — `drift` vs `isar` vs `sqflite` not yet decided
4. **Flutter WearOS maturity** — medium technical risk; worth prototyping early to validate scope feasibility
5. **iOS background sensor access** — need to verify Health API permissions flow and fallback behavior when sensor data unavailable
6. **RPE engagement rate** — no fallback explicitly designed for when user stops submitting RPE; bandit degrades to prior without acknowledgment

## Extras to Add If Time Permits (Grade Boosters, Not Required)

- Animated onboarding (3-4 screens): concept → profile → goals → optional BLE
- Dark mode + dynamic theming (`ThemeMode.system`)
- AI Decision Log (hidden debug screen showing bandit history — very impressive in demo)
- Simulated time-lapse demo (pre-seed 2 weeks data — HIGHEST impact demo trick)
- Lottie animations for session type icons
- Animated charts (`fl_chart`)
- Accessibility (semantic labels, VoiceOver/TalkBack) — rare in student projects, strong impression
- CSV/JSON export (session history + AI decisions — proves adaptation happened)
