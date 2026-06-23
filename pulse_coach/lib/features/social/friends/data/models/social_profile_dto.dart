import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';

part 'social_profile_dto.freezed.dart';
part 'social_profile_dto.g.dart';

@freezed
abstract class SocialProfileDto with _$SocialProfileDto {
  const factory SocialProfileDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'display_handle') String? displayHandle,
    @JsonKey(name: 'visibility_tier') required String visibilityTier,
  }) = _SocialProfileDto;

  factory SocialProfileDto.fromJson(Map<String, dynamic> json) =>
      _$SocialProfileDtoFromJson(json);
}

extension SocialProfileDtoMapper on SocialProfileDto {
  SocialProfile toDomain() => SocialProfile(
        userId: id,
        displayHandle: displayHandle,
        visibilityTier: VisibilityTier.fromSupabaseValue(visibilityTier),
      );
}
