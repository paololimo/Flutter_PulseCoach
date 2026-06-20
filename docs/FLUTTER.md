---
title: PulseCoach — Proposal & Compliance Analysis (Flutter) 
tags:
- dima
- polimi
- pulsecoach
- exam
- flutter aliases:
- PulseCoach Analysis Flutter
---

# PulseCoach — Proposal & Compliance Analysis (Flutter)

---

## Part A · Project Summary

### Concept

**PulseCoach** is a sport and well-being app for mobile (phone + tablet). It generates short, personalized daily micro-sessions (2–10 min) that adapt to the user's condition through on-device AI logic, sensor data, and contextual info (weather, exercise catalog).

**Target:** students and active people who want quick, decision-free workouts.

**Core differentiator:** the AI is not decorative — it runs on-device, learns from user behavior over time, and explains its decisions.

**Framework:** Flutter (cross-platform, Dart)

### Core Features

#### 1 · Profile & Goals

- Fitness level (beginner / intermediate), objective (cardio / strength / mobility / well-being), available time, constraints
- Preferences: silent workouts, indoor/outdoor, time slots

#### 2 · AI-Generated Daily Plan

- 3 micro-sessions per day (e.g., mobility 5 min, walk 12 min, breathing 3 min)
- Each session: duration, intensity, goal, essential instructions
- Dynamic adaptation after feedback (RPE 1–10) + sensor data (HR, steps)

#### 3 · On-Device Adaptive Intelligence

**Layer 1 — Deterministic rules:** safety constraints, progressive overload limits, deload triggers

**Layer 2 — Adaptive model:** contextual multi-armed bandit (epsilon-greedy or UCB) that learns which session types work best in a given user state

**State vector:** streak, avg RPE (last 3 days), time since last session, steps (24h), resting HR

**Reward signal:** +1 if completed, penalty if RPE too high, penalty if abandoned

**Adaptive difficulty control:** target RPE ≈ 6.5; if avg drops → increase load; if avg rises → reduce load (feedback control loop, formalizable and testable)

**Behavioral state machine:** states = `Active`, `Fatigued`, `AtRisk`, `Recovering`; transitions based on missed sessions, RPE trends, streak breaks. Each state has a different recommendation policy.

**Explainability:** every recommendation comes with a structured reason (e.g., "Intensity reduced: high RPE yesterday + short recovery + elevated resting HR")

#### 4 · Guided Session (Phone)

- Full-screen session view with timer, current step, HR (if available via wearable bridge), step counter
- Haptic feedback on step transitions
- Post-session: RPE feedback → save
- Sensor access via Flutter packages: `sensors_plus` (accelerometer), `health` or `pedometer` (steps), Bluetooth HR monitor via `flutter_blue_plus` if needed

#### 5 · History & Progress

- Timeline: completed sessions, total time, RPE trend, steps
- Weekly goals ("3 sessions" or "60 min")
- Reward-based medals tied to the adaptive model (bronze/silver/gold based on cumulative reward, not just repetition)

#### 6 · API Integration

- **Open-Meteo / Air Quality:** outdoor vs indoor decision based on weather, temperature, precipitation, air quality
- **ExerciseDB / wger:** exercise catalog (names, muscles, instructions) for varied micro-routines
- All external data cached locally with TTL

#### 7 · Offline-First Architecture

- Daily plan generated from cache + local AI rules
- History on local DB (`sqflite` / `drift` / `isar`)
- Deferred sync via event queue when connectivity returns
- Conflict policy: last-write-wins

### Architecture

**Clean Architecture / MVVM** in Dart + Flutter

|Layer|Responsibility|
|---|---|
|UI (Widgets/Pages)|Rendering + user input only|
|ViewModel / Cubit / Bloc|State management, validation, use-case orchestration|
|Domain|Entities + use-cases (GenerateDailyPlan, StartSession, SaveFeedback, SyncData)|
|Data|Repositories, local DB, remote API datasources, sync manager|

