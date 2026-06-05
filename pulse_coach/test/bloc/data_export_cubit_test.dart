import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/features/settings/data/services/data_export_service.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_state.dart';

import 'data_export_cubit_test.mocks.dart';

@GenerateMocks([DataExportService])
void main() {
  late MockDataExportService service;

  setUp(() {
    service = MockDataExportService();
  });

  blocTest<DataExportCubit, DataExportState>(
    '14.5-CUBIT-001: exportJson emits loading then success',
    build: () => DataExportCubit(service),
    setUp: () {
      when(service.exportJson()).thenAnswer((_) async {});
    },
    act: (cubit) => cubit.exportJson(),
    expect: () => [
      const DataExportState(isExporting: true),
      const DataExportState(isExporting: false),
    ],
  );

  blocTest<DataExportCubit, DataExportState>(
    '14.5-CUBIT-002: exportCsv emits loading then success',
    build: () => DataExportCubit(service),
    setUp: () {
      when(service.exportCsv()).thenAnswer((_) async {});
    },
    act: (cubit) => cubit.exportCsv(),
    expect: () => [
      const DataExportState(isExporting: true),
      const DataExportState(isExporting: false),
    ],
  );

  blocTest<DataExportCubit, DataExportState>(
    '14.5-CUBIT-003: exportJson emits loading then error when service throws',
    build: () => DataExportCubit(service),
    setUp: () {
      when(service.exportJson()).thenThrow(Exception('export failed'));
    },
    act: (cubit) => cubit.exportJson(),
    expect: () => [
      const DataExportState(isExporting: true),
      const DataExportState(
        isExporting: false,
        errorMessage: 'export_failed',
      ),
    ],
  );

  blocTest<DataExportCubit, DataExportState>(
    '14.5-CUBIT-004: exportCsv emits loading then error when service throws',
    build: () => DataExportCubit(service),
    setUp: () {
      when(service.exportCsv()).thenThrow(Exception('export failed'));
    },
    act: (cubit) => cubit.exportCsv(),
    expect: () => [
      const DataExportState(isExporting: true),
      const DataExportState(
        isExporting: false,
        errorMessage: 'export_failed',
      ),
    ],
  );
}
