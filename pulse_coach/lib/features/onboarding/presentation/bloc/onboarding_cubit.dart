import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';

@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(
    this._acceptDisclaimer,
    this._checkDisclaimerStatus,
    this._saveProfile,
  ) : super(const OnboardingState.disclaimerPending());

  final AcceptDisclaimer _acceptDisclaimer;
  final CheckDisclaimerStatus _checkDisclaimerStatus;
  final SaveProfile _saveProfile;

  /// Called on page init — skips disclaimer screen if already accepted.
  Future<void> checkInitialStatus() async {
    final result = await _checkDisclaimerStatus();
    result.fold(
      (_) {}, // ignore error — stay at disclaimerPending
      (accepted) {
        if (accepted) emit(const OnboardingState.disclaimerAccepted());
      },
    );
  }

  void completeOnboardingFlow() {
    emit(const OnboardingState.profileSetupReady());
  }

  Future<void> acceptDisclaimer() async {
    if (state is OnboardingLoading) return;
    emit(const OnboardingState.loading());
    final result = await _acceptDisclaimer();
    result.fold(
      (failure) => emit(OnboardingState.error(failure.message)),
      (_) => emit(const OnboardingState.disclaimerAccepted()),
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    if (state is OnboardingLoading) return;
    emit(const OnboardingState.loading());
    final result = await _saveProfile(profile);
    result.fold(
      (failure) => emit(OnboardingState.error(failure.message)),
      (_) => emit(const OnboardingState.onboardingComplete()),
    );
  }
}
