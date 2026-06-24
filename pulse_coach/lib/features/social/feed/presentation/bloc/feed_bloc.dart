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
    final current = state.mapOrNull(loaded: (s) => s);
    if (current == null) return; // a reaction only makes sense on a loaded feed
    // Guard against a rapid double-tap firing a duplicate increment RPC.
    if (current.reactingIds.contains(event.feedEntryId)) return;
    // Optimistic: flag the card so its reaction animation plays immediately.
    emit(current.copyWith(
        reactingIds: {...current.reactingIds, event.feedEntryId}));
    await _reactToEntry(event.feedEntryId);
    // Re-read the latest loaded state — the list may have changed during the await.
    final updated = state.mapOrNull(loaded: (s) => s);
    if (updated == null) return;
    final newSet = Set<String>.from(updated.reactingIds)
      ..remove(event.feedEntryId);
    // A light reaction is best-effort: on failure just drop the optimistic flag
    // and keep the feed intact rather than collapsing the whole list to an error.
    emit(updated.copyWith(reactingIds: newSet));
  }

  Future<void> _onRevoke(FeedEntryRevoked event, Emitter<FeedState> emit) async {
    final result = await _revokeEntry(event.feedEntryId);
    result.fold(
      (f) => emit(FeedState.error(failure: f)),
      (_) => add(const FeedLoaded()), // reload feed after revoke
    );
  }
}
