import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:pulse_coach/features/onboarding/presentation/widgets/disclaimer_screen.dart';

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
      child: BlocBuilder<OnboardingCubit, OnboardingState>(
        builder: (context, state) {
          if (state is OnboardingDisclaimerAccepted) {
            return const Scaffold(
              body: Center(
                child: Text('Onboarding continues — Story 2.2/2.3'),
              ),
            );
          }
          return const DisclaimerScreen();
        },
      ),
    );
  }
}
