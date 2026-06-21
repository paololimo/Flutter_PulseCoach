import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/auth/domain/usecases/export_data_use_case.dart';

part 'export_data_cubit.freezed.dart';

@freezed
sealed class ExportDataState with _$ExportDataState {
  const factory ExportDataState.initial() = ExportDataInitial;
  const factory ExportDataState.loading() = ExportDataLoading;
  const factory ExportDataState.success({required String json}) =
      ExportDataSuccess;
  const factory ExportDataState.error({required AuthFailure failure}) =
      ExportDataError;
}

@injectable
class ExportDataCubit extends Cubit<ExportDataState> {
  final ExportDataUseCase _exportData;
  ExportDataCubit(this._exportData) : super(const ExportDataState.initial());

  Future<void> exportData() async {
    emit(const ExportDataState.loading());
    final result = await _exportData.call();
    result.fold(
      (failure) => emit(ExportDataState.error(failure: failure)),
      (json) => emit(ExportDataState.success(json: json)),
    );
  }
}
