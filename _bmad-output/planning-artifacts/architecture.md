---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-03-27'
v2Rework:
  startedAt: '2026-06-20'
  completedAt: '2026-06-20'
  stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
  status: 'complete'
  backendPlatform: 'Supabase (EU region)'
inputDocuments:
  - "_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach.md"
  - "_bmad-output/planning-artifacts/product-brief-Flutter_PulseCoach-distillate.md"
  - "_bmad-output/planning-artifacts/prd.md"
  - "_bmad-output/planning-artifacts/prd-validation-report.md"
  - "_bmad-output/planning-artifacts/ux-design-specification.md"
  - "_bmad-output/planning-artifacts/addendum.md"
  - "_bmad-output/planning-artifacts/.decision-log.md"
  - "_bmad-output/planning-artifacts/ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md"
  - "_bmad-output/planning-artifacts/ux-designs/ux-Flutter_PulseCoach-2026-06-20/EXPERIENCE.md"
  - "docs/REQUIREMENTS.md"
  - "docs/FLUTTER.md"
workflowType: 'architecture'
project_name: 'Flutter_PulseCoach'
user_name: 'Paolo'
date: '2026-03-27'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

52 FRs across 10 categories spanning the complete product surface:

| Category | FRs | Architectural Impact |
|---|---|---|
| AI-Powered Daily Planning | FR5-FR12 | Core domain logic: bandit + state machine + safety rules. Requires Isolate-based computation, deterministic override layer, cold-start initialization |
| Guided Session Execution | FR16-FR20 | Full-screen overlay flow with timer, haptic feedback, WearOS sync. Real-time state management during active session |
| Feedback & Adaptation Loop | FR21-FR25 | RPE collection → reward calculation → bandit update → state machine transition. Circular data flow requiring careful orchestration |
| Explainability & Trust | FR13-FR15 | Structured reason string generation from AI decision context. Read-only projection of internal AI state |
| Environmental Context | FR33-FR36 | External API integration (Open-Meteo) with TTL caching, city-level location, fallback to indoor defaults |
| Exercise Catalog | FR26-FR28 | External API integration (ExerciseDB) with local caching and offline availability |
| Multi-Device Experience | FR37-FR41 | Dual layouts (phone/tablet) + WearOS companion. Responsive breakpoint at 600dp. Watch as passive display |
| Sensor Integration | FR42-FR44 | Health API, accelerometer, GPS. All optional with RPE-only fallback |
| Offline & Data | FR45-FR47 | Local DB as primary source, TTL caching, deferred sync queue |
| Onboarding, Profile, Settings, Progress | FR1-4, FR29-32, FR48-52 | Standard CRUD + chart rendering + dark mode + export |

**Non-Functional Requirements:**

26 NFRs organized into 5 categories with direct architectural consequences:

| Category | Key NFRs | Architectural Driver |
|---|---|---|
| Performance | NFR1 (plan <30s), NFR2 (60fps during AI), NFR4 (haptic <200ms), NFR6 (cold start <3s) | Isolate-based AI computation, reactive UI, efficient local DB queries |
| Security & Privacy | NFR7-NFR12 | Zero cloud transmission, local-only data, no auth, GDPR Art. 9 local processing |
| Reliability & Data Integrity | NFR13-NFR18 | Offline-first architecture, TTL caching, persistent local DB, deferred sync |
| Integration Resilience | NFR19-NFR23 | Fail-fast external APIs, cache-first serving, graceful degradation at every integration point |
| Accessibility | NFR24-NFR26 | 48dp touch targets, WCAG 2.1 AA contrast, full accessibility deferred to post-MVP |

**Scale & Complexity:**

- Primary domain: Cross-platform mobile (Flutter/Dart) with WearOS companion
- Complexity level: **High**
- Estimated architectural components: ~25-30 (domain entities, use cases, repositories, datasources, blocs, UI components)

### Technical Constraints & Dependencies

| Constraint | Source | Impact |
|---|---|---|
| Flutter/Dart single codebase | DIMA course requirement | All platform targets (Android, iOS, WearOS) from one codebase |
| `go_router` for navigation | Course recommendation | Navigation architecture locked to declarative routing |
| `flutter_bloc` for state management | PRD decision (confirmed) | All state flows through Bloc/Cubit pattern |
| `drift` for local database | PRD decision (confirmed) | Type-safe, reactive queries; shapes data layer |
| No cloud backend | Privacy-first + academic scope | All intelligence on-device; no server infrastructure |
| No app store publishing pre-exam | Course rule | No store compliance needed for v1 |
| Team of 2-3 developers | Academic constraint | Architecture must be partitionable into 2-3 ownership areas |
| WearOS via `wear_plus` (with Kotlin fallback) | PRD spike plan | Medium technical risk; affects companion architecture |
| iOS Health API requires real device | Platform constraint | Testing strategy must account for simulator limitations |

### Cross-Cutting Concerns Identified

1. **Offline-First Data Flow** — Every data access path must work without network. Repositories must abstract local-vs-remote transparently. Cache invalidation (TTL) is a system-wide concern.

2. **Graceful Degradation** — Sensors, APIs, and WearOS are all independently optional. The AI context vector must dynamically adjust to available inputs. No user-visible error states for expected degradation.

3. **Threading Model** — Clear separation: Dart Isolates for AI computation, async/await for I/O (network + DB), main isolate for UI. Must be documented and enforced architecturally.

4. **Responsive Layout** — Every screen has phone and tablet variants. Layout decision made once at scaffold level via `LayoutBuilder`. Components are shared; arrangement differs.

5. **Testability** — 150-200 tests across 5 layers requires clean dependency injection, mockable interfaces at every boundary, and testable domain logic isolated from Flutter framework.

6. **Privacy Boundary** — No biometric data crosses the device boundary. Location is city-level only. This constraint shapes every data flow touching health or sensor data.

7. **AI Decision Traceability** — Every recommendation must produce a structured explanation. The AI stack must expose decision context for both UX display and debug/export features.

---

### Requirements Overview — v2 Additions (Accounts, Subscriptions & Social)

> v2 lifts the defining v1 constraint ("no cloud backend"). Cloud is **optional and additive** — the v1 free, offline, account-free experience is preserved as the free tier and must never regress.

**v2 Functional Requirements (FR53–FR77):**

| Category | FRs | Architectural Impact |
|---|---|---|
| Navigation Fix | FR53 | Pure presentation/routing: explicit return affordance from drawer secondaries to primaries. No backend. Ship-first (v2.0) |
| Accounts & Auth | FR54–FR57 | New auth subsystem: email+password, Sign in with Apple, Google (OIDC), secure token storage. Optional account; app fully usable without it. E2E-encrypted, user-keyed backup/restore of profile + history + personalization state |
| Subscriptions (Pro) | FR58–FR62 | IAP integration (App/Play Store billing), entitlement/gating layer, restore/cancel, grandfathering requiring pre-/post-v2 user discrimination, free/Pro Progress boundary |
| Social — Friends | FR63–FR67 | Cloud social graph: unique handle, friend requests, activity feed, comparison. Privacy-by-default (private until opt-in) |
| Social — Shared Live Sessions | FR68–FR73, FR77 | Real-time multi-participant transport (net-new N-way relay, ~1s sync), join-code/QR pairing, momentary co-location check, deterministic group-adaptation rules on the on-device engine, per-participant RPE. In-app account deletion (store-blocking) |
| Social — Leaderboard & Scoring | FR74–FR76 | Server-maintained friends leaderboard, shared-session point bonus, ranking-only exposure |

**v2 Non-Functional Requirements (NFR27–NFR37):**

| Category | Key NFRs | Architectural Driver |
|---|---|---|
| Auth & Account Security | NFR27, NFR28 | Hashed passwords, OAuth/OIDC, TLS, secure token storage; on-device personalization preserved, no cross-user training |
| Privacy & Compliance (cloud) | NFR29, NFR30, NFR33, NFR35, NFR36, NFR37 | Visibility tiers, GDPR export + erasure cascade (≤30d), momentary non-stored co-location, unbundled per-purpose consent, EU data residency, minimum age (≈16) |
| Real-Time & Reliability | NFR31, NFR34 | ~1s sync across participants, drop-out tolerance; social degrades gracefully — v1 core stays fully offline-first regardless of account/sub state |
| Store & Billing | NFR32 | Platform IAP, Sign in with Apple parity, privacy nutrition labels |

**Scale & Complexity — revised for v2:**

- Primary domain: Cross-platform mobile **+ optional cloud backend** (client-server with real-time)
- Complexity level: **High → Enterprise-leaning** (multi-tenant data, federated auth, payments, real-time, cross-border compliance)
- New architectural components (v2): ~12–18 (auth subsystem, backend services, sync/backup, IAP/entitlements, social graph store, real-time relay, group-engine adapter, consent/erasure machinery)

### Technical Constraints & Dependencies — v2 Additions

| Constraint | Source | Impact |
|---|---|---|
| "No cloud backend" is reversed | v2 watershed | The single hardest-set v1 constraint is lifted; cloud is optional and additive, never required for the free core |
| EU data residency for EU users | NFR36 | Backend provider/region choice constrained (open item — resolved in Core Decisions) |
| Platform IAP mandatory for Pro | NFR32, store policy | No third-party payment rails for the digital subscription |
| E2E encryption with user-held key | FR57, NFR28 | Backup is an opaque blob server-side; key management UX + recovery is a design problem |
| ~1s real-time sync, N participants | NFR31 | Net-new relay — does NOT inherit the 1:1 phone↔watch bridge |
| Grandfathering pre-/post-v2 installs | FR61 | System must durably mark install cohort |

### Cross-Cutting Concerns — v2 Additions

8. **Free/Pro/Account Gating** — three-way capability matrix (account-free free / signed-in free / Pro) threaded through routing, feature access, and UI. Must never degrade the v1 free path.

9. **Cloud Privacy Boundary** — distinct from v1's device boundary: opt-in, own-account-scoped, per-purpose consent, biometric-derived state E2E-encrypted and never server-readable. Erasure must cascade across friends' feeds/leaderboard.

