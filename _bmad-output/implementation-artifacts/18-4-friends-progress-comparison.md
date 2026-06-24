---
baseline_commit: a88fdbc
---

# Story 18.4: Friends Progress Comparison

Status: done

## Story

As a Pro user,
I want to compare my weekly progress metrics against friends who have opted in to comparison,
So that I can see how I'm doing relative to my social circle without competitive pressure.

## Acceptance Criteria

**AC1 — Comparison tab renders friends' weekly metrics:**
Given a Pro user opens the Social tab → Confronto sub-tab
When the `ProgressComparisonBloc` loads
Then: `loading` state emits first (shimmer placeholders); `loaded` state shows a `ComparisonRow` for each friend who has `visibility_tier = friends_only`, with: their `@handle`, sessions completed this ISO week as `N/3`, minutes of movement this ISO week; NO RPE, HR, or behavioral state exposed (FR67, NFR29)

**AC2 — Own entry is visually distinguished:**
Given the comparison view renders
When the screen shows the list (own entry always first)
Then: the own `ComparisonRow` renders with a subtle highlight (e.g., `Card` with `surface container high` background token vs. standard `surface container` for friends); the own entry uses exactly the same layout/fields as friends' entries; no "You're winning!" framing or overtaken alert is shown (UX-DR31)

**AC3 — Private friends are invisible:**
Given a friend has `visibility_tier = private`
When the `get_friends_progress_this_week` RPC is called
Then: RLS enforces visibility at the DB — no data for private friends is returned; the Dart layer does not show them (ARCH22, NFR29)

**AC4 — Empty state:**
Given no friends have `visibility_tier = friends_only`
When the comparison view renders
Then: own entry is still shown; a "Nessun amico nel confronto" message is shown below the own row

**AC5 — Pro gate unchanged:**
Given a non-Pro user opens the Social tab
When the screen renders
Then: the existing `_LockedBanner` with `ProUpsellSheet.show(context)` on tap is shown — the tab structure itself is gated at the Pro check; non-Pro users see no Confronto tab (same behavior as AC8 in Story 18.3)

**AC6 — Supabase RPC `get_friends_progress_this_week`:**
Given migration `0007_friends_progress_rpc.sql` is applied
When the Postgres function is called by an authenticated user
Then: returns rows `(friend_id uuid, display_handle text, sessions_count bigint, minutes_total bigint)` scoped to accepted friends with `visibility_tier = 'friends_only'` and aggregated from `activity_feed` for the current ISO week (Mon 00:00 UTC → next Mon 00:00 UTC); private friends return no rows (RLS + WHERE clause enforce this); the function has REVOKE FROM public + GRANT TO authenticated

**AC7 — SocialPage extended to 3 tabs:**
Given a Pro user opens the Social tab
When the screen renders
Then: the screen has three sub-tabs — "Amici" (tab 0), "Feed" (tab 1), "Confronto" (tab 2); the `TabController(length: 3)` is the structural container; `ProgressComparisonBloc` is provided in `SocialPage.MultiBlocProvider`

**AC8 — Zero regressions:**
Given the new code is added
When the suite runs from `pulse_coach/`
Then `flutter test` reports all existing tests plus new tests green; `flutter analyze lib/ test/` reports 0 issues

## Tasks / Subtasks

- [x] **Task 1 — Supabase migration `0007_friends_progress_rpc.sql` (AC3, AC6)**
  - [x] 1.1 Create `supabase/migrations/0007_friends_progress_rpc.sql`:
    ```sql
    -- RPC for Story 18.4: returns progress metrics for accepted friends
    -- who have visibility_tier = 'friends_only', aggregated from activity_feed
    -- for the current ISO week (Mon 00:00 UTC to next Mon 00:00 UTC).
    -- SECURITY DEFINER so it bypasses activity_feed/profiles RLS,
    -- but enforces friendship + visibility_tier constraints explicitly.
    
    CREATE OR REPLACE FUNCTION get_friends_progress_this_week()
    RETURNS TABLE(
      friend_id      uuid,
      display_handle text,
      sessions_count bigint,
      minutes_total  bigint
    )
    LANGUAGE sql
    STABLE
    SECURITY DEFINER
    SET search_path = public
    AS $$
      WITH current_uid AS (
        SELECT auth.uid() AS uid
      ),
      my_friends AS (
        SELECT
          CASE
            WHEN f.requester_id = (SELECT uid FROM current_uid) THEN f.addressee_id
            ELSE f.requester_id
          END AS friend_id
        FROM friendships f
        WHERE f.status = 'accepted'
          AND (
            f.requester_id = (SELECT uid FROM current_uid)
            OR f.addressee_id = (SELECT uid FROM current_uid)
          )
      )
      SELECT
        p.id                                                                   AS friend_id,
        COALESCE(p.display_handle, p.id::text)                                AS display_handle,
        COUNT(af.id)                                                           AS sessions_count,
        COALESCE(SUM(af.duration_minutes)::bigint, 0::bigint)                 AS minutes_total
      FROM my_friends mf
      JOIN profiles p ON p.id = mf.friend_id
      LEFT JOIN activity_feed af
        ON  af.owner_id = p.id
        AND af.created_at >= date_trunc('week', now() AT TIME ZONE 'UTC')
        AND af.created_at <  date_trunc('week', now() AT TIME ZONE 'UTC') + INTERVAL '7 days'
      WHERE p.visibility_tier = 'friends_only'
      GROUP BY p.id, p.display_handle
    $$;
    
    REVOKE ALL  ON FUNCTION get_friends_progress_this_week() FROM public;
    GRANT EXECUTE ON FUNCTION get_friends_progress_this_week() TO authenticated;
    ```
    **Critical**: `auth.uid()` inside a SECURITY DEFINER function works in Supabase because PostgREST injects the JWT context as a Postgres config variable before executing the function — same mechanism used by `increment_feed_reaction` in `0006`. The CTE approach is clearer than inline subqueries and avoids the CASE ambiguity in a direct JOIN. The `LEFT JOIN` ensures friends with zero activity_feed entries this week return `sessions_count = 0, minutes_total = 0` rather than being omitted from the result set.

