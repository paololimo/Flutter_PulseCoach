# PulseCoach

**PulseCoach** is an AI-powered adaptive fitness coaching app built with Flutter. It generates short, personalized daily micro-sessions (2–10 min) that adapt to the user's condition through on-device AI logic, sensor data, and contextual information (weather, exercise catalog).

Developed as the exam project for the **DIMA** (Design and Implementation of Mobile Applications) course at **Politecnico di Milano**.

📄 **[Design Document & Test Campaign](docs/PulseCoach%20Design%20Document%20%26%20Test%20Campaign.pdf)** — the full design rationale, architecture decisions, and test campaign report.

## Concept

PulseCoach targets students and active people who want quick, decision-free workouts. The core differentiator: the AI isn't decorative — it runs on-device, adapts based on user feedback and sensor data, and explains its decisions.

### Core Features

- **Profile & Goals** — fitness level, objective (cardio / strength / mobility / well-being), available time, and constraints
- **AI-Generated Daily Plan** — three micro-sessions per day, dynamically adapted after feedback (RPE 1–10), sensor data, and weather
- **Session Catalog** — a curated exercise library with an offline fallback
- **Progress Tracking** — session history and completion trends
- **Social** — an opt-in accountability layer
- **Wear OS companion app** — session and rest display synced from the phone
- Full **light/tablet** responsive layout with rotation support, and English/Italian localization

## Tech Stack

- **Flutter / Dart**, `flutter_bloc` for state management, `go_router` for navigation
- **Drift** (SQLite) for local persistence, `get_it` + `injectable` for dependency injection
- **Supabase** for auth, storage, and backend functions
- On-device AI logic for daily plan generation, running in a background isolate
- Sensors & health data via `sensors_plus`, `health`, `geolocator`
- Wear OS module (`pulse_coach/wear`) with phone↔watch communication

## Project Structure

```
Flutter_PulseCoach/
├── docs/                          # Design docs, requirements, presentation
│   └── PulseCoach Design Document & Test Campaign.pdf
├── pulse_coach/                   # Flutter app
│   ├── lib/
│   │   ├── ai/                    # On-device AI / behavioral state machine
│   │   ├── core/                  # Cross-cutting concerns (DI, DB, error handling)
│   │   ├── features/              # Feature modules (onboarding, today, sessions_catalog,
│   │   │                          #   progress, social, settings, subscription, ...)
│   │   └── shared/                # Shared UI components
│   ├── test/                      # Unit, widget, bloc, and integration tests
│   └── wear/                      # Wear OS companion app
└── supabase/                      # Backend functions, migrations, and tests
```

## Getting Started

```bash
cd pulse_coach
flutter pub get
flutter run
```

Run the test suite:

```bash
cd pulse_coach
flutter test
```

## Documentation

- [`docs/PulseCoach Design Document & Test Campaign.pdf`](docs/PulseCoach%20Design%20Document%20%26%20Test%20Campaign.pdf) — full design and test campaign document
- [`docs/REQUIREMENTS.md`](docs/REQUIREMENTS.md) — DIMA exam requirements
- [`docs/FLUTTER.md`](docs/FLUTTER.md) — proposal & compliance analysis
- [`docs/demo-runbook.md`](docs/demo-runbook.md) — demo runbook
