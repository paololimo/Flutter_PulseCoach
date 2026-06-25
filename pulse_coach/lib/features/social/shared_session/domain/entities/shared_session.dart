import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_session.freezed.dart';

@freezed
abstract class SharedSession with _$SharedSession {
  const factory SharedSession({
    required String id,
    required String hostUserId,
    required String joinCode,
    required String status,
    required DateTime createdAt,
  }) = _SharedSession;
}
