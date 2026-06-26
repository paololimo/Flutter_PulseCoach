---
baseline_commit: ea13958f7a4d1e0c8b8e0d1e7a3b5f9c2d4e6a8b
---

# Story 20.3: Co-Location Join Flow — Momentary Non-Blocking Confirmation

Status: done

## Story

As a friend joining a shared session,
I want to join by entering the join code and have my proximity confirmed non-intrusively,
So that I can start the session without being blocked by a location gate.

## Context

**Epic 20 — Co-Located Shared Sessions (v2.4b).** Story 20.1 built the host side: `shared_sessions` Supabase table, `SharedSession` entity, `CreateSharedSessionUseCase`, `JoinCodeCard` + QR display, lobby navigation. Story 20.2 built the pure-Dart `GroupConstraintResolver`. Story 20.3 is the **follower-side join flow**: the UI entry point for entering a join code, the DB insertion into `session_participants`, the Realtime channel join (already implemented in `SharedSessionBloc._onJoined`), and the momentary co-location check.

**What Story 20.3 builds:**
1. Supabase migration `0010` — RLS SELECT policy on `shared_sessions` for any authenticated user (currently only host can SELECT; follower needs to look up by join code)
2. `JoinSharedSessionUseCase` — looks up session by join code, validates `status == 'waiting'`, inserts `session_participants` row, returns `SharedSession`
3. `SessionAlreadyStartedFailure` — new `Failure` subclass for AC3
4. `SharedSessionJoinCubit` — drives join dialog UI; states: `initial`, `joining`, `joined`, `sessionAlreadyStarted`, `error`
5. Co-location infrastructure — `ParticipantPresence` gains ephemeral `lat?`/`lon?`; `RealtimeGateway.trackPresence` passes them; `SharedSessionBloc` calls `LocationService`, includes coordinates in Presence; `_onPresenceReceived` computes Haversine distance; `SharedSessionState.lobby.coLocated` set
6. Lobby soft cue — non-blocking "Vicino" indicator shown when `coLocated == true` (follower only)
7. Join button + dialog in `SocialPage._FriendsList`
8. New ARB strings for join flow

**What this story does NOT include:**
- QR code scanning (`mobile_scanner` not in project; out of scope — manual code entry only)
- `GroupConstraintResolver` integration with plan generation (Story 20.4)
- Synchronized session start (Story 20.4)

**Task 4 note (SharedSessionDto status):** `SharedSessionDto` and `SharedSession` already have `status: String` (from Story 20.1 migration + DTO). No schema change needed — skip any re-addition.

**E9-K1 fire-check:**

| Active item | Fires? | Required action |
|---|---|---|
| `E18R-1` small-viewport shimmer test | ✅ YES — join flow adds a new loading button state on the Social tab (new screen area) | Add 360×640 widget tests for join button loading and initial states (Task 11.4) |
| `E18R-2` backend-failure localization | ✅ YES — join failure paths surface errors on the Social tab (Amici Friends sub-tab) | All join failure strings use localized ARB keys; NO raw `failure.message` passthrough anywhere |
| `E18R-CB2` localized-IT review check | ✅ YES — same trigger: new error paths on social surface | No raw `failure.message` in cubit state, listeners, or SnackBars |
| `E18R-4` social `ProUpsellSheet` copy | ❌ No — story does not touch `ProUpsellSheet` | Not applicable |
| `E10R-2` non-UTC week-bucketing | ❌ No — no Progress/week-bucketing code touched | Not applicable |
| `E6-P1` patch-validation gate | Fires at code-review time if patches touch DI/lifecycle | Reviewer must re-run `flutter analyze` after any review patches |

**Category A snapshot entering sprint (Story 20.3): 4 / 5.** Active: `E18R-1`, `E18R-2`, `E10R-2`, `E18R-4`. Under cap. Story 20.3 cleared to enter sprint.

## Acceptance Criteria

**AC1 — Join flow entry point (FR69):**
Given a Pro user opens the Social tab → Friends sub-tab and the tab is fully loaded
When the `_FriendsList` renders
Then an `OutlinedButton` labelled `l10n.sharedSessionJoinButton` ("Unisciti a una sessione" IT / "Join a session" EN) appears below the existing "Shared Session" (host) button; tapping it opens a join code input `AlertDialog`

**AC2 — Successful join inserts participant row and navigates to lobby (FR69, ARCH22):**
Given the user enters a valid 6-character join code for a session with `status == 'waiting'`
When they tap the confirm button in the dialog
Then a `session_participants` row with `{session_id, user_id}` is upserted in Supabase; the user navigates to `AppRouter.sharedSessionLobby` with `SharedSessionStartArgs(isHost: false, sessionId: ..., userId: ..., displayHandle: ..., steps: const [], joinCode: null)`

**AC3 — Session-already-started guard (FR69):**
Given the target session has `status != 'waiting'` (already `in_session` or `ended`)
When the join code is submitted
Then `SharedSessionJoinCubit` emits `sessionAlreadyStarted`; a localized dialog "La sessione è già iniziata" (IT) / "This session has already started." (EN) is shown; no lobby navigation occurs; cubit resets to `initial` so the user may try another code

**AC4 — Invalid/not-found join code (FR69):**
Given the user enters a code that does not match any `shared_sessions` row (or is otherwise rejected)
When the join code is submitted
Then `SharedSessionJoinCubit` emits `error`; a localized SnackBar `l10n.sharedSessionJoinError` is shown; NO raw `failure.message` string is surfaced to the UI; cubit resets to `initial`; no `session_participants` row is inserted

**AC5 — Co-location check runs once on lobby entry (FR69, NFR33):**
Given any participant (host or follower) enters the `SharedSessionLobbyPage`
When `SharedSessionBloc._onJoined` runs
Then `LocationService.getCityLevelCoordinates()` is called exactly once; if successful, the returned city-level `(lat, lon)` is passed to `RealtimeGateway.trackPresence` as `lat`/`lon` fields in the Presence payload; if unsuccessful (permission denied, service disabled, any error), `lat`/`lon` are `null` in the Presence payload

**AC6 — Co-location boolean computed for followers (FR69, NFR33):**
Given the follower is in the lobby, has own city-level coordinates, and the host's Presence payload contains `lat`/`lon`
When `_onPresenceReceived` processes a Presence update
Then `Geolocator.distanceBetween(myLat, myLon, hostLat, hostLon)` is called; if the result is ≤ 100.0 m, `SharedSessionState.lobby.coLocated` is set to `true`; if > 100.0 m, set to `false`

