import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = ProfileInitial;
  const factory ProfileState.loading() = ProfileLoading;
  const factory ProfileState.loaded(UserProfile profile) = ProfileLoaded;
  const factory ProfileState.error(String message) = ProfileError;
}
