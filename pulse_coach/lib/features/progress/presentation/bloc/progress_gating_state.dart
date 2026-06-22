sealed class ProgressGatingState {
  const ProgressGatingState();
}

class ProgressGatingInitial extends ProgressGatingState {
  const ProgressGatingInitial();
}

class ProgressGatingLoaded extends ProgressGatingState {
  const ProgressGatingLoaded({required this.isGrandfathered});
  final bool isGrandfathered;
}
