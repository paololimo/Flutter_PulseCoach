---
title: "Product Brief: PulseCoach"
status: "complete"
created: "2026-03-26"
updated: "2026-03-26"
inputs:
  - docs/REQUIREMENTS.md
  - docs/FLUTTER.md
---

# Product Brief: PulseCoach

## Executive Summary

You mean to exercise. You wake up intending to move. Then you open a fitness app and it asks you to choose a workout, set a duration, pick a difficulty, configure muscle groups — and you close the app. The workout never happens. Not because you lacked willpower. Because you lacked a decision.

PulseCoach removes the decision entirely. It is a Flutter-based cross-platform app (Android, iOS/iPadOS, WearOS) that generates personalized micro-workout sessions — 2 to 10 minutes — adapted in real time to how you feel, what your body data shows, and what the world outside looks like. Open the app. In under 30 seconds you have a plan: "5 min mobility + 3 min breathing — indoor, low intensity." One tap to start.

The intelligence behind this runs entirely on the device — a contextual multi-armed bandit that learns which session types work best for *this* user, a behavioral state machine that tracks fatigue and readiness over time, and a feedback control loop that adjusts load based on post-session RPE. No health data sent to a cloud for personalization. No subscription required to get recommendations that adapt. No internet connection needed to train. This is privacy-first adaptive fitness: the intelligence lives where your data does.

---

## The Problem

There's a gap between wanting to be active and actually being active — and it's not the gym membership or the motivation. It's the daily friction of deciding what to do, given how you feel, how much time you have, and what the conditions are outside.

Existing fitness apps are built for planned intent: you've already decided to work out today, you have 45 minutes allocated, and you need a guided program. This architecture serves dedicated athletes. It fails entirely for the much larger population whose schedule is fragmented, whose energy fluctuates unpredictably, and who needs a workout to fit into the gaps of life rather than around it.

The science has moved ahead of the apps. The American College of Sports Medicine named "short bouts of physical activity" a top-10 fitness trend for the first time in 2024. Multiple peer-reviewed studies confirm that repeated 2-10 minute movement bouts — exercise snacks — produce cardiovascular, metabolic, and cognitive benefits comparable to single long sessions. The paradigm is validated. No app has been purpose-built around it with adaptive intelligence.

Meanwhile, no major fitness app currently modifies workout type based on real-time air quality — a daily health consideration for hundreds of millions of people in cities worldwide. The tools haven't caught up to where people actually live and train.

---

## The Solution

PulseCoach generates three micro-sessions per day — each 2 to 10 minutes — tailored to the user's current state.

Each session is a structured sequence: exercise selection (drawn from the ExerciseDB catalog), duration, intensity cue, and step-by-step instructions. A "5 min mobility" session is five specific movements — hip circles, thoracic rotation, shoulder rolls, ankle work, hamstring flow — sequenced for the available time, with haptic step transitions on the phone and live step display on the WearOS companion.

**What feeds the decision engine:**

*Physiological input:* resting heart rate, step count, accelerometer-detected activity, and post-session RPE (Rate of Perceived Exertion, 1-10). The system targets RPE ≈ 6.5 per session type and adjusts load up or down based on the rolling 3-day average.

*Contextual input:* real-time weather (temperature, precipitation via Open-Meteo) and air quality index determine whether the session is indoor or outdoor, and surface conditions where outdoor exercise poses health risks.

**Adaptive logic — on device, not in the cloud:**
- *Safety rules layer:* deterministic constraints prevent overloading a user who is fatigued, has elevated resting HR, or has missed multiple sessions.
- *Contextual bandit:* an epsilon-greedy algorithm learns, over weeks, which session types produce the best outcomes for this specific user in their typical contexts. New users start with a conservative prior from their onboarding profile; the system begins adapting from session one.
- *Behavioral state machine:* four states — Active, Fatigued, AtRisk, Recovering — govern the recommendation policy, with rule-based transitions auditable by the user.

**Explainability by design:** every recommendation surfaces a one-line reason. *"Intensity reduced: high RPE yesterday + short recovery + elevated resting HR."* The system earns trust by showing its work.

**WearOS companion:** the watch shows the current exercise step, session timer, and live heart rate during active sessions. Post-session summary on the wrist. All AI logic remains on the phone — the watch is a display, not a decision-maker. This makes PulseCoach one of the few fitness apps with genuine multi-device presence across phone, tablet, and wearable from a single codebase.

---

## What Makes This Different

No existing app delivers these five elements together:

| | Freeletics | Fitbod | Nike TC | Apple Fitness+ | PulseCoach |
|---|:---:|:---:|:---:|:---:|:---:|
| True micro-sessions (2–10 min) | Partial | No | No | No | Yes |
| On-device adaptive AI | No (cloud) | No (cloud) | No | Partial | Yes |
| In-session RPE feedback loop | Between sessions | Between sessions | No | No | Yes |
| Weather-aware session routing | No | No | No | No | Yes |
| Air quality integration | No | No | No | No | Yes |

