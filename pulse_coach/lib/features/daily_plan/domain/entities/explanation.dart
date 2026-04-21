import 'package:freezed_annotation/freezed_annotation.dart';

part 'explanation.freezed.dart';
part 'explanation.g.dart';

/// One-line AI-generated explanation for a single session recommendation.
///
/// [sessionIndex] = position in DailyPlan.sessions (0-based).
/// [text] = human-readable reason (e.g., "Short sleep + elevated HR. Starting gentle.").
///   Always non-null and non-empty — guaranteed by ExplanationGenerator (Story 5.6).
///
/// Output of ExplanationGenerator; merged into PlannedSession.explanation by
/// DailyPlanGenerationPipeline (Story 5.5).
@freezed
abstract class Explanation with _$Explanation {
  const factory Explanation({
    required int sessionIndex,
    required String text,
  }) = _Explanation;

  factory Explanation.fromJson(Map<String, dynamic> json) =>
      _$ExplanationFromJson(json);
}
