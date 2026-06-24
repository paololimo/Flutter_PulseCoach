---
stepsCompleted:
  - "step-01-validate-prerequisites"
  - "step-02-extract-requirements"
  - "step-03-create-epics-and-stories"
  - "step-03-v2-extend-epics"
inputDocuments:
  - "_bmad-output/planning-artifacts/prd.md"
  - "_bmad-output/planning-artifacts/architecture.md"
  - "_bmad-output/planning-artifacts/ux-design-specification.md"
  - "_bmad-output/planning-artifacts/ux-designs/ux-Flutter_PulseCoach-2026-06-20/DESIGN.md"
  - "_bmad-output/planning-artifacts/ux-designs/ux-Flutter_PulseCoach-2026-06-20/EXPERIENCE.md"
  - "_bmad-output/planning-artifacts/addendum.md"
v2ExtendedAt: "2026-06-20"
---

# Flutter_PulseCoach - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for Flutter_PulseCoach, decomposing the requirements from the PRD, UX Design, and Architecture documents into implementable stories.

## Requirements Inventory

### Functional Requirements

FR1: New user can view an animated onboarding flow explaining the app concept, privacy approach, and setup process
FR2: New user can create a profile by specifying fitness level, primary goal, available time per session, and physical constraints
FR3: New user must accept a non-skippable medical disclaimer before accessing any app functionality
FR4: User can view and edit their profile and goals at any time
FR5: System generates a daily plan of 3 personalized micro-sessions (2-10 minutes each) based on the user's current state
FR6: System incorporates physiological inputs (resting HR, step count, RPE history) into session selection when available
FR7: System incorporates environmental inputs (weather, temperature, precipitation, AQI) into session selection
FR8: System routes sessions indoor or outdoor based on real-time AQI thresholds and weather conditions
FR9: System applies deterministic safety rules that override bandit recommendations (e.g., RPE avg >8 for 2 consecutive sessions → block high intensity)
FR10: System adapts session type, intensity, and duration over time using a contextual bandit learning algorithm
FR11: User can regenerate the daily plan on demand
FR12: System initializes new users with a plan capped at intensity level ≤ Low and session count = 3, derived from their onboarding fitness level and goal
FR13: Every session recommendation displays a structured explanation of why the system chose that specific session
FR14: System displays human-readable messages when the behavioral state machine transitions (e.g., entering Recovering state)
FR15: User can view their current behavioral state (Active, Fatigued, AtRisk, Recovering)
FR16: User can start any planned session with a single tap
FR17: System displays a full-screen guided session with timer, current exercise step, and step-by-step instructions
FR18: System provides haptic feedback on exercise step transitions
FR19: System displays live heart rate during active sessions when sensor data is available
FR20: User can complete or abandon a session at any time
FR21: User can submit post-session RPE feedback (1-10 scale) after completing or abandoning a session
FR22: System adjusts future session intensity based on RPE feedback, targeting rolling average ≈ 6.5
FR23: System transitions behavioral state based on missed sessions, RPE trends, and streak patterns
FR24: System reduces session count and intensity when user is in Recovering or AtRisk state
FR25: System preserves bandit learning history across state machine transitions
FR26: System populates session content from an external exercise catalog (ExerciseDB)
FR27: User can browse available sessions filtered by type (mobility, cardio, breathing)
FR28: System caches exercise catalog data locally for offline access
FR29: User can view session history as a timeline of completed sessions
FR30: User can view progress charts: minutes per week, completion rate, RPE trend, session type breakdown
FR31: User can view weekly goal progress (sessions completed vs target)
FR32: Progress charts display with animated transitions
FR33: System retrieves real-time weather data (temperature, precipitation) from Open-Meteo API
FR34: System retrieves real-time air quality index from Open-Meteo API
FR35: System uses approximate city-level location for API calls, not precise GPS coordinates
FR36: System defaults to indoor sessions when AQI data is stale (>2h) or unavailable
FR37: Phone displays bottom tab navigation (Today, Sessions, Progress) with drawer menu
FR38: Tablet displays side NavigationRail with master-detail layouts and dashboard grid
FR39: All key screens support both portrait and landscape orientation
FR40: WearOS companion displays current exercise step, session timer, and live HR during active sessions
FR41: WearOS companion displays post-session summary
FR42: System reads resting heart rate and daily step count from device Health API when permissions granted
FR43: System detects activity via accelerometer when available
FR44: System operates in RPE-only mode when sensor permissions are denied, with full functionality preserved
FR45: All core features (plan generation, session execution, RPE feedback, progress viewing) function without network connectivity
FR46: System caches weather/AQI data with TTL and exercise catalog data locally
FR47: System syncs data via deferred event queue when connectivity returns
FR48: User can toggle dark mode or follow system theme
FR49: User can view privacy and data information
FR50: User can access device and sync settings
FR51: User can view an AI Decision Log showing bandit decision history (state vector → action → reward) [MVP-if-time]
FR52: User can export session history and AI decisions as CSV/JSON [MVP-if-time]

### v2 Functional Requirements (FR53–FR77)

**v2.0 — Navigation Fix**
FR53: Every secondary screen reached from the drawer (Settings, Profile, Privacy, Debug) provides an explicit affordance to return to the primary screens without restarting the app

**v2.1 — Accounts & Authentication**
FR54: User can create a cloud account using email + password, Sign in with Apple, or Google Sign-In
FR55: User can sign in, sign out, and reset a forgotten password (email flow)
FR56: The app remains fully usable without an account — the v1 free, offline, local-only experience is preserved
FR57: When signed in, the user can opt in to back up and restore their profile, session history, and personalization state; the backup is end-to-end encrypted with a user-held key (biometric-derived state never readable server-side)

**v2.2 — Subscriptions (Pro)**
FR58: User can view subscription plans and purchase a Pro subscription via platform store billing (App Store / Play Store IAP)
FR59: System gates Pro-only features behind an active subscription; the free tier retains the full v1 core
FR60: User can restore purchases and manage or cancel the subscription via the platform store
FR61: Free tier limits Progress to the most recent session + current weekly goal; Pro unlocks full historical timeline + all charts. Pre-v2 installs (grandfathered) retain full Progress history for free
FR62: Social features (FR64–FR75) require an active Pro subscription; setting a username/handle (FR63) and viewing leaderboard ranking (FR76) are free

**v2.3 — Social: Friends & Feed**
FR63: User can set a unique username/handle and a shareable profile; privacy by default (private until explicit opt-in)
FR64: User can add friends by username, QR code/invite link, or phone contacts (with permission)
FR65: User can send, accept, decline friend requests, and remove friends
FR66: User can share completed-session progress with friends and view a friends activity feed
FR67: User can compare their progress against friends'

**v2.4a — Real-Time Transport (prerequisite for v2.4b)**
FR71: During a shared live session, all participants see a synchronized session state (current step + timer) in real time; WearOS mirrors the owning participant's synchronized view

**v2.4b — Social: Co-Located Live Shared Sessions**
FR68: User can create a shared live session and invite co-located friends via a join code / QR
FR69: A friend joins a shared session by entering the join code / scanning the QR in person; the system uses device location as a soft, momentary, non-stored co-location confirmation (non-blocking — NFR33)
FR70: System generates a single shared session plan safe for every participant via deterministic group rules: intensity ceiling = min of participants' caps; fitness level = lowest present; movement exclusion = union of constraints; duration = shortest preference; each participant's v1 FR9 safety rules still apply on top
FR72: Each participant submits their own post-session RPE; each rating feeds only that participant's own on-device personalization
FR73: Shared sessions require: (a) active Pro subscription, (b) registered account, (c) the other participants in the user's friends list, (d) location enabled, and (e) minimum age NFR37

**v2.5 — Social: Leaderboard & Scoring**
FR74: System awards points for completed sessions and maintains a friends leaderboard
FR75: Shared (co-located) sessions award more points than solo sessions
FR76: User can view the friends leaderboard ranking

**v2.1 — In-App Account Deletion (store-blocking, ships with accounts)**
FR77: User can delete their account and all associated server data from within the app (not only via a web flow); deletion is initiated in-app, confirmed, and cascades per NFR30

### NonFunctional Requirements

NFR1: Daily plan generation completes in < 30 seconds from app open, including AI computation on a background thread isolated from the UI thread
NFR2: UI maintains ≥ 60fps / ≤ 16ms frame budget during AI computation — the UI thread must never block as measured by Flutter DevTools frame rendering
NFR3: Session timer accuracy within ±1 second over the session duration
NFR4: Haptic feedback on exercise step transitions fires within 200ms of step change
NFR5: Weather/AQI API response cached and served from local DB in < 500ms when offline
NFR6: App cold start to Today screen in < 3 seconds on mid-range Android device (2022+)
NFR7: All health and biometric data stored exclusively on-device — zero transmission to external servers for personalization
NFR8: Location data sent to Open-Meteo API is approximate city-level only — no precise GPS coordinates transmitted
NFR9: Health API permissions requested with clear user-facing explanation; denial handled gracefully with RPE-only fallback
NFR10: Medical disclaimer acceptance state persisted locally; app inaccessible until accepted
NFR11: No user account, no email, no authentication required — profile data is local-only
NFR12: GDPR Art. 9 compliance: biometric data processed locally with explicit user consent, never shared
NFR13: All core features function without network connectivity
NFR14: API data cached with TTL: weather/AQI = 1 hour, exercise catalog = 24 hours
NFR15: Local on-device database survives app backgrounding, force-close, and device restart without data loss
NFR16: Bandit learning state and session history persist across app updates
NFR17: Data loss on app uninstall/reinstall is accepted for v1
NFR18: Deferred sync queue processes events in order; failed sync retries with increasing delay (capped at 1 hour)
NFR19: Open-Meteo failure → cached data; defaults indoor if stale >2h
NFR20: ExerciseDB failure → locally cached catalog; session generation continues with cached exercises
NFR21: Health API unavailable → RPE-only mode, no degradation of core AI functionality
NFR22: WearOS disconnection → phone continues independently; reconnects when available
NFR23: All external APIs must fail fast, serve cache immediately, retry automatically
NFR24: All interactive elements meet minimum touch target size (48×48dp)
NFR25: Color contrast ratios meet WCAG 2.1 AA minimum in both light and dark mode
NFR26: Full semantic accessibility (VoiceOver/TalkBack) deferred to Growth phase — SUPERSEDED for v2: full VoiceOver/TalkBack coverage is a v2 store-launch requirement (UX-DR32)

### v2 Non-Functional Requirements (NFR27–NFR37)

**Authentication & Account Security**
NFR27: Authentication uses industry-standard secure practices — passwords hashed (never stored plaintext), OAuth/OIDC for Apple and Google, secure token storage on device via `flutter_secure_storage`, transport over TLS
NFR28: On-device personalization preserved — the adaptive AI continues to run on-device; any cloud sync of personal data is opt-in, scoped to the user's own account, used only for backup/restore and explicitly-shared social data, and never used for centralized cross-user training; biometric data is not required to leave the device

**Privacy & Compliance (cloud)**
NFR29: Social sharing is explicit and user-controlled via defined visibility tiers — private (default), friends-only, and per-item sharing; data is never visible friend-of-friend; the leaderboard shows only ranking + points to a user's own friends, not underlying session/biometric detail; each share is opt-in and revocable
NFR30: GDPR for cloud data — the user can export their server data in portable JSON and delete their account (FR77); deletion cascades: profile, friendships, shared content, feed entries, and leaderboard entries removed from the server and from other users' views; visible removal immediate, full backend purge ≤30 days
NFR33: Co-location confirmation uses location only momentarily at session start to confirm proximity; precise location is not stored, not continuously tracked, never exposed to other users (only a boolean "co-located" result is used), and the check is non-blocking (a friend can still join if the soft check is inconclusive)
NFR35: Each cloud personal-data purpose (authentication, backup, social sharing, co-location check, leaderboard) has a distinct lawful basis and granular consent; consent is unbundled and independently withdrawable without deleting the account
NFR36: Cloud data residency — server-side personal data for EU users is stored in Supabase EU region eu-central-1 (Frankfurt)
NFR37: Accounts and the social suite have a minimum age of 16 (GDPR Art. 8 default, configurable per market); age is confirmed at registration; co-location and friend features are unavailable below the minimum age

**Real-Time & Reliability**
NFR31: Shared-session state stays synchronized across participants within ~1 second; a participant dropping out does not interrupt the others' session
NFR34: Social/cloud features degrade gracefully when offline; the v1 core experience remains fully offline-first regardless of account or subscription state

**Store & Billing Compliance**
NFR32: Subscription billing complies with App Store and Play Store policies — platform IAP for the Pro subscription; Sign in with Apple offered alongside Google/email per Apple guidelines; required privacy disclosures provided

### Additional Requirements (Architecture)

ARCH1: Project initialized via `flutter create --platforms=android,ios --org com.pulsecoach pulse_coach`; manual Clean Architecture scaffold (no Very Good CLI)
ARCH2: Dependency injection: `get_it` + `injectable` with code generation; all injectables registered via `@injectable` / `@singleton` annotations
ARCH3: Database: Drift with stepwise migrations via `onUpgrade` for NFR15-NFR16
ARCH4: HTTP client: `dio` with interceptors for cache logic, logging, fail-fast behavior
ARCH5: Serialization: `freezed` + `json_serializable` for all domain entities and bloc states — no manual `==` or `hashCode`
ARCH6: Bloc/Cubit split: Bloc for domain flows, Cubit for UI-only state (ThemeCubit, OnboardingCubit, ProgressCubit)
ARCH7: AI Engine: pure Dart, separate Isolate via `compute()` — no Flutter imports; input `StateVector` (freezed), output `DailyPlan` + `List<Explanation>` (freezed)
ARCH8: Error handling: `Either<Failure, T>` for all repository returns — `ServerFailure`, `CacheFailure`, `SensorFailure`, `LocationFailure`
ARCH9: Graceful degradation: network → cache (TTL check) → bundled default; never error UI for expected degradation
ARCH10: Loading state UI: Shimmer placeholder (no `CircularProgressIndicator`)
ARCH11: CI/CD: GitHub Actions with `flutter analyze` + `flutter test` on push
ARCH12: Bundled fallback: `assets/data/fallback_exercises.json` for ExerciseDB unavailability
ARCH13: WearOS: separate build target within same Flutter project; early feasibility spike required
ARCH14: Test campaign: 150-200 tests across domain (~60), data (~50), bloc (~40), widget (~30), integration (~20)
ARCH15: Responsive breakpoint: 600dp. Phone: bottom `NavigationBar`. Tablet: `NavigationRail` + master-detail
ARCH16: Theme: `ThemeData` + `ThemeExtension<PulseCoachTheme>` for custom design tokens; dark-first via `ColorScheme.fromSeed()` with `brightness: Brightness.dark`

### v2 Additional Requirements (Architecture)

ARCH17: Backend: Supabase managed BaaS (Postgres), EU region eu-central-1 (Frankfurt) — NFR36. Schema migrations via Supabase CLI (`supabase init`, SQL + RLS in version control under `supabase/migrations/`). Edge Functions (Deno/TS) in `supabase/functions/`: `validate_receipt`, `delete_account_cascade`, `export_user_data`
ARCH18: Auth: Supabase Auth (email/password, Sign in with Apple, Google OIDC). Client packages: `sign_in_with_apple`, `google_sign_in`, `supabase_flutter`. Secure token storage via `flutter_secure_storage` (Keychain/Keystore). Account is optional; app fully usable without it (FR56)
ARCH19: E2E backup: client-side encryption with user-held key (passphrase-derived via Argon2/`cryptography` pkg) before upload to Supabase Storage. Server stores ciphertext blob only — biometric-derived AI state never server-readable (NFR28, FR57). Lost key = lost backup (by design; documented)
ARCH20: IAP entitlements: `purchases_flutter` (RevenueCat) for cross-platform IAP, entitlement caching, grandfathering, and restore. `in_app_purchase` as no-dependency fallback. `EntitlementGate` (account-free free / signed-in free / Pro) consulted by router and widgets; never hardcoded inline
ARCH21: Real-time transport: Supabase Realtime Broadcast (ephemeral step+timer events) + Presence (lobby/ready/drop-out). Host-authority pattern: only the host emits `step_advanced`; followers render received state (prevents divergence). Drop-out tolerated via Presence — others' session continues uninterrupted (NFR31)
ARCH22: Social Postgres schema: tables `profiles`, `friendships`, `shared_sessions`, `session_participants`, `activity_feed`, `leaderboard_entries`, `consents`. RLS policies enforce visibility (private default / friends-only / per-item) at the DB — client checks are convenience only, never the security boundary (NFR29)
ARCH23: GDPR machinery: FK `ON DELETE CASCADE` + Edge Function `delete_account_cascade` for erasure; `export_user_data` Edge Function for portable JSON export. Consent records in `consents` table; each cloud personal-data write checks the relevant consent record first (NFR30, NFR35)
ARCH24: GroupConstraintResolver (pure Dart, `lib/ai/safety/group_constraint_resolver.dart`): deterministic rules — intensity ceiling = min of participants' caps; fitness level = lowest present; movement exclusion = union of constraints; duration = shortest preference. Each participant's v1 FR9 safety rules still apply on top. Tested exhaustively as pure-Dart in `test/domain/ai/group_constraint_resolver_test.dart`
ARCH25: New client feature modules: `lib/features/auth/`, `lib/features/subscription/`, `lib/features/social/{friends,feed,leaderboard,shared_session}/`. Cloud boundary layer: `lib/core/cloud/` (`supabase_client.dart`, `realtime_gateway.dart`, `entitlement_gate.dart`, `crypto/e2e_backup_codec.dart`). Backend artifacts outside Flutter: `supabase/migrations/`, `supabase/functions/`. Durable `installCohort` field in drift + mirrored to `profiles` on sign-in (grandfathering, FR61)
ARCH26: New Failure types extending v1 hierarchy: `AuthFailure`, `SubscriptionFailure`, `SyncFailure`, `RealtimeFailure`. Same dartz `Either<Failure,T>` contract as v1. Cloud failures degrade gracefully — v1 core path NEVER blocked by cloud/account/sub state (NFR34)
ARCH27: New Blocs follow the freezed-union rule (initial/loading/loaded/error minimum): `AuthBloc`, `SubscriptionBloc`, `SharedSessionBloc`, `FriendsBloc`. Cubit for UI-only: `VisibilityCubit`. RealtimeGateway exposes a typed Dart Stream; SharedSessionBloc subscribes — UI never touches the Supabase channel directly

### UX Design Requirements