- [x] **Task 2 — Domain entity `ProgressComparisonEntry` (AC1, AC2)**
  - [x] 2.1 Create `lib/features/social/comparison/domain/entities/progress_comparison_entry.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    
    part 'progress_comparison_entry.freezed.dart';
    
    @freezed
    abstract class ProgressComparisonEntry with _$ProgressComparisonEntry {
      const factory ProgressComparisonEntry({
        required String displayHandle,
        required int sessionsThisWeek,
        required int minutesThisWeek,
        @Default(false) bool isOwn,
      }) = _ProgressComparisonEntry;
    }
    ```
    No RPE, HR, behavioral state fields — these are forbidden by NFR29 and never fetched.

- [x] **Task 3 — Domain: repository interface + use cases (AC1, AC2)**
  - [x] 3.1 Create `lib/features/social/comparison/domain/repositories/progress_comparison_repository.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    
    abstract class ProgressComparisonRepository {
      Future<Either<SocialFailure, List<ProgressComparisonEntry>>> getFriendsProgress();
    }
    ```
  - [x] 3.2 Create `lib/features/social/comparison/domain/usecases/get_friends_comparison_use_case.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    import 'package:pulse_coach/features/social/comparison/domain/repositories/progress_comparison_repository.dart';
    
    @injectable
    class GetFriendsComparisonUseCase {
      final ProgressComparisonRepository _repository;
      const GetFriendsComparisonUseCase(this._repository);
    
      Future<Either<SocialFailure, List<ProgressComparisonEntry>>> call() =>
          _repository.getFriendsProgress();
    }
    ```
  - [x] 3.3 Create `lib/features/social/comparison/domain/usecases/get_own_weekly_summary_use_case.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
    import 'package:pulse_coach/features/progress/domain/repositories/progress_repository.dart';
    
    /// Returns (sessions: int, minutes: int) for the current ISO week from local drift.
    @injectable
    class GetOwnWeeklySummaryUseCase {
      final ProgressRepository _repository;
      const GetOwnWeeklySummaryUseCase(this._repository);
    
      Future<Either<Failure, ({int sessions, int minutes})>> call() async {
        final result = await _repository.getProgressStats();
        return result.fold(
          Left.new,
          (stats) => Right((
            sessions: stats.completedThisWeek,
            minutes: _thisWeekMinutes(stats.minutesPerWeek),
          )),
        );
      }
    
      int _thisWeekMinutes(List<WeeklyMinutes> minutesPerWeek) {
        if (minutesPerWeek.isEmpty) return 0;
        final now = DateTime.now().toUtc();
        // Monday of current ISO week (weekday 1 = Monday, 7 = Sunday)
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final label =
            '${monday.day.toString().padLeft(2, '0')}/${monday.month.toString().padLeft(2, '0')}';
        // minutesPerWeek is oldest-first; last entry is the most recent week
        if (minutesPerWeek.last.weekLabel == label) {
          return minutesPerWeek.last.totalMinutes;
        }
        return 0;
      }
    }
    ```
    **Critical**: `ProgressRepository` is imported from `package:pulse_coach/features/progress/domain/repositories/progress_repository.dart` — a cross-feature domain import, which is acceptable (domain → domain, no Flutter imports). `GetProgressStats` is `@lazySingleton`; `GetOwnWeeklySummaryUseCase` should be `@injectable` (not singleton) since it's only used here. The `weekLabel` format `DD/MM` matches what `ProgressLocalDataSource` builds — verified in `progress_stats.dart` docstring ("Monday date of that week DD/MM").

