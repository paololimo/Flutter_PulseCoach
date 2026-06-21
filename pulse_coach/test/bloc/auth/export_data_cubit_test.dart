import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/usecases/export_data_use_case.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/export_data_cubit.dart';

import 'export_data_cubit_test.mocks.dart';

@GenerateMocks([ExportDataUseCase])
void main() {
  late MockExportDataUseCase mockExportData;

  const tJson = '{"userId":"abc","email":"test@example.com"}';
  const tFailure = AuthFailure('export failed');

  setUp(() {
    mockExportData = MockExportDataUseCase();
  });

  ExportDataCubit cubit() => ExportDataCubit(mockExportData);

  group('ExportDataCubit.exportData', () {
    blocTest<ExportDataCubit, ExportDataState>(
      'emits [loading, success] on success',
      build: cubit,
      setUp: () => when(mockExportData.call())
          .thenAnswer((_) async => const Right(tJson)),
      act: (c) => c.exportData(),
      expect: () => [
        const ExportDataState.loading(),
        const ExportDataState.success(json: tJson),
      ],
    );

    blocTest<ExportDataCubit, ExportDataState>(
      'emits [loading, error] on failure',
      build: cubit,
      setUp: () => when(mockExportData.call())
          .thenAnswer((_) async => const Left(tFailure)),
      act: (c) => c.exportData(),
      expect: () => [
        const ExportDataState.loading(),
        const ExportDataState.error(failure: tFailure),
      ],
    );
  });
}
