abstract class FriendsEvent {
  const FriendsEvent();
}

class FriendsLoaded extends FriendsEvent {
  const FriendsLoaded();
}

class FriendSearchRequested extends FriendsEvent {
  final String handle;
  const FriendSearchRequested(this.handle);
}

class FriendRequestSent extends FriendsEvent {
  final String addresseeId;
  const FriendRequestSent(this.addresseeId);
}

class FriendRequestAccepted extends FriendsEvent {
  final String friendshipId;
  const FriendRequestAccepted(this.friendshipId);
}

class FriendRequestDeclined extends FriendsEvent {
  final String friendshipId;
  const FriendRequestDeclined(this.friendshipId);
}

class FriendRemoved extends FriendsEvent {
  final String friendshipId;
  const FriendRemoved(this.friendshipId);
}