10. **Real-Time Consistency** — synchronized session state across N devices with drop-out tolerance; new failure modes (partial sync, participant loss) the offline-first v1 never had.

11. **Group-Constraint Adaptation** — the on-device AI engine must accept a group constraint (deterministic min/lowest/union/shortest rules, FR70) layered on existing per-user FR9 safety — reuse, not a parallel engine.

12. **Store Compliance** — IAP, in-app account deletion, Sign in with Apple parity, privacy labels become hard gates for App Store publication (new for v2).

## Starter Template Evaluation

### Primary Technology Domain

Cross-platform mobile application (Flutter/Dart) with WearOS companion, based on confirmed project requirements and DIMA course constraints.

### Starter Options Considered

#### Option 1: `flutter create` (Standard Flutter CLI)

The default Flutter project generator. Creates a minimal project structure with platform targets.

| Aspect | Assessment |
|---|---|
| Structure | Flat, single `lib/main.dart`. No architectural patterns |
| State management | None — manual setup required |
| Testing | Basic `flutter_test` dependency, single example test |
| Linting | Default `flutter_lints` |
| Pros | Minimal, no opinionated decisions, full control |
| Cons | Requires building entire architecture from scratch |

#### Option 2: Very Good CLI (`very_good_cli` v1.0.0)

Production-grade Flutter starter by Very Good Ventures. Generates an opinionated project structure with bloc, flavors, and testing infrastructure built in.

| Aspect | Assessment |
|---|---|
| Structure | Feature-first with `app/`, bloc-based state management, generated routing |
| State management | `flutter_bloc` integrated (matches our choice) |
| Testing | Full testing infrastructure: `very_good_analysis`, `bloc_test`, coverage tooling, `--fail-fast` mode |
| Linting | Strict `very_good_analysis` (opinionated, production-grade) |
| Flavors | Dev/staging/production build flavors out of the box |
| Pros | Production-quality foundation, bloc already integrated, testing-first mindset |
| Cons | Opinionated structure may conflict with Clean Architecture; includes i18n/flavors not needed |

#### Option 3: Manual Clean Architecture Setup (from `flutter create` base)

Start with standard `flutter create`, then manually scaffold the Clean Architecture folder structure.

| Aspect | Assessment |
|---|---|
| Structure | Fully custom feature-first Clean Architecture |
| State management | Manual `flutter_bloc` integration — exact configuration needed |
| Testing | Manual setup organized by layer per test strategy |
| Pros | 100% aligned with PRD, no dead code, full transparency |
| Cons | More initial setup; negligible with AI-assisted development |

### Selected Starter: Option 3 — Manual Clean Architecture Setup

**Rationale for Selection:**

1. **Perfect alignment with PRD.** The PRD specifies Clean Architecture / MVVM with feature-first folder structure. Neither standard CLI nor Very Good CLI generates this exact structure.
2. **No dead code.** Very Good CLI includes flavors, i18n, and generated routing that PulseCoach doesn't need.
3. **WearOS as separate target.** PulseCoach requires a WearOS companion with its own UI — neither starter handles multi-target.
4. **Academic transparency.** The DIMA exam requires the team to explain all code. A manually scaffolded architecture is fully understood.
5. **AI-assisted development.** Scaffolding effort is negligible with modern tooling.

**Initialization Command:**

```bash
flutter create --platforms=android,ios --org com.pulsecoach pulse_coach
```

**Architectural Decisions Provided by Starter:**

**Language & Runtime:**
- Dart (latest stable via Flutter 3.41.x SDK), null safety enforced

**Styling Solution:**
- Material 3 with `useMaterial3: true`, custom `ThemeData` with `ColorScheme.fromSeed()` (dark-first)
- Plus Jakarta Sans + JetBrains Mono (per UX spec)

**Build Tooling:**
- Standard Flutter build system, `dart run build_runner` for drift code generation
- Android: Gradle (Kotlin DSL), iOS: Xcode / CocoaPods

**Testing Framework:**
- `flutter_test` (unit + widget), `bloc_test` (state management), `mockito` (mock generation), `integration_test` (end-to-end)
- Test folder organized by layer: `test/{domain,data,bloc,widget,integration}/`

**Code Organization:**
- Feature-first: `lib/features/{feature}/{data,domain,presentation}/`
- Core: `lib/core/{di,routing,theme,utils,constants}/`
- Repository pattern with DTO ↔ Domain mapping

**Development Experience:**
- Hot reload / hot restart, Flutter DevTools, `flutter analyze`, `flutter test --coverage`

**Key Package Versions (verified March 2026):**

| Package | Version | Role |
|---|---|---|
| Flutter SDK | 3.41.x (stable) | Framework |
| `flutter_bloc` | latest on pub.dev | State management |
| `drift` | ~2.32.x | Local database (type-safe, reactive) |
| `drift_flutter` | latest on pub.dev | Drift Flutter integration |
| `go_router` | latest on pub.dev | Declarative routing |
| `wear_plus` | latest on pub.dev | WearOS companion support |
| `dartz` | latest on pub.dev | Functional programming (Either<Failure, T>) |
| `sensors_plus` | latest on pub.dev | Accelerometer, ambient light |
| `health` | latest on pub.dev | HealthKit / Health Connect |
| `geolocator` | latest on pub.dev | City-level location |
| `fl_chart` | latest on pub.dev | Animated charts |
| `lottie` | latest on pub.dev | Session type animations |
| `google_fonts` | latest on pub.dev | Plus Jakarta Sans, JetBrains Mono |

**Note:** Project initialization using this command should be the first implementation story. Exact package versions will be pinned in `pubspec.yaml` at initialization time.

---

### Starter Template Evaluation — v2 Addendum

**Client starter: unchanged.** The v1 selection (Option 3 — Manual Clean Architecture from `flutter create`) stands and is already implemented through Epic 5–14. v2's new UI surfaces (SignInSheet, ProUpsellSheet, social components) extend the existing feature-first structure — no new client starter is warranted.

**Backend scaffold: deferred to Core Architectural Decisions.** v2 introduces a backend for the first time, but the scaffold/init command is a direct function of the platform choice, which is an open item resolved in the Core Decisions section. Candidate platforms and their corresponding scaffolds (evaluated there, with current versions verified at decision time):

| Candidate backend platform | Scaffold / init path | Server code to own? |
|---|---|---|
| Firebase (BaaS, Google) | No server scaffold; SDK + Firebase console/CLI config | No (managed) |
| Supabase (BaaS, Postgres OSS) | `supabase init` (CLI), EU region project | Minimal (edge functions, SQL/RLS) |
| Serverpod (Dart server framework) | `serverpod create` | Yes (full Dart server) |
| Custom (Node/Nest, etc.) | Framework CLI (`nest new`, …) | Yes (full server) |

The selected platform's exact scaffold command and pinned versions are web-verified and recorded in the Core Architectural Decisions section once the choice is made.

**Client-side v2 dependencies (new packages, versions to pin at decision time):** the auth/IAP/realtime client libraries (e.g. `sign_in_with_apple`, `google_sign_in`, an IAP plugin such as `in_app_purchase` or `purchases_flutter`, a realtime/websocket client, secure storage like `flutter_secure_storage`, and an E2E-crypto lib) are platform-dependent and selected alongside the backend platform in Core Decisions.

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Dependency injection: `get_it` + `injectable`
- Database migrations: stepwise via drift `onUpgrade`
- HTTP client: `dio` with interceptors
- Serialization: `freezed` + `json_serializable`
- Bloc/Cubit split: Bloc per domain concern, Cubit per UI-only state

**Important Decisions (Shape Architecture):**
- API caching: drift-based with TTL column
- Lottie assets: bundled in `assets/`
- CI: GitHub Actions (analyze + test)
- Environment config: compile-time constants

**Deferred Decisions (Post-MVP):**
- Database encryption (`sqlcipher`) — evaluate for store publication
- Advanced CI (build + deploy pipelines) — post-exam
- Feature flags — not needed for v1

### Data Architecture

| Decision | Choice | Version | Rationale |
|---|---|---|---|
| Dependency Injection | `get_it` + `injectable` | latest on pub.dev | Pragmatic DI with code-gen; reuses `build_runner` already needed for drift and freezed |
| Database | `drift` + `drift_flutter` | ~2.32.x | Confirmed in PRD. Type-safe, reactive, built-in Isolate support for threading |
| Schema Migrations | Stepwise via `onUpgrade` | — | Bandit learning state and session history must persist across app updates (NFR15-NFR16) |
| API Caching | Drift tables with `cachedAt` timestamp column | — | Single source of truth. Repository checks TTL, serves from DB if valid, fetches and updates if stale. Works offline by design |
| Serialization | `freezed` + `json_serializable` | latest on pub.dev | Immutable data classes with copyWith, equality, and JSON support. Essential for flutter_bloc state comparison |

### Authentication & Security

| Decision | Choice | Rationale |
|---|---|---|
| Authentication | None (NFR11) | No user account, no email, no auth. Profile data is local-only |
| Database Encryption | None for v1 | OS sandbox provides adequate protection. `sqlcipher` noted as post-v1 improvement |
| Location Privacy | City-level approximation only | GPS coordinates rounded to city level before Open-Meteo API calls (NFR8) |
| Health Data | On-device only, zero transmission | GDPR Art. 9 compliance via local processing with explicit consent (NFR7, NFR12) |

### API & Communication Patterns

| Decision | Choice | Version | Rationale |
|---|---|---|---|
| HTTP Client | `dio` | latest on pub.dev | Interceptors for cache logic, logging, fail-fast behavior. Built-in retry and timeout support (NFR18, NFR23) |
| Open-Meteo Integration | REST via `dio`, cached in drift, TTL 1h | — | Free API, no auth key needed. City-level lat/lon. Fallback: indoor default if cache >2h stale (NFR19) |
| ExerciseDB Integration | REST via `dio`, cached in drift, TTL 24h | — | Exercise catalog cached locally. Fallback: bundled core exercise set if no cache available (NFR20) |
| WearOS Communication | `wear_plus` (primary), Kotlin Message API (fallback) | latest on pub.dev | Phone pushes session state to watch; watch sends HR back. Early spike to validate feasibility |
| Error Handling | Fail-fast + cache-first | — | All external calls: try network → on failure serve cache → on no cache use bundled defaults. Never block UI on network |

