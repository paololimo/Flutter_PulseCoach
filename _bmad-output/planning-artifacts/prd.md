---
stepsCompleted:
  - "step-01-init"
  - "step-02-discovery"
  - "step-02b-vision"
  - "step-02c-executive-summary"
  - "step-03-success"
  - "step-04-journeys"
  - "step-05-domain"
  - "step-06-innovation"
  - "step-07-project-type"
  - "step-08-scoping"
  - "step-09-functional"
  - "step-10-nonfunctional"
  - "step-11-polish"
  - "step-12-complete"
inputDocuments:
  - "_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach.md"
  - "_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach-distillate.md"
  - "docs/REQUIREMENTS.md"
  - "docs/FLUTTER.md"
documentCounts:
  briefs: 2
  research: 0
  brainstorming: 0
  projectDocs: 2
classification:
  projectType: "mobile_app"
  domain: "health_fitness_mhealth"
  complexity: "high"
  projectContext: "greenfield"
workflowType: 'prd'
status: "v2-final"
updated: "2026-07-06"
v2Update:
  date: "2026-06-20"
  signal: "v2 features: navigation fix, accounts + subscriptions, Strava-like social with co-located live shared sessions and friends leaderboard"
  decisionLog: "_bmad-output/planning-artifacts/.decision-log.md"
  addendum: "_bmad-output/planning-artifacts/addendum.md"
v1PolishUpdate:
  date: "2026-07-06"
  signal: "v1 Experience Polish: in-session progress milestones + finish flag, ongoing session notification (pause + auto-abandon), Today active-days indicator, decision-factor iconography"
  requirements: "FR78-FR82, NFR38-NFR39"
  decisionLog: "_bmad-output/planning-artifacts/.decision-log.md"
  addendum: "_bmad-output/planning-artifacts/addendum.md"
---

# Product Requirements Document - Flutter_PulseCoach

**Author:** Paolo
**Date:** 2026-03-26

## Executive Summary

PulseCoach is a Flutter-based cross-platform fitness app (Android, iOS/iPadOS, WearOS) that generates personalized micro-workout sessions — 2 to 10 minutes — adapted in real time to the user's physiological state, behavioral history, and environmental conditions. The app targets the moment *before* the decision to exercise: when the user doesn't yet know if they have the energy, time, or motivation. Open the app, receive a calibrated plan in under 30 seconds, one tap to start.

The core intelligence runs entirely on-device: a contextual multi-armed bandit learns which session types produce the best outcomes for each user, a behavioral state machine (Active → Fatigued → AtRisk → Recovering) governs recommendation policy, and a feedback control loop adjusts intensity based on post-session RPE targeting ≈6.5. External context — real-time weather and air quality via Open-Meteo, exercise catalog via ExerciseDB — actively shapes every session. No health data leaves the device for personalization. No internet connection required to train.

The primary audience is students and remote/hybrid workers whose schedules are fragmented and unpredictable — people who keep trying to be active and keep losing to friction. The secondary audience is wearable users who want their biometric data to drive actual coaching, not just dashboards.

PulseCoach is developed as an academic project for the PoliMi DIMA exam (2025/2026), designed to demonstrate maximum coverage across all 8 evaluation criteria: novelty, complexity, external services, look and feel, multi-device support, test campaign, design document, and presentation quality.

## What Makes This Special

**Explainability as a trust mechanism.** Every recommendation surfaces a structured reason: *"Intensity reduced: high RPE yesterday + elevated resting HR + short recovery window."* The differentiation moment is when the user reads the explanation and recognizes it as accurate — the system demonstrates it has genuinely observed them. This transforms an algorithmic suggestion into a trust relationship.

**Three simultaneous convergences create the window.** The science validates exercise snacks (ACSM top-10 trend 2024, multiple peer-reviewed studies). Consumer devices now carry sufficient biometric sensors for on-device contextual AI. Privacy has become an active product selection criterion for the 18-35 demographic. Three years ago the sensors weren't ready. Three years from now the market will be occupied.

**Unexplored competitive territory.** No major fitness app combines: true micro-sessions (2-10 min) + on-device adaptive AI + in-session RPE feedback loop + weather-aware routing + air quality integration. The AQI angle alone — automatically gating outdoor exercise based on real-time air quality — is genuinely novel in the fitness app space.

**Value proposition:** *"The only app that decides for you — and explains why."*

## Project Classification

- **Project Type:** Cross-platform mobile app (Flutter/Dart) with WearOS companion
- **Domain:** Health & Fitness / mHealth — adaptive micro-workout delivery with on-device AI
- **Complexity:** High — on-device contextual bandit + behavioral state machine + RPE feedback control, multithreading via Dart Isolates, dual distinct layouts (phone/tablet) with rotation support, WearOS companion, two external APIs actively influencing AI decisions, 150-200 test campaign
- **Project Context:** Greenfield — new product built from scratch

## Success Criteria

### User Success

- **Zero-friction activation:** User opens the app and receives a calibrated 3-session daily plan in under 30 seconds. One tap to start any session.
- **Explainability trust moment:** After completing the first session, the user reads a structured explanation of why the system chose that specific session — and recognizes it as accurate. This is the primary retention trigger.
- **Empathetic state awareness:** When the behavioral state machine transitions to Recovering or Fatigued, the user sees an explicit human-readable message (e.g., *"We're giving you space to recover — light session today."*). The moment the app acknowledges fatigue before the user does is the second, deeper trust moment.
- **Retention:** ≥3 sessions/week at day 30 for active users.
- **Completion rate:** ≥75% of started sessions completed.
- **RPE perception:** Users perceive session difficulty as appropriately calibrated — not too easy, not too hard — within the first two weeks.

### Business Success

- **Primary (academic):** Maximum grade on the PoliMi DIMA exam (2025/2026). Full coverage of all 8 evaluation criteria: novelty, complexity, external services, look and feel, multi-device support, test campaign, design document, presentation quality.
- **Secondary (post-exam):** Production-quality codebase suitable for App Store publication and portfolio presentation. Code quality, architecture, and documentation must meet professional standards from day one — not retrofitted after the exam.
- **Demo impact:** Live demo on real device + tablet convincingly demonstrates AI adaptation over time using 2-week pre-seeded data. The professor sees a mature system, not a cold start.

### Technical Success

- **AI convergence:** Rolling RPE converges toward target (6.5) ±1.0 within 10 sessions for new users. Documented and verified in Design Document.
- **State machine determinism:** Every state transition (Active → Fatigued, Fatigued → AtRisk, AtRisk → Recovering, Recovering → Active) is deterministic, rule-based, and covered by a dedicated unit test. Zero ambiguous transitions.
- **Test campaign:** 150-200 automated tests organized across five layers: domain (~60), data (~50), bloc/cubit (~40), widget (~30), integration (~20).
- **Multithreading:** AI computation runs on Dart Isolates, isolated from UI thread. Network and DB operations are async. Threading model documented in Design Document.
- **Offline-first:** App fully functional without internet connection. API data cached with TTL. Deferred sync via event queue.
- **Dual layout:** Phone and tablet layouts are visually and functionally distinct — not scaled versions of each other. All key screens handle portrait and landscape rotation.

### Measurable Outcomes

| Metric | Target | Measurement Method |
|---|---|---|
| Session plan generation time | < 30 seconds from app open | Instrumented timing |
| RPE convergence | ±1.0 of target within 10 sessions | Rolling average analysis |
| Session completion rate | ≥ 75% | Completed / Started ratio |
| State machine transition coverage | 100% of transitions unit-tested | Test suite verification |
| Test count | 150-200 tests | `flutter test` count |
| Offline functionality | All core features work without network | Manual + integration tests |

## Product Scope & Development Strategy

### MVP Strategy & Philosophy

**MVP Approach:** Experience MVP — the minimum product that delivers the core "zero-decision, AI-explained" experience across all required evaluation criteria. Every MVP feature must either (a) directly satisfy a DIMA evaluation criterion or (b) be essential for the AI adaptation loop to function.

