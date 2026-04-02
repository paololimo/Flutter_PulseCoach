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
}
