---
baseline_commit: 61bcc6a
---

# Story 17.3: ProUpsellSheet with Session-Day Cooldown

Status: done

## Story

As a free-tier user,
I want the Pro upsell to appear only when I reach for a Pro feature and not again for the rest of the day,
So that I can evaluate Pro at my own pace without being nagged.

## Acceptance Criteria

**AC1 — Sheet appears on first Pro-gated tap (UX-DR25):**
Given a free-tier user taps a Pro-gated capability (e.g. tapping "Lo storico completo è una funzione Pro." on ProgressPage)
When the tap is handled and no cooldown is active
Then `ProUpsellSheet.show(context)` displays a bottom sheet stating one fact + `Scopri Pro` (primary) + `non ora` (secondary/text) buttons

**AC2 — `non ora` records cooldown and dismisses:**
Given the `ProUpsellSheet` is visible
When the user taps `non ora`
Then the sheet dismisses; `UpsellCooldownService.recordDismissal()` is called; `isCoolingDown()` returns `true` for the remainder of the calendar day

**AC3 — Subsequent Pro-gated taps silently ignored during cooldown:**
Given `UpsellCooldownService.isCoolingDown()` returns `true`
When the user taps any Pro-gated feature that calls `ProUpsellSheet.show(context)`
Then the sheet does NOT appear; no error, no visual feedback — the feature simply does not activate

**AC4 — Cooldown resets at calendar day boundary:**
Given a cooldown was recorded on day D (device local time)
When `isCoolingDown()` is called on day D+1 or later
Then it returns `false`; the sheet may appear once more

**AC5 — No persistent lock icons anywhere (UX-DR25):**
Given any free-tier user views a gated screen (e.g. ProgressPage locked state from Story 17.2)
When the screen renders
Then there is NO lock icon, badge, "🔒" glyph, or any ambient paywall signal; the paywall speaks only through the sheet

**AC6 — Zero regressions:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then both report zero issues and all existing 959 tests continue to pass; new tests are green

## Tasks / Subtasks

- [x] **Task 1 — `UpsellCooldownService` (AC2, AC3, AC4)**
  - [x] 1.1 Create `lib/features/subscription/data/services/upsell_cooldown_service.dart` — `@singleton`, takes `SharedPreferences` in constructor
  - [x] 1.2 Implement `bool isCoolingDown()`: reads `_kCooldownKey` from prefs; if null → `false`; parse stored ISO date string, compare to `DateTime.now().toLocal()` calendar date; return `true` only when same year/month/day
  - [x] 1.3 Implement `void recordDismissal()`: writes today's ISO date string (`DateTime.now().toLocal().toIso8601String().substring(0, 10)`) to `_kCooldownKey` in prefs — synchronously via `_prefs.setString(...)` (no await needed in the call site — fire-and-forget write is safe for this use case)