- [x] **Task 4 — Data layer: DTO + remote datasource + repository (AC1, AC3, AC6)**
  - [x] 4.1 Create `lib/features/social/comparison/data/models/friend_progress_dto.dart`:
    ```dart
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    
    /// Plain Dart class — no freezed needed (read-only projection, no copyWith required).
    class FriendProgressDto {
      final String friendId;
      final String displayHandle;
      final int sessionsThisWeek;
      final int minutesThisWeek;
    
      const FriendProgressDto({
        required this.friendId,
        required this.displayHandle,
        required this.sessionsThisWeek,
        required this.minutesThisWeek,
      });
    
      factory FriendProgressDto.fromJson(Map<String, dynamic> json) {
        return FriendProgressDto(
          friendId: json['friend_id'] as String? ?? '',
          displayHandle: json['display_handle'] as String? ??
              (json['friend_id'] as String? ?? ''),
          sessionsThisWeek: (json['sessions_count'] as num?)?.toInt() ?? 0,
          minutesThisWeek: (json['minutes_total'] as num?)?.toInt() ?? 0,
        );
      }
    
      ProgressComparisonEntry toDomain() => ProgressComparisonEntry(
            displayHandle: displayHandle,
            sessionsThisWeek: sessionsThisWeek,
            minutesThisWeek: minutesThisWeek,
            // isOwn defaults to false
          );
    }
    ```
    **Critical**: `sessions_count` and `minutes_total` come from Postgres aggregation and may be typed as `int` or `BigInt` depending on the Supabase client version. The `(json['sessions_count'] as num?)?.toInt()` cast handles both safely.

  - [x] 4.2 Create `lib/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart`:
    ```dart
    import 'package:flutter/foundation.dart' show visibleForTesting;
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/cloud/supabase_client.dart'
        show SupabaseClientProvider;
    
    @injectable
    class ProgressComparisonRemoteDataSource {
      final SupabaseClientProvider _supabase;
    
      ProgressComparisonRemoteDataSource(this._supabase) {
        fetchFriendsProgress = _defaultFetchFriendsProgress;
      }
    
      @visibleForTesting
      late Future<List<Map<String, dynamic>>> Function() fetchFriendsProgress;
    
      String get _uid {
        final user = _supabase.client.auth.currentUser;
        if (user == null) throw StateError('No authenticated session');
        return user.id;
      }
    
      Future<List<Map<String, dynamic>>> _defaultFetchFriendsProgress() async {
        // _uid guard: throws before the RPC if the session is gone
        _uid;
        final result = await _supabase.client.rpc('get_friends_progress_this_week');
        return List<Map<String, dynamic>>.from(result as List);
      }
    
      Future<List<Map<String, dynamic>>> loadFriendsProgress() =>
          fetchFriendsProgress();
    }
    ```
    **Critical ARCH25**: Only `lib/core/cloud/supabase_client.dart` may import `supabase_flutter` — this datasource must use `SupabaseClientProvider` from the boundary layer. Never import `supabase_flutter` directly. Follow the exact pattern of `FeedRemoteDataSource` and `FriendsRemoteDataSource`.

  - [x] 4.3 Create `lib/features/social/comparison/data/repositories/progress_comparison_repository_impl.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart';
    import 'package:pulse_coach/features/social/comparison/data/models/friend_progress_dto.dart';
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    import 'package:pulse_coach/features/social/comparison/domain/repositories/progress_comparison_repository.dart';
    
    @Injectable(as: ProgressComparisonRepository)
    class ProgressComparisonRepositoryImpl implements ProgressComparisonRepository {
      final ProgressComparisonRemoteDataSource _dataSource;
      const ProgressComparisonRepositoryImpl(this._dataSource);
    
      @override
      Future<Either<SocialFailure, List<ProgressComparisonEntry>>> getFriendsProgress() async {
        try {
          final rows = await _dataSource.loadFriendsProgress();
          final entries = rows
              .map(_safeFromJson)
              .whereType<ProgressComparisonEntry>()
              .toList();
          return Right(entries);
        } on StateError catch (e) {
          return Left(SocialFailure('Not signed in: ${e.message}'));
        } catch (e) {
          return Left(SocialFailure('Failed to load comparison: $e'));
        }
      }
    
      ProgressComparisonEntry? _safeFromJson(Map<String, dynamic> row) {
        try {
          return FriendProgressDto.fromJson(row).toDomain();
        } catch (_) {
          return null; // degrade single bad row rather than crashing the full list
        }
      }
    }
    ```