**Key patterns:** Repository pattern, DTO ↔ Domain mapping, feature-first folder structure (today, sessions, progress, settings)

**State management:** `flutter_bloc` / `riverpod` (pick one, be consistent)

**Routing:** `go_router` (as suggested by course guide)

### Mobile UI Structure — Phone

|Section|Content|
|---|---|
|Tab 1 — Today|AI plan (3 sessions), "Regenerate" button, quick-start|
|Tab 2 — Sessions|Session catalog with filters (mobility, cardio, breathing), offline cache|
|Tab 3 — Progress|Charts: min/week, completion rate, RPE trend|
|Drawer|Profile & goals, device settings, offline/sync, privacy & data, debug/export (CSV)|

### Mobile UI Structure — Tablet

|Difference|Phone → Tablet|
|---|---|
|Navigation|Bottom tabs → **side NavigationRail** or permanent drawer|
|Today screen|Single column → **master-detail** (plan list + session detail side by side)|
|Progress screen|Stacked charts → **dashboard grid** (multiple charts visible at once)|
|Sessions screen|Single list → **grid layout** with larger cards and more info per card|
|In-session|Full-screen timer → **split view** (timer + exercise instructions + HR side panel)|
|General|Higher information density, larger touch targets unnecessary, more content per screen|

### Sensor Access in Flutter

|Sensor|Flutter Package|Usage|
|---|---|---|
|Accelerometer|`sensors_plus`|Step detection, activity classification (threshold-based)|
|Pedometer / Steps|`pedometer`|Daily step count for state vector|
|Heart Rate|`flutter_blue_plus` (BLE HR monitor) or `health` (Google Fit / Apple Health)|Resting HR, in-session HR|
|GPS|`geolocator`|Outdoor session tracking (optional, for distance)|
|Ambient light|`light` / `sensors_plus`|Detect environment (indoor hint)|

### Testing Strategy

- **Domain:** GenerateDailyPlan (readiness + history → coherent plan), safety rules (high RPE → no high intensity), state machine transitions, reward calculation, bandit convergence
- **Data:** Repository caching/TTL, offline fallback, sync queue
- **ViewModel / Bloc:** correct state emissions on success/failure, sync pending handling
- **Widget:** rendering, interaction, responsive layout (phone vs tablet), rotation
- **Integration:** end-to-end session flow
- **Mocks:** `mockito` for remote datasources, fake clock for TTL

### Demo Scenario

> "User slept little, resting HR is high, yesterday's workout was intense → today the system proposes mobility + breathing. Weather is bad → cardio moved indoor. After completion, feedback is 'hard' → tomorrow intensity is reduced. Switch to tablet → same data, different layout."

---

## Part B · Compliance Matrix

> [!important] Goal: Maximum Grade Every requirement must be fully covered. Partial coverage = risk.

### Legend

- ✅ = fully covered
- ⚠️ = partially covered — needs explicit attention
- ❌ = not covered — action required

