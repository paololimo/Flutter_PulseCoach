import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';

/// Maps raw Supabase User fields to the domain [AuthUser] entity.
/// Fields are extracted in the datasource via type inference so this
/// file does not need to import supabase_flutter directly (ARCH25).
class AuthUserDto {
  static AuthUser fromFields({
    required String id,
    String? email,
    required bool isEmailConfirmed,
  }) =>
      AuthUser(id: id, email: email, isEmailConfirmed: isEmailConfirmed);
}
