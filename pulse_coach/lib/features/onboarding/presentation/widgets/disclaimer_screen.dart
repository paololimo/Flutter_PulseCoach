import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/theme/app_spacing.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;

    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                // Privacy narrative headline
                Text(
                  'Your data stays yours.',
                  style: AppTextStyles.display.copyWith(
                    color: theme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Privacy explanation
                Text(
                  'PulseCoach stores your health data exclusively on your device. '
                  'Nothing is ever sent to external servers. '
                  'You are always in full control.',
                  style: AppTextStyles.body.copyWith(
                    color: theme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Medical disclaimer text
                Text(
                  'Medical disclaimer',
                  style: AppTextStyles.h3.copyWith(color: theme.onSurface),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'PulseCoach is a fitness guidance tool, not a medical device. '
                  'It is not a substitute for professional medical advice, '
                  'diagnosis, or treatment. Always consult a qualified healthcare '
                  'professional before starting any exercise programme.',
                  style: AppTextStyles.body.copyWith(
                    color: theme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Checkbox row
                GestureDetector(
                  onTap: () => setState(() => _checked = !_checked),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _checked,
                        onChanged: null,
                        activeColor: theme.primaryColor,
                        checkColor: theme.surface,
                        side: BorderSide(color: theme.onSurfaceVariant),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I understand PulseCoach is not a medical device and '
                            'does not replace professional medical advice.',
                            style: AppTextStyles.body.copyWith(
                              color: theme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Continue button — disabled until checkbox checked
                BlocBuilder<OnboardingCubit, OnboardingState>(
                  builder: (context, state) {
                    final isLoading = state is OnboardingLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: (_checked && !isLoading)
                            ? () =>
                                context.read<OnboardingCubit>().acceptDisclaimer()
                            : null,
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
                                'Continue',
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
