# UX Spine Coverage Review — 2026-06-20

Reviewer pass over `DESIGN.md` + `EXPERIENCE.md` against BMad UX spine contracts and PRD v2 (FR53–FR77, NFR27–37). Coverage/rubric review only — no rewrites.

## Pass 1 — Structural coverage

### DESIGN.md spine

**Frontmatter tokens present:** colors ✅, typography ✅, rounded ✅, spacing ✅, components ✅. All four `rounded` keys (chip/button/card/full) and all six `spacing` keys (xs/sm/md/lg/xl/2xl) appear in the body and match. Typography scale in frontmatter matches the Typography body prose (Display 28 / H1 24 / … / Countdown 72).

**Canonical body section order** — required: Brand & Style · Colors · Typography · Layout & Spacing · Elevation & Depth · Shapes · Components · Do's and Don'ts.
Actual: Brand & Style → Colors → Typography → Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts. ✅ **All present, correct order.**

Internal consistency notes (minor, not gaps):
- Color frontmatter includes `medal-gold/silver/bronze` and they appear in the Colors body (Podium medals). ✅
- `accent-cardio` token name in frontmatter is referenced in body prose as "Cardio — Soft Coral" and as `{primary}`-adjacent accents; the body never uses the literal token name `accent-cardio`, but the value `#F0A1B0` is consistent. Acceptable.

### EXPERIENCE.md spine

**Always-on sections required:** Foundation · Information Architecture · Voice and Tone · Component Patterns · State Patterns · Interaction Primitives · Accessibility Floor · Key Flows.
Actual sections: Foundation ✅ · Information Architecture ✅ · Voice and Tone ✅ · Component Patterns ✅ · State Patterns ✅ · Interaction Primitives ✅ · (Account/Privacy Patterns, Pro Gating Patterns, Shared Session Patterns — extra v2 sections) · Accessibility Floor ✅ · (Responsive & Platform, Inspiration & Anti-patterns — extra) · Key Flows ✅.

**All 8 required sections present.** Extra v2/platform sections are additive and acceptable. **Note:** the canonical order places Accessibility Floor late and Key Flows last — satisfied. The three v2 pattern sections are interleaved between Interaction Primitives and Accessibility Floor; this is a deviation from a strict 8-section spine but does not displace or reorder any required section.

**Key Flows — named protagonists + climax beat:** All 6 flows have named protagonists (Luca, Marco, Marco, Giulia, Marco & Giulia, "any user") and an explicit **Climax:** beat. ✅ Flow 6 ("any user") is the only unnamed protagonist — acceptable for a navigation-fix flow but weakest on the rubric.

## Pass 2 — Token & cross-ref consistency

**Components in DESIGN frontmatter → body presence:** All 18 frontmatter components (HeroSessionCard, CompactSessionCard, CompletedSessionCard, InSessionView, CountdownOverlay, CompletionRing, RPEInput, StateIndicator, ExplanationLine, MiniSummary, SignInSheet, ProUpsellSheet, FriendRow, ActivityFeedCard, LeaderboardRow, SharedSessionLobby, JoinCodeCard, VisibilityTierSelector) appear in DESIGN.md Components body. ✅

**Behavioral components in EXPERIENCE Component Patterns table:** Present — HeroSessionCard, CompactSessionCard, CompletedSessionCard, RPEInput, CompletionRing, CountdownOverlay, InSessionView, MiniSummary, SignInSheet, ProUpsellSheet, FriendRow, ActivityFeedCard, LeaderboardRow, SharedSessionLobby, VisibilityTierSelector.
**GAP (minor): `JoinCodeCard`, `StateIndicator`, and `ExplanationLine` are NOT rows in the EXPERIENCE Component Patterns table.**
- `StateIndicator` / `ExplanationLine` behavior is covered narratively (State Patterns, Voice and Tone, HeroSessionCard row references `{ExplanationLine}`) — defensible as "visual-primary, behavior implied."
- `JoinCodeCard` behavior ("Calm, no countdown pressure") is purely visual and is covered in Interaction Primitives ("QR scan / join code … no countdown") — defensible. Worth adding a row for completeness.

