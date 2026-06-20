# PRD Quality Review — Flutter_PulseCoach v2 (Accounts, Subscriptions & Social)

## Overall verdict

The v2 section is a disciplined, honest extension that does the single hardest thing right: it surfaces its conflicts with the shipped v1 contract in an explicit reconciliation table and resolves each one, preserving the "privacy-first, on-device" brand promise rather than quietly breaking it. Strategic coherence and scope honesty are strong — the free/Pro boundary, the on-device-AI-stays-on-device rule, and the `[ASSUMPTION]` tagging all pull in one direction. The real risk is concentrated in done-ness clarity: the load-bearing social FRs (FR70 group-adaptation, FR74/FR75 scoring, FR71 sync) lean on adjectives ("safe and suitable", "more points", "lowest comfortable level") with no testable threshold, which is exactly where downstream story creation will stall.

## Decision-readiness — strong

v2 reads like a section written by someone who has decided things. The "Architectural Watershed" framing (§v2 Overview, line 685) names the actual bet — "PulseCoach gains an **optional cloud backend**" — instead of burying it. The brand-promise-preservation paragraph (line 692) states a non-negotiable and accepts the cost: social is enabled *only* via opt-in, own-account-scoped sync, "never centralized cross-user training." That is a trade-off named with what was given up (no cross-user training signal, therefore no federated-learning shortcut), not a smoothing.

The reconciliation table (lines 696–702) is the strongest decision-readiness artifact in the document: each v1 invariant (NFR11, NFR7, NFR17, NFR8/FR35, Growth/Vision) is paired with the v2 change and an explicit resolution. The "Open items for review" list (line 799) is genuinely open — backend tech, Pro price, point formula, WearOS-as-participant-vs-mirror, data residency — and correctly scoped *out* of the PRD where appropriate ("backend technology choice (architecture, not PRD)").

### Findings
- **low** Pro pricing left fully open (§v2 Scope, line 799 "exact Pro price/tier structure") — *Note:* defensible for a PRD, but FR58–FR61 gate real revenue behavior on a tier structure that doesn't exist yet, so v2.2 cannot be fully storyized until it lands. *Fix:* add a `[NOTE FOR PM]` at FR58 flagging that the free/Pro feature split (FR59/FR61) is specifiable now even while price is TBD.

## Substance over theater — strong

No furniture. Journey 6 (line 706) earns its place: the Marco-and-Giulia pairing is not a fifth persona for thoroughness — it is the *only* way to expose the group-adaptation constraint (intermediate nephew + 61-year-old beginner with a knee constraint), which is the entire technical novelty of the social suite. The persona directly drives FR70 and FR73. The NFRs are product-specific, not boilerplate: NFR31 pins sync to "within ~1 second (same bar as the existing phone↔WearOS bridge)" — reusing a real, measured v1 baseline rather than inventing a number. NFR33 specifies the co-location model concretely (momentary, non-stored, non-blocking).

One mild caution: NFR27 ("industry-standard secure practices — passwords hashed... TLS") is closer to boilerplate than the rest, but for an auth NFR this is acceptable as a floor and is partly redeemed by the more specific NFR28/NFR30.

## Strategic coherence — strong

The thesis holds across the whole section: *layer monetization and social on top of v1 without dissolving the on-device-privacy differentiator that made v1 distinct.* Feature prioritization follows the thesis, not ease — the v2 phasing table (lines 790–797) sequences navigation-fix → accounts → Pro → social-graph → shared-sessions → leaderboard, explicitly flagging v2.4 as "Highest technical complexity" and putting it late, after the monetization foundation it depends on. That is thesis-driven ordering.

The free/Pro line is drawn coherently and repeatedly (line 688, FR59, FR61, NFR34): the v1 core stays free, Pro gates social + full history. The counter-pressure (revenue) is balanced against the brand promise (privacy) rather than one silently winning.

### Findings
- **medium** No success metrics or counter-metrics for v2 (§v2 entire section) — *Note:* v1 has a full Success Criteria block with targets and counter-considerations; v2 introduces monetization and social retention but states no thesis-validating metric (e.g., free→Pro conversion, shared-session repeat rate, the Journey-6 "reason both showed up" claim) and no counter-metric (e.g., social pressure / leaderboard-driven over-training, which directly tensions the v1 empathetic-recovery thesis). *Fix:* add a short "v2 Success Metrics" subsection with at least one conversion metric, one social-engagement metric, and one counter-metric guarding against leaderboard-induced over-exertion.

## Done-ness clarity — thin

This is the dimension to be unforgiving on, and it is where v2 is weakest. Several of the highest-value, highest-risk FRs are specified with adjectives where bounds are needed:

- **FR70** (line 753): "difficulty, intensity, and movement selection are adapted to be **safe and suitable for all participants** (scaled to the group's lowest comfortable level and honoring every participant's constraints)." "Safe and suitable" and "lowest comfortable level" are not testable. What does "honoring a knee constraint" mean as a verifiable output — no movements tagged `knee-loading`? An engineer cannot write a pass/fail test from this. The v1 safety layer (FR9) is, by contrast, fully testable ("RPE avg >8 for 2 consecutive → block high intensity"); FR70 needs the same treatment — a concrete rule like "group intensity = min(participant max-safe intensities); exclude any exercise whose constraint-tags intersect any participant's declared constraints."
- **FR74/FR75** (lines 760–761): "awards points for completed sessions" and shared sessions "award **more points** than solo." With the point formula explicitly deferred (FR75 `[ASSUMPTION]`), the leaderboard FRs have *zero* testable consequence beyond "a number exists and shared > solo." That ordering (`shared_points > solo_points`) is the one testable assertion present; everything else is undefined.
- **FR71** (line 754): "all participants see a **synchronized** session state... in real time" — this one is partly rescued by NFR31's "~1 second" bound, but FR71 itself should cross-reference NFR31 so the testable condition travels with the FR.
- **FR57** (line 731): "back up and restore their profile, session history, and personalization state" — "personalization state" is the bandit/state-machine internals; whether restore is bit-exact or approximate is undefined, and that materially affects acceptance ("restored device produces identical next-plan" vs "approximately resumes").
- **FR69/NFR33** "soft, momentary, non-blocking" co-location: NFR33 says a friend "can still join if the soft check is inconclusive," which is good — but then the testable consequence of the location check is nearly nil (it never blocks). What *observable* behavior does the check produce? If it can't fail a join, what is its done-condition? This needs one concrete consequence (e.g., "an inconclusive check surfaces a non-blocking warning banner").

The navigation-fix FR53 (line 724), by contrast, is well-formed and testable ("explicit affordance to return to the primary screens... without restarting the app"), and the accounts/auth FRs (FR54–FR56, FR58–FR60) are concrete and verifiable.