### Frontend Architecture

| Decision | Choice | Rationale |
|---|---|---|
| State Management Split | Bloc for domain flows, Cubit for UI-only state | Bloc: SessionBloc, DailyPlanBloc, FeedbackBloc. Cubit: ThemeCubit, OnboardingCubit, ProgressCubit. Best practice per bloclibrary.dev |
| Responsive Strategy | `LayoutBuilder` at scaffold level, single 600dp breakpoint | Phone (<600dp): bottom NavigationBar. Tablet (≥600dp): NavigationRail + master-detail. Shared components, different arrangement |
| Routing | `go_router` with declarative routes | Course-recommended. Shell routes for bottom nav / NavigationRail. Overlay routes for InSessionView |
| Lottie Assets | Bundled in `assets/animations/` | Offline-first requirement. Small file sizes (10-50KB). Fallback to static Lucide icons if not ready |
| Theme Architecture | `ThemeData` + `ThemeExtension<PulseCoachTheme>` | M3 base with custom tokens for session cards, RPE, state indicators. Dark-first via `ColorScheme.fromSeed()` |

### Infrastructure & Deployment

| Decision | Choice | Rationale |
|---|---|---|
| CI/CD | GitHub Actions: `flutter analyze` + `flutter test` on push | Protects 150-200 test suite from regression. Free for educational repos |
| Environment Config | Compile-time constants in `lib/core/constants/` | All APIs are free and public (no secrets). Simple and transparent for exam |
| Monitoring | Flutter DevTools only | No production monitoring needed for academic project |
| Build Targets | Android APK + iOS (dev profile) + WearOS APK | No store publication pre-exam. Debug/profile builds for demo |

### Decision Impact Analysis

**Implementation Sequence:**
1. Project scaffolding + `get_it`/`injectable` setup + drift DB schema
2. Domain layer: entities (`freezed`), use cases, AI engine interfaces
3. Data layer: drift tables, repositories, dio remote datasources
4. Presentation layer: Blocs/Cubits, go_router config, theme
5. UI layer: phone layout → tablet layout → WearOS companion
6. Test campaign across all 5 layers

**Cross-Component Dependencies:**
- `freezed` entities are consumed by drift DAOs, blocs, and UI — must be defined first
- `get_it` registration order matters: datasources → repositories → use cases → blocs
- `dio` interceptors depend on drift cache tables being defined
- Bloc states depend on `freezed` entity equality for proper rebuild behavior
- `go_router` shell routes depend on responsive layout decision (NavigationBar vs NavigationRail)

---

### Core Architectural Decisions — v2 Additions (Cloud, Accounts & Social)

> **Guiding principle:** v2 cloud is additive and optional. The v1 on-device stack (drift, on-device AI, offline-first) remains the source of truth for the free core. Supabase is the cloud backend; nothing below blocks the account-free free path.

**v2 Critical Decisions (block v2 implementation):**
- Backend platform: **Supabase** (managed BaaS, Postgres), EU region `eu-central-1` (Frankfurt) — NFR36
- Auth: **Supabase Auth** (email/password, Sign in with Apple, Google OIDC) — NFR27, FR54–55
- Cloud data model: **Postgres + Row-Level Security**; local **drift stays canonical** for v1 core, cloud is opt-in mirror/social store
- Real-time transport: **Supabase Realtime Broadcast + Presence** for shared sessions — FR71/NFR31
- E2E backup: **client-side encryption, user-held key**; opaque blob in Supabase Storage — FR57/NFR28
- Billing: **platform IAP** via `purchases_flutter` (RevenueCat) for entitlements + grandfathering — FR58–62, NFR32

**v2 Important Decisions:**
- Group-adaptation: deterministic `GroupConstraint` layered on the existing on-device engine (reuse, not parallel) — FR70
- GDPR machinery: FK `ON DELETE CASCADE` + Edge Function for erasure/export — NFR30
- Consent: per-purpose records, unbundled, independently withdrawable — NFR35

**v2 Deferred / Open:**
- Exact Pro price/tiers (business); point formula + anti-abuse (design); WearOS participant-vs-mirror (`[ASSUMPTION]` mirror); self-host-in-EU migration (only if CLOUD Act posture must harden)

#### Data Architecture — v2

| Decision | Choice | Rationale |
|---|---|---|
| Cloud database | Supabase Postgres (EU region) | Relational model fits the social graph; RLS enforces privacy declaratively (NFR29) |
| Source of truth | Local drift stays canonical for profile/sessions/AI state; cloud is an opt-in backup + social projection | Preserves offline-first v1 (NFR34); cloud never required for the free core |
| Sync model | One-way opt-in backup/restore of own data (FR57) + purpose-scoped social writes (shared completions, leaderboard points). No silent cross-device live sync of personal history in v2 | Keeps scope bounded; avoids conflict-resolution complexity not required by PRD |
| Social schema | `profiles`, `friendships`, `shared_sessions`, `session_participants`, `activity_feed`, `leaderboard_entries`, `consents` | Normalized; FKs enable cascade erasure (NFR30) |
| Visibility enforcement | RLS policies = `private` (default) / `friends-only` / per-item; never friend-of-friend | NFR29 enforced at the DB, not the client |
| Install cohort | Durable `installCohort` (pre-v2 / post-v2) in drift and mirrored to `profiles` on sign-in | Grandfathering (FR61) must survive reinstall for signed-in users |

#### Authentication & Security — v2

| Decision | Choice | Rationale |
|---|---|---|
| Auth provider | Supabase Auth | Email/password, Apple, Google in one provider; OIDC/OAuth handled (NFR27) |
| Client packages | `sign_in_with_apple`, `google_sign_in`, `supabase_flutter` | Native sign-in sheets; Apple parity required by store (NFR32) |
| Token storage | `flutter_secure_storage` (Keychain / Keystore) | Secure refresh-token persistence (NFR27) |
| Account optionality | Auth gates only backup + social + Pro; v1 core never requires it | FR56, preserves NFR11 as the free tier |
| E2E backup encryption | Client encrypts payload with a user-held key (passphrase-derived via Argon2/`cryptography` pkg) before upload; server stores ciphertext blob only | Biometric-derived AI state never server-readable (NFR28, resolves Art. 9 — FR57) |
| Key recovery | User-held recovery phrase; lost key = lost backup (documented, by design) | No server-side key escrow → no readable-server path |

#### API & Communication Patterns — v2

| Decision | Choice | Rationale |
|---|---|---|
| Cloud access | `supabase_flutter` (PostgREST + RPC) behind v2 repositories returning `Either<Failure, T>` | Same dartz error contract as v1; cloud failures degrade gracefully (NFR34) |
| Shared-session real-time | Supabase Realtime Broadcast (ephemeral step+timer events) + Presence (lobby/ready/drop-out) | ~1s sync, N participants, no persistence of live state (FR71/NFR31/NFR33) |
| Session ownership | One participant is host; host advances steps, broadcast fans out; drop-out tolerated via Presence | NFR31 "a participant dropping out does not interrupt others" |
| Co-location check | Momentary `geolocator` read at join → boolean only, not stored, soft/non-blocking | NFR33; reuses existing v1 `geolocator` dependency |
| Server-side logic | Supabase Edge Functions: IAP receipt validation, erasure cascade, data export | Keep secrets/validation off-client |
| IAP entitlements | `purchases_flutter` (RevenueCat) → entitlement cached locally; server validates receipts | Cross-platform IAP + grandfathering + restore (FR58–60) with less custom code; `in_app_purchase` is the no-dependency fallback |

#### Frontend Architecture — v2

| Decision | Choice | Rationale |
|---|---|---|
| New feature modules | `features/auth/`, `features/subscription/`, `features/social/` (friends, feed, leaderboard, shared_session) under existing Clean Architecture | Consistent with v1 feature-first structure |
| State management | Bloc for cloud/domain flows (`AuthBloc`, `SubscriptionBloc`, `SharedSessionBloc`, `FriendsBloc`); Cubit for UI-only (`VisibilityCubit`) | Same Bloc/Cubit split rule as v1 |
| Gating | `EntitlementGate` (account-free free / signed-in free / Pro) consulted by router + widgets; contextual silent `ProUpsellSheet` on locked-feature tap | FR59/FR62; matches DESIGN "no persistent paywall" |
| Navigation fix (FR53) | Drawer secondaries (Settings/Profile/Privacy/Debug) get an explicit return affordance to primaries via `go_router` | Pure routing; ship-first (v2.0) |
| New UI components | SignInSheet, ProUpsellSheet, FriendRow, ActivityFeedCard, LeaderboardRow, SharedSessionLobby, JoinCodeCard, VisibilityTierSelector | Per DESIGN.md; reuse theme tokens, no new visual temperature |
| Group engine adapter | `GroupConstraint` (min intensity cap / lowest level / union of exclusions / shortest duration) passed into the existing on-device engine; per-user FR9 safety still applies | FR70 deterministic, testable; reuse not rewrite |

#### Infrastructure & Deployment — v2

| Decision | Choice | Rationale |
|---|---|---|
| Hosting | Supabase managed project, EU region | NFR36 data residency |
| Migrations | Supabase CLI (`supabase init`, SQL migrations in repo, RLS in version control) | Reviewable, reproducible schema + policies |
| Secrets | Supabase keys via `--dart-define` / secure config (publishable `sb_publishable_*` + secret `sb_secret_*`); no secrets in git | Legacy anon/service keys deprecated end-2026; aligns with security rule |
| CI/CD | Extend GitHub Actions: analyze + test + (new) Edge Function lint; client unaffected when offline | Build on existing pipeline |
| Compliance gates | In-app account deletion (FR77), Sign in with Apple parity, privacy nutrition labels before store submit | Store-blocking (NFR32) |
| Erasure/export | Edge Function: cascade delete across feeds/leaderboard/friendships (visible removal immediate, backend purge ≤30d) + portable JSON export | NFR30 |

