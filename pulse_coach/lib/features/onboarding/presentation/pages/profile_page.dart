import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/theme/app_spacing.dart';
import 'package:pulse_coach/core/theme/app_text_styles.dart';
import 'package:pulse_coach/core/theme/pulse_coach_theme.dart';
import 'package:pulse_coach/features/onboarding/domain/entities/user_profile.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_cubit.dart';
import 'package:pulse_coach/features/onboarding/presentation/bloc/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileCubit _cubit;
  String? _fitnessLevel;
  String? _goal;
  String? _availableTime;
  String? _physicalConstraints;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ProfileCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cubit.loadProfile());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _onChanged(UserProfile updated) {
    setState(() {
      _fitnessLevel = updated.fitnessLevel;
      _goal = updated.goal;
      _availableTime = updated.availableTime;
      _physicalConstraints = updated.physicalConstraints;
    });
    _cubit.updateProfile(updated);
  }

  Widget _segmentLabel(String label) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (_, curr) => curr is ProfileLoaded || curr is ProfileError,
        listener: (context, state) {
          if (state is ProfileLoaded && _fitnessLevel == null) {
            setState(() {
              _fitnessLevel = state.profile.fitnessLevel;
              _goal = state.profile.goal;
              _availableTime = state.profile.availableTime;
              _physicalConstraints = state.profile.physicalConstraints;
            });
          }
          if (state is ProfileError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is ProfileError && _fitnessLevel == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Profile')),
              body: Center(child: Text(state.message)),
            );
          }
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Profile',
                style: AppTextStyles.display.copyWith(color: theme.onSurface),
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildField(
                context,
                label: 'Fitness Level',
                segments: [
                  ButtonSegment<String>(
                    value: 'low',
                    label: _segmentLabel('Beginner'),
                  ),
                  ButtonSegment<String>(
                    value: 'medium',
                    label: _segmentLabel('Intermediate'),
                  ),
                ],
                selected: _fitnessLevel,
                onChanged: (val) => _onChanged(
                  UserProfile(
                    fitnessLevel: val,
                    goal: _goal!,
                    availableTime: _availableTime!,
                    physicalConstraints: _physicalConstraints!,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildField(
                context,
                label: 'Primary Goal',
                segments: [
                  ButtonSegment<String>(
                    value: 'cardio',
                    label: _segmentLabel('Cardio'),
                  ),
                  ButtonSegment<String>(
                    value: 'strength',
                    label: _segmentLabel('Strength'),
                  ),
                  ButtonSegment<String>(
                    value: 'mobility',
                    label: _segmentLabel('Mobility'),
                  ),
                  ButtonSegment<String>(
                    value: 'wellbeing',
                    label: _segmentLabel('Well-being'),
                  ),
                ],
                selected: _goal,
                showSelectedIcon: false,
                onChanged: (val) => _onChanged(
                  UserProfile(
                    fitnessLevel: _fitnessLevel!,
                    goal: val,
                    availableTime: _availableTime!,
                    physicalConstraints: _physicalConstraints!,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildField(
                context,
                label: 'Available Time',
                segments: [
                  ButtonSegment<String>(
                    value: 'short',
                    label: _segmentLabel('2–5 min'),
                  ),
                  ButtonSegment<String>(
                    value: 'long',
                    label: _segmentLabel('5–10 min'),
                  ),
                ],
                selected: _availableTime,
                onChanged: (val) => _onChanged(
                  UserProfile(
                    fitnessLevel: _fitnessLevel!,
                    goal: _goal!,
                    availableTime: val,
                    physicalConstraints: _physicalConstraints!,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildField(
                context,
                label: 'Physical Constraints',
                segments: [
                  ButtonSegment<String>(
                    value: 'none',
                    label: _segmentLabel('None'),
                  ),
                  ButtonSegment<String>(
                    value: 'knee',
                    label: _segmentLabel('Knee issues'),
                  ),
                  ButtonSegment<String>(
                    value: 'back',
                    label: _segmentLabel('Back issues'),
                  ),
                  ButtonSegment<String>(
                    value: 'indoor',
                    label: _segmentLabel('Prefer indoor'),
                  ),
                ],
                selected: _physicalConstraints,
                showSelectedIcon: false,
                onChanged: (val) => _onChanged(
                  UserProfile(
                    fitnessLevel: _fitnessLevel!,
                    goal: _goal!,
                    availableTime: _availableTime!,
                    physicalConstraints: val,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    BuildContext context, {
    required String label,
    required List<ButtonSegment<String>> segments,
    required String? selected,
    required void Function(String) onChanged,
    bool showSelectedIcon = true,
  }) {
    final theme = Theme.of(context).extension<PulseCoachTheme>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.h3.copyWith(color: theme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: segments,
          selected: selected != null ? {selected} : const <String>{},
          onSelectionChanged: (Set<String> selection) {
            if (selection.isNotEmpty) onChanged(selection.first);
          },
          showSelectedIcon: showSelectedIcon,
          emptySelectionAllowed: true,
          multiSelectionEnabled: false,
        ),
      ],
    );
  }
}