|#|Requirement|Status|Notes|
|---|---|---|---|
|1|Team of exactly 3|⚠️|Emails signed by 2 people (Paolo + Daniel). A 3rd member is mandatory.|
|2|Proposal email after mid-November|✅|Two emails sent and discussed with the professor.|
|3|Original idea (not on market, no copy)|✅|Micro-coaching with on-device adaptive AI is novel.|
|4|No social network / map / cost-split app|✅|None of these categories.|
|5|Significantly complex (multiple screens, articulated flow)|✅|3 tabs + drawer + in-session + onboarding + AI logic + offline.|
|6|At least 1 external service beyond Firebase|✅|Open-Meteo + ExerciseDB (two APIs, both actively influence AI).|
|7|Two distinct layouts: phone + tablet|✅|Phone (bottom tabs, single column) + Tablet (NavigationRail, master-detail, dashboard grid). Flutter's `LayoutBuilder` / `MediaQuery` makes this native.|
|8|Screen rotation handling|✅|Flutter handles this via `OrientationBuilder` + responsive breakpoints. Must be explicitly implemented and tested for all key screens.|
|9|Polished UI/UX, appealing look and feel|⚠️|Planned but needs a concrete design system (palette, typography, custom theme).|
|10|Multiple threads|✅|Dart `Isolate`s for AI computation + `compute()` for heavy lifting; async for network/DB. Explicitly document in design doc.|
|11|Test campaign (~hundreds of tests)|⚠️|Strategy defined, scale ("hundreds") must be committed to. Flutter's testing infrastructure (`flutter_test`, `mockito`, `integration_test`) makes this very feasible.|
|12|Design/Test Document (PDF, not user manual)|⚠️|Deliverable acknowledged, structure not detailed yet.|
|13|Professional presentation (10–12 min)|⚠️|Demo scenario exists, but no timed structure planned.|
|14|Live demo (real device or simulator)|✅|On real device + tablet emulator (or second device).|
|15|In-person, official dates only|✅|Acknowledged.|
|16|No publishing before passing|✅|Not publishing.|
|17|Sensors usage|✅|Accelerometer, pedometer, HR (via BLE or Health API), optionally GPS and light.|
|18|AI/ML encouraged|✅|On-device bandit + feedback control + state machine.|
|19|Can explain all code|⚠️|Team responsibility, not a design issue.|
|20|Language: Flutter|✅|Flutter is explicitly listed and recommended in the course guide.|

---

## Part C · Gap Analysis & Action Items

### ❌ Critical Gap

> [!danger] GAP 1 — Team Size Emails signed by 2 people. The requirement is **exactly 3**. Find a third member or get explicit written approval from the professor for a team of 2.

### ⚠️ Gaps to Strengthen

> [!warning] GAP 2 — Test Campaign Scale Plan at least **150–200 tests**. Flutter makes this easy with `flutter_test` (unit + widget) and `integration_test`.
> 
> Suggested breakdown:
> 
> - Domain (AI planning, safety rules, state machine, reward, bandit): ~60
> - Data (repositories, caching, TTL, offline fallback, sync queue): ~50
> - Bloc/Cubit (state emissions, error handling, sync status): ~40
> - Widget (rendering, responsive layout, rotation behavior): ~30
> - Integration (end-to-end session flow on phone + tablet): ~20

