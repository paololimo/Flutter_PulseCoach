---
baseline_commit: c44513f
---

# Story 19.1: RealtimeGateway and Supabase Broadcast/Presence Channel

Status: done

## Story

As a developer,
I want a `RealtimeGateway` that exposes a typed Dart stream of broadcast events and presence state,
So that `SharedSessionBloc` can subscribe without ever touching the Supabase channel directly.

## Context

This story delivers the transport infrastructure layer for Epic 19. It is purely a developer-facing plumbing story — no user-visible UI. It creates:

1. **Domain entities** `BroadcastEvent` (freezed union) and `PresenceState` (freezed value) in `lib/features/social/shared_session/domain/entities/`.
2. **`RealtimeGateway`** singleton in `lib/core/cloud/realtime_gateway.dart` that wraps the Supabase Realtime WebSocket channel and converts raw callbacks into typed Dart streams.
3. **`RealtimeFailure`** added to the existing `Failure` hierarchy.

Story 19.0 (profile row trigger) is **`done`** — the prerequisite is satisfied.

**E9-K1 fire-check for Story 19.1:** No screens are added (E18R-1 N/A); no social tab surface is modified (E18R-2 N/A); `ProUpsellSheet` not touched (E18R-4 N/A); week-bucketing not touched (E10R-2 N/A); no `Failure` surfaced to the user in UI (E18R-CB2 N/A). No fire-check items triggered.

**Category A snapshot entering sprint (Story 19.1): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Cap satisfied.

## Acceptance Criteria

**AC1 — Channel open and streams exposed:**
Given `RealtimeGateway` is implemented at `lib/core/cloud/realtime_gateway.dart`
When `RealtimeGateway.joinChannel(sessionId)` is called
Then a Supabase Realtime channel `shared-session:{sessionId}` is opened; the gateway exposes `Stream<BroadcastEvent> broadcastEvents` and `Stream<PresenceState> presenceUpdates` (ARCH21, ARCH27)

**AC2 — step_advanced broadcast maps to typed event:**
Given the gateway is connected to a channel
When the raw broadcast payload `{'step_index': int, 'elapsed_seconds': int}` is received for event `step_advanced`
Then `BroadcastEvent.stepAdvanced(stepIndex: int, elapsedSeconds: int)` is emitted on `broadcastEvents`; `SharedSessionBloc` receives it without accessing the Supabase channel directly

**AC3 — injectable singleton:**
Given `RealtimeGateway` is annotated `@singleton`
When `dart run build_runner build` is run
Then injectable code generation registers the gateway; all dependents inject `RealtimeGateway` via the constructor from `injection.config.dart`

**AC4 — clean teardown:**
Given the channel is open
When `RealtimeGateway.leaveChannel()` is called
Then `channel.unsubscribe()` + `client.removeChannel(channel)` are called; both `broadcastEvents` and `presenceUpdates` streams close (no dangling subscriptions, no further events emitted)

**AC5 — zero regressions:**
Given the new Dart files and build_runner run are added
When `flutter test` and `flutter analyze lib/ test/` are run from `pulse_coach/`
Then all existing tests pass plus new tests pass; analyzer reports 0 issues

## Tasks / Subtasks

