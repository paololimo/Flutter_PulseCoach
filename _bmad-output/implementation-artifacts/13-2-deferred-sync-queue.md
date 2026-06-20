# Story 13.2: Deferred Sync Queue

Status: done

## Story

As the system,
I want a deferred sync queue that processes events when connectivity returns,
so that data that needs eventual syncing is never lost due to temporary connectivity issues.

## Acceptance Criteria

**AC1 — Sync event stored with correct initial state:**
Given a sync event is queued (e.g., completed session, RPE feedback) while offline
When it is written to the `sync_queue` table via `SyncManager.enqueue()`
Then it is stored with eventType, payload (JSON string), `createdAt` (the "queuedAt" semantics), and `retryCount = 0` (FR47)

**AC2 — Events processed oldest-first when connectivity returns:**
Given connectivity returns
When `SyncManager.processQueue()` runs
Then events are processed in `createdAt` order (oldest first) (NFR18); events whose `nextRetryAt` is still in the future are skipped

**AC3 — Failed events get exponential backoff:**
Given a sync event fails on first retry
When retry is scheduled
Then `retryCount` is incremented and `nextRetryAt` is set using exponential backoff: `minutes = 1 << retryCount` (→ 1, 2, 4, 8, … capped at 60 min) (NFR18)

**AC4 — Successful events are removed:**
Given a sync event succeeds
When processed
Then it is removed from the `sync_queue` table (deleted)

## Tasks / Subtasks

- [x] Task 1: Add `connectivity_plus` to pubspec and wire `Connectivity` into DI (AC1, AC2)
  - [x] 1.1 Add `connectivity_plus: ^6.1.0` (or latest stable) to `dependencies` in `pulse_coach/pubspec.yaml`. **Do not add twice** — check the file first. Note: `watch_connectivity` (already present at line 62) is for WearOS only and is NOT `connectivity_plus`.
  - [x] 1.2 In `pulse_coach/lib/core/di/network_module.dart`, add `@singleton Connectivity get connectivity => Connectivity();` import `package:connectivity_plus/connectivity_plus.dart`. This registers the singleton via the existing `@module` abstract class `NetworkModule`.
  - [x] 1.3 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to regenerate `injection.config.dart`.

- [x] Task 2: Implement `SyncManager` (AC1–AC4)
  - [x] 2.1 Create `pulse_coach/lib/core/sync/sync_manager.dart`. Annotate with `@singleton`. Constructor injection: `SyncQueueDao _dao, Connectivity _connectivity`.
  - [x] 2.2 Define `typedef SyncEventHandler = Future<Either<Failure, Unit>> Function(String payload)` at the top of the file (pure Dart typedef, no Flutter import).
  - [x] 2.3 Add `final Map<String, SyncEventHandler> _handlers = {}` and `void registerHandler(String eventType, SyncEventHandler handler)` public method.
  - [x] 2.4 Implement `Future<int> enqueue(String eventType, String payload)` — delegates to `_dao.insertEntry(SyncQueueCompanion.insert(eventType: eventType, payload: payload, createdAt: DateTime.now().toUtc()))`. The table already has `retryCount` defaulting to `0`.
  - [x] 2.5 Implement `Future<void> processQueue()`:
    - Get all entries: `await _dao.getPendingEntries()` (already FIFO by `createdAt`).
    - Filter due entries: `entries.where((e) => e.nextRetryAt == null || !e.nextRetryAt!.toUtc().isAfter(DateTime.now().toUtc()))`.
    - For each due entry: look up `_handlers[entry.eventType]`. If no handler: `AppLogger.warning('SyncManager: no handler for ${entry.eventType}', name: 'SyncManager')` and `continue` (do NOT delete — preserve for future handler registration).
    - If handler exists: await it, then fold: on failure → call `_scheduleRetry(entry)`, on success → `await _dao.deleteEntry(entry.id)`.
  - [x] 2.6 Implement private `Future<void> _scheduleRetry(SyncQueueEntry entry)`:
    - Compute `minutes = (1 << entry.retryCount).clamp(1, 60)`.
    - `nextRetryAt = DateTime.now().toUtc().add(Duration(minutes: minutes))`.
    - `await _dao.updateEntry(entry.copyWith(retryCount: entry.retryCount + 1, nextRetryAt: Value(nextRetryAt)))`.
    - Log: `AppLogger.warning('SyncManager: ${entry.eventType} failed, retry in ${minutes}m (attempt ${entry.retryCount + 1})', name: 'SyncManager')`.
  - [x] 2.7 Implement `Future<void> start()`:
    - Check initial connectivity: `final current = await _connectivity.checkConnectivity()`. If any result != `ConnectivityResult.none`, call `await processQueue()`.
    - Subscribe: `_sub = _connectivity.onConnectivityChanged.listen((results) { if (results.any((r) => r != ConnectivityResult.none)) processQueue(); })`.
  - [x] 2.8 Implement `void stop()` — cancels `_sub`.