> [!warning] GAP 3 — Design/Test Document Structure Must contain:
> 
> - Software architecture (layers, patterns, data flow diagrams)
> - AI model formalization (state vector, reward function, algorithm, convergence analysis)
> - State machine diagram with transition rules
> - Responsive strategy (breakpoints, layout differences phone vs tablet)
> - Threading model (what runs on isolates, what's async)
> - Test campaign (categories, coverage, methodology, results)
> - **No screenshots, no user manual**
> 
> Tip: use architecture diagrams (C4 or similar), class diagrams, sequence diagrams, and the state machine diagram.

> [!warning] GAP 4 — Presentation Timing Structure the 10–12 minutes:
> 
> - ~2 min: problem + concept + novelty ("sell")
> - ~2 min: architecture + AI model (technical depth)
> - ~1 min: multi-device strategy (phone + tablet, rotation, responsive)
> - ~4 min: live demo (the demo scenario, show both phone and tablet)
> - ~2 min: test campaign summary + key metrics
> - ~1 min: buffer for professor questions
> 
> Rehearse with a timer. Going over 12 min is penalizing.

> [!warning] GAP 5 — Visual Identity "Look and feel" is an evaluation criterion. Define concretely:
> 
> - Custom `ThemeData` (colors, typography, shape, elevation)
> - Consistent icon set (e.g., `lucide_icons` or custom)
> - Micro-animations (page transitions, progress ring, session countdown)
> - Don't rely on raw Material defaults — customize to create a recognizable brand

---

## Part D · Ideas to Exceed Requirements

> [!tip] Extras that push from "meets requirements" to "impressive". Pick what fits your timeline.

### D1 · Onboarding Flow

Animated 3–4 screen onboarding: app concept → profile creation → goal setting → (optional) pair BLE HR monitor. Nails the "first impression" criterion.

### D2 · Dark Mode + Dynamic Theming

Full dark mode with `ThemeMode.system`. On tablet, consider a denser dashboard-style theme. Demonstrates design maturity.

### D3 · AI Decision Log (Debug View)

Hidden screen showing the bandit's decision history: state vector → action chosen → reward → updated estimates. Extremely impressive in demo to prove the system learns.

### D4 · Simulated Time-Lapse Demo

Pre-seed the local DB with 2 weeks of realistic data. During the live demo, the professor sees the AI's adaptation curve, not just a cold start. This is the single most impactful demo trick.

### D5 · Home Screen Widget

A Flutter home widget (`home_widget` package) showing today's plan or next session. Small effort, big "completeness" perception.

### D6 · Notifications

Push notification reminders tied to the user's preferred time slots (`flutter_local_notifications`). If a session is skipped, the behavioral state machine triggers a gentler reminder.

### D7 · Accessibility

Semantic labels, sufficient contrast, TalkBack/VoiceOver tested. Rarely done in student projects — makes a strong impression.

### D8 · Animated Charts

Use `fl_chart` with animated transitions for progress screens. Smooth chart builds during the demo look professional.

### D9 · Lottie Animations

Use `lottie` package for session type icons (breathing animation, stretching figure, running cycle). Adds visual polish with minimal code.

### D10 · CSV/JSON Export

Already in the drawer plan. Export session history + AI decisions. During demo: "here's the raw data proving adaptation happened."

---

## Part E · Flutter-Specific Advantages

> [!info] Things that are easier in Flutter than in ArkTS and should be leveraged.

|Area|Flutter Advantage|
|---|---|
|Responsive layouts|`LayoutBuilder`, `MediaQuery`, `OrientationBuilder` — first-class responsive support|
|Phone + Tablet|Single codebase, breakpoint-based layout switching (e.g., `< 600dp` = phone, `≥ 600dp` = tablet)|
|Screen rotation|`OrientationBuilder` wraps any widget; test both orientations easily|
|State management|Mature ecosystem: `flutter_bloc`, `riverpod`, `provider`|
|Testing|`flutter_test` (unit + widget), `integration_test`, `mockito`, `bloc_test` — all built-in or first-party|
|Navigation|`go_router` (course-recommended)|
|Sensors|`sensors_plus`, `pedometer`, `health`, `flutter_blue_plus` — well-maintained packages|
|Offline DB|`drift` (type-safe, reactive), `isar`, `sqflite`|
|Charts|`fl_chart`, `syncfusion_flutter_charts`|
|Animations|`Hero`, `AnimatedContainer`, `Lottie`, `Rive` — minimal boilerplate|
|Material 3|Full Material 3 / Material You support with `useMaterial3: true`|

---

## Part F · Priority Checklist

> [!example] Ordered by impact on grade. Do these first.

- [ ] **Confirm 3rd team member** (or get written professor approval)
- [ ] **Implement phone layout** (bottom tabs + drawer + all screens)
- [ ] **Implement tablet layout** (NavigationRail, master-detail, dashboard grid — visibly different from phone)
- [ ] **Implement screen rotation** handling for all key screens (portrait + landscape)
- [ ] **Build the AI engine** (bandit + safety rules + state machine + feedback control)
- [ ] **Integrate 2 external APIs** (Open-Meteo + ExerciseDB), both actively influencing AI decisions
- [ ] **Design threading model** (Dart isolates for AI computation, async for network/DB) and document it
- [ ] **Define visual identity** (custom ThemeData, colors, typography, animations)
- [ ] **Write 150+ tests** organized in `test/` by feature
- [ ] **Build the Design/Test Document** (PDF: architecture, AI formalization, state machine, responsive strategy, test campaign — no screenshots)
- [ ] **Structure and rehearse the presentation** (timed, 10–12 min, both device sizes in demo)
- [ ] **Pre-seed demo data** for a compelling live demo showing AI adaptation over time
- [ ] Polish extras: onboarding, dark mode, AI debug log, notifications, home widget