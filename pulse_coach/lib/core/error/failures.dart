abstract class Failure {
  String get message;
  const Failure();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message);

  @override
  int get hashCode => Object.hash(runtimeType, message);
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

class AuthFailure extends Failure {
  @override
  final String message;
  const AuthFailure(this.message);
}

class BackupFailure extends Failure {
  @override
  final String message;
  const BackupFailure(this.message);
}

class BackupDecryptionFailure extends BackupFailure {
  const BackupDecryptionFailure(super.message);
}

class SubscriptionFailure extends Failure {
  @override
  final String message;
  const SubscriptionFailure(this.message);
}

class SocialFailure extends Failure {
  @override
  final String message;
  const SocialFailure(this.message);
}

class SocialHandleTakenFailure extends SocialFailure {
  const SocialHandleTakenFailure() : super('handle_taken');
}

class RealtimeFailure extends Failure {
  @override
  final String message;
  const RealtimeFailure(this.message);
}

class SessionAlreadyStartedFailure extends Failure {
  @override
  String get message => 'session_already_started';
  const SessionAlreadyStartedFailure();
}
