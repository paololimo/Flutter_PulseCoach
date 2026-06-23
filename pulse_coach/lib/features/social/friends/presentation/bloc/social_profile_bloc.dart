import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/get_social_profile_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/update_handle_use_case.dart';
import 'package:pulse_coach/features/social/friends/domain/usecases/update_visibility_tier_use_case.dart';
import 'social_profile_event.dart';
import 'social_profile_state.dart';

@injectable
class SocialProfileBloc extends Bloc<SocialProfileEvent, SocialProfileState> {
  final GetSocialProfileUseCase _getProfile;
  final UpdateHandleUseCase _updateHandle;
  final UpdateVisibilityTierUseCase _updateVisibilityTier;

  SocialProfileBloc(
    this._getProfile,
    this._updateHandle,
    this._updateVisibilityTier,
  ) : super(const SocialProfileState.initial()) {
    on<SocialProfileLoaded>(_onLoaded);
    on<HandleUpdateRequested>(_onHandleUpdate);
    on<VisibilityTierUpdateRequested>(_onVisibilityUpdate);
  }

  Future<void> _onLoaded(
      SocialProfileLoaded event, Emitter<SocialProfileState> emit) async {
    emit(const SocialProfileState.loading());
    final result = await _getProfile();
    result.fold(
      (f) => emit(SocialProfileState.error(failure: f)),
      (profile) => emit(SocialProfileState.loaded(profile: profile)),
    );
  }

  Future<void> _onHandleUpdate(
      HandleUpdateRequested event, Emitter<SocialProfileState> emit) async {
    emit(const SocialProfileState.loading());
    final result = await _updateHandle(event.handle);
    result.fold(
      (f) => emit(SocialProfileState.error(failure: f)),
      (profile) => emit(SocialProfileState.loaded(profile: profile)),
    );
  }

  Future<void> _onVisibilityUpdate(
      VisibilityTierUpdateRequested event,
      Emitter<SocialProfileState> emit) async {
    emit(const SocialProfileState.loading());
    final result = await _updateVisibilityTier(event.tier);
    result.fold(
      (f) => emit(SocialProfileState.error(failure: f)),
      (profile) => emit(SocialProfileState.loaded(profile: profile)),
    );
  }
}