UX-DR1: Custom color token system via `ThemeExtension<PulseCoachTheme>`: Surface `#0F1119`, Surface Container `#171B26`, Surface Container High `#1E2333`, Primary `#7DD3C0`, Secondary `#A78BDA`, Tertiary `#E8C87A`, On Surface `#E2E4EA`, On Surface Variant `#9498A6`, Error `#F28B82`
UX-DR2: Dual font system via `google_fonts`: Plus Jakarta Sans (Display/H1-H3/Body/Caption) + JetBrains Mono (Timer 48sp, Countdown 72sp, RPE numbers 20sp). Tablet scale = phone × 1.2
UX-DR3: Spacing constants: `space-xs` 4dp, `space-sm` 8dp, `space-md` 16dp, `space-lg` 24dp, `space-xl` 32dp, `space-2xl` 48dp. All layout values reference these tokens
UX-DR4: Dual icon system: Lucide Icons (24dp, 1.5px stroke) for nav/UI actions; Lottie animations for 3 session types (breathing.json, mobility.json, cardio.json). Static Lucide fallback if Lottie unavailable
UX-DR5: SessionCard component: hero variant (gradient bg, Lottie icon, title, duration, intensity, AI explanation always visible in Body Small / On Surface Variant, Start CTA) + compact list item variant (icon, name, duration, chevron)
UX-DR6: Today screen layout — Hero + Upcoming List: state bar (dot + label + small completion ring X/3), hero card above fold, "COMING UP" compact list. Hero advances to next session on completion
UX-DR7: CountdownOverlay: full-screen, JetBrains Mono 72sp numbers, 400ms ease-in-out animation, aqua green accent. Reduce Motion: static numbers
UX-DR8: InSessionView: full-screen, JetBrains Mono 48sp timer, step name + instructions, linear progress bar, live HR top-right (hidden if unavailable), haptic on step transition within 200ms, recessive Abandon button. No navigation during session
UX-DR9: RPEInput: 10 circular tap targets (44dp visible, 48dp effective), JetBrains Mono 20sp, immediate visual feedback, no confirm dialog
UX-DR10: MiniSummary: auto-dismissing overlay (3000ms delay + 300ms fade), shows session type, duration, RPE, one-line system feedback. CompletionRing animates to new count during display; full pulse if final session
UX-DR11: StateIndicator: behavioral state label (Active/Fatigued/AtRisk/Recovering) + one-line explanation. State colors: Active → Primary, Fatigued → Secondary, AtRisk → Tertiary, Recovering → Secondary 70% opacity. H3 + Body Small typography
UX-DR12: CompletionRing: small variant on Today (X/3, informational). Full animation on post-session (closes with gentle pulse at 400ms ease-in-out). Reduce Motion: no animation
UX-DR13: Animated onboarding: 3 screens with Lottie animations (plan → privacy → setup). 250ms transitions. Static fallback available
UX-DR14: Profile setup: 4 fields (Fitness Level, Primary Goal, Available Time, Constraints). No account/email. Under 60s total
UX-DR15: Tablet layout: NavigationRail replacing bottom nav. Today: left panel (state + session list) + right panel (detail + Start). Progress: 2-column chart dashboard. In-session: split view (steps + timer)
UX-DR16: Portrait and landscape orientation support on all key screens via `OrientationBuilder`. No data loss on rotation
UX-DR17: Shape tokens: card 16dp radius, button 12dp, input/chip 8dp. Surface tint (not shadows) for elevation on dark mode
UX-DR18: Animation constants: standard 250ms ease-in-out, micro 150ms ease-out, ritual 400ms ease-in-out, auto-dismiss 3000ms + 300ms fade. All respect "Reduce Motion"
UX-DR19: Progress screen: fl_chart animated charts (minutes/week, completion rate, RPE trend, session type breakdown). Animate on first render and on data update
UX-DR20: Dark-mode-first with `ThemeMode.system`. Light mode via `ColorScheme.fromSeed()` from aqua green seed. Dark is default and primary demo mode

### v2 UX Design Requirements (UX-DR21–UX-DR33)

UX-DR21: 4-tab NavigationBar (v2 phone): Sessions · Today · Social · Progress. Today remains the default landing (home) at index 1. Social is the 4th destination added in v2. NavigationRail mirrors this on tablet. Nav bar hidden during InSessionView, CountdownOverlay, RPE, MiniSummary, and Onboarding
UX-DR22: Light mode color scheme fully defined: Surface #F8FFFE, Surface Container #EEF6F4, Surface Container High #E1F0ED, On Surface #1A1C1E, On Surface Variant #42474E, Error #BA1A1A. Behavioral-state Fatigued vs Recovering differ only in opacity (never in hue alone) — the text label is mandatory as the disambiguator
UX-DR23: Social accent tokens: accent-cardio #F0A1B0, medal-gold #E8C87A, medal-silver #9498A6, medal-bronze #F0A1B0. Medals always carry three redundant cues: rank number (primary) + shape-distinct glyph + text label ("1° oro / 2° argento / 3° bronzo") — never color alone (color-independence accessibility rule)
UX-DR24: SignInSheet: optional sign-in bottom sheet (Apple/Google/email), always dismissible, never blocks the free core. Appears only at the point of need (backup, social, Pro) — never proactively
UX-DR25: ProUpsellSheet: appears ONLY on tapping a locked Pro feature (never proactively). States one fact + offers `Scopri Pro` / `non ora`. After `non ora`, a cooldown suppresses the sheet for the rest of the session/day (no repeated nagging). No persistent lock badge or upsell indicator on Free screens
UX-DR26: FriendRow component: add by username/QR/contacts. Send/accept/decline/remove. Touch target ≥ 48dp; text wraps (never truncates) at 2.0× text scale
UX-DR27: ActivityFeedCard component: shows only explicitly-shared completions, no biometric detail. Light reactions (single encouragement tap). Zero push notifications for reactions; no aggregate counts shown as pressure; reactions never contribute to points. Each share is revocable
UX-DR28: LeaderboardRow component: friends-only ranking + points. Rank number is primary cue; top-3 add a shape-distinct, labeled medal glyph. No overtaken alerts, no points-delta toast or animation anywhere. Rank frozen while viewer is in AtRisk/Recovering state (Protective-State Social Suppression, UX-DR31)
UX-DR29: SharedSessionLobby and JoinCodeCard: SharedSessionLobby shows participants + group-adapted plan + one-line plain-language adaptation reason ("Adattata per tutti — intensità più bassa comoda, niente carico sul ginocchio."). JoinCodeCard shows join code + QR, refreshable, no expiry countdown pressure. Shared Start advances all devices simultaneously
UX-DR30: VisibilityTierSelector: defaults to Privato. Friends-only / per-item are explicit opt-ins. Used in Profile / share contexts. Each share is independently revocable
UX-DR31: Protective-State Social Suppression (non-negotiable behavioral rules): (1) rank/points frozen in AtRisk/Recovering — rest never reads as a lost position; (2) no shared-session nudges while in AtRisk/Recovering; (3) Today never shows leaderboard standing or "a friend passed you" — Social tab holds all of that; (4) per-day points cap prevents volume gaming; (5) reactions are receive-only acknowledgements (no score, no push notification, no aggregate pressure count)
UX-DR32: Full VoiceOver/TalkBack coverage is a v2 store-launch requirement (no longer deferred). Every custom component wrapped in `Semantics` with explicit labels. Live regions for CountdownOverlay, in-session step transitions, AND group-pushed step advances in shared sessions (live region required for AT users silently left behind when group moves on). v2 social/Pro surfaces (SignInSheet, ProUpsellSheet, LeaderboardRow incl. medal rank, SharedSessionLobby) carry Semantics labels from the start. Decorative elements (Lottie, shimmer, ring arc) use `ExcludeSemantics`
UX-DR33: Accessibility for v2 social components: LeaderboardRow/FriendRow/feed reaction tap/JoinCodeCard QR action all ≥ 48dp touch target; dense rows wrap (not truncate) at 2.0× text scale; color independence enforced throughout (medals: number + glyph + label; behavioral-state colors: always paired with text label)

### FR Coverage Map

| Epic | Stories | FRs Covered | NFRs Covered | UX-DRs | ARCH |
|---|---|---|---|---|---|
| Epic 1: Foundation | 1.1-1.7 | — | NFR2, NFR15-16 | UX-DR1–3, UX-DR17-20 | ARCH1-6, ARCH10-11, ARCH16 |
| Epic 2: Onboarding | 2.1-2.4 | FR1-4 | NFR9-12 | UX-DR13-14 | ARCH6 |
| Epic 3: Sensor Integration | 3.1-3.3 | FR42-44 | NFR7-9, NFR21 | — | ARCH8-9 |
| Epic 4: Environmental Context | 4.1-4.3 | FR33-36 | NFR5, NFR8, NFR14, NFR19, NFR23 | — | ARCH4, ARCH8-9 |
| Epic 5: AI Engine & Daily Planning | 5.1-5.6 | FR5-15, FR22-25 | NFR1-2, NFR7 | UX-DR11 | ARCH7, ARCH8 |
| Epic 6: Exercise Catalog | 6.1-6.3 | FR26-28 | NFR14, NFR20, NFR23 | — | ARCH4, ARCH12 |
| Epic 7: Today Screen | 7.1-7.4 | FR5, FR11, FR15-16 | NFR6 | UX-DR5-6, UX-DR11-12 | ARCH6, ARCH10, ARCH15 |
| Epic 8: In-Session Experience | 8.1-8.5 | FR17-20 | NFR2-4 | UX-DR7-8, UX-DR18 | ARCH6 |
| Epic 9: Feedback & Adaptation | 9.1-9.3 | FR21-24 | NFR1 | UX-DR9-10, UX-DR12 | ARCH7 |
| Epic 10: Progress & History | 10.1-10.3 | FR29-32 | — | UX-DR19 | ARCH6 |
| Epic 11: Responsive Layout | 11.1-11.3 | FR37-39 | NFR24-25 | UX-DR15-16 | ARCH15 |
| Epic 12: WearOS Companion | 12.1-12.4 | FR40-41 | NFR22 | — | ARCH13 |
| Epic 13: Offline & Data Sync | 13.1-13.3 | FR45-47 | NFR13-16, NFR18, NFR23 | — | ARCH3, ARCH9 |
| Epic 14: Settings & Extras | 14.1-14.5 | FR48-52 | NFR11, NFR26 | UX-DR20 | ARCH6 |
| Epic 15: Navigation Fix (v2.0) | 15.1 | FR53 | — | — | ARCH25 |
| Epic 16: Accounts & Auth (v2.1) | 16.1-16.4 | FR54-57, FR77 | NFR27-28, NFR30, NFR35-37 | UX-DR24 | ARCH17-19, ARCH23, ARCH25-26 |
| Epic 17: Pro Subscription (v2.2) | 17.1-17.4 | FR58-62 | NFR32, NFR34 | UX-DR25 | ARCH20, ARCH25-27 |
| Epic 18: Social Graph (v2.3) | 18.1-18.4 | FR63-67 | NFR29-30, NFR34-35 | UX-DR21, UX-DR26-28, UX-DR30-31 | ARCH22-23, ARCH25-27 |
| Epic 19: Realtime Transport (v2.4a) | 19.1-19.3 | FR71 | NFR31, NFR34 | — | ARCH21, ARCH25, ARCH27 |
| Epic 20: Shared Sessions (v2.4b) | 20.1-20.5 | FR68-70, FR72-73 | NFR31, NFR33-34 | UX-DR29, UX-DR31-33 | ARCH21, ARCH24-25, ARCH27 |
| Epic 21: Leaderboard & Scoring (v2.5) | 21.1-21.3 | FR74-76 | NFR34 | UX-DR23, UX-DR28, UX-DR31 | ARCH22, ARCH25 |

---

## Epic List

- **Epic 1: Foundation & Project Infrastructure** — Project scaffold, Clean Architecture structure, DI, database, theme system, CI/CD
- **Epic 2: Onboarding & Profile** — Animated onboarding, medical disclaimer, profile setup, profile editing
- **Epic 3: Sensor Integration** — Health API (HR + steps), accelerometer activity detection, RPE-only fallback
- **Epic 4: Environmental Context** — Open-Meteo weather + AQI integration, city-level location, caching, offline fallback
- **Epic 5: AI Engine & Daily Planning** — StateVector, behavioral state machine, safety rules, contextual bandit, plan generation, explanations
- **Epic 6: Exercise Catalog** — ExerciseDB API integration, local cache, bundled fallback, session browsing
- **Epic 7: Today Screen** — Hero + Upcoming List layout, SessionCard, StateIndicator, CompletionRing, plan regeneration
- **Epic 7.5: i18n Migration (Interstitial)** — wire `flutter_localizations` + `gen_l10n`, migrate hardcoded Italian strings from Epic 7 widgets, translate residual English labels. Cap: 2 stories. Added 2026-05-16 per Epic 7 retrospective decision. Must complete before Epic 8 kickoff.
- **Epic 8: In-Session Experience** — Story 8.0 SessionLog DAO + per-session completion persistence (closes E7-F1; precedes 8.1), CountdownOverlay, InSessionView, step timer, haptic feedback, live HR, abandon flow
- **Epic 9: Feedback & Adaptation Loop** — RPEInput, MiniSummary, RPE recording, bandit reward update, state machine transition
- **Epic 10: Progress & History** — Session history timeline, animated progress charts, weekly goal progress
- **Epic 11: Responsive Layout & Navigation** — Bottom nav / NavigationRail, master-detail tablet layouts, orientation support
- **Epic 12: WearOS Companion** — WearOS spike, in-session companion display, post-session summary, disconnect resilience
- **Epic 13: Offline & Data Sync** — Offline-first core features, deferred sync queue, data persistence guarantees
- **Epic 14: Settings, Theme & Extras** — Theme toggle, privacy screen, settings screen, AI Decision Log (MVP-if-time), CSV export (MVP-if-time)

**— v2 Epics (post-v1 implementation) —**

- **Epic 15: Navigation Fix (v2.0)** — Explicit back navigation from drawer secondary screens (Settings/Profile/Privacy/Debug) to primary shell; closes standing v1 UX defect FR53
- **Epic 16: Accounts & Authentication (v2.1)** — Supabase EU backend init, email/Apple/Google sign-in, optional E2E-encrypted backup/restore, in-app account deletion (store-blocking FR77); all Pro/social features depend on this epic
- **Epic 17: Pro Subscription & Feature Gating (v2.2)** — RevenueCat IAP, EntitlementGate (free/signed-in/Pro tiers), Progress history gating with pre-v2 grandfathering, ProUpsellSheet with cooldown
- **Epic 18: Social Graph & Friends (v2.3)** — Username/handle, VisibilityTierSelector (private by default), friend requests, shared activity feed with light reactions, friends progress comparison; all social content requires Pro
- **Epic 19: Real-Time Session Transport (v2.4a)** — Supabase Realtime Broadcast/Presence channel, RealtimeGateway Dart stream, host-authority step advancement, drop-out tolerance; prerequisite for Epic 20
- **Epic 20: Co-Located Shared Sessions (v2.4b)** — JoinCodeCard/QR invite, GroupConstraintResolver (pure Dart deterministic rules), momentary co-location check, SharedSessionLobby, per-participant RPE, Protective-State Social Suppression enforcement
- **Epic 21: Leaderboard & Scoring (v2.5)** — Points system, friends-only leaderboard with medal glyphs, shared-session point bonus, per-day points cap; rank frozen in AtRisk/Recovering state

---

## Epic 1: Foundation & Project Infrastructure

**Goal:** Establish the complete project scaffold with all architectural patterns, dependencies, database schema, theme system, and CI/CD in place. Every subsequent epic will build on this foundation without revisiting core setup.

### Story 1.1: Project Initialization & Repository Setup

As a developer,
I want a Flutter project initialized with the correct structure and CI/CD configured,
So that all contributors can develop within a consistent, linted, tested environment from day one.

**Acceptance Criteria:**

**Given** an empty directory
**When** `flutter create --platforms=android,ios --org com.pulsecoach pulse_coach` is run
**Then** the project builds and runs on both Android and iOS simulators

**Given** the project exists
**When** the feature-first directory structure is created under `lib/`
**Then** the following directories exist: `lib/core/`, `lib/features/`, and all feature subdirectories (`onboarding/`, `daily_plan/`, `session/`, `feedback/`, `progress/`, `settings/`)

**Given** the project exists
**When** `analysis_options.yaml` is configured with strict linting rules
**Then** `flutter analyze` passes with zero warnings or errors

**Given** code is pushed to any branch
**When** GitHub Actions CI runs
**Then** `flutter analyze` and `flutter test` complete successfully in the CI pipeline

### Story 1.2: Core Dependencies & pubspec Setup

As a developer,
I want all project dependencies declared and pinned in `pubspec.yaml`,
So that the build is reproducible and all packages are available from story 1.3 onward.

**Acceptance Criteria:**

**Given** the project exists
**When** `pubspec.yaml` is configured
**Then** all required packages are declared and pinned: `flutter_bloc`, `get_it`, `injectable`, `drift`, `drift_flutter`, `freezed`, `json_serializable`, `dio`, `go_router`, `google_fonts`, `fl_chart`, `lottie`, `flutter_animate`, `shimmer`, `vibration`, `health`, `sensors_plus`, `geolocator`, `wear_plus`, `build_runner`, `injectable_generator`, `drift_dev`, `freezed_annotation`, `json_annotation`

**Given** `pubspec.yaml` is configured
**When** `flutter pub get` is run
**Then** all packages resolve without conflicts and `pubspec.lock` is committed

**Given** `assets/` directories exist
**Then** `pubspec.yaml` declares `assets/animations/`, `assets/fonts/`, and `assets/data/`

### Story 1.3: Dependency Injection Setup

As a developer,
I want `get_it` + `injectable` configured with code generation,
So that all features can register and resolve dependencies via annotations without manual `getIt.register` calls.

**Acceptance Criteria:**

**Given** the DI configuration exists at `lib/core/di/injection.dart`
**When** `configureDependencies()` is called in `main.dart`
**Then** all annotated `@injectable`, `@singleton`, and `@lazySingleton` classes are registered and resolvable

**Given** a new injectable class is annotated with `@injectable`
**When** `flutter pub run build_runner build` is run
**Then** `injection.config.dart` is updated to include the new registration without manual intervention

**Given** the DI setup is complete
**When** any repository implementation is annotated with `@Injectable(as: AbstractRepository)`
**Then** resolving the abstract repository returns the concrete implementation

### Story 1.4: Drift Database Setup & Schema

As a developer,
I want all Drift database tables, DAOs, and the initial migration schema defined,
So that all features can persist and retrieve data from a structured local database.

**Acceptance Criteria:**

**Given** the database file exists at `lib/core/database/app_database.dart`
**When** the app starts
**Then** a SQLite database is created with all 9 tables: `sessions`, `daily_plans`, `user_profile`, `rpe_feedback`, `bandit_state`, `behavioral_state`, `weather_cache`, `exercise_cache`, `sync_queue`

**Given** each table is defined with a Drift `@DataClassName` annotation
**When** `build_runner` generates `app_database.g.dart`
**Then** all table classes, companion classes, and DAO implementations are generated without errors

**Given** the database exists with schema version 1
**When** a future migration adds a column (simulated in test)
**Then** the `onUpgrade` callback applies the migration without data loss

**Given** the database is open
**When** the app is force-closed and re-launched
**Then** all previously persisted data is accessible and intact (NFR15)

### Story 1.5: Core Error Handling & Either Pattern

As a developer,
I want the `Either<Failure, T>` error handling pattern and all Failure types defined,
So that repositories can return typed errors without throwing exceptions past the data layer.

**Acceptance Criteria:**

**Given** the abstract `Failure` class exists in `lib/core/error/`
**When** a failure subclass is needed
**Then** the following concrete types are available: `ServerFailure`, `CacheFailure`, `SensorFailure`, `LocationFailure`, each with a `message` field

**Given** a repository method wraps a remote datasource call
**When** the datasource throws a `ServerException`
**Then** the repository catches it and returns `Left(ServerFailure('...'))` — no exception propagates to the use case layer

**Given** a repository method wraps a cache read
**When** the cache is empty or stale
**Then** the repository returns `Left(CacheFailure('...'))` with a descriptive message

**Given** a Bloc handles a use case result
**When** the use case returns `Left(Failure)`
**Then** the Bloc emits an error state with the failure — it never throws or crashes

### Story 1.6: Theme System & Design Tokens

As a developer,
I want the full design token system implemented in `ThemeData` + `ThemeExtension<PulseCoachTheme>`,
So that all widgets consume the correct colors, typography, spacing, and shape values without hardcoded values.

**Acceptance Criteria:**

**Given** `PulseCoachTheme` extends `ThemeExtension<PulseCoachTheme>`
**When** any widget accesses `Theme.of(context).extension<PulseCoachTheme>()`
**Then** all 9 color tokens are available: `surface (#0F1119)`, `surfaceContainer (#171B26)`, `surfaceContainerHigh (#1E2333)`, `primaryColor (#7DD3C0)`, `secondary (#A78BDA)`, `tertiary (#E8C87A)`, `onSurface (#E2E4EA)`, `onSurfaceVariant (#9498A6)`, `error (#F28B82)` (UX-DR1)