- [x] Task 3: Wire SyncManager into app startup (AC2)
  - [x] 3.1 In `pulse_coach/lib/main.dart`, after `await configureDependencies()` and before `runApp(const PulseCoachApp())`, add `unawaited(getIt<SyncManager>().start())`. Import `dart:async` for `unawaited` and `package:pulse_coach/core/di/injection.dart` (already imported). Also import `package:pulse_coach/core/sync/sync_manager.dart`.
  - [x] 3.2 `unawaited` is used because start() runs a background subscription loop — blocking main() would delay the app launch.

- [x] Task 4: Write test suite (AC1–AC4) — new file `test/core/sync/sync_manager_test.dart`
  - [x] 4.1 `13.2-SYNC-001` (AC1): `enqueue()` stores entry with correct fields — use in-memory Drift DB, call `enqueue('session_completed', '{"id":1}')`, query via `getPendingEntries()`, assert `eventType`, `payload`, `retryCount == 0`, and `createdAt` is close to `DateTime.now().toUtc()`.
  - [x] 4.2 `13.2-SYNC-002` (AC2): `processQueue()` invokes handlers oldest-first — seed 3 entries with different `createdAt` timestamps, register a handler for each eventType that appends `eventType` to a list, call `processQueue()`, assert the list is in `createdAt` ascending order.
  - [x] 4.3 `13.2-SYNC-003` (AC2): `processQueue()` skips entries where `nextRetryAt` is in the future — seed entry with `nextRetryAt` = 30 min from now, call `processQueue()`, assert handler NOT called and entry still present in DB.
  - [x] 4.4 `13.2-SYNC-004` (AC3): failed handler triggers exponential backoff — seed entry with `retryCount = 0`, register failing handler, call `processQueue()`, assert entry updated with `retryCount == 1` and `nextRetryAt` is ~1 min in the future (within ±5s tolerance).
  - [x] 4.5 `13.2-SYNC-005` (AC3): retry delay caps at 60 min — seed entry with `retryCount = 6` (would give 64 min uncapped), call `_scheduleRetry` (or drive via failing handler), assert `nextRetryAt` is ≤61 min from now (i.e., capped at 60 min).
  - [x] 4.6 `13.2-SYNC-006` (AC4): successful handler deletes entry — seed entry, register succeeding handler, call `processQueue()`, assert `getPendingEntries()` is empty.
  - [x] 4.7 `13.2-SYNC-007`: unknown event type is skipped, NOT deleted — seed entry with `eventType = 'unknown_type'`, no handler registered, call `processQueue()`, assert entry still present in DB (zero-delete).
  - [x] 4.8 `13.2-SYNC-008` (AC2): `start()` calls `processQueue()` immediately when already connected — mock `Connectivity.checkConnectivity()` to return `[ConnectivityResult.wifi]`, seed one pending due entry with a succeeding handler; call `start()`, await briefly, assert entry deleted.
  - [x] 4.9 Use `@GenerateMocks([Connectivity])` for connectivity mocking. Use in-memory Drift `AppDatabase.forTesting(NativeDatabase.memory())` for all DAO tests. No `fake_async` needed — wall-clock assertions with ±10s tolerance are sufficient for backoff timing.
  - [x] 4.10 Name all test IDs `13.2-SYNC-001` through `13.2-SYNC-008`. Run `dart run build_runner build --delete-conflicting-outputs` to generate the mocks file.

