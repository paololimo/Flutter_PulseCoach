import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

part 'social_profile.freezed.dart';

@freezed
abstract class SocialProfile with _$SocialProfile {
  const factory SocialProfile({
    required String userId,
    String? displayHandle,
    required VisibilityTier visibilityTier,
  }) = _SocialProfile;
}