#### Decision Impact Analysis — v2

**Implementation sequence (mirrors PRD phasing v2.0 → v2.5):**
1. **v2.0** Navigation fix (FR53) — pure client, no backend
2. **v2.1** Supabase project (EU) + Auth + `EntitlementGate` skeleton + E2E backup/restore + in-app account deletion (FR54–57, FR77)
3. **v2.2** IAP/Pro + Progress free/Pro gating + grandfathering cohort (FR58–62)
4. **v2.3** Social graph + RLS visibility tiers + feed/comparison (FR63–67, NFR29)
5. **v2.4a** Realtime Broadcast/Presence transport (FR71)
6. **v2.4b** Group engine adapter + co-location join (FR68–70, FR72–73)
7. **v2.5** Leaderboard + scoring (FR74–76) — honor counter-metrics

**Cross-component dependencies:**
- RLS policies depend on the `friendships` model → must precede social reads
- `EntitlementGate` depends on IAP + install-cohort → precedes Pro gating
- Realtime transport (v2.4a) is a hard prerequisite for the group engine join (v2.4b)
- E2E key management must exist before any backup write
- On-device engine `GroupConstraint` interface is the only AI-layer change — keeps the bandit/state-machine otherwise untouched

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 6 areas where AI agents could make different choices: naming, structure, formats, communication, process, and AI engine isolation.

### Naming Patterns

**Dart/Flutter Code Naming (Dart style guide enforced):**

| Element | Convention | Example |
|---|---|---|
| Classes | UpperCamelCase | `DailyPlanBloc`, `SessionRepository`, `WeatherRemoteDataSource` |
| Files | snake_case | `daily_plan_bloc.dart`, `session_repository.dart` |
| Variables, parameters | lowerCamelCase | `sessionCount`, `rollingRpeAverage` |
| Constants | lowerCamelCase | `defaultEpsilon`, `maxRpeValue` |
| Enums | UpperCamelCase (type), lowerCamelCase (values) | `BehavioralState.active`, `BehavioralState.fatigued` |
| Private members | `_` prefix | `_sessionRepository`, `_computeReward()` |
| Bloc Events | Past tense verb | `SessionStarted`, `RpeFeedbackSubmitted`, `DailyPlanRegenerateRequested` |
| Bloc States | Noun or adjective | `DailyPlanLoaded`, `SessionInProgress`, `DailyPlanLoading` |
| Use cases | Verb phrase | `GenerateDailyPlan`, `SubmitRpeFeedback`, `GetSessionHistory` |
| Freezed unions | sealed class + factory constructors | `DailyPlanState.loading()`, `DailyPlanState.loaded(plan: plan)` |

**Drift Database Naming:**

| Element | Convention | Example |
|---|---|---|
| Tables | PascalCase (Dart class), maps to snake_case in SQL | `class Sessions extends Table` → `sessions` |
| Columns | camelCase (Dart), maps to snake_case in SQL | `IntColumn get sessionId` → `session_id` |
| Foreign keys | `{referenced_table_singular}Id` | `userId`, `sessionId` |
| Timestamps | `createdAt`, `updatedAt`, `cachedAt` | Standard for all tables with temporal data |
| DAOs | `{TableName}Dao` | `SessionsDao`, `BanditStateDao` |
| Database class | `AppDatabase` | Single database class in `lib/core/database/` |

**Go_Router Route Naming:**

| Element | Convention | Example |
|---|---|---|
| Route paths | kebab-case | `/today`, `/sessions`, `/progress`, `/in-session` |
| Named routes | camelCase static const | `static const today = 'today'`, `static const inSession = 'in-session'` |
| Route params | camelCase | `:sessionId` |
| Route file | `app_router.dart` in `lib/core/routing/` | Single router configuration file |

### Structure Patterns

**Feature-First Organization:**

Every feature follows the same internal structure. No exceptions.

```
lib/features/{feature_name}/
├── data/
│   ├── datasources/
│   │   ├── {feature}_remote_data_source.dart
│   │   └── {feature}_local_data_source.dart
│   ├── models/
│   │   └── {entity}_model.dart
│   └── repositories/
│       └── {feature}_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── {entity}.dart
│   ├── repositories/
│   │   └── {feature}_repository.dart
│   └── usecases/
│       └── {use_case_name}.dart
└── presentation/
    ├── bloc/
    │   ├── {feature}_bloc.dart
    │   ├── {feature}_event.dart
    │   └── {feature}_state.dart
    ├── pages/
    │   └── {feature}_page.dart
    └── widgets/
        └── {widget_name}.dart
```

**Core Layer Organization:**

```
lib/core/
├── constants/
│   └── api_constants.dart
├── database/
│   ├── app_database.dart
│   ├── tables/
│   └── daos/
├── di/
│   ├── injection.dart
│   └── injection.config.dart  (generated)
├── routing/
│   └── app_router.dart
├── theme/
│   ├── app_theme.dart
│   └── pulse_coach_theme.dart
├── error/
│   └── failures.dart
└── utils/
    └── date_utils.dart
```

**Test Organization (mirrors lib/ by layer):**

```
test/
├── domain/       # ~60 tests: use cases, entities, AI logic
│   ├── ai/       # Bandit, state machine, safety rules
│   └── usecases/
├── data/         # ~50 tests: repositories, caching, sync
│   ├── datasources/
│   └── repositories/
├── bloc/         # ~40 tests: state emissions, events
├── widget/       # ~30 tests: rendering, responsive, rotation
└── integration/  # ~20 tests: end-to-end flows
```

**Rule:** Test files mirror the source file path with `_test` suffix.

### Format Patterns

**API Response Handling:**

All remote datasources return DTOs. Repositories map DTOs → domain entities. Never expose DTOs beyond the data layer.

**Error Handling with Either:**

| Layer | Error Pattern |
|---|---|
| Remote datasource | Throws exceptions (`ServerException`, `CacheException`) |
| Repository | Catches exceptions, returns `Either<Failure, T>` |
| Use case | Passes `Either` through, may combine results |
| Bloc | Pattern-matches `Either` in event handler, emits success or failure state |
| UI | Renders based on state — never catches exceptions |

**Failure Types:**

```dart
abstract class Failure {}
class ServerFailure extends Failure { final String message; }
class CacheFailure extends Failure { final String message; }
class SensorFailure extends Failure { final String message; }
class LocationFailure extends Failure { final String message; }
```

**Date/Time Handling:**

- Internal: always `DateTime` (Dart native), UTC
- Drift storage: `DateTimeColumn` (stores as integer timestamp)
- API communication: ISO 8601 strings
- UI display: formatted via `intl` package to user locale
- Never store or compare `DateTime` as strings

**JSON Field Naming:**

- Dart models: camelCase (Dart convention)
- `@JsonKey(name: 'snake_case')` when API uses snake_case
- freezed handles this via `json_serializable` configuration

### Communication Patterns

**Bloc Event Naming:**

| Pattern | When | Example |
|---|---|---|
| `{Subject}{PastVerb}` | User action completed | `SessionStarted`, `RpeFeedbackSubmitted` |
| `{Subject}{Noun}Requested` | User requests something | `DailyPlanRegenerateRequested` |
| `{Subject}{Noun}Changed` | Value changed | `ThemeModeChanged`, `ProfileUpdated` |
| `{Subject}{Noun}Loaded` | Data loaded | `SessionHistoryLoaded` |

**Bloc State Pattern (freezed unions):**

Every bloc state uses the same union structure:

```dart
@freezed
class DailyPlanState with _$DailyPlanState {
  const factory DailyPlanState.initial() = DailyPlanInitial;
  const factory DailyPlanState.loading() = DailyPlanLoading;
  const factory DailyPlanState.loaded({required DailyPlan plan}) = DailyPlanLoaded;
  const factory DailyPlanState.error({required Failure failure}) = DailyPlanError;
}
```

Minimum states for every bloc: `initial`, `loading`, `loaded`, `error`.

**Dependency Injection Pattern:**

```dart
@injectable
class GenerateDailyPlan {
  final SessionRepository _sessionRepository;
  final AiEngine _aiEngine;
  GenerateDailyPlan(this._sessionRepository, this._aiEngine);
}

@Injectable(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository { ... }

@singleton
class AppDatabase { ... }
```

### Process Patterns

**Loading State Handling:**

- Every async operation starts by emitting `loading` state
- Loading state triggers shimmer placeholder in UI (no spinners, per UX spec)
- Minimum states: initial → loading → loaded | error
- No global loading state — each bloc manages its own

**Graceful Degradation Pattern:**

```
Try primary source (network/sensor)
  ├── Success → return data
  └── Failure → Try cache (drift)
                  ├── Cache valid (within TTL) → return cached data
                  └── Cache stale or missing → return bundled default
                                                 └── No default → return Failure
```

Rule: never show error UI for expected degradation. Sensor unavailable, API offline, WearOS disconnected — all handled silently.

**AI Engine Isolation Pattern:**

- AI computation always on a separate Dart Isolate via `compute()` or long-lived isolate
- Input: `StateVector` (serializable, freezed)
- Output: `DailyPlan` + `List<Explanation>` (serializable, freezed)
- No flutter imports in AI engine code — pure Dart only
- AI engine must be testable without Flutter framework

### Enforcement Guidelines

**All AI Agents MUST:**

1. Follow the feature-first folder structure exactly — no files outside the defined hierarchy
2. Use `freezed` for all domain entities and bloc states — no manual `==` or `hashCode`
3. Use `Either<Failure, T>` for all repository return types — no raw exception throwing past the data layer
4. Name bloc events in past tense, states as nouns — per the naming table above
5. Register all injectables via `@injectable` / `@singleton` annotations — no manual `get_it` registration
6. Keep AI engine code in pure Dart (no Flutter imports) — testable without widget framework
7. Cache all external API responses in drift with `cachedAt` column — no in-memory-only caching
8. Handle all sensor/API unavailability silently — never emit error state for expected degradation

