import 'dart:convert';

import 'package:pulse_coach/features/sessions_catalog/domain/entities/exercise.dart';

class ExerciseModel {
  const ExerciseModel({
    required this.id,
    required this.name,
    required this.description,
    required this.sessionType,
    required this.steps,
    required this.durationMinutes,
    required this.difficulty,
    required this.indoorCompatible,
    required this.outdoorCompatible,
  });

  final String id;
  final String name;
  final String description;
  final String sessionType;
  final List<String> steps;
  final int durationMinutes;
  final String difficulty;
  final bool indoorCompatible;
  final bool outdoorCompatible;

  Exercise toEntity() => Exercise(
    id: id,
    name: name,
    description: description,
    sessionType: sessionType,
    steps: List<String>.unmodifiable(steps),
    durationMinutes: durationMinutes,
    difficulty: difficulty,
    indoorCompatible: indoorCompatible,
    outdoorCompatible: outdoorCompatible,
  );

  Map<String, dynamic> toJson() => toEntity().toJson();

  factory ExerciseModel.fromPulseCoachJson(Map<String, dynamic> json) {
    final exercise = Exercise.fromJson(json);
    return ExerciseModel.fromEntity(exercise);
  }

  factory ExerciseModel.fromEntity(Exercise exercise) => ExerciseModel(
    id: exercise.id,
    name: exercise.name,
    description: exercise.description,
    sessionType: exercise.sessionType,
    steps: exercise.steps,
    durationMinutes: exercise.durationMinutes,
    difficulty: exercise.difficulty,
    indoorCompatible: exercise.indoorCompatible,
    outdoorCompatible: exercise.outdoorCompatible,
  );

  static ExerciseModel? fromExerciseDbJson(Map<String, dynamic> json) {
    final id = json['exerciseId'];
    final name = json['name'];
    final instructions = json['instructions'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }

    final steps = instructions is List
        ? instructions
              .whereType<String>()
              .map((step) => step.trim())
              .where((step) => step.isNotEmpty)
              .toList()
        : <String>[];
    if (steps.isEmpty) {
      return null;
    }

    final bodyParts = _readStringList(json['bodyParts']);
    final targetMuscles = _readStringList(json['targetMuscles']);
    final equipments = _readStringList(json['equipments']);

    final sessionType = _deriveSessionType(
      name: name,
      bodyParts: bodyParts,
      targetMuscles: targetMuscles,
      equipments: equipments,
      steps: steps,
    );
    if (sessionType == null) {
      return null;
    }

    final description = _buildDescription(
      name: name,
      bodyParts: bodyParts,
      targetMuscles: targetMuscles,
    );
    final difficulty = _deriveDifficulty(
      name: name,
      equipments: equipments,
      steps: steps,
      sessionType: sessionType,
    );
    final (indoorCompatible, outdoorCompatible) = _deriveCompatibility(
      name: name,
      equipments: equipments,
    );

    return ExerciseModel(
      id: id,
      name: name,
      description: description,
      sessionType: sessionType,
      steps: steps,
      durationMinutes: _deriveDurationMinutes(
        sessionType: sessionType,
        difficulty: difficulty,
      ),
      difficulty: difficulty,
      indoorCompatible: indoorCompatible,
      outdoorCompatible: outdoorCompatible,
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _deriveSessionType({
    required String name,
    required List<String> bodyParts,
    required List<String> targetMuscles,
    required List<String> equipments,
    required List<String> steps,
  }) {
    final haystack = [
      name,
      ...bodyParts,
      ...targetMuscles,
      ...equipments,
      ...steps,
    ].join(' ').toLowerCase();

    const cardioKeywords = {
      'cardio',
      'jump',
      'run',
      'jog',
      'burpee',
      'high knees',
      'mountain climber',
      'skater',
      'rope',
      'aerobic',
      'step up',
      'march',
      'cycling',
      'bike',
    };
    if (cardioKeywords.any(haystack.contains)) {
      return 'cardio';
    }

    const mobilityKeywords = {
      'stretch',
      'mobility',
      'yoga',
      'rotation',
      'twist',
      'cat cow',
      'bridge',
      'flexion',
      'extension',
      'lunge stretch',
      'hip',
      'spine',
      'neck',
      'shoulder',
      'waist',
      'back',
    };
    if (mobilityKeywords.any(haystack.contains)) {
      return 'mobility';
    }

    final noEquipment =
        equipments.isEmpty ||
        equipments.every(
          (equipment) =>
              equipment.toLowerCase() == 'body weight' ||
              equipment.toLowerCase() == 'bodyweight' ||
              equipment.toLowerCase() == 'none',
        );
    if (noEquipment &&
        (bodyParts.contains('waist') || bodyParts.contains('back'))) {
      return 'mobility';
    }

    return null;
  }

  static String _buildDescription({
    required String name,
    required List<String> bodyParts,
    required List<String> targetMuscles,
  }) {
    final focus = <String>[...bodyParts.take(1), ...targetMuscles.take(2)];
    if (focus.isEmpty) {
      return 'Structured exercise for PulseCoach micro-sessions.';
    }
    return '$name targeting ${focus.join(', ')}.';
  }

  static String _deriveDifficulty({
    required String name,
    required List<String> equipments,
    required List<String> steps,
    required String sessionType,
  }) {
    final haystack = '$name ${equipments.join(' ')} ${steps.join(' ')}'
        .toLowerCase();
    const highKeywords = {
      'barbell',
      'kettlebell',
      'burpee',
      'sprint',
      'jump squat',
      'pull up',
    };
    if (highKeywords.any(haystack.contains) || steps.length >= 7) {
      return 'high';
    }

    const mediumKeywords = {
      'dumbbell',
      'band',
      'lunge',
      'push up',
      'mountain climber',
      'bike',
    };
    if (mediumKeywords.any(haystack.contains) || sessionType == 'cardio') {
      return 'medium';
    }

    return 'low';
  }

  static (bool indoorCompatible, bool outdoorCompatible) _deriveCompatibility({
    required String name,
    required List<String> equipments,
  }) {
    final haystack = '$name ${equipments.join(' ')}'.toLowerCase();
    const outdoorRequiredKeywords = {
      'run',
      'jog',
      'sprint',
      'hike',
      'trail',
      'cycling',
      'outdoor',
    };
    if (outdoorRequiredKeywords.any(haystack.contains)) {
      return (false, true);
    }

    const indoorOnlyKeywords = {'treadmill', 'stationary bike', 'elliptical'};
    if (indoorOnlyKeywords.any(haystack.contains)) {
      return (true, false);
    }

    return (true, true);
  }

  static int _deriveDurationMinutes({
    required String sessionType,
    required String difficulty,
  }) {
    final base = switch (sessionType) {
      'cardio' => 7,
      'mobility' => 5,
      'breathing' => 4,
      _ => 5,
    };
    final offset = switch (difficulty) {
      'high' => 1,
      'medium' => 0,
      'low' => -1,
      _ => 0,
    };
    return (base + offset).clamp(2, 10);
  }

  @override
  String toString() => jsonEncode(toJson());
}