**{token} cross-refs in EXPERIENCE → exist in DESIGN:** References found: `{ExplanationLine}`, `{Hero}`, `{ProUpsellSheet}`, `{primary}`, `{medal-gold/silver/bronze}`, `{medal-gold}`, `{medal-silver}`, `{medal-bronze}`.
- `{primary}` ✅, `{ExplanationLine}` ✅, `{ProUpsellSheet}` ✅, `{medal-gold/silver/bronze}` ✅ (all exist in DESIGN frontmatter/body).
- **`{Hero}`** (used in CompactSessionCard row, "in-place {Hero} swap") has **no exact `Hero` token** in DESIGN — the component is `HeroSessionCard`. Minor naming mismatch; intent clear.

Overall cross-ref hygiene is good. No dangling token references to non-existent colors/components beyond the `{Hero}` shorthand.

## Pass 3 — v2 requirement coverage

| FR/NFR | Covered? | Where / gap |
|---|---|---|
| FR53 (back from drawer) | ✅ | IA table row + State? n/a; Flow 6; "v2 FR53" in IA. |
| FR54 (create account: email/Apple/Google) | ✅ | SignInSheet (DESIGN + EXPERIENCE): Apple/Google/Email. |
| FR55 (sign in/out, password reset) | ✅ | IA "Account/Backup … Sign in/out, password reset". |
| FR56 (usable without account) | ✅ | Foundation, Account Patterns ("optional and additive", FR56). |
| FR57 (E2E backup/restore, user-held key) | ✅ | Account Patterns ("Backup is E2E-encrypted … FR57/NFR28"). |
| FR58 (view/purchase Pro via store IAP) | ✅ | IA "Pro/Subscription … purchase"; Flow 4 store IAP. |
| FR59 (gate Pro, free keeps v1 core) | ✅ | Pro Gating Patterns (FR59 cited). |
| FR60 (restore/manage/cancel via store) | ✅ | IA "restore, manage/cancel (via store)"; Flow 4 "restore-aware". |
| FR61 (free = recent+weekly; Pro = full history; grandfather) | ✅ | IA Progress row + State Patterns "Pre-v2 grandfathered user". |
| FR62 (social create=Pro; username+view free) | ✅ | Pro Gating Patterns (FR62 cited explicitly). |
| FR63 (username + privacy-by-default) | ✅ | Account Patterns (privacy by default), VisibilityTierSelector. |
| FR64 (add friends: username/QR/contacts) | ✅ | FriendRow EXPERIENCE row ("Add by username / QR / contacts"). |
| FR65 (send/accept/decline/remove) | ✅ | FriendRow row. |
| FR66 (share completion + activity feed) | ✅ | ActivityFeedCard (DESIGN + EXPERIENCE). |
| FR67 (compare progress vs friends) | ⚠️ Partial | Leaderboard covers ranking/points comparison; no explicit head-to-head "compare progress" surface beyond leaderboard. Acceptable if leaderboard IS the comparison; flag for confirm. |
| FR68 (create shared session, invite via code/QR) | ✅ | JoinCodeCard + Flow 5; FR68 cited in Shared Session Patterns. |
| FR69 (join via code/QR + soft co-location) | ✅ | Flow 5; State Patterns "Co-location inconclusive". |
| FR70 (deterministic group-adapted plan) | ✅ | Shared Session Patterns (full min/lowest/union/shortest rules, FR70). |
| FR71 (real-time sync; drop-out non-interrupting) | ✅ | Shared Session Patterns (FR71/NFR31); State Patterns. |
| FR72 (per-participant RPE) | ✅ | Shared Session Patterns (FR72); Flow 5. |
| FR73 (shared-session gating: Pro+account+friends+location+age) | ✅ | Shared Session Patterns "Gating (FR73)". |
| FR74 (points + friends leaderboard) | ✅ | LeaderboardRow. |
| FR75 (shared sessions worth more points) | ✅ | LeaderboardRow caption; Flow 5 climax. |
| FR76 (view leaderboard ranking — free) | ✅ | Pro Gating Patterns ("viewing the leaderboard ranking" free). |
| FR77 (in-app account deletion, cascade) | ✅ | Account Patterns (FR77, destructive-action pattern, ≤30d). |
| NFR27 (auth security: hashing/OAuth/TLS) | ⚠️ Partial | Brand-promise floor + NFR27-adjacent; not explicitly named. Largely backend/non-UX; design touchpoint (secure token) implied. Acceptable as out-of-UX-scope but no explicit decision. |
| NFR28 (on-device personalization preserved) | ✅ | Foundation "Brand-promise floor"; Account Patterns (NFR28). |
| NFR29 (visibility tiers, private default, revocable) | ✅ | Account Patterns (NFR29), VisibilityTierSelector, ActivityFeedCard "revocable". |
| NFR30 (GDPR export + cascade delete) | ✅ | Account Patterns ("Data export (NFR30)", cascade). |
| NFR31 (~1s sync, drop-out tolerant) | ✅ | Shared Session Patterns + State Patterns (NFR31). |
| NFR32 (store/billing compliance, privacy labels) | ⚠️ Partial | Sign in with Apple alongside Google present; IAP present. Privacy nutrition labels not a UX decision — not surfaced. Acceptable. |
| NFR33 (co-location momentary, non-blocking, boolean) | ✅ | Account Patterns (NFR33); State Patterns. |
| NFR34 (graceful offline; v1 offline-first) | ✅ | Foundation; State Patterns "Offline (v2 cloud)". |
| NFR35 (granular unbundled consent, withdrawable) | ✅ | Account Patterns (NFR35). |
| NFR36 (EU data residency) | ❌ Not covered | No design touchpoint. Pure backend/business decision — correctly out of UX scope but listed as a gap per instructions. |
| NFR37 (minimum age 16, confirmed at registration) | ✅ | Account Patterns (NFR37); Shared Session gating. |