**Resource Requirements:** Team of 2-3 Flutter developers with Dart proficiency. One team member should own the AI engine (bandit + state machine + safety rules), one should own the UI layer (phone + tablet + responsive), and one should own integration (WearOS + APIs + sensors). Overlapping ownership expected given small team size.

**Core User Journeys Supported:**
- J1 (Marco — Student): Full success path with AI adaptation, weather/AQI, WearOS
- J2 (Elena — Remote Worker): Pattern learning, breathing sessions, step count integration
- J3 (Luca — Onboarding): Animated onboarding, cold-start bandit, first session
- J4 (Marco Redux — Bad Week): State machine transitions, empathetic messaging, graceful re-engagement

### MVP — Minimum Viable Product

**Core functionality:**
- AI-generated daily plan (3 micro-sessions, 2-10 min each) with contextual bandit + behavioral state machine + RPE feedback control
- Guided session view (full-screen timer, current step, HR, haptic feedback on step transitions)
- Post-session RPE feedback (1-10) feeding back into the adaptive engine
- Explainability layer: structured reason string on every recommendation
- Empathetic state messaging: human-readable state transition notifications
- History and progress tracking (timeline, weekly goals, RPE trend charts)

**Multi-device:**
- Phone layout: bottom tab navigation (Today, Sessions, Progress), drawer (Profile, Settings, Privacy, Debug)
- Tablet layout: side NavigationRail, master-detail Today screen, dashboard grid Progress, grid Sessions, split-view in-session
- Screen rotation: portrait and landscape on all key screens
- WearOS companion: session display (timer, step, HR), post-session summary

**External services:**
- Open-Meteo: weather + AQI → indoor/outdoor decision + health risk flags (city-level location, not precise GPS)
- ExerciseDB: exercise catalog (names, muscles, instructions) → session content population

**Technical infrastructure:**
- On-device AI on Dart Isolates (no cloud dependency for personalization)
- Offline-first: local DB, TTL-cached API data, deferred sync via event queue
- Clean Architecture / MVVM with feature-first folder structure

**Look & feel (grade-critical):**
- Animated onboarding flow (3-4 screens: concept → profile → goals)
- Dark mode with `ThemeMode.system` support
- Custom ThemeData (colors, typography, shape, elevation) — no raw Material defaults
- Lottie animations for session type icons (breathing, stretching, running cycle)
- Animated charts (`fl_chart`) with smooth transitions on progress screens

**Test campaign:**
- 150-200 tests in `test/` organized by layer

**Documentation:**
- Design/Test Document (PDF): architecture, AI formalization, state machine diagram, responsive strategy, threading model, test campaign

**Must-Have Capabilities (Non-Negotiable):**

| Capability | Evaluation Criterion | Sacrificable? |
|---|---|---|
| On-device AI (bandit + state machine + RPE loop) | Complexity, Novelty | Never |
| Dual layout phone + tablet (visually distinct) | Multi-device | Never |
| Screen rotation (portrait + landscape) | Multi-device | Never |
| WearOS companion | Multi-device | Never |
| Open-Meteo + ExerciseDB integration | External services | Never |
| 150-200 test campaign | Test campaign | Never |
| Dark mode + custom ThemeData | Look & feel | Never |
| Design/Test Document (PDF) | Documentation | Never |
| Medical disclaimer (non-skippable) | Domain safety | Never |
| Safety rules layer with deterministic overrides | Domain safety | Never |

**MVP Look & Feel (Grade-Critical):**

| Feature | Priority | Fallback if Time-Constrained |
|---|---|---|
| Custom ThemeData + Material 3 | Must-have | — |
| Dark mode (`ThemeMode.system`) | Must-have | — |
| Animated charts (`fl_chart`) | Must-have | — |
| Lottie animations (session type icons) | Should-have | Flutter native `AnimatedContainer` / `Hero` animations |
| Animated onboarding (3-4 screens) | Should-have | Static onboarding with same content, no animation |

### MVP If Time Permits

- **AI Decision Log (debug view):** Hidden screen showing bandit decision history (state vector → action → reward → updated estimates). High demo impact — proves the system learns.
- **CSV/JSON export:** Session history + AI decisions export. Proves adaptation happened with raw data.

### Contingency Sacrifice Order

If time pressure forces scope reduction, sacrifice in this exact order:

1. **First:** Lottie animations → replace with Flutter native animations
2. **Second:** Animated onboarding → replace with functional static onboarding
3. **Third:** AI Decision Log + CSV export (already classified as "MVP if time permits")
4. **Never sacrifice:** WearOS, tablet layout, rotation, 2 external APIs, test campaign, dark mode, custom look & feel

### Implementation Order

| Phase | Focus | Parallel Track |
|---|---|---|
| Phase 1a | AI engine + domain layer + unit tests (~60 tests) | **WearOS spike** (validate `wear_plus` feasibility) |
| Phase 1b | UI phone: Today, Sessions, Progress, Drawer, In-Session | Health API spike (real iOS device) |
| Phase 1c | Tablet layout: NavigationRail, master-detail, dashboard grid | — |
| Phase 1d | WearOS companion (informed by spike results) | — |
| Phase 1e | Look & feel polish: onboarding, dark mode, Lottie, fl_chart animations | — |
| Phase 1f | Test campaign completion (remaining ~140 tests) + Design Document | — |

### Risk Mitigation Strategy

**Technical Risks:**

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `wear_plus` insufficient for WearOS communication | Medium | High | Early spike in Phase 1a; fallback to minimal Kotlin native module |
| HealthKit requires real iOS device (no simulator testing) | Confirmed | Medium | Schedule real-device testing sessions; RPE-only fallback path covers functionality |
| AI bandit convergence too slow | Low | Medium | Conservative epsilon schedule; fall back to rule-based if no convergence in 15 sessions |
| `drift` reactive queries performance on large history | Low | Low | PulseCoach data volume is small (3 sessions/day × 365 = ~1100 records/year) |

**Market Risks:**

| Risk | Mitigation |
|---|---|
| Exercise snack paradigm not resonating with users | Academic context — user adoption is a post-exam concern; demo data pre-seeded for compelling presentation |
| Explainability messages feel robotic | Template library with human-reviewed variants; iterate during test campaign |

**Resource Risks:**

| Risk | Mitigation |
|---|---|
| Third team member not confirmed | Design architecture and code for 2-person team; third member accelerates but is not blocking |
| Time pressure near exam deadline | Contingency sacrifice order defined above; core evaluation criteria protected |

### Growth Features (Post-MVP)

- Accessibility (semantic labels, VoiceOver/TalkBack)
- Home screen widget (`home_widget`)
- Push notification reminders
- watchOS (Apple Watch) companion
- App Store publication + privacy policy

### Vision (Future)

- Federated learning for improved bandit initialization from aggregate patterns — without centralizing individual health data
- Deeper health ecosystem integration (Apple Health, Google Fit sync)
- Cognitive wellness positioning: breathing and mobility sessions as productivity interventions ("3-minute reset between meetings")
- Privacy-first context-aware intelligence layer for daily movement and recovery — physical and cognitive

## User Journeys

### Journey 1: Marco — The Overwhelmed Student (Primary, Success Path)

**Persona:** Marco, 22, engineering student at PoliMi. Sleeps irregularly, eats when he remembers, genuinely wants to be more active. Has downloaded and abandoned Nike Training Club, Freeletics, and a yoga app in the past year. Not because he's lazy — because a 30-minute workout doesn't fit between a 9am lecture and an 11am lab.

**Opening Scene:** Tuesday, 7:45am. Marco's alarm went off late. He slept five hours. It's raining outside, and the AQI in Milan is 85 (moderate). He picks up his phone while still in bed, half-awake, and opens PulseCoach out of habit — he set it up two days ago.

**Rising Action:** The app loads his Today screen instantly. Three sessions are already waiting:
- *"5 min mobility — indoor, low intensity"*
- *"3 min breathing reset — indoor, minimal effort"*
- *"4 min light cardio — indoor, moderate intensity"*

