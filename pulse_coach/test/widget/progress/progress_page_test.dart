import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

import 'progress_page_test.mocks.dart';

@GenerateMocks([GetSessionHistory])
void main() {
  group('ProgressPage', () {
    late MockGetSessionHistory mockGetSessionHistory;

    setUp(() async {
      await getIt.reset();
      mockGetSessionHistory = MockGetSessionHistory();
      getIt.registerFactory<ProgressCubit>(
        () => ProgressCubit(mockGetSessionHistory),
      );
    });

    tearDown(() async {
      await getIt.reset();
    });

    Future<void> pumpProgressPage(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          locale: const Locale('it'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: ProgressPage()),
        ),
      );
    }

    testWidgets('10.1-WIDGET-001: shows shimmer when loading', (tester) async {
      final pending = Completer<Either<Failure, List<SessionHistoryEntry>>>();
      when(mockGetSessionHistory()).thenAnswer((_) => pending.future);

      await pumpProgressPage(tester);
      await tester.pump();

      expect(find.byType(ShimmerPlaceholder), findsNWidgets(3));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('10.1-WIDGET-002: shows empty state when no entries', (
      tester,
    ) async {
      when(
        mockGetSessionHistory(),
      ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));

      await pumpProgressPage(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Nessuna sessione ancora. Inizia la tua prima oggi!'),
        findsOneWidget,
      );
    });

    testWidgets('10.1-WIDGET-003: shows session tiles for loaded entries', (
      tester,
    ) async {
      when(
        mockGetSessionHistory(),
      ).thenAnswer((_) async => Right([_entry(sessionType: 'cardio')]));

      await pumpProgressPage(tester);
      await tester.pumpAndSettle();

      expect(find.byType(SessionHistoryTile), findsOneWidget);
      expect(find.text('Cardio'), findsOneWidget);
      expect(find.text('RPE 7'), findsOneWidget);
    });

    testWidgets('10.1-WIDGET-004: error state shows error message', (
      tester,
    ) async {
      when(mockGetSessionHistory()).thenAnswer(
        (_) async => const Left(CacheFailure('progress_history_load_failed')),
      );

      await pumpProgressPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Impossibile caricare la cronologia'), findsOneWidget);
    });

    testWidgets('10.1-WIDGET-005: abandoned tile rendered at reduced opacity', (
      tester,
    ) async {
      when(mockGetSessionHistory()).thenAnswer(
        (_) async => Right([
          _entry(
            sessionType: 'mobility',
            abandoned: true,
            rpeValue: null,
            elapsedSeconds: 185,
          ),
        ]),
      );

      await pumpProgressPage(tester);
      await tester.pumpAndSettle();

      final opacityFinder = find.ancestor(
        of: find.byType(ListTile),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsOneWidget);
      final opacity = tester.widget<Opacity>(opacityFinder);
      expect(opacity.opacity, lessThanOrEqualTo(0.5));
      expect(find.text('—'), findsOneWidget);
    });
  });
}

SessionHistoryEntry _entry({
  required String sessionType,
  bool abandoned = false,
  int? rpeValue = 7,
  int? elapsedSeconds,
}) {
  return SessionHistoryEntry(
    sessionLogId: 1,
    completedAt: DateTime.utc(2026, 5, 24, 8, 30),
    sessionType: sessionType,
    durationMinutes: 20,
    abandoned: abandoned,
    rpeValue: rpeValue,
    elapsedSeconds: elapsedSeconds,
  );
}
