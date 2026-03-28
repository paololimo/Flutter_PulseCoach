import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/app.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/theme_cubit.dart';

void main() {
  setUp(() {
    getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
    getIt.registerSingleton<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
  });

  tearDown(() async {
    await getIt.get<AppDatabase>().close();
    await getIt.reset();
  });

  testWidgets('App smoke test — renders without crashing', (tester) async {
    await tester.pumpWidget(const PulseCoachApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
