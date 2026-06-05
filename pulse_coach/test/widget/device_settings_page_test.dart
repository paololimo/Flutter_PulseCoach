import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_state.dart';
import 'package:pulse_coach/features/settings/presentation/pages/device_settings_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

import 'device_settings_page_test.mocks.dart';

@GenerateMocks([DeviceSettingsCubit])
void main() {
  late MockDeviceSettingsCubit cubit;

  setUp(() {
    cubit = MockDeviceSettingsCubit();
    when(cubit.stream).thenAnswer((_) => const Stream.empty());
    when(cubit.close()).thenAnswer((_) async {});
    when(cubit.requestHealthPermission()).thenAnswer((_) async {});
    when(cubit.syncNow()).thenAnswer((_) async {});
    when(cubit.load()).thenAnswer((_) async {});
  });

  Widget buildPage(DeviceSettingsState state) {
    when(cubit.state).thenReturn(state);

    return MaterialApp(
      locale: const Locale('it'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: BlocProvider<DeviceSettingsCubit>.value(
        value: cubit,
        child: const DeviceSettingsPage(),
      ),
    );
  }

  group('DeviceSettingsPage', () {
    testWidgets('14.3-WIDGET-001: page shows health permission status label', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildPage(const DeviceSettingsState(isLoading: false)),
      );

      expect(find.text('Stato sconosciuto'), findsOneWidget);
    });

    testWidgets(
      '14.3-WIDGET-002: "Richiedi permesso" button visible when healthPermissionGranted == false',
      (tester) async {
        await tester.pumpWidget(
          buildPage(
            const DeviceSettingsState(
              isLoading: false,
              healthPermissionGranted: false,
            ),
          ),
        );

        expect(find.text('Richiedi permesso'), findsOneWidget);
      },
    );

    testWidgets(
      '14.3-WIDGET-003: "Richiedi permesso" button absent when healthPermissionGranted == true',
      (tester) async {
        await tester.pumpWidget(
          buildPage(
            const DeviceSettingsState(
              isLoading: false,
              healthPermissionGranted: true,
            ),
          ),
        );

        expect(find.text('Richiedi permesso'), findsNothing);
      },
    );

    testWidgets(
      '14.3-WIDGET-004: "Sincronizza ora" button visible when pendingSyncCount > 0 && isOnline',
      (tester) async {
        await tester.pumpWidget(
          buildPage(
            const DeviceSettingsState(
              isLoading: false,
              pendingSyncCount: 1,
              isOnline: true,
            ),
          ),
        );

        expect(find.text('Sincronizza ora'), findsOneWidget);
      },
    );

    testWidgets(
      '14.3-WIDGET-005: "Sincronizza ora" button absent when pendingSyncCount == 0',
      (tester) async {
        await tester.pumpWidget(
          buildPage(
            const DeviceSettingsState(
              isLoading: false,
              pendingSyncCount: 0,
              isOnline: true,
            ),
          ),
        );

        expect(find.text('Sincronizza ora'), findsNothing);
      },
    );
  });
}
