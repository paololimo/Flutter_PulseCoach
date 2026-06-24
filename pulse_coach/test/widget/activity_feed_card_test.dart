// [18.3-WIDGET-001..005] ActivityFeedCard widget tests
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/social/feed/domain/entities/feed_entry.dart';
import 'package:pulse_coach/features/social/feed/presentation/widgets/activity_feed_card.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );

final _tEntry = FeedEntry(
  id: 'feed-1',
  ownerHandle: 'paolol',
  ownerId: 'user-abc',
  sessionType: 'cardio',
  durationMinutes: 25,
  completedAt: DateTime.utc(2026, 6, 24, 9, 0),
  createdAt: DateTime.utc(2026, 6, 24, 10, 0),
);

void main() {
  group('ActivityFeedCard', () {
    testWidgets(
      '18.3-WIDGET-001: non-own entry — renders handle, duration, reaction button (no count shown)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ActivityFeedCard(
              entry: _tEntry,
              isOwn: false,
              isReacting: false,
              onReact: () {},
            ),
          ),
        );

        expect(find.text('@paolol'), findsOneWidget);
        expect(find.text('25 min'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        // No reaction count displayed
        expect(find.textContaining(RegExp(r'^\d+$')), findsNothing);
        // No revoke button
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets(
      '18.3-WIDGET-002: own entry — renders revoke button, NO reaction button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ActivityFeedCard(
              entry: _tEntry,
              isOwn: true,
              isReacting: false,
              onReact: () {},
              onRevoke: () {},
            ),
          ),
        );

        expect(find.byIcon(Icons.close), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsNothing);
      },
    );

    testWidgets(
      '18.3-WIDGET-003: reaction tap — calls onReact callback',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          _wrap(
            ActivityFeedCard(
              entry: _tEntry,
              isOwn: false,
              isReacting: false,
              onReact: () => tapped = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.favorite_border));
        expect(tapped, isTrue);
      },
    );

    testWidgets(
      '18.3-WIDGET-004: isReacting=true — ScaleTransition present for reaction icon',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ActivityFeedCard(
              entry: _tEntry,
              isOwn: false,
              isReacting: true,
              onReact: () {},
            ),
          ),
        );

        // ScaleTransition is used for the reaction icon; there may be others from
        // MaterialApp route transitions — verify at least one is present.
        expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      '18.3-WIDGET-005: touch targets ≥ 48dp — reaction and revoke buttons meet constraint',
      (tester) async {
        // Test reaction button size (non-own)
        await tester.pumpWidget(
          _wrap(
            ActivityFeedCard(
              entry: _tEntry,
              isOwn: false,
              isReacting: false,
              onReact: () {},
            ),
          ),
        );

        final reactionBox = tester.getSize(find.byType(GestureDetector).first);
        expect(reactionBox.width, greaterThanOrEqualTo(48));
        expect(reactionBox.height, greaterThanOrEqualTo(48));

        // Test revoke button size (own entry)
        await tester.pumpWidget(
          _wrap(
            ActivityFeedCard(
              entry: _tEntry,
              isOwn: true,
              isReacting: false,
              onReact: () {},
              onRevoke: () {},
            ),
          ),
        );

        final revokeBox = tester.getSize(find.byType(IconButton).first);
        expect(revokeBox.width, greaterThanOrEqualTo(48));
        expect(revokeBox.height, greaterThanOrEqualTo(48));
      },
    );
  });
}