- [x] Task 5: Verify
  - [x] 5.1 Run `flutter test` from `pulse_coach/`. Target: ≥ 787 existing + 8 new = ≥ 795 total. All existing tests must remain green.
  - [x] 5.2 Run `flutter analyze` from `pulse_coach/`. Must be 0 issues.
  - [x] 5.3 Confirm `pulse_coach/lib/core/di/injection.config.dart` has been regenerated and includes `SyncManager` singleton registration.

## Dev Notes

### What Is Already Implemented (Do Not Reinvent)

| Component | File | Status |
|---|---|---|
| `SyncQueue` DB table | `lib/core/database/tables/sync_queue_table.dart` | DONE — columns: `id`, `eventType`, `payload`, `retryCount` (default 0), `nextRetryAt` (nullable), `createdAt` |
| `SyncQueueDao` | `lib/core/database/daos/sync_queue_dao.dart` | DONE — `getPendingEntries()` (FIFO by `createdAt`), `insertEntry()`, `updateEntry()`, `deleteEntry(int id)` |
| `SyncQueue` wired into `AppDatabase` | `lib/core/database/app_database.dart` | DONE — already in tables list and daos list |
| Existing FIFO test | `test/core/database/daos/sync_queue_dao_test.dart` | DONE — test `1.4-UNIT-014` proves ordering + update + delete. Do NOT duplicate. |
| `AppLogger` | `lib/core/logging/app_logger.dart` | DONE — use `AppLogger.warning(name: 'SyncManager')` for skipped/retry logs, `AppLogger.error` only for unrecoverable failures |
| NetworkModule DI | `lib/core/di/network_module.dart` | NEEDS `Connectivity` added (Task 1.2) |

### `SyncQueue` Column Naming Note

The epics.md AC says `queuedAt` but the **actual column in `sync_queue_table.dart` is `createdAt`**. Do not add a new column — `createdAt` IS the queue timestamp. The `SyncQueueDao.getPendingEntries()` already orders by `createdAt ASC` (oldest first), satisfying NFR18.

### `copyWith` Pattern for Drift Entries

The generated `SyncQueueEntry` supports `copyWith` with `Value<T>` for nullable fields. Pattern verified in existing tests:

```dart
entry.copyWith(retryCount: 2, nextRetryAt: Value(retryAt))  // update
entry.copyWith(nextRetryAt: const Value(null))               // clear nullable
```

### Exponential Backoff Formula

```dart
Duration _backoffDelay(int currentRetryCount) {
  final minutes = (1 << currentRetryCount).clamp(1, 60);
  return Duration(minutes: minutes);
}
```

| `retryCount` (before increment) | Wait |
|---|---|
| 0 | 1 min |
| 1 | 2 min |
| 2 | 4 min |
| 3 | 8 min |
| 4 | 16 min |
| 5 | 32 min |
| 6+ | 60 min (capped) |

Call `_backoffDelay(entry.retryCount)` **before** incrementing — the current count determines the next wait.

### `connectivity_plus` API (v6.x)

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

// Check current state
final results = await Connectivity().checkConnectivity(); // List<ConnectivityResult>
final isOnline = results.any((r) => r != ConnectivityResult.none);

// Stream
Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
  if (results.any((r) => r != ConnectivityResult.none)) { /* online */ }
});
```

Use `List<ConnectivityResult>` — **not** a single `ConnectivityResult` (the v6 API changed from v4 which returned a single value). Do not use `ConnectivityResult.mobile/wifi/ethernet` directly — check `!= none`.

### DI Registration — NetworkModule Extension

Add to `lib/core/di/network_module.dart`:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

@singleton
Connectivity get connectivity => Connectivity();
```

