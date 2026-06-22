---
stepsCompleted: ['step-01-load-context', 'step-02-discover-tests', 'step-03-map-criteria', 'step-04-analyze-gaps', 'step-05-gate-decision']
lastStep: 'step-05-gate-decision'
lastSaved: '2026-06-22'
scope: 'Epic 17 — Pro Subscription & Feature Gating (v2.2)'
coverageBasis: 'acceptance_criteria'
oracleResolutionMode: 'formal_requirements'
oracleConfidence: 'high'
oracleSources:
  - '_bmad-output/implementation-artifacts/17-1-revenuecat-iap-integration-and-entitlement-gate.md'
  - '_bmad-output/implementation-artifacts/17-2-progress-history-free-pro-gating-with-grandfathering.md'
  - '_bmad-output/implementation-artifacts/17-3-pro-upsell-sheet-with-session-day-cooldown.md'
  - '_bmad-output/implementation-artifacts/17-4-subscription-purchase-restore-and-management.md'
externalPointerStatus: 'not_used'
tempCoverageMatrixPath: '/tmp/tea-trace-coverage-matrix-epic17-2026-06-22.json'
---

# Coverage Traceability Matrix — Epic 17
**Generated:** 2026-06-22  
**Scope:** Epic 17 — Stories 17.1, 17.2, 17.3, 17.4 (Pro Subscription & Feature Gating v2.2)  
**Oracle mode:** `formal_requirements` (25 ACs across 4 story files, all status: done)  
**Oracle confidence:** high  
**Test suite:** `flutter test` 982/982 PASS | `flutter analyze` 0 issues  
**Epic 17 dedicated tests:** ~50 total (33 unit + 17 widget/component)

---

## Test Inventory

| Test File | Level | Epic 17 Count | Status | Test IDs |
|-----------|-------|---------------|--------|----------|
| `test/bloc/subscription_bloc_test.dart` | unit | 9 | committed | initial-state, check-pro/signedInFree/accountFree/error, 17.4-BLOC-001..004 |
| `test/bloc/paywall_cubit_test.dart` | unit | 3 | committed | 17.4-PAYWALL-001..003 |
| `test/bloc/progress_gating_cubit_test.dart` | unit | 5 | committed | 17.2-CUBIT-001..005 |
| `test/data/subscription/entitlement_gate_test.dart` | unit | 5 | committed | check-accountFree/pro/signedInFree/accountFree-no-session/NFR34 |
| `test/features/subscription/upsell_cooldown_service_test.dart` | unit | 4 | committed | 17.3-COOL-001..004 |
| `test/features/subscription/get_install_cohort_use_case_test.dart` | unit | 4 | committed | use-case-001..004 |
| `test/features/auth/auth_repository_impl_sync_test.dart` | unit | 3 | committed | 17.2-SYNC-001..003 |
| `test/data/database/app_database_test.dart` | unit | +2 (migration) | committed | schema-v9-migration, backfill-pre_v2 |
| `test/widget/subscription/pro_upsell_sheet_test.dart` | component | 5 | committed | 17.3-WIDGET-001..005 |
| `test/widget/subscription/paywall_page_test.dart` | component | 7 | committed | 17.4-WIDGET-001..007 |
| `test/widget/settings_page_test.dart` | component | 2 | committed | 17.4-WIDGET-008..009 |
| `test/widget/progress/progress_page_test.dart` | component | 3 | committed | 17.2-WIDGET-001..003 |
| **Total** | | **~50** | | |

---

## Traceability Matrix

