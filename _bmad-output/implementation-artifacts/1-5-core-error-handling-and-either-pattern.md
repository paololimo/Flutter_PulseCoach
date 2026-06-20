# Story 1.5: Core Error Handling & Either Pattern

Status: review

## Story

As a developer,
I want the `Either<Failure, T>` error handling pattern and all Failure types defined,
so that repositories can return typed errors without throwing exceptions past the data layer.

## Acceptance Criteria

1. **Given** the abstract `Failure` class exists in `lib/core/error/`
   **When** a failure subclass is needed
   **Then** the following concrete types are available: `ServerFailure`, `CacheFailure`, `SensorFailure`, `LocationFailure`, each with a `message` field

2. **Given** a repository method wraps a remote datasource call
   **When** the datasource throws a `ServerException`
   **Then** the repository catches it and returns `Left(ServerFailure('...'))` — no exception propagates to the use case layer

3. **Given** a repository method wraps a cache read
   **When** the cache is empty or stale
   **Then** the repository returns `Left(CacheFailure('...'))` with a descriptive message

4. **Given** a Bloc handles a use case result
   **When** the use case returns `Left(Failure)`
   **Then** the Bloc emits an error state with the failure — it never throws or crashes

## Tasks / Subtasks

- [x] Task 1: Implement `lib/core/error/failures.dart` (AC: #1)
  - [x] Replace stub with full implementation: abstract `Failure` + 4 concrete subclasses
  - [x] Each subclass: `ServerFailure`, `CacheFailure`, `SensorFailure`, `LocationFailure` with `final String message` and `const` constructor

- [x] Task 2: Create `lib/core/error/exceptions.dart` (AC: #2, #3)
  - [x] Define `ServerException`, `CacheException`, `SensorException`, `LocationException` — each with `final String message` and `const` constructor
  - [x] Datasources throw these exceptions; repositories catch them

- [x] Task 3: Create `lib/core/utils/either_extensions.dart` (AC: #2, #3, #4)
  - [x] Define `EitherX<L, R>` extension on `Either<L, R>` with: `rightOrNull`, `leftOrNull` (note: dartz 0.10.1 already provides `isLeft()`/`isRight()` as methods)
  - [x] Import `package:dartz/dartz.dart`

- [x] Task 4: Write unit tests (AC: #1, #2, #3, #4)
  - [x] Create `test/core/error/failures_test.dart` — test all 4 failure constructors and `message` field
  - [x] Create `test/core/error/exceptions_test.dart` — test all 4 exception constructors
  - [x] Create `test/core/utils/either_extensions_test.dart` — test extension getters
  - [x] Verify existing 14 tests still pass: `flutter test`

- [x] Task 5: Verify CI compatibility
  - [x] `flutter analyze` → 0 issues
  - [x] `flutter test` → all tests pass (14 pre-existing + 14 new = 28 total)

## Dev Notes

### Critical: failures.dart — MODIFY Existing Stub

`lib/core/error/failures.dart` already exists as a stub with only a comment. **Replace the entire contents** — do not create a new file. The architecture specifies this exact structure:

```dart
// lib/core/error/failures.dart
abstract class Failure {
  const Failure();
}

class ServerFailure extends Failure {
  final String message;
  const ServerFailure(this.message);
}

class CacheFailure extends Failure {
  final String message;
  const CacheFailure(this.message);
}

class SensorFailure extends Failure {
  final String message;
  const SensorFailure(this.message);
}

class LocationFailure extends Failure {
  final String message;
  const LocationFailure(this.message);
}
```

**No `freezed` on Failure classes** — these are plain Dart classes, not freezed. The architecture code template shows plain `class` declarations without freezed annotations.

### Critical: exceptions.dart — CREATE New File

`lib/core/error/exceptions.dart` does NOT exist yet. The architecture mandates: "Remote datasource throws exceptions (`ServerException`, `CacheException`)". Create with matching exception types to the failures:

```dart
// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class SensorException implements Exception {
  final String message;
  const SensorException(this.message);
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
}
```

**Exception → Failure mapping (used in repositories):**
| Exception | Failure |
|---|---|
| `ServerException` | `ServerFailure` |
| `CacheException` | `CacheFailure` |
| `SensorException` | `SensorFailure` |
| `LocationException` | `LocationFailure` |

### Critical: either_extensions.dart — CREATE New File

`lib/core/utils/either_extensions.dart` does NOT exist yet. Architecture directory listing explicitly includes this file. Provide convenience getters so repositories and blocs don't need to call `.fold()` everywhere:

```dart
// lib/core/utils/either_extensions.dart
import 'package:dartz/dartz.dart';

extension EitherX<L, R> on Either<L, R> {
  bool get isLeft => fold((_) => true, (_) => false);
  bool get isRight => fold((_) => false, (_) => true);
  R? get rightOrNull => fold((_) => null, (r) => r);
  L? get leftOrNull => fold((l) => l, (_) => null);
}
```

### Critical: dartz 0.10.1 API

`dartz: ^0.10.1` is already in `pubspec.yaml`. **Do NOT add it again.** **Do NOT migrate to `fpdart`** — that is a deferred decision (see deferred-work.md).

**dartz Either usage in repositories:**
```dart
import 'package:dartz/dartz.dart';
import 'package:pulse_coach/core/error/exceptions.dart';
import 'package:pulse_coach/core/error/failures.dart';

// Correct repository pattern — AC #2 and #3
Future<Either<Failure, SomeEntity>> fetchData() async {
  try {
    final result = await remoteDatasource.fetchData();
    return Right(result);
  } on ServerException catch (e) {
    return Left(ServerFailure(e.message));
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  }
}
```

**Bloc pattern for AC #4:**
```dart
// In a Bloc event handler
final result = await useCase(params);
result.fold(
  (failure) => emit(state.copyWith(status: Status.error, failure: failure)),
  (data)    => emit(state.copyWith(status: Status.loaded, data: data)),
);
```

### Critical: File Naming — Do NOT Rename

`lib/core/utils/pulse_date_utils.dart` (the existing file) was named differently from what the architecture says (`date_utils.dart`). For `either_extensions.dart`, follow the architecture name exactly — do NOT rename to `pulse_either_extensions.dart`.

### Critical: Package Imports Only

Per project rule from Story 1.1 (enforced throughout): always use `package:pulse_coach/...` imports, never relative `../` imports.

```dart
// Correct
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/error/exceptions.dart';

// Wrong — NEVER do this
import '../../error/failures.dart';
```

### Testing Requirements

**New test files:**

**`test/core/error/failures_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';

void main() {
  group('Failure types', () {
    test('ServerFailure stores message', () {
      const f = ServerFailure('server error');
      expect(f.message, 'server error');
      expect(f, isA<Failure>());
    });

    test('CacheFailure stores message', () {
      const f = CacheFailure('cache miss');
      expect(f.message, 'cache miss');
      expect(f, isA<Failure>());
    });

    test('SensorFailure stores message', () {
      const f = SensorFailure('sensor unavailable');
      expect(f.message, 'sensor unavailable');
      expect(f, isA<Failure>());
    });

    test('LocationFailure stores message', () {
      const f = LocationFailure('permission denied');
      expect(f.message, 'permission denied');
      expect(f, isA<Failure>());
    });
  });
}
```

**`test/core/error/exceptions_test.dart`**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/exceptions.dart';

void main() {
  group('Exception types', () {
    test('ServerException stores message', () {
      const e = ServerException('500 Internal Server Error');
      expect(e.message, '500 Internal Server Error');
      expect(e, isA<Exception>());
    });

    test('CacheException stores message', () {
      const e = CacheException('cache empty');
      expect(e.message, 'cache empty');
    });

    test('SensorException stores message', () {
      const e = SensorException('accelerometer not available');
      expect(e.message, 'accelerometer not available');
    });

    test('LocationException stores message', () {
      const e = LocationException('location permission denied');
      expect(e.message, 'location permission denied');
    });
  });
}
```

**`test/core/utils/either_extensions_test.dart`**
```dart
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/utils/either_extensions.dart';

void main() {
  group('EitherX extensions', () {
    test('isRight true for Right', () {
      final e = Right<String, int>(42);
      expect(e.isRight, isTrue);
      expect(e.isLeft, isFalse);
    });

    test('isLeft true for Left', () {
      final e = Left<String, int>('error');
      expect(e.isLeft, isTrue);
      expect(e.isRight, isFalse);
    });

    test('rightOrNull returns value for Right', () {
      final e = Right<String, int>(42);
      expect(e.rightOrNull, 42);
    });

    test('rightOrNull returns null for Left', () {
      final e = Left<String, int>('error');
      expect(e.rightOrNull, isNull);
    });

    test('leftOrNull returns value for Left', () {
      final e = Left<String, int>('error');
      expect(e.leftOrNull, 'error');
    });

    test('leftOrNull returns null for Right', () {
      final e = Right<String, int>(42);
      expect(e.leftOrNull, isNull);
    });
  });
}
```

**Test mirror rule:** `lib/core/error/failures.dart` → `test/core/error/failures_test.dart`

**Pre-existing tests must still pass:** 14 tests (3 DI + 11 database).

### File Locations

| File | Action |
|---|---|
| `pulse_coach/lib/core/error/failures.dart` | MODIFY — replace stub with full Failure hierarchy |
| `pulse_coach/lib/core/error/exceptions.dart` | CREATE — Exception types for datasource layer |
| `pulse_coach/lib/core/utils/either_extensions.dart` | CREATE — EitherX extension on Either<L, R> |
| `pulse_coach/test/core/error/failures_test.dart` | CREATE |
| `pulse_coach/test/core/error/exceptions_test.dart` | CREATE |
| `pulse_coach/test/core/utils/either_extensions_test.dart` | CREATE |

**Do NOT touch:** `main.dart`, `injection.dart`, `injection.config.dart`, `app_database.dart`, any feature files. This story is infrastructure error handling only.

### Anti-Patterns to Avoid

| ❌ Do NOT | ✅ Do Instead |
|---|---|
| `throw Exception('...')` in repository | `return Left(ServerFailure('...'))` |
| `throw ServerException(...)` in repository | Repositories only catch exceptions; throw is for datasources only |
| Use `freezed` on Failure or Exception classes | Plain Dart classes with `const` constructors |
| Use `fpdart` instead of `dartz` | Use `dartz: ^0.10.1` — already in pubspec.yaml |
| Relative imports (`../error/failures.dart`) | `package:pulse_coach/core/error/failures.dart` |
| Re-export `dartz` types from core | Let each file import `package:dartz/dartz.dart` directly |
| Abstract `Failure` as a sealed class | Plain abstract class — no freezed, no sealed |
| `Failure` with `==` override | Not needed for v1 — pattern match by type in tests |

### Architecture Compliance

- **ARCH8:** `Either<Failure, T>` for all repository returns ✅ (defines the foundation)
- **ARCH9:** Graceful degradation — never throw exceptions past the data layer ✅
- Architecture enforcement rule #3: `Either<Failure, T>` for all repository return types — no raw exception throwing past the data layer ✅
- Error handling layer: `lib/core/error/failures.dart` + `lib/core/error/exceptions.dart` (architecture directory spec) ✅
- Utils layer: `lib/core/utils/either_extensions.dart` (architecture directory spec) ✅

### Previous Story Intelligence (Story 1.4)

- `flutter analyze` must report 0 issues — was passing after Story 1.4 ✅
- `package:` imports only — enforced since Story 1.1 ✅
- Generated files (`.g.dart`) are committed — not relevant here (no code generation in Story 1.5) ✅
- Test file path mirrors `lib/` path — `lib/core/error/` → `test/core/error/` ✅
- dartz note from Story 1.4 deferred work: "`dartz` package unmaintained since 2022 — `fpdart` is the community successor. Evaluate migration if Dart SDK compatibility issues arise" — **do NOT migrate in this story**; use dartz as-is

### Known Deferred Item (Do Not Address in This Story)

From deferred-work.md: "No error handling in `main()` around `configureDependencies()` — add try/catch with fallback error screen or `FlutterError.onError` hook." This story defines the error types, but wiring them to `main.dart` is out of scope for 1.5.

### References

- [Source: epics.md#Story 1.5] — User story statement and acceptance criteria
- [Source: architecture.md#Error Handling with Either] — Layer responsibility table, Failure type definitions
- [Source: architecture.md#Complete Project Directory Structure] — `lib/core/error/` and `lib/core/utils/either_extensions.dart`
- [Source: architecture.md#Enforcement Guidelines] — Rule #3: Either<Failure, T> for all repository returns
- [Source: architecture.md#Key Package Versions] — `dartz: latest on pub.dev` (^0.10.1 in pubspec)
- [Source: architecture.md#Anti-Patterns] — throw Exception → Left(ServerFailure)
- [Source: story 1-4#Known Dependency Notes] — dartz unmaintained; do not migrate to fpdart now
- [Source: deferred-work.md] — main.dart error handling deferred; dartz migration deferred

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- dartz 0.10.1 already defines `isLeft()` and `isRight()` as instance methods on `Either`. Extension getters with the same names are shadowed by class methods in Dart. Resolved by: (1) removing the shadowed getters from the extension, keeping only `rightOrNull`/`leftOrNull`; (2) updating tests to use `e.isLeft()`/`e.isRight()` (dartz native API).
- `prefer_const_constructors` lint on `Right<...>()`/`Left<...>()` in test — resolved by adding `const` prefix (dartz constructors support `const`).

### Completion Notes List

- Replaced `failures.dart` stub with full abstract `Failure` hierarchy + 4 concrete subclasses (`ServerFailure`, `CacheFailure`, `SensorFailure`, `LocationFailure`), each with `const` constructor and `final String message`.
- Created `exceptions.dart` with 4 exception types (`ServerException`, `CacheException`, `SensorException`, `LocationException`) implementing `Exception`, mirroring the Failure types for the datasource→repository boundary.
- Created `either_extensions.dart` with `EitherX<L, R>` extension providing `rightOrNull` and `leftOrNull` getters. Note: `isLeft()`/`isRight()` are already available from dartz 0.10.1 natively.
- Created 3 test files: 4 tests for failures, 4 tests for exceptions, 6 tests for either extensions (including 2 testing dartz native methods).
- All 28 tests pass; `flutter analyze` reports 0 issues.

### File List

- pulse_coach/lib/core/error/failures.dart (modified)
- pulse_coach/lib/core/error/exceptions.dart (created)
- pulse_coach/lib/core/utils/either_extensions.dart (created)
- pulse_coach/test/core/error/failures_test.dart (created)
- pulse_coach/test/core/error/exceptions_test.dart (created)
- pulse_coach/test/core/utils/either_extensions_test.dart (created)

### Review Findings

- [x] [Review][Decision→Patch] `Failure` base class has no `message` getter — added `String get message;` to abstract `Failure` + `@override` on subclasses [pulse_coach/lib/core/error/failures.dart]
- [x] [Review][Patch] Exception classes lack `toString()` override — added `toString()` to all 4 exception classes [pulse_coach/lib/core/error/exceptions.dart]
- [x] [Review][Patch] Inconsistent `isA<Exception>()` assertion — added `isA<Exception>()` to 3 missing test cases [pulse_coach/test/core/error/exceptions_test.dart]
- [x] [Review][Defer] Failure classes lack equality/hashCode — two instances with same message are not equal by value. Spec explicitly defers: "Not needed for v1". Consider `Equatable` when BLoC states depend on Failure comparison — deferred, pre-existing
- [x] [Review][Defer] `rightOrNull`/`leftOrNull` ambiguous when type param is nullable — `Right(null).rightOrNull` and `Left('err').rightOrNull` both return `null`. Document limitation or prefer `fold()` for nullable types — deferred, pre-existing

## Change Log

- 2026-03-28: Story 1.5 implemented — failures.dart stub replaced with full Failure hierarchy; exceptions.dart and either_extensions.dart created; 14 new tests added (28 total); flutter analyze 0 issues.
- 2026-03-28: Code review — 3 patches applied (Failure base message getter, Exception toString(), test consistency); 2 deferred; 4 dismissed. All 28 tests pass, flutter analyze 0 issues.

## Status

done
