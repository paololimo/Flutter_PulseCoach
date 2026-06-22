import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/progress/domain/entities/progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/entities/session_history_entry.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_progress_stats.dart';
import 'package:pulse_coach/features/progress/domain/usecases/get_session_history.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_stats_cubit.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/completion_rate_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/minutes_per_week_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/rpe_trend_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_history_tile.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/session_type_breakdown_chart.dart';
import 'package:pulse_coach/features/progress/presentation/widgets/weekly_goal_indicator.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/get_install_cohort_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/purchase_pro_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/restore_purchases_use_case.dart';
import 'package:pulse_coach/features/progress/presentation/bloc/progress_gating_cubit.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

import 'progress_page_test.mocks.dart';

@GenerateMocks([
  GetSessionHistory,
  GetProgressStats,
  GetInstallCohortUseCase,
  CheckEntitlementUseCase,
  PurchaseProUseCase,
  RestorePurchasesUseCase,
])
void main() {
  group('ProgressPage', () {
    late MockGetSessionHistory mockGetSessionHistory;
    late MockGetProgressStats mockGetProgressStats;
    late MockGetInstallCohortUseCase mockGetInstallCohort;
    late MockCheckEntitlementUseCase mockCheckEntitlement;
    late MockPurchaseProUseCase mockPurchasePro;
    late MockRestorePurchasesUseCase mockRestorePurchases;

    setUp(() async {
      await getIt.reset();
      mockGetSessionHistory = MockGetSessionHistory();
      mockGetProgressStats = MockGetProgressStats();
      mockGetInstallCohort = MockGetInstallCohortUseCase();
      mockCheckEntitlement = MockCheckEntitlementUseCase();
      mockPurchasePro = MockPurchaseProUseCase();
      mockRestorePurchases = MockRestorePurchasesUseCase();

      provideDummy<SubscriptionState>(const SubscriptionState.initial());

      when(
        mockGetProgressStats(),
      ).thenAnswer((_) async => const Right(_emptyStats));

      // Default: grandfathered user so full progress content is visible.
      when(
        mockGetInstallCohort(),
      ).thenAnswer((_) async => const Right('pre_v2'));

      // Default: pro tier so full content always shows.
      when(
        mockCheckEntitlement(),
      ).thenAnswer((_) async => const Right(SubscriptionTier.pro));

      getIt.registerFactory<ProgressCubit>(
        () => ProgressCubit(mockGetSessionHistory),
      );
      getIt.registerFactory<ProgressStatsCubit>(
        () => ProgressStatsCubit(mockGetProgressStats),
      );
      getIt.registerFactory<ProgressGatingCubit>(
        () => ProgressGatingCubit(mockGetInstallCohort),
      );
    });

    tearDown(() async {
      await getIt.reset();
    });

    Future<void> pumpProgressPage(WidgetTester tester) async {
      await tester.pumpWidget(
        BlocProvider<SubscriptionBloc>(
          create: (_) => SubscriptionBloc(
            mockCheckEntitlement,
            mockPurchasePro,
            mockRestorePurchases,
          ),
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ProgressPage()),
          ),
        ),
      );
    }

    testWidgets('10.1-WIDGET-001: shows shimmer when loading', (tester) async {
      final pending = Completer<Either<Failure, List<SessionHistoryEntry>>>();
      when(mockGetSessionHistory()).thenAnswer((_) => pending.future);

      await pumpProgressPage(tester);
      await tester.pump();

      expect(find.byType(ShimmerPlaceholder), findsAtLeastNWidgets(3));
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

    testWidgets('10.2-WIDGET-006: charts tab shows insufficient data text', (
      tester,
    ) async {
      when(
        mockGetSessionHistory(),
      ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));
      when(mockGetProgressStats()).thenAnswer(
        (_) async => const Right(
          ProgressStats(
            completedCount: 2,
            abandonedCount: 0,
            minutesPerWeek: [],
            rpeTrend: [],
            sessionTypeCounts: {},
            completedThisWeek: 1,
            weeklyTarget: 3,
          ),
        ),
      );

      await pumpProgressPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grafici'));
      await tester.pumpAndSettle();

      expect(
        find.text('Completa più sessioni per vedere i tuoi progressi'),
        findsOneWidget,
      );
    });

    testWidgets('10.2-WIDGET-008: charts tab shows all four chart widgets', (
      tester,
    ) async {
      when(
        mockGetSessionHistory(),
      ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));
      when(mockGetProgressStats()).thenAnswer(
        (_) async => Right(
          ProgressStats(
            completedCount: 2,
            abandonedCount: 1,
            minutesPerWeek: const [
              WeeklyMinutes(weekLabel: '25/05', totalMinutes: 45),
            ],
            rpeTrend: [
              RpeDataPoint(completedAt: DateTime(2026, 5, 25), rpeValue: 6),
            ],
            sessionTypeCounts: const {'cardio': 2, 'mobility': 1},
            completedThisWeek: 2,
            weeklyTarget: 3,
          ),
        ),
      );

      await pumpProgressPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grafici'));
      await tester.pumpAndSettle();

      expect(find.byType(MinutesPerWeekChart), findsOneWidget);
      expect(find.byType(CompletionRateChart), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.byType(RpeTrendChart), findsOneWidget);
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(find.byType(SessionTypeBreakdownChart), findsOneWidget);
    });

    testWidgets(
      '10.2-WIDGET-009: RPE chart shows empty-state when rpeTrend is empty',
      (tester) async {
        when(
          mockGetSessionHistory(),
        ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));
        when(mockGetProgressStats()).thenAnswer(
          (_) async => const Right(
            ProgressStats(
              completedCount: 3,
              abandonedCount: 0,
              minutesPerWeek: [
                WeeklyMinutes(weekLabel: '25/05', totalMinutes: 45),
              ],
              rpeTrend: [],
              sessionTypeCounts: {'cardio': 3},
              completedThisWeek: 3,
              weeklyTarget: 3,
            ),
          ),
        );

        await pumpProgressPage(tester);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Grafici'));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -350));
        await tester.pumpAndSettle();

        expect(find.text('Nessun dato RPE ancora disponibile'), findsOneWidget);
        expect(find.byType(RpeTrendChart), findsNothing);
      },
    );

    testWidgets('10.2-WIDGET-007: charts tab shows three shimmer rows', (
      tester,
    ) async {
      final pending = Completer<Either<Failure, ProgressStats>>();
      reset(mockGetProgressStats);
      when(
        mockGetSessionHistory(),
      ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));
      when(mockGetProgressStats()).thenAnswer((_) => pending.future);

      await pumpProgressPage(tester);
      await tester.pump();
      await tester.tap(find.byType(Tab).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ShimmerPlaceholder), findsNWidgets(4));
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      '10.3-WIDGET-006: weekly goal indicator stays visible above tabs',
      (tester) async {
        when(
          mockGetSessionHistory(),
        ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));
        when(mockGetProgressStats()).thenAnswer(
          (_) async => const Right(
            ProgressStats(
              completedCount: 3,
              abandonedCount: 0,
              minutesPerWeek: [
                WeeklyMinutes(weekLabel: '25/05', totalMinutes: 45),
              ],
              rpeTrend: [],
              sessionTypeCounts: {'cardio': 3},
              completedThisWeek: 2,
              weeklyTarget: 3,
            ),
          ),
        );

        await pumpProgressPage(tester);
        await tester.pumpAndSettle();

        expect(find.byType(WeeklyGoalIndicator), findsOneWidget);
        expect(find.text('2 di 3 sessioni questa settimana'), findsOneWidget);

        await tester.tap(find.text('Grafici'));
        await tester.pumpAndSettle();

        expect(find.byType(WeeklyGoalIndicator), findsOneWidget);
        expect(find.text('2 di 3 sessioni questa settimana'), findsOneWidget);
      },
    );

    testWidgets(
      '17.2-WIDGET-001: post_v2 free user sees locked banner instead of tabs',
      (tester) async {
        // Override defaults: post_v2 + free tier
        when(
          mockGetInstallCohort(),
        ).thenAnswer((_) async => const Right('post_v2'));
        when(
          mockCheckEntitlement(),
        ).thenAnswer((_) async => const Right(SubscriptionTier.signedInFree));
        when(
          mockGetSessionHistory(),
        ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));

        await pumpProgressPage(tester);
        await tester.pumpAndSettle();

        expect(
          find.text('Lo storico completo è una funzione Pro.'),
          findsOneWidget,
        );
        expect(find.byType(TabBar), findsNothing);
      },
    );

    testWidgets(
      '17.2-WIDGET-002: pre_v2 grandfathered user sees full tabs regardless of tier',
      (tester) async {
        // Override defaults: pre_v2 + free tier (grandfathered)
        when(
          mockGetInstallCohort(),
        ).thenAnswer((_) async => const Right('pre_v2'));
        when(
          mockCheckEntitlement(),
        ).thenAnswer(
          (_) async => const Right(SubscriptionTier.signedInFree),
        );
        when(
          mockGetSessionHistory(),
        ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));

        await pumpProgressPage(tester);
        await tester.pumpAndSettle();

        expect(find.byType(TabBar), findsOneWidget);
        expect(
          find.text('Lo storico completo è una funzione Pro.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '17.2-WIDGET-003: AC4 — Pro unlock reveals full content in-place reactively',
      (tester) async {
        // post_v2 free user → starts on the locked banner.
        when(
          mockGetInstallCohort(),
        ).thenAnswer((_) async => const Right('post_v2'));
        when(
          mockGetSessionHistory(),
        ).thenAnswer((_) async => const Right(<SessionHistoryEntry>[]));

        var tier = SubscriptionTier.signedInFree;
        when(mockCheckEntitlement()).thenAnswer((_) async => Right(tier));

        final subscriptionBloc = SubscriptionBloc(
          mockCheckEntitlement,
          mockPurchasePro,
          mockRestorePurchases,
        );
        addTearDown(subscriptionBloc.close);

        await tester.pumpWidget(
          BlocProvider<SubscriptionBloc>.value(
            value: subscriptionBloc,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              locale: const Locale('it'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: ProgressPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Locked: post_v2 + free.
        expect(
          find.text('Lo storico completo è una funzione Pro.'),
          findsOneWidget,
        );
        expect(find.byType(TabBar), findsNothing);

        // Purchase completes (Story 17.4) → tier flips to Pro; the root
        // SubscriptionBloc re-emits loaded(pro) and the page rebuilds in-place.
        tier = SubscriptionTier.pro;
        subscriptionBloc.add(const SubscriptionEvent.checkRequested());
        await tester.pumpAndSettle();

        expect(find.byType(TabBar), findsOneWidget);
        expect(
          find.text('Lo storico completo è una funzione Pro.'),
          findsNothing,
        );
      },
    );
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

const _emptyStats = ProgressStats(
  completedCount: 0,
  abandonedCount: 0,
  minutesPerWeek: [],
  rpeTrend: [],
  sessionTypeCounts: {},
  completedThisWeek: 0,
  weeklyTarget: 3,
);