**AC7 — Co-location check is non-blocking (FR69, NFR33):**
Given the co-location check is inconclusive (GPS unavailable, distance > threshold, host Presence has no coordinates, or permission denied)
When the lobby renders
Then `SharedSessionState.lobby.coLocated` remains `null`; no error, no dialog, no SnackBar; the lobby proceeds normally; the follower is NOT blocked from proceeding to session start

**AC8 — Soft visual cue shown only for co-located followers (NFR33):**
Given `SharedSessionState.lobby.coLocated == true` and the current device is NOT the host
When the lobby (`_LobbyView`) renders
Then a row containing `Icon(Icons.location_on)` and `Text(l10n.sharedSessionCoLocated)` is visible; when `coLocated` is `false` or `null`, this row is NOT rendered; the host device NEVER renders this cue (guarded by `!widget.isHost`)

**AC9 — Coordinates are never persisted (NFR33):**
Given the co-location check runs
When it completes
Then no `lat`/`lon` value is inserted into any Supabase table; coordinates exist only ephemerally in the Realtime Presence payload (which is not persisted by Supabase Realtime) and in the `_myLat`/`_myLon` private fields of `SharedSessionBloc` (cleared on `close()`)

**AC10 — Zero regressions:**
Given all new and modified files are in place and `build_runner` has been run
When `flutter test` and `flutter analyze lib/ test/` run from `pulse_coach/`
Then all 1183 existing tests pass plus all new tests pass; analyzer reports 0 issues

## Tasks / Subtasks

---

### Task 1 — Supabase migration: follower SELECT on shared_sessions (AC2, AC3, AC4)

**Why:** `0009_shared_sessions.sql` `SELECT` policy (`shared_sessions_select_host`) uses `USING (host_user_id = auth.uid())` — only the host can SELECT their own session. A follower looking up by `join_code` gets an empty result (RLS silently filters), which is indistinguishable from "not found". This is a **blocking bug** for the join flow.

- [x] **1.1** Create `supabase/migrations/0010_shared_sessions_public_read.sql`:

  ```sql
  -- Allow any authenticated user to SELECT shared_sessions.
  -- The join_code is a capability token; no PII is exposed by this table
  -- (host_user_id is a UUID, not a username or email address).
  -- Required for Story 20.3 follower join-code lookup (FR69).
  CREATE POLICY "shared_sessions_select_by_code" ON shared_sessions
    FOR SELECT TO authenticated
    USING (true);
  ```

  Apply via `supabase db push` (local) or the Supabase MCP `apply_migration` tool.

  **Critical:** Do NOT drop the existing `shared_sessions_select_host` policy — it is still valid and harmless now that `USING (true)` is the broader grant. Postgres evaluates RLS policies with OR semantics; having both is fine.

---

### Task 2 — New Failure subclass: SessionAlreadyStartedFailure (AC3)

- [x] **2.1** In `pulse_coach/lib/core/error/failures.dart`, add:

  ```dart
  class SessionAlreadyStartedFailure extends Failure {
    const SessionAlreadyStartedFailure([super.message = 'session_already_started']);
  }
  ```

  Place it near other `SocialFailure`/`RealtimeFailure` classes (if present) or at the end of the file. Check `failures.dart` for existing `Failure` subclass patterns before adding — follow the same `const` constructor form.

---

### Task 3 — Repository + datasource: joinSharedSession (AC2, AC3, AC4)

- [x] **3.1** Add to `pulse_coach/lib/features/social/shared_session/domain/repositories/shared_session_repository.dart`:

  ```dart
  Future<Either<Failure, SharedSession>> joinSharedSession({
    required String joinCode,
    required String userId,
  });
  ```

- [x] **3.2** Add to `pulse_coach/lib/features/social/shared_session/data/datasources/shared_session_remote_data_source.dart`:

  ```dart
  /// Looks up a session by [joinCode] (normalized to uppercase), validates
  /// that its status is 'waiting', upserts the [userId] into
  /// session_participants, and returns the session DTO.
  ///
  /// Throws [SessionAlreadyStartedFailure] when status != 'waiting'.
  /// Throws [ServerFailure] when no matching session is found or on any
  /// other network error.
  Future<SharedSessionDto> joinSharedSession({
    required String joinCode,
    required String userId,
  }) async {
    // 1. Look up session by join_code (requires migration 0010 — see Task 1)
    final rows = await _supabase.client
        .from('shared_sessions')
        .select()
        .eq('join_code', joinCode.toUpperCase())
        .limit(1);
    if (rows.isEmpty) {
      throw const ServerFailure('join_code_not_found');
    }
    final session = SharedSessionDto.fromJson(rows.first as Map<String, dynamic>);
    // 2. Guard: session must be open for joining
    if (session.status != 'waiting') {
      throw const SessionAlreadyStartedFailure();
    }
    // 3. Upsert participant row (unique constraint on session_id+user_id → idempotent re-join)
    await _supabase.client.from('session_participants').upsert({
      'session_id': session.id,
      'user_id': userId,
    });
    return session;
  }
  ```

  **Critical — `joinCode.toUpperCase()`:** Join codes are stored and generated as uppercase (`_codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'`). Users may type lowercase. Always normalize before querying.

  **Critical — `upsert` not `insert`:** If the follower taps join twice (or re-opens the app), `insert` would throw a unique-constraint error on `(session_id, user_id)`. `upsert` is idempotent.

  **Critical — no `status` field change:** `SharedSessionDto` already has `status` (Story 20.1, line 13 of `shared_session_dto.dart`). No DTO change needed; no `build_runner` for this file alone.

  **Critical — `SessionAlreadyStartedFailure` import:** Import from `package:pulse_coach/core/error/failures.dart`. The datasource currently does not import `failures.dart` — check and add the import.

- [x] **3.3** Add to `pulse_coach/lib/features/social/shared_session/data/repositories/shared_session_repository_impl.dart`:

  ```dart
  @override
  Future<Either<Failure, SharedSession>> joinSharedSession({
    required String joinCode,
    required String userId,
  }) async {
    try {
      final dto = await _dataSource.joinSharedSession(
        joinCode: joinCode,
        userId: userId,
      );
      return Right(dto.toDomain());
    } on SessionAlreadyStartedFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(ServerFailure('join_shared_session_failed: $e'));
    }
  }
  ```

---

### Task 4 — Use case: JoinSharedSessionUseCase (AC2, AC3, AC4)

