import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_state.dart';

@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._getProfile, this._updateProfile)
      : super(const ProfileState.initial());

  final GetProfile _getProfile;
  final UpdateProfile _updateProfile;

  Future<void> loadProfile() async {
    emit(const ProfileState.loading());
    final result = await _getProfile();
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileState.error(failure.message)),
      (profile) => emit(ProfileState.loaded(profile)),
    );
  }

  Future<void> updateProfile(UserProfile profile) async {
    // Do NOT emit loading — keeps SegmentedButton UI stable during silent save
    final result = await _updateProfile(profile);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileState.error(failure.message)),
      (_) => emit(ProfileState.loaded(profile)),
    );
  }
}
