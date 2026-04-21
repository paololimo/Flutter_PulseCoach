// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  fitnessLevel: json['fitnessLevel'] as String,
  goal: json['goal'] as String,
  availableTime: json['availableTime'] as String,
  physicalConstraints: json['physicalConstraints'] as String,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'fitnessLevel': instance.fitnessLevel,
      'goal': instance.goal,
      'availableTime': instance.availableTime,
      'physicalConstraints': instance.physicalConstraints,
    };
