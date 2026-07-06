# Delta Review — Ongoing Session Notification (FR79 / FR80 / NFR39)

**Reviewer role:** Mobile platform & privacy-compliance reviewer
**Scope:** ONLY the ongoing-session-notification feature added 2026-07-06 (FR79, FR80, NFR39 in `prd.md`; "Experience Polish mechanism notes" in `addendum.md`). The rest of the PRD was not reviewed.
**Date:** 2026-07-06
**Gate verdict:** PASS-WITH-FIXES

---

## Requirement text under review

- **FR79** — Backgrounding during an active session shows an ongoing (persistent, not swipe-dismissible) notification with session name + paused timer. `[ASSUMPTION]` Android-primary; iOS best-effort (no guaranteed live-updating timer).
- **FR80** — On backgrounding, timer pauses (freezes). After a configurable inactivity timeout, the notification is dismissed and the session is abandoned via the existing FR20 abandon flow, returning the user to Today. Re-entering before timeout resumes the paused session.
- **NFR39** — Notification exposes only session name + timer, never biometric/HR (consistent with NFR7). Android 13+ requests POST_NOTIFICATIONS with rationale; on denial the session still pauses in-app with no notification (NFR9 graceful degradation).

Project context relied on: offline-first, local-only, no accounts (v1); NFR7 = biometric never leaves device; NFR9 = permission denial degrades gracefully; Android APK + iOS targets; no notification infrastructure exists yet.

---

## 1. Android correctness

**1a. "Not swipe-dismissible" is no longer guaranteed on Android 14+.** [HIGH]
`flutter_local_notifications` `ongoing: true` prevented swipe-dismissal on older Android. As of Android 14 (API 34), the OS made ongoing notifications user-dismissible by swipe; the only reliable non-dismissible pin is a notification backed by a *running* foreground service. Since this feature deliberately does **not** run a foreground service (see 1b), FR79's literal "not swipe-dismissible" over-promises on Android 14+. **Fix:** soften FR79 to "persistent/ongoing (best-effort non-dismissible; on Android 14+ the OS permits user swipe-dismissal)" and make the app tolerant of the user dismissing it — a swipe-away must not silently orphan session state.

**1b. Foreground service is NOT required — this is correct, and it should be stated explicitly.** [LOW / confirmation]
Because the timer *pauses* (freezes) on backgrounding (FR80), there is no ongoing CPU/timer work to keep alive, so a foreground service is genuinely unnecessary. This is the right call: it avoids the Android 14 foreground-service-type declaration and the Play Store review justification burden (`android:foregroundServiceType` + policy declaration form). **Fix:** add an explicit non-requirement to the PRD/architecture: "No foreground service is used; therefore no `foregroundServiceType` declaration or Play Console FGS justification is required." Making this explicit prevents an implementer from reflexively reaching for a FGS and inheriting the Play policy cost.

**1c. The mechanism that fires the FR80 inactivity timeout while backgrounded is unspecified and non-trivial.** [HIGH]
This is the deepest gap. With no foreground service and a suspended Dart isolate, the app cannot reliably "run a timer" in the background to (a) auto-dismiss the notification and (b) abandon the session at timeout. Two viable patterns, each with consequences the PRD doesn't address:
   - **Scheduled/alarm pattern** (e.g., `zonedSchedule` / AlarmManager / WorkManager): can post/replace/cancel a notification at a wall-clock time, but running actual app logic to mutate session state while suspended is unreliable/battery-restricted.
   - **Reconcile-on-resume pattern**: store a monotonic pause timestamp; on next foreground compute elapsed; if elapsed > timeout, abandon. Simple and reliable — **but** the notification then stays pinned until the user reopens the app, which contradicts FR80's "after inactivity timeout the notification dismisses."
   These two goals (dismiss-at-timeout-while-backgrounded vs. abandon-in-app-logic) cannot both be met cleanly without background execution. **Fix:** the PRD must specify which behavior is authoritative. Recommended: reconcile-on-resume for the abandon/state decision, plus a scheduled notification cancel/replace at the timeout instant for the visual dismissal, and accept that the definitive abandon is committed on next app open.

**1d. POST_NOTIFICATIONS handling is well specified.** [OK]
NFR39 correctly requires the Android 13+ runtime prompt with rationale and graceful degradation on denial. Minor: specify the prompt fires contextually (first session start) rather than at app launch, to maximize grant rate and match NFR9 intent.

---

## 2. iOS correctness

**2a. The [ASSUMPTION] in FR79 is technically accurate.** [OK]
iOS genuinely has no pinned, live-updating notification for a backgrounded/suspended app outside of Live Activities (ActivityKit). A one-shot `UNNotification` is possible; a continuously updating timer is not. The "best-effort, informational only" framing and deferring Live Activities are correct. The hedged wording keeps FR79 from over-promising at the concept level.

**2b. iOS notification permission is entirely unaddressed — an omission.** [HIGH]
NFR39 handles Android 13+ POST_NOTIFICATIONS but says nothing about iOS, which also requires explicit authorization (`UNUserNotificationCenter.requestAuthorization`). The iOS "best-effort local notification" cannot appear at all unless authorization was granted. **Fix:** extend NFR39 to cover iOS notification authorization with the same rationale + graceful-degradation posture (session still pauses if denied). Without this, the iOS best-effort path silently no-ops for users who never granted permission.