**Given** the typography system is defined in `AppTextStyles`
**When** a widget uses `AppTextStyles.timerDisplay`
**Then** the style is JetBrains Mono, 48sp; `AppTextStyles.countdown` is JetBrains Mono 72sp; `AppTextStyles.rpeNumbers` is JetBrains Mono 20sp; all other roles use Plus Jakarta Sans per the UX spec scale (UX-DR2)

**Given** `AppSpacing` constants are defined
**When** a widget applies `AppSpacing.md` (16dp) for card padding
**Then** the spacing value is consistently 16dp across the app (UX-DR3)

**Given** shape tokens are defined
**When** a card widget uses `AppShapes.cardRadius`
**Then** corner radius is 16dp; buttons use 12dp; inputs/chips use 8dp (UX-DR17)

**Given** the dark theme is configured
**When** `ThemeMode.dark` is active
**Then** surface tint (lighter surface color) is used for elevation — no shadows; maximum 3 elevation levels (UX-DR17, ARCH16)

**Given** the app is built with the theme
**When** all text elements are inspected
**Then** minimum text size is 11sp (Caption) — no text below this threshold (UX-DR2)

### Story 1.7: App Shell & Navigation Scaffold (Phone)

As a developer,
I want the top-level app shell configured with `go_router` and the phone bottom navigation scaffold,
So that all features can be navigated to and the routing is established for subsequent epics.

**Acceptance Criteria:**

**Given** the `MaterialApp.router` is configured in `app.dart`
**When** the app launches
**Then** routing is handled by `go_router` with defined routes for: `/onboarding`, `/today`, `/sessions`, `/progress`, `/session/active`, `/session/rpe`, `/session/summary`, `/settings`, `/profile`, `/privacy`

**Given** onboarding is complete and the user profile exists
**When** the app launches
**Then** the router redirects to `/today` (skipping onboarding)

**Given** onboarding is not complete
**When** the app launches
**Then** the router redirects to `/onboarding`

**Given** the app shell renders the Today screen
**When** viewed on a phone (< 600dp width)
**Then** a `BottomNavigationBar` is shown with 3 tabs: Today, Sessions, Progress with Lucide icons (24dp, 1.5px stroke, On Surface Variant inactive / Primary active) (FR37, UX-DR4)

**Given** the app shell renders
**When** the drawer icon is tapped
**Then** a navigation drawer opens with items: Profile, Settings, Privacy (and Debug in dev mode)

---

## Epic 2: Onboarding & Profile

**Goal:** Guide new users through the app concept, privacy promise, and profile setup in under 90 seconds, collecting only the data needed to generate the first plan.

### Story 2.1: Medical Disclaimer Screen

As a new user,
I want to see a medical disclaimer before using any app features,
So that I understand this is not a medical device and can make an informed decision to proceed.

**Acceptance Criteria:**

**Given** the app is opened for the first time
**When** the disclaimer screen renders
**Then** it displays a clear, readable disclaimer stating the app is not a medical device and is not a substitute for professional medical advice

**Given** the disclaimer is displayed
**When** the user taps "I Understand"
**Then** acceptance is persisted to the local database (not in-memory only) and the user proceeds to the onboarding flow (NFR10)

**Given** disclaimer has been accepted
**When** the app is re-opened
**Then** the disclaimer screen is not shown again — the router bypasses it

**Given** the disclaimer screen is displayed
**Then** there is no way to skip or dismiss it without explicitly tapping the acceptance button (FR3)

### Story 2.2: Animated Onboarding Flow

As a new user,
I want to see an animated introduction explaining the app concept and privacy promise,
So that I understand PulseCoach before providing my profile information.

**Acceptance Criteria:**

**Given** the onboarding flow starts after disclaimer acceptance
**When** Screen 1 renders
**Then** it shows the Lottie animation `onboarding_plan.json` and the headline "Move more. Decide less." with a body line explaining the autoplay concept (UX-DR13)

**Given** the user taps "Next" on Screen 1
**When** Screen 2 renders
**Then** it shows `onboarding_privacy.json` animation and "Your data stays yours." with explanation of on-device-only data (UX-DR13)

**Given** the user taps "Next" on Screen 2
**When** Screen 3 renders
**Then** it shows `onboarding_setup.json` animation and "Let's set you up in 60 seconds." with a "Get Started" CTA (UX-DR13)

**Given** any screen transition occurs
**When** measured
**Then** the transition uses a 250ms ease-in-out animation (UX-DR18)

**Given** the device has "Reduce Motion" enabled
**When** onboarding renders
**Then** Lottie animations are replaced with static frames and transitions are instant cuts (UX-DR18)

**Given** Lottie files fail to load
**When** onboarding renders
**Then** static Lucide icons with session-type color accents are shown as fallback (UX-DR4)

### Story 2.3: Profile Setup Screen

As a new user,
I want to set up my fitness profile with 4 questions,
So that the system can generate a calibrated first plan within 60 seconds of completing onboarding.

**Acceptance Criteria:**

**Given** the user taps "Get Started" on onboarding Screen 3
**When** the profile setup screen renders
**Then** 4 options are displayed: Fitness Level (Beginner/Intermediate), Primary Goal (Cardio/Strength/Mobility/Well-being), Available Time (2-5 min / 5-10 min), Physical Constraints (None / Knee issues / Back issues / Prefer indoor) (FR2, UX-DR14)

**Given** all 4 fields have selections
**When** the user taps "Start My Plan"
**Then** the profile is persisted to the `user_profile` table with selected values and `onboardingCompleted = true`

**Given** the profile is persisted
**When** the AI plan generation is triggered
**Then** the first plan is generated with intensity ≤ Low and session count = 3, derived from the onboarding fitness level (FR12)

**Given** the profile is saved
**When** the user is navigated to Today
**Then** the total time from "Get Started" tap to Today screen is < 90 seconds on a mid-range Android device

**Given** no account or email is required
**When** the profile setup screen is inspected
**Then** there is no email field, password field, or account creation prompt (NFR11, UX-DR14)

### Story 2.4: Profile View & Edit

As a returning user,
I want to view and edit my profile and goals at any time,
So that the system can adjust my plan as my fitness level or preferences change.

**Acceptance Criteria:**

**Given** the user navigates to Profile from the drawer
**When** the profile screen renders
**Then** all 4 profile fields are displayed with their current values (FR4)

**Given** the user taps "Edit" on any field
**When** a new value is selected
**Then** the change is persisted to `user_profile` table immediately

**Given** the profile is updated
**When** the user returns to Today
**Then** the daily plan is regenerated to reflect the updated profile values

---

## Epic 3: Sensor Integration

**Goal:** Read physiological signals (HR, steps) from the device Health API and detect activity via accelerometer, gracefully falling back to RPE-only mode when permissions are denied.

### Story 3.1: Health API Integration (HR & Steps)

As the system,
I want to read resting heart rate and daily step count from the device Health API,
So that the AI engine can incorporate physiological signals into plan generation.

**Acceptance Criteria:**

**Given** the app requests Health API permissions (HealthKit on iOS / Health Connect on Android)
**When** the permission prompt appears
**Then** the prompt includes a clear explanation of how the data is used (e.g., "Used to personalize your sessions. Stays on your device.") (NFR9)

**Given** permissions are granted
**When** the `HealthRepository` fetches data
**Then** resting HR (bpm) and step count (daily total) are returned as domain entities and stored in the `behavioral_state` table with a timestamp

**Given** Health API data is successfully read
**When** the `StateVector` is constructed for plan generation
**Then** `restingHR` and `stepCount` fields are populated from the Health API result (FR42)

**Given** data is fetched from Health API
**When** the data is stored
**Then** it is stored exclusively on-device with no transmission to external servers (NFR7)

### Story 3.2: Accelerometer Activity Detection

As the system,
I want to detect user activity patterns via the device accelerometer,
So that the state vector has activity-level context even when Health API is unavailable.

**Acceptance Criteria:**

**Given** the accelerometer is available on the device
**When** the app is in the foreground
**Then** the `SensorRepository` reads accelerometer data via `sensors_plus` and classifies activity as sedentary/active/moderate (FR43)

**Given** activity is detected via accelerometer
**When** the `StateVector` is built
**Then** the `activityLevel` field is populated from the accelerometer classification

**Given** the accelerometer is unavailable
**When** the `StateVector` is built
**Then** the `activityLevel` field is null and plan generation continues without it (ARCH9)

### Story 3.3: RPE-Only Fallback Mode

As the system,
I want all core functionality to work with zero sensor data,
So that users who deny Health API permissions receive the same quality of experience as those who grant them.

**Acceptance Criteria:**

**Given** the user denies all Health API permissions
**When** the system constructs the `StateVector`
**Then** `restingHR`, `stepCount`, and `activityLevel` are null — the system enters RPE-only mode (FR44, NFR21)

**Given** the system is in RPE-only mode
**When** a daily plan is generated
**Then** the bandit selects sessions based on RPE history, profile, and environmental context alone — plan quality is not degraded

**Given** the system is in RPE-only mode
**When** the user views the Today screen
**Then** the StateIndicator explanation reflects available data (e.g., RPE history, profile) without referencing missing sensor data

---

## Epic 4: Environmental Context

**Goal:** Fetch and cache weather and AQI data from Open-Meteo, use it to route sessions indoor/outdoor, and degrade gracefully when the API is unreachable.

### Story 4.1: Open-Meteo API Integration

As the system,
I want to fetch real-time weather (temperature, precipitation) and AQI data from Open-Meteo,
So that the AI engine can route sessions appropriately based on outdoor conditions.

**Acceptance Criteria:**

**Given** the user's approximate city-level location is available (no precise GPS)
**When** the `WeatherRepository` calls Open-Meteo
**Then** temperature, precipitation probability, and AQI are returned and persisted to `weather_cache` table with `cachedAt` timestamp (FR33, FR34, NFR8)

**Given** the API is called
**When** the request is made
**Then** the request includes only city-level coordinates (e.g., rounded to 1 decimal place) — no precise GPS coordinates are sent (FR35, NFR8)

**Given** AQI is above threshold (≥ 100 — unhealthy for sensitive groups)
**When** the `StateVector` is built
**Then** the `aqiLevel` field is marked as `high` and sessions are constrained to indoor (FR8)

**Given** the Open-Meteo API returns an error
**When** the repository handles the failure
**Then** it returns `Left(ServerFailure)` — no exception propagates and the UI does not show an error (ARCH8, ARCH9)

### Story 4.2: Weather Cache & TTL Management

As the system,
I want weather and AQI data to be cached with a 1-hour TTL,
So that users receive plan generation in < 500ms even when offline.

**Acceptance Criteria:**

**Given** weather data exists in `weather_cache` and `cachedAt` is within 1 hour
**When** the `WeatherRepository` is queried
**Then** cached data is returned immediately without a network call (NFR5, NFR14)

**Given** the cache is stale (> 1 hour old) and the API is reachable
**When** the `WeatherRepository` is queried
**Then** fresh data is fetched, persisted to cache, and returned

**Given** the cache is stale and the API is unreachable
**When** the `WeatherRepository` is queried
**Then** stale cached data is returned — sessions default to indoor if AQI data is stale > 2 hours (FR36, NFR19)

**Given** fresh data is fetched and cached
**When** measured against NFR5
**Then** subsequent offline reads return in < 500ms

### Story 4.3: City-Level Location Resolution

As the system,
I want to resolve the user's approximate city-level location without storing or transmitting precise coordinates,
So that Open-Meteo API calls respect the privacy requirement.

**Acceptance Criteria:**

**Given** the `geolocator` package is used
**When** location is requested
**Then** coordinates are rounded to 1 decimal place (approximately 11km precision) before any use or storage (FR35, NFR8)

**Given** location permission is denied
**When** the `WeatherRepository` is queried
**Then** it returns `Left(LocationFailure)` and the system defaults to indoor sessions for plan generation (FR36)

**Given** location is resolved
**When** stored in the database
**Then** only the rounded (city-level) coordinates are stored — raw GPS data is never persisted

---

## Epic 5: AI Engine & Daily Planning

**Goal:** Implement the contextual bandit AI engine, behavioral state machine, safety rules, plan generation, and AI explanation system — all running in a separate Dart Isolate.

### Story 5.1: Domain Models & StateVector

As a developer,
I want all AI engine domain models defined as pure Dart `@freezed` classes,
So that the AI engine and all its inputs/outputs are immutable, serializable, and testable without the Flutter framework.

**Acceptance Criteria:**

**Given** the domain model files exist in `lib/features/daily_plan/domain/entities/`
**When** `build_runner` runs
**Then** `StateVector`, `DailyPlan`, `PlannedSession`, `Explanation`, `BehavioralState` (enum), `BanditState`, and `SafetyConstraints` are generated as immutable `@freezed` classes

**Given** `StateVector` is defined
**When** inspected
**Then** it contains: `restingHR` (nullable double), `stepCount` (nullable int), `activityLevel` (nullable enum), `rpeHistory` (List<int>, last 5), `missedSessions` (int), `streak` (int), `aqiLevel` (enum), `temperature` (nullable double), `precipitation` (nullable bool), `userProfile` (UserProfile), `currentState` (BehavioralState)

**Given** the domain models have no Flutter imports
**When** `dart analyze` is run on the `domain/` and AI engine files
**Then** zero Flutter framework imports are detected (ARCH7)

### Story 5.2: Behavioral State Machine

As the system,
I want a deterministic behavioral state machine that tracks and transitions user state,
So that the AI engine has context about the user's current capacity before generating a plan.

**Acceptance Criteria:**

**Given** the `BehavioralStateMachine` is implemented as a pure Dart class
**When** `StateVector` shows RPE avg > 8 for last 2 sessions
**Then** the machine transitions to `Fatigued` state (FR23)

**Given** state is `Fatigued` and `missedSessions >= 2`
**When** the machine evaluates
**Then** it transitions to `AtRisk` state (FR23)

**Given** state is `AtRisk` or `Fatigued`
**When** user completes 2 consecutive sessions with RPE ≤ 7
**Then** state transitions to `Recovering` (FR23)

**Given** state is `Recovering` and user completes 3 sessions with RPE avg ≤ 6.5 and streak ≥ 3
**When** the machine evaluates
**Then** state transitions back to `Active` (FR23)

**Given** any state transition occurs
**When** the transition is written to the `behavioral_state` table
**Then** a human-readable transition message is generated (e.g., "You've been pushing hard. Taking it easier today.") (FR14)

**Given** the state is `Recovering` or `AtRisk`
**When** a plan is generated
**Then** `SafetyConstraints` include `maxIntensity = Low` and `maxSessionCount = 2` (FR24)

### Story 5.3: Safety Rules Override System

As the system,
I want deterministic safety rules that override bandit recommendations,
So that session intensity is automatically reduced when biometric or behavioral signals indicate risk.

**Acceptance Criteria:**

**Given** RPE average of last 2 sessions is > 8
**When** the safety rule engine evaluates
**Then** high-intensity sessions are blocked regardless of bandit recommendation (FR9)

**Given** the user is in `AtRisk` state
**When** safety rules apply
**Then** only Low intensity sessions are permitted and session count is capped at 2 (FR9, FR24)

**Given** AQI is high (≥ 100)
**When** safety rules apply
**Then** all outdoor sessions are blocked — only indoor sessions are permitted (FR8)

**Given** safety rules produce constraints
**When** the bandit generates a plan
**Then** the plan returned from the AI engine respects all active safety constraints — no override is possible from the bandit layer (FR9)

### Story 5.4: Contextual Bandit Algorithm

As the system,
I want a contextual bandit that learns from RPE feedback to improve session selection over time,
So that recommendations become more personalized without any explicit user configuration.

**Acceptance Criteria:**

**Given** the `BanditEngine` is implemented as a pure Dart class with no Flutter imports
**When** initialized for a new user
**Then** bandit arms represent session type × intensity combinations; initial exploration is uniform (FR10)

**Given** the user submits RPE feedback after a session
**When** `updateReward(sessionId, rpe)` is called
**Then** the bandit updates arm weights: sessions with RPE near 6.5 receive positive reward; deviation from 6.5 reduces reward (FR22)

**Given** bandit state exists in `bandit_state` table
**When** the user transitions behavioral state (e.g., Fatigued → Recovering)
**Then** bandit arm weights are preserved — learning history is not reset (FR25)

**Given** the `BanditEngine.selectSessions(stateVector, constraints)` is called
**When** measured against NFR1
**Then** session selection completes in < 30 seconds on a background isolate — zero UI thread blocking (NFR1, NFR2, ARCH7)

**Given** a new user with no RPE history
**When** sessions are selected
**Then** the bandit defaults to exploration mode, returning varied session types within the safety constraints

### Story 5.5: Daily Plan Generation & AI Isolation

As the system,
I want the complete plan generation pipeline running in a separate Dart Isolate,
So that the UI thread is never blocked during AI computation and maintains ≥ 60fps.

**Acceptance Criteria:**

**Given** the `GenerateDailyPlan` use case is called
**When** execution starts
**Then** AI computation runs in a separate Dart Isolate via `compute()` — the UI thread remains unblocked (ARCH7, NFR1, NFR2)

**Given** the plan generation pipeline runs
**When** it executes
**Then** it executes in order: 1) fetch StateVector (sensor + env + RPE history), 2) evaluate state machine, 3) apply safety rules, 4) call bandit `selectSessions`, 5) generate explanations, 6) return `DailyPlan` (FR5-FR9)

**Given** a `DailyPlan` is generated
**When** it is persisted
**Then** the plan is stored in `daily_plans` table with `generatedAt` timestamp and `planDate`

**Given** the app opens and no plan exists for today
**When** the Today screen loads
**Then** plan generation is triggered automatically and completes in < 30 seconds (NFR1)

**Given** a plan exists for today in the database
**When** the app opens
**Then** the cached plan is served immediately without re-generation (NFR6)

### Story 5.6: AI Explanation Generation

As the system,
I want every session recommendation to have a structured one-line explanation derived from the state vector,
So that users understand why each session was chosen and trust the system's recommendations.

**Acceptance Criteria:**

**Given** a `PlannedSession` is generated
**When** the explanation engine runs
**Then** a one-line explanation is generated referencing available state signals (e.g., "Short sleep + elevated HR. Starting gentle." or "Low step count today. Light movement to get going.") (FR13)

**Given** only RPE history is available (no sensor data)
**When** the explanation is generated
**Then** it references RPE history or behavioral state (e.g., "You've been consistent this week. Stepping it up slightly.")

**Given** the `BehavioralState` is `Recovering`
**When** explanation is generated
**Then** it communicates the reduced intensity reason (e.g., "Your body needs a lighter day. We've adjusted accordingly.") (FR14)

**Given** explanations are stored
**When** the `PlannedSession` entity is inspected
**Then** the `explanation` field contains the generated string — it is always non-null and non-empty

---

## Epic 6: Exercise Catalog

**Goal:** Fetch session exercise content from ExerciseDB, cache it locally, provide a bundled fallback, and expose a session browsing UI.

### Story 6.1: ExerciseDB API Integration & Cache

As the system,
I want to fetch exercise content from ExerciseDB and cache it in the local database,
So that sessions are populated with real exercise steps and available offline.

**Acceptance Criteria:**

**Given** the `ExerciseRepository` calls ExerciseDB
**When** exercises are fetched by session type (mobility/cardio/breathing)
**Then** exercise entities (name, description, steps, duration, difficulty, indoor/outdoor flag) are stored in the `exercise_cache` table with `cachedAt` timestamp (FR26)

**Given** cache exists and `cachedAt` is within 24 hours
**When** the repository is queried
**Then** cached exercises are returned without a network call (NFR14)

