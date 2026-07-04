import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/ai/state_machine/behavioral_state.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/leaderboard/data/rank_freeze_store.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/rank_pinning.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/usecases/get_friends_leaderboard_use_case.dart';

import 'leaderboard_event.dart';
import 'leaderboard_state.dart';

@injectable
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final GetFriendsLeaderboardUseCase _getLeaderboard;
  final RankFreezeStore _freezeStore;
  final AppDatabase _db;

  LeaderboardBloc(this._getLeaderboard, this._freezeStore, this._db)
    : super(const LeaderboardState.initial()) {
    on<LeaderboardLoaded>(_onLoaded);
  }

  Future<void> _onLoaded(
    LeaderboardLoaded event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(const LeaderboardState.loading());

    final result = await _getLeaderboard();
    if (result.isLeft()) {
      emit(
        LeaderboardState.error(
          failure: result.fold((f) => f, (_) => throw AssertionError()),
        ),
      );
      return;
    }
    final raw = result.getOrElse(() => []);

    // The use-case result is already wrapped in Either, but the DB read and
    // the freeze-store writes below are not — guard them so a throw (e.g. a
    // DB-closed teardown race) surfaces as an error state instead of leaving
    // the bloc wedged on `loading` forever.
    try {
      final stateRow = await _db.behavioralStateDao.getLatestState();
      final behavioralState = _parseBehavioralState(stateRow?.currentState);
      final isProtective =
          behavioralState == BehavioralState.atRisk ||
          behavioralState == BehavioralState.recovering;

      if (!isProtective) {
        // Not protective: clear any stale freeze from a prior episode and
        // show the live ranking.
        await _freezeStore.clear();
        emit(
          LeaderboardState.loaded(
            entries: RankPinning.compute(raw: raw, frozenOwnRank: null),
            isFrozen: false,
          ),
        );
        return;
      }

      var frozenRank = _freezeStore.getFrozenRank();
      var ownPresent = false;
      if (frozenRank == null) {
        // First observation of this protective episode: the live rank AT
        // THIS MOMENT becomes the frozen value (see "Resolved Ambiguity —
        // How 'the rank they held when they entered' is captured").
        final live = RankPinning.compute(raw: raw, frozenOwnRank: null);
        LeaderboardEntry? ownLive;
        for (final e in live) {
          if (e.isOwn) {
            ownLive = e;
            break;
          }
        }
        if (ownLive != null) {
          frozenRank = ownLive.rank;
          ownPresent = true;
          await _freezeStore.setFrozenRank(frozenRank);
        }
      } else {
        for (final e in raw) {
          if (e.isOwn) {
            ownPresent = true;
            break;
          }
        }
      }

      emit(
        LeaderboardState.loaded(
          entries: RankPinning.compute(raw: raw, frozenOwnRank: frozenRank),
          // Only report frozen when the pin is actually applied: a stored
          // rank with the own entry absent leaves the ranking unpinned.
          isFrozen: frozenRank != null && ownPresent,
        ),
      );
    } catch (e) {
      emit(
        LeaderboardState.error(
          failure: SocialFailure('Failed to load leaderboard: $e'),
        ),
      );
    }
  }

  // Mirrors shared_session_bloc.dart's _parseBehavioralState: unrecognized
  // or missing state defaults to `active` (fail-open to "not protective").
  BehavioralState _parseBehavioralState(String? raw) {
    if (raw == null) return BehavioralState.active;
    return switch (raw.toLowerCase()) {
      'active' => BehavioralState.active,
      'fatigued' => BehavioralState.fatigued,
      'atrisk' => BehavioralState.atRisk,
      'recovering' => BehavioralState.recovering,
      _ => BehavioralState.active,
    };
  }
}
