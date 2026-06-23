import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

abstract class SocialProfileEvent {
  const SocialProfileEvent();
}

class SocialProfileLoaded extends SocialProfileEvent {
  const SocialProfileLoaded();
}

class HandleUpdateRequested extends SocialProfileEvent {
  final String handle;
  const HandleUpdateRequested(this.handle);
}

class VisibilityTierUpdateRequested extends SocialProfileEvent {
  final VisibilityTier tier;
  const VisibilityTierUpdateRequested(this.tier);
}