Below the first session, a single line: *"Intensity reduced: short sleep detected + elevated resting HR (78 bpm vs your baseline 65)."* Marco reads it. He didn't tell the app he slept badly — it figured it out from his heart rate. He taps "Start" on the mobility session.

**Climax:** Five minutes later, he's done. Hip circles, thoracic rotation, shoulder rolls — each step appeared on screen with a timer, and his WearOS watch buzzed at each transition. The post-session screen asks: "How did that feel? (1-10)." He taps 5. The app responds: *"Got it. Tomorrow's plan will reflect this."*

He realizes: this is the first fitness app that asked him how he *actually felt* — and promised to use the answer.

**Resolution:** By day 10, Marco has completed 22 sessions. He hasn't thought about "working out" once. He just opens the app when he has a gap, does what it says, and moves on. His RPE average has stabilized around 6. The system knows he prefers mobility in the morning and breathing exercises between study sessions. He hasn't made a single fitness decision in ten days — and he's more active than he's been in months.

**Capabilities revealed:** Daily plan generation, RPE feedback loop, sensor integration (HR, sleep inference), weather/AQI integration, WearOS companion, explainability display, session timer with step transitions.

---

### Journey 2: Elena — The Remote Worker Between Meetings (Primary, Alternative Goal)

**Persona:** Elena, 29, UX designer working remotely from her apartment in Turin. Back-to-back video calls from 9am to 1pm, then focused work until 6pm. Her step count averages 2,100/day. She knows it's bad. She bought a fitness tracker six months ago. It tells her she's sedentary. It doesn't tell her what to do about it.

**Opening Scene:** Thursday, 2:55pm. Elena just finished a draining stakeholder review. Her next meeting is at 3:30pm. She has 30 minutes but zero energy for anything that feels like "exercise." She opens PulseCoach.

**Rising Action:** The Today screen shows her afternoon session: *"3 min breathing reset — your step count is low (1,800) and your last session was yesterday morning."* The explanation continues: *"State: Active → recommendation policy favoring recovery-adjacent sessions in the afternoon based on your pattern."*

Elena doesn't fully understand the state machine terminology, but she understands the message: the app noticed she's been sitting all day and is offering something gentle. She taps Start.

**Climax:** Three minutes of guided box breathing. Inhale 4 seconds, hold 4, exhale 4, hold 4. Her watch shows her heart rate dropping from 82 to 68 during the session. When it ends, she rates it a 4 (easy). The app notes: *"Adjusting — your afternoon sessions may increase slightly in intensity next week."*

She doesn't feel like she "worked out." She feels like she *reset*. The distinction matters.

**Resolution:** After three weeks, Elena's daily pattern has emerged: a 5-minute mobility session before her first call, a breathing reset in the afternoon slump, and a 7-minute light cardio in the evening. Her average daily step count has risen to 4,200 — not from the sessions themselves, but because the micro-movements break the inertia of sitting. The app adapted to her rhythm without her configuring anything. She tells a colleague: "It's like having a coach who watched you for a month before saying anything."

**Capabilities revealed:** Low-activity detection (step count integration), pattern learning (time-of-day preferences), breathing session delivery, afternoon-specific recommendations, gradual intensity progression, WearOS HR display during session.

---

### Journey 3: Luca — The New User Onboarding (First Contact)

**Persona:** Luca, 25, PhD student, heard about PulseCoach from Marco. Skeptical of fitness apps — he's tried three and deleted all of them within a week. Downloads PulseCoach expecting to be disappointed.

**Opening Scene:** Luca opens the app for the first time. Instead of a login wall or a 15-field profile form, he sees an animated onboarding flow — three screens with Lottie animations:
1. *"Move more. Decide less."* — animation of a phone generating a session plan
2. *"Your data stays yours."* — animation of a phone with a shield icon
3. *"Let's set you up in 60 seconds."*

**Rising Action:** The profile screen asks four things:
- Fitness level: Beginner / Intermediate (he picks Beginner)
- Primary goal: Cardio / Strength / Mobility / Well-being (he picks Well-being)
- Available time per session: 2-5 min / 5-10 min (he picks 2-5 min)
- Any constraints: None / Knee issues / Back issues / Prefer indoor (he picks None)

No email. No password. No credit card. Setup complete in 40 seconds.

**Climax:** The Today screen appears immediately with his first plan — three conservative sessions calibrated to a beginner profile. The first session is a 3-minute gentle mobility routine. Below it: *"Starting conservative — I'll learn your preferences as we go."*

Luca expected to be sold something. Instead, the app gave him a plan and explained its reasoning. He starts the session.

**Resolution:** Luca completes his first session in his kitchen. It took 3 minutes. The RPE prompt appears — he taps 3 (easy). The app responds: *"Noted. I'll increase variety tomorrow."* He doesn't delete the app that evening. By day 3, the sessions are already slightly more challenging and varied. The epsilon-greedy bandit is exploring. Luca doesn't know that — he just notices the app is getting better at knowing what he likes.

**Capabilities revealed:** Animated onboarding flow, minimal profile setup (4 fields), cold-start bandit initialization from profile, conservative first-day plan, immediate plan generation, RPE collection, bandit exploration phase.

---

### Journey 4: Marco Redux — The Bad Week (Edge Case / AtRisk State)

**Persona:** Marco again, now at day 25. Exam period hit. He's been stressed, sleeping 4-5 hours, skipped sessions for 3 consecutive days.

**Opening Scene:** Friday morning. Marco opens PulseCoach for the first time in 3 days. He expects the app to guilt-trip him with missed session counts or motivational quotes. Instead, the Today screen shows something different.

**Rising Action:** The state indicator shows: **Recovering** (it was AtRisk after 2 missed days, now transitioning). The daily plan has changed:
- *"3 min gentle breathing — indoor, minimal effort"*
- *"4 min light stretching — indoor, low intensity"*
- *"(Third session paused — resume when ready)"*

The explanation reads: *"You've been away for 3 days and your resting HR is elevated (82 bpm). We're giving you space to recover — light sessions only until your rhythm stabilizes."*

**Climax:** Marco does the breathing session. It takes 3 minutes. He rates it 4. No pressure, no shame, no "you missed your streak!" notification. The app treated his absence as data, not failure. The state machine moved him through AtRisk → Recovering automatically, reducing session count and intensity.

**Resolution:** Over the next 4 days, Marco completes light sessions. His resting HR drops back to 68. The state machine transitions him back to Active. Session intensity gradually increases. By day 30, he's back to his normal rhythm — and the system didn't lose his preference history from before the break. The bandit retained what it learned; only the state machine policy changed temporarily.

**Capabilities revealed:** State machine transitions (Active → AtRisk → Recovering → Active), missed session detection, empathetic messaging, intensity deload, session count reduction, resting HR monitoring, graceful re-engagement, bandit memory persistence across state changes.

---

### Journey 5: Elena — The Wearable Power User (Secondary User)

**Persona:** Elena again, now at week 6. She's become curious about *why* the app makes the decisions it does. She's a designer — she appreciates systems that show their work.

**Opening Scene:** Elena opens the drawer menu and navigates to the Progress tab on her tablet. The dashboard grid shows four charts simultaneously: minutes per week (trending up), completion rate (82%), RPE trend (stabilized around 6.2), and weekly session breakdown by type (mobility 40%, breathing 30%, cardio 30%).

**Rising Action:** She switches to the AI Decision Log (debug view). She sees a timeline of decisions:
- *Day 12: State vector [streak:5, avgRPE:6.8, hoursSinceLastSession:14, steps24h:3200, restingHR:66] → Action: breathing_reset → Reward: +1 (completed, RPE 5)*
- *Day 13: State vector [streak:6, avgRPE:6.4, hoursSinceLastSession:18, steps24h:4100, restingHR:64] → Action: moderate_cardio → Reward: +1 (completed, RPE 7)*

