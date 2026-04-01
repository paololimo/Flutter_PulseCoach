import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_state.freezed.dart';

@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState.loading() = OnboardingLoading;
  const factory OnboardingState.disclaimerPending() = OnboardingDisclaimerPending;
  const factory OnboardingState.disclaimerAccepted() = OnboardingDisclaimerAccepted;
  const factory OnboardingState.error(String message) = OnboardingError;
}