**Anti-Patterns to Avoid:**

| Anti-Pattern | Correct Pattern |
|---|---|
| `throw Exception('...')` in repository | `return Left(ServerFailure('...'))` |
| Bloc state as simple class with mutable fields | `@freezed` sealed class with factory constructors |
| `if (mounted) setState(...)` | Bloc emits state, BlocBuilder rebuilds |
| Hardcoded API URL strings in datasource | Import from `api_constants.dart` |
| Test file in random location | Mirror `lib/` path with `_test.dart` suffix |
| Flutter imports in domain/AI layer | Pure Dart only — `import 'package:flutter/...';` forbidden |
| Manual `getIt.registerSingleton(...)` calls | `@singleton` annotation on class |
| Spinner/CircularProgressIndicator for loading | Shimmer placeholder matching content layout |

---

### Implementation Patterns & Consistency Rules — v2 Additions

> New conflict points introduced by cloud/auth/social/IAP/real-time code. The v1 patterns above still apply unchanged (feature-first folders, freezed states, `Either<Failure,T>`, shimmer loading, on-device AI isolation).

#### Naming Patterns — v2

**Supabase / Postgres naming:**

| Element | Convention | Example |
|---|---|---|
| Tables | `snake_case`, plural | `profiles`, `friendships`, `session_participants` |
| Columns | `snake_case` | `created_at`, `display_handle`, `visibility_tier` |
| Primary key | `id` (uuid) | `id uuid default gen_random_uuid()` |
| Foreign keys | `{singular}_id` | `owner_id`, `friend_id`, `shared_session_id` |
| RLS policies | `{table}_{action}_{principal}` | `profiles_select_friends`, `feed_insert_owner` |
| RPC / Edge Functions | `snake_case` verb phrase | `delete_account_cascade`, `validate_receipt`, `export_user_data` |
| Realtime channel | `shared-session:{sessionId}` | kebab namespace + colon + uuid |
| Broadcast event | `{noun}_{pastVerb}` | `step_advanced`, `participant_joined`, `session_ended` |

**Client mapping rule (unchanged boundary):** Supabase JSON is `snake_case`; v2 DTOs map to camelCase domain entities at the repository boundary via `@JsonKey(name: 'snake_case')` + freezed — DTOs never leave the data layer (same rule as v1 ExerciseDB/Open-Meteo).

#### Structure Patterns — v2

New feature modules follow the exact v1 feature-first structure (`data/{datasources,models,repositories}`, `domain/{entities,repositories,usecases}`, `presentation/{bloc,pages,widgets}`):

```
lib/features/
├── auth/            # sign-in, account, E2E backup/restore
├── subscription/    # IAP, entitlements, Pro gating
└── social/
    ├── friends/
    ├── feed/
    ├── leaderboard/
    └── shared_session/   # lobby, join, realtime sync
```

- Supabase client + cloud datasources live in `lib/core/cloud/` (`supabase_client.dart`, `realtime_gateway.dart`) — analogous to `lib/core/database/` for drift. Single Supabase client, registered `@singleton`.
- Edge Functions / SQL migrations live outside Flutter, in `supabase/` at repo root (`supabase/functions/`, `supabase/migrations/`) — version-controlled, reviewed in CI.
- Tests mirror as v1: `test/data/social/...`, `test/bloc/auth/...`; group-engine rules tested as pure-Dart in `test/domain/ai/group_constraint_test.dart` (deterministic, exhaustive — same discipline as v1 FR9 safety rules).

#### Format Patterns — v2

**New Failure types** (extend the v1 `Failure` hierarchy, same structural-equality rule):

```dart
class AuthFailure extends Failure { final String message; }
class SubscriptionFailure extends Failure { final String message; }
class SyncFailure extends Failure { final String message; }
class RealtimeFailure extends Failure { final String message; }
```

- Cloud datasources throw (`AuthException`, `SupabaseException`) → repositories catch → `Either<Failure,T>` (identical layering to v1).
- DateTime over the wire: ISO 8601 UTC strings (Supabase `timestamptz`); never integer timestamps in cloud JSON (drift-only convention stays local).
- E2E backup payload: ciphertext is an opaque base64 blob + non-secret metadata (`schemaVersion`, `createdAt`); no plaintext personal field is ever in a cloud row for backup.

#### Communication Patterns — v2

- New Blocs follow the freezed-union rule (`initial/loading/loaded/error` minimum): `AuthState`, `SubscriptionState`, `FriendsState`, `SharedSessionState`. Events past-tense (`SignInRequested`, `FriendRequestAccepted`, `StepAdvanced`).
- Real-time inbound: the `RealtimeGateway` exposes a Dart `Stream` of typed broadcast events; `SharedSessionBloc` subscribes (same pattern as v1 `SessionLogsDao.watchLogsForPlan` stream subscription). UI never touches the Supabase channel directly.
- Host authority: only the host emits `step_advanced`; followers render received state — they never advance locally (prevents divergence, NFR31).

#### Process Patterns — v2

**Three-tier gating (the v2 cross-cutting rule):**

```
EntitlementGate.check(feature)
  ├── account-free free  → v1 core always allowed
  ├── signed-in free     → + backup/restore, set handle, view leaderboard ranking
  └── Pro (active sub)   → + friends, feed, shared sessions, scoring, full Progress history
                            (grandfathered pre-v2 installs → full Progress history free)
```
- Locked-feature tap → contextual silent `ProUpsellSheet` (never a persistent banner — DESIGN rule).

**Cloud graceful degradation (extends the v1 pattern):**
```
Cloud op (auth/social/sync)
  ├── Online + entitled → execute
  ├── Offline → queue if it's an own-data write; otherwise show calm "non disponibile offline"
  └── v1 core path NEVER blocked by cloud/account/sub state (NFR34)
```

**Consent-before-write:** every cloud personal-data write checks the relevant per-purpose `consents` record first (NFR35). No consent → no write, no silent fallback to sending data.

**E2E rule:** personalization/biometric-derived state is encrypted client-side before any upload; the plaintext never reaches a Supabase row (NFR28). Agents must never add a "convenience" plaintext column for it.

#### Enforcement Guidelines — v2 (additions)

**All AI Agents MUST (v2):**
9. Map Supabase `snake_case` JSON → camelCase domain at the repository boundary; never leak Supabase DTOs past `data/`.
10. Enforce visibility via RLS at the DB; client checks are convenience only, never the security boundary (NFR29).
11. Route all feature access through `EntitlementGate`; never hardcode a Pro check inline in a widget.
12. Encrypt personal/biometric backup payloads client-side before upload; never persist them as plaintext cloud columns (NFR28).
13. Keep the v1 free/offline path reachable with zero cloud calls; never make a cloud/account/sub call a prerequisite for core flows (NFR34).
14. Test group-adaptation rules (FR70) as pure-Dart, exhaustively (min/lowest/union/shortest + per-user FR9 override).

**v2 Anti-Patterns:**

| Anti-Pattern | Correct Pattern |
|---|---|
| Client-side `if (isFriend)` as the only visibility guard | RLS policy at the DB; client is convenience |
| Plaintext bandit/RPE state in a Supabase column | Client-side E2E ciphertext blob |
| Follower advances session step locally | Only host emits `step_advanced`; followers render |
| Inline `if (user.isPro)` scattered in widgets | Single `EntitlementGate` consulted by router + widgets |
| Blocking the Today flow on a sign-in/sync call | v1 core runs with zero cloud dependency |
| Storing precise GPS for co-location | Momentary boolean only, not persisted (NFR33) |
| Cloud write without consent check | Check `consents` per purpose before any personal-data write |

## Project Structure & Boundaries

### Complete Project Directory Structure