- [x] **Task 1 — Domain entities: BroadcastEvent + PresenceState (AC1, AC2)**

  - [x] 1.1 Create `pulse_coach/lib/features/social/shared_session/domain/entities/broadcast_event.dart`:

    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';

    part 'broadcast_event.freezed.dart';

    @freezed
    sealed class BroadcastEvent with _$BroadcastEvent {
      const factory BroadcastEvent.stepAdvanced({
        required int stepIndex,
        required int elapsedSeconds,
      }) = StepAdvanced;
      const factory BroadcastEvent.sessionStarted() = SessionStarted;
      const factory BroadcastEvent.sessionEnded() = SessionEnded;
      const factory BroadcastEvent.unknown({required String rawEvent}) = UnknownBroadcast;
    }
    ```

    **Critical — sealed class:** Use `sealed class` (not `class`) so the compiler enforces exhaustive matching in `SharedSessionBloc` switch expressions. This requires `freezed` annotation `@freezed sealed class BroadcastEvent`.

    **Critical — `unknown` variant:** Always include an `unknown` fallback variant. Supabase may deliver unexpected event names (e.g., system pings). Without `unknown`, the mapping code would silently drop events or throw; with it, the bloc can safely ignore unknown events.

    **Critical — payload key names:** The Supabase broadcast payload uses `step_index` and `elapsed_seconds` (snake_case). The Dart model uses `stepIndex` and `elapsedSeconds` (camelCase). The mapping happens in `RealtimeGateway._parseBroadcast()`, not in the freezed class.

    **Do NOT add `@JsonSerializable`** to `BroadcastEvent` — it is NOT serialized to/from JSON by the app; it is parsed manually in `RealtimeGateway` from the raw callback map. Adding json_serializable here would generate `.g.dart` files that conflict with `.freezed.dart` and create confusion.

  - [x] 1.2 Create `pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.dart`:

    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';

    part 'presence_state.freezed.dart';

    @freezed
    abstract class PresenceState with _$PresenceState {
      const factory PresenceState({
        required List<ParticipantPresence> participants,
      }) = _PresenceState;
    }

    @freezed
    abstract class ParticipantPresence with _$ParticipantPresence {
      const factory ParticipantPresence({
        required String userId,
        String? displayHandle,
      }) = _ParticipantPresence;
    }
    ```

    **Critical — naming:** `PresenceState` is a project domain type. It does NOT conflict with `realtime_client`'s `SinglePresenceState` at import time because the domain entities live in `lib/features/.../domain/`, which never imports `realtime_client` or `supabase_flutter`. The `RealtimeGateway` (in `lib/core/cloud/`) imports both and is responsible for the conversion.

    **Critical — `userId` source:** The `userId` field maps to `p.payload['user_id']` from the tracked presence payload. See Task 2.2 for how `_emitPresenceState()` reads the channel's current presence state.

  - [x] 1.3 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`.
    Verify that `broadcast_event.freezed.dart` and `presence_state.freezed.dart` are generated in the same directories as the source files. Commit these generated files alongside their source.

- [x] **Task 2 — RealtimeGateway implementation (AC1, AC2, AC3, AC4)**

  - [x] 2.1 Create `pulse_coach/lib/core/cloud/realtime_gateway.dart`:

    ```dart
    import 'dart:async';

    import 'package:injectable/injectable.dart';
    import 'package:meta/meta.dart';
    import 'package:supabase_flutter/supabase_flutter.dart';

    import 'package:pulse_coach/core/cloud/supabase_client.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

    @singleton
    class RealtimeGateway {
      final SupabaseClientProvider _clientProvider;

      RealtimeChannel? _channel;
      StreamController<BroadcastEvent>? _broadcastController;
      StreamController<PresenceState>? _presenceController;

      RealtimeGateway(this._clientProvider);

      Stream<BroadcastEvent> get broadcastEvents =>
          _broadcastController?.stream ?? const Stream.empty();

      Stream<PresenceState> get presenceUpdates =>
          _presenceController?.stream ?? const Stream.empty();

      Future<void> joinChannel(String sessionId) async {
        _broadcastController = StreamController<BroadcastEvent>.broadcast();
        _presenceController = StreamController<PresenceState>.broadcast();

        _channel = _clientProvider.client
            .channel('shared-session:$sessionId')
            .onBroadcast(
              event: 'step_advanced',
              callback: (payload) {
                final event = _parseBroadcast('step_advanced', payload);
                if (event != null) _broadcastController?.add(event);
              },
            )
            .onBroadcast(
              event: 'session_started',
              callback: (_) => _broadcastController
                  ?.add(const BroadcastEvent.sessionStarted()),
            )
            .onBroadcast(
              event: 'session_ended',
              callback: (_) =>
                  _broadcastController?.add(const BroadcastEvent.sessionEnded()),
            )
            .onPresenceSync((_) => _emitPresenceState())
            .onPresenceJoin((_) => _emitPresenceState())
            .onPresenceLeave((_) => _emitPresenceState());

        _channel!.subscribe();
      }

      Future<void> leaveChannel() async {
        await _channel?.unsubscribe();
        final ch = _channel;
        if (ch != null) {
          await _clientProvider.client.removeChannel(ch);
        }
        await _broadcastController?.close();
        await _presenceController?.close();
        _channel = null;
        _broadcastController = null;
        _presenceController = null;
      }

      Future<void> sendBroadcast({
        required String event,
        required Map<String, dynamic> payload,
      }) async {
        await _channel?.sendBroadcastMessage(event: event, payload: payload);
      }

      Future<void> trackPresence({
        required String userId,
        String? displayHandle,
      }) async {
        await _channel?.track({
          'user_id': userId,
          'display_handle': displayHandle,
        });
      }

      Future<void> untrackPresence() async {
        await _channel?.untrack();
      }

      void _emitPresenceState() {
        final rawState = _channel?.presenceState() ?? [];
        final participants = rawState
            .expand((s) => s.presences)
            .map((p) => ParticipantPresence(
                  userId: p.payload['user_id'] as String? ?? '',
                  displayHandle: p.payload['display_handle'] as String?,
                ))
            .toList();
        _presenceController?.add(PresenceState(participants: participants));
      }

      @visibleForTesting
      static BroadcastEvent? parseBroadcast(
          String event, Map<String, dynamic> payload) {
        switch (event) {
          case 'step_advanced':
            final stepIndex = payload['step_index'];
            final elapsedSeconds = payload['elapsed_seconds'];
            if (stepIndex is int && elapsedSeconds is int) {
              return BroadcastEvent.stepAdvanced(
                stepIndex: stepIndex,
                elapsedSeconds: elapsedSeconds,
              );
            }
            return null;
          case 'session_started':
            return const BroadcastEvent.sessionStarted();
          case 'session_ended':
            return const BroadcastEvent.sessionEnded();
          default:
            return BroadcastEvent.unknown(rawEvent: event);
        }
      }

      BroadcastEvent? _parseBroadcast(
              String event, Map<String, dynamic> payload) =>
          parseBroadcast(event, payload);
    }
    ```

    **Critical — ARCH25 boundary:** `RealtimeGateway` is in `lib/core/cloud/` — one of the two permitted locations that may `import 'package:supabase_flutter/supabase_flutter.dart'` directly. Do NOT import supabase_flutter anywhere else. The domain entities (`BroadcastEvent`, `PresenceState`) are pure Dart with zero Flutter/Supabase imports.

    **Critical — channel naming:** `'shared-session:$sessionId'` — kebab-case namespace + colon + sessionId (architecture convention: `{kebab-namespace}:{uuid}`). This exact format must be used; Story 19.2 relies on it for host/follower channel membership.

    **Critical — broadcast event naming:** `'step_advanced'`, `'session_started'`, `'session_ended'` — snake_case `{noun}_{pastVerb}` per architecture convention. Do NOT use camelCase on the wire.

    **Critical — `.subscribe()` return value:** `RealtimeChannel.subscribe()` is synchronous and returns `RealtimeChannel` (the same channel, for chaining). It does NOT return a Future — calling `await` on it is wrong. Use `_channel!.subscribe()` without `await`.

    **Critical — `.unsubscribe()` IS async:** `RealtimeChannel.unsubscribe()` returns `Future<String>`. Always `await` it in `leaveChannel()` before closing the stream controllers.

    **Critical — `removeChannel`:** After `unsubscribe()`, call `await _clientProvider.client.removeChannel(ch)` to clean up the socket-level registration. Without this, re-joining the same channel (e.g., after a drop-out) will throw "tried to subscribe multiple times".

    **Critical — `broadcast()` stream controllers:** Use `StreamController<T>.broadcast()` (not the default single-subscription). `SharedSessionBloc` and future `InSessionView` widgets may both listen; a single-subscription controller would throw on the second listener.

    **Critical — `@visibleForTesting` on `parseBroadcast`:** Exposing this static method as `@visibleForTesting` allows unit tests to verify the parsing logic without mocking the Supabase channel. The private `_parseBroadcast` instance method delegates to the static one. Do NOT make `parseBroadcast` public (it would leak internal implementation details).

    **Critical — `presenceState()` shape:** `channel.presenceState()` returns `List<SinglePresenceState>` from `realtime_client`. Each `SinglePresenceState` has `key: String` and `presences: List<Presence>`. Each `Presence` has `payload: Map<String, dynamic>` containing the map passed to `track()`. This story uses `payload['user_id']` and `payload['display_handle']` — these keys must match exactly what Story 19.2 passes to `trackPresence()`.

    **Critical — `const Stream.empty()` guard:** If `broadcastEvents` or `presenceUpdates` is accessed before `joinChannel()` is called (or after `leaveChannel()` closes the controllers), the guard `_broadcastController?.stream ?? const Stream.empty()` returns an immediately-completing empty stream instead of throwing a null dereference.

  - [x] 2.2 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` to update `injection.config.dart` with the new `@singleton RealtimeGateway` registration.

    Verify `injection.config.dart` contains a `gh.registerSingleton<RealtimeGateway>(RealtimeGateway(gh<SupabaseClientProvider>()))` (or the equivalent `lazy_singleton`/`factory` pattern) entry. If it does not appear, ensure the `@module` or `@InjectableInit` scan includes `lib/core/cloud/`.