### Story 17.1 — RevenueCat IAP Integration & EntitlementGate

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | `purchases_flutter` SDK configured at app startup before any IAP call | P2 | PARTIAL | `subscription_bloc_test` exercises self-dispatch behavior requiring SDK; no isolated boot-order unit test; startup wiring verified structurally by `flutter test` 943/943 after 17.1 |
| AC2 | `EntitlementGate.check()` resolves all three tiers: `pro`, `signedInFree`, `accountFree` | P1 | FULL | `entitlement_gate_test.dart`: check-pro, check-signedInFree, check-accountFree |
| AC3 | Default tier is `accountFree` before any `refresh()` call | P1 | FULL | `entitlement_gate_test.dart`: "check() defaults to accountFree before any refresh" |
| AC4 | `SubscriptionBloc` emits error state on network/entitlement failure; cached tier preserved (NFR34) | P1 | FULL | `subscription_bloc_test`: "emits [loading, error] on checkEntitlement failure"; `entitlement_gate_test`: "check() preserves cached tier when refresh() throws NFR34" |
| AC5 | No loading flash: `SubscriptionBloc` reads RevenueCat local cache, loading→loaded within same pump | P2 | PARTIAL | `subscription_bloc_test` blocTest verifies correct loading→loaded emission sequence; frame-budget "no flash" assertion absent (structural guarantee via `skip: 0` self-dispatch pattern) |
| AC6 | `installCohort` TEXT column added to Drift `user_profile` table (schema v8→v9) with `pre_v2` backfill | P1 | FULL | `app_database_test.dart` +2 migration tests: schema v8→v9 column creation + existing-row `pre_v2` backfill (per story completion notes) |
| AC7 | Zero regressions: 943 passing tests after 17.1 | P3 | FULL | Story 17.1 completion notes: "943/943 PASS" |

**Story 17.1 summary:** 4 FULL · 2 PARTIAL · 0 NONE · 1 P3-meta

---

### Story 17.2 — Progress History Free/Pro Gating with Grandfathering

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | Pre-v2 user (`installCohort = 'pre_v2'`) sees full Progress tabs regardless of `SubscriptionTier` | P1 | FULL | `progress_page_test.dart 17.2-WIDGET-002`; `progress_gating_cubit_test.dart 17.2-CUBIT-002` |
| AC2 | Post-v2 free user sees locked banner instead of Progress tabs (no lock icon badge) | P1 | FULL | `progress_page_test.dart 17.2-WIDGET-001` (locked banner renders; no extraneous lock icon widget) |
| AC3 | Tapping the locked banner prompt invokes `ProUpsellSheet.show()` | P2 | PARTIAL | No direct widget test in `progress_page_test.dart` verifying tap→sheet integration; ProUpsellSheet widget behavior tested independently in 17.3-WIDGET-001..005 |
| AC4 | Pro tier unlock reveals full Progress content in-place (no navigation) | P1 | FULL | `progress_page_test.dart 17.2-WIDGET-003` (reactive unlock: `SubscriptionBloc` emits `loaded(pro)` → cubit rebuilds → full tabs appear) |
| AC5 | `installCohort` is restored from Supabase on sign-in (merge rule: `pre_v2` always wins) | P2 | FULL | `auth_repository_impl_sync_test.dart 17.2-SYNC-002` (local `post_v2` + cloud `pre_v2` → local updated to `pre_v2`) |
| AC6 | `installCohort` written to Supabase `profiles` on sign-in | P2 | FULL | `auth_repository_impl_sync_test.dart 17.2-SYNC-001` (local `pre_v2` + cloud `post_v2` → cloud written canonical `pre_v2`) |
| AC7 | Zero regressions: 958 passing tests after 17.2 | P3 | FULL | Story 17.2 completion notes: "958/958 PASS" |

**Story 17.2 summary:** 5 FULL · 1 PARTIAL · 0 NONE · 1 P3-meta

---

### Story 17.3 — ProUpsellSheet with Session-Day Cooldown

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | `ProUpsellSheet.show()` displays modal bottom sheet when `isCoolingDown()` returns false | P1 | FULL | `pro_upsell_sheet_test.dart 17.3-WIDGET-001` |
| AC2 | Tapping "non ora" calls `recordDismissal()` and dismisses the sheet | P1 | FULL | `pro_upsell_sheet_test.dart 17.3-WIDGET-003`; `upsell_cooldown_service_test.dart 17.3-COOL-002` (isCoolingDown returns true after recordDismissal) |
| AC3 | Subsequent `show()` calls return early silently when `isCoolingDown()` returns true | P1 | FULL | `pro_upsell_sheet_test.dart 17.3-WIDGET-002` |
| AC4 | Cooldown resets at calendar day boundary (`yyyy-MM-dd`), not 24-hour rolling window | P2 | FULL | `upsell_cooldown_service_test.dart 17.3-COOL-003` (isCoolingDown returns false when stored date is yesterday) |
| AC5 | No persistent lock icons anywhere in the app (UX principle: prompt, not lock) | P2 | PARTIAL | `progress_page_test.dart 17.2-WIDGET-001` renders banner correctly; `17.2-WIDGET-002` shows full tabs. No explicit `find.byIcon(Icons.lock).findsNothing` assertion; absence is implied by successful rendering |
| AC6 | Zero regressions: 966 passing tests after 17.3 | P3 | FULL | Story 17.3 completion notes: "966/966 PASS" |

