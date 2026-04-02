import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/routing/app_router.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/disclaimer_screen.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/onboarding_carousel.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/profile_setup_form.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final OnboardingCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<OnboardingCubit>();
    // Check if disclaimer was previously accepted — skip screen if so.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _cubit.checkInitialStatus(),
    );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<OnboardingCubit, OnboardingState>(
        buildWhen: (prev, curr) =>
            curr is! OnboardingLoading && curr is! OnboardingError,
        listener: (context, state) {
          if (state is OnboardingOnboardingComplete) {
            context.go(AppRouter.today);
          }
          if (state is OnboardingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is OnboardingProfileSetupReady) {
            return const ProfileSetupForm();
          }
          if (state is OnboardingDisclaimerAccepted) {
            return const OnboardingCarousel();
          }
          return const DisclaimerScreen();
        },
      ),
    );
  }
}
