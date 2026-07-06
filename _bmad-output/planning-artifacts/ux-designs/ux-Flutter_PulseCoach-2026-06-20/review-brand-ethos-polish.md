# Brand-Ethos Consistency Review — v1 Experience Polish (FR78 / FR81 / FR82)

_Scope: only the 2026-07-06 Update that added `MilestoneProgressBar` (FR78), `ActiveDaysCard` (FR81), and `FactorIconRow` (FR82) to DESIGN.md + EXPERIENCE.md. Untouched v1/v2 material was not re-reviewed. Ethos tested: calm counter-statement, no streak-guilt, one emotional temperature that never raises its voice, warmth over metrics, resolve don't linger, silence is a feature, competence over congratulation._

## Verdict: **PASS-WITH-FIXES**

The FR78 micro-animation is disciplined and well-fenced. FR82 is a clean addition. FR81's reframe is the load-bearing risk: the distilled wording removes the *theater* of a streak but keeps its *mechanic* (a consecutive counter that resets to zero), which leaves a real crack and a citable internal contradiction. One MED semiotic issue on FR78's chosen glyph, one MED on completion-beat stacking, one LOW on FR82. None is a hard fail; all are fixable in-spine.

---

## Findings

### [HIGH] ActiveDaysCard keeps the streak *mechanic* while renaming it — the reset-to-zero is still a guilt chain
**Where:** `DESIGN.md` → Brand & Style, "Streak-counter vs. active-days" (line ~132: *"the count of **consecutive** days with a completed session"*) and Components → ActiveDaysCard (line ~216). Contradicts `EXPERIENCE.md` → Interaction Primitives (line ~112: *"Banned: streak mechanics (flame glyphs, don't-break-the-chain, **reset-shame**…)"*) and Anti-patterns (line ~178) + Brand claim *"not a chain to protect."*

**The crack:** "Consecutive days with a completed session" is, definitionally, a chain. The reframe strips the flame, the banner, and the "streak lost" copy — but it keeps the one property that makes a streak a guilt device: **the number climbs while you comply and snaps to 0 the moment you rest.** A user who sees "Attivo da 12 giorni" and, after a single (physiologically legitimate) rest day, opens the app to "Attivo da 0 giorni" experiences the exact loss the brand law forbids — silence around the drop does not neutralize the drop. This directly undercuts the recovery-empathy promise the app defends everywhere else (Flow 3, Protective-State Suppression, "absence is physiological data, not failure"). The spine *asserts* it is "not a chain to protect," but the mechanic it specifies *is* a chain. That is an internal contradiction, not just a tone risk.

**Suggested fix:** Change the underlying metric from *consecutive* to a **non-resetting** one, so the ethos claim becomes true rather than aspirational. Options, in order of preference:
- **Windowed count:** "Attivo N degli ultimi 30 giorni" — never resets to zero on one rest day, reads rest as normal variance.
- **Cumulative count:** "N giorni attivi questo mese" — monotonic within the period, no punishment event.

If Paolo insists on retaining *consecutive* (it was a deliberate reconciliation), the spine must at minimum stop claiming it is "not a chain" and instead state the accepted residual risk explicitly, and specify that the transition from N→0 is rendered with the identical calm treatment as any other value **including no visual delta emphasis** (no color change, no downward motion) — but note that even a silent 12→0 is a felt reset. The windowed reframe is the only version that actually holds the line.

---

### [MED] FR78 finish marker uses a checkered-flag glyph — a racing/victory metaphor inside the one sanctioned flourish
**Where:** `DESIGN.md` → Components → MilestoneProgressBar (line ~209) and Do/Don't row (line ~242); `EXPERIENCE.md` → Component Patterns (line ~71) + Flow 2 (line ~194–196).

**The crack:** The animation *timing* is correctly restrained (~300–400ms, no confetti/particles/sound, Reduce-Motion → static, never extends beyond the marker). The problem is semiotic, not motion-budget: a **checkered flag** is the finish-line-of-a-race icon — a competition/win metaphor. It quietly imports "you won the race" into an app whose entire thesis is "calm counter-statement to the fitness category" and "competence over congratulation." It is the sports-achievement register the brand rejects, smuggled in as a glyph rather than an animation. The one place they sanctioned a flourish is the one place the metaphor should be *least* competitive.

**Suggested fix:** Replace the checkered-flag with a neutral, calm end-marker that reads "complete," not "won": a soft filled terminal dot, a thin `rounded/full` cap, or a small circle-check in `{primary}`. Keep the settle+glow beat unchanged. Update DESIGN.md line ~209 and EXPERIENCE.md Flow 2 ("finish flag") wording accordingly.

---

### [MED] New finish-marker glow now fires seconds before the existing CompletionRing pulse — two positive beats back-to-back
**Where:** `EXPERIENCE.md` → Flow 2, steps 3–4 (lines ~195–196): finish-marker glow at last-step completion, then the 3s MiniSummary where `CompletionRing` "animates here." Cross-ref `DESIGN.md` CompletionRing (line ~211, "emotional pulse belongs to the post-session summary") and MilestoneProgressBar ("distinct from the CompletionRing pulse").

**The crack:** The spines correctly declare the two animations *distinct*, but do not address that they now fire **in sequence within ~3–4 seconds**: finish glow → RPE tap → ring pulse. Individually each is restrained; compounded, they read as a two-stage completion celebration, which nudges against "one emotional temperature… never raises its voice" and "resolve, don't linger." The single sanctioned flourish was sanctioned as *one* beat; the flow now delivers two.

**Suggested fix:** Add one sentence to the MilestoneProgressBar spec (or Flow 2) stating the two beats must not stack into a sequence — e.g. the finish-marker glow and the MiniSummary ring pulse are mutually aware, and the end-of-session emotional beat lives in **one** of them (recommend keeping the ring pulse as the single emotional close and making the finish-marker settle purely functional/static, or vice-versa). At minimum, name the adjacency so implementation doesn't produce a double-flourish by default.

---

### [LOW] FactorIconRow factor detail sits behind a tap, and a multi-glyph strip edges toward the rejected metrics dashboard
**Where:** `DESIGN.md` → Components → FactorIconRow (line ~215); `EXPERIENCE.md` → Component Patterns (line ~69). Tension with `DESIGN.md` Do/Don't *"One always-visible AI explanation line… | Hide the 'why' behind a tap"* and Anti-patterns *"multi-metric dashboards (phone)."*

**The crack (minor):** The primary "why" stays visible in `ExplanationLine`, so the core rule holds — but each factor glyph's meaning is revealed only on tap, and a row of up to five glyphs directly under the single calm line risks *reading* as a compact metric strip, the thing the phone experience explicitly rejects. This is presentation-only over FR13/FR14 and is well-guarded (variable slots, recessive `on-surface-variant`, semantics labels), so the risk is low, not structural.

**Suggested fix:** No wording change strictly required. Optionally add a guard to the FactorIconRow spec: cap the row so it never presents as a full data readout (it already shows "only factors that applied"), and keep it visually subordinate to the ExplanationLine (smaller, dimmer, no numeric values) so it can never be mistaken for a metrics row. The existing "purely informational, never an action surface" line covers most of this.

---

## Notes
- The `humidity` exclusion (FR82) is correctly and consistently stated in both spines — no issue.
- FR78's Reduce-Motion / NFR38 handling is complete and consistent across DESIGN Do/Don't, Component spec, and EXPERIENCE Accessibility Floor — no issue.
- ActiveDaysCard's single-source-of-truth (FR23 signal, no parallel counter) is clean — the HIGH finding is about the *metric definition*, not the data plumbing.