She can see the bandit learning. The epsilon value has dropped from 0.3 to 0.12 — exploration is decreasing as the system becomes more confident.

**Climax:** She taps "Export CSV" and downloads her complete session history + AI decision log. She opens it in a spreadsheet. Every session, every state vector, every reward signal — transparent and verifiable. She realizes she's looking at a system that doesn't just personalize — it *proves* it personalizes.

**Resolution:** Elena shares the export with Marco. "Look — it actually learned that I prefer breathing in the afternoon and mobility in the morning. It's not random." The data confirms what she felt: the app genuinely adapted to her. The explainability wasn't marketing — it was architecture.

**Capabilities revealed:** Tablet dashboard grid layout, animated charts (`fl_chart`), Progress screen with multiple simultaneous metrics, AI Decision Log (debug view), CSV/JSON export, bandit transparency (epsilon decay visible), NavigationRail tablet navigation, master-detail patterns.

---

### Journey Requirements Summary

| Capability | J1 (Marco) | J2 (Elena) | J3 (Luca) | J4 (Bad Week) | J5 (Power User) |
|---|:---:|:---:|:---:|:---:|:---:|
| Daily plan generation | ✓ | ✓ | ✓ | ✓ | |
| RPE feedback collection | ✓ | ✓ | ✓ | ✓ | |
| Explainability layer | ✓ | ✓ | ✓ | ✓ | |
| Contextual bandit (adaptive) | ✓ | ✓ | ✓ | | ✓ |
| Behavioral state machine | | | | ✓ | ✓ |
| Empathetic state messaging | | | | ✓ | |
| Weather + AQI integration | ✓ | | | | |
| Sensor integration (HR, steps) | ✓ | ✓ | | ✓ | |
| WearOS companion | ✓ | ✓ | | | |
| Animated onboarding | | | ✓ | | |
| Cold-start initialization | | | ✓ | | |
| Session timer + step display | ✓ | ✓ | ✓ | ✓ | |
| Progress charts (animated) | | | | | ✓ |
| Tablet layout (dashboard grid) | | | | | ✓ |
| AI Decision Log | | | | | ✓ |
| CSV/JSON export | | | | | ✓ |
| Offline functionality | ✓ | ✓ | ✓ | ✓ | ✓ |

## Domain-Specific Requirements

### Compliance & Privacy

- **No FDA/HIPAA obligations:** PulseCoach is not a medical device and does not process clinical data. No regulatory certification required.
- **GDPR (EU users, biometric data as sensitive data under Art. 9):** Minimal exposure — all health data stays on-device, no cloud backend, no data transmission for personalization. Explicit user consent required for Health API access (HR, step count).
- **Location privacy:** Weather/AQI calls use approximate city-level location only. No precise GPS tracking stored or transmitted.

### Safety Layer

- **Formal safety rules with deterministic overrides:** A safety rules layer sits above the contextual bandit and enforces non-negotiable limits. These overrides are deterministic, documented in the Design Document, and covered by dedicated unit tests. Examples:
  - If rolling average RPE > 8 for 2 consecutive sessions → automatic block of high-intensity sessions regardless of bandit recommendation
  - If behavioral state is AtRisk → maximum session intensity capped at "low", session count reduced to 2
  - If AQI > 100 → outdoor sessions blocked, indoor alternatives substituted
  - If resting HR > 20% above user baseline → intensity reduced automatically
- **Medical disclaimer (mandatory, non-skippable):** First-launch screen with explicit consent: *"PulseCoach is not a medical device. Consult a physician before starting any physical activity program."* Must be accepted before accessing the app. Acceptance persisted locally; cannot be bypassed, dismissed, or skipped. Displayed before onboarding.

### Technical Constraints

- **Sensor noise and degradation:** Biometric sensor data (HR, step count) can be noisy, intermittent, or absent (user without wearable). The system must function with graceful degradation — falling back to RPE-only adaptation when sensor data is unavailable.
- **iOS background sensor access:** iOS 14+ restricts background Health API access. Explicit permission handling with clear fallback behavior when permissions are denied.
- **RPE subjectivity:** RPE is self-reported and inherently subjective. The system uses rolling 3-day average smoothing rather than treating individual RPE values as ground truth. Outlier detection flags RPE jumps > 3 points between consecutive sessions.

### Risk Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| AI suggests inappropriate exercise for undisclosed medical condition | User injury, liability | Medical disclaimer + safety rules layer + conservative cold-start + intensity caps |
| Prolonged RPE feedback absence (>3 sessions) | Bandit degrades, recommendations become unreliable | Fallback to conservative policy (low intensity, high variety) until RPE data resumes |
| Sensor data unavailable (no wearable) | Reduced context for AI decisions | RPE-only mode: bandit operates on behavioral data alone, still functional |
| AQI data stale or API unreachable | Outdoor session in poor air quality | Cached AQI with TTL; if stale >2h or unavailable, default to indoor |
| User returns after extended absence | Cold-restart shock if system resumes at previous intensity | State machine handles via AtRisk → Recovering path; intensity reset while bandit memory preserved |

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. On-Device Adaptive AI Stack (Primary Innovation)**
The combination of three AI mechanisms working in concert — contextual multi-armed bandit (learning preferences) + behavioral state machine (governing policy) + RPE feedback control loop (calibrating intensity) — running entirely on-device is genuinely novel in the fitness app space. Individual components exist in research; the integration into a real-time, privacy-first mobile system does not.

**2. Explainability as Product Differentiator**
Fitness apps don't explain their recommendations. PulseCoach treats explainability not as a compliance checkbox but as the primary trust-building mechanism. The structured reason string (*"Intensity reduced: high RPE yesterday + elevated resting HR"*) is the product's signature interaction — the moment the user recognizes the system has genuinely observed them.

**3. Deterministic Safety Layer Above Stochastic AI**
A formal safety rules layer that deterministically overrides the bandit's stochastic recommendations is architecturally unusual in consumer fitness. This is a pattern borrowed from industrial control systems (safety-instrumented systems) applied to adaptive wellness — where the AI explores freely within guardrails, but the guardrails are non-negotiable and testable.

**4. Pre-Decision Targeting**
Every fitness app targets the user *after* they've decided to exercise. PulseCoach targets the moment *before* the decision — when the user doesn't know if they have energy, time, or motivation. This reframes the product from "workout tool" to "activation tool" and changes the competitive frame entirely.

**5. AQI-Aware Session Routing**
Automatically gating outdoor exercise based on real-time air quality index is genuinely novel in consumer fitness. No major app routes sessions indoor/outdoor based on AQI thresholds — this is a health-protection feature disguised as a convenience feature.

### Market Context & Competitive Landscape

- **Exercise snacks:** ACSM top-10 fitness trend 2024. Peer-reviewed evidence supports micro-bouts of activity for cardiometabolic health. No dominant app built specifically around this paradigm.
- **On-device AI in fitness:** Apple Fitness+ uses cloud-based recommendation. Freeletics uses server-side adaptation. Fitbod uses local heuristics but not bandit-based learning. PulseCoach's fully on-device adaptive stack is differentiated.
- **Explainable fitness AI:** No consumer fitness app surfaces structured reasoning for its recommendations. This is an open space.
- **AQI integration:** Running apps (Nike Run Club, Strava) show weather but don't route sessions based on air quality. PulseCoach's AQI-based indoor/outdoor gating is unoccupied territory.

### Validation Approach

| Innovation | Validation Method | Success Indicator |
|---|---|---|
| Adaptive AI stack | RPE convergence test: target ±1.0 within 10 sessions | Rolling average converges in simulated and real user data |
| Explainability | User journey testing: does the user read and recognize the explanation? | Demo observer can follow the reasoning chain without explanation |
| Safety layer | Unit test coverage: 100% of override rules tested | Every safety rule has a passing test; no bandit recommendation bypasses a safety constraint |
| Pre-decision targeting | Session start latency: < 30 seconds from app open to first tap | Instrumented timing confirms zero-decision UX |
| AQI routing | Integration test: AQI > 100 → no outdoor sessions generated | Deterministic test with mocked AQI data |