- [x] **Task 5 — ProgressComparisonBloc (AC1–AC5)**
  - [x] 5.1 Create `lib/features/social/comparison/presentation/bloc/progress_comparison_event.dart`:
    ```dart
    abstract class ProgressComparisonEvent {
      const ProgressComparisonEvent();
    }
    
    class ProgressComparisonLoaded extends ProgressComparisonEvent {
      /// The current user's own display handle — sourced from SocialProfileBloc at dispatch site.
      final String ownHandle;
      const ProgressComparisonLoaded(this.ownHandle);
    }
    ```

  - [x] 5.2 Create `lib/features/social/comparison/presentation/bloc/progress_comparison_state.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    
    part 'progress_comparison_state.freezed.dart';
    
    @freezed
    abstract class ProgressComparisonState with _$ProgressComparisonState {
      const factory ProgressComparisonState.initial() = _Initial;
      const factory ProgressComparisonState.loading() = _Loading;
      const factory ProgressComparisonState.loaded({
        required ProgressComparisonEntry ownEntry,
        required List<ProgressComparisonEntry> friendEntries,
      }) = _Loaded;
      const factory ProgressComparisonState.error({required Failure failure}) = _Error;
    }
    ```

  - [x] 5.3 Create `lib/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart`:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    import 'package:pulse_coach/features/social/comparison/domain/usecases/get_friends_comparison_use_case.dart';
    import 'package:pulse_coach/features/social/comparison/domain/usecases/get_own_weekly_summary_use_case.dart';
    import 'progress_comparison_event.dart';
    import 'progress_comparison_state.dart';
    
    @injectable
    class ProgressComparisonBloc
        extends Bloc<ProgressComparisonEvent, ProgressComparisonState> {
      final GetFriendsComparisonUseCase _getFriends;
      final GetOwnWeeklySummaryUseCase _getOwn;
    
      ProgressComparisonBloc(this._getFriends, this._getOwn)
          : super(const ProgressComparisonState.initial()) {
        on<ProgressComparisonLoaded>(_onLoaded);
      }
    
      Future<void> _onLoaded(
        ProgressComparisonLoaded event,
        Emitter<ProgressComparisonState> emit,
      ) async {
        emit(const ProgressComparisonState.loading());
    
        // Run both use cases in parallel — they hit different data sources (cloud vs local drift)
        final results = await Future.wait([
          _getFriends(),
          _getOwn(),
        ]);
    
        final friendsResult =
            results[0] as dynamic; // Either<SocialFailure, List<ProgressComparisonEntry>>
        final ownResult =
            results[1] as dynamic; // Either<Failure, ({int sessions, int minutes})>
    
        // Emit error if either fails
        if (ownResult.isLeft()) {
          emit(ProgressComparisonState.error(failure: ownResult.fold((f) => f, (_) => throw AssertionError())));
          return;
        }
        if (friendsResult.isLeft()) {
          emit(ProgressComparisonState.error(failure: friendsResult.fold((f) => f, (_) => throw AssertionError())));
          return;
        }
    
        final own = ownResult.getOrElse(() => (sessions: 0, minutes: 0));
        final friends = friendsResult.getOrElse(() => <ProgressComparisonEntry>[]);
    
        emit(ProgressComparisonState.loaded(
          ownEntry: ProgressComparisonEntry(
            displayHandle: event.ownHandle,
            sessionsThisWeek: own.sessions,
            minutesThisWeek: own.minutes,
            isOwn: true,
          ),
          friendEntries: friends,
        ));
      }
    }
    ```
    **Critical**: `Future.wait` parallelizes the cloud RPC and local drift read. This is safe because they hit different data sources. The `dynamic` casts are needed because `Future.wait` returns `List<dynamic>` when the element types differ — OR replace with explicit typed variables:
    ```dart
    // Alternative cleaner approach with Dart 3 records:
    final (friendsResult, ownResult) = await (
      _getFriends(),
      _getOwn(),
    ).wait;
    ```
    Use whichever the project's Dart SDK supports (Dart ≥ 3.0 supports record `.wait`; check `dart --version` if needed — Flutter 3.41.x ships Dart 3.3.x, so records are supported).

- [x] **Task 6 — ComparisonRow widget (AC1, AC2, NFR29)**
  - [x] 6.1 Create `lib/features/social/comparison/presentation/widgets/comparison_row.dart`:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:pulse_coach/features/social/comparison/domain/entities/progress_comparison_entry.dart';
    import 'package:pulse_coach/l10n/app_localizations.dart';
    
    class ComparisonRow extends StatelessWidget {
      final ProgressComparisonEntry entry;
      static const int weeklyTarget = 3; // FR12: always 3 — AI session-count cap
    
      const ComparisonRow({super.key, required this.entry});
    
      @override
      Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
    
        // isOwn gets subtle surface container high background; friends get standard card
        final backgroundColor = entry.isOwn
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainer;
    
        return Card(
          color: backgroundColor,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '@${entry.displayHandle}',
                    style: theme.textTheme.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.visible, // UX-DR33: wraps, never truncates
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.comparisonSessions(entry.sessionsThisWeek, weeklyTarget),
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      l10n.comparisonMinutes(entry.minutesThisWeek),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }
    ```
    **Critical NFR29**: No RPE, HR, or behavioral state fields must ever be added to this widget. The only fields are handle + sessions/weeklyTarget + minutes. `weeklyTarget` is a compile-time constant (always 3 per FR12); do NOT fetch it from the DB.

- [x] **Task 7 — ProgressComparisonPage (AC1–AC5)**
  - [x] 7.1 Create `lib/features/social/comparison/presentation/pages/progress_comparison_page.dart`:
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart';
    import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_event.dart';
    import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_state.dart';
    import 'package:pulse_coach/features/social/comparison/presentation/widgets/comparison_row.dart';
    import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
    import 'package:pulse_coach/l10n/app_localizations.dart';
    import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';
    
    class ProgressComparisonPage extends StatelessWidget {
      const ProgressComparisonPage({super.key});
    
      @override
      Widget build(BuildContext context) {
        return const _ComparisonView();
      }
    }
    
    class _ComparisonView extends StatefulWidget {
      const _ComparisonView();
    
      @override
      State<_ComparisonView> createState() => _ComparisonViewState();
    }
    
    class _ComparisonViewState extends State<_ComparisonView> {
      @override
      void initState() {
        super.initState();
        // Dispatch once at init — ownHandle sourced from SocialProfileBloc above in tree
        final profileState = context.read<SocialProfileBloc>().state;
        final ownHandle =
            profileState.whenOrNull(loaded: (p) => p.displayHandle) ?? '';
        context.read<ProgressComparisonBloc>().add(ProgressComparisonLoaded(ownHandle));
      }
    
      @override
      Widget build(BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
    
        return BlocConsumer<ProgressComparisonBloc, ProgressComparisonState>(
          listener: (context, state) {
            state.whenOrNull(
              error: (_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.socialGenericError)),
                );
              },
            );
          },
          builder: (context, state) {
            return state.when(
              initial: () => const _ComparisonShimmer(),
              loading: () => const _ComparisonShimmer(),
              loaded: (ownEntry, friendEntries) {
                return RefreshIndicator(
                  onRefresh: () async {
                    final profileState =
                        context.read<SocialProfileBloc>().state;
                    final ownHandle =
                        profileState.whenOrNull(loaded: (p) => p.displayHandle) ??
                            '';
                    context
                        .read<ProgressComparisonBloc>()
                        .add(ProgressComparisonLoaded(ownHandle));
                  },
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          l10n.comparisonThisWeek,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      ComparisonRow(entry: ownEntry),
                      if (friendEntries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            l10n.comparisonEmptyFriends,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      else
                        ...friendEntries.map((e) => ComparisonRow(key: ValueKey(e.displayHandle), entry: e)),
                    ],
                  ),
                );
              },
              error: (_) => const _ComparisonShimmer(),
            );
          },
        );
      }
    }
    
    class _ComparisonShimmer extends StatelessWidget {
      const _ComparisonShimmer();
    
      @override
      Widget build(BuildContext context) {
        return Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ShimmerPlaceholder(height: 72),
            ),
          ),
        );
      }
    }
    ```
    **Critical**: `SocialProfileBloc` is provided by the ancestor `SocialPage.MultiBlocProvider` — `ProgressComparisonPage` does NOT need to provide it again. `ProgressComparisonBloc` is also provided at `SocialPage` level (Task 8). The page just uses `context.read<...>()` to access both.

    **Critical**: Error state shows `socialGenericError` (localized, already exists in ARB) — NOT the raw failure message (lesson from Story 18.3 review finding).

- [x] **Task 8 — Extend SocialPage to 3 tabs (AC5, AC7)**
  - [x] 8.1 Modify `lib/features/social/friends/presentation/pages/social_page.dart`:
    - Add import: `import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart';`
    - Add import: `import 'package:pulse_coach/features/social/comparison/presentation/pages/progress_comparison_page.dart';`
    - In `SocialPage.build` `MultiBlocProvider.providers`: add
      ```dart
      BlocProvider<ProgressComparisonBloc>(
        create: (_) => getIt<ProgressComparisonBloc>(),
        // Event is dispatched from _ComparisonViewState.initState — NOT here
      ),
      ```
    - In `_SocialViewState.initState`: change `TabController(length: 2, ...)` → `TabController(length: 3, ...)`
    - In `_SocialViewState.build`, the `TabBar` and `TabBarView`:
      ```dart
      TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: l10n.friendsScreenTitle),
          Tab(text: l10n.feedScreenTitle),
          Tab(text: l10n.comparisonScreenTitle),  // ADD
        ],
      ),
      // ...
      TabBarView(
        controller: _tabController,
        children: [
          _FriendsTab(searchController: _searchController),
          const FeedPage(),
          const ProgressComparisonPage(),  // ADD
        ],
      ),
      ```
    **Critical**: `ProgressComparisonBloc` is provided by `SocialPage.MultiBlocProvider`. `ProgressComparisonPage` uses `BlocProvider.value` semantics via `context.read<ProgressComparisonBloc>()` — the page itself does NOT create a new BlocProvider. This prevents re-initialization on tab switch.

    **Critical**: Do NOT dispatch `ProgressComparisonLoaded` from `SocialPage.build` — it is dispatched from `_ComparisonViewState.initState()` because it needs the `ownHandle` from `SocialProfileBloc`, which is only resolvable in a widget context with an active tree.