The `Connectivity()` constructor is cheap — no async needed. After adding, run `build_runner` to regenerate `injection.config.dart`.

### SyncManager DI Registration

```dart
import 'package:injectable/injectable.dart';

@singleton
class SyncManager {
  SyncManager(this._dao, this._connectivity);
  // ...
}
```

Injectable will auto-wire `SyncQueueDao` and `Connectivity` from the container. The generated code in `injection.config.dart` will call `SyncManager(getIt<SyncQueueDao>(), getIt<Connectivity>())`.

### main.dart Wiring

Add after `await configureDependencies()` and before `runApp`:

```dart
import 'dart:async' show unawaited;
import 'package:pulse_coach/core/sync/sync_manager.dart';

// in main():
unawaited(getIt<SyncManager>().start());
runApp(const PulseCoachApp());
```

Do NOT `await start()` — it subscribes to a stream (infinite), so awaiting would block `runApp`. Use `unawaited` to fire-and-forget.

### Handler Registration (v1 MVP)

For Story 13.2, the `SyncManager` only needs the handler registry API. **No real backend exists** — the handlers map will be empty in the initial wiring, and the SyncManager will correctly skip unknown event types (log + continue). If time permits, register the `exercise_catalog_sync` handler pointing to `SyncExerciseCatalog` use case — that is purely optional in this story.

### Architecture Constraints

- `SyncManager` lives in `lib/core/sync/` — it is infrastructure, not a feature.
- Pure Dart only — no Flutter imports (`import 'package:flutter/...'` is forbidden). `connectivity_plus` is a Dart + platform package, not a Flutter widget — it is fine to import in `core/sync/`.
- No new Drift tables or columns — `sync_queue` is already defined and at schema version 8. Do NOT bump `schemaVersion`.
- No new freezed models — `SyncQueueEntry` is a generated Drift class, not a freezed class.
- The `SyncEventHandler` typedef returns `Either<Failure, Unit>` — consistent with all repository return types in this project.

### Project Structure Notes

New files:
- `pulse_coach/lib/core/sync/sync_manager.dart` — NEW singleton service
- `pulse_coach/test/core/sync/sync_manager_test.dart` — NEW test file (create `sync/` subdirectory)
- `pulse_coach/test/core/sync/sync_manager_test.mocks.dart` — generated by build_runner

Updated files:
- `pulse_coach/pubspec.yaml` — add `connectivity_plus`
- `pulse_coach/lib/core/di/network_module.dart` — add `Connectivity` singleton
- `pulse_coach/lib/core/di/injection.config.dart` — regenerated by build_runner
- `pulse_coach/lib/main.dart` — wire `SyncManager.start()`

No changes to:
- Any Drift table/DAO files
- Any existing feature Blocs/Cubits
- `app_database.dart` (no schema change)

### Previous Story Learnings (13.1)

- **`connectivity_plus` was explicitly deferred from Story 13.1**: the Story 13.1 dev notes stated "do not add `connectivity_plus` to `pubspec.yaml` in this story" — THIS is the story to add it.
- **`SyncManager` is NOT implemented in Story 13.1**: 13.1 explicitly does not implement `SyncManager`. Story 13.2 creates it from scratch.
- **In-memory DB pattern**: `AppDatabase.forTesting(NativeDatabase.memory())` for all DAO tests (same pattern as 13.1 offline tests and the existing `sync_queue_dao_test.dart`).
- **`@GenerateMocks` pattern**: `@GenerateMocks([SyncQueueDao, Connectivity])` — this is not needed for `SyncQueueDao` since we can use the real in-memory DB, but DO mock `Connectivity` to control the connectivity stream in tests.
- **Test ID format**: `13.2-SYNC-001` (epic.story-SUITE-NNN).
- **`AppLogger.warning` not `AppLogger.error`** for routine sync issues — reserve `error` level for unrecoverable failures consistent with the E10R-1 convention established in Story 13.1.

### References