### Risk Mitigation

| Innovation Risk | Fallback |
|---|---|
| Bandit doesn't converge fast enough | Conservative epsilon schedule; fall back to rule-based recommendations if convergence not achieved in 15 sessions |
| Explainability messages feel robotic or confusing | Template library with human-reviewed message variants; A/B test message formats during test campaign |
| Safety layer too restrictive (blocks too many sessions) | Tunable thresholds documented in Design Document; threshold review during test campaign |
| AQI API unreliable | See Domain-Specific Requirements > Risk Mitigations for full fallback strategy |
| Pre-decision UX feels too opinionated ("I want to choose") | Optional "Browse sessions" mode for users who want control — but not in MVP scope |

## Mobile App Specific Requirements

### Project-Type Overview

PulseCoach is a Flutter/Dart cross-platform mobile application targeting Android, iOS/iPadOS, and WearOS from a single codebase. The app is offline-first, sensor-integrated, and runs adaptive AI computation locally. The architecture prioritizes testability, production-quality code, and clear separation of concerns for both academic evaluation and post-exam App Store publication.

### Platform Requirements

| Platform | Target | Min SDK | Notes |
|---|---|---|---|
| Android | Phone + Tablet | API 26 (Android 8.0) | Primary development platform |
| iOS | iPhone + iPad | iOS 15+ | Health API requires HealthKit entitlement |
| WearOS | Companion display | Wear OS 3.0+ | Session display only, no AI logic |

**Framework decisions (confirmed):**
- **State management:** `flutter_bloc` — structured, testable with `bloc_test`, well-documented architecture for Design Document
- **Local database:** `drift` — type-safe, reactive queries, strong integration with `flutter_bloc`
- **Navigation:** `go_router` (course-recommended)
- **Architecture:** Clean Architecture / MVVM, feature-first folder structure

### Device Permissions & Sensor Access

| Permission | Platform | Package | Usage | Fallback if Denied |
|---|---|---|---|---|
| Health data (HR, steps) | iOS (HealthKit) | `health` | Resting HR, daily step count for AI state vector | RPE-only mode |
| Health data (HR, steps) | Android (Health Connect) | `health` | Resting HR, daily step count for AI state vector | RPE-only mode |
| Motion & accelerometer | Both | `sensors_plus` | Step detection, activity classification | RPE-only mode |
| Approximate location | Both | `geolocator` | City-level location for weather/AQI API calls | Manual city selection |
| Bluetooth (WearOS) | Android | `wear_plus` | Phone ↔ watch communication | App functions without watch |

**Permission philosophy:** Graceful degradation, never persistent prompting. If the user denies any permission, the system operates with available data only. The bandit adapts its context vector to whatever inputs are present — RPE is always available as the minimum viable signal. All fallback paths documented explicitly in Design Document.

### WearOS Companion Architecture

- **Primary approach:** `wear_plus` (Flutter) for single-codebase Dart implementation
- **Fallback:** Minimal Kotlin native module for phone ↔ watch Message API if `wear_plus` proves insufficient
- **Decision point:** Early development spike to validate `wear_plus` capabilities
- **Watch scope:** Display only — current exercise step, session timer, live HR, post-session summary. Zero AI logic on watch.
- **Communication pattern:** Phone pushes session state to watch; watch sends HR data back to phone

### Offline Mode Architecture

- **Primary data source:** Local `drift` database — all core features work without network
- **API caching:** Weather/AQI and exercise catalog cached with TTL (weather: 1h, exercises: 24h)
- **Sync strategy:** Deferred sync via event queue when connectivity returns
- **Conflict resolution:** Last-write-wins (acceptable for single-user, single-device primary use)
- **AI computation:** Fully on-device via Dart Isolates — never depends on network

### Threading Model

| Operation | Execution Context | Rationale |
|---|---|---|
| AI plan generation (bandit + state machine + safety rules) | Dart `Isolate` | Heavy computation isolated from UI thread |
| RPE feedback processing + reward calculation | Dart `Isolate` | Keeps UI responsive during model update |
| Network requests (weather, AQI, exercises) | `async/await` | I/O-bound, non-blocking |
| Database read/write | `async/await` (drift reactive streams) | I/O-bound, reactive updates |
| UI rendering | Main isolate | Flutter framework requirement |

### Store Compliance

- **Pre-exam:** App store publication explicitly forbidden by course rules
- **Post-exam:** Codebase designed for production quality from day one to enable App Store submission
- **Privacy policy:** Required for both App Store and Play Store — draft during post-MVP phase
- **HealthKit / Health Connect:** Both require app review justification for health data access — plan submission narrative during post-MVP

### Implementation Considerations

- **Responsive breakpoints:** `< 600dp` = phone layout (bottom tabs), `≥ 600dp` = tablet layout (NavigationRail + master-detail). Implemented via `LayoutBuilder` / `MediaQuery`.
- **Rotation handling:** `OrientationBuilder` on all key screens. Both portrait and landscape tested for phone and tablet.
- **Theme system:** Custom `ThemeData` with `useMaterial3: true`. Dark mode via `ThemeMode.system`. No raw Material defaults.
- **Test infrastructure:** `flutter_test` (unit + widget), `bloc_test` (state management), `mockito` (remote datasource mocking), `integration_test` (end-to-end flows). Fake clock for TTL testing.

## Functional Requirements

### Onboarding & Profile

- **FR1:** New user can view an animated onboarding flow explaining the app concept, privacy approach, and setup process
- **FR2:** New user can create a profile by specifying fitness level, primary goal, available time per session, and physical constraints
- **FR3:** New user must accept a non-skippable medical disclaimer before accessing any app functionality
- **FR4:** User can view and edit their profile and goals at any time

### AI-Powered Daily Planning

- **FR5:** System generates a daily plan of 3 personalized micro-sessions (2-10 minutes each) based on the user's current state
- **FR6:** System incorporates physiological inputs (resting HR, step count, RPE history) into session selection when available
- **FR7:** System incorporates environmental inputs (weather, temperature, precipitation, AQI) into session selection
- **FR8:** System routes sessions indoor or outdoor based on real-time AQI thresholds and weather conditions
- **FR9:** System applies deterministic safety rules that override bandit recommendations (e.g., RPE avg >8 for 2 consecutive sessions → block high intensity)
- **FR10:** System adapts session type, intensity, and duration over time using a contextual bandit learning algorithm
- **FR11:** User can regenerate the daily plan on demand
- **FR12:** System initializes new users with a plan capped at intensity level ≤ Low and session count = 3, derived from their onboarding fitness level and goal

### Explainability & Trust

- **FR13:** Every session recommendation displays a structured explanation of why the system chose that specific session
- **FR14:** System displays human-readable messages when the behavioral state machine transitions (e.g., entering Recovering state)
- **FR15:** User can view their current behavioral state (Active, Fatigued, AtRisk, Recovering)

### Guided Session Execution

- **FR16:** User can start any planned session with a single tap
- **FR17:** System displays a full-screen guided session with timer, current exercise step, and step-by-step instructions
- **FR18:** System provides haptic feedback on exercise step transitions
- **FR19:** System displays live heart rate during active sessions when sensor data is available
- **FR20:** User can complete or abandon a session at any time

### Feedback & Adaptation Loop

- **FR21:** User can submit post-session RPE feedback (1-10 scale) after completing or abandoning a session
- **FR22:** System adjusts future session intensity based on RPE feedback, targeting rolling average ≈6.5
- **FR23:** System transitions behavioral state based on missed sessions, RPE trends, and streak patterns
- **FR24:** System reduces session count and intensity when user is in Recovering or AtRisk state
- **FR25:** System preserves bandit learning history across state machine transitions

### Exercise Catalog

- **FR26:** System populates session content from an external exercise catalog (ExerciseDB)
- **FR27:** User can browse available sessions filtered by type (mobility, cardio, breathing)
- **FR28:** System caches exercise catalog data locally for offline access

