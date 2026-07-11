import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/repositories/exercise_repository.dart';
import 'package:pulse_coach/features/sessions_catalog/domain/usecases/get_exercises_by_type.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/bloc/sessions_catalog_cubit.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/widgets/session_catalog_card.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/widgets/session_catalog_detail_sheet.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

/// Stub repo returning one exercise per requested session type.
class _ExerciseRepositoryStub implements ExerciseRepository {
  @override
  Future<Either<Failure, List<Exercise>>> getExercisesByType(
    String sessionType,
  ) async {
    return Right([
      Exercise(
        id: '$sessionType-1',
        name: sessionType == 'mobility' ? 'Hip Reset' : '$sessionType session',
        description: 'Test session',
        sessionType: sessionType,
        steps: const ['Start', 'Finish'],
        durationMinutes: 5,
        difficulty: 'low',
        indoorCompatible: true,
        outdoorCompatible: true,
      ),
    ]);
  }

  @override
  Future<Either<Failure, Unit>> syncCatalog() async => const Right(unit);
}

SessionsCatalogCubit _catalogCubit() =>
    SessionsCatalogCubit(GetExercisesByType(_ExerciseRepositoryStub()));

Widget _wrap(SessionsCatalogCubit cubit) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme,
  home: Scaffold(body: SessionsPage(cubit: cubit)),
);

void main() {
  group('SessionsPage master-detail layout', () {
    testWidgets(
      'tablet width shows an inline detail pane instead of a modal',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 1300));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(_wrap(_catalogCubit()));
        await tester.pumpAndSettle();

        // Before any selection: empty-state pane, no detail body yet.
        expect(find.byType(SessionCatalogDetailPlaceholder), findsOneWidget);
        expect(find.byType(SessionCatalogDetailBody), findsNothing);

        await tester.tap(find.byType(SessionCatalogCard).first);
        await tester.pumpAndSettle();

        // Detail renders inline in the right pane (not a bottom sheet), so the
        // placeholder is replaced and no modal close button is present.
        expect(find.byType(SessionCatalogDetailBody), findsOneWidget);
        expect(find.byType(SessionCatalogDetailPlaceholder), findsNothing);
        expect(find.byIcon(Icons.close), findsNothing);
      },
    );

    testWidgets('tablet width highlights the selected master card', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1300));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(_catalogCubit()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SessionCatalogCard).first);
      await tester.pumpAndSettle();

      final selectedCard = tester.widget<SessionCatalogCard>(
        find.byType(SessionCatalogCard).first,
      );
      expect(selectedCard.selected, isTrue);
    });

    testWidgets('phone width opens the detail as a modal bottom sheet', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_wrap(_catalogCubit()));
      await tester.pumpAndSettle();

      // No split pane on phone widths.
      expect(find.byType(SessionCatalogDetailPlaceholder), findsNothing);

      await tester.tap(find.byType(SessionCatalogCard).first);
      await tester.pumpAndSettle();

      // Modal sheet carries the close (pop) affordance.
      expect(find.byType(SessionCatalogDetailSheet), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