- [x] **Task 3 — RealtimeFailure (AC1)**

  - [x] 3.1 Add to `pulse_coach/lib/core/error/failures.dart` (after `SocialHandleTakenFailure`, before the end of the file):

    ```dart
    class RealtimeFailure extends Failure {
      @override
      final String message;
      const RealtimeFailure(this.message);
    }
    ```

    **Critical — structural equality:** `RealtimeFailure` inherits the `operator==` + `hashCode` from `Failure` base class (`Object.hash(runtimeType, message)`). No additional equality implementation needed. Do NOT add `@freezed` to `Failure` subclasses — they use the hand-written structural equality defined in `Failure`.

    **Scope note:** `RealtimeFailure` is defined here because Story 19.2 (`SharedSessionBloc`) will return `Either<RealtimeFailure, ...>` from use cases. Story 19.1 does not use it in runtime code, but defining it now avoids a mid-flight file change in Story 19.2.

- [x] **Task 4 — Tests (AC2, AC5)**

  - [x] 4.1 Create `pulse_coach/test/core/cloud/realtime_gateway_test.dart`:

    ```dart
    // [19.1-GW-001..007] RealtimeGateway.parseBroadcast unit tests
    import 'package:flutter_test/flutter_test.dart';
    import 'package:pulse_coach/core/cloud/realtime_gateway.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';

    void main() {
      group('RealtimeGateway.parseBroadcast (19.1)', () {
        test('19.1-GW-001: step_advanced with valid ints → StepAdvanced', () {
          final result = RealtimeGateway.parseBroadcast(
            'step_advanced',
            {'step_index': 3, 'elapsed_seconds': 45},
          );
          expect(result,
              const BroadcastEvent.stepAdvanced(stepIndex: 3, elapsedSeconds: 45));
        });

        test('19.1-GW-002: step_advanced with missing keys → null (malformed, drop)', () {
          final result = RealtimeGateway.parseBroadcast(
            'step_advanced',
            {'step_index': 3}, // elapsed_seconds missing
          );
          expect(result, isNull);
        });

        test('19.1-GW-003: session_started → SessionStarted', () {
          final result = RealtimeGateway.parseBroadcast('session_started', {});
          expect(result, const BroadcastEvent.sessionStarted());
        });

        test('19.1-GW-004: session_ended → SessionEnded', () {
          final result = RealtimeGateway.parseBroadcast('session_ended', {});
          expect(result, const BroadcastEvent.sessionEnded());
        });

        test('19.1-GW-005: unknown event → UnknownBroadcast', () {
          final result = RealtimeGateway.parseBroadcast('ping', {});
          expect(result, const BroadcastEvent.unknown(rawEvent: 'ping'));
        });

        test('19.1-GW-006: step_advanced with wrong payload type → null', () {
          final result = RealtimeGateway.parseBroadcast(
            'step_advanced',
            {'step_index': '3', 'elapsed_seconds': '45'}, // strings, not ints
          );
          expect(result, isNull);
        });

        test('19.1-GW-007: step_advanced with step_index 0 → valid (first step)', () {
          final result = RealtimeGateway.parseBroadcast(
            'step_advanced',
            {'step_index': 0, 'elapsed_seconds': 0},
          );
          expect(result,
              const BroadcastEvent.stepAdvanced(stepIndex: 0, elapsedSeconds: 0));
        });
      });
    }
    ```

    **Why parse-only tests for the gateway:** `RealtimeGateway` wraps callback-based Supabase APIs. The callback registration and channel subscription require a real or mock `SupabaseClient` + `RealtimeChannel`. Since `RealtimeChannel` is a concrete class that requires a live WebSocket connection to behave meaningfully, the mock-based test would only verify call delegation (not behavior). The `@visibleForTesting parseBroadcast` static method captures the only meaningful pure logic. The full stream integration is tested in Story 19.2 via `SharedSessionBloc` tests which mock `RealtimeGateway` at the bloc boundary.

  - [x] 4.2 Create `pulse_coach/test/domain/social/shared_session/broadcast_event_test.dart`:

    ```dart
    // [19.1-DOMAIN-001..004] BroadcastEvent and PresenceState pure Dart tests
    import 'package:flutter_test/flutter_test.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/broadcast_event.dart';
    import 'package:pulse_coach/features/social/shared_session/domain/entities/presence_state.dart';

    void main() {
      group('BroadcastEvent (19.1)', () {
        test('19.1-DOMAIN-001: stepAdvanced equality', () {
          const a = BroadcastEvent.stepAdvanced(stepIndex: 2, elapsedSeconds: 30);
          const b = BroadcastEvent.stepAdvanced(stepIndex: 2, elapsedSeconds: 30);
          expect(a, b);
        });

        test('19.1-DOMAIN-002: different events are not equal', () {
          const a = BroadcastEvent.stepAdvanced(stepIndex: 1, elapsedSeconds: 10);
          const b = BroadcastEvent.sessionStarted();
          expect(a, isNot(b));
        });

        test('19.1-DOMAIN-003: sealed match covers all variants', () {
          const events = [
            BroadcastEvent.stepAdvanced(stepIndex: 0, elapsedSeconds: 0),
            BroadcastEvent.sessionStarted(),
            BroadcastEvent.sessionEnded(),
            BroadcastEvent.unknown(rawEvent: 'x'),
          ];
          for (final e in events) {
            // Exhaustive switch — compiler will error if a variant is missing
            final label = switch (e) {
              StepAdvanced() => 'step',
              SessionStarted() => 'start',
              SessionEnded() => 'end',
              UnknownBroadcast() => 'unknown',
            };
            expect(label, isA<String>());
          }
        });
      });

      group('PresenceState (19.1)', () {
        test('19.1-DOMAIN-004: empty participants list', () {
          const s = PresenceState(participants: []);
          expect(s.participants, isEmpty);
        });

        test('19.1-DOMAIN-005: participants equality', () {
          const a = PresenceState(participants: [
            ParticipantPresence(userId: 'u1', displayHandle: 'alice'),
          ]);
          const b = PresenceState(participants: [
            ParticipantPresence(userId: 'u1', displayHandle: 'alice'),
          ]);
          expect(a, b);
        });
      });
    }
    ```

  - [x] 4.3 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/` (required only if Task 4 introduced new `@GenerateMocks` — these tests use no mocks, so this step only applies if Task 2.2's build_runner is not already done).

  - [x] 4.4 Run `flutter test` from `pulse_coach/` — all existing tests plus new 12 tests (7 gateway + 5 domain) green.

  - [x] 4.5 Run `flutter analyze lib/ test/` from `pulse_coach/` — 0 issues.

## Dev Notes

### ARCH25 — supabase_flutter import boundary

`lib/core/cloud/realtime_gateway.dart` is one of exactly TWO permitted files to import `package:supabase_flutter/supabase_flutter.dart`:
1. `lib/core/cloud/supabase_client.dart` (singleton provider)
2. `lib/core/cloud/realtime_gateway.dart` (this story)
3. `lib/main.dart` (one-time `Supabase.initialize()`)

Domain entities (`BroadcastEvent`, `PresenceState`) are pure Dart — zero Flutter or Supabase imports. `SharedSessionBloc` (Story 19.2) imports the domain entities and `RealtimeGateway`, but never imports `supabase_flutter` directly.

### supabase_flutter 2.x Realtime API (realtime_client 2.8.0)

The project pins `supabase_flutter: ^2.9.0` (resolved ≥ 2.9.0 in lockfile). The `RealtimeChannel` type and its methods are stable across 2.x:

| Method | Type | Note |
|---|---|---|
| `client.channel(name)` | sync → `RealtimeChannel` | creates channel, does NOT subscribe |
| `.onBroadcast(event:, callback:)` | sync → `RealtimeChannel` (chainable) | registers callback |
| `.onPresenceSync(callback)` | sync → `RealtimeChannel` (chainable) | registers callback |
| `.onPresenceJoin(callback)` | sync → `RealtimeChannel` (chainable) | registers callback |
| `.onPresenceLeave(callback)` | sync → `RealtimeChannel` (chainable) | registers callback |
| `.subscribe()` | sync → `RealtimeChannel` | opens WebSocket; do NOT await |
| `.unsubscribe()` | async → `Future<String>` | always await |
| `client.removeChannel(ch)` | async → `Future<String>` | cleans socket entry; always await |
| `.sendBroadcastMessage(event:, payload:)` | async → `Future<ChannelResponse>` | send outbound broadcast |
| `.track(payload)` | async → `Future<ChannelResponse>` | update own presence |
| `.untrack()` | async → `Future<ChannelResponse>` | remove own presence |
| `.presenceState()` | sync → `List<SinglePresenceState>` | snapshot of all tracked presences |

`presenceState()` returns the *current* in-memory snapshot; it must be called from within the presence callbacks (`_emitPresenceState()`) which fire after the gateway's internal presence map is updated. Calling it outside a callback gives stale or empty results.

### Broadcast payload schema (Story 19.2 contract)

Story 19.2 will call `RealtimeGateway.sendBroadcast` with these exact payloads:

| Event | Payload keys | Dart types |
|---|---|---|
| `step_advanced` | `step_index`, `elapsed_seconds` | `int`, `int` |
| `session_started` | _(empty map)_ | — |
| `session_ended` | _(empty map)_ | — |

`parseBroadcast` defensively null-checks both `step_index` and `elapsed_seconds` and returns `null` for malformed payloads. The broadcast stream never emits `null` — a null result from `_parseBroadcast` is silently dropped. This prevents the stream from crashing on an unexpected server-side broadcast format change.

### Presence payload schema (Story 19.2 contract)

Story 19.2 will call `RealtimeGateway.trackPresence(userId: ..., displayHandle: ...)`. The gateway passes `{'user_id': userId, 'display_handle': displayHandle}` to `channel.track()`. These exact keys are what `_emitPresenceState()` reads back from `Presence.payload`. Any change to these keys in Story 19.2 must be reflected in `_emitPresenceState()`.

### DI registration — `@singleton` lifetime

`RealtimeGateway` is `@singleton` (created once for the app lifetime). This is intentional because there is at most one active realtime channel session at a time and the stream controllers must be stable references across the widget tree. If Story 19.2+ ever needs to support simultaneous channels, a refactor to `@lazySingleton` or a factory pattern would be required — but do NOT make that change preemptively.

### SharedSessionBloc testability (Story 19.2 pre-flight)

`SharedSessionBloc` (Story 19.2) will depend on `RealtimeGateway`. To mock it in bloc tests, use `@GenerateNiceMocks([MockSpec<RealtimeGateway>()])` in `shared_session_bloc_test.dart`. `RealtimeGateway` is a concrete class (no interface needed) — Mockito's `@GenerateNiceMocks` generates a mock that stubs all methods. When mocking:
- `when(mockGateway.broadcastEvents).thenAnswer((_) => broadcastSubject.stream)`
- `when(mockGateway.presenceUpdates).thenAnswer((_) => presenceSubject.stream)`

This pre-flight note is for the Story 19.2 dev agent — no action required in this story.

### Directory structure created by this story

This story creates the `shared_session/` feature subtree from scratch. The full path that must exist after Task 1:

```
pulse_coach/lib/features/social/shared_session/
  domain/
    entities/
      broadcast_event.dart          # NEW
      broadcast_event.freezed.dart  # GENERATED
      presence_state.dart           # NEW
      presence_state.freezed.dart   # GENERATED
