# StateIndicator & Explanation Copy — Product Decisions

**Date:** 2026-05-15
**Decision owner:** Paolo (Project Lead)
**Participants:** Sally (UX), John (PM, standing in for PO)
**Status:** Decided
**Closes:** Epic 5 retro carry-over → Epic 6 re-flag → Epic 6.5 retro carry-over (3 epics of slippage) — second of two blocking product reviews
**Unblocks:** Story 7.1 (`StateIndicator`) creation
**Pairs with:** `ai-state-graph-product-decisions-2026-05-15.md` (same-day)

---

## Scope

Decide the copy model, tone, and concrete FR14 transition messages for the `StateIndicator` widget on the Today screen. This document is **load-bearing for the state machine architecture**: per the state-graph decision doc Q2 caveat, if `fatigued`-from-`active` copy is identical to `fatigued`-from-`recovering` copy, the state-machine target reverts to `atRisk`. The decisions below honor that caveat.

---

## Decisions

### Q1 — Copy model

**Decision:** **State-aware (transition-conditioned).**

Copy strings vary by current state AND prior state. Cost: ~12 strings in Italian, stored in `lib/l10n/state_messages.it.arb` keyed as `transition_{from}_{to}`.

**Rationale:**
- Only model that honors the state-graph Q2 caveat without reopening it.
- Placeholder ships Story 7.1 without real copy on the first non-placeholder Today surface — breaks Epic 7's user-facing promise.
- State-only forces target state back to `atRisk` → reopens state-graph review → Story 7.1 slips one sprint. State-aware is the cheapest path to delivery.

**Out of scope (binding):** no further contextual variants beyond `transition_{from}_{to}`. No time-of-day, streak, or weather-conditioned copy in Story 7.1. JTBD of `StateIndicator` is *"dimmi dove sono e cosa fare adesso"* — single axis.

---

### Q2 — Tone

**Decision:** **Friendly-coach.**

Writing rules (binding for all state strings, including future additions):

1. Seconda persona singolare ("tu", "hai", "stai") — never "Lei", never third-person.
2. Verbi al presente. Mai condizionali clinici ("dovresti", "potresti considerare").
3. **Constatazione + invito**, never **diagnosi + prescrizione**. The coach observes and invites; never diagnoses or prescribes.
4. Una frase per messaggio. Two only when the second is the actionable invite, separated by em-dash or period.
5. Nessun nome di stato (`atRisk`, `fatigued`, ecc.) esposto nel testo. The user reads the message, not the state code.
6. Niente emoji nello `StateIndicator` (state already carries color + icon).
7. Punto esclamativo permesso solo al ritorno a `active`.

**Forbidden:**
- Clinical register ("a rischio", "patologico", "deficit", "compromesso").
- Gamified register ("level up", "streak bonus", "achievement").
- Infantilizing register ("bravo!", "fantastico!").

---

### Q3 — User-facing state labels

Internal code labels remain `active`, `fatigued`, `atRisk`, `recovering`. User-facing labels in `StateIndicator`:

| Code label | User label (IT) |
|---|---|
| `active` | **In forma** |
| `fatigued` | **Sotto sforzo** |
| `atRisk` | **In ripresa** |
| `recovering` | **In recupero** |

**Rationale:** "In ripresa" replaces "A rischio" (clinical register, forbidden by Q2) and Sally's original "Da riprendere". "In ripresa" is gerundive-progressive, symmetric with "In recupero", and signals momentum rather than alarm. Note that `atRisk` and `recovering` have visually similar but semantically distinct labels — `StateIndicator` icon/color is the disambiguator (atRisk = amber-orange + warning glyph; recovering = green + restore glyph; final color tokens to be confirmed during Story 7.1 implementation).

---

### Q4 — FR14 Transition Messages (canonical, Italian)

| Key | Transition | Trigger | Copy |
|---|---|---|---|
| `transition_active_atRisk` | `active → atRisk` | `missedSessions >= 2` (Q1 state-graph, depends on Story 7.1b) | *"Ci sei mancato. Ripartiamo leggeri — 5 minuti bastano oggi."* |
| `transition_active_fatigued` | `active → fatigued` | `last-2-RPE avg > 8` | *"Hai spinto forte. Oggi alleggeriamo: sessione corta."* |
| `transition_fatigued_atRisk` | `fatigued → atRisk` | `missedSessions >= 2` while fatigued | *"Il corpo chiede una pausa più lunga. Riprendiamo dolcemente."* |
| `transition_recovering_fatigued` | `recovering → fatigued` | `last RPE >= 9` (Q2 state-graph, NEW) | *"Stiamo rientrando, ma l'ultimo sforzo è stato intenso. Torniamo a una sessione facile."* |
| `transition_atRisk_recovering` | `atRisk → recovering` | `3 RPE avg ≤ 7 AND missed=0` (Q3 state-graph, tightened) | *"Stai tornando in ritmo. Continuiamo con calma."* |
| `transition_fatigued_recovering` | `fatigued → recovering` | Same rule, from `fatigued` | *"Stai tornando in ritmo. Continuiamo con calma."* |
| `transition_recovering_active` | `recovering → active` | `3 RPE avg ≤ 6.5 AND streak ≥ 3` | *"Sei di nuovo in forma! Riprendiamoci il piano completo."* |