- [x] **Task 9 — ARB keys (AC1–AC4)**
  - [x] 9.1 In `lib/l10n/app/app_en.arb`, add before closing `}`:
    ```json
    "comparisonScreenTitle": "Comparison",
    "comparisonThisWeek": "This week",
    "comparisonSessions": "{count}/{target} sessions",
    "@comparisonSessions": {
      "placeholders": {
        "count": {"type": "int"},
        "target": {"type": "int"}
      }
    },
    "comparisonMinutes": "{count} min",
    "@comparisonMinutes": {
      "placeholders": {
        "count": {"type": "int"}
      }
    },
    "comparisonEmptyFriends": "No friends have opted in to comparison yet."
    ```
  - [x] 9.2 In `lib/l10n/app/app_it.arb`, add before closing `}`:
    ```json
    "comparisonScreenTitle": "Confronto",
    "comparisonThisWeek": "Questa settimana",
    "comparisonSessions": "{count}/{target} sessioni",
    "@comparisonSessions": {
      "placeholders": {
        "count": {"type": "int"},
        "target": {"type": "int"}
      }
    },
    "comparisonMinutes": "{count} min",
    "@comparisonMinutes": {
      "placeholders": {
        "count": {"type": "int"}
      }
    },
    "comparisonEmptyFriends": "Nessun amico nel confronto."
    ```
  - [x] 9.3 Run `flutter pub get` to regenerate localizations.