```

The `data/` and `presentation/` subdirectories are NOT created in this story. Do NOT create placeholder files, empty classes, or stub implementations for Story 19.2+ artifacts — the next story will create them.

### No Supabase migration in this story

The Realtime channel `shared-session:{sessionId}` is a pure in-memory/WebSocket channel. No DB row, no migration, no `supabase/migrations/` file is needed for this story. The `shared_sessions` table (for join code persistence) is created in Story 20.1.

### Category A fire-check (Story 19.1 entry)

**Category A snapshot: 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. No new Category A items open in this story. Sprint gate satisfied.

### Project Structure — Files NEW/MODIFIED

```
pulse_coach/
  lib/core/cloud/
    realtime_gateway.dart                                              # NEW (@singleton)

  lib/core/error/
    failures.dart                                                      # MODIFIED (+RealtimeFailure)

  lib/features/social/shared_session/domain/entities/
    broadcast_event.dart                                               # NEW (freezed sealed union)
    broadcast_event.freezed.dart                                       # GENERATED
    presence_state.dart                                                # NEW (freezed value)
    presence_state.freezed.dart                                        # GENERATED

  lib/injection.config.dart                                           # REGENERATED (build_runner)

  test/core/cloud/
    realtime_gateway_test.dart                                         # NEW (7 parse tests)

  test/domain/social/shared_session/
    broadcast_event_test.dart                                          # NEW (5 domain tests)

