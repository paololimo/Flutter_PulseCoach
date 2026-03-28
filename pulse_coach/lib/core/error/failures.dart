abstract class Failure {
  String get message;
  const Failure();
}

class ServerFailure extends Failure {
  @override
  final String message;
  const ServerFailure(this.message);
}

class CacheFailure extends Failure {
  @override
  final String message;
  const CacheFailure(this.message);
}

class SensorFailure extends Failure {
  @override
  final String message;
  const SensorFailure(this.message);
}

class LocationFailure extends Failure {
  @override
  final String message;
  const LocationFailure(this.message);
}