### Progress & History

- **FR29:** User can view session history as a timeline of completed sessions
- **FR30:** User can view progress charts: minutes per week, completion rate, RPE trend, session type breakdown
- **FR31:** User can view weekly goal progress (sessions completed vs target)
- **FR32:** Progress charts display with animated transitions

### Environmental Context

- **FR33:** System retrieves real-time weather data (temperature, precipitation) from Open-Meteo API
- **FR34:** System retrieves real-time air quality index from Open-Meteo API
- **FR35:** System uses approximate city-level location for API calls, not precise GPS coordinates
- **FR36:** System defaults to indoor sessions when AQI data is stale (>2h) or unavailable

### Multi-Device Experience

- **FR37:** Phone displays bottom tab navigation (Today, Sessions, Progress) with drawer menu
- **FR38:** Tablet displays side NavigationRail with master-detail layouts and dashboard grid
- **FR39:** All key screens support both portrait and landscape orientation
- **FR40:** WearOS companion displays current exercise step, session timer, and live HR during active sessions
- **FR41:** WearOS companion displays post-session summary

### Sensor Integration

- **FR42:** System reads resting heart rate and daily step count from device Health API when permissions granted
- **FR43:** System detects activity via accelerometer when available
- **FR44:** System operates in RPE-only mode when sensor permissions are denied, with full functionality preserved

### Offline & Data

- **FR45:** All core features (plan generation, session execution, RPE feedback, progress viewing — per NFR13) function without network connectivity
- **FR46:** System caches weather/AQI data with TTL and exercise catalog data locally
- **FR47:** System syncs data via deferred event queue when connectivity returns

### Settings & Configuration

- **FR48:** User can toggle dark mode or follow system theme
- **FR49:** User can view privacy and data information
- **FR50:** User can access device and sync settings

### MVP-If-Time Capabilities

- **FR51:** User can view an AI Decision Log showing bandit decision history (state vector → action → reward)
- **FR52:** User can export session history and AI decisions as CSV/JSON

### Experience Polish (v1)

Motivational and explanatory UI enhancements layered on the existing v1 core (in-session, Today, explainability). No new AI/domain behavior — presentation-layer polish plus one new platform capability (the ongoing session notification).

- **FR78:** The guided-session progress bar displays intermediate milestone markers at each session-step boundary and a distinct final "finish" marker (checkered flag), giving the user visible checkpoints and a clear end goal as the session advances. Reaching the final marker on completion plays a brief celebratory animation. For single-step sessions (no intermediate boundaries), only the start and finish markers are shown.
- **FR79:** When the app is backgrounded during an active session, the system posts a session notification showing the session name and paused timer. Tapping the notification returns the user to the paused session — or to Today if the session has already been auto-abandoned per FR80. The notification tolerates user dismissal without orphaning session state (dismissing it does not itself abandon the session). **Platform scope (decision, not assumption):** a live-updating, pinned/ongoing notification is an Android-only capability; iOS does not support it, so on iOS the notification is a one-shot informational post without a guaranteed live-updating timer, while the session still pauses per FR80.
- **FR80:** On backgrounding during an active session, the session timer pauses (freezes at the current time, shown in the FR79 notification). If the app is not resumed within a configurable inactivity timeout (**default 5 minutes**), the session is abandoned via the existing abandon flow (FR20) and the notification is cancelled; the abandonment is reconciled on the next app resume. Resuming before the timeout expires resumes the paused session and cancels the pending abandon. Rapid background/foreground toggling does not accumulate: each resume cancels the pending timeout and each new backgrounding restarts it.
- **FR81:** The Today tab displays a calm "active-days" indicator — the number of days **within the trailing 30-day window** (device local timezone) that have at least one completed session — presented as a gentle piece of continuity state, not a streak. The count is **windowed, not consecutive**: a rest day silently ages out of the 30-day window rather than resetting the count to zero, so there is no chain to break and no reset event. After an absence the indicator simply reads a lower value, with no "streak lost" messaging, badge, flame glyph, or reset notification. `[ASSUMPTION]` The active-days count reuses the underlying activity signal already tracked by the behavioral state machine (FR23) rather than introducing a second source of truth.
- **FR82:** Session explanations (FR13/FR14) are reinforced with animated icons/visual glyphs representing the exercise and the decision factors that drove the recommendation — exercise type, intensity, and the environmental factors already captured (temperature, precipitation, air-quality/AQI). No new environmental data is introduced (humidity explicitly excluded — decided 2026-07-06).

## Non-Functional Requirements

### Performance

- **NFR1:** Daily plan generation completes in < 30 seconds from app open, including AI computation on a background thread isolated from the UI thread
- **NFR2:** UI maintains ≥ 60fps / ≤ 16ms frame budget during AI computation — the UI thread must never block as measured by Flutter DevTools frame rendering
- **NFR3:** Session timer accuracy within ±1 second over the session duration
- **NFR4:** Haptic feedback on exercise step transitions fires within 200ms of step change
- **NFR5:** Weather/AQI API response cached and served from local DB in < 500ms when offline
- **NFR6:** App cold start to Today screen in < 3 seconds on mid-range Android device (2022+)

### Security & Privacy

- **NFR7:** All health and biometric data (HR, step count, RPE history, bandit learning state) stored exclusively on-device — zero transmission to external servers for personalization
- **NFR8:** Location data sent to Open-Meteo API is approximate city-level only — no precise GPS coordinates transmitted
- **NFR9:** Health API permissions (HealthKit / Health Connect) requested with clear user-facing explanation of usage; denial handled gracefully with RPE-only fallback
- **NFR10:** Medical disclaimer acceptance state persisted locally; app inaccessible until accepted
- **NFR11:** No user account, no email, no authentication required — profile data is local-only
- **NFR12:** GDPR Art. 9 compliance: biometric data (heart rate) classified as sensitive data; processed locally with explicit user consent, never shared

### Reliability & Data Integrity

- **NFR13:** All core features (plan generation, session execution, RPE feedback, progress viewing) function without network connectivity
- **NFR14:** API data cached with TTL: weather/AQI = 1 hour, exercise catalog = 24 hours. Stale cache served when API unreachable.
- **NFR15:** Local on-device database survives app backgrounding, force-close, and device restart without data loss
- **NFR16:** Bandit learning state and session history persist across app updates
- **NFR17:** Data loss on app uninstall/reinstall is accepted for v1 — consistent with privacy-first, no-cloud architecture. CSV/JSON export (FR52) serves as manual backup mechanism.
- **NFR18:** Deferred sync queue processes events in order when connectivity returns; failed sync retries with increasing delay intervals (capped at 1 hour)

### Integration Resilience

- **NFR19:** Open-Meteo API failure → app uses cached weather/AQI data; defaults to indoor sessions if cache stale >2 hours
- **NFR20:** ExerciseDB API failure → app uses locally cached exercise catalog; session generation continues with cached exercises
- **NFR21:** Health API unavailable or permissions denied → system operates in RPE-only mode with no degradation of core AI functionality
- **NFR22:** WearOS companion disconnection during active session → phone continues session independently; watch reconnects and resumes display when available
- **NFR23:** All external API integrations must fail fast when unreachable, serve cached data immediately, and retry automatically when connectivity returns

### Accessibility (Minimum — MVP)

- **NFR24:** All interactive elements meet minimum touch target size (48x48dp per Material Design guidelines)
- **NFR25:** Color contrast ratios meet WCAG 2.1 AA minimum (4.5:1 for normal text, 3:1 for large text) in both light and dark mode
- **NFR26:** Minimum accessibility requirements (NFR24-NFR25) met in MVP; full semantic accessibility (VoiceOver/TalkBack screen reader support) deferred to Growth phase per Product Scope

### Experience Polish (v1)

