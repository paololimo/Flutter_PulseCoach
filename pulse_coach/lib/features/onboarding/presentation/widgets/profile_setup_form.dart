import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/theme/app_spacing.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

class ProfileSetupForm extends StatefulWidget {
  const ProfileSetupForm({super.key});

  @override
  State<ProfileSetupForm> createState() => _ProfileSetupFormState();
}

class _ProfileSetupFormState extends State<ProfileSetupForm> {
  String? _fitnessLevel;
  String? _goal;
  String? _availableTime;
  String? _physicalConstraints;

  bool get _allSelected =>
      _fitnessLevel != null &&
      _goal != null &&
      _availableTime != null &&
      _physicalConstraints != null;

  void _onSubmit() {
    context.read<OnboardingCubit>().saveProfile(
      UserProfile(
        fitnessLevel: _fitnessLevel!,
        goal: _goal!,
        availableTime: _availableTime!,
        physicalConstraints: _physicalConstraints!,
      ),
    );
  }

  Widget _buildField(String label, SegmentedButton<String> button) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.h3.copyWith(color: theme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        button,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileSetupHeading,
                    style: AppTextStyles.display.copyWith(
                      color: theme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _buildField(
                    l10n.profileFitnessLevel,
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'low',
                          label: Text(l10n.profileFitnessBeginner),
                        ),
                        ButtonSegment<String>(
                          value: 'medium',
                          label: Text(l10n.profileFitnessIntermediate),
                        ),
                      ],
                      selected: _fitnessLevel != null
                          ? {_fitnessLevel!}
                          : const <String>{},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() => _fitnessLevel =
                            selection.isNotEmpty ? selection.first : null);
                      },
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(
                    l10n.profilePrimaryGoal,
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'cardio',
                          label: Text(l10n.profileGoalCardio),
                        ),
                        ButtonSegment<String>(
                          value: 'strength',
                          label: Text(l10n.profileGoalStrength),
                        ),
                        ButtonSegment<String>(
                          value: 'mobility',
                          label: Text(l10n.profileGoalMobility),
                        ),
                        ButtonSegment<String>(
                          value: 'wellbeing',
                          label: Text(l10n.profileGoalWellbeing),
                        ),
                      ],
                      selected: _goal != null ? {_goal!} : const <String>{},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() =>
                            _goal = selection.isNotEmpty ? selection.first : null);
                      },
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(
                    l10n.profileAvailableTime,
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'short',
                          label: Text('2–5 min'),
                        ),
                        ButtonSegment<String>(
                          value: 'long',
                          label: Text('5–10 min'),
                        ),
                      ],
                      selected: _availableTime != null
                          ? {_availableTime!}
                          : const <String>{},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() => _availableTime =
                            selection.isNotEmpty ? selection.first : null);
                      },
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(
                    l10n.profilePhysicalConstraints,
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment<String>(
                          value: 'none',
                          label: Text(l10n.profileConstraintNone),
                        ),
                        ButtonSegment<String>(
                          value: 'knee',
                          label: Text(l10n.profileConstraintKnee),
                        ),
                        ButtonSegment<String>(
                          value: 'back',
                          label: Text(l10n.profileConstraintBack),
                        ),
                        ButtonSegment<String>(
                          value: 'indoor',
                          label: Text(l10n.profileConstraintIndoor),
                        ),
                      ],
                      selected: _physicalConstraints != null
                          ? {_physicalConstraints!}
                          : const <String>{},
                      onSelectionChanged: (Set<String> selection) {
                        setState(() => _physicalConstraints =
                            selection.isNotEmpty ? selection.first : null);
                      },
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  BlocBuilder<OnboardingCubit, OnboardingState>(
                    builder: (context, state) {
                      final isLoading = state is OnboardingLoading;
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              (_allSelected && !isLoading) ? _onSubmit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            disabledBackgroundColor:
                                theme.primaryColor.withValues(alpha: 0.3),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.surface,
                                  ),
                                )
                              : Text(
                                  l10n.profileStartPlan,
                                  style: AppTextStyles.body.copyWith(
                                    color: theme.surface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