- [x] **Task 10 — build_runner and DI (AC8)**
  - [x] 10.1 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`.
    New generated files expected:
    - `progress_comparison_entry.freezed.dart`
    - `progress_comparison_state.freezed.dart`
    - Updated `injection.config.dart` with: `ProgressComparisonRemoteDataSource`, `ProgressComparisonRepositoryImpl`, `GetFriendsComparisonUseCase`, `GetOwnWeeklySummaryUseCase`, `ProgressComparisonBloc`
  - [x] 10.2 Run `flutter analyze lib/ test/` — 0 issues.

- [x] **Task 11 — Tests (AC1–AC4, AC8)**
  - [x] 11.1 Create `test/data/social/progress_comparison_remote_data_source_test.dart`:
    Using the `@visibleForTesting` seam pattern (same as `feed_remote_data_source_test.dart`):
    ```
    // [18.4-DS-001] loadFriendsProgress — returns list of rows from RPC
    // [18.4-DS-002] loadFriendsProgress — returns empty list when RPC returns []
    // [18.4-DS-003] _uid guard — throws StateError when currentUser is null
    ```
  - [x] 11.2 Create `test/bloc/progress_comparison_bloc_test.dart`:
    Use `@GenerateMocks([ProgressComparisonRepository, ProgressRepository])` + `bloc_test`:
    ```
    // [18.4-BLOC-001] ProgressComparisonLoaded → [loading, loaded(ownEntry, friendEntries)]
    //                 ownEntry.isOwn = true, friendEntries[0].isOwn = false
    // [18.4-BLOC-002] ProgressComparisonLoaded — getFriendsProgress error → [loading, error]
    // [18.4-BLOC-003] ProgressComparisonLoaded — getOwnWeeklySummary error → [loading, error]
    // [18.4-BLOC-004] ProgressComparisonLoaded — empty friend list → [loading, loaded(ownEntry, [])]
    ```
  - [x] 11.3 Create `test/widget/comparison_row_test.dart`:
    ```
    // [18.4-WIDGET-001] own entry — highlighted (surfaceContainerHigh), shows handle + sessions/3 + minutes
    // [18.4-WIDGET-002] friend entry — standard card color, shows handle + sessions + minutes
    // [18.4-WIDGET-003] no RPE, HR, or behavioral state rendered — verify absent from widget tree
    ```
  - [x] 11.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate mock files.
  - [x] 11.5 Run `flutter test` — all existing + new tests green.
  - [x] 11.6 Run `flutter analyze lib/ test/` — 0 issues.

### Review Findings

_Code review 2026-06-24 (Blind Hunter + Edge Case Hunter + Acceptance Auditor, Opus). All 8 ACs verified PASS by the Acceptance Auditor; no AC-breaking defect found._

- [x] [Review][Patch] Own row shows bare `@` on first open; no re-dispatch when SocialProfileBloc finishes loading [progress_comparison_page.dart:30-39] — FIXED: added a `BlocListener<SocialProfileBloc>` (listenWhen → loaded) that re-dispatches `ProgressComparisonLoaded(handle)` once the profile resolves. (Decision: Paolo chose to fix beyond the spec-accepted behavior.)
- [x] [Review][Patch] SQL week window is not self-contained UTC — depends on session `TimeZone` [0007_friends_progress_rpc.sql:44-45] — FIXED: both bounds wrapped with `... AT TIME ZONE 'UTC'` to produce a `timestamptz` boundary independent of session TZ. (Flagged independently by Blind Hunter + Acceptance Auditor.)
- [x] [Review][Defer] `_thisWeekMinutes` relies on byte-identical `DD/MM` label coupling between use case and `ProgressLocalDataSource` [get_own_weekly_summary_use_case.dart:188-200] — deferred, extends existing E10R-2 concern (happy path verified correct; add a non-UTC regression test per Dev Note, not new Category A debt).
- [x] [Review][Defer] Handle-less friend renders as `@<uuid>` (SQL `COALESCE(display_handle, p.id::text)`) [friend_progress_dto.dart / 0007:37] — deferred, low-probability (handle setup is enforced in Story 18.1); UX-only, not a data leak (already a friend).

## Dev Notes

### Critical: ARCH25 — Never Import supabase_flutter Directly

`ProgressComparisonRemoteDataSource` must import only `package:pulse_coach/core/cloud/supabase_client.dart show SupabaseClientProvider`. Never import `supabase_flutter` directly. Pattern identical to `FeedRemoteDataSource`.

### Critical: `_uid` StateError Guard

`ProgressComparisonRemoteDataSource._uid` uses `StateError` (not `AuthFailureException`) — this matches the `FriendsRemoteDataSource` pattern. The repository catches `StateError` and maps it to `SocialFailure('Not signed in: ...')`.

### Critical: ProgressComparisonBloc — Parallel Await Pattern

Both `_getFriends()` and `_getOwn()` should be called in parallel since they hit different data sources. Use Dart 3 record `.wait` syntax (Flutter 3.41.x ships Dart 3.3.x, records supported):
```dart
final (friendsResult, ownResult) = await (_getFriends(), _getOwn()).wait;
```
This avoids the `dynamic` cast issue in `Future.wait<Object>`. If the Dart version doesn't support it, use:
```dart
final futures = await Future.wait<Object?>([_getFriends(), _getOwn()]);
```

### Critical: ProgressComparisonBloc — Own Entry Handle

The own `displayHandle` is passed via `ProgressComparisonLoaded(ownHandle)`. It is sourced from `SocialProfileBloc` at the dispatch site (`_ComparisonViewState.initState`). The Bloc does NOT depend on `SocialProfileBloc`. If `SocialProfileBloc` is still loading at dispatch time, `ownHandle` will be `''` — acceptable (empty string shows as `@`, and a pull-to-refresh will re-dispatch with the correct handle once the profile loads).

### Critical: weeklyTarget = 3 Is a Compile-Time Constant

Per FR12 and `ProgressStats.weeklyTarget` docstring: "Always 3 — the AI initial session-count cap." Do NOT fetch this from Supabase or drift. Hardcode as `static const int weeklyTarget = 3` in `ComparisonRow`. This mirrors how `WeeklyGoalIndicator` works in the progress feature.

### Critical: Own Data Source vs. Friends Data Source

- **Own data**: sourced from local drift via `GetOwnWeeklySummaryUseCase` → `GetProgressStats` → `ProgressLocalDataSource`. Shows all completed sessions (not just shared ones).
- **Friends data**: sourced from Supabase `activity_feed` via RPC. Shows only explicitly shared sessions.
- This asymmetry is intentional and aligned with the story ACs: the user sees their full picture; friends see only what they've shared. Do NOT change this to make both data sources symmetric.

### Critical: `_thisWeekMinutes` Week Label Format

`GetOwnWeeklySummaryUseCase._thisWeekMinutes` derives the current ISO week label as `DD/MM` from `DateTime.now().toUtc()`. This matches exactly what `ProgressLocalDataSource` writes into `WeeklyMinutes.weekLabel`. The method returns 0 if the last bucket's label doesn't match (user has no sessions this week). This is correct — 0 minutes for a week with no sessions.

**E10R-2 awareness**: The `_mondayOf` computation uses `DateTime.now().toUtc()` (UTC-first), matching the established convention from Epic 10.3. Non-UTC device clocks will bucket correctly because all dates are normalized to UTC before label comparison.

### Critical: SocialPage Tab Count Change — No Double-Dispatch

`ProgressComparisonBloc` is provided in `SocialPage.MultiBlocProvider` WITHOUT dispatching an event. The event is dispatched from `_ComparisonViewState.initState()`. This is the correct pattern because:
1. The event needs `ownHandle` from `SocialProfileBloc` (only resolvable in widget context)
2. Dispatching at `MultiBlocProvider.create` would execute before the widget tree is mounted

Do NOT add `..add(ProgressComparisonLoaded(''))` to the `BlocProvider.create` lambda.

### Critical: Error State Uses `socialGenericError`

Per Story 18.3 review finding: raw `failure.message` strings are English SDK internals and must NOT be shown to the IT-locked user. `ProgressComparisonPage` always shows `l10n.socialGenericError` on error (already exists in both ARB files — do NOT add a duplicate).

### Critical: Row-Mapping Resilience

`ProgressComparisonRepositoryImpl._safeFromJson` wraps each row's `FriendProgressDto.fromJson` in try/catch and returns `null`, filtered by `.whereType<ProgressComparisonEntry>()`. A single bad RPC row degrades gracefully rather than erroring the entire list. Pattern from Story 18.3 `FeedRepositoryImpl._rowToDto`.

### Critical: `FriendProgressDto` — No freezed

`FriendProgressDto` is a plain Dart class — no freezed annotation, no `part` directives, no build_runner generation needed for this file. It is a one-way read-only projection. This keeps Task 10's build_runner output minimal.

### Category A Fire-Check (Story 18.4 Entry)

**Category A snapshot at Story 18.3 close (2026-06-24): 2 / 5.** Active: `E10R-2` (non-UTC week-bucketing test), `E17R-1` (paywall i18n). Neither triggered by Story 18.4. Sprint is clear.

**E10R-2 note**: Story 18.4 introduces `GetOwnWeeklySummaryUseCase._thisWeekMinutes`, which computes the Monday label using UTC. This is the same computation pattern as `ProgressLocalDataSource` (Story 10.3 fix). The non-UTC regression test (`E10R-2`) targets the `_mondayOf` utility in the progress feature — it does NOT cover the new `_thisWeekMinutes` method. Consider adding a single non-UTC test in `test/domain/social/get_own_weekly_summary_use_case_test.dart` to cover this edge case (not counted as new Category A debt — it's an extension of the existing `E10R-2` concern, not a new defect).

### Project Structure — Files NEW/MODIFIED

```
supabase/migrations/
  0007_friends_progress_rpc.sql                                    # NEW