**Given** ExerciseDB API is unreachable
**When** the repository is queried
**Then** it falls back to the local cache; if cache is also empty, it loads `assets/data/fallback_exercises.json` (FR28, NFR20, ARCH12)

**Given** the bundled fallback is loaded
**When** plan generation uses it
**Then** a complete daily plan of 3 sessions is generated — no error state is shown to the user (ARCH9)

### Story 6.2: Bundled Fallback Exercise Catalog

As a developer,
I want a curated bundled exercise catalog in `assets/data/fallback_exercises.json`,
So that the app can generate plans even when ExerciseDB is unavailable and local cache is empty.

**Acceptance Criteria:**

**Given** `fallback_exercises.json` exists in `assets/data/`
**When** parsed
**Then** it contains at least 30 exercises: 10 mobility, 10 cardio, 10 breathing — each with at least 3 steps and a duration between 2-10 minutes (FR26, NFR20)

**Given** the fallback is loaded
**When** inspected
**Then** all exercises have `indoorCompatible: true` — the fallback never requires outdoor access

**Given** the `ExerciseCacheRepository` is queried with empty cache and unreachable API
**When** the fallback is returned
**Then** it is returned as `Right(exercises)` — not as a failure — and is indistinguishable from cached API data at the use case layer

### Story 6.3: Session Browsing Screen

As a user,
I want to browse available session types filtered by category,
So that I can explore what kinds of sessions PulseCoach offers.

**Acceptance Criteria:**

**Given** the user navigates to the Sessions tab
**When** the screen renders
**Then** sessions are displayed grouped by type: Mobility, Cardio, Breathing (FR27)

**Given** the user taps a filter chip (e.g., "Mobility")
**When** the filter is applied
**Then** only sessions of that type are visible in the list

**Given** the sessions list is loading
**When** data is being fetched
**Then** shimmer placeholders are displayed (no `CircularProgressIndicator`) (ARCH10)

**Given** the user taps a session card in the catalog
**When** the detail view opens
**Then** session name, description, duration, intensity, and step list are displayed

---

## Epic 6.5: Foundation Hardening (Interstitial)

**Goal:** Close the foundation gaps surfaced by Epic 5 and Epic 6 retrospectives before Epic 7 (Today Screen) builds on top. Resolve the unmet `flutter analyze` cleanup commitment, align AppShell tab order with the UX spec, harden the catalog with defense-in-depth normalization and uniqueness guards, triage accumulated deferred work, and establish a process ledger so retro action items stop slipping between epics.

**Rationale:**

- Epic 5 retro committed to `flutter analyze` → 0 warnings and action-item tracking. Both unmet at end of Epic 6.
- Epic 6 retro identified `sessionType` normalization and fallback ID uniqueness as recurring deferred-item categories across all 3 stories.
- AppShell currently orders tabs `Today, Sessions, Progress` while UX spec specifies `Sessions, Today, Progress`. Epic 7 builds the Today screen — fix the foundation contract first.
- `deferred-work.md` has accumulated 28+ items across Epic 6. Triage is needed: each item is promoted, kept, or closed before Epic 7 multiplies consumers.

**External (non-story) prerequisites tracked alongside this epic:**

- Product review: AI state-graph semantics (Alice + Winston) — decisions for `active + missedSessions >= 2` escalation, `recovering` demotion, `atRisk → recovering` guard. Output: decision doc under `_bmad-output/`.
- Product review: explanation copy for Today screen (Sally + Alice) — placeholder vs templated vs state-aware copy decision. Output: decision doc under `_bmad-output/`.

### Story 6.5.1: Analyzer Cleanup & AppShell Tab Order

As a developer,
I want `flutter analyze` to report zero warnings and AppShell tabs ordered per the UX spec,
So that Epic 7 builds on a clean foundation that matches the documented design.

**Acceptance Criteria:**

**Given** the project compiles cleanly
**When** `flutter analyze` runs from `pulse_coach/`
**Then** it reports zero issues, or remaining info-level items are explicitly documented in a tracked exception list with rationale

**Given** the app shell renders
**When** the bottom navigation is inspected
**Then** tab order is `Sessions, Today, Progress` matching the UX specification

**Given** the AppShell tab order has changed
**When** `flutter test` runs
**Then** existing widget tests asserting tab positions are updated and pass without regression in onboarding/redirect/router behavior

### Story 6.5.2: Catalog Defense-in-Depth & Deferred-Work Triage

As a developer,
I want the catalog repository and presentation layer to normalize input defensively and the deferred-work backlog to be triaged,
So that Epic 7 consumers do not inherit silently-dropped data or an unbounded debt list.

**Acceptance Criteria:**

**Given** `SessionsCatalogCubit` (or repository boundary) receives a `sessionType` parameter
**When** the value is `'Mobility'`, `'mobility '`, `'MOBILITY'`, or empty
**Then** input is normalized to lowercase/trim before filtering and unknown variants are logged via `dart:developer.log` (FR26, NFR23)

**Given** `ExerciseLocalDataSource._loadFallback` parses `assets/data/fallback_exercises.json`
**When** two records share the same `id`
**Then** duplicates are deduplicated at load time with a logged warning, and a unit test covers the duplicate-ID case (NFR20)

**Given** `_bmad-output/implementation-artifacts/deferred-work.md` contains 28+ items as of Epic 6 closure
**When** the triage task runs
**Then** every item is classified as `PROMOTE` (moved to an active task with target story/epic), `KEEP` (remains deferred with updated re-evaluation trigger), or `CLOSE` (with rationale recorded); the file structure preserves history and adds the triage decision per item

**Given** Story 6.5.2 implementation is complete
**When** `flutter test` runs
**Then** new unit tests for sessionType normalization and fallback ID uniqueness pass alongside the existing suite without regression

### Story 6.5.3: Process Action-Item Ledger

As a project lead,
I want retro action items tracked in a structured ledger visible alongside sprint status,
So that commitments stop slipping silently between epics.

**Acceptance Criteria:**

**Given** retro action items exist from Epic 5 and Epic 6
**When** the ledger artifact is created
**Then** it lists each commitment with: source retro, description, owner, target epic/story, and status (`pending` / `in-progress` / `done` / `dropped` with rationale)

**Given** the ledger exists
**When** future retros run
**Then** the retrospective workflow includes a "review ledger" step where each pending item is reconfirmed, reassigned, or closed

**Given** the ledger is established
**When** Epic 7 kickoff begins
**Then** all Epic 5 + Epic 6 critical-path commitments are visible in the ledger with explicit status

### Story 6.5.4: Dependency Major Version Upgrades

As a developer,
I want core direct dependencies bumped to their latest resolvable major versions one cluster at a time,
So that Epic 7 builds on a current, supported dependency tree without absorbing migration risk inside a feature story.

**Background:** `flutter pub outdated` (run 2026-05-15, after the safe minor/patch sweep) reports the following direct dependencies blocked on older majors than the latest resolvable version. Each cluster is a breaking change requiring its own migration:

- `go_router` 15 → 17 (routing API breaking changes; touches `app_router.dart`, redirect logic, all `context.go/push` sites)
- `get_it` 8 → 9 **paired with** `injectable` 2.7 → 3 + `injectable_generator` 2.12 → 3 (DI container API + generator output change; requires `dart run build_runner build --delete-conflicting-outputs`)
- `geolocator` 13 → 14 + `geolocator_android` 4 → 5 (permissions/runtime API breaking change; touches `location_service.dart` and weather/location flows)
- `sensors_plus` 6 → 7 (stream API breaking change; touches accelerometer activity detection in Epic 3.2)
- `fl_chart` 0.70 → 1.2 (chart widget API breaking change; touches any chart usage on Progress / future Today screens)
- `google_fonts` 6 → 8 (font loader API; touches `theme.dart` font loading)

**Acceptance Criteria:**

**Given** each major-version cluster above
**When** the upgrade is applied
**Then** it is performed in its own commit (`chore(deps): bump <package> to <major>`) with the migration scoped to that cluster only — no mixing clusters in a single commit

**Given** an upgrade cluster has been applied
**When** `flutter analyze` and the full `flutter test` suite run from `pulse_coach/`
**Then** both pass with zero new issues and no test regressions versus the pre-bump baseline; any test changes are migration-required (API rename, signature change) and not silent assertion weakening

**Given** the DI cluster (`get_it` + `injectable` + `injectable_generator`) is being upgraded
**When** the bump is applied
**Then** `dart run build_runner build --delete-conflicting-outputs` is rerun and the regenerated `injection.config.dart` is committed alongside the pubspec change

**Given** all six clusters have been upgraded
**When** `flutter pub outdated` is run
**Then** no direct dependency in `pubspec.yaml` shows a `Resolvable` version newer than `Current`, OR any remaining gap is explicitly documented in this story's completion notes with rationale (e.g., upstream regression, intentional pin)

---

## Epic 7: Today Screen

**Goal:** Implement the Hero + Upcoming List Today screen layout with all required components, making the recommended next session immediately obvious and actionable.

**Pre-Epic Product Decisions (2026-05-15):** two blocking product reviews closed. See:
- `_bmad-output/implementation-artifacts/ai-state-graph-product-decisions-2026-05-15.md` — adds rules `active → atRisk` (Q1, depends on Story 7.1b), `recovering → fatigued` (Q2), tightens `→ recovering` (Q3).
- `_bmad-output/implementation-artifacts/explanation-copy-product-decisions-2026-05-15.md` — state-aware copy, friendly-coach tone, user-facing labels (`In forma`, `Sotto sforzo`, `In ripresa`, `In recupero`), 7 FR14 transition strings.
- `_bmad-output/implementation-artifacts/story-7.1b-scope-2026-05-15.md` — Story 7.1b scope.
- `_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md` — Story 7.0 scope.

**Binding constraints for Epic 7 sprint:**
- Story 7.1b must merge in the same PR cluster as Story 7.1, otherwise the new `active → atRisk` rule is removed before merge.
- Story 7.0 must merge before Story 7.1 (BLoC error contract must be pinned before consumers mount).

### Story 7.0: Failure Equality BLoC Re-emission Regression Test

As a developer,
I want a regression test that pins the `DailyPlanBloc` re-emission behavior when two equal `Failure` instances are emitted,
So that future edits to `Failure` equality or BLoC state shape do not silently change UI behavior on the Today screen.

**Acceptance Criteria:**

**Given** `Failure` has structural equality (`Object.hash(runtimeType, message)`, Story 6.5.3)
**When** the `DailyPlanBloc` emits two equal `Error(CacheFailure('X'))` consecutively
**Then** `bloc.stream` emits exactly one `Error` state (coalescing confirmed) — locked by test `6.5-EQ-BLOC-001`

**Given** the `DailyPlanBloc.Error` state exposes a `retryAttempts: int` field (default 0)
**When** the use case fails again and the bloc emits `Error(retryAttempts=N+1, sameFailure)`
**Then** `bloc.stream` emits both states because `retryAttempts` breaks structural equality — locked by test `6.5-EQ-BLOC-002`

**Given** `Error(CacheFailure('X'))` is emitted
**When** `Error(NetworkFailure('X'))` is then emitted
**Then** both events are observed because `runtimeType` differs — locked by test `6.5-EQ-BLOC-003`

**Given** the work completes
**When** `flutter test` runs
**Then** baseline is 388 → 391, and `flutter analyze` remains at 0

See `_bmad-output/implementation-artifacts/failure-equality-bloc-regression-spec-2026-05-15.md` for full file list, schema impact, and effort estimate (~0.25 day).

### Story 7.1: StateIndicator Component

As a user,
I want to see my current behavioral state with a plain-language explanation,
So that I understand why today's sessions are calibrated the way they are.

**Authoritative copy and tone:** all visible strings, user-facing labels, and FR14 transition messages are defined in `_bmad-output/implementation-artifacts/explanation-copy-product-decisions-2026-05-15.md`. The decision doc is load-bearing — its Q1 (state-aware), Q2 (friendly-coach tone), Q3 (user-facing labels), Q4 (transition strings), and Q5 (static sub-copy) are part of this story's AC.

**Acceptance Criteria:**

**Given** the `StateIndicator` widget is rendered
**When** `BehavioralState.active` is the current state
**Then** dot + user-facing label **"In forma"** in Primary color (`#7DD3C0`) and the static sub-copy *"Pronto per il piano di oggi."* are displayed (FR15, UX-DR11)

**Given** `BehavioralState.fatigued`
**When** the widget renders without a transition this cycle
**Then** dot + user-facing label **"Sotto sforzo"** in Secondary color (`#A78BDA`) and the static sub-copy *"Oggi alleggeriamo per recuperare."* (UX-DR11)

**Given** `BehavioralState.atRisk`
**When** the widget renders without a transition this cycle
**Then** dot + user-facing label **"In ripresa"** in Tertiary color (`#E8C87A`) and the static sub-copy *"Ripartiamo con calma. Sessioni brevi e leggere."* (UX-DR11)

**Given** `BehavioralState.recovering`
**When** the widget renders without a transition this cycle
**Then** dot + user-facing label **"In recupero"** in Secondary at 70% opacity and the static sub-copy *"Costruiamo il ritmo, un passo alla volta."* (UX-DR11)

**Given** `atRisk` and `recovering` share visually similar labels
**When** both are possible to encounter in user testing
**Then** the dot/icon for each state is visually disambiguated (e.g., `atRisk` = warning glyph; `recovering` = restore glyph). Final icon tokens chosen by Sally during implementation.

**Given** a `BehavioralTransition.stateChanged == true` reaches the widget
**When** the widget renders
**Then** the static sub-copy is **replaced** by the FR14 transition message corresponding to the `transition_{from}_{to}` key from `state_messages.it.arb` (decision doc Q4). Static sub-copy is used only when no transition fired this cycle.

**Given** the i18n contract
**When** `lib/l10n/state_messages.it.arb` is inspected
**Then** it contains exactly 15 keys: 7 `transition_{from}_{to}` keys (the 6 main transitions plus the duplicate `fatigued_recovering` mapped to the same string), 4 `state_label_{name}` keys, and 4 `state_static_{name}` keys.

**Given** the load-bearing invariant from state-graph decision Q2
**When** a regression test asserts string equality
**Then** `transition_active_fatigued` **must not equal** `transition_recovering_fatigued`. If a future edit makes them equal, the test fails. (If this test ever flips and the strings are intentionally unified, the state-machine target for `recovering` overload must revert from `fatigued` to `atRisk` — see decision doc.)

**Given** the BehavioralStateMachine rules updated by the state-graph decision
**When** Story 7.1 ships
**Then** the rule set in `lib/ai/state_machine/behavioral_state_machine.dart` matches `ai-state-graph-product-decisions-2026-05-15.md` §"Final Rule Set" — 6 prioritized rules. Note: the `active → atRisk` rule (priority 1) ships only if Story 7.1b also merges in the same PR cluster; otherwise it is removed before merge.

**Given** the widget is rendered
**When** checked for typography
**Then** state label uses H3 (Plus Jakarta Sans Medium 17sp); sub-copy uses Body Small (Plus Jakarta Sans Regular 13sp, On Surface Variant color); no emoji rendered in `StateIndicator`.

**Given** the writing rules from copy decision Q2
**When** any string in `state_messages.it.arb` is reviewed
**Then** it satisfies: seconda persona singolare; presente; constatazione + invito (mai diagnosi + prescrizione); una frase (al massimo due separate da em-dash); no internal state codes (`atRisk`, etc.); no clinical/gamified register; no `!` except in `recovering → active` and `state_label_active` strings.

### Story 7.1b: missedSessions Decay & Reset

As the AI engine,
I need a deterministic `missedSessions` counter derived from the daily-plan log,
So that the new `active → atRisk` rule (state-graph decision Q1) operates on a counter with reliable semantics and no stuck-state bugs.

**Binding:** must merge in the same PR cluster as Story 7.1. If Story 7.1b slips or is descoped, the `active → atRisk` rule (state-graph decision Q1) is **removed** from `behavioral_state_machine.dart` before Story 7.1 merge — no exception.

**Acceptance Criteria:**

**Given** `MissedSessionsCalculator` is implemented as pure Dart
**When** called with the last 7 days of `DailyPlanRecord` history, `expectedPerWeek`, and `now`
**Then** it returns `count of expected_session_days WHERE day ∈ [now-6d, now] AND completed = false`

**Given** cold start (no daily-plan records)
**When** `GenerateDailyPlan` runs
**Then** `StateVector.missedSessions = 0`

**Given** user has 3 daily plans in last 7 days with 1 completed
**When** `GenerateDailyPlan` runs
**Then** `missedSessions = 2`

**Given** user has 14 daily plans in last 14 days, all uncompleted
**When** `GenerateDailyPlan` runs
**Then** `missedSessions = 7` — older days are outside the rolling window (no explicit long-absence reset logic)

**Given** user completes a session today, prior 6 days had 3 misses
**When** `GenerateDailyPlan` runs
**Then** `missedSessions = 3` — recent completion does **not** erase prior misses within the window (preserves JTBD "disengagement" framing)

**Given** `StateVector.missedSessions >= 2` AND current state is `active`
**When** `BehavioralStateMachine.evaluate` runs
**Then** state transitions to `atRisk` with the FR14 message `transition_active_atRisk` from `state_messages.it.arb` ("Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi.")

**Given** priority guard
**When** state is `active` AND `missedSessions = 2` AND `last-2-RPE avg > 8`
**Then** `atRisk` wins over `fatigued` (priority 1 over priority 3)

**Given** the implementation lands
**When** code is inspected
**Then** no new Drift column has been added; `missedSessions` is computed on-the-fly from the existing daily-plan log; `behavioral_state_table` schema is unchanged.

**Given** test suite
**When** `flutter test` runs
**Then** baseline 388 → 401 (+13 tests: 8 calculator unit, 2 use-case integration, 3 state-machine rule tests); `flutter analyze` remains at 0.

**Pre-sprint verification (gating):** before sprint commit, Amelia confirms `daily_plans` table (or the Epic 5/7 equivalent) exposes per-day `completionStatus` with sufficient granularity for the window query. If absent, a ~2-hour "Story 7.1b-pre" migration task precedes 7.1b. See `_bmad-output/implementation-artifacts/story-7.1b-scope-2026-05-15.md`.

### Story 7.2: SessionCard Component

As a user,
I want to see session recommendations in a card that immediately conveys what to do and why,
So that I can decide whether to start in under 3 seconds.

**Acceptance Criteria:**

**Given** the `SessionCard` hero variant is rendered
**When** a `PlannedSession` with type, duration, intensity, and explanation is provided
**Then** the card displays: Lottie session type icon, session title, duration (e.g., "5 min"), intensity (e.g., "Low"), AI explanation (always visible, Body Small, On Surface Variant color), and a "Start Session" primary CTA button (FR13, UX-DR5)

**Given** the hero card is rendered
**When** visual inspection occurs
**Then** the card has 16dp padding on all sides, 16dp corner radius, Surface Container background, and a subtle gradient background area (UX-DR5, UX-DR17)

**Given** the compact list item variant is rendered (for "COMING UP" sessions)
**When** a session is provided
**Then** the card shows: session type icon, session name, duration, and a chevron — no explanation text, no Start button (UX-DR5)

**Given** a session type is Cardio
**When** the card renders
**Then** the accent color is soft coral (`#F0A1B0`); Mobility uses Primary (`#7DD3C0`); Breathing uses Secondary (`#A78BDA`) (UX-DR1)

### Story 7.3: Today Screen Layout & Hero Progression

As a user,
I want the Today screen to show my next recommended session as a prominent hero with remaining sessions below,
So that I know exactly what to do without any scanning or deciding.

**Acceptance Criteria:**

**Given** a `DailyPlan` with 3 sessions is loaded
**When** the Today screen renders
**Then** the layout is top-to-bottom: state bar (StateIndicator + small CompletionRing), hero `SessionCard` (full width, above fold), "COMING UP" section header, 2 compact `SessionCard` items (FR5, FR15, UX-DR6)

