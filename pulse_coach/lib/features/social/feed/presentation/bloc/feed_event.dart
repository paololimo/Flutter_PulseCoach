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
