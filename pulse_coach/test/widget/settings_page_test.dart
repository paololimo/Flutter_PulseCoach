import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/domain/repositories/auth_repository.dart';
import 'package:pulse_coach/features/auth/domain/usecases/get_signed_in_user_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_apple_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_in_with_google_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/delete_account_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:pulse_coach/features/auth/domain/usecases/sign_up_with_email_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_state.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/locale_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/purchase_pro_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/restore_purchases_use_case.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsPage', () {
    late SharedPreferences prefs;
    late ThemeCubit themeCubit;
    late LocaleCubit localeCubit;

    Future<void> pumpSettingsPage(
      WidgetTester tester, {
      Map<String, Object> initialValues = const {},
      DataExportCubit Function() exportCubitFactory =
          _StubDataExportCubit.new,
      SubscriptionTier subscriptionTier = SubscriptionTier.accountFree,
    }) async {
      // Tall surface so the full settings ListView (now including the Language
      // section) renders — the lazy ListView would otherwise not build the
      // bottom "Esporta dati" tile in the default 600px-tall test window.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(initialValues);
      prefs = await SharedPreferences.getInstance();
      themeCubit = ThemeCubit(prefs);
      localeCubit = LocaleCubit(prefs);
      getIt.registerFactory<DataExportCubit>(exportCubitFactory);
      final authBloc = _StubAuthBloc();
      final settingsRepo = _StubEntitlementRepositoryForSettings(subscriptionTier);
      final subscriptionBloc = SubscriptionBloc(
        CheckEntitlementUseCase(settingsRepo),
        PurchaseProUseCase(settingsRepo),
        RestorePurchasesUseCase(settingsRepo),
      );
      addTearDown(() async {
        await themeCubit.close();
        await localeCubit.close();
        await authBloc.close();
        await subscriptionBloc.close();
        await getIt.reset();
      });

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: themeCubit),
              BlocProvider.value(value: localeCubit),
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<SubscriptionBloc>.value(value: subscriptionBloc),
            ],
            child: const SettingsPage(),
          ),
        ),
      );
    }

    testWidgets(
      '14.1-WIDGET-001: renders 3 theme segment labels',
      (tester) async {
        await pumpSettingsPage(tester);

        expect(find.text('Scuro'), findsOneWidget);
        expect(find.text('Chiaro'), findsOneWidget);
        expect(find.text('Sistema'), findsOneWidget);
      },
    );

    testWidgets(
      '14.1-WIDGET-002: tapping Chiaro sets ThemeMode.light',
      (tester) async {
        await pumpSettingsPage(tester);

        await tester.tap(find.text('Chiaro'));
        await tester.pump();

        expect(themeCubit.state, ThemeMode.light);
        expect(prefs.getString('theme_mode'), 'light');
      },
    );

    testWidgets(
      '14.1-WIDGET-003: selected theme is reflected in SegmentedButton',
      (tester) async {
        await pumpSettingsPage(tester, initialValues: {'theme_mode': 'system'});

        final segmentedButton = tester.widget<SegmentedButton<ThemeMode>>(
          find.byType(SegmentedButton<ThemeMode>),
        );
        expect(segmentedButton.selected, {ThemeMode.system});
      },
    );

    testWidgets(
      '14.5-WIDGET-001: renders data export settings entry',
      (tester) async {
        await pumpSettingsPage(tester);

        expect(find.text('Dati'), findsOneWidget);
        expect(find.text('Esporta dati'), findsOneWidget);
      },
    );

    testWidgets(
      '14.5-WIDGET-002: tapping export data opens format option sheet',
      (tester) async {
        await pumpSettingsPage(tester);

        await tester.tap(find.text('Esporta dati'));
        await tester.pumpAndSettle();

        expect(find.text('Esporta dati'), findsNWidgets(2));
        expect(find.text('JSON'), findsOneWidget);
        expect(find.text('CSV'), findsOneWidget);
      },
    );

    testWidgets(
      '14.5-WIDGET-003: loading state replaces format buttons with a spinner',
      (tester) async {
        final cubit = _ControllableExportCubit();
        await pumpSettingsPage(tester, exportCubitFactory: () => cubit);

        await tester.tap(find.text('Esporta dati'));
        await tester.pumpAndSettle();

        cubit.emitExporting();
        await tester.pump();
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('JSON'), findsNothing);
        expect(find.text('CSV'), findsNothing);
      },
    );

    testWidgets(
      '17.4-WIDGET-008: free user sees Scopri Pro tile, not Gestisci abbonamento',
      (tester) async {
        await pumpSettingsPage(
          tester,
          subscriptionTier: SubscriptionTier.accountFree,
        );
        await tester.pump(); // SubscriptionBloc processes self-dispatched checkRequested

        expect(find.text('Scopri Pro'), findsOneWidget);
        expect(find.text('Gestisci abbonamento'), findsNothing);
      },
    );

    testWidgets(
      '17.4-WIDGET-009: pro user sees Gestisci abbonamento tile, not Scopri Pro',
      (tester) async {
        await pumpSettingsPage(
          tester,
          subscriptionTier: SubscriptionTier.pro,
        );
        await tester.pump(); // SubscriptionBloc processes self-dispatched checkRequested

        expect(find.text('Gestisci abbonamento'), findsOneWidget);
        expect(find.text('Scopri Pro'), findsNothing);
      },
    );

    testWidgets(
      '14.5-WIDGET-004: error state shows localized SnackBar and restores buttons',
      (tester) async {
        final cubit = _ControllableExportCubit();
        await pumpSettingsPage(tester, exportCubitFactory: () => cubit);

        await tester.tap(find.text('Esporta dati'));
        await tester.pumpAndSettle();

        cubit.emitError();
        await tester.pump();
        await tester.pump();

        expect(find.text('Errore durante l\'esportazione'), findsOneWidget);
        expect(find.text('JSON'), findsOneWidget);
        expect(find.text('CSV'), findsOneWidget);
      },
    );
  });
}