**Given** the Today screen renders on a standard phone
**When** inspected without scrolling
**Then** the hero card, state bar, Start button, and AI explanation are all visible — no scroll required to see the primary action (UX-DR6)

**Given** Session 1 is completed
**When** the user returns to Today
**Then** Session 2 becomes the new hero card; Session 3 moves to the "COMING UP" list with 1 item (UX-DR6)

**Given** all 3 sessions are completed
**When** the hero zone renders
**Then** it displays a "All done for today" completion state instead of a session card (UX-DR6)

**Given** the plan is loading
**When** inspected
**Then** shimmer placeholders matching the session card layout are displayed — no spinner (ARCH10)

**Given** no plan exists for today
**When** the screen first loads and generation is in progress
**Then** the loading state shows shimmer, completing within < 30 seconds (NFR1, NFR6)

### Story 7.4: CompletionRing Component & Plan Regeneration

As a user,
I want to see my daily session progress visually and be able to regenerate my plan,
So that I have a sense of accomplishment and can refresh sessions if they don't fit my current mood.

**Acceptance Criteria:**

**Given** the `CompletionRing` small variant is in the Today screen state bar
**When** 1 of 3 sessions is complete
**Then** the ring shows 1/3 progress (one segment filled in Primary color) (FR15, UX-DR12)

**Given** the ring is in the small (informational) variant
**When** viewed
**Then** it is visible but secondary — it does not compete with the hero card for visual attention (UX-DR12)

**Given** "Reduce Motion" is enabled
**When** the ring updates
**Then** it updates without animation — progress changes are instant (UX-DR12, UX-DR18)

**Given** the user taps the regenerate action (Lucide icon, secondary placement)
**When** tapped
**Then** the `DailyPlanRegenerateRequested` event is dispatched and the plan is regenerated with shimmer loading (FR11)

---

## Epic 7.5: i18n Migration (Interstitial)

**Goal:** Wire `flutter_localizations` + `gen_l10n`, then migrate the hardcoded Italian copy introduced across Epic 7 widgets into ARB-backed lookups, so Epic 8's new in-session UI (Countdown, InSessionView labels, abandon dialog) starts from a localized foundation instead of compounding the debt.

**Scope rules (per Epic 7 retrospective decision, 2026-05-16):**

- Cap: **2 stories max**.
- Must complete **before Epic 8 kickoff**.
- No new product features; pure infrastructure + migration.
- Zero-tolerance baselines (`flutter analyze` 0 issues, `flutter test` 503+/503+ all green) preserved at every commit.
- Story 7.5.1 ships infrastructure only — **no string migration**. Story 7.5.2 migrates strings — **no infrastructure changes**. The split is intentional: each story can roll back independently.

**Out of scope (explicit):**

- English `app_en.arb` content for any string not already needed for `gen_l10n` to compile. Italian is the only user-facing locale for MVP; English ARB exists as plumbing and may be left as stub identical to Italian for now.
- Onboarding / Sessions tab / Profile screens string migration — those screens still mix English/Italian. Only Epic 7 (Today screen) widgets are in scope. Other screens are tracked separately and may be migrated in a future Epic N.5 if the debt grows.
- Migrating `BehavioralStateMachine` transition message literals in `behavioral_state_machine.dart` — they are already authoritative copies of ARB strings (acknowledged duplication per Story 7.1 deferred item `state-machine source hardcodes Italian transition strings duplicating state_messages.it.arb`). A future story can collapse that duplication once the i18n pattern is established; not in Epic 7.5 scope.
- Pluralization (`Intl.plural`) and date/number formatting helpers. Add when a feature actually needs them.

### Story 7.5.1: Wire `flutter_localizations` + `gen_l10n`

As a developer,
I want `flutter_localizations` and `gen_l10n` wired into the project with a working ARB pipeline,
So that subsequent stories can resolve user-facing strings through `AppLocalizations.of(context)` instead of hardcoded literals.

**Acceptance Criteria:**

**Given** `pubspec.yaml` is inspected
**When** the project is fetched
**Then** `flutter_localizations: sdk: flutter` and `intl` (latest compatible with the current Flutter SDK) are direct dependencies, and `flutter: generate: true` is set under the `flutter:` key

**Given** `l10n.yaml` is created at `pulse_coach/l10n.yaml`
**When** inspected
**Then** it declares: `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `synthetic-package: true` (or `false` with explicit `output-dir` — pick one and document why)

**Given** `lib/l10n/app_en.arb` and `lib/l10n/app_it.arb` are created
**When** inspected
**Then** each file contains exactly one stub key (`@@locale`, `appTitle`) so `gen_l10n` produces a valid `AppLocalizations` class. **No Epic 7 strings are migrated in this story** — that is Story 7.5.2's scope.

**Given** `lib/main.dart` (and any `MaterialApp` constructor) is updated
**When** the app boots
**Then** `MaterialApp` carries `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`, and `locale: const Locale('it')` (fallback `en`). The Italian locale is forced for MVP per product decision.

**Given** the existing `lib/l10n/state_messages.it.arb` file
**When** Story 7.5.1 ships
**Then** the file is left untouched (it remains the inline-strings source). It will be folded into `app_it.arb` by Story 7.5.2 in the same migration pass.

**Given** a smoke widget test under `test/l10n/`
**When** it instantiates `MaterialApp` with the delegates and calls `AppLocalizations.of(context)!.appTitle`
**Then** it returns the Italian value (proving the delegate chain resolves correctly)

**Given** the work completes
**When** `flutter test` and `flutter analyze` run from `pulse_coach/`
**Then** test count grows by at most +3 (1 smoke test + 0–2 ARB-validation tests), `flutter analyze` shows 0 issues, and `dart run build_runner` is **not** required (gen_l10n runs as part of `flutter pub get` / build)

### Story 7.5.2: Migrate Epic 7 Italian Strings to ARB

As a developer,
I want every Italian string introduced during Epic 7 resolved through `AppLocalizations.of(context)` instead of being a hardcoded literal,
So that the Today screen is fully localized, the residual English "COMING UP" label is translated, and Epic 8 can extend the same pattern without first paying setup cost.

**Acceptance Criteria:**

**Given** the Epic 7 widgets are inspected after Story 7.5.2 ships
**When** the following files are grepped for Italian-only character patterns (`grep -nE "(à|è|é|ì|ò|ù|'[A-Za-zàèéìòù].{2,}')" lib/features/today/`)
**Then** **zero matches** appear in `today_page.dart`, `completion_ring.dart`, `completed_session_card.dart`, `state_indicator.dart`, `session_card_helpers.dart`, `hero_session_card.dart`, `compact_session_card.dart` — all user-visible Italian copy lives in `lib/l10n/app_it.arb`

**Given** `lib/l10n/app_it.arb` is inspected after migration
**When** counted
**Then** it carries (at minimum) the 15 keys previously in `state_messages.it.arb` (4 state labels + 4 static sub-copy + 7 transitions) **plus** the migrated TodayPage strings (regenerate tooltip + a11y label, "COMING UP" header in Italian, "Ottimo lavoro!" all-done state, "Tutte le sessioni completate per oggi.", "Impossibile caricare il piano.", `CompletionRing` a11y label, `CompletedSessionCard` a11y label, session display names, intensity labels, duration helper, hero card semantics + button label). Estimated count: 30–40 keys total. **The previous file `state_messages.it.arb` is deleted** in this story; its keys move under `app_it.arb`.

**Given** the previously-English "COMING UP" label in `today_page.dart`
**When** the Today screen renders
**Then** it shows the Italian translation (proposed: `"PROSSIME"` — Sally to confirm during this story's spec review)

**Given** the Story 7.1 invariant tests `7.1-ARB-001` (15-key count) and `7.1-ARB-002` (`transition_active_fatigued != transition_recovering_fatigued`)
**When** Story 7.5.2 ships
**Then** both tests are **updated, not deleted**: ARB-001 asserts the new total count of Italian user-facing keys; ARB-002 still pins the load-bearing Q2 invariant against `app_it.arb`. Test IDs remain stable.

**Given** `BehavioralStateMachine` transition message literals
**When** the implementation is inspected
**Then** they remain hardcoded Italian (out of scope per Epic 7.5 scope rules) — the ARB now carries the canonical copy, the state machine carries the implementation copy, and the duplication is recorded as a known deferred item with a follow-up trigger ("collapse when 3+ features consume state-machine messages directly").

**Given** the work completes
**When** `flutter test` and `flutter analyze` run from `pulse_coach/`
**Then** the full suite passes (target ≈ 506+/506+), `flutter analyze` shows 0 issues, on-device manual verification confirms the Today screen looks identical to pre-migration (Italian copy unchanged, "COMING UP" → "PROSSIME" only visible delta)

---

## Epic 8: In-Session Experience

**Goal:** Deliver a focused, distraction-free guided session from 3-2-1 countdown through step-by-step exercise execution with haptic feedback and live HR display.

> **Sprint binding (added 2026-05-16 per Epic 7 retrospective):**
> - **Story 8.0 (SessionLog DAO + per-session completion persistence) must merge before Story 8.1.** It closes E7-F1 (completion does not survive force-stop/relaunch) and gives `TodaySessionCubit` a stable plan ID, folding in the `_isSamePlan` heuristic refactor (Story 7.3 deferred item).
> - **`vibration` package must be added to `pubspec.yaml` before Story 8.3** (haptic feedback prerequisite). Land as a small `chore(deps)` commit.
> - **Epic 7.5 (i18n / `gen_l10n` migration) must complete before this epic kicks off** so new in-session widgets (Countdown, InSession step labels, abandon dialog copy) start localized rather than adding to the i18n debt.

### Story 8.0: SessionLog DAO + Per-Session Completion Persistence

As a returning user,
I want my session completion progress to survive closing and reopening the app,
So that the Today screen's progress ring and completed-session cards reflect what I actually finished today.

**Acceptance Criteria:**

**Given** the user has completed 1 or more sessions on the Today screen earlier today
**When** the user force-stops the app and relaunches it
**Then** the Today screen restores the same `CompletionRing` fraction and the same `CompletedSessionCard` stack that were visible before the force-stop (closes E7-F1)

**Given** a fresh install with no prior completions
**When** the Today screen loads
**Then** `CompletionRing` reads `0/N` and no `CompletedSessionCard`s are shown (no false positives from prior days)

**Given** a daily plan is regenerated (whether or not `generatedAt` and `sessions.length` are identical to the previous plan)
**When** `TodaySessionCubit` evaluates plan identity
**Then** it uses a stable persisted plan ID (not the `_isSamePlan` timestamp+length heuristic deferred from Story 7.3) — a same-second regenerate that produces identical length **does not** preserve stale completion state from the previous plan

**Given** the new persistence layer is in place
**When** `flutter test` and `flutter analyze` run from `pulse_coach/`
**Then** zero-tolerance baseline is preserved (analyze 0 issues) and the test suite grows with new DAO + cubit-persistence tests

### Story 8.1: CountdownOverlay

As a user,
I want a calm 3-2-1 countdown before a session starts,
So that I have a moment to transition mentally from the planning view to the physical activity.

**Acceptance Criteria:**

**Given** the user taps "Start Session"
**When** the transition to the session view occurs
**Then** a full-screen `CountdownOverlay` displays with 3 → 2 → 1 in JetBrains Mono 72sp, Primary color background accent, and 400ms ease-in-out number animations (UX-DR7, UX-DR18)

**Given** the countdown completes (after ~3 seconds)
**When** the overlay dismisses
**Then** the screen transitions to the full-screen `InSessionView` with the first exercise step loaded

**Given** "Reduce Motion" is enabled
**When** the countdown renders
**Then** numbers display statically — no animation between numbers; transition to session is an instant cut (UX-DR7, UX-DR18)

### Story 8.2: InSessionView — Timer & Step Display

As a user,
I want a full-screen, focused session view with a large timer and clear step instructions,
So that I can follow the session without any navigation or decisions.

**Acceptance Criteria:**

**Given** the `InSessionView` is rendered
**When** inspected
**Then** it shows: JetBrains Mono 48sp session timer (counting down), current exercise step name (H2 typography), step instructions (Body typography), and a linear progress bar showing steps remaining (UX-DR8)

**Given** the timer is running
**When** measured against NFR3
**Then** timer accuracy is within ±1 second over the full session duration (NFR3)

**Given** a session step is active
**When** the step completes and the next step begins
**Then** the UI transitions to the next step automatically — no user action required (FR17)

**Given** the `InSessionView` is active
**When** the user attempts to navigate away
**Then** no navigation elements are available except the recessive "Abandon" button (small, On Surface Variant color, not prominent) (UX-DR8)

**Given** the user is in the `InSessionView`
**When** inspected for layout
**Then** it uses 24dp horizontal padding, 32dp top padding, single-column centered layout — no grid (UX-DR8)

### Story 8.3: Haptic Feedback on Step Transitions

As a user,
I want a haptic buzz when each exercise step ends and the next begins,
So that I know to change exercise without looking at my screen.

**Acceptance Criteria:**

**Given** a step transition occurs during an active session
**When** the transition fires
**Then** a haptic feedback pattern is triggered via `vibration` package within 200ms of the step change (FR18, NFR4)

**Given** the device does not support haptic feedback (e.g., emulator or disabled)
**When** a step transition occurs
**Then** the app does not crash — haptic call is a no-op (ARCH9)

**Given** the session has > 1 step
**When** the entire session is completed
**Then** haptic feedback fires once for each step transition throughout the session

### Story 8.4: Live Heart Rate Display

As a user,
I want to see my live heart rate during a session when my sensor permits it,
So that I can monitor my effort level without stopping.

**Acceptance Criteria:**

**Given** the Health API returns live HR data during a session
**When** the `InSessionView` renders
**Then** live HR is displayed in the top-right corner (e.g., "♥ 72 bpm") in Caption typography (FR19, UX-DR8)

**Given** live HR data is unavailable (permission denied or sensor unavailable)
**When** the `InSessionView` renders
**Then** the HR display area is hidden — no empty state or error shown (ARCH9, UX-DR8)

**Given** HR data is available but temporarily delayed
**When** the display updates
**Then** the last known value is shown until a new reading arrives — no flickering

### Story 8.5: Session Abandon Flow

As a user,
I want to abandon a session mid-flow if needed,
So that I'm never locked into a session that isn't right for the moment.

**Acceptance Criteria:**

**Given** the user taps "Abandon" during an active session
**When** a confirmation is requested
**Then** a bottom sheet or dialog confirms intent with "Abandon Session" and "Keep Going" options (FR20)

**Given** the user confirms abandonment
**When** the session is abandoned
**Then** the session is marked as abandoned in the `sessions` table with elapsed time and last completed step recorded

**Given** a session is abandoned
**When** the flow continues
**Then** the RPE input screen is shown for the partial session — abandonment is treated as valid data (FR20, FR21)

---

## Epic 9: Feedback & Adaptation Loop

**Goal:** Collect RPE feedback after every session (completed or abandoned), update the bandit reward, trigger state machine evaluation, and auto-return to Today.

### Story 9.1: RPEInput Component

As a user,
I want to tap a single RPE number after a session with zero friction,
So that I can close the feedback loop in under 5 seconds without navigation.

**Acceptance Criteria:**

**Given** a session completes or is abandoned
**When** the RPE screen renders on a surface ≥ 516dp wide (tablet, landscape phone)
**Then** a single horizontal row of 10 circular tap targets (1-10) in JetBrains Mono 20sp is displayed (FR21, UX-DR9)

**Given** a session completes or is abandoned
**When** the RPE screen renders on a surface < 516dp wide (portrait phone)
**Then** two rows of five circular tap targets (1-5, 6-10) in JetBrains Mono 20sp are displayed, each target maintaining ≥ 48dp hit area (NFR24); this is the approved degrade from UX-DR9 for phone-width screens (see E9R-3 decision)

**Given** each tap target
**When** measured for touch area
**Then** visible diameter is 44dp with effective touch area ≥ 48dp (NFR24, UX-DR9)

**Given** the user taps a number
**When** the tap is registered
**Then** the number highlights immediately (150ms ease-out micro-animation) and the RPE value is submitted — no confirm button, no dialog (UX-DR9, UX-DR18)

**Given** the RPE is submitted
**When** persisted
**Then** it is written to the `rpe_feedback` table with `sessionId`, `rpeValue`, and `timestamp` (FR21)

**Given** the RPE submission Cubit (`RpeFeedbackCubit` or equivalent)
**When** spec is written under the **E8-P1 Cubit-lifecycle invariants** template
**Then** the AC set covers, at minimum: (a) `submit()` idempotency — duplicate taps within the 150ms animation window are a no-op; (b) `close()` cancels any pending stream subscription and async I/O; (c) `rpe_feedback` persistence-error paths emit an explicit `error(Failure)` state (NOT `debugPrint`-only — E8-T1 convergence point); (d) at least one test per invariant

**Given** the test guardrails for this story
**When** ARB-key assertions are written
**Then** **E7.5-P2 invariant pattern applies** — no `expect(userFacingKeys, hasLength(N))` magnitude-based assertions; use "no key removed / all keys load / new keys for this story present" invariants instead (closes E7.5-P2 hard gate per E8-P2)

**Given** the new `rpe_feedback` table (schemaVersion v7 → v8)
**When** the spec is drafted
**Then** **E8-P3 schema-bump cadence cap** is honored — the spec explicitly declares that no pending bump in Epic 9 can be consolidated with this one (RPE feedback is the only known Epic 9 schema change)

### Story 9.2: MiniSummary & CompletionRing Animation

As a user,
I want a brief summary after submitting RPE that auto-dismisses,
So that I feel acknowledged without needing to take any action.

**Acceptance Criteria:**

**Given** RPE is submitted
**When** the `MiniSummary` overlay renders
**Then** it shows: session type, duration completed, RPE recorded, and one-line system feedback (e.g., "Got it. Adjusting intensity tomorrow.") (UX-DR10)

**Given** the `MiniSummary` is visible
**When** the `CompletionRing` within it animates
**Then** the ring progresses from the previous session count to the new count (e.g., 1/3 → 2/3) during the 3-second display window (UX-DR10, UX-DR12)

**Given** this was the final session (3/3)
**When** the ring reaches full completion
**Then** the ring closes with a gentle pulse animation (400ms ease-in-out) (UX-DR12)

**Given** "Reduce Motion" is enabled
**When** the `MiniSummary` renders
**Then** the ring updates without animation; the overlay still appears and auto-dismisses (UX-DR18)

**Given** the auto-dismiss timer (3000ms + 300ms fade) completes
**When** the overlay fades
**Then** the user is returned to the Today screen with the completed session marked (UX-DR10)

### Story 9.3: Bandit Reward Update & State Machine Re-evaluation

As the system,
I want to update the bandit's arm weights and re-evaluate behavioral state after each RPE submission,
So that the next plan generation benefits from the new feedback immediately.

**Acceptance Criteria:**

**Given** RPE is submitted
**When** the `UpdateBanditReward` use case runs
**Then** the arm weight for the completed session's (type × intensity) pair is updated: reward is higher when RPE is near 6.5, lower when RPE deviates significantly (FR22)

**Given** the reward is calculated
**When** `BanditState` is updated in the database
**Then** the update is persisted to `bandit_state` table with a `updatedAt` timestamp (FR25)

**Given** the RPE history now has a new entry
**When** the `BehavioralStateMachine` re-evaluates
**Then** if the transition conditions are met, the `behavioral_state` table is updated and a transition message is generated (FR23)

**Given** the bandit reward update runs
**When** measured
**Then** it executes in a background Isolate — the UI thread is not blocked during this computation (ARCH7, NFR2)

**Given** the `BehavioralStateMachine.evaluate()` re-trigger logic (this story's core change)
**When** spec is written under the **E8-P1 Cubit-lifecycle invariants** template
**Then** the state-machine invocation Cubit/use-case covers: idempotency on re-entry, cancellation on dispose, explicit error state on Isolate failure (E8-T1 convergence)

**Given** `BehavioralStateMachine.evaluate()` signature is being touched in this story
**When** the spec is drafted
**Then** **E7.5-T1 is folded in as a stretch goal** — wire the 7 dead ARB `transition*` keys (`app_it.arb` / `app_en.arb`) through the consumer at lines `lib/ai/state_machine/behavioral_state_machine.dart:35,44,53,68,81,94`, replacing hardcoded Italian literals with `AppLocalizations` keys (or a `BehavioralTransition.transitionKey` enum the widget resolves). Stretch-allowable **only** if it does not expand epic scope; otherwise defer to Story 9.4 firm

**Given** E7.5-T1 is deferred from Story 9.3 stretch
**When** Story 9.3 retro confirms non-absorption
**Then** PM (John) creates a Story 9.4 at that point with E7.5-T1 as its sole scope (no placeholder is kept in `epics.md` until non-absorption is confirmed, per Deferred Items Budget rule)

---

## Epic 10: Progress & History

**Goal:** Display session history as a timeline and progress charts with animated transitions, giving users a clear view of their streak, RPE trends, and activity breakdown.

> **Epic 10 Kickoff Prep (from Epic 9 retro, 2026-05-24 — `epic-9-retro-2026-05-24.md`):**
> 1. **Story 10.0 (below)** closes the E8-T1 centralized-logger deliverable before chart/history error paths are added.
> 2. **E7-T2 viewport/golden test infra must be unblocked before Story 10.2** (re-targeted from Epic 11 via action item E9R-2). The RPE overflow `9.1-WIDGET-005` proved that widget tests at the default 800dp surface miss phone-width layout failures — Epic 10's four charts are the next exposure. Story 10.2 ACs require an explicit 360dp layout assertion.
> 3. **UX-DR9 two-row RPE degrade** (branch `fix/rpe-input-overflow-360dp`) pending Sally + John validation (action item E9R-3) — unrelated to Epic 10 scope but tracked.
> 4. No new schema bump expected in Epic 10 (read-side only) — preserves E8-P3.

### Story 10.0: Centralized Logger & Error-Path Convergence

As a developer,
I want a single structured logging facility that cubits and use cases route error paths through,
So that DAO/service failures are observable in both UI state and logs instead of being swallowed by scattered `debugPrint` / `developer.log` calls.

**Acceptance Criteria:**

**Given** a centralized logger is introduced (e.g. `lib/core/logging/`)
**When** a DAO or service call fails inside a cubit or use case
**Then** the failure both (a) emits an observable state event (an explicit `error(Failure)` state — never `debugPrint`-only) AND (b) produces a structured log entry through the central logger (E8-T1)

**Given** the scattered error-path logging from Stories 8.0/8.2/8.3/8.4/8.5 and 9.1/9.2/9.3
**When** this story is implemented
**Then** those call sites converge onto the central logger; no error path remains `debugPrint`-only (closes the 8.4 "project-wide observability gap" defer and the 8.5 "silent swallow of DAO failure" patch follow-up)

**Given** the logger
**When** built and release builds run
**Then** logging is a real sink in debug and a no-op-safe path in release (i.e. release does not "lie" — user-facing error state is independent of the log sink)

**Note:** This story closes the **E8-T1** Category A deliverable (action item E9R-1). It was triggered-and-ignored in Epic 9 (Story 9.1 was the trigger; only the symptom was mitigated via explicit error states). Scheduling it first in Epic 10 means subsequent history/chart error paths are built on the logger rather than retrofitted.

### Story 10.1: Session History Timeline

As a user,
I want to see a chronological timeline of all my completed and abandoned sessions,
So that I can track what I've done and see patterns in my activity.

**Acceptance Criteria:**

**Given** the user navigates to the Progress screen
**When** the history tab renders
**Then** sessions are displayed in reverse chronological order with: date, session type icon (Lottie/Lucide), session name, duration, and RPE value (FR29)

**Given** a session was abandoned
**When** it appears in the timeline
**Then** it is visually distinguished (e.g., muted opacity or an "Abandoned" label) from completed sessions

**Given** no sessions have been completed
**When** the history timeline renders
**Then** an empty-state text message ("No sessions yet. Start your first one today.") is displayed — minimal text only, **no illustration** (per UX spec "No empty states with illustrations", ux-design-specification.md §1424; confirmed on-device 2026-05-27)

**Given** the history is loading
**When** inspected
**Then** shimmer placeholders matching the session row layout are displayed (ARCH10)

### Story 10.2: Progress Charts

As a user,
I want to see animated charts of my key metrics (minutes/week, completion rate, RPE trend, session type breakdown),
So that I can understand my progress at a glance without interpreting raw data.

**Acceptance Criteria:**

**Given** the user views the Progress screen charts tab
**When** the charts render
**Then** 4 charts are displayed using `fl_chart`: minutes per week (line or bar), completion rate (ring or bar), RPE trend over time (line), session type breakdown (pie or donut) (FR30, UX-DR19)

**Given** the charts render for the first time
**When** they animate in
**Then** each chart has an entry animation (250ms ease-in-out minimum) appropriate to its chart type (FR32, UX-DR18)

**Given** new session data arrives (e.g., after completing a session)
**When** the charts update
**Then** they animate smoothly to the new data values — no instant jump (UX-DR19)

**Given** insufficient data exists (< 3 sessions)
**When** a chart would be meaningless
**Then** that chart is replaced with a placeholder message ("Complete more sessions to see your trend") rather than showing a misleading chart

**Given** the E7-T2 viewport/golden test infra (unblocked before this story per Epic 9 retro action E9R-2)
**When** the charts and their layout are tested
**Then** the test suite asserts all 4 charts render without overflow at a **360dp** surface (Samsung A520F width), not only the default 800dp `flutter_test` surface — closing the layout-blindness class of bug that produced the RPE overflow `9.1-WIDGET-005`

**Given** `fl_chart` and `google_fonts` are currently zero-import direct dependencies (deferred item 6.5.4)
**When** this story is drafted
**Then** the spec explicitly decides per package: **use** it here, or **prune** it from `pubspec.yaml` — no third "leave it dangling" outcome

### Story 10.3: Weekly Goal Progress

As a user,
I want to see how many sessions I've completed vs my weekly target,
So that I have a simple sense of whether I'm on track this week.

**Acceptance Criteria:**

**Given** the user's profile specifies available session frequency
**When** the Progress screen renders
**Then** a weekly goal indicator shows "X of Y sessions this week" with a visual progress bar (FR31)

**Given** the user meets their weekly target (3 sessions in a week)
**When** the indicator renders
**Then** the progress bar is fully filled in Primary color with a subtle completion state

**Given** the user has completed 0 sessions this week
**When** the indicator renders
**Then** it shows "0 of 3 sessions this week" with an encouraging message

---

## Epic 11: Responsive Layout & Navigation

**Goal:** Implement the tablet master-detail layouts, NavigationRail, and portrait/landscape orientation support so that the app feels native on any screen size.

### Story 11.1: Responsive Scaffold & NavigationRail (Tablet)

As a tablet user,
I want a side navigation rail instead of a bottom bar,
So that the navigation pattern is appropriate for larger screens.

**Acceptance Criteria:**

**Given** the app runs on a device with screen width ≥ 600dp
**When** the scaffold renders
**Then** a `NavigationRail` is displayed on the left side with the same 3 destinations (Today, Sessions, Progress) and a drawer toggle (FR38, ARCH15, UX-DR15)

**Given** the screen width < 600dp
**When** the scaffold renders
**Then** a `BottomNavigationBar` is displayed (FR37, ARCH15)

**Given** the breakpoint is implemented via `LayoutBuilder`
**When** the device is rotated and crosses the 600dp threshold
**Then** the navigation switches between rail and bottom bar without data loss or rebuild (ARCH15)

### Story 11.2: Tablet Today Screen (Master-Detail)

As a tablet user,
I want a master-detail Today screen layout,
So that I can see the session list and session detail simultaneously without navigation.

**Acceptance Criteria:**

**Given** the app is on a tablet (≥ 600dp width)
**When** the Today screen renders
**Then** left panel shows: state bar + all 3 sessions (hero highlighted), right panel shows: selected session detail with full AI explanation, Start button, and step preview (UX-DR15)

**Given** the user taps a session in the left panel
**When** it is selected
**Then** the right panel updates to show that session's details — no full-screen navigation

**Given** the completion ring
**When** viewed on tablet Today
**Then** it is visible in the left panel header area (UX-DR15)

### Story 11.3: Portrait & Landscape Orientation Support

As a user,
I want all key screens to support both portrait and landscape orientation,
So that I can use the app comfortably in either orientation.

**Acceptance Criteria:**

**Given** any key screen (Today, Sessions, Progress, InSessionView)
**When** the device is rotated
**Then** the layout adapts via `OrientationBuilder` — no data loss, no overflow, no broken layouts (FR39, UX-DR16)

**Given** the `InSessionView` is active and the device is rotated
**When** the orientation changes
**Then** the timer continues uninterrupted and session state is preserved

**Given** landscape orientation on a phone
**When** the Today screen renders
**Then** the layout adjusts (e.g., hero card and upcoming list side-by-side or scrollable) without content overflow

---

## Epic 12: WearOS Companion

**Goal:** Deliver a WearOS companion that displays the active session step, timer, and HR — after validating feasibility with an early spike.

### Story 12.1: WearOS Feasibility Spike

As a developer,
I want to validate that `wear_plus` supports the required in-session display on WearOS,
So that we commit to WearOS implementation only if it is technically feasible within the project constraints.

**Acceptance Criteria:**

**Given** `wear_plus` is integrated as a separate build target
**When** a minimal WearOS build is run on a WearOS emulator or device
**Then** basic Wear UI rendering (text + button) works within the Flutter build pipeline (ARCH13)

**Given** the spike is complete
**When** results are reviewed
**Then** a documented spike outcome is written: feasibility confirmed or deferred with reasoning. If deferred, Epic 12 stories 12.2-12.4 are moved to backlog

### Story 12.2: In-Session WearOS Display

As a user with a WearOS watch,
I want my watch to display the current exercise step, session timer, and live HR during an active session,
So that I can follow the session without holding my phone.

**Acceptance Criteria:**

**Given** the WearOS companion is connected and a session is active on the phone
**When** the in-session state is broadcast
**Then** the WearOS display shows: current step name, session countdown timer, and live HR (when available) (FR40)

**Given** the WearOS display is showing an active session
**When** the step timer counts down
**Then** the timer on the watch updates in sync with the phone timer (within 1 second accuracy)

**Given** the WearOS companion is connected
**When** a step transition occurs on the phone
**Then** the watch display updates to the new step within 1 second of the transition

### Story 12.3: Post-Session WearOS Summary

As a user with a WearOS watch,
I want to see a post-session summary on my watch,
So that I get session closure feedback on the device I'm wearing.

**Acceptance Criteria:**

**Given** a session completes or is abandoned
**When** the phone transitions to the RPE screen
**Then** the WearOS companion displays a brief post-session summary: session type, duration, and a prompt to rate RPE on the phone (FR41)

**Given** the summary is displayed
**When** RPE is submitted on the phone
**Then** the WearOS display returns to its ambient/idle state

### Story 12.4: WearOS Disconnect Resilience

As a user,
I want the phone session to continue independently if my watch disconnects mid-session,
So that a connectivity hiccup never interrupts my workout.

**Acceptance Criteria:**

**Given** a session is active and the WearOS companion disconnects
**When** disconnection is detected
**Then** the phone session continues without interruption — no error state, no pause (NFR22)

**Given** the WearOS reconnects during or after an active session
**When** reconnection occurs
**Then** the companion display resumes showing the current session state or post-session summary

---

## Epic 13: Offline & Data Sync

**Goal:** Guarantee all core features work without network connectivity and implement the deferred sync queue for data that needs eventual server sync.

### Story 13.1: Offline-First Core Features

As a user,
I want all core features to work without network connectivity,
So that I can use PulseCoach anywhere without worrying about connectivity.

**Acceptance Criteria:**

**Given** the device has no network connectivity
**When** the user opens the app
**Then** plan generation succeeds using cached exercises, cached weather/AQI (or indoor default), and RPE history — zero error states visible (FR45, NFR13)

**Given** no network connectivity
**When** a session is completed and RPE is submitted
**Then** the session is stored locally and the bandit is updated — no data loss (FR45)

**Given** no network connectivity
**When** the user navigates to Progress
**Then** history and charts render from local data — no "offline" error message (FR45)

**Given** the app goes offline mid-session
**When** the session continues
**Then** the session completes normally — no interruption from network loss

### Story 13.2: Deferred Sync Queue

As the system,
I want a deferred sync queue that processes events when connectivity returns,
So that data that needs eventual syncing is never lost due to temporary connectivity issues.

**Acceptance Criteria:**

**Given** a sync event is queued (e.g., completed session, RPE feedback) while offline
**When** it is written to `sync_queue` table
**Then** it is stored with event type, payload, `queuedAt`, and `retryCount = 0` (FR47)

**Given** connectivity returns
**When** the `SyncManager` processes the queue
**Then** events are processed in `queuedAt` order (oldest first) (NFR18)

**Given** a sync event fails on first retry
**When** retry is scheduled
**Then** the retry delay increases exponentially (1min, 2min, 4min, ...) capped at 1 hour, and `retryCount` is incremented in the database (NFR18)

**Given** a sync event succeeds
**When** processed
**Then** it is removed from the `sync_queue` table

### Story 13.3: Data Persistence Guarantees

As a developer,
I want explicit tests validating that all critical data survives app lifecycle events,
So that NFR15 and NFR16 are provably met and not just assumed.

**Acceptance Criteria:**

**Given** the app is force-closed mid-session
**When** the app is re-opened
**Then** the daily plan, session history, bandit state, and behavioral state are all intact in the database (NFR15)

**Given** the app is updated to a new version with a schema migration
**When** the app launches post-update
**Then** all existing user data (sessions, RPE feedback, bandit state) is accessible and the migration succeeds without data loss (NFR16, ARCH3)

**Given** `cachedAt` timestamps exist for weather and exercise data
**When** the TTL check runs
**Then** data within TTL is served; data outside TTL triggers a background refresh if network is available (NFR14)

---

## Epic 14: Settings, Theme & Extras

**Goal:** Implement theme toggling, privacy information, device settings, and MVP-if-time bonus features (AI Decision Log, data export).

### Story 14.1: Theme Toggle (Dark / Light / System)

As a user,
I want to choose between dark mode, light mode, or follow my system setting,
So that the app looks right for my environment and preferences.

**Acceptance Criteria:**

**Given** the user navigates to Settings
**When** the theme option is visible
**Then** 3 options are available: Dark, Light, System (FR48)

**Given** the user selects "System"
**When** `ThemeMode.system` is applied
**Then** the app theme follows the device's current dark/light setting (UX-DR20)

**Given** the user selects "Dark"
**When** the theme applies
**Then** the full dark palette (`#0F1119` surface) is active — this is the default on first launch (UX-DR20)