_bmad-output/implementation-artifacts/
  sprint-status.yaml                                                   # MODIFIED (19-1 → ready-for-dev)
```

No new use cases, repositories, or Blocs in this story. `SharedSessionBloc` is Story 19.2.

### References

- Epic 19 ACs (epics.md line ~2530): `_bmad-output/planning-artifacts/epics.md`
- Architecture — realtime pattern (line ~785): `_bmad-output/planning-artifacts/architecture.md`
- Architecture — channel naming convention (line ~743): `_bmad-output/planning-artifacts/architecture.md`
- Architecture — v2 directory structure (line ~1295): `_bmad-output/planning-artifacts/architecture.md`
- ARCH25 boundary comment: `pulse_coach/lib/core/cloud/supabase_client.dart:1`
- Existing Failure hierarchy: `pulse_coach/lib/core/error/failures.dart`
- Story 19.0 (done, prerequisite): `_bmad-output/implementation-artifacts/19-0-profile-row-creation-on-signup.md`
- `realtime_client` 2.8.0 `RealtimeChannel` API: `~/.pub-cache/hosted/pub.dev/realtime_client-2.8.0/lib/src/realtime_channel.dart`
- `realtime_client` 2.8.0 `RealtimePresence` / `SinglePresenceState`: `~/.pub-cache/hosted/pub.dev/realtime_client-2.8.0/lib/src/realtime_presence.dart`, `types.dart`
- Action-item ledger (E9-K1 fire-check + Category A): `_bmad-output/implementation-artifacts/action-item-ledger.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Completion Notes List

