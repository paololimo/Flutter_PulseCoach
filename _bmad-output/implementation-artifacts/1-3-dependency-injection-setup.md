# Story 1.3: Dependency Injection Setup

Status: done

## Story

As a developer,
I want `get_it` + `injectable` configured with code generation,
so that all features can register and resolve dependencies via annotations without manual `getIt.register` calls.

## Acceptance Criteria

1. **Given** the DI configuration exists at `lib/core/di/injection.dart`
   **When** `configureDependencies()` is called in `main.dart`
   **Then** all annotated `@injectable`, `@singleton`, and `@lazySingleton` classes are registered and resolvable without throwing

2. **Given** a new injectable class is annotated with `@injectable`
   **When** `dart run build_runner build --delete-conflicting-outputs` is run
   **Then** `injection.config.dart` is updated to include the new registration without manual intervention

3. **Given** the DI setup is complete
   **When** any repository implementation is annotated with `@Injectable(as: AbstractRepository)`
   **Then** resolving the abstract repository returns the concrete implementation

## Tasks / Subtasks

- [x] Task 1: Implement `lib/core/di/injection.dart` (AC: #1, #2)
  - [x] Replace the stub with the `@InjectableInit` pattern
  - [x] Export `getIt` as `final getIt = GetIt.instance;`
  - [x] Import `injection.config.dart` (to be generated)
  - [x] Keep `configureDependencies()` signature unchanged (`Future<void>`) — `main.dart` already calls it

- [x] Task 2: Run code generation (AC: #2)
  - [x] Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` directory
  - [x] Verify `lib/core/di/injection.config.dart` is generated without errors
  - [x] Commit `injection.config.dart` to git — generated files MUST be committed (Story 1.1 rule)

- [x] Task 3: Address deferred error handling from Story 1.1 review (AC: #1)
  - [x] Add error handling in `main.dart` around `configureDependencies()` (see Dev Notes)
  - [x] Ensure a black screen / unhandled crash does NOT occur if DI init fails

- [x] Task 4: Write DI initialization test (AC: #1)
  - [x] Create `test/core/di/injection_test.dart`
  - [x] Verify `configureDependencies()` completes without throwing

- [x] Task 5: Verify CI compatibility (AC: #1, #2)
  - [x] `flutter analyze` → 0 issues
  - [x] `flutter test` → existing `test/widget/app_test.dart` smoke test still passes

## Dev Notes

### Critical: `injection.dart` Implementation Pattern

Replace the current stub **exactly** as follows — do not change the function signature (main.dart depends on it):

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async => getIt.init();
```

**Why `@InjectableInit()` with default params:** `injectable_generator: ^2.6.2` generates `init()` as an extension on `GetIt`. Default settings are correct — no need to set `asExtension`, `preferRelativeImports`, or `initializerName` manually.

**`getIt` must be exported** — all features reference `getIt` for resolution. It must be accessible as `package:pulse_coach/core/di/injection.dart`'s top-level export.

### Critical: `injection.config.dart` is Generated — Commit It

After running build_runner, `lib/core/di/injection.config.dart` will be created. **Commit it.** This follows the established project rule from Story 1.1: generated files (`.g.dart`, `.freezed.dart`, `injection.config.dart`) are committed, never gitignored.

**Expected initial content** of the generated file (no registered services yet — that's correct):
```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    return this;
  }
}
```

> Note: hash codes in import aliases (`_i174`, `_i526`) may differ — that is normal and correct.

### Critical: Error Handling in `main.dart` (Deferred from Story 1.1 Review)

The `deferred-work.md` explicitly flags this for Story 1.3:

> "No error handling in `main()` around `configureDependencies()` — when Story 1.3 implements real DI registration, an unhandled throw will produce a black screen with no error feedback."

Update `main.dart`:

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/di/injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await configureDependencies();
  } catch (e, st) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
    // DI failure is fatal — runApp still called to show Flutter error widget
  }
  runApp(const PulseCoachApp());
}
```

**Why:** When real services are registered in Stories 1.4–1.7, any misconfigured registration will throw during `configureDependencies()`. Without a try/catch, the app silently shows a black screen with no debugging signal.

### Code Generation Command

Run from `pulse_coach/` directory (where `pubspec.yaml` lives):

```bash
dart run build_runner build --delete-conflicting-outputs
```

`--delete-conflicting-outputs` resolves any stale generated files from prior runs. Always use this flag.

**Watch mode** (for development only, not CI):
```bash
dart run build_runner watch --delete-conflicting-outputs
```

### DI Annotation Reference for Future Stories

| Annotation | Usage | When to Use |
|---|---|---|
| `@injectable` | `@injectable class MyService { ... }` | Regular classes; new instance per injection |
| `@singleton` | `@singleton class AppDatabase { ... }` | Single instance for app lifetime |
| `@lazySingleton` | `@lazySingleton class CacheManager { ... }` | Single instance, created on first use |
| `@Injectable(as: I)` | `@Injectable(as: SessionRepository)` on `SessionRepositoryImpl` | Bind abstract → concrete for interfaces |

**Registration order** (enforced by injectable, but important to know):
datasources → repositories → use cases → blocs

**Anti-pattern:** Never call `getIt.registerSingleton(...)` or `getIt.registerFactory(...)` manually. Always use annotations.

### File Locations

| File | Action |
|---|---|
| `pulse_coach/lib/core/di/injection.dart` | MODIFY — replace stub |
| `pulse_coach/lib/core/di/injection.config.dart` | GENERATE via build_runner, then COMMIT |
| `pulse_coach/lib/main.dart` | MODIFY — add error handling |
| `pulse_coach/test/core/di/injection_test.dart` | CREATE — new test |

**Do NOT touch any other files.** Stories 1.4+ register actual services.

### Testing Requirements

**New test file:** `test/core/di/injection_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';

