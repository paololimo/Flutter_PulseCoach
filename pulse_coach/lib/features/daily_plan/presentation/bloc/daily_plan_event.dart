part of 'daily_plan_bloc.dart';

/// Events are sealed classes (Dart 3) — no @freezed needed for events.
/// Names in past tense per architecture naming convention.
sealed class DailyPlanEvent {}

/// Dispatched on app open / Today screen init — checks cache then generates.
class DailyPlanGenerateRequested extends DailyPlanEvent {}

/// Dispatched when user taps regenerate (FR11) — bypasses cache.
class DailyPlanRegenerateRequested extends DailyPlanEvent {}