- Task 1: Created `BroadcastEvent` (freezed sealed union with 4 variants: stepAdvanced, sessionStarted, sessionEnded, unknown) and `PresenceState`+`ParticipantPresence` (freezed value objects). Build_runner generated `.freezed.dart` for both. No `@JsonSerializable` added per story spec.
- Task 2: Created `RealtimeGateway` singleton in `lib/core/cloud/` — broadcast event registration via chained `.onBroadcast()`, presence sync/join/leave via `_emitPresenceState()`, `parseBroadcast` exposed as `@visibleForTesting` static. `package:meta` replaced with `package:flutter/foundation.dart` (meta not a direct dependency). `inject.config.dart` updated automatically by build_runner: `gh.singleton<RealtimeGateway>(RealtimeGateway(gh<SupabaseClientProvider>()))`.
- Task 3: `RealtimeFailure` added to `failures.dart` after `SocialHandleTakenFailure`. Inherits structural equality from `Failure` base — no extra equality needed.
- Task 4: 12 new tests (7 gateway parse + 5 domain entity). ATDD followed: test files written and confirmed failing (compilation errors) before source files created. Full suite: 1106 tests passed, 0 failures. `flutter analyze lib/ test/` = 0 issues.

### File List

- `pulse_coach/lib/features/social/shared_session/domain/entities/broadcast_event.dart` — NEW
- `pulse_coach/lib/features/social/shared_session/domain/entities/broadcast_event.freezed.dart` — GENERATED
- `pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.dart` — NEW
- `pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.freezed.dart` — GENERATED
- `pulse_coach/lib/core/cloud/realtime_gateway.dart` — NEW
- `pulse_coach/lib/core/error/failures.dart` — MODIFIED (+RealtimeFailure)
- `pulse_coach/lib/core/di/injection.config.dart` — REGENERATED (build_runner)
- `pulse_coach/test/core/cloud/realtime_gateway_test.dart` — NEW (7 parse tests)
- `pulse_coach/test/domain/social/shared_session/broadcast_event_test.dart` — NEW (5 domain tests)
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — MODIFIED (19-1 → review)

