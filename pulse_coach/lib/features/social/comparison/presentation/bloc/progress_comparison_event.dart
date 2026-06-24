abstract class ProgressComparisonEvent {
  const ProgressComparisonEvent();
}

class ProgressComparisonLoaded extends ProgressComparisonEvent {
  /// The current user's own display handle — sourced from SocialProfileBloc at dispatch site.
  final String ownHandle;
  const ProgressComparisonLoaded(this.ownHandle);
}
