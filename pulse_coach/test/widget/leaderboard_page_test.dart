import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/social/leaderboard/domain/entities/leaderboard_entry.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_bloc.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_event.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/bloc/leaderboard_state.dart';
import 'package:pulse_coach/features/social/leaderboard/presentation/pages/leaderboard_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(_FakeLeaderboardBloc bloc) => MaterialApp(
  locale: const Locale('it'),
  theme: AppTheme.darkTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: BlocProvider<LeaderboardBloc>.value(
      value: bloc,
      child: const LeaderboardPage(),
    ),
  ),
);

void main() {
  testWidgets(
    '[21.2-WIDGET-001] loaded, 3+ entries → medal labels for top 3, points count for rank 4+',
    (tester) async {
      final bloc = _FakeLeaderboardBloc(
        const LeaderboardState.loaded(
          entries: [
            LeaderboardEntry(
              userId: '1',
              displayHandle: 'alice',
              totalPoints: 100,
              isOwn: false,
              rank: 1,
            ),
            LeaderboardEntry(
              userId: '2',
              displayHandle: 'bob',
              totalPoints: 80,
              isOwn: false,
              rank: 2,
            ),
            LeaderboardEntry(
              userId: '3',
              displayHandle: 'carl',
              totalPoints: 50,
              isOwn: true,
              rank: 3,
            ),
            LeaderboardEntry(
              userId: '4',
              displayHandle: 'dave',
              totalPoints: 10,
              isOwn: false,
              rank: 4,
            ),
          ],
          isFrozen: false,
        ),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();

      expect(find.text('1° oro'), findsOneWidget);
      expect(find.text('2° argento'), findsOneWidget);
      expect(find.text('3° bronzo'), findsOneWidget);
      expect(find.text('10 punti'), findsOneWidget);
    },
  );

  testWidgets(
    '[21.2-WIDGET-002] loaded, empty entries → empty-state text shown, no crash',
    (tester) async {
      final bloc = _FakeLeaderboardBloc(
        const LeaderboardState.loaded(entries: [], isFrozen: false),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();

      expect(find.text('Nessun amico in classifica.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '[21.2-WIDGET-003] error state → generic localized SnackBar shown, never raw failure.message',
    (tester) async {
      const rawMessage = 'Failed to load leaderboard: Bad state';
      final controller = StreamController<LeaderboardState>.broadcast();
      addTearDown(controller.close);
      final bloc = _FakeLeaderboardBloc(
        const LeaderboardState.loading(),
        stream: controller.stream,
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();

      controller.add(
        const LeaderboardState.error(failure: SocialFailure(rawMessage)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));

      expect(find.text('Qualcosa è andato storto. Riprova.'), findsOneWidget);
      expect(find.text(rawMessage), findsNothing);
    },
  );

  testWidgets(
    '[21.2-WIDGET-004] no AnimatedSwitcher or implicit-animation widget present anywhere (AC6 guard)',
    (tester) async {
      final bloc = _FakeLeaderboardBloc(
        const LeaderboardState.loaded(
          entries: [
            LeaderboardEntry(
              userId: '1',
              displayHandle: 'alice',
              totalPoints: 100,
              isOwn: false,
              rank: 1,
            ),
          ],
          isFrozen: false,
        ),
      );

      await tester.pumpWidget(_wrap(bloc));
      await tester.pump();

      expect(find.byType(AnimatedSwitcher), findsNothing);
    },
  );
}

class _FakeLeaderboardBloc extends Fake implements LeaderboardBloc {
  final LeaderboardState _state;
  final Stream<LeaderboardState> _stream;
  _FakeLeaderboardBloc(this._state, {Stream<LeaderboardState>? stream})
    : _stream = stream ?? const Stream.empty();

  @override
  LeaderboardState get state => _state;

  @override
  Stream<LeaderboardState> get stream => _stream;

  @override
  bool get isClosed => false;

  @override
  void add(LeaderboardEvent event) {}

  @override
  Future<void> close() async {}
}