**Given** the user selects "Light"
**When** the theme applies
**Then** a light theme generated via `ColorScheme.fromSeed()` from the aqua green seed is applied (UX-DR20)

**Given** the theme is changed
**When** it is persisted via `ThemeCubit`
**Then** the selection is stored locally and applied on next app launch without re-selection

### Story 14.2: Privacy Information Screen

As a user,
I want to read a clear privacy information screen,
So that I can verify exactly what data is collected, stored, and shared.

**Acceptance Criteria:**

**Given** the user navigates to Privacy from the drawer
**When** the screen renders
**Then** it clearly explains: data stored on-device only, no external transmission for personalization, Health API data usage, location data is city-level only, GDPR compliance statement (FR49, NFR7, NFR12)

**Given** the privacy screen is displayed
**When** inspected
**Then** it makes no reference to external accounts, servers, or data sharing for personalization purposes

### Story 14.3: Device & Sync Settings Screen

As a user,
I want to manage my device integrations and sync status from a settings screen,
So that I can understand and control what the app connects to.

**Acceptance Criteria:**

**Given** the user navigates to Settings
**When** the screen renders
**Then** it shows: Health API permission status (granted/denied) with option to re-request, WearOS connection status (connected/disconnected), sync queue status (pending items count), and cache info (last weather update, exercise cache date) (FR50)

**Given** the user taps "Re-request Health Permission"
**When** the system dialog is triggered
**Then** the OS permission dialog appears and the status updates after the user responds

**Given** the sync queue has pending items
**When** the settings screen renders
**Then** the count of pending sync events is displayed and a "Sync Now" button is available (when connectivity is present)

### Story 14.4: AI Decision Log [MVP-if-time]

As an advanced user,
I want to see a log of the AI's session selection decisions,
So that I can understand how the system is learning and adapting to me.

**Acceptance Criteria:**

**Given** this story is implemented only if time permits before v1 launch
**When** the user navigates to AI Decision Log from the Settings drawer (Debug section)
**Then** a list of bandit decision records is displayed: date, StateVector summary → selected session type/intensity → RPE reward (FR51)

**Given** the log is displayed
**When** the user taps a row
**Then** an expanded view shows the full state vector fields that contributed to the decision

**Given** no decisions have been recorded (new user)
**When** the log renders
**Then** an empty state message is shown: "No decisions yet. Complete your first session to see how the AI is learning."

### Story 14.5: Data Export [MVP-if-time]

As a power user,
I want to export my session history and AI decisions as CSV or JSON,
So that I can analyze my data in external tools or maintain a personal record.

**Acceptance Criteria:**

**Given** this story is implemented only if time permits before v1 launch
**When** the user taps "Export Data" in Settings
**Then** a bottom sheet offers export formats: CSV and JSON (FR52)

**Given** the user selects JSON export
**When** the export runs
**Then** a JSON file is generated containing: all sessions (date, type, duration, RPE), weekly summaries, and bandit decision history — and shared via the OS share sheet

**Given** the user selects CSV export
**When** the export runs
**Then** a CSV file with session rows (date, type, duration, rpe, abandoned) is generated and shared via the OS share sheet

---

## Epic 15: Navigation Fix (v2.0)

**Goal:** Close the standing v1 UX defect where secondary drawer screens (Settings, Profile, Privacy, Debug) had no affordance to return to the primary shell (Today, Sessions, Progress) without restarting the app. This is a pure routing change — no backend, no new UI components. Ship first among v2 work.

### Story 15.1: Back Navigation from Drawer Secondary Screens

As a user,
I want an explicit way to return to the main app screens from Settings, Profile, Privacy, and Debug,
So that I can navigate back to Today, Sessions, or Progress without having to relaunch the app.

**Acceptance Criteria:**

**Given** the user opens the drawer and taps Settings
**When** the Settings screen renders
**Then** an AppBar back arrow (or equivalent top-left affordance) is visible that navigates back to the previously active primary tab (Today, Sessions, or Progress) without restarting the app (FR53)

**Given** the user opens Profile from the drawer
**When** the Profile screen renders
**Then** the same back affordance is present and returns to the primary shell

**Given** the user opens Privacy from the drawer
**When** the Privacy screen renders
**Then** the back affordance is present and returns to the primary shell

**Given** the user opens Debug from the drawer (dev mode only)
**When** the Debug screen renders
**Then** the back affordance is present and returns to the primary shell

**Given** the user is on a secondary drawer screen
**When** they tap the system back button (Android) or swipe back (iOS)
**Then** the behavior is consistent with the AppBar affordance — they return to the primary shell, not to an empty stack

**Given** the navigation routing in `app_router.dart`
**When** a secondary screen is pushed from the drawer
**Then** it is pushed onto the go_router navigation stack as a sub-route of the shell route, preserving tab state on pop

---