- **NFR38:** New animated elements (session milestone markers and finish animation per FR78, and decision-factor icons per FR82) honor the NFR2 60fps / ≤ 16ms frame budget and respect the OS "reduce motion" accessibility setting, degrading to static equivalents when reduced motion is enabled. The FR81 active-days indicator carries no bespoke animation beyond the standard card reveal and is therefore intentionally excluded from this list.
- **NFR39:** The session notification (FR79) exposes only non-sensitive content — session name and timer — and never biometric/HR data, consistent with NFR7. Notification permission is requested with a clear rationale on both platforms (Android 13+ `POST_NOTIFICATIONS`, iOS notification authorization); if denied, the session still pauses in-app per FR80 with no notification, preserving the NFR9 graceful-degradation posture. **Lock-screen visibility (decided 2026-07-06):** the full session name is shown on the lock screen — session names are generic exercise-category labels (mobility / cardio / breathing) with low disclosure sensitivity, and no biometric/HR data ever appears; users needing stricter privacy rely on the OS per-app lock-screen redaction setting.

---

# v2 — Accounts, Subscriptions & Social

**Added:** 2026-06-20 · **Author:** Paolo · **Status:** Draft (Fast path)

> This section extends the v1 PRD above. v1 ships and remains the **free, offline, account-free** experience. v2 layers cloud accounts, a Pro subscription, and a Strava-like social suite on top — without removing v1's on-device-personalization promise. Tags marked `[ASSUMPTION]` are inferred and need Paolo's confirmation in review.

## v2 Overview & Architectural Watershed

The defining change in v2 is that PulseCoach gains an **optional cloud backend**. v1 was deliberately local-only ("no data leaves the device"); v2 keeps that as the default free experience but adds:

1. **Optional cloud accounts** — for cross-device backup/restore and as the identity layer for social.
2. **Pro subscription** — gates the social suite and the full Progress history ("storico"). The v1 core (daily AI plan, sessions, in-session experience, AI explainability, last-session progress, weekly goal) stays free.
3. **Social suite (Strava-like)** — friends, shared progress, a friends leaderboard, and **co-located live shared sessions** whose difficulty is adapted to be safe for every participant.
4. **A navigation fix** carried over from v1 feedback: secondary drawer screens (Settings/Profile/Privacy) had no way back to the primary screens.

**Brand-promise preservation (non-negotiable).** The adaptive AI (contextual bandit + state machine + RPE loop) continues to run **on-device**. Cloud sync is **opt-in**, scoped to the user's **own** account, and used only for backup/restore and explicitly-shared social data — never centralized cross-user training. Biometric data is still not *required* to leave the device. This keeps the v1 "privacy-first" differentiator intact while enabling social.

### Reconciliation with v1 requirements (conflicts surfaced)

| v1 requirement | v2 change | Resolution |
|---|---|---|
| **NFR11** — no account, no auth, profile local-only | v2 adds optional accounts | v1 account-free, offline, local-only experience **preserved as the free tier**; account optional, required only for backup + social/Pro |
| **NFR7** — all health/biometric data on-device, zero transmission for personalization | v2 adds cloud sync + social sharing | Personalization AI stays on-device; cloud sync is opt-in, own-account-scoped, backup + explicitly-shared data only; no cross-user training |
| **NFR17** — data loss on uninstall accepted | v2 adds cloud backup | Resolved for signed-in users via backup/restore; still accepted for account-free free-tier users |
| **NFR8 / FR35** — approximate city-level location only, no precise GPS | v2 needs co-location for shared sessions | Join-code/QR pairing; GPS used only as a **soft, momentary, non-stored** proximity confirmation at session start — not continuous tracking |
| **Growth/Vision** — "App Store publication", "federated learning", "health ecosystem" | v2 realizes App Store publication + accounts | App Store publication and accounts move from Growth into v2 scope |

## v2 User Journey

### Journey 6: Marco & Giulia — The Co-Located Shared Session (Social, Primary)

