// [E22R-2] AccountPage error localization regression tests.
// Guards against raw `failure.message` (English code/exception string) leaking
// to the SnackBar in either locale — auth + export-data error paths.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/export_data_cubit.dart';
import 'package:pulse_coach/features/auth/presentation/pages/account_page.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/visibility_cubit.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

// The raw failure codes that must NEVER reach the UI.
const _rawAuthCode = 'delete failed: PostgrestException(boom)';
const _rawExportCode = 'export failed: Exception(boom)';

class _FakeAuthBloc extends Fake implements AuthBloc {
  _FakeAuthBloc(this._state, {required Stream<AuthState> stream})
      : _stream = stream;
  final AuthState _state;
  final Stream<AuthState> _stream;

  @override
  AuthState get state => _state;
  @override
  Stream<AuthState> get stream => _stream;
  @override
  bool get isClosed => false;
  @override
  void add(AuthEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeExportDataCubit extends Fake implements ExportDataCubit {
  _FakeExportDataCubit(this._state, {required Stream<ExportDataState> stream})
      : _stream = stream;
  final ExportDataState _state;
  final Stream<ExportDataState> _stream;

  @override
  ExportDataState get state => _state;
  @override
  Stream<ExportDataState> get stream => _stream;
  @override
  bool get isClosed => false;
  @override
  Future<void> close() async {}
}

class _FakeSocialProfileBloc extends Fake implements SocialProfileBloc {
  @override
  SocialProfileState get state => const SocialProfileState.initial();
  @override
  Stream<SocialProfileState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(SocialProfileEvent event) {}
  @override
  Future<void> close() async {}
}

Widget _wrap(AuthBloc auth, ExportDataCubit export) => MaterialApp(
  locale: const Locale('it'),
  theme: AppTheme.darkTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<ExportDataCubit>.value(value: export),
    ],
    child: const AccountPage(),
  ),
);

void main() {
  setUp(() {
    getIt.registerFactory<SocialProfileBloc>(_FakeSocialProfileBloc.new);
    getIt.registerFactory<VisibilityCubit>(VisibilityCubit.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'E22R-2-WIDGET-001: AuthError shows localized generic, never the raw code',
    (tester) async {
      final authCtrl = StreamController<AuthState>.broadcast();
      final auth = _FakeAuthBloc(
        const AuthState.unauthenticated(),
        stream: authCtrl.stream,
      );
      final export = _FakeExportDataCubit(
        const ExportDataState.initial(),
        stream: const Stream.empty(),
      );

      await tester.pumpWidget(_wrap(auth, export));
      authCtrl.add(const AuthState.error(failure: AuthFailure(_rawAuthCode)));
      await tester.pump();

      expect(find.text('Operazione non riuscita. Riprova.'), findsOneWidget);
      expect(find.text(_rawAuthCode), findsNothing);

      await authCtrl.close();
    },
  );

  testWidgets(
    'E22R-2-WIDGET-002: ExportDataError shows localized generic, never the raw code',
    (tester) async {
      final exportCtrl = StreamController<ExportDataState>.broadcast();
      final auth = _FakeAuthBloc(
        const AuthState.unauthenticated(),
        stream: const Stream.empty(),
      );
      final export = _FakeExportDataCubit(
        const ExportDataState.initial(),
        stream: exportCtrl.stream,
      );

      await tester.pumpWidget(_wrap(auth, export));
      exportCtrl.add(
        const ExportDataState.error(failure: AuthFailure(_rawExportCode)),
      );
      await tester.pump();

      expect(
        find.text('Errore durante l\'esportazione dei dati. Riprova.'),
        findsOneWidget,
      );
      expect(find.text(_rawExportCode), findsNothing);

      await exportCtrl.close();
    },
  );
}