**No-coverage list:** NFR36 (data residency — out of UX scope). Partial/confirm: FR67 (compare = leaderboard?), NFR27 / NFR32 (backend/store compliance, minimal UX surface).

## Contradictions

1. **Nav-bar destination count / tab order.** EXPERIENCE Foundation says "WearOS (tertiary)" and IA nav is **Sessions · Today · Social · Progress** (4 tabs, Today center). CLAUDE.md records the v1 live order as **Sessions · Today · Progress** (3 tabs, Today index 1). v2 adding Social as 4th tab makes Today no longer center index — EXPERIENCE calls Today "the center of gravity and default" but with 4 tabs it is index 1 of 4 (not visually centered). Not a spine-internal contradiction, but a self-description tension ("center of gravity" vs. 4-tab layout). Flag for UX confirm, not a blocker.

2. **CompletionRing placement on Today.** DESIGN Layout "Today (phone) vertical rhythm" lists order: State bar → Hero → COMING UP → **CompletionRing (secondary)**. IA table describes Today as "Hero session + COMING UP + CompletionRing." Consistent. No contradiction — noted as verified.

3. **No substantive DESIGN↔EXPERIENCE contradictions found** on tokens, color usage, shapes, or component behavior. The two spines are internally aligned (e.g., RPE 40dp visual/48dp target, two-row degrade threshold ~516dp appears identically in both).

## Verdict
Spines are structurally complete and v2-coverage-solid; only true gap is NFR36 (out-of-UX-scope), with minor cross-ref/table cleanups (JoinCodeCard/StateIndicator/ExplanationLine rows, `{Hero}`→`{HeroSessionCard}`) and three confirm-items (FR67, NFR27, NFR32) — ship-ready after a light cleanup pass.
