// [19.0-WIDGET-001] AuthError with 'email_address_invalid' failure → shows signInErrorInvalidEmail
// [19.0-WIDGET-002] AuthError with generic failure → shows signInErrorGeneric
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/widgets/sign_in_sheet.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class _FakeAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Widget _wrap(AuthBloc bloc) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child!,
  ),
  home: BlocProvider<AuthBloc>.value(
    value: bloc,
    child: const Scaffold(
      body: SingleChildScrollView(child: SignInSheet()),
    ),
  ),
);

void main() {
  group('SignInSheet error display (19.0)', () {
    test('sanity: AuthFailure equality', () {
      expect(
        const AuthFailure('email_address_invalid'),
        equals(const AuthFailure('email_address_invalid')),
      );
    });

    testWidgets(
      '19.0-WIDGET-001: AuthError email_address_invalid → shows signInErrorInvalidEmail',
      (tester) async {
        final bloc = _FakeAuthBloc();
        whenListen(
          bloc,
          Stream.value(
            const AuthState.error(
              failure: AuthFailure('email_address_invalid'),
            ),
          ),
          initialState: const AuthState.error(
            failure: AuthFailure('email_address_invalid'),
          ),
        );

        await tester.pumpWidget(_wrap(bloc));
        await tester.pump();

        // Italian ARB key value
        expect(
          find.text('Indirizzo email non valido. Usa un indirizzo reale.'),
          findsOneWidget,
        );
        expect(
          find.text('Accesso non riuscito. Riprova.'),
          findsNothing,
        );

        await bloc.close();
      },
    );

    testWidgets(
      '19.0-WIDGET-002: AuthError generic failure → shows signInErrorGeneric',
      (tester) async {
        final bloc = _FakeAuthBloc();
        whenListen(
          bloc,
          Stream.value(
            const AuthState.error(failure: AuthFailure('network error')),
          ),
          initialState:
              const AuthState.error(failure: AuthFailure('network error')),
        );

        await tester.pumpWidget(_wrap(bloc));
        await tester.pump();

        expect(
          find.text('Accesso non riuscito. Riprova.'),
          findsOneWidget,
        );
        expect(
          find.text('Indirizzo email non valido. Usa un indirizzo reale.'),
          findsNothing,
        );

        await bloc.close();
      },
    );
  });
}
