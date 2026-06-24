// [18.2-WIDGET-NEW-003..004] QrCodeScreen widget tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/pages/qr_code_screen.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget _wrap() => const MaterialApp(
  locale: Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: QrCodeScreen(),
);

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    '18.2-WIDGET-NEW-003: displayHandle set → QrImageView and @handle text shown',
    (tester) async {
      getIt.registerFactory<SocialProfileBloc>(
        () => _FakeSocialProfileBloc(
          const SocialProfileState.loaded(
            profile: SocialProfile(
              userId: 'u1',
              displayHandle: 'mario',
              visibilityTier: VisibilityTier.private,
            ),
          ),
        ),
      );

      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('@mario'), findsOneWidget);
    },
  );

  testWidgets(
    '18.2-WIDGET-NEW-004: displayHandle null → no-handle prompt shown',
    (tester) async {
      getIt.registerFactory<SocialProfileBloc>(
        () => _FakeSocialProfileBloc(
          const SocialProfileState.loaded(
            profile: SocialProfile(
              userId: 'u1',
              displayHandle: null,
              visibilityTier: VisibilityTier.private,
            ),
          ),
        ),
      );

      await tester.pumpWidget(_wrap());
      await tester.pump();

      expect(find.byType(QrImageView), findsNothing);
      expect(
        find.text('Imposta prima il tuo nome utente.'),
        findsOneWidget,
      );
    },
  );
}

class _FakeSocialProfileBloc extends Fake implements SocialProfileBloc {
  final SocialProfileState _state;
  _FakeSocialProfileBloc(this._state);

  @override
  SocialProfileState get state => _state;

  @override
  Stream<SocialProfileState> get stream => const Stream.empty();

  @override
  bool get isClosed => false;

  @override
  void add(SocialProfileEvent event) {}

  @override
  Future<void> close() async {}
}