**Load-bearing distinction (closes state-graph Q2 caveat):**
- `transition_active_fatigued` recognizes **exertion** ("Hai spinto forte").
- `transition_recovering_fatigued` recognizes **dissonance** ("Stiamo rientrando, ma l'ultimo sforzo è stato intenso").

These strings are semantically distinct. **Q2 of the state-graph decision doc is now formally closed**: target state `fatigued` is confirmed for both arrival paths.

**Note:** `transition_atRisk_recovering` and `transition_fatigued_recovering` use the same string. This is intentional — the user-relevant fact is "you're returning to rhythm", not which alarm state you came from. Acceptable (not load-bearing for the state machine).

---

### Q5 — Static `StateIndicator` body copy (no transition fired)

When the state has not changed this evaluation, `StateIndicator` shows the static label + a static sub-copy. One string per state:

| State | Static sub-copy |
|---|---|
| `active` (In forma) | *"Pronto per il piano di oggi."* |
| `fatigued` (Sotto sforzo) | *"Oggi alleggeriamo per recuperare."* |
| `atRisk` (In ripresa) | *"Ripartiamo con calma. Sessioni brevi e leggere."* |
| `recovering` (In recupero) | *"Costruiamo il ritmo, un passo alla volta."* |

Story 7.1 implementation choice: if state just changed, show the FR14 transition message; otherwise show the static sub-copy. Single-source rule, no other branching.

---

## i18n / l10n Contract

- File: `lib/l10n/state_messages.it.arb` (create in Story 7.1).
- Keys: `transition_{from}_{to}` (7 keys), `state_label_{name}` (4 keys), `state_static_{name}` (4 keys). **15 strings total** for Story 7.1.
- English (`state_messages.en.arb`): **out of scope for Epic 7**. When added, strings are **reinterpreted, not translated** — e.g., "In ripresa" is not "At risk"; it must be re-authored from the same JTBD frame.
- Adding any new state-machine rule requires adding its `transition_{from}_{to}` key in the same PR. Enforced by code review.

---

## Implementation Checklist for Story 7.1

- [x] Copy model: state-aware (Q1).
- [x] Tone rules (Q2) — codified in this doc; story should reference these as AC.
- [x] User-facing labels (Q3) — locked.
- [x] FR14 transition strings (Q4) — locked.
- [x] Static sub-copies (Q5) — locked.
- [ ] Story 7.1 AC must include: `StateIndicator` consumes `transition_{from}_{to}` when state just changed (`BehavioralTransition.stateChanged == true`), otherwise `state_static_{name}`.
- [ ] Story 7.1 AC must include: never show internal state code label (`atRisk`, etc.) in any UI surface.
- [ ] Story 7.1 AC must include: regression test asserting `transition_active_fatigued != transition_recovering_fatigued` (load-bearing for state-graph Q2 — if these strings become equal in a future edit, state-machine target must revert to `atRisk`).

---

## Caveats and Open Items

| Item | Owner | Status |
|---|---|---|
| English copy (`state_messages.en.arb`) | Sally + future i18n review | Out of scope for Epic 7. Reinterpret, don't translate. |
| Color + icon tokens for state labels (especially `atRisk` vs `recovering`) | Sally + Amelia | Resolved during Story 7.1 implementation, not in this doc. |
| Time-of-day / streak / weather variants | Sally | Explicitly out of scope. JTBD axis is state only. |
| Tone audit of existing onboarding/disclaimer copy | Sally | Optional follow-up. Not blocking. |

---

## Decision Record

| Q | Sally | John | Final (Paolo) |
|---|---|---|---|
| Q1 model | State-aware | State-aware (cost framing) | **State-aware** |
| Q2 tone | Friendly-coach | Friendly-coach | **Friendly-coach** + 7 writing rules |
| Q3 labels | In forma / Sotto sforzo / Da riprendere / In recupero | — (state codes internal) | **In forma / Sotto sforzo / In ripresa / In recupero** (Paolo edit: "Da riprendere" → "In ripresa") |
| Q4 FR14 copy | Empathetic, "stiamo" plurale | Practical, next-action specific | **Merge: Sally tone + John specificity** |
| Q5 static copy | — | — | New: locked one string per state |

---

## Sign-off

- 🎨 Sally (UX) — agreed; voice and writing rules captured.
- 📋 John (PM, PO stand-in) — agreed; state-graph Q2 caveat formally closed.
- 👤 Paolo (Project Lead) — final decisions recorded above.

This document closes the Epic 5 retro carry-over "Explanation copy product review for Today screen" and, together with `ai-state-graph-product-decisions-2026-05-15.md`, removes both blockers to Story 7.1 creation.
