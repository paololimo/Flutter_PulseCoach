import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';

part 'social_profile_state.freezed.dart';

@freezed
class SocialProfileState with _$SocialProfileState {
  const factory SocialProfileState.initial() = _Initial;
  const factory SocialProfileState.loading() = _Loading;
  const factory SocialProfileState.loaded({
    required SocialProfile profile,
  }) = _Loaded;
  const factory SocialProfileState.error({
    required Failure failure,
  }) = _Error;
}
