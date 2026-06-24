// [18.1-WIDGET-NEW-001..003] HandleSetupSection widget tests.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/social_profile.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/widgets/handle_setup_section.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(SocialProfileState state) => MaterialApp(
  locale: const Locale('it'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: BlocProvider<SocialProfileBloc>.value(
      value: _FakeSocialProfileBloc(state),
      child: const HandleSetupSection(),
    ),
  ),
);

void main() {
  testWidgets(
    '18.1-WIDGET-NEW-001: loaded(displayHandle=null) → setup form visible',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SocialProfileState.loaded(
            profile: SocialProfile(
              userId: 'u1',
              displayHandle: null,
              visibilityTier: VisibilityTier.private,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Imposta il tuo nome utente'), findsOneWidget);
      expect(find.text('Salta per ora'), findsOneWidget);
    },
  );

  testWidgets(
    '18.1-WIDGET-NEW-002: loaded(displayHandle="mario") → @mario tile, no form',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          const SocialProfileState.loaded(
            profile: SocialProfile(
              userId: 'u1',
              displayHandle: 'mario',
              visibilityTier: VisibilityTier.private,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('@mario'), findsOneWidget);
      expect(find.text('Imposta il tuo nome utente'), findsNothing);
    },
  );

  testWidgets(
    '18.1-WIDGET-NEW-003: tap "Salta per ora" → form collapses',
    (tester) async {
      await tester.pumpWidget(_wrap(const SocialProfileState.initial()));
      await tester.pump();

      expect(find.text('Salta per ora'), findsOneWidget);

      await tester.tap(find.text('Salta per ora'));
      await tester.pump();

      expect(find.text('Imposta il tuo nome utente'), findsNothing);
      expect(find.text('Salta per ora'), findsNothing);
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
}
