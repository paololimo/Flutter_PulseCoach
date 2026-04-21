import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String fitnessLevel;        // 'low' | 'medium'
  final String goal;                // 'cardio' | 'strength' | 'mobility' | 'wellbeing'
  final String availableTime;       // 'short' | 'long'
  final String physicalConstraints; // 'none' | 'knee' | 'back' | 'indoor'

  const UserProfile({
    required this.fitnessLevel,
    required this.goal,
    required this.availableTime,
    required this.physicalConstraints,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          fitnessLevel == other.fitnessLevel &&
          goal == other.goal &&
          availableTime == other.availableTime &&
          physicalConstraints == other.physicalConstraints;

  @override
  int get hashCode => Object.hash(fitnessLevel, goal, availableTime, physicalConstraints);
}