## Epic 16: Accounts & Authentication (v2.1)

**Goal:** Introduce optional cloud accounts via Supabase Auth (EU region), giving users the ability to sign in with email, Apple, or Google. Build the E2E-encrypted backup/restore mechanism and implement in-app account deletion (store-blocking FR77). All subsequent social and Pro features depend on this epic's `AuthBloc` and `EntitlementGate` skeleton.

### Story 16.1: Supabase Backend Initialization & Cloud Client Setup

As a developer,
I want the Supabase EU project initialized with migrations, RLS scaffolding, and the Flutter client registered,
So that all subsequent v2 stories can access the cloud backend through a single, properly configured client.

**Acceptance Criteria:**

**Given** the Supabase CLI is installed and configured
**When** `supabase init` is run at the repo root
**Then** a `supabase/` directory is created with `config.toml` targeting the EU region `eu-central-1` (Frankfurt) (ARCH17, NFR36)

**Given** the Supabase project is initialized
**When** the initial migration `0001_profiles_auth.sql` is applied
**Then** the `profiles` table exists with columns: `id` (uuid PK, references `auth.users`), `display_handle` (nullable text, unique), `install_cohort` (enum: pre_v2, post_v2), `visibility_tier` (enum: private, friends_only), `created_at` (timestamptz)

**Given** `supabase_flutter` is added to `pubspec.yaml`
**When** the app initializes in `main.dart`
**Then** `Supabase.initialize(url: ..., anonKey: ...)` is called once with the EU project credentials; the client is registered as a `@singleton` in `lib/core/cloud/supabase_client.dart` (ARCH25)

**Given** the client is initialized
**When** the app launches without any signed-in session
**Then** the `Supabase.instance.client.auth.currentSession` is null and the app loads the v1 free core normally — no crash, no sign-in prompt (FR56, NFR34)

**Given** a new Dart client dependency is introduced (`flutter_secure_storage`, `sign_in_with_apple`, `google_sign_in`)
**When** `flutter pub get` and `dart run build_runner build` are run
**Then** all packages resolve and injectable code generation completes without errors

### Story 16.2: Email / Apple / Google Sign-In and Sign-Out

As a user,
I want to optionally create a cloud account and sign in with email, Apple, or Google,
So that I can unlock backup, social, and Pro features without the account being required for the free core.

**Acceptance Criteria:**

**Given** the user taps an account-gated feature (backup, social, Pro)
**When** the `SignInSheet` appears
**Then** it is a dismissible bottom sheet offering three sign-in methods: Sign in with Apple, Sign in with Google, and Email/password — in that order per App Store guidelines (UX-DR24, NFR32)

**Given** the user dismisses the `SignInSheet` with the close gesture
**When** they return to the screen they came from
**Then** the free core is fully functional — dismissal never blocks or degrades v1 features (FR56, NFR34)

**Given** the user chooses Sign in with Apple
**When** the native Apple ID sheet completes successfully
**Then** a Supabase auth session is created; `AuthBloc` emits `authenticated` state with the user's UID; `flutter_secure_storage` persists the refresh token (NFR27)

**Given** the user chooses Sign in with Google
**When** the Google Sign-In flow completes
**Then** a Supabase auth session is created and the same `authenticated` state is emitted

**Given** the user signs in with email + password (new account)
**When** the registration form is submitted
**Then** Supabase sends a confirmation email; until confirmed, the user remains in `unconfirmed` state and cannot access backup/social/Pro; the free core remains accessible

**Given** the user is signed in
**When** they tap Sign Out in Settings → Account
**Then** `AuthBloc` emits `unauthenticated`; the Supabase session is cleared from `flutter_secure_storage`; the free core continues to function using local drift data (NFR34)

**Given** the sign-in call to Supabase fails (no connectivity)
**When** `AuthBloc` receives the error
**Then** it emits `error(AuthFailure('...'))`; the `SignInSheet` shows an inline error message and remains open; the free core is unaffected (ARCH26)

### Story 16.3: E2E-Encrypted Backup and Restore

As a signed-in user,
I want to opt in to backing up my profile, session history, and personalization state to my cloud account,
So that I can restore my data on reinstall or a new device, while keeping biometric-derived data private from the server.

**Acceptance Criteria:**

**Given** the user is signed in and navigates to Settings → Account → Backup
**When** the backup screen renders
**Then** backup is clearly presented as opt-in; a toggle enables cloud backup; the explanation states the data is encrypted with a key only the user holds (FR57, UX voice: plain language, not fine print)

**Given** the user enables backup for the first time
**When** the system generates an encryption key (passphrase-derived via Argon2 using `cryptography` pkg)
**Then** a one-time recovery phrase is shown; the user must explicitly acknowledge before proceeding; the key is stored locally in `flutter_secure_storage` and never uploaded

**Given** the backup key is established
**When** the user taps "Back up now"
**Then** the `e2e_backup_codec.dart` encrypts the drift export payload (profile + session history + bandit state) into a ciphertext blob; only the ciphertext blob + non-secret metadata (`schemaVersion`, `createdAt`) are uploaded to Supabase Storage — no plaintext personal field in any cloud row (NFR28, ARCH19)

**Given** a signed-in user reinstalls the app on a new device
**When** they sign in and navigate to Settings → Account → Restore
**Then** they are prompted for their recovery phrase; the ciphertext is downloaded from Supabase Storage; `e2e_backup_codec.dart` decrypts and restores the drift database

**Given** the user enters an incorrect recovery phrase
**When** decryption is attempted
**Then** the decryption fails gracefully with an inline error message; no partial data is written to drift; the user can retry or cancel

**Given** backup is offline (no connectivity)
**When** the user taps "Back up now"
**Then** the operation is queued; a subtle inline note reads "Sto usando i dati salvati — sincronizzerò appena disponibile"; the free core is unaffected (NFR34)

### Story 16.4: In-App Account Deletion and Data Export

As a user,
I want to delete my account and all associated server-side data from within the app,
So that I can exercise my GDPR right to erasure without needing to navigate to an external web flow.

**Acceptance Criteria:**

**Given** the user navigates to Settings → Account → Delete Account
**When** the delete account option renders
**Then** a destructive-action confirmation dialog appears with a two-step confirmation: the destructive action name is shown, Cancel is the dominant/primary button, and the confirm-delete button is clearly secondary (EXPERIENCE.md destructive-action pattern) (FR77)

**Given** the user confirms deletion
**When** the `delete_account` use case is called
**Then** the Supabase Edge Function `delete_account_cascade` is invoked; all server-side data (profile, friendships, shared content, feed entries, leaderboard entries) is deleted cascading from the FK structure; visible removal is immediate (NFR30)

**Given** the deletion call succeeds
**When** the cascade completes
**Then** the local auth session is cleared; the user is returned to the v1 onboarding screen (treated as a fresh install); local drift data is NOT deleted (v1 local data belongs to the device, not the account)

**Given** the deletion fails (connectivity issue)
**When** `AuthBloc` receives the error
**Then** the dialog shows an inline error; the account is NOT deleted; the user can retry; no partial deletion occurs

**Given** the user is signed in and navigates to Settings → Account → Export Data
**When** they tap "Esporta i miei dati"
**Then** the Supabase Edge Function `export_user_data` is invoked; a portable JSON file containing all server-side personal data (profile, friendships, feed entries, leaderboard points) is returned and shared via the OS share sheet (NFR30)

---

## Epic 17: Pro Subscription & Feature Gating (v2.2)

**Goal:** Introduce the Pro subscription tier via platform IAP (RevenueCat), implement the `EntitlementGate` that governs access to the three capability tiers (account-free free / signed-in free / Pro), apply the Progress history gate with pre-v2 grandfathering, and deliver the `ProUpsellSheet` with cooldown — the only place in the UI where the paywall speaks.

### Story 17.1: RevenueCat IAP Integration and EntitlementGate

As a developer,
I want RevenueCat integrated for cross-platform IAP and an `EntitlementGate` available to all routes and widgets,
So that Pro features can be gated consistently without inline `if (user.isPro)` checks scattered across the codebase.

**Acceptance Criteria:**

**Given** `purchases_flutter` is added to `pubspec.yaml`
**When** the app initializes
**Then** `Purchases.configure(...)` is called with the RevenueCat API key for the current platform; the singleton is registered in `lib/features/subscription/` (ARCH20)

**Given** `EntitlementGate` is implemented in `lib/core/cloud/entitlement_gate.dart`
**When** any widget or route calls `EntitlementGate.check(Feature.xxx)`
**Then** it returns one of three tiers: `accountFree`, `signedInFree`, or `pro`; the result is derived from the current auth state + active RevenueCat entitlement (ARCH20, FR59, FR62)

**Given** the app is in account-free mode (no sign-in)
**When** `EntitlementGate.check` is called for any Pro feature
**Then** the tier returns `accountFree`; no sign-in is required for v1 core features

**Given** the entitlement check fails due to connectivity
**When** `SubscriptionBloc` processes the error
**Then** it emits `error(SubscriptionFailure('...'))`; the last-known cached entitlement is used; the v1 free core is unaffected (NFR34)

**Given** an `@injectable` `SubscriptionBloc` is registered
**When** the app launches
**Then** the bloc initializes with the current entitlement state synchronously from RevenueCat's cache before the first frame renders — no loading flash on the gating UI

### Story 17.2: Progress History Free/Pro Gating with Grandfathering

As a pre-v2 user (grandfathered) or a Pro subscriber,
I want full access to my Progress history and all charts,
So that existing users are not retroactively paywalled for data they already had.

**Acceptance Criteria:**

**Given** a user who installed before v2 (installCohort = pre_v2)
**When** they open the Progress screen
**Then** the full session history timeline and all four animated charts are visible regardless of subscription state (FR61, ARCH25)

**Given** a post-v2 user with a free (non-Pro) account
**When** they open the Progress screen
**Then** only the current weekly goal widget is visible; the tab bar, history list, and charts are replaced by a single tappable prompt: "Lo storico completo è una funzione Pro." with no persistent lock icon or badge elsewhere (FR59, FR61, UX-DR25)

> **Reconciled 2026-06-23 (Epic 17 retro):** the original wording listed "the most recent session and the current weekly goal widget". The delivered Story 17.2 + implementation (`progress_page.dart`) show **only** the weekly goal widget + prompt (no recent-session card). AC aligned to as-built behavior (verified on-device).

**Given** a post-v2 free user taps the "Lo storico completo è una funzione Pro." prompt area
**When** the tap is registered
**Then** the `ProUpsellSheet` appears (see Story 17.3)

**Given** a post-v2 user purchases a Pro subscription
**When** RevenueCat confirms the entitlement
**Then** the full Progress history and charts appear in-place immediately — no celebration screen, no badge (UX voice: content is the reward, not the unlock)

**Given** the `installCohort` must survive reinstall for signed-in users
**When** a pre-v2 user signs in after reinstall
**Then** the `installCohort` value from the `profiles` Supabase row is applied, restoring grandfathered status (FR61, ARCH25)

### Story 17.3: ProUpsellSheet with Session-Day Cooldown

As a free-tier user,
I want the Pro upsell to appear only when I reach for a Pro feature and not again for the rest of the day,
So that I can evaluate Pro at my own pace without being nagged.

**Acceptance Criteria:**

**Given** a free-tier user taps a Pro-gated capability (e.g. full Progress history, social content creation)
**When** the tap is handled
**Then** the `ProUpsellSheet` appears as a bottom sheet stating the single relevant fact and offering two buttons: `Scopri Pro` (primary) and `non ora` (secondary, dismiss) (UX-DR25)

**Given** the `ProUpsellSheet` is visible
**When** the user taps `non ora`
**Then** the sheet dismisses; a cooldown timestamp is recorded locally; the `ProUpsellSheet` does NOT appear again for the remainder of the current session/day for any Pro-gated tap

**Given** the cooldown is active
**When** the user taps another Pro-gated feature
**Then** the tap is silently ignored (no sheet, no error, no visual feedback on the lock) — the feature simply does not activate

**Given** a new day begins (midnight, device time)
**When** the user taps a Pro-gated feature
**Then** the cooldown has reset; the `ProUpsellSheet` may appear once more per day

**Given** the user is on the free Progress screen
**When** the screen renders
**Then** there is NO persistent lock icon, badge, or "🔒" glyph visible anywhere on Free screens — the paywall speaks only through the sheet, never through ambient pressure signals (UX-DR25)

### Story 17.4: Subscription Purchase, Restore, and Management

As a user,
I want to purchase, restore, and manage my Pro subscription within the app,
So that I can upgrade, cancel, or recover my subscription through standard store flows.

**Acceptance Criteria:**

**Given** the user taps `Scopri Pro` in the `ProUpsellSheet`
**When** the paywall page renders (via `features/subscription/presentation/pages/paywall_page.dart`)
**Then** the available Pro plan(s) are fetched from RevenueCat and displayed with price and billing period; no price is hardcoded (FR58)

**Given** the user taps the purchase button on a Pro plan
**When** the platform IAP sheet completes successfully
**Then** RevenueCat confirms the entitlement; `SubscriptionBloc` emits `loaded(entitlement: pro)`; `EntitlementGate` updates; Pro features unlock in-place (FR58)

**Given** a returning user has previously purchased Pro on another device
**When** they tap "Ripristina acquisti"
**Then** RevenueCat restores the entitlement from the platform store; `SubscriptionBloc` emits the updated entitlement; Pro features unlock (FR60)

**Given** a Pro subscriber wants to cancel
**When** they tap "Gestisci abbonamento" in Settings → Account
**Then** the app opens the platform's subscription management page (App Store or Play Store) via a URL; no custom cancellation flow is implemented (FR60, NFR32)

---

## Epic 18: Social Graph & Friends (v2.3)

**Goal:** Build the social graph layer: username/handle setup with privacy-by-default, the friend request flow, a friends-only activity feed showing explicitly-shared completions with light reactions, and a friends progress comparison view. All social content creation requires Pro. This epic depends on Epic 16 (auth) and Epic 17 (EntitlementGate).

### Story 18.0: Auth/Backup Datasource Test Hardening (closes E16R-1)

> **Critical-path prerequisite (Epic 17 retro, 2026-06-23 — E17R-2).** This is the deferred `E16R-1` test-hardening item, promoted to a standalone story per Paolo's decision. It MUST be scheduled and `done` **before Story 18.1 enters the sprint**, because Epic 18 works heavily on `profiles` + RLS + restore, and the restore-integrity fix from Story 16.3 (a P1) still has no dedicated regression test. `E16R-1` slipped through all four Epic 17 stories (annotated in every fire-check, never enforced — see E17R-3).

As a developer,
I want a regression test for the Drift export→restore round-trip and a safety assertion that `signOut()` runs only after a successful (200) server response,
So that the critical restore-integrity path (Story 16.3 P1 fix) and the "no partial sign-out state" safety property (Story 16.4 AC2/AC4) are protected against regression before the social layer builds on `profiles`.

**Acceptance Criteria:**

**Given** a populated local database is exported and then restored from the export blob
**When** the restore round-trip completes
**Then** a regression test asserts the restored data is byte-for-byte / row-for-row equivalent to the original (closes the 16.3 P1 restore-integrity coverage gap, which currently has no dedicated test)

**Given** a sign-out is requested against the auth/backup datasource
**When** the server response is non-200 (failure)
**Then** a test asserts `signOut()` does NOT run — no partial/orphaned local state is produced (closes 16.4-D2, merged into E16R-1 at the Epic 17 kickoff triage)

**Given** the new tests are added
**When** the suite runs
**Then** `flutter test` stays green and `flutter analyze` reports 0 issues; the action-item ledger marks `E16R-1` / `E17R-2` as `done`

### Story 18.1: Username Handle Setup and VisibilityTierSelector

As a signed-in user,
I want to set a unique username/handle and control who can see my activity,
So that I can participate in the social layer on my own terms with privacy as the default.

**Acceptance Criteria:**

**Given** the user signs in for the first time
**When** prompted to set up their social profile
**Then** they are invited to set a unique username/handle; this step is skippable (social handle is optional within free tier); the profile is set to `visibility_tier = private` by default (FR63, UX-DR30, NFR29)

**Given** the user submits a username
**When** the handle is validated against the `profiles` table
**Then** if unique: the `display_handle` column is updated and the profile becomes reachable by that handle; if duplicate: an inline validation error is shown without leaving the screen

**Given** the `VisibilityTierSelector` component renders in Profile settings
**When** the user selects a visibility tier
**Then** the available tiers are: `Privato` (default), `Solo amici`; the selection is persisted to `profiles.visibility_tier` via a Supabase PATCH; RLS immediately reflects the new policy (UX-DR30, NFR29)

**Given** a profile is set to `Privato`
**When** any other user's client queries the `profiles` table
**Then** RLS returns no row for this user — privacy is enforced at the DB, not the client (ARCH22, NFR29)

### Story 18.2: Friend Request Flow

As a Pro user,
I want to add friends by username, QR code, or phone contacts and manage pending requests,
So that I can build a friends list to participate in the social features.

**Acceptance Criteria:**

**Given** the user opens the Social tab → Friends
**When** the Friends screen renders
**Then** they see: a search field (add by username), a "Mostra il mio QR" button, an "Importa dai contatti" option, a list of pending requests (sent + received), and their current friends list (FR64, FR65)

**Given** the user searches for a username
**When** a matching `display_handle` is found in `profiles` and the target's visibility allows discovery
**Then** a `FriendRow` (UX-DR26) shows the handle with a "Aggiungi amico" button; tapping it inserts a `friendship` row with `status = pending` (FR64, ARCH22)

**Given** the target user views their pending requests
**When** they tap "Accetta"
**Then** the `friendship.status` is updated to `accepted`; RLS now grants mutual friends-only data access; both users' friend lists update reactively (FR65)

**Given** the target user taps "Rifiuta"
**When** the refusal is processed
**Then** the `friendship` row is deleted; neither party sees the request again; no notification is sent about the refusal

**Given** a user taps "Rimuovi amico" on a current friend
**When** the removal is confirmed
**Then** the `friendship` row is deleted; the removed user no longer appears in each other's friend lists; shared feed data already posted remains visible until individually revoked (FR65)

**Given** the user taps "Mostra il mio QR"
**When** the QR screen renders
**Then** a QR code encoding their `display_handle` is shown; scanning it on another device pre-fills the friend search

### Story 18.3: Activity Feed with Light Reactions

As a Pro user,
I want to see completed sessions my friends have explicitly shared and send a light reaction,
So that I can feel connected to friends' progress without biometric detail being exposed or pressure being created.

**Acceptance Criteria:**

**Given** a Pro user completes a session
**When** the `MiniSummary` resolves
**Then** an optional "Condividi con gli amici" toggle appears; it defaults to OFF; sharing must be an explicit user choice (FR66, NFR29)

**Given** the user enables the share toggle
**When** the session is saved
**Then** an `activity_feed` row is inserted: `owner_id`, `session_type`, `duration_minutes`, `completed_at` — no RPE value, no HR, no other biometric field (NFR29, UX-DR27)

**Given** a friend opens the Social tab → Feed
**When** the feed renders
**Then** shared entries appear as `ActivityFeedCard` components showing: friend's handle, session type icon, duration, and relative time — no biometric detail (UX-DR27)

**Given** the viewer taps the single reaction tap target on a feed card
**When** the reaction is registered
**Then** the `activity_feed` row receives a `reactions` increment; a single-tap visual acknowledgement plays (e.g., the icon briefly scales); no push notification is sent to the poster; the aggregate reaction count is NOT shown as a visible number to anyone (UX-DR27, UX-DR31)

**Given** the sharer navigates to their own shared entry and taps "Revoca condivisione"
**When** the revocation is confirmed
**Then** the `activity_feed` row is deleted; it disappears from all friends' feeds immediately (NFR29)

### Story 18.4: Friends Progress Comparison