**2c. Scope FR79 explicitly per-platform.** [MEDIUM]
Recommend splitting FR79 into per-platform acceptance criteria (Android AC: persistent ongoing notification with paused timer; iOS AC: one-shot informational local notification, no live timer guarantee) rather than one requirement with an embedded assumption. This makes each platform independently testable and prevents QA from failing iOS against Android expectations. Same for the "abandon on iOS" path — on iOS the abandon is effectively reconcile-on-resume (see 1c), which should be stated.

---

## 3. Privacy — lock-screen content exposure

**3a. NFR39 does not address lock-screen visibility, and session names can carry health inference.** [HIGH]
NFR39 correctly excludes biometric/HR data (consistent with NFR7). However, the *session name* itself is displayed and, by default, renders on the lock screen where a bystander can read it without unlocking the device. For a mental-health/wellness app, session names may be sensitive by inference (e.g., an anxiety/stress/breathing-for-panic session name reveals a wellness-state signal about the user). NFR39's "non-sensitive content" claim treats the session name as unconditionally non-sensitive; that is not obviously true for this product category. **Fix:** make a conscious, documented decision:
   - **Recommended:** set notification lock-screen visibility to a redacted/generic form — Android `VISIBILITY_PRIVATE` (or a public version showing a generic string like "PulseCoach · session in progress") and the iOS hidden-preview equivalent — so the specific session name only appears after unlock.
   - At minimum, NFR39 should explicitly state the lock-screen exposure decision rather than being silent on it.
   This keeps the feature aligned with the app's local-only / privacy-forward posture (NFR7).

---

## 4. Completeness gaps

**4a. Notification-tap behavior (deep link) is unspecified.** [HIGH]
FR79/FR80 never say what tapping the notification does. The expected behavior — deep-link straight back into the active in-session screen and resume the paused timer — is net-new routing since no notification infrastructure exists. This needs an explicit AC (tap → navigate to in-session route → resume), distinct from a plain app relaunch, and must handle the case where the session was already auto-abandoned by timeout before the tap (tap should land on Today, not a dead session).

**4b. Rapid background/foreground toggling semantics are undefined.** [MEDIUM]
Pause/resume must be idempotent and debounced: rapid toggling must not drift the timer, spawn duplicate notifications, or mis-handle the inactivity clock. Open question the PRD must answer: does the inactivity timeout reset on each foreground, or accumulate across background intervals? (Recommended: the inactivity clock is the contiguous time since the *most recent* backgrounding; foregrounding cancels it.) State this explicitly.

**4c. Auto-abandon vs. explicit abandon may pollute the behavioral state machine.** [MEDIUM]
FR80 routes the timeout through the existing FR20 abandon flow, and the addendum says partial progress is "handled as today." But an auto-abandon caused by the phone locking is behaviorally different from a user deliberately quitting. If both feed the adherence/behavioral-state signals identically, a user who simply pocketed their phone could be pushed toward AtRisk/Recovering unfairly. **Fix:** decide whether timeout-driven abandon should be tagged distinctly from explicit abandon so it does not over-penalize the state machine — or explicitly document that they are intentionally equivalent.

**4d. Single-active-session guarantee and stale-notification reconciliation.** [MEDIUM]
The design implicitly assumes one active session. Specify: a single fixed notification ID, and the notification is guaranteed cleared on completion, abandon, and app kill. Critically, without a foreground service an ongoing notification can be **orphaned** if the OS/user force-kills the app while a session is backgrounded — on next cold start the app must reconcile session state (leveraging NFR15's surviving DB) and clear any stale notification. Add this as an AC.

**4e. Timeout clock source.** [LOW]
The frozen timer / inactivity computation should use a monotonic clock (Android `elapsedRealtime`) or a stored wall-clock timestamp that is robust to the user changing device time, so a device clock change cannot prematurely or indefinitely defer the abandon. Minor implementation note worth capturing in architecture.

---

## Summary of required fixes before implementation

| ID | Sev | Fix |
|----|-----|-----|
| 1a | HIGH | Soften FR79 "not swipe-dismissible" for Android 14+; tolerate user dismissal without orphaning state. |
| 1c | HIGH | Specify the backgrounded inactivity-timeout mechanism (scheduled cancel + reconcile-on-resume authority). |
| 2b | HIGH | Add iOS notification authorization handling to NFR39 (parallel to Android POST_NOTIFICATIONS). |
| 3a | HIGH | Decide + document lock-screen visibility; redact/generic session name on lock screen. |
| 4a | HIGH | Specify notification-tap deep-link + resume behavior, incl. already-abandoned case. |
| 1b | LOW | State explicitly: no foreground service → no FGS type declaration / Play justification. |
| 2c | MED | Split FR79 into per-platform acceptance criteria. |
| 4b | MED | Define rapid-toggle idempotency and whether the inactivity clock resets or accumulates. |
| 4c | MED | Decide whether auto-abandon is tagged distinctly from explicit abandon for the state machine. |
| 4d | MED | Single fixed notification ID; guaranteed clear + cold-start reconciliation of orphaned notifications. |
| 4e | LOW | Use a monotonic/time-change-robust clock for the timeout computation. |

**Verdict rationale:** The feature concept is sound and the Android-primary / iOS-best-effort framing is honest. No fatal flaw, but five HIGH gaps (Android 14 dismissibility, backgrounded-timeout mechanism, iOS permission omission, lock-screen privacy, tap deep-link) must be resolved in the PRD/architecture before this is implementation-ready. Hence **PASS-WITH-FIXES**.