void main() {
  tearDown(() async {
    // Reset GetIt between test runs to avoid state leakage
    await getIt.reset();
  });

  test('configureDependencies completes without throwing', () async {
    await expectLater(configureDependencies(), completes);
  });

  test('getIt container is ready after configureDependencies', () async {
    await configureDependencies();
    expect(getIt.isReady, isTrue);
  });
}
```

**Test mirroring rule (ARCH):** Test path mirrors `lib/` path → `lib/core/di/injection.dart` → `test/core/di/injection_test.dart`.

**Existing test must still pass:** `test/widget/app_test.dart` (1/1).

### Architecture Compliance Guardrails

| Rule | Source |
|---|---|
| No manual `getIt.register*()` calls — annotations only | ARCH (enforcement rule #5) |
| Use `package:pulse_coach/...` imports — no relative `../` | Story 1.1 rule |
| `injection.config.dart` committed to git — not gitignored | Story 1.1 + 1.2 rule |
| `get_it: ^8.0.3`, `injectable: ^2.5.0`, `injectable_generator: ^2.6.2` | Real pubspec.yaml |
| `flutter_lints` only — no `very_good_analysis` | Story 1.1 rule |
| `@singleton` for `AppDatabase` (Story 1.4 will use this pattern) | ARCH: DI patterns |
| Generated files use `freezed: ^3.2.5`, `freezed_annotation: ^3.1.0` | Story 1.2 resolved versions |

### Anti-Patterns to Avoid

| ❌ Do NOT | ✅ Do Instead |
|---|---|
| `getIt.registerSingleton(MyService())` | `@singleton class MyService` |
| `getIt.registerFactory<MyService>(() => MyService())` | `@injectable class MyService` |
| Modify `injection.config.dart` by hand | Let build_runner manage it |
| Gitignore `injection.config.dart` | Commit it |
| Add `@module` or environment configs yet | YAGNI — Story 1.3 is infrastructure only |
| Touch any other `.dart` files beyond injection.dart, main.dart | Stories 1.4–1.7 scope |
| Register real services in this story | No real services exist yet |

### Project Structure Notes

Only 3 files change in this story:
1. `lib/core/di/injection.dart` — stub → real implementation
2. `lib/core/di/injection.config.dart` — new, generated by build_runner
3. `lib/main.dart` — add error handling wrapper

All other Dart files are Story 1.4+ scope.

### References

- [Source: epics.md#Story 1.3 Acceptance Criteria] — User story and ACs
- [Source: architecture.md#Dependency Injection Pattern] — `@injectable`, `@singleton`, `@Injectable(as: ...)` code examples
- [Source: architecture.md#Enforcement Guidelines rule #5] — No manual get_it registration
- [Source: architecture.md#Anti-Patterns] — `Manual getIt.registerSingleton(...) → @singleton annotation on class`
- [Source: architecture.md#Complete Project Directory Structure] — `lib/core/di/injection.dart` + `injection.config.dart (Generated)`
- [Source: story 1-1#Dev Notes] — Generated files committed, `package:` imports only
- [Source: story 1-2#Dev Notes] — `get_it: ^8.0.3`, `injectable: ^2.5.0`, `injectable_generator: ^2.6.2` (actual resolved versions)
- [Source: deferred-work.md] — Error handling in `main()` deferred to Story 1.3
- [Source: architecture.md#Commands] — `dart run build_runner build --delete-conflicting-outputs`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `getIt.isReady` is a method (not property) in GetIt 8.x — replaced with `getIt.allReady()` (async Future) in test
- `getIt.allReadySync()` returns false due to internal injectable environment objects — `allReady()` resolves correctly
- `init()` extension generated synchronously (not async) in injectable_generator 2.6.2 — `async =>` wrapper in `configureDependencies()` handles this correctly; `flutter analyze` confirms 0 issues

### Completion Notes List

- Implemented `lib/core/di/injection.dart` with `@InjectableInit()` pattern, `getIt = GetIt.instance`, and import of generated config
- Ran `build_runner build --delete-conflicting-outputs`; generated `injection.config.dart` with empty `GetItInjectableX` extension (correct — no services registered yet)
- Added try/catch in `main.dart` around `configureDependencies()` to prevent black screen on DI failure
- Created `test/core/di/injection_test.dart` with 2 tests: completion check + allReady() check
- All 3 tests pass (2 DI + 1 smoke); `flutter analyze` → 0 issues

### File List

- `pulse_coach/lib/core/di/injection.dart` — modified (stub → @InjectableInit implementation)
- `pulse_coach/lib/core/di/injection.config.dart` — generated by build_runner, committed
- `pulse_coach/lib/main.dart` — modified (added try/catch around configureDependencies)
- `pulse_coach/test/core/di/injection_test.dart` — created (new DI initialization tests)

### Review Findings

- [x] [Review][Decision] DI failure swallowed — l'app prosegue con container rotto: in `main.dart`, il catch block riporta l'errore via `FlutterError.reportError` ma poi chiama `runApp(PulseCoachApp())` incondizionatamente. Se DI fallisce, l'app parte con container vuoto/parziale. Qualsiasi widget che risolve dipendenze via `getIt` lancerà un errore confuso "not registered", mascherando la causa reale. AC#4 chiede un messaggio diagnostico — non che l'app continui in stato rotto. [main.dart:7-12]

## Change Log

- 2026-03-28: Story 1.3 implemented — DI setup with get_it + injectable, code generation, error handling in main.dart, DI tests added
- 2026-03-28: Code review passed — fixed DI failure error handling to show dedicated error widget instead of running broken app