**Privacy as a competitive position, not a compliance stance.** Health and biometric data stays on-device. The adaptation logic, the learning history, the RPE record — none of it leaves the phone without user consent. Weather and AQI lookups use approximate city-level location, not precise coordinates, by design. In a market where fitness data incidents have made the 18-35 demographic acutely privacy-aware, "your fitness intelligence lives where your data does" is a first-class value proposition, not a footnote.

**Explainability is rare.** Most fitness AI is a black box. A system that tells you *why* it made a recommendation — and is right — builds the kind of trust that turns first-week users into long-term ones.

**The AQI angle is genuinely unexplored.** Billions of people live in cities where the indoor/outdoor decision has real health consequences daily. No major fitness app automates that decision.

*Academic grounding:* PulseCoach is a practical implementation of the Just-in-Time Adaptive Intervention (JITAI) framework (Nahum-Shani et al., 2018), with a contextual bandit architecture analogous to the Stanford HeartSteps trial (Murphy et al., 2016) — the benchmark deployed mHealth bandit system, which also used weather as a contextual feature. This theoretical foundation makes the design both defensible and formally analyzable.

---

## Who This Serves

**Primary — Students and remote/hybrid workers who want to be active but can't make it stick.** Two distinct but equally underserved groups: students navigating unpredictable academic schedules, and remote workers who sit for 6-8 hours a day with real but irregular 5-10 minute gaps throughout. Both have abandoned 30-60 minute workout programs not from lack of motivation but from the impossibility of consistency. Their defining trait is not that they're inactive; it's that they *keep trying* and the friction keeps winning.

Their aha moments are different but the product is the same. For the student: 7:30am, slept poorly, raining, AQI elevated — *"5 min mobility + 3 min breathing — indoor, low intensity."* For the remote worker: 3pm slump, back-to-back meetings just ended — *"3 min breathing reset — your step count is low and your last session was two days ago."* No decision. No planning. Just action, calibrated to exactly this moment.

**Secondary: Wearable users who want coaching that actually uses their data.** They've been tracking steps and heart rate for months. They want a system that closes the loop — that takes those numbers and does something useful with them.

---

## Success Criteria

**Academic — PoliMi DIMA exam (primary):**
- Full coverage of all 8 evaluation criteria: novelty, complexity, external services, look and feel, multi-device support, test campaign, design document, presentation quality
- Test campaign: 150-200 automated tests organized across five layers (domain AI logic, data/caching, state management, widget/responsive, end-to-end integration)
- Live demo: AI adaptation visibly observable via 2-week pre-seeded data timeline, demonstrated on both phone and tablet

**Product fitness (post-exam indicators):**
- Retention: ≥ 3 sessions/week at day 30 for active users
- Completion rate: ≥ 75% of started sessions completed
- Adaptation quality: rolling RPE converges toward target ± 1.0 within 10 sessions for new users

---

## Scope

**In scope — v1:**
- Dual layouts: phone (bottom tab nav, full-screen session) and tablet (NavigationRail, master-detail, dashboard grid) — visually and functionally distinct
- Screen rotation: all key screens handle portrait and landscape
- WearOS companion: session display (timer, step, HR), post-session summary
- On-device AI: contextual bandit + behavioral state machine + RPE feedback control + explainability layer
- External APIs: Open-Meteo (weather + AQI) and ExerciseDB (exercise catalog) — both actively influence session selection
- Sensors: accelerometer, pedometer, heart rate (Health API / Google Fit)
- Offline-first: local DB, deferred sync, TTL caching for APIs
- Multithreading: Dart Isolates for AI computation, async for network and DB
- Test campaign: 150-200 tests in `test/` by layer
- Design/Test Document (PDF): software architecture, AI formalization, state machine, responsive strategy, threading model, test campaign — no screenshots

**Explicitly out of scope for v1:**
- External BLE HR monitor pairing (Health API used instead)
- Home screen widget
- Push notification reminders
- watchOS (Apple Watch) — WearOS only
- App store publishing (course requirement: prohibited until after exam)

---

## Vision

PulseCoach demonstrates that adaptive, privacy-respecting fitness intelligence is possible without cloud infrastructure — and that the exercise snack paradigm, already validated by science, can be made genuinely frictionless by software.

If the premise holds — that people will consistently choose a system that removes the planning burden and adapts to their real-world state — the roadmap expands naturally: watchOS support, home widget, notification-based session nudges, deeper health ecosystem integration (Apple Health, Google Fit), and eventually a federated learning layer that improves bandit initialization for new users from aggregate patterns — without ever centralizing individual health data.

The scope of the problem also extends beyond physical fitness. Breathing and mobility sessions — already part of the v1 session catalog — have documented effects on cortisol, cognitive performance, and stress recovery. A "3-minute reset between meetings" is not a micro-workout; it is a productivity intervention. PulseCoach's architecture supports this framing without any product change, opening an adjacent positioning in the focus and cognitive wellness space that the current fitness app market has not yet occupied.

The long-term position: the privacy-first, context-aware intelligence layer for daily movement and recovery — physical and cognitive. The app that finally makes the science of exercise snacks accessible to everyone who keeps meaning to work out and keeps not doing it.