As a Pro user,
I want to compare my weekly progress metrics against friends who have opted in to comparison,
So that I can see how I'm doing relative to my social circle without competitive pressure.

**Acceptance Criteria:**

**Given** a Pro user opens Progress → Confronto amici
**When** the comparison view renders
**Then** a list of friends who have `visibility_tier = friends_only` (or per-item sharing covering progress) is shown with their weekly metrics: sessions completed vs weekly goal and minutes of movement — no RPE, HR, or behavioral state exposed (FR67, NFR29)

**Given** a friend has `visibility_tier = private`
**When** the comparison view queries the `profiles` and `activity_feed` tables
**Then** RLS returns no data for that friend — they do not appear in the comparison list (ARCH22, NFR29)

**Given** the user's own data is displayed in the comparison view
**When** the screen renders
**Then** the user's own entry is visually distinguished (e.g., slightly highlighted) but uses the same layout as friends' entries — no "You're winning!" framing or overtaken alerting

---

## Epic 19: Real-Time Session Transport (v2.4a)

**Goal:** Implement the Supabase Realtime Broadcast/Presence infrastructure as a standalone, testable layer before shared session logic is layered on top. This epic delivers the `RealtimeGateway` Dart stream, host-authority enforcement, and drop-out tolerance — prerequisites for Epic 20 (Co-Located Shared Sessions).

### Story 19.0: Profile Row Creation on Signup (closes E18R-5)

> **Critical-path prerequisite (Epic 18 retro / E18R-3 live spike, 2026-06-24 — E18R-5).** It MUST be scheduled and `done` **before Story 19.1 enters the sprint**, because Epic 19 stacks realtime presence on `auth` + `profiles`, and the E18R-3 live-backend spike proved that a genuinely new user has **no `profiles` row** at all: `SocialProfileRemoteDataSource` only issues `UPDATE`s, and no DB trigger or edge-function creates the row at signup. A real new user can therefore never set a handle (the `UPDATE` matches 0 rows and throws), and presence/handle-based discovery in Epic 19 would have no profile to resolve. (Same "prerequisite story closes a foundational gap before the epic builds on it" pattern as Story 18.0 closing E16R-1.)

As a newly-registered user,
I want a `profiles` row to exist automatically the moment my account is created,
So that I can set my handle, choose my visibility tier, and be discoverable — and so the realtime social layer has a profile to resolve.

**Acceptance Criteria:**

**Given** a new user completes email (or Apple/Google) signup
**When** the `auth.users` row is created
**Then** a matching `public.profiles` row is created automatically (id = `auth.users.id`, `visibility_tier = 'private'` default, `install_cohort = 'post_v2'`, `display_handle = null`) — implemented as a Postgres `handle_new_user` trigger on `auth.users` (preferred; server-authoritative) so it fires for every provider, not only the email path

**Given** the new `profiles` row exists
**When** the user opens the Account page and submits a handle
**Then** `updateHandle` succeeds (the `UPDATE ... .single()` now matches exactly one row) — closing the E18R-3 finding where a fresh user's handle setup threw because no row existed

**Given** the trigger is added as a new Supabase migration (`supabase/migrations/0008_*.sql`)
**When** the migration is applied
**Then** it is idempotent and back-fills a `profiles` row for any pre-existing `auth.users` lacking one; a regression/integration test asserts that a freshly-created auth user has exactly one `profiles` row with the documented defaults

**Given** signup with a no-MX / invalid email domain (the E18R-6 finding)
**When** GoTrue returns `400 email_address_invalid`
**Then** the app surfaces a clear localized message (not the generic "Accesso non riuscito. Riprova.") — this AC folds the minor E18R-6 item into this story; if descoped, E18R-6 remains a standalone open item

### Story 19.1: RealtimeGateway and Supabase Broadcast/Presence Channel

As a developer,
I want a `RealtimeGateway` that exposes a typed Dart stream of broadcast events and presence state,
So that `SharedSessionBloc` can subscribe without ever touching the Supabase channel directly.

**Acceptance Criteria:**

**Given** `RealtimeGateway` is implemented at `lib/core/cloud/realtime_gateway.dart`
**When** `RealtimeGateway.joinChannel(sessionId)` is called
**Then** a Supabase Realtime channel `shared-session:{sessionId}` is opened; the gateway exposes two typed Dart streams: `Stream<BroadcastEvent>` and `Stream<PresenceState>` (ARCH21, ARCH27)

**Given** the gateway is connected to a channel
**When** a broadcast event `step_advanced` is received
**Then** the `BroadcastEvent.stepAdvanced(stepIndex: int, elapsedSeconds: int)` event is emitted on the typed stream; `SharedSessionBloc` receives it and updates state without accessing `RealtimeGateway` internals

**Given** `RealtimeGateway` is registered as `@singleton`
**When** `dart run build_runner build` is run
**Then** injectable code generation registers the gateway; all dependents can inject it via the constructor

**Given** the channel is open
**When** `RealtimeGateway.leaveChannel()` is called
**Then** the Supabase channel is cleanly unsubscribed; both Dart streams complete; no dangling subscriptions remain

### Story 19.2: Host-Authority Step Advancement and Presence Lobby

As the host of a shared session,
I want to be the sole authority that advances steps, with all followers rendering my broadcast,
So that all participants see a synchronized session state without divergence.

**Acceptance Criteria:**

**Given** the session is in progress and the current user is the host
**When** the session timer advances to the next step
**Then** only the host's `SharedSessionBloc` emits a `step_advanced` broadcast event via `RealtimeGateway`; follower clients never emit this event independently (ARCH21)

**Given** a follower receives a `step_advanced` event
**When** `SharedSessionBloc` processes the event
**Then** it updates the session state to the received step index and elapsed time; the UI re-renders the new step immediately; any local timer drift is corrected to match the host's elapsed time

**Given** a `PresenceState` event fires with all participants
**When** the `SharedSessionLobby` renders
**Then** all joined participants are listed with their display handles; a "Start" button is only active when ≥2 participants are in Presence (the host + at least one follower)

**Given** the host taps "Start"
**When** the `session_started` broadcast event fires
**Then** all participants' `SharedSessionBloc` instances simultaneously emit `inSession` state; all clients transition to the synchronized `InSessionView` at step 0 (UX-DR29)

**Given** a `Semantics(liveRegion: true)` is required for group-pushed step advances
**When** `SharedSessionBloc` emits a `stepAdvanced` state
**Then** the step name widget in `InSessionView` is wrapped in `Semantics(liveRegion: true, label: '...')` so screen readers announce the new step to AT users silently advanced by the group (UX-DR32, EXPERIENCE.md accessibility)

### Story 19.3: Drop-Out Tolerance and Reconnect

As a shared session participant,
I want the session to continue uninterrupted if another participant drops out or loses connectivity,
So that a network issue for one person does not ruin the session for everyone else.

**Acceptance Criteria:**

**Given** a follower loses connectivity mid-session
**When** their Presence entry disappears from the channel
**Then** the host's `SharedSessionBloc` emits a `participantDropped` state; the session continues without interruption for remaining participants; a subtle inline note appears: "[handle] si è disconnesso" (NFR31, UX-DR29)

**Given** a dropped participant regains connectivity
**When** they re-join the Presence channel
**Then** their `SharedSessionBloc` receives the current step + elapsed time from the host's next `step_advanced` event and snaps to the correct position; they rejoin the session in progress

**Given** the host loses connectivity
**When** Presence confirms the host is gone
**Then** leadership is transferred to the next participant in alphabetical join order; the new host takes authority for `step_advanced` emissions; no session interruption for followers

**Given** all participants finish the session
**When** the last `session_ended` broadcast fires
**Then** `RealtimeGateway.leaveChannel()` is called; each participant's `SharedSessionBloc` transitions to the RPE input state independently

---

## Epic 20: Co-Located Shared Sessions (v2.4b)

**Goal:** Build the complete shared session user experience on top of the Epic 19 real-time transport: join code/QR creation, the `GroupConstraintResolver`, momentary co-location confirmation, the `SharedSessionLobby`, synchronized start, and per-participant RPE with Protective-State Social Suppression enforcement. Depends on Epics 16, 17, 18, and 19.

### Story 20.1: Shared Session Creation — JoinCodeCard and Lobby Navigation

As a Pro user,
I want to create a shared session and share a join code / QR so co-located friends can join,
So that we can start a group session together in person.

**Acceptance Criteria:**

**Given** the user is a Pro subscriber with at least one friend in their friends list
**When** they tap "Sessione condivisa" in the Social tab
**Then** a `shared_sessions` row is inserted in Supabase; a random, human-readable 6-character join code is generated and stored (FR68, ARCH22)

**Given** the session row is created
**When** the `SharedSessionLobby` page renders
**Then** the `JoinCodeCard` displays the join code in large JetBrains Mono typography and a QR code encoding it; a "Aggiorna codice" button allows refreshing without creating a new session (UX-DR29)

**Given** the host is waiting in the lobby
**When** no friend has joined after 5 minutes
**Then** an inline message prompts "Nessuno ancora — condividi il codice" but the lobby remains open indefinitely with no expiry countdown (UX-DR29 "no expiry countdown pressure")

**Given** the user taps "Annulla" in the lobby before anyone joins
**When** the cancellation is confirmed
**Then** the `shared_sessions` row is deleted; the Realtime channel is left; the user returns to the Social tab

### Story 20.2: GroupConstraintResolver — Deterministic Group Plan Generation

As a developer,
I want a pure-Dart `GroupConstraintResolver` that deterministically computes the group plan constraints from all participants' profiles,
So that the shared session plan is safe for everyone and its rules are fully testable.

**Acceptance Criteria:**

**Given** `GroupConstraintResolver` is implemented at `lib/ai/safety/group_constraint_resolver.dart`
**When** it receives a `List<ParticipantProfile>` where each profile contains `safetyCapIntensity`, `fitnessLevel`, `movementExclusions`, `availableTimeMinutes`
**Then** it returns a `GroupConstraint` with: `intensityCeiling = min(safetyCapIntensity for all)`, `fitnessLevel = lowest(fitnessLevel for all)`, `movementExclusions = union(movementExclusions for all)`, `durationMinutes = min(availableTimeMinutes for all)` (FR70, ARCH24)

**Given** any participant's individual v1 FR9 safety rule would block the group plan
**When** the `GroupConstraintResolver` runs after the deterministic group rules
**Then** the group plan is further reduced to satisfy the most restrictive per-user safety override — the per-user FR9 rules are applied on top of, not instead of, the group rules (FR70)

**Given** `group_constraint_resolver_test.dart` in `test/domain/ai/`
**When** the test suite runs
**Then** every combination of group rule (min cap, lowest level, union exclusions, shortest duration) is tested exhaustively with at least 4 edge cases: single participant, all-same profile, heterogeneous mixed group, and group with one AtRisk participant triggering intensity override (ARCH24)

**Given** `GroupConstraintResolver` is pure Dart
**When** any import is added to the file
**Then** `flutter analyze` rejects any `import 'package:flutter/...'` — no Flutter dependency is permitted (same rule as v1 AI engine) (ARCH24)

### Story 20.3: Co-Location Join Flow — Momentary Non-Blocking Confirmation

As a friend joining a shared session,
I want to join by entering the join code or scanning the QR and have my proximity confirmed non-intrusively,
So that I can start the session without being blocked by a location gate.

**Acceptance Criteria:**

**Given** a friend opens the Social tab and taps "Unisciti a una sessione" (or scans the QR from `JoinCodeCard`)
**When** the join code is submitted
**Then** the `session_participants` row for this user is inserted; they enter the `SharedSessionLobby` Presence channel (FR68, FR69)

**Given** the participant is in the lobby
**When** a momentary co-location check is triggered
**Then** `geolocator` reads the current position once (a single, non-continuous read); the boolean result ("co-located" if within ~100m of the host) is computed locally and NOT stored anywhere; only the boolean is used by the lobby to display a soft visual cue (FR69, NFR33)

**Given** the co-location check is inconclusive (GPS unavailable, distance > threshold, or permission denied)
**When** the check resolves
**Then** the friend is NOT blocked from joining; the lobby proceeds normally; no error is shown to either participant; the soft check failing does not gate session start (FR69, NFR33)

**Given** the session has already started (host tapped Start) and a friend tries to join late
**When** they submit the join code
**Then** they are informed the session is already in progress; they cannot join mid-session; they are offered to create their own session or wait for the next one

### Story 20.4: Synchronized Session Start and Shared InSessionView

As a shared session participant,
I want all devices to show the same step and timer in real time when the session starts,
So that the experience of exercising together is synchronized regardless of device.

**Acceptance Criteria:**

**Given** all expected participants are in the lobby (Presence) and the host taps "Inizia"
**When** the `session_started` broadcast fires
**Then** all participants' `SharedSessionBloc` instances simultaneously transition to `inSession` state; all clients render `InSessionView` at step 0 with the timer at 0:00 (FR71, UX-DR29)

**Given** the host's timer advances to the next step
**When** `SharedSessionBloc` emits `step_advanced` via `RealtimeGateway`
**Then** all follower clients receive the event within ~1 second; their UI advances to the matching step without any user action; the timer snaps to the host's elapsed time (NFR31)

**Given** the `InSessionView` is the shared variant
**When** it renders
**Then** a subtle participant count indicator shows how many users are in the session (e.g., "2 partecipanti"); otherwise the layout is identical to the v1 solo `InSessionView` — no additional complexity

**Given** haptic feedback on step transition (v1 behavior)
**When** a follower's `InSessionView` receives a `step_advanced` state
**Then** `HapticFeedback.mediumImpact()` fires within 200ms of the state update, exactly as in solo sessions (NFR4)

**Given** the session ends (last step completes)
**When** the `session_ended` broadcast fires
**Then** each participant's `SharedSessionBloc` transitions independently to the RPE input state; each device handles RPE collection autonomously (FR72)

### Story 20.5: Per-Participant RPE and Protective-State Social Suppression

As a shared session participant,
I want to submit my own RPE after the session and have the social layer respect my recovery state,
So that social pressure never overrides the v1 recovery-empathy promise.

**Acceptance Criteria:**

**Given** the shared session has ended
**When** each participant reaches the RPE input screen
**Then** the RPE prompt and interaction are identical to the v1 solo flow; there is no indication of what other participants rated; each rating is submitted independently and feeds only that user's on-device bandit (FR72)

**Given** a participant is in `AtRisk` or `Recovering` behavioral state
**When** they are in a shared session lobby or receive a shared session invitation
**Then** the app does NOT proactively surface "start a shared session" CTAs on the Today screen; incoming join codes still function if they choose to join voluntarily, but the app never nudges (UX-DR31)

**Given** a participant in `AtRisk`/`Recovering` completes a shared session
**When** the session is saved and leaderboard points would normally be awarded
**Then** points ARE awarded (the session happened and was safe); however rank movement is NOT surfaced to the user on the Today screen — any leaderboard update is silently applied in the Social tab only (UX-DR31)

**Given** the group plan is generated for a participant currently in `AtRisk`
**When** `GroupConstraintResolver` runs
**Then** that participant's AtRisk safety cap (max low intensity, count=2 per FR24) is included in the group constraint computation — their protective state lowers the intensity ceiling for the entire group

---

## Epic 21: Leaderboard & Scoring (v2.5)

**Goal:** Introduce the points system, friends-only leaderboard with medal glyphs, and shared-session point bonus with a per-day cap. Protective-State Social Suppression rules established in Epic 20 are enforced throughout. This is the final v2 epic — ship only after validating the counter-metrics (AtRisk-state session starts and group-session RPE distribution are not adversely affected by gamification).

### Story 21.1: Points System and Solo Session Scoring

As a user,
I want to earn points for completing sessions so they appear on the leaderboard,
So that I have a low-pressure record of my activity relative to friends.

**Acceptance Criteria:**

**Given** a user completes a session (solo)
**When** the session is saved to drift
**Then** a `leaderboard_entries` upsert is sent to Supabase awarding a base point value per session; the point formula uses: `base_points = duration_minutes * intensity_weight` where intensity_weight is: minimal=1, low=1.5, moderate=2 (FR74)

**Given** a per-day points cap is enforced
**When** a user has already reached the daily cap
**Then** additional sessions on the same calendar day award 0 points; the cap prevents gaming by volume (UX-DR31, counter-metric guardrail)

**Given** a points update is sent while offline
**When** connectivity returns
**Then** the pending `leaderboard_entries` write is replayed from the cloud write queue (extending `sync_manager.dart`, ARCH26); the leaderboard reflects the correct total retroactively

**Given** any screen other than the Social tab
**When** the screen renders
**Then** no points total, points delta, or rank number is visible — scoring lives exclusively in the Social tab (UX-DR31, Today never shows leaderboard standing)

### Story 21.2: Friends-Only Leaderboard and Rank Freeze

As a user,
I want to see a friends leaderboard with medal glyphs for the top three and have my rank frozen while I'm in a protective state,
So that resting never reads as losing ground.

**Acceptance Criteria:**

**Given** the user opens Social → Classifica
**When** the leaderboard renders
**Then** it shows only mutual friends (+ the user themselves) ranked by total points; non-friends are never visible (FR76, NFR29, RLS enforced at DB)

**Given** the top-3 positions are rendered
**When** each `LeaderboardRow` renders
**Then** the top 3 each display three redundant cues: (1) prominent rank number, (2) shape-distinct medal glyph (star/circle/diamond or equivalent distinct shapes), and (3) a text label ("1° oro", "2° argento", "3° bronzo") — never color alone (UX-DR23, UX-DR28, UX-DR33)

**Given** the user is in `AtRisk` or `Recovering` state
**When** the leaderboard data is loaded
**Then** the user's rank row is frozen at the rank they held when they entered the protective state; any rank changes (going up or down) are not applied until they return to `Active` or `Fatigued` (UX-DR28, UX-DR31)

**Given** a friend overtakes the user on the leaderboard
**When** the leaderboard updates
**Then** no toast, no push notification, no animation, and no "sei stato superato da [handle]" indicator is shown anywhere — overtaken alerts are explicitly banned (UX-DR31, EXPERIENCE.md)

**Given** the leaderboard tab renders
**When** a points-delta or movement animation would normally be shown
**Then** no such animation runs — the leaderboard is a calm, static ranking view; no dynamism or score animation in this screen (UX-DR31)

### Story 21.3: Shared-Session Point Bonus and Counter-Metric Monitoring

As a user who completed a co-located shared session,
I want the session to award more points than a solo session,
So that the social incentive reinforces doing things together — within counter-metric guardrails.

**Acceptance Criteria:**

**Given** a shared session completes (all participants submitted RPE)
**When** the scoring Edge Function runs server-side
**Then** each participant receives `base_points * shared_session_multiplier` where the multiplier is a server-side constant (initial value: 1.5); the multiplier is applied in the Edge Function, never hardcoded client-side (FR75)

**Given** the per-day points cap is active (Story 21.1)
**When** a shared session bonus would exceed the daily cap
**Then** points are capped at the daily limit regardless of the multiplier; the bonus cannot circumvent the volume-gaming protection

**Given** the shared-session multiplier is in effect
**When** a user in `AtRisk`/`Recovering` participates in a shared session
**Then** their points are awarded normally (they chose to exercise and did so safely); rank is still frozen per Story 21.2 so the bonus produces no visible rank change while in protective state

**Given** the leaderboard and scoring system is live
**When** the PM reviews the counter-metrics dashboard weekly for the first month after launch
**Then** the following conditions must hold to keep scoring live: (a) AtRisk-state session starts have NOT increased vs. the pre-leaderboard baseline, and (b) group-session RPE distribution has NOT shifted above the ≈6.5 target band. If either counter-metric regresses, the shared-session multiplier is reduced to 1.0 (same as solo) until investigated

---

*End of Epic Breakdown — 21 Epics (v1: 1–14, v1.5: 7.5, v2: 15–21)*