- Story ACs: `_bmad-output/planning-artifacts/epics.md` §Epic 13, Story 13.2 (lines 1812–1834)
- Sync requirements: PRD FR47, NFR18
- Existing `SyncQueue` table: `pulse_coach/lib/core/database/tables/sync_queue_table.dart`
- Existing `SyncQueueDao`: `pulse_coach/lib/core/database/daos/sync_queue_dao.dart`
- Existing FIFO DAO test (DO NOT duplicate): `pulse_coach/test/core/database/daos/sync_queue_dao_test.dart`
- Network DI module to extend: `pulse_coach/lib/core/di/network_module.dart`
- DI injection entry: `pulse_coach/lib/core/di/injection.dart`
- App startup: `pulse_coach/lib/main.dart`
- AppLogger conventions: `pulse_coach/lib/core/logging/app_logger.dart`
- Story 13.1 (offline audit + E10R-1): `_bmad-output/implementation-artifacts/13-1-offline-first-core-features.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6 (create-story context engine, 2026-06-04)
GPT-5 Codex (implementation agent, 2026-06-04)

### Debug Log References

- `flutter pub get` — passed; resolved `connectivity_plus 6.1.5`.
- `dart run build_runner build --delete-conflicting-outputs` — passed; regenerated DI and Mockito mocks.
- `flutter test test/core/sync/sync_manager_test.dart` — passed, 8/8 targeted SyncManager tests.
- `flutter analyze` — passed, 0 issues.
- `flutter test` — passed, 796/796 tests.

### Completion Notes List

- Added `connectivity_plus` and registered a singleton `Connectivity` in `NetworkModule`.
- Implemented `SyncManager` with enqueue, handler registration, FIFO due-entry processing, future-retry skipping, exponential backoff capped at 60 minutes, successful deletion, and unknown-type preservation.
- Wired `SyncManager.start()` into app startup via `unawaited(...)` after dependency configuration.
- Added `SyncQueueDao` to DI module registration so `SyncManager` can be constructed by injectable.
- Added an 8-case SyncManager test suite covering AC1-AC4 and startup connectivity processing.
- Regenerated `injection.config.dart` and `sync_manager_test.mocks.dart`.

### File List

- `_bmad-output/implementation-artifacts/13-2-deferred-sync-queue.md`
- `_bmad-output/implementation-artifacts/sprint-status.yaml`
- `pulse_coach/lib/core/di/health_module.dart`
- `pulse_coach/lib/core/di/injection.config.dart`
- `pulse_coach/lib/core/di/network_module.dart`
- `pulse_coach/lib/core/sync/sync_manager.dart`
- `pulse_coach/lib/main.dart`
- `pulse_coach/pubspec.lock`
- `pulse_coach/pubspec.yaml`
- `pulse_coach/test/core/sync/sync_manager_test.dart`
- `pulse_coach/test/core/sync/sync_manager_test.mocks.dart`

### Change Log

- 2026-06-04: Implemented deferred sync queue manager, connectivity DI, startup processing, and full SyncManager test coverage.

## Review Findings

_Adversarial code review 2026-06-04 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). All 4 ACs verified FULLY SATISFIED by the Acceptance Auditor; findings below are robustness/concurrency hardening beyond the AC surface._

### Decision Needed — RESOLVED 2026-06-04

- [x] [Review][Decision→Patch P0] No max-retry / dead-letter policy — **Resolved (Paolo): cap retries at N=10.** When `retryCount` reaches 10, delete the entry + `AppLogger.error('SyncManager: dropping <eventType> after 10 failed attempts')`. No "mark failed" (schema bump forbidden). Tracked as patch P0 below.
- [x] [Review][Decision→Patch P7] `enqueue()` does not drain when online — **Resolved (Paolo): patch.** After insert, `enqueue()` checks `checkConnectivity()` and, if online, `unawaited(processQueue())` (reuses P1 re-entrancy guard). Tracked as patch P7 below.

### Patch (actionable, fix unambiguous)

- [x] [Review][Patch P0] Cap retries + dead-letter — in `_scheduleRetry` (or before it), if the post-increment `retryCount` would reach 10, delete the entry and `AppLogger.error`. [sync_manager.dart `processQueue`/`_scheduleRetry`] (resolved from Decision 1)
- [x] [Review][Patch P7] `enqueue()` drains when already online — after the insert, check `checkConnectivity()`; if online, `unawaited(processQueue())`. [sync_manager.dart `enqueue`] (resolved from Decision 2)
- [x] [Review][Patch P1] Re-entrancy guard on `processQueue()` — startup `processQueue()` and the `unawaited(processQueue())` connectivity callback can run concurrently with no in-flight flag; both read the same `getPendingEntries()` snapshot → handler invoked twice (double send) and double `_scheduleRetry` (double `retryCount` increment). Add a `bool _processing` early-return guard. [sync_manager.dart `processQueue`/`start`] (blind+edge, High)
- [x] [Review][Patch] Handler that throws is uncaught — `await handler(entry.payload)` is not wrapped; a throwing handler (vs returning `Left`) propagates out of the loop, aborts all remaining due entries that pass, and becomes an unhandled async error under `unawaited`. Wrap in try/catch and treat a throw as a failure → `_scheduleRetry`. [sync_manager.dart `processQueue`] (blind+edge, Medium-High)
- [x] [Review][Patch] Connectivity stream `onError` unhandled — `onConnectivityChanged.listen((results){...})` has no `onError`; a platform-channel error becomes an unhandled async error and may cancel the subscription, silently killing all future auto-sync. Add an `onError` that logs via `AppLogger.warning`. [sync_manager.dart `start`] (edge, Medium)
- [x] [Review][Patch] `start()` / `checkConnectivity()` throw kills auto-sync for the session — `start()` is not wrapped in try/catch; if `checkConnectivity()` throws, the subsequent `.listen` never runs and (under `unawaited` in main.dart) the error is swallowed → no auto-sync the whole session. Wrap the body so a probe failure still establishes the subscription. [sync_manager.dart `start`, main.dart] (edge, Medium)
- [x] [Review][Patch] Bit-shift overflow / negative `retryCount` in backoff — `(1 << entry.retryCount)` wraps negative at `retryCount >= 63` → `.clamp(1,60)` returns 1, collapsing backoff to the 1-min floor; a negative `retryCount` (corrupt row) throws. Clamp the exponent (e.g. `(1 << retryCount.clamp(0, 6))`) before the shift. [sync_manager.dart `_scheduleRetry`] (blind+edge, Low)
- [x] [Review][Patch] Redundant unused lifecycle aliases — `stop()`, `close()`, `dispose()` all funnel to the same teardown; only `stop()` is used (tearDown + `start()`). `close()`/`dispose()` are untested dead surface beyond the story scope (Simplicity-First). Collapse to a single `stop()`/`dispose()`. [sync_manager.dart] (auditor, Low)

### Deferred (real, not actionable now)

- [x] [Review][Defer] Handler-registration-vs-`start()` ordering race — `start()` runs in `main.dart` right after DI, before any feature calls `registerHandler`; startup-pending entries hit the no-handler path and sit un-retried until the next connectivity flap. Not actionable in v1: the MVP registers no handlers yet (per Dev Notes "handlers map will be empty in initial wiring"); zero-delete on unknown type is by design and tested (13.2-SYNC-007). [sync_manager.dart `processQueue`] — deferred, MVP has no handlers yet
- [x] [Review][Defer] Unbounded fetch / no `LIMIT` — `getPendingEntries()` selects the whole table and `processQueue` awaits every handler serially; a large offline backlog is drained in one pass. Scalability concern on the pre-existing DAO, not a regression of this change. [sync_queue_dao.dart `getPendingEntries`] — deferred, pre-existing DAO design
- [x] [Review][Defer] Sub-second precision / ordering ties — drift's default `DateTimeColumn` stores epoch seconds, so `createdAt` truncates and oldest-first ordering is non-deterministic for entries enqueued within the same second. Pre-existing schema behavior; the code's own `toUtc()` handling is correct. [sync_queue_table.dart] — deferred, pre-existing drift schema behavior
