import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_state.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:shimmer/shimmer.dart';

import 'sessions_page_test.mocks.dart';

@GenerateMocks([GetExercisesByType])
void main() {
  late MockGetExercisesByType mockGetExercisesByType;

  const mobility = Exercise(
    id: 'mobility-1',
    name: 'Hip Reset',
    description: 'Open hips and restore range.',
    sessionType: 'mobility',
    steps: ['Breathe tall', 'Lunge gently', 'Rotate slowly'],
    durationMinutes: 8,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  const cardio = Exercise(
    id: 'cardio-1',
    name: 'Tempo Walk',
    description: 'A brisk walk with short pickups.',
    sessionType: 'cardio',
    steps: ['Warm up', 'Pick up pace', 'Cool down'],
    durationMinutes: 12,
    difficulty: 'medium',
    indoorCompatible: false,
    outdoorCompatible: true,
  );

  const breathing = Exercise(
    id: 'breathing-1',
    name: 'Box Breathing',
    description: 'Settle your breathing rhythm.',
    sessionType: 'breathing',
    steps: ['Inhale', 'Hold', 'Exhale', 'Hold'],
    durationMinutes: 5,
    difficulty: 'low',
    indoorCompatible: true,
    outdoorCompatible: true,
  );

  setUp(() {
    mockGetExercisesByType = MockGetExercisesByType();
  });

  void stubCatalog() {
    when(
      mockGetExercisesByType.call('mobility'),
    ).thenAnswer((_) async => const Right([mobility]));
    when(
      mockGetExercisesByType.call('cardio'),
    ).thenAnswer((_) async => const Right([cardio]));
    when(
      mockGetExercisesByType.call('breathing'),
    ).thenAnswer((_) async => const Right([breathing]));
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    SessionsCatalogCubit? cubit,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SessionsPage(
            cubit: cubit ?? SessionsCatalogCubit(mockGetExercisesByType),
          ),
        ),
      ),
    );
  }

  group('SessionsPage', () {
    testWidgets('6.3-WIDGET-001: renders grouped category headers and cards', (
      tester,
    ) async {
      stubCatalog();

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Mobility'), findsWidgets);
      expect(find.text('Cardio'), findsWidgets);
      expect(find.text('Breathing'), findsWidgets);
      expect(find.text('Hip Reset'), findsOneWidget);
      expect(find.text('Tempo Walk'), findsOneWidget);
      expect(find.text('Box Breathing'), findsOneWidget);
    });

    testWidgets('6.3-WIDGET-002: filter chip hides other categories', (
      tester,
    ) async {
      stubCatalog();

      await pumpPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'Cardio'));
      await tester.pumpAndSettle();

      final selectedChip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, 'Cardio'),
      );
      expect(selectedChip.selected, isTrue);
      expect(find.text('Tempo Walk'), findsOneWidget);
      expect(find.text('Hip Reset'), findsNothing);
      expect(find.text('Box Breathing'), findsNothing);
    });

    testWidgets(
      '6.3-WIDGET-003: loading uses shimmer placeholders and no spinner',
      (tester) async {
        final pending = Completer<Either<Failure, List<Exercise>>>();
        when(
          mockGetExercisesByType.call('mobility'),
        ).thenAnswer((_) => pending.future);

        await pumpPage(tester);
        await tester.pump();

        expect(find.byType(Shimmer), findsWidgets);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('6.3-WIDGET-004: card tap opens detail sheet content', (
      tester,
    ) async {
      stubCatalog();

      await pumpPage(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hip Reset'));
      await tester.pumpAndSettle();

      expect(find.text('Open hips and restore range.'), findsOneWidget);
      expect(find.text('8 min'), findsWidgets);
      expect(find.text('Low intensity'), findsOneWidget);
      expect(find.text('1. Breathe tall'), findsOneWidget);
      expect(find.text('2. Lunge gently'), findsOneWidget);
      expect(find.text('3. Rotate slowly'), findsOneWidget);
    });

    testWidgets('6.3-WIDGET-005: narrow phone layout does not overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      stubCatalog();

      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '6.3-WIDGET-006: selected trailing filter chip scrolls fully into view',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        stubCatalog();
        final cubit = SessionsCatalogCubit(mockGetExercisesByType);
        addTearDown(cubit.close);

        await pumpPage(tester, cubit: cubit);
        await tester.pumpAndSettle();

        final breathingFinder = find.widgetWithText(FilterChip, 'Breathing');
        final initialRect = tester.getRect(breathingFinder);
        expect(initialRect.right, greaterThan(tester.view.physicalSize.width));

        cubit.selectCategory(SessionsCatalogCategory.breathing);
        await tester.pumpAndSettle();

        final selectedChip = tester.widget<FilterChip>(breathingFinder);
        final selectedRect = tester.getRect(breathingFinder);
        expect(selectedChip.selected, isTrue);
        expect(selectedRect.left, greaterThanOrEqualTo(0));
        expect(
          selectedRect.right,
          lessThanOrEqualTo(tester.view.physicalSize.width),
        );
      },
    );
  });
}
