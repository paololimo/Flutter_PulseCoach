import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/accept_request_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/decline_request_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_friends_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_pending_requests_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/remove_friend_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/search_by_handle_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/send_friend_request_use_case.dart';
import 'friends_event.dart';
import 'friends_state.dart';

@injectable
class FriendsBloc extends Bloc<FriendsEvent, FriendsState> {
  final GetFriendsUseCase _getFriends;
  final GetPendingRequestsUseCase _getPendingRequests;
  final SearchByHandleUseCase _searchByHandle;
  final SendFriendRequestUseCase _sendRequest;
  final AcceptRequestUseCase _acceptRequest;
  final DeclineRequestUseCase _declineRequest;
  final RemoveFriendUseCase _removeFriend;

  FriendsBloc(
    this._getFriends,
    this._getPendingRequests,
    this._searchByHandle,
    this._sendRequest,
    this._acceptRequest,
    this._declineRequest,
    this._removeFriend,
  ) : super(const FriendsState.initial()) {
    on<FriendsLoaded>(_onLoaded);
    on<FriendSearchRequested>(_onSearch);
    on<FriendRequestSent>(_onSendRequest);
    on<FriendRequestAccepted>(_onAccept);
    on<FriendRequestDeclined>(_onDecline);
    on<FriendRemoved>(_onRemove);
  }

  Future<void> _onLoaded(
      FriendsLoaded event, Emitter<FriendsState> emit) async {
    emit(const FriendsState.loading());
    final friendsResult = await _getFriends();
    final requestsResult = await _getPendingRequests();
    friendsResult.fold(
      (f) => emit(FriendsState.error(failure: f)),
      (friends) => requestsResult.fold(
        (f) => emit(FriendsState.error(failure: f)),
        (requests) => emit(FriendsState.loaded(
          friends: friends,
          pendingRequests: requests,
        )),
      ),
    );
  }

  Future<void> _onSearch(
      FriendSearchRequested event, Emitter<FriendsState> emit) async {
    final wasLoaded = state.mapOrNull<bool>(
      loaded: (s) {
        emit(s.copyWith(searchResult: null, requestSent: false));
        return true;
      },
    );
    if (wasLoaded == null) emit(const FriendsState.loading());

    final result = await _searchByHandle(event.handle.trim());
    result.fold(
      (f) => emit(FriendsState.error(failure: f)),
      (profile) {
        final nowLoaded = state.mapOrNull<bool>(
          loaded: (s) {
            emit(s.copyWith(searchResult: profile, requestSent: false));
            return true;
          },
        );
        if (nowLoaded == null) add(const FriendsLoaded());
      },
    );
  }

  Future<void> _onSendRequest(
      FriendRequestSent event, Emitter<FriendsState> emit) async {
    final result = await _sendRequest(event.addresseeId);
    result.fold(
      (f) => emit(FriendsState.error(failure: f)),
      (_) => state.mapOrNull<void>(
        loaded: (s) => emit(s.copyWith(requestSent: true)),
      ),
    );
  }

  Future<void> _onAccept(
      FriendRequestAccepted event, Emitter<FriendsState> emit) async {
    final result = await _acceptRequest(event.friendshipId);
    result.fold(
      (f) => emit(FriendsState.error(failure: f)),
      (_) => add(const FriendsLoaded()),
    );
  }

  Future<void> _onDecline(
      FriendRequestDeclined event, Emitter<FriendsState> emit) async {
    final result = await _declineRequest(event.friendshipId);
    result.fold(
      (f) => emit(FriendsState.error(failure: f)),
      (_) => add(const FriendsLoaded()),
    );
  }

  Future<void> _onRemove(
      FriendRemoved event, Emitter<FriendsState> emit) async {
    final result = await _removeFriend(event.friendshipId);
    result.fold(
      (f) => emit(FriendsState.error(failure: f)),
      (_) => add(const FriendsLoaded()),
    );
  }
}