```
pulse_coach/
├── .github/
│   └── workflows/
│       └── ci.yml                          # flutter analyze + flutter test
├── .gitignore
├── analysis_options.yaml                   # Strict linting rules
├── pubspec.yaml                            # All dependencies pinned
├── pubspec.lock
├── README.md
│
├── assets/
│   ├── animations/                         # Lottie files
│   │   ├── breathing.json
│   │   ├── mobility.json
│   │   ├── cardio.json
│   │   ├── onboarding_plan.json
│   │   ├── onboarding_privacy.json
│   │   └── onboarding_setup.json
│   ├── fonts/
│   └── data/
│       └── fallback_exercises.json         # Bundled exercise catalog fallback (NFR20)
│
├── lib/
│   ├── main.dart                           # App entry point, DI init, runApp
│   ├── app.dart                            # MaterialApp.router, theme, go_router
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart
│   │   │   ├── app_constants.dart
│   │   │   └── ai_constants.dart
│   │   ├── database/
│   │   │   ├── app_database.dart
│   │   │   ├── app_database.g.dart         # Generated
│   │   │   ├── sync_manager.dart            # Deferred sync queue processor
│   │   │   ├── tables/
│   │   │   │   ├── sessions_table.dart
│   │   │   │   ├── daily_plans_table.dart
│   │   │   │   ├── user_profile_table.dart
│   │   │   │   ├── rpe_feedback_table.dart
│   │   │   │   ├── bandit_state_table.dart
│   │   │   │   ├── behavioral_state_table.dart
│   │   │   │   ├── weather_cache_table.dart
│   │   │   │   ├── exercise_cache_table.dart
│   │   │   │   └── sync_queue_table.dart
│   │   │   └── daos/
│   │   │       ├── sessions_dao.dart
│   │   │       ├── daily_plans_dao.dart
│   │   │       ├── user_profile_dao.dart
│   │   │       ├── rpe_feedback_dao.dart
│   │   │       ├── bandit_state_dao.dart
│   │   │       ├── behavioral_state_dao.dart
│   │   │       ├── weather_cache_dao.dart
│   │   │       ├── exercise_cache_dao.dart
│   │   │       └── sync_queue_dao.dart
│   │   ├── di/
│   │   │   ├── injection.dart
│   │   │   └── injection.config.dart       # Generated
│   │   ├── error/
│   │   │   ├── exceptions.dart
│   │   │   └── failures.dart
│   │   ├── routing/
│   │   │   └── app_router.dart
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   └── pulse_coach_theme.dart
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── either_extensions.dart
│   │       └── location_service.dart        # City-level location for weather API
│   │
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── data/
│   │   │   │   └── repositories/
│   │   │   │       └── onboarding_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user_profile.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── onboarding_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── save_profile.dart
│   │   │   │       └── accept_disclaimer.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── onboarding_cubit.dart
│   │   │       │   └── onboarding_state.dart
│   │   │       ├── pages/
│   │   │       │   └── onboarding_page.dart
│   │   │       └── widgets/
│   │   │           ├── onboarding_screen.dart
│   │   │           ├── profile_setup_form.dart
│   │   │           └── disclaimer_checkbox.dart
│   │   │
│   │   ├── today/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── daily_plan_local_data_source.dart
│   │   │   │   └── repositories/
│   │   │   │       └── daily_plan_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── daily_plan.dart
│   │   │   │   │   ├── planned_session.dart
│   │   │   │   │   └── explanation.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── daily_plan_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── generate_daily_plan.dart
│   │   │   │       └── regenerate_daily_plan.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── daily_plan_bloc.dart
│   │   │       │   ├── daily_plan_event.dart
│   │   │       │   └── daily_plan_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── today_page.dart
│   │   │       │   └── today_page_tablet.dart
│   │   │       └── widgets/
│   │   │           ├── hero_session_card.dart
│   │   │           ├── compact_session_card.dart
│   │   │           ├── completed_session_card.dart
│   │   │           ├── state_indicator.dart
│   │   │           ├── explanation_line.dart
│   │   │           └── completion_ring.dart
│   │   │
│   │   ├── session/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── session_local_data_source.dart
│   │   │   │   │   └── sensor_data_source.dart        # Health API (HR, steps)
│   │   │   │   └── repositories/
│   │   │   │       └── session_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── session.dart
│   │   │   │   │   ├── exercise_step.dart
│   │   │   │   │   └── session_result.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── session_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── start_session.dart
│   │   │   │       ├── complete_session.dart
│   │   │   │       └── abandon_session.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── session_bloc.dart
│   │   │       │   ├── session_event.dart
│   │   │       │   └── session_state.dart
│   │   │       ├── pages/
│   │   │       │   └── in_session_page.dart
│   │   │       └── widgets/
│   │   │           ├── countdown_overlay.dart
│   │   │           ├── exercise_display.dart
│   │   │           ├── session_timer.dart
│   │   │           ├── rpe_input.dart
│   │   │           └── mini_summary.dart
│   │   │
│   │   ├── sessions_catalog/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── exercise_remote_data_source.dart
│   │   │   │   │   └── exercise_local_data_source.dart
│   │   │   │   ├── models/
│   │   │   │   │   └── exercise_model.dart
│   │   │   │   └── repositories/
│   │   │   │       └── exercise_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── exercise.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── exercise_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_exercises_by_type.dart
│   │   │   │       └── sync_exercise_catalog.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── sessions_catalog_cubit.dart
│   │   │       │   └── sessions_catalog_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── sessions_page.dart
│   │   │       │   └── sessions_page_tablet.dart
│   │   │       └── widgets/
│   │   │           └── session_catalog_card.dart
│   │   │
│   │   ├── progress/
│   │   │   ├── data/
│   │   │   │   ├── datasources/
│   │   │   │   │   └── progress_local_data_source.dart
│   │   │   │   └── repositories/
│   │   │   │       └── progress_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── progress_stats.dart
│   │   │   │   │   └── session_history_entry.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── progress_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── get_progress_stats.dart
│   │   │   │       └── get_session_history.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── progress_cubit.dart
│   │   │       │   └── progress_state.dart
│   │   │       ├── pages/
│   │   │       │   ├── progress_page.dart
│   │   │       │   └── progress_page_tablet.dart
│   │   │       └── widgets/
│   │   │           ├── minutes_per_week_chart.dart
│   │   │           ├── completion_rate_chart.dart
│   │   │           ├── rpe_trend_chart.dart
│   │   │           └── session_type_breakdown_chart.dart
│   │   │
│   │   ├── settings/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── theme_cubit.dart
│   │   │       │   └── theme_state.dart
│   │   │       ├── pages/
│   │   │       │   └── settings_page.dart
│   │   │       └── widgets/
│   │   │           ├── profile_section.dart
│   │   │           ├── theme_toggle.dart
│   │   │           ├── privacy_info.dart
│   │   │           └── debug_section.dart
│   │   │
│   │   └── weather/
│   │       ├── data/
│   │       │   ├── datasources/
│   │       │   │   ├── weather_remote_data_source.dart
│   │       │   │   └── weather_local_data_source.dart
│   │       │   ├── models/
│   │       │   │   ├── weather_model.dart
│   │       │   │   └── aqi_model.dart
│   │       │   └── repositories/
│   │       │       └── weather_repository_impl.dart
│   │       └── domain/
│   │           ├── entities/
│   │           │   └── weather_context.dart
│   │           ├── repositories/
│   │           │   └── weather_repository.dart
│   │           └── usecases/
│   │               └── get_weather_context.dart
│   │
│   ├── ai/                                 # Pure Dart — NO Flutter imports
│   │   ├── engine/
│   │   │   ├── ai_engine.dart
│   │   │   └── ai_engine_isolate.dart
│   │   ├── bandit/
│   │   │   ├── contextual_bandit.dart
│   │   │   ├── bandit_state.dart
│   │   │   ├── reward_calculator.dart
│   │   │   └── state_vector.dart
│   │   ├── state_machine/
│   │   │   ├── behavioral_state_machine.dart
│   │   │   ├── behavioral_state.dart
│   │   │   └── recommendation_policy.dart
│   │   ├── safety/
│   │   │   └── safety_rules.dart
│   │   └── explainability/
│   │       └── explanation_generator.dart
│   │
│   └── shared/
│       └── widgets/
│           ├── responsive_scaffold.dart
│           ├── shimmer_placeholder.dart
│           └── adaptive_navigation.dart
│
├── wear/                                    # WearOS companion (separate target)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── session_display_page.dart
│   │   ├── rest_display_page.dart
│   │   ├── summary_display_page.dart
│   │   └── communication/
│   │       └── phone_bridge.dart
│   └── pubspec.yaml
│
├── test/
│   ├── domain/                              # ~60 tests
│   │   ├── ai/
│   │   │   ├── contextual_bandit_test.dart
│   │   │   ├── behavioral_state_machine_test.dart
│   │   │   ├── safety_rules_test.dart
│   │   │   ├── reward_calculator_test.dart
│   │   │   ├── explanation_generator_test.dart
│   │   │   └── ai_engine_test.dart
│   │   └── usecases/
│   │       ├── generate_daily_plan_test.dart
│   │       ├── start_session_test.dart
│   │       ├── submit_rpe_feedback_test.dart
│   │       └── get_weather_context_test.dart
│   ├── data/                                # ~50 tests
│   │   ├── datasources/
│   │   │   ├── weather_remote_data_source_test.dart
│   │   │   ├── exercise_remote_data_source_test.dart
│   │   │   └── weather_local_data_source_test.dart
│   │   └── repositories/
│   │       ├── daily_plan_repository_impl_test.dart
│   │       ├── session_repository_impl_test.dart
│   │       ├── weather_repository_impl_test.dart
│   │       └── exercise_repository_impl_test.dart
│   ├── bloc/                                # ~40 tests
│   │   ├── daily_plan_bloc_test.dart
│   │   ├── session_bloc_test.dart
│   │   ├── progress_cubit_test.dart
│   │   ├── onboarding_cubit_test.dart
│   │   └── theme_cubit_test.dart
│   ├── widget/                              # ~30 tests
│   │   ├── hero_session_card_test.dart
│   │   ├── rpe_input_test.dart
│   │   ├── countdown_overlay_test.dart
│   │   ├── completion_ring_test.dart
│   │   ├── responsive_scaffold_test.dart
│   │   └── today_page_test.dart
│   ├── integration/                         # ~20 tests
│   │   ├── session_flow_test.dart
│   │   ├── onboarding_flow_test.dart
│   │   └── daily_plan_generation_test.dart
│   └── helpers/
│       ├── mock_helpers.dart
│       ├── fake_clock.dart
│       └── test_data.dart
│
└── integration_test/
    └── app_test.dart
```

### Architectural Boundaries

**Layer Boundaries (strict):**

```
┌──────────────────────────────────────────┐
│  PRESENTATION (Flutter)                   │
│  Pages, Widgets, Blocs/Cubits             │
│  ↓ depends on Domain only                 │
├──────────────────────────────────────────┤
│  DOMAIN (Pure Dart)                       │
│  Entities (freezed), Use Cases,           │
│  Repository interfaces (abstract)         │
│  ↓ depends on nothing                     │
├──────────────────────────────────────────┤
│  DATA (Dart + packages)                   │
│  Repository impls, DTOs, Datasources      │
│  ↓ implements Domain interfaces           │
├──────────────────────────────────────────┤
│  AI ENGINE (Pure Dart — NO Flutter)       │
│  Bandit, State Machine, Safety Rules      │
│  ↓ consumed by Domain use cases           │
├──────────────────────────────────────────┤
│  CORE (Dart + Flutter)                    │
│  DI, Database, Routing, Theme, Errors     │
└──────────────────────────────────────────┘
```

**Import Rules:**

| From | Can Import | Cannot Import |
|---|---|---|
| Presentation | Domain, Core, Shared widgets | Data |
| Domain | Nothing | Presentation, Data, Core, Flutter |
| Data | Domain, Core | Presentation |
| AI Engine | Nothing | Flutter, Presentation, Data, Core |
| Core | Dart/Flutter packages only | Features, Domain, Data |

**External Integration Boundaries:**

