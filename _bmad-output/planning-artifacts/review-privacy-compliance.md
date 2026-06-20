# Privacy & Compliance Review — PulseCoach v2

**Reviewer:** Privacy & Compliance
**Date:** 2026-06-20
**Scope:** PRD v2 section "Accounts, Subscriptions & Social" + addendum, reconciled against v1 NFRs (Security & Privacy, Domain-Specific Requirements).
**Verdict:** v2 introduces a genuine architectural watershed (cloud, social graph, co-location, biometric-derived backup) but its privacy/compliance requirements are under-specified and partly unenforceable. Several v1 promises are softened without a clean reconciliation, and the highest-risk surfaces — co-location safety, biometric backup, and default social visibility — lack the controls needed to ship in the EU. **Not ready for v2.4 (co-located sessions) without remediation; v2.1–v2.3 need tightening first.**

---

## CRITICAL

### C1 — Co-location + friends location creates a stalking/safety surface, with no minors, consent-symmetry, or abuse model
- **Location:** FR68–FR69, FR73, NFR33; addendum "Shared-session mechanism notes"; Journey 6.
- **Note:** v2 lets a "friend" trigger a device-location check on another user to confirm co-location, and the social graph (FR63 public-facing profile, FR66 activity feed, FR74 leaderboard) reveals when/where/with-whom a person trains. Even though NFR33 says location is "soft, momentary, non-stored," the *existence* of a friend-initiated location check plus a public training pattern is a classic stalking/intimate-partner-abuse vector. Journey 6 itself pairs a 24-year-old with a 61-year-old relative — there is **no age gate, no minor handling, and no Art. 8 GDPR (child consent) treatment** anywhere in v2. There is also no consent symmetry: nothing states that *both* parties must actively consent at session start before any location signal is read on either device. "Non-blocking" (a friend can join even if the soft check is inconclusive) means the safety control is explicitly defeatable.
- **Fix:** (1) Require **mutual, per-session, foreground, explicit** opt-in to the co-location check on every participant's own device — never a check one user runs against another. (2) Read location **only on the local device to self-confirm proximity**; never transmit one user's coordinates to another. Prefer a non-GPS proximity proof (shared QR/join-code + BLE/nearby handshake) so raw location need not be read at all. (3) Add a **minimum age (16+ EU default) gate** for accounts and social, and an Art. 8 parental-consent path or hard block for minors. (4) Add an explicit safety section: block/report/mute a friend, hide-from-leaderboard, and a documented threat model for stalking and location abuse. (5) Make co-location failure **fail-closed for the location signal** (proceed without location, never proceed by silently accepting an unconfirmed location).

### C2 — Opt-in cloud backup of "personalization state" leaks Art. 9 biometric-derived data off-device, contradicting NFR7/NFR12/NFR28
- **Location:** FR57, NFR28, NFR30; reconciliation table rows NFR7 & NFR17.
- **Note:** v2 repeatedly claims biometrics "stay on device" / "not *required* to leave the device." But FR57 backs up "session history and **personalization state**" to the cloud. The bandit state vector and RPE/HR history *are* derived from biometric (Art. 9) data — Journey 5 shows the state vector literally contains `restingHR` and `avgRPE`. Backing that up means **special-category data leaves the device the moment a user opts into backup**. The PRD's framing ("biometric not *required* to leave the device") is technically true but misleading; in practice the headline backup feature transmits Art. 9-derived data. NFR28's "biometric not required to leave the device" does not match FR57's actual payload. This is the single biggest gap between the v1 promise and v2 reality.
- **Fix:** Decide and state explicitly one of: (a) backup is **end-to-end encrypted with a user-held key** (server cannot read it) — then document the key model, recovery story, and that the provider is processor-only; or (b) backup **excludes raw HR and any biometric-derived state**, backing up only non-sensitive profile/preferences. Either way, FR57/NFR28/NFR30 must be reworded to stop implying biometrics never leave the device when opt-in backup is on, and the privacy disclosure (NFR32) must declare Art. 9 data collection. Add an explicit **Art. 9 lawful basis = explicit consent** at the backup opt-in, separate from the account-creation consent.

