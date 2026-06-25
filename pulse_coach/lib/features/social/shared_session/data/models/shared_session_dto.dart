import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session.dart';

part 'shared_session_dto.freezed.dart';
part 'shared_session_dto.g.dart';

@freezed
abstract class SharedSessionDto with _$SharedSessionDto {
  const factory SharedSessionDto({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'host_user_id') required String hostUserId,
    @JsonKey(name: 'join_code') required String joinCode,
    @JsonKey(name: 'status') required String status,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _SharedSessionDto;

  factory SharedSessionDto.fromJson(Map<String, dynamic> json) =>
      _$SharedSessionDtoFromJson(json);
}

extension SharedSessionDtoMapper on SharedSessionDto {
  SharedSession toDomain() => SharedSession(
        id: id,
        hostUserId: hostUserId,
        joinCode: joinCode,
        status: status,
        createdAt: DateTime.parse(createdAt),
      );
}
