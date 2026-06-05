import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/features/settings/data/services/data_export_service.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/data_export_state.dart';

@injectable
class DataExportCubit extends Cubit<DataExportState> {
  DataExportCubit(this._exportService) : super(const DataExportState());

  final DataExportService _exportService;

  Future<void> exportJson() async {
    emit(const DataExportState(isExporting: true));
    try {
      await _exportService.exportJson();
      if (isClosed) return;
      emit(const DataExportState());
    } catch (_) {
      if (isClosed) return;
      emit(
        const DataExportState(
          isExporting: false,
          errorMessage: 'export_failed',
        ),
      );
    }
  }

  Future<void> exportCsv() async {
    emit(const DataExportState(isExporting: true));
    try {
      await _exportService.exportCsv();
      if (isClosed) return;
      emit(const DataExportState());
    } catch (_) {
      if (isClosed) return;
      emit(
        const DataExportState(
          isExporting: false,
          errorMessage: 'export_failed',
        ),
      );
    }
  }
}
