import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:pulse_coach/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/accept_disclaimer.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/check_disclaimer_status.dart';
import 'package:pulse_coach/features/onboarding/domain/usecases/save_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(prefs));
    getIt.registerLazySingleton<LocaleCubit>(() => LocaleCubit(prefs));
    getIt.registerSingleton<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(getIt<AppDatabase>()),
    );
    getIt.registerFactory<AcceptDisclaimer>(
      () => AcceptDisclaimer(getIt<OnboardingRepository>()),
    );
    getIt.registerFactory<CheckDisclaimerStatus>(
      () => CheckDisclaimerStatus(getIt<OnboardingRepository>()),
    );
    getIt.registerFactory<SaveProfile>(
      () => SaveProfile(getIt<OnboardingRepository>()),
    );
    getIt.registerFactory<OnboardingCubit>(
      () => OnboardingCubit(
        getIt<AcceptDisclaimer>(),
        getIt<CheckDisclaimerStatus>(),
        getIt<SaveProfile>(),
      ),
    );
  });

  tearDown(() async {
    await getIt.get<AppDatabase>().close();
    await getIt.reset();
  });

  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const PulseCoachApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets(
    '7.5-L10N-001: app forces Italian locale and registers localization delegates',
    (tester) async {
      await tester.pumpWidget(const PulseCoachApp());
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, equals(const Locale('it')));
      expect(app.localizationsDelegates, contains(AppLocalizations.delegate));
      expect(
        app.supportedLocales,
        containsAll([const Locale('en'), const Locale('it')]),
      );
    },
  );
}