### Findings
- **critical** FR70 group-adaptation has no testable rule (§FR70, line 753) — *Note:* the single most novel and safety-relevant v2 capability is specified entirely in adjectives ("safe and suitable", "lowest comfortable level"). Mixed-ability co-located sessions with a frail/elderly participant are a real injury-liability surface (same class as v1's FR9 safety layer), and this cannot be storyized or safety-tested as written. *Fix:* express FR70 as a deterministic rule mirroring FR9 — group intensity = minimum of each participant's safe ceiling; exclude any exercise whose constraint-tags intersect the union of participants' declared constraints; add the corresponding unit-test obligation.
- **high** FR74/FR75 scoring undefined to the point of untestability (§FR74–FR75, lines 760–761) — *Note:* with the point formula deferred, the only verifiable assertion is `shared > solo`. A whole phase (v2.5) rests on this. *Fix:* either pull a minimal formula into the PRD (even "points = completed_minutes × type_multiplier; shared multiplier ≥ 1.5") or explicitly mark FR74–FR76 as design-blocked and out of any near-term sprint until the addendum's formula lands.
- **medium** FR57 "personalization state" restore fidelity unspecified (§FR57, line 731) — *Note:* bit-exact vs approximate restore changes the acceptance criterion and the backup format. *Fix:* state the restore guarantee (recommend: restored device reproduces the same next-plan given identical inputs).
- **medium** FR71 testable bound lives only in NFR31, not in the FR (§FR71/NFR31) — *Note:* the "~1s" sync target is the FR's only done-condition and is one section away. *Fix:* cross-reference NFR31 from FR71.
- **low** NFR31's "a participant dropping out does not interrupt the others" duplicates FR-level behavior implied by Journey 6 but appears in no FR — *Fix:* add an FR (or extend FR71) for drop-out resilience so it's storyized, not buried in an NFR.

## Scope honesty — strong

This is v2's best dimension and the one the prompt asked to scrutinize hardest. Omissions are explicit, not inferred. The reconciliation table (lines 696–702) does real work — it is exactly the `[NON-GOAL]`/conflict-surfacing the rubric wants, applied to the awkward case (contradicting a *shipped* v1 promise). The free-tier preservation is stated four times so it cannot be silently assumed.

`[ASSUMPTION]` density is calibrated, not excessive. Six inline `[ASSUMPTION]` tags (FR57, FR62, FR71, FR75, the v2.x phasing header line 788, and the addendum), each on a genuine inference the user did not directly confirm (backup-is-private-not-training; social-suite-is-the-paid-line; WearOS-mirrors-owner; point-formula-deferred; build-order; scoring details). For a "Fast path / Draft" extension introducing a backend, monetization, and a social graph, that count is *appropriately low* — these are the real open inferences, not anxiety tags. The header (line 681) tells the reader upfront that `[ASSUMPTION]` tags "need Paolo's confirmation in review," which is honest framing.

Open-items density relative to stakes: this is a Draft, not a green-light-to-build, and it says so ("Status: Draft (Fast path)", line 679). The open items are concentrated in the genuinely-undecided (price, formula, backend, data residency) and explicitly listed (line 799). Acceptable for the stated stakes.

### Findings
- **medium** No explicit Non-Goals list for v2 (§v2 entire section) — *Note:* the reconciliation table handles v1-conflict omissions well, but forward-looking non-goals are only implied (e.g., is real-time *remote* (non-co-located) shared sessions a non-goal? cross-user training is ruled out, but is a public/global leaderboard beyond friends a non-goal? are group sessions >2 participants in or out?). Journey 6 is strictly 2-person and co-located; the FRs say "all participants" without bounding N. *Fix:* add a short v2 Non-Goals block: co-located only (no remote), friends-only leaderboard (no global), and state whether N>2 is in scope.
- **low** `[ASSUMPTION]` on FR71 (WearOS mirrors owner) overlaps an item already in the "Open items for review" list ("whether WearOS participates as a full shared-session participant or mirror-only", line 799) — minor redundancy, not a problem, but the assumption and the open item should resolve together.

## Downstream usability — adequate

IDs are contiguous and unique across the v1→v2 seam: FR53–FR76 continue cleanly from v1's FR1–FR52, and NFRs continue from NFR26. Cross-references mostly resolve (FR59→v1 core, FR62→FR64–FR75, FR73→NFR33, NFR34→v1 offline). Journey 6 has named protagonists (Marco + Giulia) carrying context inline. The reconciliation table makes the section pullable-out-alone better than most.

Two mechanical defects keep this from "strong" (see Mechanical notes): the v2 NFRs are numbered **out of order** (NFR27, 28, 29, 30, **33**, 31, 34, 32 as they appear top-to-bottom under their subheadings), and there is no v2 Glossary, so new domain nouns ("shared session", "co-location", "friends leaderboard", "Pro", "free tier", "storico"/"historical timeline") are defined only by usage. For a section feeding architecture + UX + stories, a 6-term glossary stub would pay off. "Storico" (line 688) appears once in Italian then never again — a synonym for "full historical timeline" (FR61) that a downstream extractor could miss.

### Findings
- **medium** v2 NFRs presented out of numeric order (§v2 NFRs, lines 766–784) — *Note:* under the subheadings the visual order is NFR27,28,29,30,33,31,34,32. NFR33 sits inside "Privacy & Compliance", NFR31 inside "Real-Time", NFR32 inside "Store" — the *grouping* is sensible but the *numbers* zig-zag, which makes a "find NFR31" lookup and any auto-generated index error-prone. *Fix:* either renumber to match presentation order or add a one-line NFR index mapping number→subsection.
- **low** No v2 glossary; "storico" (§line 688) used once then dropped as a synonym for the FR61 historical timeline — *Fix:* add a short v2 term list and drop or gloss "storico".

## Shape fit — strong

The shape matches the product. v2 is a consumer social/monetization extension, so a UJ with named protagonists is load-bearing — and Journey 6 is exactly that, carrying the group-adaptation constraint that no FR could convey alone. The section is not over-formalized (one journey, not five redundant ones) nor under-formalized (it has FRs, NFRs, reconciliation, and phasing). The brownfield reality — extending a *shipped* v1 — is handled correctly: existing v1 requirements are referenced by ID and the conflicts are distinguished from new scope, which is precisely what the rubric asks of a brownfield PRD. The addendum correctly offloads downstream depth (proximity model, point formula) rather than padding the PRD.

## Mechanical notes

- **ID continuity:** FR53–FR76 and NFR27–NFR34 continue v1's sequences without gap or duplicate. Good.
- **NFR ordering defect:** v2 NFRs appear as 27,28,29,30,**33,31,34,32** down the page (grouped by subsection, numbered out of sequence). Flagged above as medium for downstream tooling.
- **Assumptions Index roundtrip:** Six inline `[ASSUMPTION]` tags (FR57, FR62, FR71, FR75, v2 Scope header line 788, addendum scoring note). There is **no consolidated Assumptions Index** at the end of the document — the inline tags exist but are not rolled up. For a Fast-path draft this is tolerable, but a 6-line index would close the roundtrip the rubric expects.
- **Cross-refs:** FR45 already back-references NFR13 (v1, clean). v2 cross-refs (FR59, FR62, FR73→NFR33, NFR31↔FR71) resolve, except FR71's bound is not cross-referenced back from the FR (flagged under Done-ness).
- **Glossary:** No glossary in either v1 or v2. New v2 nouns rely on usage. "storico" (line 688) is an un-glossed synonym for FR61's "historical timeline".
- **Journey protagonist naming:** Journey 6 names Marco + Giulia inline with full context. Compliant.
- **Decision log / addendum:** Front-matter references `.decision-log.md` and `addendum.md`; addendum read and consistent (co-location proximity model and point formula correctly deferred there, matching the PRD's `[ASSUMPTION]` tags).