**Story 17.3 summary:** 4 FULL · 1 PARTIAL · 0 NONE · 1 P3-meta

---

### Story 17.4 — Subscription Purchase, Restore & Management

| # | Acceptance Criterion | Priority | Coverage | Evidence |
|---|---------------------|----------|----------|----------|
| AC1 | `PaywallPage` renders live prices from RevenueCat offerings (no hardcoded prices) | P0 | FULL | `paywall_page_test.dart 17.4-WIDGET-002` (plan cards show `priceString` + `period` from `ProOffer` entity); `paywall_cubit_test.dart 17.4-PAYWALL-001` (loadOfferings emits `loaded(offers)`) |
| AC2 | Purchase flow: `purchaseRequested` → `SubscriptionBloc` → `loaded(pro)` → `PaywallPage` pops | P0 | FULL | `subscription_bloc_test.dart 17.4-BLOC-001` (purchaseRequested → [loading, loaded(pro)]); `paywall_page_test.dart 17.4-WIDGET-003` (Acquista tap → event dispatched); `17.4-WIDGET-005` (loading→loaded(pro) → page pops) |
| AC3 | Restore purchases: `restoreRequested` → `SubscriptionBloc` → tier re-confirmed | P1 | FULL | `subscription_bloc_test.dart 17.4-BLOC-003` (restoreRequested → [loading, loaded(tier)]); `paywall_page_test.dart 17.4-WIDGET-004` (Ripristina acquisti → event dispatched) |
| AC4 | "Gestisci abbonamento" tile visible for Pro users; tapping opens platform store subscription URL | P1 | PARTIAL | `settings_page_test.dart 17.4-WIDGET-009` (Pro user sees "Gestisci abbonamento"); `17.4-WIDGET-008` (free user sees "Scopri Pro"). No mockito-based test for `launchUrl` tap action — deferred at code review |
| AC5 | Zero regressions: 982 passing tests after 17.4 | P3 | FULL | Story 17.4 completion notes: "982/982 PASS" (981 + 1 review patch) |

**Story 17.4 summary:** 3 FULL · 1 PARTIAL · 0 NONE · 1 P3-meta

---

## Coverage Statistics (Steps 3+4)

| Metric | Value |
|--------|-------|
| Total ACs | 25 |
| FULL coverage | 20 (80%) |
| PARTIAL coverage | 5 (20%) |
| NONE coverage | 0 |
| WAIVED | 0 |

### Priority Breakdown

| Priority | Total | FULL | PARTIAL | NONE | Coverage% |
|----------|-------|------|---------|------|-----------|
| P0 | 2 | 2 | 0 | 0 | **100%** ✅ |
| P1 | 12 | 11 | 1 | 0 | **91.7%** ✅ |
| P2 | 7 | 3 | 4 | 0 | 42.9% |
| P3 | 4 | 4 | 0 | 0 | 100% |
| **Overall** | **25** | **20** | **5** | **0** | **80%** ✅ |

---

## Gap Analysis (Step 4)

### Gaps by Priority

**P0 gaps:** None ✅

**P1 gaps (PARTIAL):**

| AC | Gap Description | Risk |
|----|----------------|------|
| 17.4-AC4 | `launchUrl` invocation not tested: "Gestisci abbonamento" tile renders correctly (WIDGET-008/009) but no test mocks `url_launcher` and verifies the call. A misconfigured URL would reach production undetected. | Medium |

**P2 gaps (PARTIAL):**