class _StubDataExportCubit extends Cubit<DataExportState>
    implements DataExportCubit {
  _StubDataExportCubit() : super(const DataExportState());

  @override
  Future<void> exportCsv() async {}

  @override
  Future<void> exportJson() async {}
}

class _ControllableExportCubit extends Cubit<DataExportState>
    implements DataExportCubit {
  _ControllableExportCubit() : super(const DataExportState());

  void emitExporting() => emit(const DataExportState(isExporting: true));

  void emitError() =>
      emit(const DataExportState(errorMessage: 'export_failed'));

  @override
  Future<void> exportCsv() async {}

  @override
  Future<void> exportJson() async {}
}

class _StubAuthBloc extends AuthBloc {
  _StubAuthBloc()
      : super(
          GetSignedInUserUseCase(_StubAuthRepository()),
          SignInWithAppleUseCase(_StubAuthRepository()),
          SignInWithGoogleUseCase(_StubAuthRepository()),
          SignInWithEmailUseCase(_StubAuthRepository()),
          SignUpWithEmailUseCase(_StubAuthRepository()),
          SignOutUseCase(_StubAuthRepository()),
          DeleteAccountUseCase(_StubAuthRepository()),
        );
}

class _StubAuthRepository implements AuthRepository {
  @override
  Future<Either<AuthFailure, AuthUser>> signInWithApple() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithGoogle() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, AuthUser?>> signUp({
    required String email,
    required String password,
  }) async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, Unit>> signOut() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<AuthUser?> getSignedInUser() async => null;

  @override
  Future<Either<AuthFailure, Unit>> deleteAccount() async =>
      const Left(AuthFailure('stub'));

  @override
  Future<Either<AuthFailure, String>> exportData() async =>
      const Left(AuthFailure('stub'));
}

class _StubEntitlementRepositoryForSettings implements EntitlementRepository {
  _StubEntitlementRepositoryForSettings([
    this._tier = SubscriptionTier.accountFree,
  ]);

  final SubscriptionTier _tier;

  @override
  Future<SubscriptionTier> currentTier() async => _tier;
  @override
  Future<void> invalidateCache() async {}
  @override
  Future<Either<Failure, List<ProOffer>>> getOfferings() async =>
      const Right([]);
  @override
  Future<Either<Failure, SubscriptionTier>> purchasePro(
    String packageId,
  ) async => const Right(SubscriptionTier.pro);
  @override
  Future<Either<Failure, SubscriptionTier>> restorePurchases() async =>
      const Right(SubscriptionTier.pro);
}