| Integration | Boundary File | Direction |
|---|---|---|
| Open-Meteo API | `weather_remote_data_source.dart` | Outbound HTTP |
| ExerciseDB API | `exercise_remote_data_source.dart` | Outbound HTTP |
| Health API | Sensor datasource in session feature | Inbound sensor |
| WearOS | `phone_bridge.dart` (wear target) | Bidirectional |
| Drift DB | DAOs in `core/database/daos/` | Local persistence |

### Requirements to Structure Mapping

| Feature | FRs Covered | Directory |
|---|---|---|
| Onboarding | FR1-FR4 | `lib/features/onboarding/` |
| Today / Daily Plan | FR5-FR15 | `lib/features/today/` |
| Session Execution | FR16-FR21 | `lib/features/session/` |
| Feedback & Adaptation | FR21-FR25 | `lib/features/session/` + `lib/ai/` |
| Exercise Catalog | FR26-FR28 | `lib/features/sessions_catalog/` |
| Progress & History | FR29-FR32 | `lib/features/progress/` |
| Weather/AQI | FR33-FR36 | `lib/features/weather/` |
| Multi-Device | FR37-FR39 | `lib/shared/widgets/` |
| WearOS | FR40-FR41 | `wear/` |
| Sensors | FR42-FR44 | `lib/features/session/data/` |
| Offline | FR45-FR47 | `lib/core/database/` + repositories |
| Settings | FR48-FR52 | `lib/features/settings/` |

**AI Engine Mapping:**

| Component | FRs/NFRs | File |
|---|---|---|
| Safety rules | FR9 | `lib/ai/safety/safety_rules.dart` |
| Contextual bandit | FR10, FR22 | `lib/ai/bandit/contextual_bandit.dart` |
| State machine | FR14, FR23-FR24 | `lib/ai/state_machine/behavioral_state_machine.dart` |
| RPE feedback loop | FR21-FR22 | `lib/ai/bandit/reward_calculator.dart` |
| Explainability | FR13-FR15 | `lib/ai/explainability/explanation_generator.dart` |
| Isolate execution | NFR1-NFR2 | `lib/ai/engine/ai_engine_isolate.dart` |

### Data Flow

```
User opens app
    │
    ▼
DailyPlanBloc ── GenerateDailyPlan (use case)
    │                    │
    │         ┌──────────┼──────────┐
    │         ▼          ▼          ▼
    │    WeatherRepo  ExerciseRepo  SessionRepo
    │    (cache/API)  (cache/API)   (drift)
    │         └──────────┼──────────┘
    │                    ▼
    │              AiEngineIsolate.compute()
    │                    │
    │         ┌──────────┼──────────┐
    │         ▼          ▼          ▼
    │    SafetyRules  Bandit    StateMachine
    │         └──────────┼──────────┘
    │                    ▼
    │         DailyPlan + Explanations
    │                    │
    ▼                    ▼
UI renders HeroSessionCard + CompactSessionCards
    │
    ▼ (user taps Start)
SessionBloc ── StartSession
    │
    ▼ (session completes)
SessionBloc ── CompleteSession → RPE → Reward → Bandit update
    │
    ▼
DailyPlanBloc re-evaluates → next hero
```

### Development Workflow

| Command | Purpose |
|---|---|
| `flutter create --platforms=android,ios --org com.pulsecoach pulse_coach` | Initial project creation |
| `dart run build_runner build --delete-conflicting-outputs` | Generate drift, freezed, injectable code |
| `dart run build_runner watch` | Watch mode for code generation |
| `flutter run` | Run on device/emulator |
| `flutter test` | Run all tests |
| `flutter test --coverage` | Tests with coverage |
| `flutter analyze` | Linter |

---

### Project Structure & Boundaries — v2 Additions

**New directories (extend the existing tree):**

```
pulse_coach/
├── lib/
│   ├── core/
│   │   └── cloud/                          # NEW — Supabase boundary (mirrors core/database/)
│   │       ├── supabase_client.dart        # @singleton; init with EU URL + publishable key
│   │       ├── realtime_gateway.dart       # Broadcast/Presence → typed Dart Stream
│   │       ├── entitlement_gate.dart        # account-free / signed-in / Pro resolver
│   │       └── crypto/
│   │           └── e2e_backup_codec.dart   # encrypt/decrypt user-keyed backup blob
│   │
│   ├── features/
│   │   ├── auth/                            # NEW — FR54–57, FR77
│   │   │   ├── data/{datasources,models,repositories}/
│   │   │   ├── domain/{entities,repositories,usecases}/   # sign_in, sign_out, backup, restore, delete_account
│   │   │   └── presentation/
│   │   │       ├── bloc/ (auth_bloc, auth_event, auth_state)
│   │   │       ├── pages/ (sign_in_page, account_page)
│   │   │       └── widgets/ (sign_in_sheet, backup_settings)
│   │   │
│   │   ├── subscription/                    # NEW — FR58–62
│   │   │   ├── data/ (revenuecat datasource, entitlement repo impl)
│   │   │   ├── domain/ (entitlement, usecases: purchase, restore, check_entitlement)
│   │   │   └── presentation/ (subscription_bloc, paywall_page, widgets/pro_upsell_sheet)
│   │   │
│   │   └── social/                          # NEW — FR63–76
│   │       ├── friends/    (data/domain/presentation — friend_row, add_friend)
│   │       ├── feed/       (activity_feed_card, comparison)
│   │       ├── leaderboard/(leaderboard_row, scoring)
│   │       └── shared_session/
│   │           ├── data/ (realtime datasource, shared_session repo impl)
│   │           ├── domain/ (group_constraint, usecases: create/join/advance)
│   │           └── presentation/ (shared_session_bloc, lobby_page, widgets/join_code_card, visibility_tier_selector)
│   │
│   └── ai/
│       └── safety/
│           └── group_constraint_resolver.dart   # NEW — FR70 deterministic group rules (pure Dart)
│
├── supabase/                                # NEW — backend artifacts, outside Flutter
│   ├── config.toml
│   ├── migrations/                          # SQL schema + RLS policies (version-controlled)
│   │   ├── 0001_profiles_friendships.sql
│   │   ├── 0002_shared_sessions.sql
│   │   ├── 0003_leaderboard.sql
│   │   └── 0004_consents.sql
│   └── functions/                           # Edge Functions (Deno/TS)
│       ├── validate_receipt/
│       ├── delete_account_cascade/
│       └── export_user_data/
│
├── test/
│   ├── domain/ai/
│   │   └── group_constraint_resolver_test.dart   # NEW — exhaustive FR70 (pure Dart)
│   ├── data/
│   │   ├── auth/ (auth_repository_impl_test, e2e_backup_codec_test)
│   │   └── social/ (shared_session_repository_impl_test, friends_repository_impl_test)
│   └── bloc/
│       ├── auth_bloc_test.dart
│       ├── subscription_bloc_test.dart
│       └── shared_session_bloc_test.dart
```

**v2 Architectural Boundaries:**

- New layer: CLOUD sits beside CORE — `lib/core/cloud/` is the only place that imports `supabase_flutter`. Repositories depend on cloud datasources, never on the Supabase client directly. Same dependency-inversion rule as drift.
- Import rules (extend the v1 table):

| From | Can Import | Cannot Import |
|---|---|---|
| Cloud (`core/cloud/`) | Dart/Flutter + `supabase_flutter` | Features, Domain, Data |
| Features (auth/social/subscription) | Domain, Core (incl. Cloud gateway), Shared widgets | Data of other features, raw Supabase client |
| AI `group_constraint_resolver` | Nothing (pure Dart) | Flutter, Supabase, Data |

- Security boundary = RLS at Supabase, not the client. The client `EntitlementGate` and visibility checks are convenience/UX only.
- External integration boundaries (additions):

| Integration | Boundary File | Direction |
|---|---|---|
| Supabase Auth | `auth_remote_data_source.dart` | Bidirectional |
| Supabase Postgres (social) | `*_remote_data_source.dart` (per social feature) | Bidirectional via PostgREST |
| Supabase Realtime | `realtime_gateway.dart` | Bidirectional (broadcast/presence) |
| RevenueCat / Store IAP | `subscription_remote_data_source.dart` | Bidirectional |
| Supabase Storage (E2E backup) | `e2e_backup_codec.dart` + auth datasource | Outbound (ciphertext only) |

**Requirements → Structure Mapping (v2):**

| Feature | FRs Covered | Directory |
|---|---|---|
| Navigation fix | FR53 | `lib/core/routing/app_router.dart` |
| Accounts & Auth & Backup | FR54–57, FR77 | `lib/features/auth/` + `core/cloud/crypto/` |
| Subscriptions / Pro gating | FR58–62 | `lib/features/subscription/` + `core/cloud/entitlement_gate.dart` |
| Friends & Feed | FR63–67 | `lib/features/social/{friends,feed}/` |
| Shared live sessions | FR68–73 | `lib/features/social/shared_session/` + `core/cloud/realtime_gateway.dart` |
| Group adaptation | FR70 | `lib/ai/safety/group_constraint_resolver.dart` |
| Leaderboard & scoring | FR74–76 | `lib/features/social/leaderboard/` |
| Privacy/consent/erasure | NFR29/30/35 | `supabase/migrations/` (RLS) + `supabase/functions/` |

**Data Flow — Shared Live Session (v2):**

```
Host taps "Shared session"
   │
   ▼
SharedSessionBloc ── CreateSharedSession → shared_sessions row + JoinCodeCard (code+QR)
   │
Friend scans QR → JoinSharedSession
   │   └─ momentary geolocator check → boolean co-located (not stored)
   ▼
RealtimeGateway: channel `shared-session:{id}` (Presence = lobby)
   │
GroupConstraintResolver (pure Dart): min cap / lowest level / union exclusions / shortest duration
   │   └─ each participant's FR9 safety still applies
   ▼
One shared plan + adaptation explanation → SharedSessionLobby
   │
Host taps Start → broadcast `step_advanced` ──▶ all followers render (host authority)
   │
Each participant completes → own RPE → feeds ONLY own on-device bandit
   │
   ▼
leaderboard_entries (+ shared-session point bonus) — Edge Function scoring
```

