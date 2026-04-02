---
name: Project State
description: PulseCoach current sprint state and key technical facts
type: project
---

Epic 1 done, Epic 2 in-progress. Story 2.2 done (91 tests). Story 2.3 ready-for-dev.

**Why:** Tracking where we are to avoid re-deriving sprint state each session.
**How to apply:** When creating stories or checking status, start from Epic 2 Story 2.4 as next backlog after 2.3 completes.

Key technical facts:
- DB schema v2 (v3 needed for Story 2.3 — adds availableTime + physicalConstraints columns)
- OnboardingCubit constructor: (AcceptDisclaimer, CheckDisclaimerStatus) — Story 2.3 adds SaveProfile as 3rd param
- Test count: 91 after Story 2.2
- Lottie infinite ticker workaround: wrap carousel tests in MediaQuery(disableAnimations: true)
