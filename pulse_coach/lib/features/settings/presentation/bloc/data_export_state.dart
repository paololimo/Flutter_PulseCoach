import 'package:equatable/equatable.dart';

class DataExportState extends Equatable {
  const DataExportState({this.isExporting = false, this.errorMessage});

  final bool isExporting;
  final String? errorMessage;

  @override
  List<Object?> get props => [isExporting, errorMessage];
}