- [x] **Task 2 — Update `ProUpsellSheet` with cooldown gating (AC1, AC2, AC3)**
  - [x] 2.1 Change `ProUpsellSheet._()` constructor to accept `UpsellCooldownService _cooldown` (private final field)
  - [x] 2.2 Change `show()` to: resolve `UpsellCooldownService` (via `cooldownOverride ?? getIt<UpsellCooldownService>()`); if `isCoolingDown()` → return early (no sheet, no error); otherwise call `showModalBottomSheet` passing the resolved service to the widget
  - [x] 2.3 Wire `non ora` button: call `_cooldown.recordDismissal()` before `Navigator.of(context).pop()` — the existing `Scopri Pro` button closes without recording cooldown (Story 17.4 wires the purchase; tapping `Scopri Pro` is a positive intent, not a dismissal)
  - [x] 2.4 Add `@visibleForTesting UpsellCooldownService? cooldownOverride` named param to `show()` for test isolation (mirrors 17.2's `@visibleForTesting` seam pattern on `AuthRepositoryImpl`)

- [x] **Task 3 — DI wiring (AC6)**
  - [x] 3.1 Confirm `@singleton` annotation on `UpsellCooldownService` — `SharedPreferences` is already registered as async singleton via `settings_module.dart`; no additional module needed
  - [x] 3.2 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [x] 3.3 Confirm `UpsellCooldownService` appears in `injection.config.dart`

- [x] **Task 4 — Tests (AC1–AC5, AC6)**
  - [x] 4.1 Create `test/features/subscription/upsell_cooldown_service_test.dart`:
    - `17.3-COOL-001`: `isCoolingDown()` returns `false` when no key stored (first open)
    - `17.3-COOL-002`: `isCoolingDown()` returns `true` after `recordDismissal()` called (same day)
    - `17.3-COOL-003`: `isCoolingDown()` returns `false` when stored date is yesterday
    - `17.3-COOL-004`: `recordDismissal()` writes today's ISO date string (`yyyy-MM-dd`) to prefs
  - [x] 4.2 Create `test/widget/subscription/pro_upsell_sheet_test.dart` (or update if it exists):
    - `17.3-WIDGET-001`: `show()` calls `showModalBottomSheet` when cooldown returns `false` (not cooling)
    - `17.3-WIDGET-002`: `show()` returns early without showing sheet when cooldown returns `true`
    - `17.3-WIDGET-003`: tapping `non ora` calls `cooldown.recordDismissal()` then dismisses the sheet
  - [x] 4.3 Run `flutter test` — all 959 + new tests green; `flutter analyze` 0 issues

## Dev Notes

### UpsellCooldownService — full implementation shape

```dart
// lib/features/subscription/data/services/upsell_cooldown_service.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class UpsellCooldownService {
  static const _kCooldownKey = 'pro_upsell_dismissed_date';
  final SharedPreferences _prefs;

  UpsellCooldownService(this._prefs);

  bool isCoolingDown() {
    final stored = _prefs.getString(_kCooldownKey);
    if (stored == null) return false;
    final today = _todayLocalString();
    return stored == today;
  }

  void recordDismissal() {
    _prefs.setString(_kCooldownKey, _todayLocalString());
  }

  String _todayLocalString() =>
      DateTime.now().toLocal().toIso8601String().substring(0, 10);
}
```

No `Either` / no `Failure` — this is a best-effort UI preference, not a domain operation. If `setString` fails silently (e.g. full disk), the worst outcome is no cooldown this session — acceptable (UX-DR25 says "no repeated nagging" as a goal, not a hard invariant).

### ProUpsellSheet — updated shape

```dart
// lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/material.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/subscription/data/services/upsell_cooldown_service.dart';

class ProUpsellSheet extends StatelessWidget {
  final UpsellCooldownService _cooldown;
  const ProUpsellSheet._(this._cooldown);

  static void show(
    BuildContext context, {
    @visibleForTesting UpsellCooldownService? cooldownOverride,
  }) {
    final cooldown = cooldownOverride ?? getIt<UpsellCooldownService>();
    if (cooldown.isCoolingDown()) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => ProUpsellSheet._(cooldown),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... existing layout unchanged ...
    // non ora handler:
    //   onPressed: () {
    //     _cooldown.recordDismissal();
    //     Navigator.of(context).pop();
    //   }
    //
    // Scopri Pro handler: unchanged (pop only — Story 17.4 wires purchase)
  }
}
```

### Critical: `@singleton` for `UpsellCooldownService` is correct

`EntitlementGate` is `@singleton` — use the same pattern. One instance per app lifecycle manages cooldown state. A new instance (if incorrectly `@injectable`) would lose the SharedPreferences-backed state on re-read — but since SharedPreferences is persistent, even a fresh instance reads the right value. Still, `@singleton` is correct to match the project's pattern for infrastructure services (`EntitlementGate`, `AppDatabase`).

### Critical: Do NOT make SharedPreferences calls async in `show()`

`SharedPreferences.getString()` is synchronous once the instance is resolved. `setString()` is synchronous too (it updates an in-memory map; the async disk flush is handled internally). The DI async singleton (`singletonAsync<SharedPreferences>`) means it's resolved before any widget calls `show()` — safe.

### Critical: `Scopri Pro` does NOT record the dismissal

`Scopri Pro` is a positive intent — the user is actively interested. Recording a dismissal on `Scopri Pro` would suppress the sheet for the day if the purchase flow gets cancelled. Only `non ora` is a rejection signal. Story 17.4 will navigate to a paywall page from `Scopri Pro` — cooldown state must remain clean for that flow.

### Critical: ProUpsellSheet import in `show()` needs `injection.dart`

`lib/core/di/injection.dart` is the `getIt` entry point (it re-exports `get_it`'s `GetIt.instance`). Import it as `package:pulse_coach/core/di/injection.dart`. Do NOT import `injection.config.dart` directly (it's generated).

### Critical: Test isolation for `ProUpsellSheet` widget tests

Use the `cooldownOverride` seam:

```dart
// In test:
final mockCooldown = MockUpsellCooldownService();
when(mockCooldown.isCoolingDown()).thenReturn(false);
ProUpsellSheet.show(tester.element(find.byType(MaterialApp)), cooldownOverride: mockCooldown);
```

Mock with `@GenerateMocks([UpsellCooldownService])` — `UpsellCooldownService` has no generics, mockito will generate cleanly.

### Critical: No call-site changes needed in ProgressPage

`_ProgressLockedBanner` from Story 17.2 already calls `ProUpsellSheet.show(context)` — this call site continues to work unchanged. The cooldown check is now inside `show()`.

### DI registration order for UpsellCooldownService

Per `project-context.md` DI order:
1. `AppDatabase` (singleton)
2. DAOs
3. Remote datasources
4. **Local datasources ← `UpsellCooldownService` fits here (SharedPreferences-backed)**
5. Repositories
6. Use cases
7. Blocs/Cubits

`SharedPreferences` is already registered as step ~1a (async singleton via `SettingsModule`) — `UpsellCooldownService` depends on it, so injectable will resolve it after the async singleton is ready.

### E9-K1 Fire-Check (Category B standing rule)

**(a) DI/lifecycle/cross-cutting patches [E6-P1 scope]:** **TRIGGERED.** Adds `UpsellCooldownService` to DI → `build_runner` required. No constructor change to existing blocs.

**(b) E16R-1 trigger check:** This story does NOT touch `AuthRepositoryImpl`. E16R-1 (restore round-trip + signOut-after-200 test hardening) remains open. It should be scheduled in Story 17.4 or as a standalone.

**(c) Cubit/BLoC collection-index pre-flight [E7-P2]:** **NOT triggered.** No collection-index state involved.

### Project Structure — New Files

```
lib/features/subscription/
  └── data/services/
      └── upsell_cooldown_service.dart         # NEW

test/features/subscription/
  └── upsell_cooldown_service_test.dart         # NEW
  └── upsell_cooldown_service_test.mocks.dart   # NEW (generated)

test/widget/subscription/
  └── pro_upsell_sheet_test.dart                # NEW (or updated)
  └── pro_upsell_sheet_test.mocks.dart          # NEW (generated)
```

### Project Structure — Modified Files

```
lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart  # +cooldown gating
lib/core/di/injection.config.dart                                       # GENERATED
```

### References

- Epic 17.3 ACs: `_bmad-output/planning-artifacts/epics.md` line 2312
- UX-DR25 (ProUpsellSheet, no lock badges, no nagging): `_bmad-output/planning-artifacts/epics.md` line 235
- UX-DR32 (VoiceOver/TalkBack semantics): `_bmad-output/planning-artifacts/epics.md` line 242
- NFR34 (cloud failure must not block free core): `_bmad-output/planning-artifacts/epics.md` (referenced throughout Epic 17)
- ProUpsellSheet stub (from Story 17.2): `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart`
- Story 17.2 Dev Notes §ProUpsellSheet Stub Design: `_bmad-output/implementation-artifacts/17-2-progress-history-free-pro-gating-with-grandfathering.md`
- `EntitlementGate` (`@singleton` pattern reference): `lib/core/cloud/entitlement_gate.dart`
- `SharedPreferences` DI registration: `lib/core/di/settings_module.dart`
- `ThemeCubit` (SharedPreferences usage pattern): `lib/features/settings/presentation/bloc/theme_cubit.dart`
- `AuthRepositoryImpl` (`@visibleForTesting` seam pattern): `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `injection.dart` getIt export: `lib/core/di/injection.dart`
- Project context (DI order, Bloc/Cubit rules, test structure): `_bmad-output/project-context.md`
- AC compliance rule (persistent_fact): every AC must be concrete, observable, and verifiable

### Review Findings

- [x] [Review][Patch] Dismissal alternativi (scrim-tap / swipe-down / back Android) non armano il cooldown — RISOLTO (whenComplete + result): `show()` ora apre `showModalBottomSheet<bool>` e registra `recordDismissal()` in `.then((intent) { if (intent != true) ... })`; `Scopri Pro` fa `pop(true)` (intent positivo, nessun cooldown), `non ora` fa `pop(false)`, scrim/swipe/back risolvono a `null` → cooldown armato. Campo `_cooldown` del widget rimosso (non più usato). Aggiunti widget test WIDGET-004 (Scopri Pro non registra) e WIDGET-005 (barrier dismiss registra). Era: — `showModalBottomSheet` usa i default `isDismissible: true` / `enableDrag: true`; solo il bottone `non ora` chiama `recordDismissal()`. Chi chiude il foglio con un gesto diverso da `non ora` rivede l'upsell al prossimo tap gated nello stesso giorno. Conforme ad AC2/AC3 come *letteralmente* scritte (definite solo sul path `non ora`), ma in tensione con l'intento della storia ("not again for the rest of the day") e UX-DR25 ("no repeated nagging"). Sollevato da tutti e tre i layer (blind+edge+auditor). Fix non univoco: vedi opzioni nel review. [`pro_upsell_sheet.dart` `show()` + handler `non ora`]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- `UpsellCooldownService` created as `@singleton` taking `SharedPreferences`; uses calendar-day string comparison (`yyyy-MM-dd`) for cooldown, no `Either`/`Failure` (best-effort UI preference).
- `ProUpsellSheet.show()` updated: resolves `UpsellCooldownService` via `cooldownOverride ?? getIt<>()`, returns early if cooling down, passes service to widget constructor.
- `non ora` button wires `_cooldown.recordDismissal()` before `Navigator.pop()`; `Scopri Pro` pops without recording (positive intent).
- `flutter/foundation.dart` import was redundant — `@visibleForTesting` is re-exported by `flutter/material.dart`; removed.
- `build_runner` generated `UpsellCooldownService` in `injection.config.dart` (line 295) and mock in `pro_upsell_sheet_test.mocks.dart`.
- 966/966 tests pass (+7 new); `flutter analyze` 0 issues.

### File List

lib/features/subscription/data/services/upsell_cooldown_service.dart (NEW)
lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart (MODIFIED)
lib/core/di/injection.config.dart (GENERATED)
test/features/subscription/upsell_cooldown_service_test.dart (NEW)
test/widget/subscription/pro_upsell_sheet_test.dart (NEW)
test/widget/subscription/pro_upsell_sheet_test.mocks.dart (GENERATED)