**Development Workflow (additions):**

| Command | Purpose |
|---|---|
| `supabase init` / `supabase start` | Local backend + EU project scaffold |
| `supabase migration new <name>` | New SQL migration (schema + RLS) |
| `supabase functions deploy <fn>` | Deploy Edge Function |

---

## Step 7 — Validation Report

### Validation Checklist

| # | Check | Status |
|---|---|---|
| 1 | Every FR (FR1–FR52) mapped to a specific directory/file | ✅ Pass |
| 2 | Every NFR (NFR1–NFR26) addressed by an architectural decision or pattern | ✅ Pass |
| 3 | All PRD domain entities have corresponding drift tables + DAOs | ✅ Pass |
| 4 | All external APIs have datasource + repository + caching strategy | ✅ Pass |
| 5 | AI engine components (bandit, state machine, safety rules) mapped to `lib/core/ai/` | ✅ Pass |
| 6 | Sensor access mapped to datasources with graceful degradation | ✅ Pass |
| 7 | WearOS companion target has clear boundary (display-only, no AI logic) | ✅ Pass |
| 8 | Dual layout strategy defined (phone <600dp vs tablet ≥600dp) | ✅ Pass |
| 9 | Offline-first data flow consistent (drift primary, sync queue, TTL caching) | ✅ Pass |
| 10 | Test strategy covers all 5 layers with realistic counts summing to 150–200 | ✅ Pass |
| 11 | Threading model documented (Isolates for AI, compute() for heavy, async for I/O) | ✅ Pass |
| 12 | DI strategy consistent (get_it + injectable, @singleton for DB, @injectable for use-cases) | ✅ Pass |
| 13 | Error handling consistent (Either<Failure, T> via dartz, typed failures) | ✅ Pass |
| 14 | Privacy constraints respected (no cloud, no auth, city-level location, GDPR Art. 9) | ✅ Pass |
| 15 | Project structure tree complete — no referenced files missing | ✅ Pass (after fixes) |

### Gaps Found and Resolved

| # | Gap | Resolution |
|---|---|---|
| 1 | `sensor_data_source.dart` missing from session feature datasources | Added to `lib/features/session/data/datasources/` |
| 2 | `location_service.dart` not placed in project structure | Added to `lib/core/utils/` |
| 3 | `sync_manager.dart` not mapped in project structure | Added to `lib/core/database/` |
| 4 | `dartz` package missing from Key Package Versions table | Added to packages table |

### Coherence Assessment

**Internal coherence:** All architectural decisions reference each other consistently. The data flow (UI → Bloc → UseCase → Repository → DataSource/DAO) is uniform across all features. The AI engine boundary is clean — pure Dart with no Flutter imports, communicable only through use-cases.

**PRD alignment:** 52/52 functional requirements and 26/26 non-functional requirements have explicit mapping to architectural components. No orphan requirements.

**UX spec alignment:** All 12 custom components from the UX specification (HeroSessionCard, RPEInput, CompletionRing, etc.) map to `lib/shared/widgets/` or feature-specific presentation layers. The responsive strategy (breakpoints, NavigationBar vs NavigationRail) is architecturally supported.

**Implementation readiness:** The architecture provides sufficient detail for a developer to begin implementation without ambiguity on structure, patterns, naming conventions, or data flow. Code templates for Bloc states, repository patterns, DI registration, and error handling are provided.

**Overall validation result: ✅ PASS** — Architecture is complete, coherent, and implementation-ready.

---

### Step 7 — Validation Report (v2 Addendum)

#### v2 Requirements Coverage

| Req | Covered by | Status |
|---|---|---|
| FR53 nav fix | `app_router.dart` return affordance | ✅ |
| FR54–55 auth | Supabase Auth + `features/auth/` | ✅ |
| FR56 account-optional | `EntitlementGate` account-free tier; NFR11 preserved | ✅ |
| FR57 E2E backup/restore | `e2e_backup_codec.dart` + Supabase Storage (ciphertext) | ✅ |
| FR58–60 IAP/restore/cancel | `features/subscription/` + RevenueCat + store | ✅ |
| FR61 free/Pro Progress + grandfathering | `EntitlementGate` + `installCohort` (drift + profile) | ✅ |
| FR62 gating seam | Handle/leaderboard-view free; social create Pro | ✅ |
| FR63 handle + privacy-by-default | `profiles` + RLS default `private` | ✅ |
| FR64–67 friends/feed/compare | `social/{friends,feed}/` + RLS | ✅ |
| FR68–69 create/join + co-location | `shared_session/` + `realtime_gateway` + momentary `geolocator` | ✅ |
| FR70 group adaptation | `group_constraint_resolver.dart` (pure Dart, deterministic) | ✅ |
| FR71 real-time sync | Broadcast/Presence, host authority | ✅ |
| FR72 per-participant RPE | each feeds own on-device bandit | ✅ |
| FR73 shared-session gating | `EntitlementGate` + friends + location + age | ✅ |
| FR74–76 leaderboard/scoring | `social/leaderboard/` + scoring Edge Function | ✅ |
| FR77 in-app account deletion | `delete_account` usecase + `delete_account_cascade` fn | ✅ |
| NFR27 auth security | OAuth/OIDC + `flutter_secure_storage` + TLS | ✅ |
| NFR28 on-device + E2E | engine stays local; ciphertext-only upload | ✅ |
| NFR29 visibility tiers | RLS at DB | ✅ |
| NFR30 export + erasure cascade | `export_user_data` + `delete_account_cascade` (≤30d) | ✅ |
| NFR31 ~1s sync + drop-out | Broadcast + Presence tolerance | ✅ |
| NFR32 store/billing | IAP + Apple parity + privacy labels | ✅ |
| NFR33 momentary co-location | boolean only, not stored | ✅ |
| NFR34 offline-first preserved | v1 core never blocked by cloud | ✅ |
| NFR35 unbundled consent | `consents` table + consent-before-write | ✅ |
| NFR36 EU residency | Supabase EU region | ✅ |
| NFR37 minimum age | confirmed at registration (auth) | ⚠️ Partial — see gaps |

#### Coherence Assessment (v1 ↔ v2)

- No contradiction with shipped v1. Cloud is additive; the on-device engine, drift-as-source-of-truth, offline-first, and the `Either<Failure,T>`/freezed/feature-first patterns are all reused, not replaced. The only AI-layer change is the additive `GroupConstraint` interface.
- NFR reconciliations honored. NFR11/NFR7/NFR17/NFR8 conflicts resolved exactly as the PRD decision-log specifies (free tier = account-free; biometrics E2E/on-device; backup for signed-in; co-location momentary).
- Privacy thesis intact. RLS + per-purpose consent + E2E + EU region + counter-metrics keep the v1 differentiator under the new social surface.

#### v2 Gaps Found

| Priority | Gap | Disposition |
|---|---|---|
| Minor | NFR37 min-age placement not yet a concrete component | Add age-confirmation step in `auth` registration usecase; final per-market value is a business open item |
| Minor | Offline write queue for own-data social writes referenced in patterns but not a structural file | Reuse/extend existing `sync_manager.dart` (`core/database/`) for v2 cloud write queue |
| Open (non-blocking) | Point formula + anti-abuse (FR75) | Deferred to design (PRD addendum) |
| Open (non-blocking) | Pro price/tiers | Business decision |
| Open (non-blocking) | WearOS shared-session participant vs mirror (FR71 `[ASSUMPTION]`) | Defaulted to mirror; confirm later |
| Accepted risk | CLOUD Act exposure (US-corp BaaS) | Mitigated by E2E (biometric state) + EU region + minimal PII; self-host-in-EU exit path documented |

#### v2 Completeness Checklist

- [x] v2 context analyzed, scale re-assessed (High → Enterprise-leaning)
- [x] v2 constraints + cross-cutting concerns mapped
- [x] Backend platform decided (Supabase, EU) with versions web-verified
- [x] Auth / data / real-time / IAP / E2E / infra decisions documented
- [x] v2 naming / structure / format / communication / process patterns defined
- [x] v2 directory tree, boundaries, requirements→structure mapping complete
- [x] v2 data flow (shared session, E2E backup, IAP) specified
- [ ] All v2 NFRs fully placed structurally — NFR37 age + offline queue are minor open placements

#### v2 Readiness Assessment

**Overall Status (v2): READY WITH MINOR GAPS** — no critical/blocking gap; the two minor placements (NFR37 age confirmation, cloud write queue) are small and localized, and the remaining open items are explicitly business/design deferrals from the PRD, not architecture holes.

**Confidence:** High.

**Key strengths:** additive design preserves shipped v1; RLS maps privacy declaratively; on-device AI + E2E keeps the privacy thesis; phasing (v2.0→v2.5) is independently shippable.

**Implementation handoff — first v2 priority:** v2.0 navigation fix (pure client), then v2.1 Supabase EU project init (`supabase init`) + Auth + `EntitlementGate` skeleton + E2E backup + in-app account deletion.

---

## v2 Rework — Completion Note (2026-06-20)

This document was reworked on 2026-06-20 to integrate the **v2 — Accounts, Subscriptions & Social** scope (PRD `v2-final`, addendum, and the 2026-06-20 UX `DESIGN.md`/`EXPERIENCE.md`). The original v1 architecture (2026-03-27, implemented through Epic 5–14) is preserved unchanged; every v2 section is additive and reconciles with the shipped v1 rather than overwriting it.

**v2 decisions of record:** Supabase (EU region) backend · Supabase Auth (email/Apple/Google) · Postgres + RLS for the social graph and visibility tiers · Realtime Broadcast/Presence for co-located shared sessions · client-side E2E-encrypted, user-keyed backup · platform IAP (RevenueCat) with grandfathering · deterministic `GroupConstraint` layered on the existing on-device engine.

**Status:** READY WITH MINOR GAPS — no blocking gaps; open items are PRD-deferred business/design decisions (Pro price, point formula, WearOS mirror, final min-age).