pulse_coach/
  lib/features/social/
    comparison/                                                      # NEW module
      domain/entities/
        progress_comparison_entry.dart                              # NEW
        progress_comparison_entry.freezed.dart                      # GENERATED
      domain/repositories/
        progress_comparison_repository.dart                         # NEW
      domain/usecases/
        get_friends_comparison_use_case.dart                        # NEW
        get_own_weekly_summary_use_case.dart                        # NEW (cross-feature: imports ProgressRepository)
      data/models/
        friend_progress_dto.dart                                    # NEW (plain Dart — no build_runner)
      data/datasources/
        progress_comparison_remote_data_source.dart                 # NEW
      data/repositories/
        progress_comparison_repository_impl.dart                    # NEW
      presentation/bloc/
        progress_comparison_event.dart                              # NEW
        progress_comparison_state.dart                              # NEW
        progress_comparison_state.freezed.dart                      # GENERATED
        progress_comparison_bloc.dart                               # NEW
      presentation/pages/
        progress_comparison_page.dart                               # NEW
      presentation/widgets/
        comparison_row.dart                                         # NEW

    friends/presentation/pages/
      social_page.dart                                             # MODIFIED (+3rd tab, +ProgressComparisonBloc provider)

  lib/l10n/app/
    app_en.arb                                                     # MODIFIED (+5 keys)
    app_it.arb                                                     # MODIFIED (+5 keys)

  lib/core/di/
    injection.config.dart                                          # GENERATED (updated DI)

  test/data/social/
    progress_comparison_remote_data_source_test.dart              # NEW (3 tests: 18.4-DS-001..003)
  test/bloc/
    progress_comparison_bloc_test.dart                            # NEW (4 tests: 18.4-BLOC-001..004)
  test/widget/
    comparison_row_test.dart                                       # NEW (3 tests: 18.4-WIDGET-001..003)
