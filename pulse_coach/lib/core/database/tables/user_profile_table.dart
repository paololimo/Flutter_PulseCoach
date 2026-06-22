import 'package:drift/drift.dart';

@DataClassName('UserProfileData')
class UserProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fitnessGoal => text().nullable()();
  IntColumn get weeklySessionTarget =>
      integer().withDefault(const Constant(3))();
  TextColumn get intensityPreference =>
      text().nullable()(); // 'low' | 'medium' | 'high'
  TextColumn get environmentPreference =>
      text().nullable()(); // 'indoor' | 'outdoor' | 'any'
  TextColumn get availableTime => text().nullable()();
  TextColumn get physicalConstraints => text().nullable()();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get disclaimerAccepted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get installCohort => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
