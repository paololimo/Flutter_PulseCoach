import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    String? email,
    required bool isEmailConfirmed,
  }) = _AuthUser;
}