**Personas:** Marco (24, our v1 student, now intermediate fitness) and his friend Giulia (61, Marco's aunt, a beginner who tires quickly and has a sensitive knee). They're both PulseCoach Pro users and friends in-app.

**Opening Scene:** Saturday, 10am, a park near home. Marco wants to do a session *with* Giulia. He opens PulseCoach, taps "Shared session", and the app shows a **join code + QR**. Giulia, standing next to him, scans it. The app confirms they're together (a quick, momentary location check — no map, no tracking) and shows both names in the lobby.

**Rising Action:** Marco's profile is intermediate; Giulia's is beginner with a knee constraint. The app does **not** pick Marco's usual moderate-cardio plan. It generates **one shared plan scaled to the whole group** — a 5-minute low-intensity mobility + breathing sequence that's safe for Giulia's knee and still worthwhile for Marco. A line explains: *"Adapted for everyone here — lowest comfortable intensity, no knee-loading movements."*

**Climax:** They tap Start together. Both phones (and Marco's watch) show the **same step and timer in real time** — when the app advances from "Hip circles" to "Box breathing", it advances on both devices at once. They finish together. Each rates their own RPE: Marco taps 4, Giulia taps 6. Each rating feeds only that person's own learning.

**Resolution:** The session lands on the **friends leaderboard** — and because it was a *shared* session, it's worth **more points** than a solo one. Giulia, who'd never have done an "advanced" workout alone, just trained with her nephew at a level that fit her. Marco got social points and a small recovery session. The next week they do it again — the shared session became the reason both of them showed up.

**Capabilities revealed:** Cloud account + friends, shared-session create/join via code/QR, momentary co-location confirmation, group-adapted difficulty (scaled to weakest + constraints), real-time synchronized session state across participants (+ watch), per-participant RPE, friends leaderboard with shared-session point bonus, Pro gating.

## v2 Functional Requirements

### Navigation Fix

- **FR53:** Every secondary screen reached from the drawer (Settings, Profile, Privacy, Debug) provides an explicit affordance to return to the primary screens (Today, Sessions, Progress) without restarting the app. *(Closes the v1 feedback that the Settings/Profile drawer had no "back" path.)*

### Accounts & Authentication

- **FR54:** User can create a cloud account using email + password, Sign in with Apple, or Google Sign-In.
- **FR55:** User can sign in, sign out, and reset a forgotten password (email flow).
- **FR56:** The app remains fully usable **without an account** — the v1 free, offline, local-only experience is preserved; an account is optional and required only to unlock backup, social, and Pro features.
- **FR57:** When signed in, the user can **opt in** to back up and restore their profile, session history, and personalization state to/from their own cloud account (e.g., on reinstall or a new device). The backup is **end-to-end encrypted with a user-held key** so that biometric-derived personalization state (bandit/RPE/HR-derived signals) is never readable server-side — preserving the NFR7/NFR12/NFR28 "biometrics do not leave the device in readable form" promise. Backup is the user's private backup, never centralized training data. *(Resolves the Art. 9 conflict raised in review — see NFR28.)*

### Subscriptions (Pro)

- **FR58:** User can view subscription plans and purchase a **Pro** subscription via the platform store billing (App Store / Play Store IAP).
- **FR59:** System gates Pro-only features behind an active subscription; the free tier retains the full v1 core (AI daily plan, sessions, in-session experience, explainability, last-session progress, weekly goal).
- **FR60:** User can restore purchases and manage or cancel the subscription via the platform store.
- **FR61:** Free tier limits Progress to the **most recent session + current weekly goal**; **Pro** unlocks the full historical timeline and all progress charts (minutes/week, completion rate, RPE trend, session-type breakdown). **Grandfathering (decided 2026-06-20):** users who installed v1 *before* v2 ship retain full Progress history for free — the Pro history gate applies only to new (post-v2) installs. The system must distinguish pre-v2 from post-v2 users to apply this.
- **FR62:** Social features (FR64–FR75) require an active Pro subscription. Setting a username/handle (FR63) and *viewing* the friends leaderboard ranking (FR76) are **free**; creating social content (friends, sharing, shared sessions, scoring participation) is Pro. *(Gating seam clarified per review.)*

### Social — Friends

- **FR63:** User can set a unique username/handle and a shareable profile. **Privacy by default:** a new profile and its activity are **private** (visible to no one) until the user explicitly opts into a visibility tier (see NFR29) — no data is public by default.
- **FR64:** User can add friends by username, by QR code / invite link, or from phone contacts (with contacts permission).
- **FR65:** User can send, accept, decline friend requests, and remove friends.
- **FR66:** User can share completed-session progress with friends and view a friends activity feed.
- **FR67:** User can compare their progress against friends'.

### Social — Co-Located Live Shared Sessions

- **FR68:** User can create a shared live session and invite co-located friends via a join code / QR.
- **FR69:** A friend joins a shared session by entering the join code / scanning the QR in person; the system uses device location as a **soft, momentary** confirmation of co-location (non-blocking — see NFR33).
- **FR70:** System generates a **single shared session plan** safe for every participant, via **deterministic group rules** layered on the engine (testable, analogous to the v1 FR9 safety layer):
  - Session **intensity ceiling = the minimum** of every participant's individual safety cap (the lowest-capped participant sets the ceiling).
  - **Fitness level = the lowest** level present in the group (e.g., a beginner + an intermediate → beginner-level plan).
  - **Movement exclusion = the union** of every participant's constraints (e.g., if any participant has a knee constraint, no knee-loading movements appear for anyone).
  - **Duration = the shortest** available-time preference among participants.
  - Each participant's own v1 safety rules (FR9) still apply individually on top of the group plan; if any v1 safety override would block the group plan, the group plan is reduced accordingly.
- **FR71:** During a shared live session, all participants see a **synchronized** session state (current step + timer) in real time. `[ASSUMPTION]` WearOS mirrors the owning participant's synchronized view.
- **FR72:** Each participant submits their **own** post-session RPE; each rating feeds only that participant's own personalization.
- **FR73:** Shared sessions require: (a) an active Pro subscription, (b) a registered account, (c) the other participants in the user's friends list, (d) location enabled for co-location confirmation, and (e) all participants meet the minimum age (see NFR37).
- **FR77:** User can **delete their account and all associated server data from within the app** (not only via a web flow), satisfying Apple App Store Guideline 5.1.1(v) and GDPR right-to-erasure. Deletion is initiated in-app, confirmed, and cascades per NFR30. *(Added per review — store-blocking gap; must ship with accounts in v2.1.)*

### Social — Leaderboard & Scoring

- **FR74:** System awards points for completed sessions and maintains a friends leaderboard.
- **FR75:** Shared (co-located) sessions award **more points** than solo sessions. `[ASSUMPTION]` Exact point formula and anti-abuse rules deferred to design (addendum).
- **FR76:** User can view the friends leaderboard ranking.

## v2 Non-Functional Requirements

### Authentication & Account Security

- **NFR27:** Authentication uses industry-standard secure practices — passwords hashed (never stored plaintext), OAuth/OIDC for Apple and Google, secure token storage on device, transport over TLS.
- **NFR28:** **On-device personalization preserved** — the adaptive AI continues to run on-device; any cloud sync of personal data is opt-in, scoped to the user's own account, used only for backup/restore and explicitly-shared social data, and never used for centralized cross-user training. Biometric data is not required to leave the device.

### Privacy & Compliance (cloud)

- **NFR29:** Social sharing is explicit and user-controlled via **defined visibility tiers** — `private` (default, no one), `friends-only`, and per-item sharing. Data is never visible friend-of-friend; the leaderboard shows only ranking + points to a user's own friends, not underlying session/biometric detail. Each share is opt-in; the user can revoke a share and the data is withdrawn from others' feeds.
- **NFR30:** GDPR for cloud data — the user can **export** their server data in a portable, machine-readable format (e.g. JSON) and **delete their account** (FR77). Deletion **cascades**: the user's profile, friendships, shared content, feed entries, and leaderboard entries are removed from the server and from other users' views within a defined SLA (target: visible removal immediate, full backend purge ≤ 30 days). v1's biometric-stays-on-device posture is retained.
- **NFR33:** Co-location confirmation uses location only **momentarily at session start** to confirm proximity; precise location is **not stored, not continuously tracked, never exposed to other users** (only a boolean "co-located" result is used), and the check is **non-blocking** (a friend can still join if the soft check is inconclusive).
- **NFR35:** Each cloud personal-data purpose (authentication, backup, social sharing, co-location check, leaderboard) has a **distinct lawful basis and granular consent**; consent is unbundled, and the user can **withdraw any single consent** independently without deleting the account. A published privacy policy / data-processing notice covers all server-side processing.
- **NFR36:** Cloud data **residency** — server-side personal data for EU users is stored in an EU region. `[ASSUMPTION]` Exact provider/region is an architecture/business decision (open item).
- **NFR37:** Accounts and the social suite have a **minimum age** (`[ASSUMPTION]` 16, aligned with GDPR Art. 8 default; configurable per market); age is confirmed at registration. Co-location and friend features are unavailable below the minimum age.

### Real-Time & Reliability

- **NFR31:** Shared-session state stays synchronized across participants within ~1 second (same bar as the existing phone↔WearOS bridge); a participant dropping out does not interrupt the others' session.
- **NFR34:** Social/cloud features degrade gracefully when offline; the v1 core experience remains fully offline-first regardless of account or subscription state.

### Store & Billing Compliance

- **NFR32:** Subscription billing complies with App Store and Play Store policies — platform IAP for the Pro subscription; Sign in with Apple offered alongside Google/email per Apple guidelines; required privacy disclosures (data collection nutrition labels) provided.

## v2 Success Metrics

| Metric | Target | Why |
|---|---|---|
| Free → Pro conversion | `[ASSUMPTION]` ≥ 3% of active free users within 60 days | Validates the freemium boundary |
| Social activation | ≥ 1 friend added by Pro users within first week of Pro | Social is the Pro value driver |
| Shared-session adoption | ≥ 1 co-located shared session per active friend-pair / month | Validates the headline v2 capability |
| Backup/restore success | ≥ 99% successful restores on reinstall (opt-in users) | Trust in the new cloud layer |

**Counter-metrics (must NOT regress — protect the v1 thesis):**
- **Empathetic-recovery integrity:** leaderboard/points pressure must not increase sessions started while in `AtRisk`/`Recovering` state, nor raise post-session RPE above the ≈6.5 target band. If gamification pushes users to overtrain, it breaks the v1 promise. Track AtRisk-state session starts and group-session RPE distribution.
- **Free-tier health:** v1 free-tier retention (≥3 sessions/week at day 30) must not drop after the Pro paywall lands.

## v2 Scope & Phasing

`[ASSUMPTION]` Suggested build order (to confirm). Each phase is independently shippable:

| Phase | Focus | Notes |
|---|---|---|
| **v2.0** | Navigation fix (FR53) | Small, ship immediately; unblocks the standing v1 UX defect |
| **v2.1** | Accounts + in-app account deletion (FR54–FR57, FR77) + E2E backup/restore + privacy policy + store readiness | Backend foundation; account deletion ships WITH accounts (store-blocking) |
| **v2.2** | Pro subscription + Progress free/Pro gating with grandfathering (FR58–FR62) | Monetization live; App Store publication |
| **v2.3** | Social graph: username, friends, shared progress, comparison (FR63–FR67) + visibility tiers (NFR29) | First social value |
| **v2.4a** | Real-time multi-participant session transport (FR71) | Net-new N-participant relay — NOT inherited from the 1:1 phone↔watch bridge |
| **v2.4b** | Group-adapted difficulty engine + co-location join (FR68–FR70, FR72, FR73) | Group-constraint rules on the engine; depends on v2.4a |
| **v2.5** | Leaderboard & scoring (FR74–FR76) | Retention/gamification layer; honor counter-metrics |

**Open items for review (non-blocking for the PRD):** backend technology choice + data residency region (architecture); exact Pro price/tier structure; point formula & anti-abuse rules; whether WearOS is a full shared-session participant or mirror-only; final minimum-age value per market.