```

### References

- Story 18.4 ACs: `_bmad-output/planning-artifacts/epics.md` line 2478
- FR67 (progress comparison): `_bmad-output/planning-artifacts/epics.md` line 103
- NFR29 (explicit sharing, visibility tiers, no biometric): `_bmad-output/planning-artifacts/epics.md` line 159
- ARCH22 (social Postgres schema, RLS enforcement): `_bmad-output/planning-artifacts/architecture.md` line ~399
- ARCH25 (supabase_flutter boundary): `lib/core/cloud/supabase_client.dart`
- ARCH27 (Bloc for cloud flows, Cubit for UI): `_bmad-output/planning-artifacts/architecture.md`
- UX-DR31 (no "overtaken" framing, Protective-State Social Suppression): `_bmad-output/planning-artifacts/epics.md` line 241
- UX-DR33 (48dp touch targets, text wraps): `_bmad-output/planning-artifacts/epics.md` line 243
- FR12 (weeklyTarget always 3): `_bmad-output/planning-artifacts/epics.md`
- `@visibleForTesting` seam pattern: `lib/features/social/friends/data/datasources/friends_remote_data_source.dart`
- `FeedRemoteDataSource` (seam + ARCH25): `lib/features/social/feed/data/datasources/feed_remote_data_source.dart`
- `FeedRepositoryImpl._rowToDto` (resilient row mapping): `lib/features/social/feed/data/repositories/feed_repository_impl.dart`
- Story 18.3 review (raw failure.message = English SDK text → always use l10n): Story 18.3 review finding #3
- `GetProgressStats` / `ProgressRepository` / `WeeklyMinutes`: `lib/features/progress/domain/`
- `SocialProfileBloc` (own handle source): `lib/features/social/friends/presentation/bloc/social_profile_bloc.dart`
- `SocialPage` (existing MultiBlocProvider + TabController pattern): `lib/features/social/friends/presentation/pages/social_page.dart`
- `ShimmerPlaceholder`: `lib/shared/widgets/shimmer_placeholder.dart`
- `SocialFailure` / `CacheFailure`: `lib/core/error/failures.dart`
- `socialGenericError` ARB key (already exists): `lib/l10n/app/app_en.arb` + `app_it.arb`
- Existing migrations `0001..0006`: `supabase/migrations/`
- `ProgressStats.weeklyTarget` docstring ("Always 3"): `lib/features/progress/domain/entities/progress_stats.dart`
- E10R-2 (non-UTC week-bucketing): `_bmad-output/implementation-artifacts/action-item-ledger.md` line ~235

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

None — clean implementation, no debugging required.

### Completion Notes List

- Implemented full `comparison` feature module: domain entity, repository interface, 2 use cases, DTO, datasource (ARCH25-compliant), repository impl, Bloc (event/state/handler), page and widget.
- ATDD followed: tests written before production code (test files created first, then implementation added to make them pass).
- `ProgressComparisonBloc` uses Dart 3 record `.wait` syntax to parallelize cloud RPC + local drift reads.
- `GetOwnWeeklySummaryUseCase._thisWeekMinutes` derives ISO week label `DD/MM` from `DateTime.now().toUtc()`, matching `ProgressLocalDataSource` convention (E10R-2-aware).
- `SocialPage` extended from 2 to 3 tabs: `TabController(length: 3)` + added "Confronto" tab and `ProgressComparisonBloc` provider.
- ARB: 5 keys added to both `app_en.arb` and `app_it.arb` (`comparisonScreenTitle`, `comparisonThisWeek`, `comparisonSessions`, `comparisonMinutes`, `comparisonEmptyFriends`).
- `ProgressComparisonBloc` provided at `SocialPage.MultiBlocProvider` level; event dispatched from `_ComparisonViewState.initState` (NOT at provider creation time — avoids pre-mount dispatch issue).
- Error state always shows `l10n.socialGenericError` (never raw failure message) per Story 18.3 review finding.
- `_safeFromJson` per-row try/catch degrades gracefully on bad RPC rows.
- 10 new tests (3 DS, 4 Bloc, 3 Widget) all green; full suite 1056 tests passed.

### File List

**New files:**
- `supabase/migrations/0007_friends_progress_rpc.sql`
- `pulse_coach/lib/features/social/comparison/domain/entities/progress_comparison_entry.dart`
- `pulse_coach/lib/features/social/comparison/domain/entities/progress_comparison_entry.freezed.dart`
- `pulse_coach/lib/features/social/comparison/domain/repositories/progress_comparison_repository.dart`
- `pulse_coach/lib/features/social/comparison/domain/usecases/get_friends_comparison_use_case.dart`
- `pulse_coach/lib/features/social/comparison/domain/usecases/get_own_weekly_summary_use_case.dart`
- `pulse_coach/lib/features/social/comparison/data/models/friend_progress_dto.dart`
- `pulse_coach/lib/features/social/comparison/data/datasources/progress_comparison_remote_data_source.dart`
- `pulse_coach/lib/features/social/comparison/data/repositories/progress_comparison_repository_impl.dart`
- `pulse_coach/lib/features/social/comparison/presentation/bloc/progress_comparison_event.dart`
- `pulse_coach/lib/features/social/comparison/presentation/bloc/progress_comparison_state.dart`
- `pulse_coach/lib/features/social/comparison/presentation/bloc/progress_comparison_state.freezed.dart`
- `pulse_coach/lib/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart`
- `pulse_coach/lib/features/social/comparison/presentation/pages/progress_comparison_page.dart`
- `pulse_coach/lib/features/social/comparison/presentation/widgets/comparison_row.dart`
- `pulse_coach/test/data/social/progress_comparison_remote_data_source_test.dart`
- `pulse_coach/test/data/social/progress_comparison_remote_data_source_test.mocks.dart`
- `pulse_coach/test/bloc/progress_comparison_bloc_test.dart`
- `pulse_coach/test/bloc/progress_comparison_bloc_test.mocks.dart`
- `pulse_coach/test/widget/comparison_row_test.dart`

**Modified files:**
- `pulse_coach/lib/features/social/friends/presentation/pages/social_page.dart` (+3rd tab, +ProgressComparisonBloc provider)
- `pulse_coach/lib/l10n/app/app_en.arb` (+5 keys)
- `pulse_coach/lib/l10n/app/app_it.arb` (+5 keys)
- `pulse_coach/lib/core/di/injection.config.dart` (DI updated by build_runner)

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-24 | 1.0.0 | Story created. | claude-sonnet-4-6 |
| 2026-06-24 | 1.1.0 | Story implemented: comparison module, 3-tab SocialPage, ARB keys, 10 new tests. | claude-sonnet-4-6 |
