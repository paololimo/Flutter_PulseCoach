class HealthData {
  final int? restingHr;
  final int? stepCount;

  const HealthData({this.restingHr, this.stepCount});

  bool get hasData => restingHr != null || stepCount != null;
}
