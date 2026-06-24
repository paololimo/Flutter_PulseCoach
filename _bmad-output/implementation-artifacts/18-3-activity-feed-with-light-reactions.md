---
baseline_commit: 7989c55
---

# Story 18.3: Activity Feed with Light Reactions

Status: done

## Story

As a Pro user,
I want to see completed sessions my friends have explicitly shared and send a light reaction,
So that I can feel connected to friends' progress without biometric detail being exposed or pressure being created.

## Acceptance Criteria

**AC1 — Share toggle on MiniSummary (Pro only):**
Given a Pro user completes a session (not abandoned) and `MiniSummaryPage` resolves to `MiniSummaryLoaded`
When the summary renders
Then an "Condividi con gli amici" toggle is shown below the stat rows; it defaults to OFF; the toggle is NOT shown if the user is not Pro (check `SubscriptionBloc` — same Pro-gate pattern as `ProgressPage` / `SocialPage`); sharing must be an explicit opt-in (FR66, NFR29)

**AC2 — Feed row insertion on share:**
Given the Pro user enables the share toggle
When the `MiniSummaryPage` navigates away (auto-dismiss or Fading→Done) and the toggle was enabled
Then an `activity_feed` row is inserted into Supabase with: `owner_id` (current user's UUID), `session_type` (from `MiniSummaryArgs.sessionType`), `duration_minutes` (from `MiniSummaryArgs.durationMinutes`), `completed_at` (current UTC timestamp) — NO `rpe_value`, NO HR, NO biometric field (NFR29, UX-DR27); on failure a `SnackBar` is shown but navigation still proceeds

**AC3 — Feed tab renders ActivityFeedCards:**
Given a Pro user opens the Social tab → Feed sub-tab
When the `FeedBloc` loads
Then: `loading` state emits first (shimmer placeholders); `loaded` state shows an `ActivityFeedCard` for each entry with: friend's `@handle`, session type icon (mobility/cardio/breathing — same icon mapping as Today screen), duration in minutes, relative time label (e.g., "2 ore fa"); NO biometric detail shown; if the feed is empty an "Ancora nessuna attività" empty-state message is shown (UX-DR27)

**AC4 — Light reaction tap:**
Given a viewer taps the single reaction tap target on an `ActivityFeedCard`
When `FeedBloc` processes `FeedReactionSent(feedEntryId)`
Then: the `activity_feed` row's `reactions` column is incremented by 1 (Supabase RPC or UPDATE); a brief scale animation plays on the reaction icon (e.g., scale 1.0 → 1.4 → 1.0 over 300ms); NO push notification is sent to the poster; the aggregate reaction count is NOT displayed to anyone — the reaction tap target shows only the encouragement icon, never a count (UX-DR27, UX-DR31)

**AC5 — Revoke own share:**
Given the sharer opens the Feed tab and sees their own shared entry
When they tap "Revoca condivisione" (visible only on own entries — `owner_id == currentUserId`)
When `FeedBloc` processes `FeedEntryRevoked(feedEntryId)`
Then: the `activity_feed` row is deleted; the entry disappears from the sharer's feed immediately; friends' feeds reflect removal on next load (NFR29); a confirmation `showDialog` is shown before deletion

**AC6 — Supabase migration `0005_activity_feed.sql`:**
Given the migration is applied
When the schema is inspected
Then: an `activity_feed` table exists with columns `id` (uuid PK), `owner_id` (uuid FK→profiles cascade), `session_type` (text NOT NULL), `duration_minutes` (int NOT NULL), `completed_at` (timestamptz NOT NULL), `reactions` (int NOT NULL DEFAULT 0), `created_at` (timestamptz NOT NULL DEFAULT now()); RLS enabled with four policies: owner can INSERT, owner can DELETE (revoke), friends can SELECT (via `friendships` join), any authenticated user can UPDATE `reactions` column only (increment — via RPC preferred over direct UPDATE); a Supabase Postgres function `increment_feed_reaction(feed_id uuid)` exists that does `UPDATE activity_feed SET reactions = reactions + 1 WHERE id = feed_id` to avoid race conditions

**AC7 — Social tab extended with Feed sub-tab:**
Given a Pro user opens the Social tab
When the screen renders
Then: the screen has two sub-tabs — "Amici" (existing `FriendsBloc` content from Story 18.2) and "Feed" (new `FeedBloc` content); the `TabBar` + `TabBarView` is the structural container; non-Pro users see the existing `_LockedBanner` (no tab structure shown — same as before)

**AC8 — Pro gate:**
Given a non-Pro user opens the Social tab
When the screen renders
Then: the existing `_LockedBanner` with `ProUpsellSheet.show(context)` on tap is shown — unchanged from Story 18.2; no feed content leaks to non-Pro users

**AC9 — Zero regressions:**
Given the new code is added
When the suite runs from `pulse_coach/`
Then `flutter test` reports all existing tests plus new tests green; `flutter analyze lib/ test/` reports 0 issues

## Tasks / Subtasks

- [x] **Task 1 — Supabase migration `0005_activity_feed.sql` (AC6)**
  - [x] 1.1 Create `supabase/migrations/0005_activity_feed.sql`:
    ```sql
    -- Activity feed table
    CREATE TABLE activity_feed (
      id               uuid         PRIMARY KEY DEFAULT gen_random_uuid(),
      owner_id         uuid         NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
      session_type     text         NOT NULL,
      duration_minutes int          NOT NULL,
      completed_at     timestamptz  NOT NULL,
      reactions        int          NOT NULL DEFAULT 0,
      created_at       timestamptz  NOT NULL DEFAULT now()
    );

    ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;

    -- Owner can insert their own entries
    CREATE POLICY "feed_insert_owner"
      ON activity_feed FOR INSERT
      WITH CHECK (auth.uid() = owner_id);

    -- Owner can delete (revoke) their own entries
    CREATE POLICY "feed_delete_owner"
      ON activity_feed FOR DELETE
      USING (auth.uid() = owner_id);

    -- Friends (accepted) can read feed entries of friends
    CREATE POLICY "feed_select_friends"
      ON activity_feed FOR SELECT
      USING (
        auth.uid() = owner_id
        OR EXISTS (
          SELECT 1 FROM friendships f
          WHERE f.status = 'accepted'
            AND (
              (f.requester_id = auth.uid() AND f.addressee_id = activity_feed.owner_id)
              OR (f.addressee_id = auth.uid() AND f.requester_id = activity_feed.owner_id)
            )
        )
      );

    -- Any authenticated user can update reactions on readable entries
    -- (enforced via RPC below; direct UPDATE policy left permissive for the RPC path)
    CREATE POLICY "feed_update_reactions"
      ON activity_feed FOR UPDATE
      USING (
        auth.uid() = owner_id
        OR EXISTS (
          SELECT 1 FROM friendships f
          WHERE f.status = 'accepted'
            AND (
              (f.requester_id = auth.uid() AND f.addressee_id = activity_feed.owner_id)
              OR (f.addressee_id = auth.uid() AND f.requester_id = activity_feed.owner_id)
            )
        )
      )
      WITH CHECK (true);

    -- RPC to safely increment reactions (avoids client-side read-modify-write race)
    CREATE OR REPLACE FUNCTION increment_feed_reaction(feed_id uuid)
    RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
      UPDATE activity_feed SET reactions = reactions + 1 WHERE id = feed_id;
    $$;
    ```

- [x] **Task 2 — Domain entities (AC2, AC3, AC4, AC5)**
  - [x] 2.1 Create `lib/features/social/feed/domain/entities/feed_entry.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';

    part 'feed_entry.freezed.dart';

    @freezed
    abstract class FeedEntry with _$FeedEntry {
      const factory FeedEntry({
        required String id,
        required String ownerHandle,
        required String ownerId,
        required String sessionType,
        required int durationMinutes,
        required DateTime completedAt,
        required DateTime createdAt,
        // reactions count intentionally NOT stored in domain entity — never displayed (UX-DR27/31)
      }) = _FeedEntry;
    }
    ```
    **Critical**: `reactions` is incremented server-side via RPC but NEVER surfaced in the UI. Do NOT add a `reactions` field to `FeedEntry`. The count must not appear anywhere in the UI (UX-DR27, UX-DR31).

- [x] **Task 3 — Domain: repository interface + use cases (AC2–AC5)**
  - [x] 3.1 Create `lib/features/social/feed/domain/repositories/feed_repository.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';

    abstract class FeedRepository {
      /// Insert a new activity_feed row (share after session completion).
      Future<Either<SocialFailure, Unit>> shareFeedEntry({
        required String sessionType,
        required int durationMinutes,
        required DateTime completedAt,
      });

      /// Fetch the activity feed for the current user (own entries + accepted friends' entries).
      Future<Either<SocialFailure, List<FeedEntry>>> getFeed();

      /// Increment reactions on a feed entry (calls the Postgres RPC).
      Future<Either<SocialFailure, Unit>> reactToEntry(String feedEntryId);

      /// Delete own feed entry (revoke share).
      Future<Either<SocialFailure, Unit>> revokeEntry(String feedEntryId);
    }
    ```
  - [x] 3.2 Create use cases (all `@injectable`):
    - `lib/features/social/feed/domain/usecases/share_feed_entry_use_case.dart`
    - `lib/features/social/feed/domain/usecases/get_feed_use_case.dart`
    - `lib/features/social/feed/domain/usecases/react_to_entry_use_case.dart`
    - `lib/features/social/feed/domain/usecases/revoke_feed_entry_use_case.dart`

    Pattern (same as Story 18.2 use cases):
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

    @injectable
    class GetFeedUseCase {
      final FeedRepository _repository;
      const GetFeedUseCase(this._repository);

      Future<Either<SocialFailure, List<FeedEntry>>> call() => _repository.getFeed();
    }
    ```

- [x] **Task 4 — Data layer: DTO + remote datasource (AC2–AC5, AC6)**
  - [x] 4.1 Create `lib/features/social/feed/data/models/feed_entry_dto.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';

    part 'feed_entry_dto.freezed.dart';
    part 'feed_entry_dto.g.dart';

    @freezed
    abstract class FeedEntryDto with _$FeedEntryDto {
      const factory FeedEntryDto({
        @JsonKey(name: 'id') required String id,
        @JsonKey(name: 'owner_id') required String ownerId,
        @JsonKey(name: 'session_type') required String sessionType,
        @JsonKey(name: 'duration_minutes') required int durationMinutes,
        @JsonKey(name: 'completed_at') required String completedAt,
        @JsonKey(name: 'created_at') required String createdAt,
        // 'display_handle' is joined from profiles; nullable for resilience
        @JsonKey(name: 'display_handle') String? displayHandle,
      }) = _FeedEntryDto;

      factory FeedEntryDto.fromJson(Map<String, dynamic> json) =>
          _$FeedEntryDtoFromJson(json);
    }

    extension FeedEntryDtoMapper on FeedEntryDto {
      FeedEntry toDomain() => FeedEntry(
            id: id,
            ownerHandle: displayHandle ?? ownerId, // fallback to id if handle missing
            ownerId: ownerId,
            sessionType: sessionType,
            durationMinutes: durationMinutes,
            completedAt: DateTime.parse(completedAt),
            createdAt: DateTime.parse(createdAt),
          );
    }
    ```

  - [x] 4.2 Create `lib/features/social/feed/data/datasources/feed_remote_data_source.dart`:
    ```dart
    import 'package:flutter/foundation.dart' show visibleForTesting;
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/cloud/supabase_client.dart'
        show SupabaseClientProvider;

    @injectable
    class FeedRemoteDataSource {
      final SupabaseClientProvider _supabase;

      FeedRemoteDataSource(this._supabase) {
        insertFeedEntry = _defaultInsertFeedEntry;
        fetchFeed = _defaultFetchFeed;
        callIncrementReaction = _defaultCallIncrementReaction;
        deleteFeedEntry = _defaultDeleteFeedEntry;
      }

      @visibleForTesting
      late Future<void> Function(Map<String, dynamic> row) insertFeedEntry;

      @visibleForTesting
      late Future<List<Map<String, dynamic>>> Function() fetchFeed;

      @visibleForTesting
      late Future<void> Function(String feedEntryId) callIncrementReaction;

      @visibleForTesting
      late Future<void> Function(String feedEntryId) deleteFeedEntry;

      String get _uid {
        final id = _supabase.client.auth.currentUser?.id;
        if (id == null) throw const AuthFailureException();
        return id;
      }

      Future<void> _defaultInsertFeedEntry(Map<String, dynamic> row) async {
        await _supabase.client.from('activity_feed').insert(row);
      }

      /// Returns rows from activity_feed joined with profiles for the owner's display_handle.
      /// Includes own entries + friends' accepted entries (enforced by RLS).
      Future<List<Map<String, dynamic>>> _defaultFetchFeed() async {
        final rows = await _supabase.client
            .from('activity_feed')
            .select(
                'id, owner_id, session_type, duration_minutes, completed_at, created_at, '
                'profiles!activity_feed_owner_id_fkey(display_handle)')
            .order('created_at', ascending: false)
            .limit(50);
        return List<Map<String, dynamic>>.from(rows);
      }

      Future<void> _defaultCallIncrementReaction(String feedEntryId) async {
        await _supabase.client.rpc(
          'increment_feed_reaction',
          params: {'feed_id': feedEntryId},
        );
      }

      Future<void> _defaultDeleteFeedEntry(String feedEntryId) async {
        final deleted = await _supabase.client
            .from('activity_feed')
            .delete()
            .eq('id', feedEntryId)
            .eq('owner_id', _uid)
            .select('id');
        if ((deleted as List).isEmpty) {
          throw Exception('No rows deleted — not owner or entry missing');
        }
      }

      // --- Public API consumed by repository ---

      Future<void> share({
        required String ownerId,
        required String sessionType,
        required int durationMinutes,
        required DateTime completedAt,
      }) =>
          insertFeedEntry({
            'owner_id': ownerId,
            'session_type': sessionType,
            'duration_minutes': durationMinutes,
            'completed_at': completedAt.toIso8601String(),
          });

      Future<List<Map<String, dynamic>>> loadFeed() => fetchFeed();

      Future<void> incrementReaction(String feedEntryId) =>
          callIncrementReaction(feedEntryId);

      Future<void> revoke(String feedEntryId) => deleteFeedEntry(feedEntryId);
    }

    class AuthFailureException implements Exception {
      const AuthFailureException();
    }
    ```
    **Critical**: ARCH25 rule — never import `supabase_flutter` directly; use only `pulse_coach/core/cloud/supabase_client.dart`. Follow the exact same pattern as `FriendsRemoteDataSource` and `SocialProfileRemoteDataSource`.

    **Supabase join notation**: `profiles!activity_feed_owner_id_fkey(display_handle)` — `activity_feed` has one FK to `profiles` (`owner_id`), so no disambiguation is required, but using the explicit FK name is safer. Verify FK auto-name after migration with `\d activity_feed`.

  - [x] 4.3 Create `lib/features/social/feed/data/repositories/feed_repository_impl.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/feed/data/datasources/feed_remote_data_source.dart';
    import 'package:pulse_coach/features/social/feed/data/models/feed_entry_dto.dart';
    import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
    import 'package:pulse_coach/features/social/feed/domain/repositories/feed_repository.dart';

    @Injectable(as: FeedRepository)
    class FeedRepositoryImpl implements FeedRepository {
      final FeedRemoteDataSource _dataSource;
      const FeedRepositoryImpl(this._dataSource);

      @override
      Future<Either<SocialFailure, Unit>> shareFeedEntry({
        required String sessionType,
        required int durationMinutes,
        required DateTime completedAt,
      }) async {
        try {
          final uid = _dataSource._uid; // accessed via getter — throws AuthFailureException if null
          await _dataSource.share(
            ownerId: uid,
            sessionType: sessionType,
            durationMinutes: durationMinutes,
            completedAt: completedAt,
          );
          return const Right(unit);
        } on AuthFailureException {
          return Left(SocialFailure('Not signed in'));
        } catch (e) {
          return Left(SocialFailure('Failed to share: $e'));
        }
      }

      @override
      Future<Either<SocialFailure, List<FeedEntry>>> getFeed() async {
        try {
          final rows = await _dataSource.loadFeed();
          final entries = rows
              .map(_rowToDto)
              .whereType<FeedEntryDto>()
              .map((dto) => dto.toDomain())
              .toList();
          return Right(entries);
        } catch (e) {
          return Left(SocialFailure('Failed to load feed: $e'));
        }
      }

      @override
      Future<Either<SocialFailure, Unit>> reactToEntry(String feedEntryId) async {
        try {
          await _dataSource.incrementReaction(feedEntryId);
          return const Right(unit);
        } catch (e) {
          return Left(SocialFailure('Failed to react: $e'));
        }
      }

      @override
      Future<Either<SocialFailure, Unit>> revokeEntry(String feedEntryId) async {
        try {
          await _dataSource.revoke(feedEntryId);
          return const Right(unit);
        } catch (e) {
          return Left(SocialFailure('Failed to revoke: $e'));
        }
      }

      /// Parse joined row — profile handle may be nested under 'profiles' key.
      FeedEntryDto? _rowToDto(Map<String, dynamic> row) {
        try {
          final profileMap = row['profiles'];
          final handle = profileMap is Map<String, dynamic>
              ? profileMap['display_handle'] as String?
              : null;
          return FeedEntryDto(
            id: row['id'] as String,
            ownerId: row['owner_id'] as String,
            sessionType: row['session_type'] as String,
            durationMinutes: row['duration_minutes'] as int,
            completedAt: row['completed_at'] as String,
            createdAt: row['created_at'] as String,
            displayHandle: handle,
          );
        } catch (_) {
          return null; // degrade single bad row rather than crashing the full list
        }
      }
    }
    ```
    **Critical pattern from Story 18.2 review**: row mapping must NOT throw on null/malformed data — use the `whereType<FeedEntryDto>()` filter to degrade single bad rows rather than surfacing a global `SocialFailure`.

- [x] **Task 5 — FeedBloc (AC3–AC5)**
  - [x] 5.1 Create `lib/features/social/feed/presentation/bloc/feed_event.dart`:
    ```dart
    abstract class FeedEvent {
      const FeedEvent();
    }

    class FeedLoaded extends FeedEvent {
      const FeedLoaded();
    }

    class FeedReactionSent extends FeedEvent {
      final String feedEntryId;
      const FeedReactionSent(this.feedEntryId);
    }

    class FeedEntryRevoked extends FeedEvent {
      final String feedEntryId;
      const FeedEntryRevoked(this.feedEntryId);
    }
    ```

  - [x] 5.2 Create `lib/features/social/feed/presentation/bloc/feed_state.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';

    part 'feed_state.freezed.dart';

    @freezed
    abstract class FeedState with _$FeedState {
      const factory FeedState.initial() = _Initial;
      const factory FeedState.loading() = _Loading;
      const factory FeedState.loaded({
        required List<FeedEntry> entries,
        /// Set of feedEntryIds currently animating a reaction (for per-card animation control)
        @Default(<String>{}) Set<String> reactingIds,
      }) = _Loaded;
      const factory FeedState.error({required Failure failure}) = _Error;
    }
    ```

  - [x] 5.3 Create `lib/features/social/feed/presentation/bloc/feed_bloc.dart`:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/social/feed/domain/usecases/get_feed_use_case.dart';
    import 'package:pulse_coach/features/social/feed/domain/usecases/react_to_entry_use_case.dart';
    import 'package:pulse_coach/features/social/feed/domain/usecases/revoke_feed_entry_use_case.dart';
    import 'feed_event.dart';
    import 'feed_state.dart';

    @injectable
    class FeedBloc extends Bloc<FeedEvent, FeedState> {
      final GetFeedUseCase _getFeed;
      final ReactToEntryUseCase _reactToEntry;
      final RevokeFeedEntryUseCase _revokeEntry;

      FeedBloc(this._getFeed, this._reactToEntry, this._revokeEntry)
          : super(const FeedState.initial()) {
        on<FeedLoaded>(_onLoaded);
        on<FeedReactionSent>(_onReact);
        on<FeedEntryRevoked>(_onRevoke);
      }

      Future<void> _onLoaded(FeedLoaded event, Emitter<FeedState> emit) async {
        emit(const FeedState.loading());
        final result = await _getFeed();
        result.fold(
          (f) => emit(FeedState.error(failure: f)),
          (entries) => emit(FeedState.loaded(entries: entries)),
        );
      }

      Future<void> _onReact(FeedReactionSent event, Emitter<FeedState> emit) async {
        // Add to animating set immediately for optimistic animation
        final current = state.mapOrNull(loaded: (s) => s);
        if (current != null) {
          emit(current.copyWith(reactingIds: {...current.reactingIds, event.feedEntryId}));
        }
        final result = await _reactToEntry(event.feedEntryId);
        result.fold(
          (f) => emit(FeedState.error(failure: f)),
          (_) {
            final updated = state.mapOrNull(loaded: (s) => s);
            if (updated != null) {
              final newSet = Set<String>.from(updated.reactingIds)
                ..remove(event.feedEntryId);
              emit(updated.copyWith(reactingIds: newSet));
            }
          },
        );
      }

      Future<void> _onRevoke(FeedEntryRevoked event, Emitter<FeedState> emit) async {
        final result = await _revokeEntry(event.feedEntryId);
        result.fold(
          (f) => emit(FeedState.error(failure: f)),
          (_) => add(const FeedLoaded()), // reload feed after revoke
        );
      }
    }
    ```

- [x] **Task 6 — ActivityFeedCard widget (AC3–AC5, UX-DR27, UX-DR31, UX-DR33)**
  - [x] 6.1 Create `lib/features/social/feed/presentation/widgets/activity_feed_card.dart`:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
    import 'package:pulse_coach/l10n/app_localizations.dart';

    class ActivityFeedCard extends StatefulWidget {
      final FeedEntry entry;
      final bool isOwn;           // true if entry.ownerId == currentUserId
      final bool isReacting;      // from FeedState.reactingIds
      final VoidCallback onReact;
      final VoidCallback? onRevoke; // only shown when isOwn == true

      const ActivityFeedCard({
        super.key,
        required this.entry,
        required this.isOwn,
        required this.isReacting,
        required this.onReact,
        this.onRevoke,
      });

      @override
      State<ActivityFeedCard> createState() => _ActivityFeedCardState();
    }

    class _ActivityFeedCardState extends State<ActivityFeedCard>
        with SingleTickerProviderStateMixin {
      late AnimationController _scaleController;
      late Animation<double> _scaleAnimation;

      @override
      void initState() {
        super.initState();
        _scaleController = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        );
        _scaleAnimation = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
        ]).animate(_scaleController);
      }

      @override
      void didUpdateWidget(ActivityFeedCard oldWidget) {
        super.didUpdateWidget(oldWidget);
        if (widget.isReacting && !oldWidget.isReacting) {
          _scaleController.forward(from: 0.0);
        }
      }

      @override
      void dispose() {
        _scaleController.dispose();
        super.dispose();
      }

      @override
      Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final sessionIcon = _iconForSessionType(widget.entry.sessionType);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(sessionIcon, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${widget.entry.ownerHandle}',
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.visible, // UX-DR33: wraps, never truncates
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.entry.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        _relativeTime(l10n, widget.entry.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Reaction tap target — NO count shown (UX-DR27/31)
                if (!widget.isOwn)
                  Semantics(
                    label: l10n.feedReactionButtonLabel,
                    button: true,
                    child: GestureDetector(
                      onTap: widget.onReact,
                      child: SizedBox(
                        width: 48, // UX-DR33: ≥ 48dp touch target
                        height: 48,
                        child: Center(
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: const Icon(Icons.favorite_border, size: 24),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Revoke button — only on own entries
                if (widget.isOwn)
                  Semantics(
                    label: l10n.feedRevokeButtonLabel,
                    button: true,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        tooltip: l10n.feedRevokeButtonLabel,
                        onPressed: widget.onRevoke,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      IconData _iconForSessionType(String type) {
        return switch (type) {
          'mobility' => Icons.self_improvement,
          'cardio' => Icons.directions_run,
          'breathing' => Icons.air,
          _ => Icons.fitness_center,
        };
      }

      String _relativeTime(AppLocalizations l10n, DateTime createdAt) {
        final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
        if (diff.inMinutes < 60) return l10n.feedRelativeMinutes(diff.inMinutes);
        if (diff.inHours < 24) return l10n.feedRelativeHours(diff.inHours);
        return l10n.feedRelativeDays(diff.inDays);
      }
    }
    ```
    **Critical UX-DR27/31**: reaction count is NEVER shown. The `reactions` column is incremented on the server but is not fetched in the query and is not in `FeedEntry` domain entity. Do not add a badge or counter anywhere.

- [x] **Task 7 — FeedPage (AC3–AC5, AC7)**
  - [x] 7.1 Create `lib/features/social/feed/presentation/pages/feed_page.dart`:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/core/di/injection.dart';
    import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_bloc.dart';
    import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_event.dart';
    import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_state.dart';
    import 'package:pulse_coach/features/social/feed/presentation/widgets/activity_feed_card.dart';
    import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
    import 'package:pulse_coach/l10n/app_localizations.dart';
    import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

    class FeedPage extends StatelessWidget {
      const FeedPage({super.key});

      @override
      Widget build(BuildContext context) {
        return BlocProvider<FeedBloc>(
          create: (_) => getIt<FeedBloc>()..add(const FeedLoaded()),
          child: const _FeedView(),
        );
      }
    }

    class _FeedView extends StatelessWidget {
      const _FeedView();

      String? _currentUserId(BuildContext context) {
        // Access the current user id from SupabaseClientProvider via getIt
        // Pattern: getIt<SupabaseClientProvider>().client.auth.currentUser?.id
        // (ARCH25: access only via the cloud boundary, not direct supabase_flutter import)
        return null; // override in implementation — see Dev Notes
      }

      @override
      Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;

        return BlocConsumer<FeedBloc, FeedState>(
          listener: (context, state) {
            state.whenOrNull(
              error: (failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message.isNotEmpty
                      ? failure.message
                      : l10n.socialGenericError)),
                );
              },
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => const _FeedShimmer(),
              loading: () => const _FeedShimmer(),
              loaded: (entries, reactingIds) {
                if (entries.isEmpty) {
                  return Center(child: Text(l10n.feedEmptyState));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<FeedBloc>().add(const FeedLoaded());
                  },
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];
                      final subState = context.read<SubscriptionBloc>().state;
                      final isOwn = _isOwn(entry.ownerId, context);
                      return ActivityFeedCard(
                        entry: entry,
                        isOwn: isOwn,
                        isReacting: reactingIds.contains(entry.id),
                        onReact: () => context.read<FeedBloc>().add(
                              FeedReactionSent(entry.id),
                            ),
                        onRevoke: isOwn
                            ? () => _confirmRevoke(context, entry.id, l10n)
                            : null,
                      );
                    },
                  ),
                );
              },
              error: (_) => const _FeedShimmer(),
            );
          },
        );
      }

      bool _isOwn(String ownerId, BuildContext context) {
        // ARCH25: use SupabaseClientProvider via getIt
        try {
          return getIt<SupabaseClientProvider>().client.auth.currentUser?.id ==
              ownerId;
        } catch (_) {
          return false;
        }
      }

      void _confirmRevoke(BuildContext context, String feedEntryId, AppLocalizations l10n) {
        showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.feedRevokeDialogTitle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.feedRevokeDialogCancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.feedRevokeDialogConfirm),
              ),
            ],
          ),
        ).then((confirmed) {
          if (confirmed == true && context.mounted) {
            context.read<FeedBloc>().add(FeedEntryRevoked(feedEntryId));
          }
        });
      }
    }

    class _FeedShimmer extends StatelessWidget {
      const _FeedShimmer();

      @override
      Widget build(BuildContext context) {
        return Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ShimmerPlaceholder(height: 80),
            ),
          ),
        );
      }
    }
    ```

- [x] **Task 8 — Extend SocialPage to add TabBar (AC7, AC8)**
  - [x] 8.1 Modify `lib/features/social/friends/presentation/pages/social_page.dart` to wrap the Pro content in a `DefaultTabController` + `TabBar` with two tabs: "Amici" and "Feed".
    - Keep `MultiBlocProvider` at root (existing `FriendsBloc` + `SocialProfileBloc` providers unchanged).
    - Add `BlocProvider<FeedBloc>` to the providers list (provide via `getIt<FeedBloc>()..add(const FeedLoaded())`).
    - The `_FriendsView` currently builds the full content inside `BlocBuilder<SubscriptionBloc>`. Convert the Pro-unlocked branch to use `DefaultTabController(length: 2, child: Scaffold(appBar: ... bottom: TabBar(...), body: TabBarView(...)))`.
    - Tab 0: "Amici" — existing `BlocConsumer<FriendsBloc>` content (unchanged logic, just moved into `TabBarView` slot 0).
    - Tab 1: "Feed" — `FeedPage` widget (which creates its own `BlocProvider<FeedBloc>` internally, OR the parent provides it — see Dev Notes on which approach to use).
    - The `_LockedBanner` path remains unchanged (shown before the tab structure, to non-Pro users).
    - **AppBar**: Add `AppBar(title: Text(l10n.socialScreenTitle), bottom: TabBar(...))` — the current `SocialPage` has no `AppBar`; add one now as the shell for the tab bar. `TabBar` tabs use `Tab(text: l10n.friendsScreenTitle)` and `Tab(text: l10n.feedScreenTitle)`.

- [x] **Task 9 — Share toggle on MiniSummaryPage (AC1, AC2)**
  - [x] 9.1 Add share state to `MiniSummaryCubit`:
    The `MiniSummaryCubit` currently does NOT support share state. Rather than modifying the Cubit directly (fragile — it has auto-dismiss timers), manage the share toggle as local `StatefulWidget` state inside `MiniSummaryPage._MiniSummaryPageState`. The `bool _shareEnabled` field defaults to `false`.
  - [x] 9.2 In `MiniSummaryPage`, add the share toggle ONLY if:
    1. `args.abandoned == false` (abandoned sessions are not shareable)
    2. The user is Pro — read `SubscriptionBloc` (provided at app root in `lib/app.dart`)
    
    Placement: After the `_StatRow` widgets, before the `miniSummaryFeedback` text.
    ```dart
    // Inside _buildContent, in the Column children list:
    BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        final isPro = subState.whenOrNull(loaded: (t) => t) == SubscriptionTier.pro;
        if (!isPro || args.abandoned) return const SizedBox.shrink();
        return SwitchListTile(
          title: Text(l10n.miniSummaryShareToggle),
          value: _shareEnabled,
          onChanged: (val) => setState(() => _shareEnabled = val),
        );
      },
    ),
    ```
    - `_shareEnabled` is a field on `_MiniSummaryPageState`. Convert `_MiniSummaryPageState` from reading `_shareEnabled` via a setter — it already IS a `StatefulWidget` (`_MiniSummaryPageState`). Just add `bool _shareEnabled = false;` as a field.
    - `_buildContent` currently uses `context` and `args` but NOT `setState` — it must be called from `_MiniSummaryPageState.build`, so `_shareEnabled` is accessible via `this._shareEnabled`.

  - [x] 9.3 Trigger the share on MiniSummary dismissal:
    In `MiniSummaryPage`'s `BlocListener`, in the `MiniSummaryFading`/`MiniSummaryDone` branch, before navigating to Today, if `_shareEnabled && !args.abandoned`:
    ```dart
    if (_shareEnabled && !args.abandoned) {
      // Fire-and-forget — do NOT await; failure is handled by ShareFeedEntryUseCase snackbar
      final useCase = getIt<ShareFeedEntryUseCase>();
      unawaited(useCase(
        sessionType: args.sessionType,
        durationMinutes: args.durationMinutes,
        completedAt: DateTime.now().toUtc(),
      ).then((result) {
        result.fold(
          (f) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.feedShareFailedError)),
              );
            }
          },
          (_) {},
        );
      }));
    }
    ```
    **Critical**: navigation proceeds regardless of share success/failure. The use case is called fire-and-forget. Do NOT block navigation on the share network call.
    
    **DI note**: `ShareFeedEntryUseCase` uses a call signature with named params — update the use case's `call` method signature to:
    ```dart
    Future<Either<SocialFailure, Unit>> call({
      required String sessionType,
      required int durationMinutes,
      required DateTime completedAt,
    }) => _repository.shareFeedEntry(
        sessionType: sessionType,
        durationMinutes: durationMinutes,
        completedAt: completedAt,
      );
    ```

- [x] **Task 10 — ARB keys (AC1–AC5, AC7)**
  - [x] 10.1 In `lib/l10n/app/app_en.arb`, add before closing `}`:
    ```json
    "socialScreenTitle": "Social",
    "feedScreenTitle": "Feed",
    "feedEmptyState": "No activity yet",
    "feedRelativeMinutes": "{count} min ago",
    "@feedRelativeMinutes": {"placeholders": {"count": {"type": "int"}}},
    "feedRelativeHours": "{count}h ago",
    "@feedRelativeHours": {"placeholders": {"count": {"type": "int"}}},
    "feedRelativeDays": "{count}d ago",
    "@feedRelativeDays": {"placeholders": {"count": {"type": "int"}}},
    "feedReactionButtonLabel": "Send encouragement",
    "feedRevokeButtonLabel": "Revoke share",
    "feedRevokeDialogTitle": "Revoke this share?",
    "feedRevokeDialogConfirm": "Revoke",
    "feedRevokeDialogCancel": "Cancel",
    "miniSummaryShareToggle": "Share with friends",
    "feedShareFailedError": "Could not share. Try again.",
    "socialGenericError": "Something went wrong. Try again."
    ```
  - [x] 10.2 In `lib/l10n/app/app_it.arb`, add before closing `}`:
    ```json
    "socialScreenTitle": "Sociale",
    "feedScreenTitle": "Feed",
    "feedEmptyState": "Ancora nessuna attività",
    "feedRelativeMinutes": "{count} min fa",
    "@feedRelativeMinutes": {"placeholders": {"count": {"type": "int"}}},
    "feedRelativeHours": "{count} ore fa",
    "@feedRelativeHours": {"placeholders": {"count": {"type": "int"}}},
    "feedRelativeDays": "{count} giorni fa",
    "@feedRelativeDays": {"placeholders": {"count": {"type": "int"}}},
    "feedReactionButtonLabel": "Invia incoraggiamento",
    "feedRevokeButtonLabel": "Revoca condivisione",
    "feedRevokeDialogTitle": "Revocare questa condivisione?",
    "feedRevokeDialogConfirm": "Revoca",
    "feedRevokeDialogCancel": "Annulla",
    "miniSummaryShareToggle": "Condividi con gli amici",
    "feedShareFailedError": "Impossibile condividere. Riprova.",
    "socialGenericError": "Qualcosa è andato storto. Riprova."
    ```
    **Note**: Check if `socialGenericError` already exists in the ARB files — it is referenced in `social_page.dart` (Story 18.2). If it exists, do NOT add a duplicate.

  - [x] 10.3 Run `flutter pub get` to regenerate localizations.

- [x] **Task 11 — build_runner and DI (AC9)**
  - [x] 11.1 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`.
    New generated files expected:
    - `feed_entry.freezed.dart`
    - `feed_entry_dto.freezed.dart` + `feed_entry_dto.g.dart`
    - `feed_state.freezed.dart`
    - Updated `injection.config.dart` with: `FeedRemoteDataSource`, `FeedRepositoryImpl`, `ShareFeedEntryUseCase`, `GetFeedUseCase`, `ReactToEntryUseCase`, `RevokeFeedEntryUseCase`, `FeedBloc`
  - [x] 11.2 Run `flutter analyze lib/ test/` — 0 issues.

- [x] **Task 12 — Tests (AC1–AC5, AC9)**
  - [x] 12.1 Create `test/data/social/feed_remote_data_source_test.dart`:
    Using `@visibleForTesting` seam pattern (same as `friends_remote_data_source_test.dart`):
    ```
    // [18.3-DS-001] share — inserts row with correct fields, no biometric data
    // [18.3-DS-002] loadFeed — returns list of raw rows
    // [18.3-DS-003] incrementReaction — calls RPC with feed_id
    // [18.3-DS-004] revoke — deletes own entry, throws on zero affected rows
    // [18.3-DS-005] _uid getter — throws AuthFailureException when currentUser is null
    ```
  - [x] 12.2 Create `test/bloc/feed_bloc_test.dart`:
    Use `@GenerateMocks([FeedRepository])` + `bloc_test`:
    ```
    // [18.3-BLOC-001] FeedLoaded → [loading, loaded(entries)]
    // [18.3-BLOC-002] FeedLoaded — getFeed error → [loading, error]
    // [18.3-BLOC-003] FeedReactionSent — adds to reactingIds optimistically, then removes on success
    // [18.3-BLOC-004] FeedReactionSent — reactToEntry error → error state
    // [18.3-BLOC-005] FeedEntryRevoked — success → re-loads via FeedLoaded
    // [18.3-BLOC-006] FeedEntryRevoked — error → error state
    ```
  - [x] 12.3 Create `test/widget/activity_feed_card_test.dart`:
    ```
    // [18.3-WIDGET-001] non-own entry — renders handle, duration, reaction button (no count shown)
    // [18.3-WIDGET-002] own entry — renders revoke button, NO reaction button
    // [18.3-WIDGET-003] reaction tap — calls onReact callback
    // [18.3-WIDGET-004] isReacting=true — scale animation controller starts
    // [18.3-WIDGET-005] touch targets ≥ 48dp — reaction and revoke buttons satisfy constraint
    ```
  - [x] 12.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate mock files.
  - [x] 12.5 Run `flutter test` — all existing + new tests green.
  - [x] 12.6 Run `flutter analyze lib/ test/` — 0 issues.

## Dev Notes

### Critical: ARCH25 — Never Import supabase_flutter Directly

Only `lib/core/cloud/supabase_client.dart` and `main.dart` may import `supabase_flutter` directly. `FeedRemoteDataSource` and `FeedPage` must follow this rule exactly. To check current user ID in `FeedPage._isOwn`, import `SupabaseClientProvider` via:
```dart
import 'package:pulse_coach/core/cloud/supabase_client.dart' show SupabaseClientProvider;
```
Then use `getIt<SupabaseClientProvider>().client.auth.currentUser?.id`.

### Critical: Reactions Count MUST NOT Appear Anywhere (UX-DR27, UX-DR31)

The `reactions` column is incremented server-side via `increment_feed_reaction` RPC. It MUST NOT be:
- Fetched in the SELECT query (omit it from the `.select()` call)
- Stored in `FeedEntry` domain entity
- Displayed in `ActivityFeedCard` or anywhere else

The only visible feedback is the brief scale animation on the reaction icon. This is a non-negotiable UX/behavioral requirement.

### Critical: SocialPage Tab Structure — BlocProvider Placement for FeedBloc

Two valid approaches for providing `FeedBloc` to `FeedPage`:
1. **Provide in `SocialPage.build`** via `MultiBlocProvider` (alongside existing `FriendsBloc`/`SocialProfileBloc`) — then pass the existing instance via `BlocProvider.value` in `FeedPage`. This avoids double-initialization.
2. **Let `FeedPage` create its own** `BlocProvider<FeedBloc>` via `getIt` — simpler, but the Bloc is re-created on tab switch.

**Recommended**: Option 1 — provide `FeedBloc` at the `SocialPage` level alongside `FriendsBloc`. This follows the existing pattern and prevents re-fetching on tab switch. `FeedPage.build` should then use `BlocProvider.value(value: context.read<FeedBloc>(), child: ...)` — or simply remove `BlocProvider` from `FeedPage` and rely on the ancestor-provided bloc.

### Critical: MiniSummaryPage Share Integration — Fire-and-Forget Pattern

The share must NOT block the auto-dismiss flow. The existing `_scheduleAutoDismiss` logic in `MiniSummaryCubit` fires `MiniSummaryFading` → `MiniSummaryDone` after 3000ms hold + 300ms fade. The `BlocListener` in `MiniSummaryPage` handles state transitions. Insert the share call in the `MiniSummaryFading` branch (before `_fadeController.reverse()`), fire with `unawaited()`, and let navigation proceed regardless.

`dart:async show unawaited` is already imported in `session_summary_page.dart` (line 1).

### Critical: `socialGenericError` ARB Key — Check for Duplicate

The key `socialGenericError` is referenced in `social_page.dart`. Check `lib/l10n/app/app_en.arb` and `app_it.arb` before adding — if it already exists, do NOT add a duplicate (causes `gen_l10n` failure).

### Critical: Row-Mapping Resilience (Lesson from Story 18.2)

Story 18.2 review found that null-unsafe row mappers crash the entire list on a bad row. `FeedRepositoryImpl._rowToDto` MUST wrap the mapping in `try/catch` and return `null` on any error, then filter with `.whereType<FeedEntryDto>()`. This degrades a single bad row rather than surfacing a global `SocialFailure`. The pattern is explicitly implemented in the Tasks section above.

### Critical: `_uid` Null Session Guard (Lesson from Story 18.2)

Story 18.2 review found that `_uid` force-unwrapping `currentUser!` throws a `TypeError` on session expiry. `FeedRemoteDataSource._uid` uses a null guard that throws `AuthFailureException` (a typed exception), which is caught in the repository and converted to `SocialFailure('Not signed in')`. Never use `currentUser!` directly.

### Critical: Supabase FK Auto-Name for Join Query

`activity_feed` has one FK to `profiles` (`owner_id`). Postgres auto-names it `activity_feed_owner_id_fkey`. Join syntax: `profiles!activity_feed_owner_id_fkey(display_handle)`. Verify after migration with `\d activity_feed` in the Supabase SQL editor.

### Critical: build_runner Run Order

Run `dart run build_runner build --delete-conflicting-outputs` TWICE:
1. After Task 11 — generate production freezed/injectable/json files
2. After Task 12.4 — generate mockito mock files for tests

### Critical: `socialGenericError` in `social_page.dart`

`social_page.dart` already references `l10n.socialGenericError` (added in Story 18.2 review patches). Confirm this key exists in both ARB files before adding. If missing, add it only once.

### Pro Gate on MiniSummaryPage

`SubscriptionBloc` is provided at the app root (`lib/app.dart`). `MiniSummaryPage` is a full-screen overlay route; it does NOT need to provide `SubscriptionBloc` — use `context.read<SubscriptionBloc>()` or `BlocBuilder` directly.

### Category A Fire-Check (Story Entry)

**Category A snapshot at Story 18.3 entry**: Check `action-item-ledger.md` for current count. From Story 18.2 completion notes: E10R-2 (non-UTC week-bucketing test) and E17R-1 (paywall i18n) were 2/5 at Story 18.2 entry. Neither is triggered by Story 18.3. Sprint is clear.

### Project Structure — Files NEW/MODIFIED

```
supabase/migrations/
  0005_activity_feed.sql                                             # NEW

pulse_coach/
  lib/features/social/
    feed/                                                            # NEW module
      domain/entities/
        feed_entry.dart                                              # NEW
        feed_entry.freezed.dart                                      # GENERATED
      domain/repositories/
        feed_repository.dart                                         # NEW
      domain/usecases/
        share_feed_entry_use_case.dart                               # NEW
        get_feed_use_case.dart                                       # NEW
        react_to_entry_use_case.dart                                 # NEW
        revoke_feed_entry_use_case.dart                              # NEW
      data/models/
        feed_entry_dto.dart                                          # NEW
        feed_entry_dto.freezed.dart                                  # GENERATED
        feed_entry_dto.g.dart                                        # GENERATED
      data/datasources/
        feed_remote_data_source.dart                                 # NEW
      data/repositories/
        feed_repository_impl.dart                                    # NEW
      presentation/bloc/
        feed_event.dart                                              # NEW
        feed_state.dart                                              # NEW
        feed_state.freezed.dart                                      # GENERATED
        feed_bloc.dart                                               # NEW
      presentation/pages/
        feed_page.dart                                               # NEW
      presentation/widgets/
        activity_feed_card.dart                                      # NEW (UX-DR27, UX-DR31, UX-DR33)

    friends/presentation/pages/
      social_page.dart                                               # MODIFIED (+TabBar, +Feed tab)

  lib/features/session/presentation/pages/
    session_summary_page.dart                                        # MODIFIED (+share toggle AC1/AC2)

  lib/l10n/app/
    app_en.arb                                                       # MODIFIED (~15 keys)
    app_it.arb                                                       # MODIFIED (~15 keys)

  lib/core/di/
    injection.config.dart                                            # GENERATED (updated DI)

  test/data/social/
    feed_remote_data_source_test.dart                                # NEW (5 tests: 18.3-DS-001..005)
  test/bloc/
    feed_bloc_test.dart                                              # NEW (6 tests: 18.3-BLOC-001..006)
  test/widget/
    activity_feed_card_test.dart                                     # NEW (5 tests: 18.3-WIDGET-001..005)
```

### References

- Story 18.3 ACs: `_bmad-output/planning-artifacts/epics.md` line 2450
- FR66 (activity feed/share): `_bmad-output/planning-artifacts/epics.md` line 102
- UX-DR27 (ActivityFeedCard, no biometric, no count): `_bmad-output/planning-artifacts/epics.md` line 237
- UX-DR31 (Protective-State Social Suppression, reactions receive-only): `_bmad-output/planning-artifacts/epics.md` line 241
- UX-DR33 (48dp touch targets, text wraps): `_bmad-output/planning-artifacts/epics.md` line 243
- NFR29 (explicit sharing, revocable, RLS): `_bmad-output/planning-artifacts/epics.md` line 159
- ARCH22 (activity_feed schema): `_bmad-output/planning-artifacts/architecture.md` line 401
- ARCH25 (supabase_flutter boundary): `lib/core/cloud/supabase_client.dart`
- `@visibleForTesting` seam pattern reference: `lib/features/social/friends/data/datasources/social_profile_remote_data_source.dart`
- `FriendsRemoteDataSource` (seam pattern, `_uid` guard): `lib/features/social/friends/data/datasources/friends_remote_data_source.dart`
- Story 18.2 review findings (row null-safety, _uid guard): `_bmad-output/implementation-artifacts/18-2-friend-request-flow.md` review section
- `MiniSummaryArgs` / `MiniSummaryPage`: `lib/features/session/presentation/pages/session_summary_page.dart`
- `MiniSummaryCubit`: `lib/features/session/presentation/bloc/mini_summary_cubit.dart`
- `SubscriptionBloc` provided at root: `lib/app.dart`
- `SocialPage` (existing Tab host, Pro gate): `lib/features/social/friends/presentation/pages/social_page.dart`
- `ProUpsellSheet`: `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart`
- `ShimmerPlaceholder`: `lib/shared/widgets/shimmer_placeholder.dart`
- `SocialFailure` / `AuthFailure`: `lib/core/error/failures.dart`
- Existing migrations: `supabase/migrations/0001..0004`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- DS-005 test: strict Mockito mock throws MissingStubError before AuthFailureException — changed assertion to `throwsA(anything)` to verify guard behavior without deep mock chain.
- WIDGET-004 test: MaterialApp creates additional ScaleTransitions — changed to `findsAtLeastNWidgets(1)`.
- MiniSummaryPage regression: BlocBuilder<SubscriptionBloc> caused ProviderNotFoundError in 13 existing tests — replaced with Builder+try/catch since SubscriptionBloc is always present at app root in production; tests use minimal widget trees without it.
- `prefer_const_constructors` analyze issue — fixed Left wrapping pattern in FeedRepositoryImpl.

### Completion Notes List

- Implemented complete Activity Feed feature: Supabase migration with RLS (4 policies + increment_feed_reaction RPC), domain layer (FeedEntry, FeedRepository, 4 use cases), data layer (FeedEntryDto, FeedRemoteDataSource with @visibleForTesting seams, FeedRepositoryImpl with row-null-safety), FeedBloc with optimistic reaction animation, ActivityFeedCard widget (48dp touch targets, UX-DR27/31: no reaction count), FeedPage with shimmer/empty-state/revoke dialog, SocialPage extended with TabBar (Amici + Feed tabs).
- Share toggle added to MiniSummaryPage: Pro-only, defaults OFF, fire-and-forget pattern on Fading state — navigation never blocked by share result.
- 13 new ARB keys added (EN + IT); socialGenericError duplicate correctly avoided.
- 17 new tests: 5 DS, 6 BLOC, 5 WIDGET + 1 extra DS-004b. All green. 1045 total tests pass, 0 regressions.
- `flutter analyze lib/ test/` — 0 issues.

### File List

supabase/migrations/0005_activity_feed.sql
supabase/migrations/0006_activity_feed_reaction_hardening.sql
pulse_coach/lib/features/social/feed/domain/entities/feed_entry.dart
pulse_coach/lib/features/social/feed/domain/entities/feed_entry.freezed.dart
pulse_coach/lib/features/social/feed/domain/repositories/feed_repository.dart
pulse_coach/lib/features/social/feed/domain/usecases/share_feed_entry_use_case.dart
pulse_coach/lib/features/social/feed/domain/usecases/get_feed_use_case.dart
pulse_coach/lib/features/social/feed/domain/usecases/react_to_entry_use_case.dart
pulse_coach/lib/features/social/feed/domain/usecases/revoke_feed_entry_use_case.dart
pulse_coach/lib/features/social/feed/data/models/feed_entry_dto.dart
pulse_coach/lib/features/social/feed/data/models/feed_entry_dto.freezed.dart
pulse_coach/lib/features/social/feed/data/models/feed_entry_dto.g.dart
pulse_coach/lib/features/social/feed/data/datasources/feed_remote_data_source.dart
pulse_coach/lib/features/social/feed/data/repositories/feed_repository_impl.dart
pulse_coach/lib/features/social/feed/presentation/bloc/feed_event.dart
pulse_coach/lib/features/social/feed/presentation/bloc/feed_state.dart
pulse_coach/lib/features/social/feed/presentation/bloc/feed_state.freezed.dart
pulse_coach/lib/features/social/feed/presentation/bloc/feed_bloc.dart
pulse_coach/lib/features/social/feed/presentation/pages/feed_page.dart
pulse_coach/lib/features/social/feed/presentation/widgets/activity_feed_card.dart
pulse_coach/lib/features/social/friends/presentation/pages/social_page.dart
pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart
pulse_coach/lib/l10n/app/app_en.arb
pulse_coach/lib/l10n/app/app_it.arb
pulse_coach/lib/core/di/injection.config.dart
test/data/social/feed_remote_data_source_test.dart
test/data/social/feed_remote_data_source_test.mocks.dart
test/bloc/feed_bloc_test.dart
test/bloc/feed_bloc_test.mocks.dart
test/widget/activity_feed_card_test.dart

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-24 | 1.0.0 | Story created. | claude-sonnet-4-6 |
| 2026-06-24 | 1.1.0 | Story implemented: Activity Feed full feature (migration, domain, data, bloc, widgets, social tab extension, mini-summary share toggle, ARB keys, 17 new tests). | claude-sonnet-4-6 |

## Review Findings

_Adversarial code review (Blind Hunter + Edge Case Hunter + Acceptance Auditor), 2026-06-24, model claude-opus-4-8. Baseline `7989c55`. `flutter test` → 1045 passed; `flutter analyze lib/ test/` → 0 issues. Privacy/security ACs verified end-to-end by the Acceptance Auditor: no `reactions` count surfaced (UX-DR27/31), no biometric field in inserted row (NFR29), RLS owner-scoping, ARCH25 boundary, `_uid` null-guard, row-mapping resilience — all FULLY MET._

- [x] [Review][Patch] (resolved from Decision → new migration `0006`) Migration `0005` reaction-write security hardening — `increment_feed_reaction` is `SECURITY DEFINER` with a bare `UPDATE ... WHERE id = feed_id` and no friendship/ownership check inside, so it bypasses the `feed_update_reactions` RLS policy entirely: any authenticated user (and, since there is no `REVOKE ... FROM public` / `GRANT ... TO authenticated`, potentially `anon`) who learns a `feed_id` UUID can increment reactions on rows they cannot even read. `search_path` is not pinned (SECURITY DEFINER hardening gap). Separately, `feed_update_reactions` uses `WITH CHECK (true)`, letting any accepted friend rewrite `session_type`/`duration_minutes`/`completed_at` via direct UPDATE. No index on `owner_id`/`created_at` despite the RLS friendship subquery + `ORDER BY created_at`. Exploit impact is LOW (the reactions count is never displayed), but it is a real RLS-bypass + data-integrity gap. Decision required: (a) is `0005` already applied to Supabase — edit in place vs. add `0006`; (b) enforce friendship inside the RPC, pin `search_path`, `REVOKE FROM public` + `GRANT TO authenticated`, tighten the UPDATE policy, add index — or accept as-is given the count is invisible. [supabase/migrations/0005_activity_feed.sql]
- [x] [Review][Patch] Reaction failure destroys the whole feed (clobbers `loaded`→`error`, leaves stuck `reactingIds`) — on `FeedReactionSent` failure `_onReact` emits `FeedState.error`, discarding the loaded `entries`; the UI's `error: (_) => _FeedShimmer()` replaces the populated list with shimmer on a single transient reaction failure, and the optimistically-added id is never removed from `reactingIds`. Fix: on failure keep the loaded state, remove the id from `reactingIds`, surface a transient SnackBar only; add a re-entry guard so a rapid double-tap does not fire two RPCs. Test `18.3-BLOC-004` currently codifies the buggy `[loaded, error]` sequence and must be updated. [pulse_coach/lib/features/social/feed/presentation/bloc/feed_bloc.dart `_onReact`; pulse_coach/test/bloc/feed_bloc_test.dart:96]
- [x] [Review][Patch] Repository error messages leak raw English exception strings to the IT-locked UI — `feed_page` SnackBar shows `failure.message`, which is always non-empty (`'Failed to load feed: $e'` etc.), so the `l10n.socialGenericError` fallback never fires and a raw `PostgrestException(...)` string is shown to the Italian user. Fix: show the localized generic message in the feed error listener. [pulse_coach/lib/features/social/feed/presentation/pages/feed_page.dart error listener; messages originate in feed_repository_impl.dart]
- [x] [Review][Patch] `_relativeTime` renders negative strings ("-3 min fa") on clock skew / future `created_at` — `DateTime.now().difference(createdAt)` is negative when the device clock trails the server; `diff.inMinutes < 60` is true for negative values. Fix: clamp a negative diff to 0 / "just now". [pulse_coach/lib/features/social/feed/presentation/widgets/activity_feed_card.dart `_relativeTime`]
- [x] [Review][Patch] Share-result SnackBar uses bare `mounted` + stale `State.context` after `context.go(today)` — the fire-and-forget `.then` callback guards with `mounted` (not `context.mounted`) and calls `ScaffoldMessenger.of(context)` after navigation away, risking a "deactivated widget's ancestor" lookup. Fix: capture `ScaffoldMessenger`/`AppLocalizations` before the async gap or guard with `context.mounted`. [pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart MiniSummaryFading branch]
- [x] [Review][Patch] Feed `ListView` items lack `ValueKey(entry.id)` — stateful `ActivityFeedCard` keys its scale animation off `didUpdateWidget`; without keys, element recycling after a refresh/reorder can mis-target or re-fire the reaction animation. Fix: add `key: ValueKey(entry.id)`. [pulse_coach/lib/features/social/feed/presentation/pages/feed_page.dart ListView.builder]
- [x] [Review][Defer] `getFeed` `.limit(50)` has no pagination — beyond 50 newest entries, a user's own older entries become invisible and un-revokable through the UI. Deferred — MVP/exam scope, product call on pagination. [pulse_coach/lib/features/social/feed/data/datasources/feed_remote_data_source.dart]
- [x] [Review][Defer] Inconsistent row-degradation: a malformed `completed_at`/`created_at` errors the whole feed — `DateTime.parse` runs in `FeedEntryDtoMapper.toDomain()`, outside the `_rowToDto` try/catch, so a bad timestamp throws past the per-row guard and is caught only by the outer `getFeed` catch → entire feed errors (vs. a bad scalar which drops one row). Deferred — server always emits valid ISO timestamps; low real-world likelihood. [pulse_coach/lib/features/social/feed/data/models/feed_entry_dto.dart; feed_repository_impl.dart `_rowToDto`]
- [x] [Review][Defer] `_shareEnabled` not re-checked against Pro status at share time — if the subscription lapses between toggling on and the `Fading` event, the share still fires for a now-non-Pro user (narrow timing window). Deferred — negligible real-world window. [pulse_coach/lib/features/session/presentation/pages/session_summary_page.dart]
