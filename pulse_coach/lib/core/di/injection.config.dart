// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:pulse_coach/core/database/app_database.dart' as _i79;
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i462;
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i338;
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart'
    as _i944;
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart'
    as _i145;
import 'package:pulse_coach/features/onboarding/domain/usecases/get_profile.dart'
    as _i529;
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart'
    as _i280;
import 'package:pulse_coach/features/onboarding/domain/usecases/update_profile.dart'
    as _i926;
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart'
    as _i472;
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart'
    as _i901;
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart'
    as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i79.AppDatabase>(() => _i79.AppDatabase());
    gh.lazySingleton<_i291.ThemeCubit>(() => _i291.ThemeCubit());
    gh.lazySingleton<_i338.OnboardingRepository>(
      () => _i462.OnboardingRepositoryImpl(gh<_i79.AppDatabase>()),
    );
    gh.factory<_i944.AcceptDisclaimer>(
      () => _i944.AcceptDisclaimer(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i145.CheckDisclaimerStatus>(
      () => _i145.CheckDisclaimerStatus(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i529.GetProfile>(
      () => _i529.GetProfile(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i280.SaveProfile>(
      () => _i280.SaveProfile(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i926.UpdateProfile>(
      () => _i926.UpdateProfile(gh<_i338.OnboardingRepository>()),
    );
    gh.factory<_i901.ProfileCubit>(
      () =>
          _i901.ProfileCubit(gh<_i529.GetProfile>(), gh<_i926.UpdateProfile>()),
    );
    gh.factory<_i472.OnboardingCubit>(
      () => _i472.OnboardingCubit(
        gh<_i944.AcceptDisclaimer>(),
        gh<_i145.CheckDisclaimerStatus>(),
        gh<_i280.SaveProfile>(),
      ),
    );
    return this;
  }
}