| AC | Gap Description | Risk |
|----|----------------|------|
| 17.1-AC1 | IAP SDK boot-order not directly unit-tested. Startup wiring verified structurally via successful test suite run; no isolated "SDK configured before consumer" assertion. | Low |
| 17.1-AC5 | No-flash assertion absent. Frame-budget guarantee is structural (`.skip(0)` self-dispatch) rather than behavioral. | Low |
| 17.2-AC3 | `ProgressPage` banner tap → `ProUpsellSheet.show()` integration not directly tested. Sheet behavior verified independently; end-to-end tap integration gap. | Low |
| 17.3-AC5 | No explicit `find.byIcon(Icons.lock).findsNothing` assertion. Absence of lock icons is implicit in rendering tests. | Low |

### Coverage Heuristics

| Heuristic | Status | Notes |
|-----------|--------|-------|
| Endpoint coverage | N/A | No REST endpoints owned; RevenueCat SDK is a library, not a controller endpoint |
| Auth negative paths | Present | `entitlement_gate_test` covers signed-out (accountFree) + thrown-error (NFR34 cache); `17.2-SYNC-003` covers Supabase throw on sync |
| Error path coverage | Present | Purchase failure (BLOC-002), restore failure (BLOC-004), offerings error (PAYWALL-002), Supabase sync throw (SYNC-003) all covered |
| UI loading/empty/error states | Present | Shimmer loading (WIDGET-001), error SnackBar (WIDGET-006), loaded-non-pro SnackBar (WIDGET-007), locked banner (WIDGET-001), full tabs (WIDGET-002) |
| Happy-path-only gaps | 2 | 17.1-AC1 (boot wiring), 17.4-AC4 (launchUrl tap) |
| UI journey without E2E | Not applicable | No E2E framework in project; coverage via Flutter widget tests (component level) |

---

## Recommendations

| Priority | Action | AC(s) |
|----------|--------|-------|
| MEDIUM | Add `url_launcher` mock test in `settings_page_test.dart`: stub `canLaunchUrl`/`launchUrl`, tap "Gestisci abbonamento", verify `launchUrl` called with App Store subscription management URL | 17.4-AC4 |
| LOW | Add explicit `find.byIcon(Icons.lock).findsNothing` assertion to `17.2-WIDGET-001` | 17.3-AC5 |
| LOW | Add `ProUpsellSheet.show()` integration test from `progress_page_test.dart` banner tap (requires mock of cooldown service) | 17.2-AC3 |
| LOW | Accept 17.1-AC1 (boot-order) and 17.1-AC5 (no-flash) as structurally verified; document as known gap in ledger | 17.1-AC1, 17.1-AC5 |
| LOW | Run `/bmad:tea:test-review` to assess test quality across Epic 17 suite | — |

---

## Gate Decision (Step 5)

```
╔══════════════════════════════════════════╗
║  GATE DECISION: ✅ PASS                  ║
╚══════════════════════════════════════════╝
```

**Rationale:** P0 coverage is 100%, P1 coverage is 91.7% (target: ≥90%), and overall coverage is 80% (minimum: ≥80%). All three gate thresholds are met. No P0 or critical gaps identified.

| Criterion | Required | Actual | Status |
|-----------|----------|--------|--------|
| P0 coverage | 100% | 100% | ✅ MET |
| P1 coverage (target) | ≥ 90% | 91.7% | ✅ MET |
| P1 coverage (minimum) | ≥ 80% | 91.7% | ✅ MET |
| Overall coverage | ≥ 80% | 80% | ✅ MET |

**Collection status:** COLLECTED  
**Oracle:** `formal_requirements` (4 story files, all status: done) — confidence: high  
**Decision date:** 2026-06-22  
**Evaluator:** Paolo

### Residual Risks

The single P1 PARTIAL item (17.4-AC4 — `launchUrl` not tested) represents a medium-risk gap: a misconfigured App Store URL would reach production undetected. The recommendation above (MEDIUM priority) should be resolved before the next subscription-related story or before Epic 17 retrospective sign-off.

The four P2 PARTIAL items carry low individual risk and are acceptable at this gate. The banner-tap integration gap (17.2-AC3) is the most actionable and could be addressed as a quick follow-up task.

---

*Report generated by bmad-testarch-trace workflow (Create mode) — 2026-06-22*