### C3 — No lawful basis / consent architecture or DPA/controller-processor model for any cloud personal data
- **Location:** NFR29, NFR30, NFR32 (all of "Privacy & Compliance (cloud)"); v2 Overview.
- **Note:** v2 stands up a backend processing accounts, social graph, shared progress, leaderboards, and (per C2) biometric-derived backup — yet there is **no stated lawful basis per processing purpose** (account = contract; social sharing = consent; any analytics = separate consent), no consent record/withdrawal mechanism, no privacy policy artifact, no data-residency/region decision (flagged only as an "open item"), and no controller/processor framing for the chosen backend (Firebase/Supabase/etc. are processors needing a DPA + SCCs if outside the EEA). NFR30 says "processed lawfully with consent" but bundles all purposes under one word ("consent"), which GDPR does not allow. For an EU-targeted app (personas are in Milan/Turin) this is a foundational gap, not a detail.
- **Fix:** Add NFRs for: (1) a **per-purpose lawful-basis map** and granular, separately-withdrawable consents; (2) a published **privacy policy + DPA/SCC** requirement before v2.1 ships; (3) a **data-residency decision (EU region default)** promoted from "open item" to a requirement; (4) records-of-processing and a consent-withdrawal flow that also stops future processing, not just deletes past data.

---

## HIGH

