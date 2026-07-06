# PRD Addendum — Flutter_PulseCoach v2

Depth contributed by the user that belongs downstream (architecture, UX, solution design) rather than in the PRD's main narrative.

## Shared-session mechanism notes (v2)

- **Co-location requirement:** shared sessions require participants to be physically together. Enforced via device geolocation (the v1 `geolocator` dependency already exists). Open: exact proximity model (GPS radius threshold vs. shared join-code at a place).
- **Difficulty adaptation:** a shared session must produce a single plan suitable for the whole group — cannot run advanced-strength for a mixed group containing a frail/elderly participant. Likely scales to the common/lowest safe level. Should reuse the existing AI/RL behavioral engine (`BehavioralStateMachine` / bandit) rather than a new system; the engine must accept a group constraint, not a single-user state.
- **Gating:** shared sessions require (1) a registered cloud account, (2) location enabled, (3) the other participants present in the user's friends list.

## Scoring / leaderboard notes (v2)

- Friends leaderboard where shared sessions award more points than solo sessions (incentive to train together). Point formula / anti-abuse rules TBD downstream.

## Experience Polish mechanism notes (v1, 2026-07-06)

### Ongoing session notification (FR79/FR80/NFR39)
- **Net-new dependency:** no notification stack exists today. Likely `flutter_local_notifications` (foreground/ongoing notification on Android). No `.env`/secrets needed.
- **Android:** ongoing (`ongoing: true`, not swipe-dismissible) notification showing session name + paused timer. Android 13+ requires the `POST_NOTIFICATIONS` runtime permission — request with a clear rationale; on denial the session still pauses in-app with no notification (graceful degradation per NFR9).
- **iOS constraint (why FR79 is Android-primary):** iOS has no equivalent to a persistent, live-updating pinned notification for a backgrounded app. A one-shot local notification can be posted, but a continuously updating timer is not guaranteed. Design should treat iOS as best-effort: session pauses reliably; notification is informational only. Live Activities (ActivityKit) is a possible future enhancement, out of scope here.
- **Inactivity timeout (FR80) — default 5 min (decided 2026-07-06), configurable.** On expiry the session is abandoned through the existing FR20 abandon flow (partial progress handled as today).
- **No foreground service (explicit non-requirement):** because the timer *pauses* on background (no work runs while backgrounded), a foreground service is NOT required — so no Android `foregroundServiceType` declaration and no Play Store foreground-service justification are needed. This is a deliberate scope choice; a live-running background timer would change this.
- **Timeout firing mechanism (why FR80 is worded as reconcile-on-resume):** with the isolate suspended and no FGS, the app cannot reliably run a countdown while backgrounded. Implement as: on background, schedule a delayed local-notification update/cancel and record `backgroundedAt`; on resume, reconcile — if `now - backgroundedAt ≥ timeout`, transition the session to abandoned (FR20); else cancel the pending abandon and resume. Also reconcile on cold start (orphaned notification after process death → clear it and finalize the abandon).
- **Android 14+ dismissibility:** ongoing notifications are swipe-dismissible unless FGS-backed. Since we avoid FGS, FR79 must tolerate user dismissal — dismissing the notification does not abandon the session; the FR80 timeout still governs abandonment independently.
- **iOS authorization:** iOS requires `UNUserNotificationCenter` authorization; without it the best-effort notification silently no-ops (session still pauses). Request with rationale (NFR39).
- **Notification-tap routing (FR79):** net-new deep link — tap resumes the paused session route; if already auto-abandoned, route to Today. Cold-start tap must reconcile first (see firing mechanism).
- **Lock-screen visibility:** full session name shown (decided 2026-07-06); acceptable because labels are generic exercise categories and carry no biometric data (NFR39).

### Decision-factor iconography (FR82)
- Presentation-layer only over existing explainability (FR13/FR14). Factors surfaced as icons/glyphs: exercise type, intensity, temperature, precipitation, AQI. **Humidity deliberately excluded** (2026-07-06) — `WeatherContext` does not capture it and no new Open-Meteo field is being added for v1.

### Active-days indicator (FR81)
- The metric is a rolling 30-day windowed active-days count (non-resetting), per the 2026-07-06 UX reframe — **not** a consecutive-day streak (a rest day ages out of the window rather than snapping the count to zero).
- Should reuse the activity signal already computed by `BehavioralStateMachine` (FR23), exposed to the Today presentation layer, rather than introducing a parallel counter (single source of truth).

### Session milestones + finish flag (FR78)
- Progress-bar markers derived from existing session-step boundaries; finish "flag" marker + brief completion animation. Must honor the 60fps budget (NFR2) and respect OS reduce-motion (NFR38).