### Review Findings

_Code review 2026-06-25 (adversarial: Blind Hunter + Edge Case Hunter + Acceptance Auditor, Opus). All 5 ACs verified satisfied (analyze clean, 12/12 new tests green). Findings below are latent-defect / scope-boundary items._

- [x] [Review][Patch] `parseBroadcast` accept `num` (int or double) and coerce with `.toInt()` instead of strict `is int` — interop hardening so float-encoded payloads aren't dropped; added GW-008 double-case test [realtime_gateway.dart:113]
- [x] [Review][Patch] `sendBroadcast` / `trackPresence` / `untrackPresence` throw `StateError` when `_channel == null` instead of silent no-op — fail-fast contract [realtime_gateway.dart:73]
- [x] [Review][Patch] `joinChannel` re-entry guard added — a second call now awaits `leaveChannel()` first, preventing channel/controller leak [realtime_gateway.dart:30]
- [x] [Review][Patch] `_emitPresenceState` now uses defensive `is String` checks instead of `as String?` cast — no longer throws on non-String presence payloads [realtime_gateway.dart:94]
- [x] [Review][Patch] `leaveChannel` now detaches refs first + `try/finally` guarantees controllers close even if `unsubscribe()`/`removeChannel()` throws [realtime_gateway.dart:60]
- [x] [Review][Patch] ARCH25 header comment corrected to "one of the few locations" (main.dart, supabase_client.dart, secure_local_storage.dart, this file) [realtime_gateway.dart:1]
- [x] [Review][Defer] Late-subscriber race: broadcast getters return `const Stream.empty()` before join and a fresh controller stream after; a consumer holding a pre-join/post-leave reference receives no events. No replay/seed — events between `subscribe()` and first `.listen()` are lost [realtime_gateway.dart:24] — deferred to Story 19.2 (consumer wiring)
- [x] [Review][Defer] No error handling on async Supabase calls and `subscribe()` status not observed — failed joins are indistinguishable from a quiet healthy channel; `RealtimeFailure` defined but not yet surfaced [realtime_gateway.dart:30] — deferred to Story 19.2 (`Either<RealtimeFailure,...>` at bloc boundary, per spec)
- [x] [Review][Defer] Gateway lifecycle (join/leave/presence/stream teardown) has zero test coverage — only the static `parseBroadcast` and entity equality are tested — deferred to Story 19.2 (gateway mocked at bloc boundary, per spec)
- [x] [Review][Defer] `_emitPresenceState` does not filter empty/duplicate `user_id` — missing id becomes `''`, duplicate connections yield ghost/duplicate participants [realtime_gateway.dart:94] — deferred to Story 19.2 (presence UI)

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-25 | 1.0.0 | Story created. | claude-sonnet-4-6 |
| 2026-06-25 | 1.1.0 | Implementation complete: BroadcastEvent, PresenceState, RealtimeGateway, RealtimeFailure. 12 new tests + 1106 total green. | claude-sonnet-4-6 |
