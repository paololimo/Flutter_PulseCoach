// [18.1-WIDGET-001..003] VisibilityTierSelector widget tests.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/visibility_tier.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/visibility_cubit.dart';
import 'package:pulse_coach/features/social/friends/presentation/widgets/visibility_tier_selector.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

import 'visibility_tier_selector_test.mocks.dart';

@GenerateMocks([SocialProfileBloc])
void main() {
  late MockSocialProfileBloc mockBloc;
  late VisibilityCubit cubit;

  setUp(() {
    mockBloc = MockSocialProfileBloc();
    cubit = VisibilityCubit();
    when(mockBloc.state).thenReturn(const SocialProfileState.initial());
    when(mockBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget buildWidget() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('it'),
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<SocialProfileBloc>.value(value: mockBloc),
            BlocProvider<VisibilityCubit>.value(value: cubit),
          ],
          child: const VisibilityTierSelector(),
        ),
      ),
    );
  }

  testWidgets(
    '18.1-WIDGET-001: renders two segments (Privato, Solo amici)',
    (tester) async {
      await tester.pumpWidget(buildWidget());

      expect(find.text('Privato'), findsOneWidget);
      expect(find.text('Solo amici'), findsOneWidget);
    },
  );

  testWidgets(
    '18.1-WIDGET-002: tapping Solo amici dispatches VisibilityTierUpdateRequested(friendsOnly)',
    (tester) async {
      await tester.pumpWidget(buildWidget());

      final events = <SocialProfileEvent>[];
      when(mockBloc.add(any)).thenAnswer((inv) {
        events.add(inv.positionalArguments.first as SocialProfileEvent);
      });

      await tester.tap(find.text('Solo amici'));
      await tester.pump();

      expect(events, contains(isA<VisibilityTierUpdateRequested>().having(
        (e) => e.tier,
        'tier',
        VisibilityTier.friendsOnly,
      )));
    },
  );

  testWidgets(
    '18.1-WIDGET-003: tapping Privato dispatches VisibilityTierUpdateRequested(private)',
    (tester) async {
      // Start with friendsOnly selected so Private can be tapped.
      cubit.select(VisibilityTier.friendsOnly);
      await tester.pumpWidget(buildWidget());

      final events = <SocialProfileEvent>[];
      when(mockBloc.add(any)).thenAnswer((inv) {
        events.add(inv.positionalArguments.first as SocialProfileEvent);
      });

      await tester.tap(find.text('Privato'));
      await tester.pump();

      expect(events, contains(isA<VisibilityTierUpdateRequested>().having(
        (e) => e.tier,
        'tier',
        VisibilityTier.private,
      )));
    },
  );
}
