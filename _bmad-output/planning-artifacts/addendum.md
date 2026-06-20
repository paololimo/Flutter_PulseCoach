# PRD Addendum — Flutter_PulseCoach v2

Depth contributed by the user that belongs downstream (architecture, UX, solution design) rather than in the PRD's main narrative.

## Shared-session mechanism notes (v2)

- **Co-location requirement:** shared sessions require participants to be physically together. Enforced via device geolocation (the v1 `geolocator` dependency already exists). Open: exact proximity model (GPS radius threshold vs. shared join-code at a place).
- **Difficulty adaptation:** a shared session must produce a single plan suitable for the whole group — cannot run advanced-strength for a mixed group containing a frail/elderly participant. Likely scales to the common/lowest safe level. Should reuse the existing AI/RL behavioral engine (`BehavioralStateMachine` / bandit) rather than a new system; the engine must accept a group constraint, not a single-user state.
- **Gating:** shared sessions require (1) a registered cloud account, (2) location enabled, (3) the other participants present in the user's friends list.

## Scoring / leaderboard notes (v2)

- Friends leaderboard where shared sessions award more points than solo sessions (incentive to train together). Point formula / anti-abuse rules TBD downstream.
