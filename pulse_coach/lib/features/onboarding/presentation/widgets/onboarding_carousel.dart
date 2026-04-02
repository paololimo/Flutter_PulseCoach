import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:pulse_coach/core/theme/app_spacing.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';

class _PageData {
  const _PageData({
    required this.assetPath,
    required this.headline,
    required this.body,
    required this.fallbackIcon,
  });

  final String assetPath;
  final String headline;
  final String body;
  final IconData fallbackIcon;
}

const _pages = [
  _PageData(
    assetPath: 'assets/animations/onboarding_plan.json',
    headline: 'Move more. Decide less.',
    body:
        'PulseCoach selects your sessions automatically, adapting each day to how your body actually feels.',
    fallbackIcon: Icons.auto_awesome,
  ),
  _PageData(
    assetPath: 'assets/animations/onboarding_privacy.json',
    headline: 'Your data stays yours.',
    body:
        'All your health data lives on your device. Nothing is sent to external servers — ever.',
    fallbackIcon: Icons.lock_outline,
  ),
  _PageData(
    assetPath: 'assets/animations/onboarding_setup.json',
    headline: "Let's set you up in 60 seconds.",
    body:
        'Four quick questions and PulseCoach will have your first personalized plan ready.',
    fallbackIcon: Icons.person_outline,
  ),
];

class OnboardingCarousel extends StatefulWidget {
  const OnboardingCarousel({
    super.key,
    @visibleForTesting this.overrideAssetPath,
  });

  /// When non-null, replaces all Lottie asset paths — used only in tests
  /// to trigger errorBuilder and verify fallback icons (AC6).
  @visibleForTesting
  final String? overrideAssetPath;

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final nextPage = _currentPage + 1;
    if (disableAnimations) {
      _pageController.jumpToPage(nextPage);
    } else {
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildFallbackIcon(int index, Color primaryColor) {
    return Center(
      child: Icon(
        _pages[index].fallbackIcon,
        size: 72,
        color: primaryColor,
      ),
    );
  }

  Widget _buildPage(int index, PulseCoachTheme theme) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final page = _pages[index];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            flex: 5,
            child: Lottie.asset(
              widget.overrideAssetPath ?? page.assetPath,
              fit: BoxFit.contain,
              repeat: !disableAnimations,
              animate: !disableAnimations,
              errorBuilder: (context, error, stackTrace) =>
                  _buildFallbackIcon(index, theme.primaryColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            page.headline,
            style: AppTextStyles.display.copyWith(color: theme.onSurface),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            page.body,
            style: AppTextStyles.body.copyWith(color: theme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildPageDots(theme),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: index < _pages.length - 1
                  ? _goToNextPage
                  : () =>
                      context.read<OnboardingCubit>().completeOnboardingFlow(),
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(
                index < _pages.length - 1 ? 'Next' : 'Get Started',
                style: AppTextStyles.body.copyWith(
                  color: theme.surface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageDots(PulseCoachTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final isActive = i == _currentPage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          width: AppSpacing.sm,
          height: AppSpacing.sm,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? theme.primaryColor
                : theme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.surface,
        body: SafeArea(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _pages.length,
            itemBuilder: (context, index) => _buildPage(index, theme),
          ),
        ),
      ),
    );
  }
}