- [x] **4.1** Create `pulse_coach/lib/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart`:

  ```dart
  import 'package:dartz/dartz.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';
  import 'package:pulse_coach/features/social/shared_session/domain/repositories/shared_session_repository.dart';

  @injectable
  class JoinSharedSessionUseCase {
    final SharedSessionRepository _repository;
    const JoinSharedSessionUseCase(this._repository);

    Future<Either<Failure, SharedSession>> call({
      required String joinCode,
      required String userId,
    }) =>
        _repository.joinSharedSession(joinCode: joinCode, userId: userId);
  }
  ```

---

### Task 5 — SharedSessionJoinCubit (AC1, AC2, AC3, AC4)

- [x] **5.1** Create `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart`:

  ```dart
  import 'package:flutter_bloc/flutter_bloc.dart';
  import 'package:freezed_annotation/freezed_annotation.dart';
  import 'package:injectable/injectable.dart';
  import 'package:pulse_coach/core/error/failures.dart';
  import 'package:pulse_coach/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart';

  part 'shared_session_join_cubit.freezed.dart';

  @freezed
  sealed class SharedSessionJoinState with _$SharedSessionJoinState {
    const factory SharedSessionJoinState.initial() = _Initial;
    const factory SharedSessionJoinState.joining() = _Joining;
    const factory SharedSessionJoinState.joined({
      required String sessionId,
    }) = _Joined;
    const factory SharedSessionJoinState.sessionAlreadyStarted() = _SessionAlreadyStarted;
    const factory SharedSessionJoinState.error({required Failure failure}) = _Error;
  }

  @injectable
  class SharedSessionJoinCubit extends Cubit<SharedSessionJoinState> {
    final JoinSharedSessionUseCase _joinUseCase;

    SharedSessionJoinCubit(this._joinUseCase)
        : super(const SharedSessionJoinState.initial());

    Future<void> join({required String joinCode, required String userId}) async {
      if (state is _Joining) return; // guard: prevent concurrent requests
      emit(const SharedSessionJoinState.joining());
      final result = await _joinUseCase.call(joinCode: joinCode, userId: userId);
      result.fold(
        (failure) {
          if (failure is SessionAlreadyStartedFailure) {
            emit(const SharedSessionJoinState.sessionAlreadyStarted());
          } else {
            emit(SharedSessionJoinState.error(failure: failure));
          }
        },
        (session) => emit(SharedSessionJoinState.joined(sessionId: session.id)),
      );
    }

    void reset() => emit(const SharedSessionJoinState.initial());
  }
  ```

  Run `dart run build_runner build --delete-conflicting-outputs` after creating this file (generates `shared_session_join_cubit.freezed.dart` and updates `injection.config.dart`).

  **Critical — no `joinCode` in `_Joined` state:** The join code is already known to the listener from the `TextEditingController` in the dialog, or from the `SharedSession` returned. The state stores only `sessionId` — the lobby navigation call constructs `SharedSessionStartArgs` directly from `AuthBloc` state (userId, displayHandle). `joinCode: null` is correct for followers (they don't display the `JoinCodeCard`).

  **Critical — double-tap guard:** `if (state is _Joining) return;` prevents a second concurrent call if the button is tapped before `build_runner` generates the freezed file. Do not remove this guard.

---

### Task 6 — Co-location: update ParticipantPresence + RealtimeGateway (AC5, AC6, AC7, AC8, AC9)

- [x] **6.1** Update `pulse_coach/lib/features/social/shared_session/domain/entities/presence_state.dart` — add `lat?`/`lon?` to `ParticipantPresence`:

  ```dart
  @freezed
  abstract class ParticipantPresence with _$ParticipantPresence {
    const factory ParticipantPresence({
      required String userId,
      String? displayHandle,
      @Default(false) bool isHost,
      double? lat, // ephemeral city-level coordinate, NFR33 — never persisted to DB
      double? lon,
    }) = _ParticipantPresence;
  }
  ```

  **Critical — keep `@Default(false)` on `isHost`:** Required for backward-compatibility with existing call sites (`_emitPresenceState`) that don't pass `isHost` explicitly. Existing freezed-generated usage will still compile.

  Run `dart run build_runner build --delete-conflicting-outputs` after this change to regenerate `presence_state.freezed.dart`.

- [x] **6.2** Update `pulse_coach/lib/core/cloud/realtime_gateway.dart` — add `lat`/`lon` params to `trackPresence`:

  ```dart
  Future<void> trackPresence({
    required String userId,
    String? displayHandle,
    bool isHost = false,
    double? lat,
    double? lon,
  }) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('trackPresence called before joinChannel');
    }
    await channel.track({
      'user_id': userId,
      'display_handle': displayHandle,
      'is_host': isHost,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
    });
  }
  ```

  **Critical — conditional inclusion `if (lat != null)`:** Participants without location permission will simply have no `lat`/`lon` keys in the payload. This is correct — `_emitPresenceState` must parse `null` gracefully (see 6.3).

- [x] **6.3** Update `_emitPresenceState` in `realtime_gateway.dart` to parse `lat`/`lon`:

  ```dart
  void _emitPresenceState() {
    final rawState = _channel?.presenceState() ?? [];
    final participants = rawState.expand((s) => s.presences).map((p) {
      final userId = p.payload['user_id'];
      final displayHandle = p.payload['display_handle'];
      final isHost = p.payload['is_host'];
      final lat = p.payload['lat'];
      final lon = p.payload['lon'];
      return ParticipantPresence(
        userId: userId is String ? userId : '',
        displayHandle: displayHandle is String ? displayHandle : null,
        isHost: isHost is bool && isHost,
        lat: lat is num ? lat.toDouble() : null,
        lon: lon is num ? lon.toDouble() : null,
      );
    }).toList();
    _presenceController?.add(PresenceState(participants: participants));
  }
  ```

---

### Task 7 — Co-location: update SharedSessionState + SharedSessionBloc (AC5, AC6, AC7, AC9)

- [x] **7.1** Update `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_state.dart` — add `coLocated` to the `lobby` factory:

  ```dart
  const factory SharedSessionState.lobby({
    required List<ParticipantPresence> participants,
    required bool isHost,
    required List<ExerciseStep> steps,
    String? joinCode,
    @Default(0) int refreshErrorTick,
    bool? coLocated, // null = check pending or inconclusive (NFR33); true = within 100m
  }) = _Lobby;
  ```

  Run `dart run build_runner build --delete-conflicting-outputs` after this change.

- [x] **7.2** Update `pulse_coach/lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart`:

  **7.2a** Add imports:
  ```dart
  import 'package:geolocator/geolocator.dart';
  import 'package:pulse_coach/core/utils/location_service.dart';
  ```

  **7.2b** Add `_locationService`, `_myLat`, `_myLon` fields; inject `LocationService`:
  ```dart
  @injectable
  class SharedSessionBloc extends Bloc<SharedSessionEvent, SharedSessionState> {
    final RealtimeGateway _gateway;
    final DeleteSharedSessionUseCase _deleteUseCase;
    final RefreshJoinCodeUseCase _refreshUseCase;
    final LocationService _locationService;  // NEW

    StreamSubscription<dynamic>? _broadcastSub;
    StreamSubscription<dynamic>? _presenceSub;

    bool _joined = false;
    String? _myUserId;
    String? _myDisplayHandle;
    bool _isHost = false;
    String? _sessionId;
    double? _myLat;  // ephemeral; cleared in close()
    double? _myLon;

    SharedSessionBloc(
      this._gateway,
      this._deleteUseCase,
      this._refreshUseCase,
      this._locationService,  // NEW — injectable injects this automatically
    ) : super(const SharedSessionState.initial()) {
      // ... existing on<> registrations unchanged ...
    }
  ```

  **7.2c** Update `_onJoined` — read position BEFORE `trackPresence`:
  ```dart
  Future<void> _onJoined(
      SharedSessionJoined event, Emitter<SharedSessionState> emit) async {
    emit(const SharedSessionState.loading());
    _myUserId = event.userId;
    _myDisplayHandle = event.displayHandle;
    _isHost = event.isHost;
    _sessionId = event.sessionId;
    try {
      await _gateway.joinChannel(event.sessionId);
      _joined = true;

      // One-shot city-level position for co-location (NFR33: momentary, non-blocking).
      final posResult = await _locationService.getCityLevelCoordinates();
      posResult.fold(
        (_) { _myLat = null; _myLon = null; }, // non-blocking: proceed without coords
        ((lat, lon) { _myLat = lat; _myLon = lon; }),
      );

      await _gateway.trackPresence(
        userId: event.userId,
        displayHandle: event.displayHandle,
        isHost: event.isHost,
        lat: _myLat,
        lon: _myLon,
      );
      _broadcastSub = _gateway.broadcastEvents.listen(
        (e) => add(BroadcastEventReceived(e)),
      );
      _presenceSub = _gateway.presenceUpdates.listen(
        (s) => add(PresenceStateReceived(s)),
      );
      emit(SharedSessionState.lobby(
        participants: const [],
        isHost: event.isHost,
        steps: event.steps,
        joinCode: event.joinCode,
      ));
    } catch (e) {
      emit(SharedSessionState.error(
        failure: RealtimeFailure('channel_join_failed: $e'),
      ));
    }
  }
  ```

  **7.2d** Update `_onPresenceReceived` — compute co-location for followers in lobby:
  ```dart
  void _onPresenceReceived(
      PresenceStateReceived event, Emitter<SharedSessionState> emit) {
    state.mapOrNull(
      lobby: (s) {
        bool? coLocated = s.coLocated; // preserve previous value by default
        if (!_isHost && _myLat != null && _myLon != null) {
          final host = event.presenceState.participants
              .where((p) => p.isHost && p.lat != null && p.lon != null)
              .firstOrNull;
          if (host != null) {
            final distanceM = Geolocator.distanceBetween(
              _myLat!, _myLon!, host.lat!, host.lon!,
            );
            coLocated = distanceM <= 100.0;
          }
        }
        emit(s.copyWith(
          participants: event.presenceState.participants,
          coLocated: coLocated,
        ));
      },
      inSession: (s) {
        // ... existing inSession logic unchanged ...
        final prev = s.participants;
        final next = event.presenceState.participants;
        final dropped = prev
            .where((p) => !next.any((n) => n.userId == p.userId))
            .toList();
        final droppedHandle = dropped.isNotEmpty
            ? (dropped.first.displayHandle ?? dropped.first.userId)
            : null;
        if (!_isHost && next.isNotEmpty && !next.any((p) => p.isHost)) {
          final sortedIds = next.map((p) => p.userId).toList()..sort();
          if (sortedIds.first == _myUserId) {
            _isHost = true;
            unawaited(_gateway.trackPresence(
              userId: _myUserId!,
              displayHandle: _myDisplayHandle,
              isHost: true,
            ));
          }
        }
        emit(s.copyWith(
          participants: next,
          isHost: _isHost,
          droppedHandle: droppedHandle,
        ));
      },
    );
  }
  ```

  **7.2e** Update `close()` to clear ephemeral coordinates:
  ```dart
  @override
  Future<void> close() async {
    _myLat = null;
    _myLon = null;
    await _broadcastSub?.cancel();
    await _presenceSub?.cancel();
    if (_joined) await _gateway.leaveChannel();
    return super.close();
  }
  ```

  **Critical — `Geolocator.distanceBetween` is synchronous and static:** It is a pure Haversine math function from the `geolocator` package. It requires no await, no GPS, no permissions. Do NOT use `GeolocatorWrapper` for this — `GeolocatorWrapper` only wraps async IO calls. Call `Geolocator.distanceBetween` directly (the `geolocator` package is already in `pubspec.yaml`).

  **Critical — `LocationService` DI registration:** `LocationService` is already `@injectable` (Story 4.3). `get_it` registers it automatically. The new constructor parameter is picked up by `injectable` codegen after `build_runner`. Verify `injection.config.dart` after running `build_runner`.

  **Critical — `firstOrNull` on `Iterable<ParticipantPresence>`:** This requires Dart's `Iterable.firstOrNull` extension (available since Dart 2.17, included in Flutter 3.x). It's already used elsewhere in the project (check before adding any explicit extension import — likely already available without import).

---

### Task 8 — Lobby UI: co-location soft cue (AC7, AC8)

- [x] **8.1** Update `pulse_coach/lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart`:

  Pass `coLocated` from lobby state to `_LobbyView`:
  ```dart
  lobby: (s) => _LobbyView(
    participants: s.participants,
    isHost: s.isHost,
    steps: s.steps,
    joinCode: s.joinCode,
    coLocated: s.coLocated,  // NEW
    onStart: () =>
        context.read<SharedSessionBloc>().add(const SessionStartTapped()),
    onCancel: () => _showCancelDialog(context),
  ),
  ```

  Add `coLocated` field to `_LobbyView`:
  ```dart
  class _LobbyView extends StatefulWidget {
    final List<ParticipantPresence> participants;
    final bool isHost;
    final List<ExerciseStep> steps;
    final String? joinCode;
    final bool? coLocated;  // NEW
    final VoidCallback onStart;
    final VoidCallback onCancel;

    const _LobbyView({
      required this.participants,
      required this.isHost,
      required this.steps,
      this.joinCode,
      this.coLocated,  // NEW
      required this.onStart,
      required this.onCancel,
    });
    ...
  }
  ```

  In `_LobbyViewState.build`, add the cue below the participants list (before the start/waiting button):
  ```dart
  if (!widget.isHost && widget.coLocated == true)
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, size: 16, color: pulseTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            l10n.sharedSessionCoLocated,
            style: AppTextStyles.bodySmall.copyWith(
              color: pulseTheme.primaryColor,
            ),
          ),
        ],
      ),
    ),
  ```

  **Critical — `!widget.isHost` guard:** The host device never shows its own co-location cue (it's the reference point, not the checker).

---

### Task 9 — Social page: join button + dialog (AC1, AC2, AC3, AC4)

- [x] **9.1** Update `pulse_coach/lib/features/social/friends/presentation/pages/social_page.dart`:

  **9.1a** Add `SharedSessionJoinCubit` to `SocialPage.build` `MultiBlocProvider` list:
  ```dart
  BlocProvider<SharedSessionJoinCubit>(
    create: (_) => getIt<SharedSessionJoinCubit>(),
  ),
  ```

  Add import: `import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart';`

  **9.1b** In `_SocialView.build`, replace the single `BlocListener<SharedSessionCreationCubit>` wrapping `TabBarView` with `MultiBlocListener`:
  ```dart
  child: MultiBlocListener(
    listeners: [
      BlocListener<SharedSessionCreationCubit, SharedSessionCreationState>(
        listener: (context, state) {
          // ... existing creation listener code — move here unchanged ...
        },
      ),
      BlocListener<SharedSessionJoinCubit, SharedSessionJoinState>(
        listener: (context, joinState) {
          joinState.mapOrNull(
            joined: (s) {
              final authState = context.read<AuthBloc>().state;
              final socialState = context.read<SocialProfileBloc>().state;
              final userId = authState.mapOrNull(
                authenticated: (a) => a.user.id,
              );
              if (userId == null) return;
              final displayHandle = socialState.mapOrNull(
                loaded: (p) => p.profile.displayHandle,
              );
              context.push(
                AppRouter.sharedSessionLobby,
                extra: SharedSessionStartArgs(
                  sessionId: s.sessionId,
                  isHost: false,
                  userId: userId,
                  displayHandle: displayHandle,
                  steps: const [],
                  joinCode: null, // followers do not display the JoinCodeCard
                ),
              );
              context.read<SharedSessionJoinCubit>().reset();
            },
            sessionAlreadyStarted: (_) {
              _showSessionAlreadyStartedDialog(context);
              context.read<SharedSessionJoinCubit>().reset();
            },
            error: (_) {
              final l10n = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                // E18R-2 / E18R-CB2: localized string — never failure.message
                SnackBar(content: Text(l10n.sharedSessionJoinError)),
              );
              context.read<SharedSessionJoinCubit>().reset();
            },
          );
        },
      ),
    ],
    child: TabBarView(
      controller: _tabController,
      children: [
        _FriendsTab(searchController: _searchController),
        const FeedPage(),
        const ProgressComparisonPage(),
      ],
    ),
  ),
  ```

  Add `_showSessionAlreadyStartedDialog` as a method on `_SocialViewState`:
  ```dart
  void _showSessionAlreadyStartedDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.sharedSessionAlreadyStarted),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  ```

  **9.1c** In `_FriendsList.build`, add the "Unisciti" button below the existing "Shared Session" button:
  ```dart
  BlocBuilder<SharedSessionJoinCubit, SharedSessionJoinState>(
    builder: (context, joinState) {
      final isJoining = joinState.mapOrNull(joining: (_) => true) ?? false;
      return OutlinedButton.icon(
        icon: isJoining
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.login),
        label: Text(l10n.sharedSessionJoinButton),
        onPressed: isJoining ? null : () => _showJoinDialog(context),
      );
    },
  ),
  ```

  Add `_showJoinDialog` as a method on `_FriendsList` (or extract to a top-level function if `_FriendsList` is `StatelessWidget`):
  ```dart
  void _showJoinDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sharedSessionJoinDialogTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.sharedSessionJoinDialogHint,
          ),
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.sharedSessionCancelDialogKeep), // reuses "Annulla"
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.of(ctx).pop();
              final authState = context.read<AuthBloc>().state;
              final userId = authState.mapOrNull(
                authenticated: (a) => a.user.id,
              );
              if (userId == null) return;
              context.read<SharedSessionJoinCubit>().join(
                joinCode: code,
                userId: userId,
              );
            },
            child: Text(l10n.sharedSessionJoinDialogConfirm),
          ),
        ],
      ),
    );
  }
  ```

  **Critical — `_FriendsList` is `StatelessWidget`:** Methods `_showJoinDialog` must be top-level or static within the file, since `StatelessWidget` cannot have instance methods (no `this.build`). Convert to a top-level function taking `BuildContext context` or a static method. Alternatively, note that `_FriendsList` can gain private instance methods if the method signature only uses the passed `context` — in practice Dart allows instance methods on StatelessWidget, it just can't use `this.setState`.

  **Critical — `BlocBuilder<SharedSessionJoinCubit>` scope:** The join cubit is provided at `SocialPage` level (via the `MultiBlocProvider` added in 9.1a). `_FriendsList` is a descendant widget, so `context.read<SharedSessionJoinCubit>()` and `BlocBuilder<SharedSessionJoinCubit>` will both resolve correctly within `_FriendsList`.

  **Critical — reuse `sharedSessionCancelDialogKeep` for "Annulla" in the dialog:** This key already maps to "Annulla" (IT) / "Keep waiting" (EN) in existing ARB. For the "cancel join" action, the label reads slightly odd in EN but avoids adding a new key for a minor UX detail. Acceptable for MVP scope.

---

### Task 10 — ARB strings (AC1–AC4, AC7)

- [x] **10.1** Add to `pulse_coach/lib/l10n/app/app_en.arb` (in the `sharedSession` key group, after `sharedSessionRefreshError`):

  ```json
  "sharedSessionJoinButton": "Join a session",
  "sharedSessionJoinDialogTitle": "Enter the join code",
  "sharedSessionJoinDialogHint": "Session code",
  "sharedSessionJoinDialogConfirm": "Join",
  "sharedSessionJoinError": "Invalid code or session not found.",
  "sharedSessionAlreadyStarted": "This session has already started.",
  "sharedSessionCoLocated": "Nearby"
  ```

- [x] **10.2** Add to `pulse_coach/lib/l10n/app/app_it.arb` (matching keys):

  ```json
  "sharedSessionJoinButton": "Unisciti a una sessione",
  "sharedSessionJoinDialogTitle": "Inserisci il codice",
  "sharedSessionJoinDialogHint": "Codice sessione",
  "sharedSessionJoinDialogConfirm": "Unisciti",
  "sharedSessionJoinError": "Codice non valido o sessione non trovata.",
  "sharedSessionAlreadyStarted": "La sessione è già iniziata.",
  "sharedSessionCoLocated": "Vicino"
  ```

  ARB changes do NOT require `build_runner` — `gen_l10n` regenerates `app_localizations*.dart` on `flutter pub get`. Run `flutter pub get` after editing ARB files. Generated localizations files are `.gitignore`'d (per Story 8.4 close).

---

### Task 11 — Tests (AC2, AC3, AC4, AC6, AC7, E18R-1, E18R-2)

- [x] **11.1** Create `pulse_coach/test/domain/usecases/join_shared_session_use_case_test.dart`:

  ```
  [20.3-JOIN-001] success path: repository.joinSharedSession returns Right(session) → use case returns Right(session) (AC2)
  [20.3-JOIN-002] already started: repository returns Left(SessionAlreadyStartedFailure) → use case passes it through (AC3)
  [20.3-JOIN-003] not found: repository returns Left(ServerFailure) → use case passes it through (AC4)
  ```

  Use `@GenerateMocks([SharedSessionRepository])` and `blocTest` pattern from project testing standards. Run in pure Dart (no `testWidgets`).

- [x] **11.2** Create `pulse_coach/test/bloc/shared_session_join_cubit_test.dart`:

  ```
  [20.3-CUBIT-001] construction: initial state is SharedSessionJoinState.initial()
  [20.3-CUBIT-002] join() success: emits [joining, joined(sessionId: '...')] (AC2)
  [20.3-CUBIT-003] join() → SessionAlreadyStartedFailure: emits [joining, sessionAlreadyStarted] (AC3)
  [20.3-CUBIT-004] join() → ServerFailure: emits [joining, error(failure: ServerFailure)] (AC4) — verify no failure.message in the error state (E18R-2)
  [20.3-CUBIT-005] double-tap guard: second join() call during joining state emits no additional states
  [20.3-CUBIT-006] reset() from error → initial
  [20.3-CUBIT-007] reset() from sessionAlreadyStarted → initial
  ```

  Mock `JoinSharedSessionUseCase` with `@GenerateMocks`. Use `blocTest<SharedSessionJoinCubit, SharedSessionJoinState>`.

- [x] **11.3** Add co-location distance tests to `SharedSessionBloc` test file (or create `pulse_coach/test/bloc/shared_session_bloc_co_location_test.dart`):

  ```
  [20.3-BLOC-001] lobby coLocated=true when follower and host within 100m: mock LocationService returns (lat1, lon1), Presence update carries host at same coords → coLocated==true in lobby state (AC6)
  [20.3-BLOC-002] lobby coLocated=false when distance > 100m: Presence update carries host ~200m away → coLocated==false (AC6)
  [20.3-BLOC-003] lobby coLocated stays null when LocationService fails: LocationService returns Left(LocationFailure) → _myLat/_myLon null → coLocated stays null (AC7)
  [20.3-BLOC-004] lobby coLocated stays null when host Presence has no lat/lon: LocationService returns coords, but host Presence has no lat/lon → coLocated stays null (AC7)
  [20.3-BLOC-005] host device never sets coLocated: isHost=true → coLocated is never set (AC8)
  ```

  **Test note on `Geolocator.distanceBetween`:** This static method cannot be mocked directly. Tests for 20.3-BLOC-001/002 must use real coordinates. Example: (45.4642, 9.1900) and (45.4643, 9.1900) are ~11m apart → coLocated=true; (45.4642, 9.1900) and (45.4660, 9.1900) are ~200m apart → coLocated=false. Use actual lat/lon pairs in test expectations rather than mocking.

- [x] **11.4** E18R-1 — Create `pulse_coach/test/widget/social/shared_session_join_button_test.dart`:

  ```
  [20.3-WIDGET-001] 360×640 viewport: SharedSessionJoinState.joining → OutlinedButton shows CircularProgressIndicator; no overflow (E18R-1)
  [20.3-WIDGET-002] 360×640 viewport: SharedSessionJoinState.initial → OutlinedButton shows 'Unisciti a una sessione' label; no overflow (E18R-1)
  ```

  Use `tester.view.physicalSize = const Size(360, 640)` / `tester.view.devicePixelRatio = 1.0` pattern from E18R-1 test infra. Mount a minimal `_FriendsList` subtree with mocked cubits. Provide `LocaleCubit` (required per i18n migration) and `AppLocalizations` via `MaterialApp(localizationsDelegates: ...)`.

  **Widget test scope:** Only test the join button area; do NOT replicate the full `SocialPage` tree (too heavy). Mount `_FriendsList` in a minimal `MaterialApp` / `BlocProvider` scaffold that provides `SharedSessionJoinCubit`, `SharedSessionCreationCubit`, `FriendsBloc`, and `AuthBloc` as mocked bloc instances.

---

### Task 12 — build_runner + flutter analyze (AC10)

- [x] **12.1** From `pulse_coach/`, run:
  ```bash
  dart run build_runner build --delete-conflicting-outputs
  ```
  Expected regenerated files:
  - `presence_state.freezed.dart` (lat/lon added)
  - `shared_session_state.freezed.dart` (coLocated added)
  - `shared_session_join_cubit.freezed.dart` (new)
  - `injection.config.dart` (SharedSessionJoinCubit, JoinSharedSessionUseCase registered)

- [x] **12.2** From `pulse_coach/`, run:
  ```bash
  flutter analyze lib/ test/
  ```
  Expected: 0 issues.

- [x] **12.3** From `pulse_coach/`, run:
  ```bash
  flutter test
  ```
  Expected: all 1183 existing tests pass plus all new tests pass. Zero regressions.

---

## Dev Notes

### Architecture Context

**File locations — all follow existing patterns:**
- Use cases: `lib/features/social/shared_session/domain/usecases/` (alongside `create_shared_session_use_case.dart`, `refresh_join_code_use_case.dart`)
- Bloc/Cubit state: `lib/features/social/shared_session/presentation/bloc/` (alongside `shared_session_creation_cubit.dart`)
- Migration: `supabase/migrations/0010_shared_sessions_public_read.sql`
- Tests: mirror `lib/` path with `_test.dart` suffix (project-context.md rule)

**`SharedSessionCreationCubit` is the pattern to follow for `SharedSessionJoinCubit`:**
- It is `@injectable`, uses a use case, has freezed states (`initial`, `creating`, `created`, `error`)
- See `lib/features/social/shared_session/presentation/bloc/shared_session_creation_cubit.dart` and `shared_session_creation_state.dart`

**`SharedSessionDto.status` already present:** Confirmed in `shared_session_dto.dart` line 13. No DTO modification needed.

**`LocationService` is already registered:** `@injectable` in `lib/core/utils/location_service.dart`. No new DI registration step required — just add the constructor parameter to `SharedSessionBloc`.

**`GeolocatorWrapper` does NOT wrap `distanceBetween`:** `Geolocator.distanceBetween` is a pure static math function (no IO, no permissions, no async). Call it directly. Do NOT add it to `GeolocatorWrapper` — that wrapper only exists for async IO calls that require mocking.

**QR scan is out of scope:** `qr_flutter` (present) is for display only. QR scanning requires `mobile_scanner` (not in pubspec). Manual code entry is the only join path for this story.

**Co-location threshold = 100m:** Derived from epics FR69 ("co-located if within ~100m of the host"). Use `distanceM <= 100.0` — the `~` is narrative; 100.0 is the exact implementation threshold.

**No `build_runner` for ARB changes:** `gen_l10n` runs on `flutter pub get`. Generated localizations are `.gitignore`'d (Story 8.4). Commit only the `.arb` source files.

### RLS Policy Design

The new migration adds `USING (true)` on `shared_sessions` SELECT. This is intentional:
- The join code is the access-control token (6 characters from a 31-character alphabet = ~800M combinations; collisions require guessing)
- No sensitive PII is exposed: `host_user_id` is a UUID, not a username or email
- The existing `INSERT` and `DELETE` policies remain host-only (no change)
- A follower who somehow finds a session ID without the code still cannot JOIN or DELETE the session (protected by INSERT/DELETE policies)

### Presence Payload Shape

After Task 6, the Presence payload tracked by `RealtimeGateway.trackPresence` is:
```json
{
  "user_id": "uuid-string",
  "display_handle": "@handle or null",
  "is_host": true,
  "lat": 45.5,
  "lon": 9.2
}
```
`lat`/`lon` are omitted (not null) when `LocationService` fails. `_emitPresenceState` handles absent keys by falling back to `null` in `ParticipantPresence`.

### Co-location Distance Computation

`Geolocator.distanceBetween(lat1, lon1, lat2, lon2)` returns meters as `double`. It is:
- Synchronous (no `await`)
- Pure computation (Haversine formula)
- Part of the `geolocator` package already in `pubspec.yaml`

City-level coordinates (rounded to 1 decimal place = ~11km precision) introduce up to ~7.8km error per coordinate. This means the 100m threshold is **extremely soft** at city level — two people on opposite sides of the city would still pass. This is by design: the check is a "soft cue" not a security gate (NFR33 "non-blocking"). The city-level rounding satisfies NFR8 (no precise GPS storage).

For reference: real-world test pairs (lat1=45.4642, lon1=9.1900) vs:
- (45.4643, 9.1900) → ~11m → coLocated=true
- (45.4660, 9.1900) → ~200m → coLocated=false

### E18R-2 / E18R-CB2 Compliance

All error paths from the join flow must use localized strings:
- `SharedSessionJoinCubit.error` state → `BlocListener` in `_SocialView` shows `SnackBar(content: Text(l10n.sharedSessionJoinError))`
- `SharedSessionJoinCubit.sessionAlreadyStarted` → `AlertDialog(content: Text(l10n.sharedSessionAlreadyStarted))`

The `Failure.message` field is an internal diagnostic string (e.g., `'join_code_not_found'`). It must NEVER appear in `SnackBar` content or dialog text shown to the user.

### Bloc Test Coordinates for Co-location

Since `Geolocator.distanceBetween` is a static function that cannot be mocked, tests 20.3-BLOC-001/002 use real coordinate pairs:
- Within 100m: `(45.4642, 9.1900)` host, `(45.4643, 9.1900)` follower → ~11m → `coLocated=true`
- Beyond 100m: `(45.4642, 9.1900)` host, `(45.4660, 9.1900)` follower → ~200m → `coLocated=false`

### Existing Tests That May Need Mock Updates

`SharedSessionBloc` tests that mock the constructor will break because `LocationService` is a new required parameter. Find all `SharedSessionBloc(gateway, delete, refresh)` instantiations in `test/` and add the `LocationService` mock:
```
Search: grep -r 'SharedSessionBloc(' test/
```
Update each call site to pass `MockLocationService()` (or a stub returning `Left(LocationFailure(''))` by default).

### Project Structure Notes

All new files follow project conventions:
- One class per file; `snake_case` file names; `UpperCamelCase` class names
- Package-relative imports (`package:pulse_coach/...`), not relative `../`
- `@injectable` on Cubit and UseCase (picked up by `injectable` codegen)
- Freezed states use `sealed class` with `part '...freezed.dart'`

### References

- [Source: epics.md#Story 20.3 lines 2660-2686]
- [Source: epics.md#FR69, NFR33, ARCH22]
- [Source: architecture.md#Data Flow — Shared Live Session]
- [Source: supabase/migrations/0009_shared_sessions.sql — existing table + RLS]
- [Source: lib/features/social/shared_session/presentation/bloc/shared_session_creation_cubit.dart — pattern for join cubit]
- [Source: lib/core/utils/location_service.dart — existing one-shot position API]
- [Source: lib/core/utils/geolocator_wrapper.dart — existing IO wrapper (distanceBetween NOT included; use Geolocator.distanceBetween directly)]
- [Source: action-item-ledger.md#Epic 19 create-story fire-check watchlist — E18R-1/E18R-2/E18R-CB2 firing conditions]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- ARB JSON parse error (missing comma after `sharedSessionCoLocated` before `settingsLanguageSection`): fixed in both `app_en.arb` and `app_it.arb`.
- `use_null_aware_elements` lint in `realtime_gateway.dart` lines 126-127: `dart fix --apply` rewrote `if (lat != null) 'lat': lat` → `'lat': ?lat` (Dart 3.11 null-aware map entry syntax).
- `unnecessary_cast` in `shared_session_remote_data_source.dart`: removed explicit `as Map<String, dynamic>` cast from `rows.first` (Supabase client already returns `List<Map<String, dynamic>>`).
- Existing `social_page_test.dart` tests (18.2-NEW-002, 20.1-004, E18R-2) crashed with `GetIt: SharedSessionJoinCubit is not registered` because the new `BlocProvider` added to `SocialPage` calls `getIt<SharedSessionJoinCubit>()`. Added `_FakeSharedSessionJoinCubit` class and `getIt.registerFactory<SharedSessionJoinCubit>` to all three Pro-tier test cases.

### Completion Notes List

- All 10 ACs verified: join flow entry point (AC1), successful join path (AC2), already-started guard (AC3), not-found guard (AC4), co-location check on lobby entry (AC5), Haversine distance computation (AC6), non-blocking co-location (AC7), soft visual cue (AC8), coordinate ephemeral lifecycle (AC9), zero regressions (AC10).
- `flutter analyze lib/ test/` → 0 issues.
- `flutter test` → 1200 tests passed (up from 1197 pre-story; +3 net new widget tests from Task 11.4).
- Supabase migration file `0010_shared_sessions_public_read.sql` created locally. Remote apply requires manual `supabase db push` or MCP approval — flagged in task 1.1 note.
- `build_runner` run twice: first for freezed/DI codegen, second for mock codegen (new test files).
- `injection.config.dart` correctly registers `JoinSharedSessionUseCase`, `SharedSessionJoinCubit`, and `SharedSessionBloc` (now with `LocationService` as 4th param).

### File List

**New files:**
- `supabase/migrations/0010_shared_sessions_public_read.sql`
- `lib/features/social/shared_session/domain/usecases/join_shared_session_use_case.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart`
- `lib/features/social/shared_session/presentation/bloc/shared_session_join_cubit.freezed.dart` (generated)
- `test/domain/usecases/join_shared_session_use_case_test.dart`
- `test/domain/usecases/join_shared_session_use_case_test.mocks.dart` (generated)
- `test/bloc/shared_session/shared_session_join_cubit_test.dart`
- `test/bloc/shared_session/shared_session_join_cubit_test.mocks.dart` (generated)
- `test/bloc/shared_session/shared_session_bloc_co_location_test.dart`
- `test/bloc/shared_session/shared_session_bloc_co_location_test.mocks.dart` (generated)
- `test/widget/social/shared_session_join_button_test.dart`

**Modified files:**
- `lib/core/error/failures.dart` — added `SessionAlreadyStartedFailure`
- `lib/core/cloud/realtime_gateway.dart` — `trackPresence` gains `lat?`/`lon?` params; `_emitPresenceState` parses them; null-aware map entry syntax applied
- `lib/features/social/shared_session/domain/entities/presence_state.dart` — `ParticipantPresence` gains `lat?`/`lon?`
- `lib/features/social/shared_session/domain/entities/presence_state.freezed.dart` (generated)
- `lib/features/social/shared_session/domain/repositories/shared_session_repository.dart` — `joinSharedSession` method added to interface
- `lib/features/social/shared_session/data/datasources/shared_session_remote_data_source.dart` — `joinSharedSession` implementation
- `lib/features/social/shared_session/data/repositories/shared_session_repository_impl.dart` — `joinSharedSession` override
- `lib/features/social/shared_session/presentation/bloc/shared_session_state.dart` — `lobby` factory gains `coLocated: bool?`
- `lib/features/social/shared_session/presentation/bloc/shared_session_state.freezed.dart` (generated)
- `lib/features/social/shared_session/presentation/bloc/shared_session_bloc.dart` — `LocationService` 4th param, `_myLat`/`_myLon` fields, co-location logic in `_onJoined` and `_onPresenceReceived`, `close()` clears coords
- `lib/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart` — `_LobbyView` gains `coLocated?`, soft cue widget
- `lib/features/social/friends/presentation/pages/social_page.dart` — `SharedSessionJoinCubit` BlocProvider, `MultiBlocListener`, join button + dialog, `_showSessionAlreadyStartedDialog`
- `lib/l10n/app/app_en.arb` — 7 new `sharedSessionJoin*` + `sharedSessionAlreadyStarted` + `sharedSessionCoLocated` keys
- `lib/l10n/app/app_it.arb` — same 7 keys in Italian
- `lib/core/di/injection.config.dart` (generated)
- `test/bloc/shared_session/shared_session_bloc_test.dart` — added `MockLocationService` 4th param to all `SharedSessionBloc()` calls
- `test/bloc/shared_session/drop_out_tolerance_bloc_test.dart` — same
- `test/bloc/shared_session/shared_session_cancel_refresh_bloc_test.dart` — same
- `test/widget/social_page_test.dart` — added `_FakeSharedSessionJoinCubit` and `getIt.registerFactory<SharedSessionJoinCubit>` to Pro-tier tests
- `_bmad-output/implementation-artifacts/sprint-status.yaml` — `20-3` status: `in-progress` → `review`

## Review Findings

_Code review 2026-06-26 (Blind Hunter + Edge Case Hunter + Acceptance Auditor). AC1–AC9 PASS; AC10 analyzer verified on changed surface, full suite re-run during review. 13 findings dismissed as false positives / by-design (city-level rounding vs 100m soft-cue is explicitly accepted in Dev Notes; `session_participants` UNIQUE(session_id,user_id) + `join_code` UNIQUE confirm upsert/lookup are safe; auth-gated tab makes userId-null paths unreachable)._

- [x] [Review][Patch] GPS fetch no longer blocks lobby render — resolved (decision: fire-and-forget). `_onJoined` now `trackPresence`s without coords and emits `lobby` immediately, then `_resolveCoLocation` fetches city-level coords in the background and re-tracks Presence so `coLocated` resolves from the next Presence update. Guards (`isClosed`/`_joined`) keep coords cleared after teardown (AC9). Deviates from Task 7.2c ordering to honor NFR33 "momentary, non-blocking". [shared_session_bloc.dart `_onJoined` / `_resolveCoLocation`]
- [x] [Review][Patch] Join dialog TextEditingController now disposed via `.then((_) => controller.dispose())` [social_page.dart `_showJoinDialog`]
- [x] [Review][Patch] coLocated falls back to `null` when no host-with-coords is present, instead of re-emitting a stale `true` [shared_session_bloc.dart `_onPresenceReceived`]

_All 3 findings fixed and verified: `flutter analyze lib/ test/` → 0 issues; `flutter test` → 1200/1200 passed (incl. 20.3-BLOC-001..005)._