### H1 — NFR30 right-to-erasure/export is not sufficient or testable
- **Location:** NFR30.
- **Note:** NFR30 says the user "can export and delete their account and all associated server data." It does not define: scope (does deletion cascade to data *replicated into friends' feeds, leaderboards, and shared-session records*?), format/completeness of export (Art. 20 portability = machine-readable), SLA (Art. 12 = without undue delay / 1 month), proof/verification, backup-and-log purge, or what happens to a friend's view of a deleted user's shared sessions. As written it is untestable and almost certainly under-scoped (friend-of-friend copies survive deletion).
- **Fix:** Specify erasure cascade (including data propagated into other users' feeds/leaderboards/shared-session history, or a documented anonymization rule), a machine-readable export covering *all* personal data, a response SLA, and an acceptance test that verifies no residual personal data after deletion. Reconcile with v1 FR52 (local CSV/JSON export) so users understand local vs server export.

### H2 — Social default visibility and friend-of-friend leakage undefined; NFR29 not granular enough
- **Location:** FR63, FR66, FR67, NFR29; leaderboard FR74–FR76.
- **Note:** FR63 creates a "shareable **public-facing** profile" — "public" default is the most dangerous possible default and contradicts privacy-by-default (Art. 25, data-protection-by-default). NFR29 claims "granular control over who can see their progress" but no FR defines the visibility model: who sees the activity feed (FR66), can friends-of-friends see shared sessions, is the leaderboard friends-only or wider, and what is the **default** (should be private/opt-in). The leaderboard inherently exposes activity volume/timing to everyone on it.
- **Fix:** State **private-by-default**; sharing and leaderboard participation are explicit opt-ins. Define the visibility tiers (private / friends / public) and pin defaults to the most private. Explicitly prohibit friend-of-friend leakage of progress and shared-session data. Add an "appear on leaderboard" opt-out that still allows training. Make NFR29 testable by enumerating the visibility matrix.

### H3 — NFR32 store privacy disclosures are incomplete and will fail review as written
- **Location:** NFR32; Store Compliance (v1).
- **Note:** NFR32 mentions "data collection nutrition labels" generically. But v2 now collects: account identifiers, contacts (FR64), **location** (FR69), social graph, and **health/biometric-derived backup** (C2). Apple **App Tracking Transparency** and the **Health data** special rules, plus Google **Health Connect** policy and **Data Safety** form (which forbids selling/sharing health data and requires explicit disclosure), all apply. Contacts access (FR64) and location each need a purpose string and a privacy-label entry. None of this is enumerated; a generic "we provide labels" line will not pass either store's health-data review.
- **Fix:** Enumerate every collected data category, its purpose, linkage to identity, and the matching Apple Privacy Nutrition Label / Google Data Safety entries. Add explicit requirements: no health data used for tracking/ads, purpose strings for location + contacts, Health Connect policy compliance, and account-deletion availability **in-app and via a public URL** (both stores now mandate this for accounts).

### H4 — Contacts upload (FR64) has no consent/retention/least-data treatment
- **Location:** FR64.
- **Note:** "Add friends from phone contacts" typically implies uploading/hashing the address book server-side for matching — that is processing personal data of **third parties who never consented** (the contacts themselves). No requirement covers hashing, no-server-retention, transparency, or making this a clearly separate optional step.
- **Fix:** Require contacts matching to be **opt-in, separate, hashed, non-retained** (no server-side storage of non-matching contacts), with a clear notice that it processes other people's data. Consider on-device-only matching.

---

## MEDIUM

### M1 — Real-time shared-session transport leaks presence/location-adjacent data with no stated protection
- **Location:** FR71, NFR31; Journey 6.
- **Note:** A live synchronized session reveals real-time presence and co-participation to the backend and peers. No requirement states the channel is TLS/E2E, what the server retains about who-trained-with-whom-when, or retention limits. This relationship-graph telemetry is itself sensitive.
- **Fix:** Add transport-security + minimal-retention requirements for shared-session signaling; define what (if anything) is persisted about co-participation and for how long.

### M2 — Subscription/billing data and entitlement checks not privacy-scoped
- **Location:** FR58–FR62, NFR32.
- **Note:** Pro gating (incl. gating the *health history* in FR61) ties feature access to subscription state. No requirement states billing is handled entirely by platform IAP with no card data touching the backend, nor how entitlement is verified without over-collecting.
- **Fix:** State that payment data never reaches PulseCoach servers (platform IAP only) and that entitlement verification collects the minimum (receipt/token), not financial data.

### M3 — Group-adapted difficulty (FR70) cross-uses one participant's constraints with the group
- **Location:** FR70, FR73; addendum "Difficulty adaptation."
- **Note:** Scaling a shared plan to honor "every participant's constraints" (e.g., Giulia's knee, a health condition) means **one user's health-constraint data influences/visible-via the shared plan** to others. Even if not shown verbatim, "no knee-loading movements" can disclose a sensitive condition. No requirement governs whether constraints are revealed or only their effect.
- **Fix:** Require that group adaptation use constraints **without disclosing the underlying condition** to other participants (effect-only, no source attribution), and that participating shares only the minimum needed.

### M4 — No breach-notification, security-incident, or data-minimization/retention requirements for the new backend
- **Location:** NFR27–NFR34 (whole cloud block).
- **Note:** GDPR Art. 33/34 breach notification, general retention limits, and data-minimization are absent now that a real backend exists. v1 didn't need them (no server); v2 does.
- **Fix:** Add NFRs for breach detection + 72h notification readiness, defined retention periods per data category, and data-minimization as a design constraint.

---

## LOW

### L1 — `[ASSUMPTION]` tags on consent-critical items (FR57, FR62, FR75, FR71) leave privacy posture unconfirmed
- **Location:** FR57, FR62, FR71, FR75 (all marked `[ASSUMPTION]`).
- **Note:** The most privacy-load-bearing claim ("backup is the user's private encrypted backup, not centralized training data," FR57) is an unconfirmed assumption. Privacy posture shouldn't rest on an unratified `[ASSUMPTION]`.
- **Fix:** Promote FR57's encryption/no-training claim to a confirmed, testable requirement before v2.1.

### L2 — v1 onboarding copy "Your data stays yours" / "no data leaves device" becomes misleading in v2
- **Location:** v1 Journey 3 onboarding screen 2; v1 Executive Summary ("No health data leaves the device"); marketing value prop.
- **Note:** v2 silently makes the v1 onboarding promise conditional. A user who saw "your data stays yours" in v1 and later enables backup/social experiences a changed promise. This is a reconciliation gap (consent/transparency, and arguably a fairness/dark-pattern concern) not surfaced in the reconciliation table.
- **Fix:** Update onboarding/marketing copy for v2 to say data stays on-device **by default** and only leaves with explicit opt-in; add this row to the reconciliation table.

### L3 — NFR33 "soft, momentary, non-stored" lacks a testable definition
- **Location:** NFR33, FR69.
- **Note:** "Momentary" and "soft" are not measurable. No max duration, accuracy/coarseness, or guarantee-of-non-persistence is specified; "non-blocking" can be read as "ignorable," weakening it further.
- **Fix:** Define momentary numerically (e.g., single coarse read at session start, discarded within N seconds, never written to DB or sent to peers), and add an acceptance test asserting no location row is persisted and no coordinate is transmitted to another user.

---

## Reconciliation summary — v1 promises softened by v2

| v1 promise | v2 reality | Reconciled cleanly? |
|---|---|---|
| NFR7 / Exec summary: no health data leaves device | FR57 backs up personalization (biometric-derived) state | **No** — see C2 |
| NFR11: no account | FR54 accounts (optional) | Yes (free tier preserved) |
| NFR12: biometrics never shared | Backup + group constraint (FR70) expose biometric-derived data | **Partially** — see C2, M3 |
| Journey 3 onboarding "your data stays yours" | Conditional in v2 | **No** — see L2 (not in reconciliation table) |
| NFR8/FR35: city-level location only, no GPS | FR69 reads device location for co-location | **Partially** — soft check, but C1/L3 gaps |

---

## Recommended gating before ship
- **Block v2.4 (co-located sessions)** until C1 (consent symmetry, minors, abuse model, self-only location read) is resolved.
- **Block v2.1 (accounts + backup)** until C2 (biometric backup encryption/scope) and C3 (lawful basis, privacy policy, data residency, DPA) are resolved.
- **Before v2.3 (social):** resolve H2 (private-by-default), H4 (contacts), H1 (erasure scope).
- **Before any store submission:** resolve H3 (privacy labels / health-data disclosures / in-app account deletion).
