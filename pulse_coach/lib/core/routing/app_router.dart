import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/profile_page.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/today/presentation/pages/today_page.dart';
import 'package:pulse_coach/shared/widgets/app_shell.dart';

class AppRouter {
  // Route path constants — kebab-case paths, camelCase names
  static const String onboarding = '/onboarding';
  static const String today = '/today';
  static const String sessions = '/sessions';
  static const String progress = '/progress';
  static const String sessionActive = '/session/active';
  static const String sessionRpe = '/session/rpe';
  static const String sessionSummary = '/session/summary';
  static const String settings = '/settings';
  static const String profile = '/profile';
  static const String privacy = '/privacy';

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: _redirect,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => null),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: today,
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (_) =>
                      getIt<DailyPlanBloc>()..add(DailyPlanGenerateRequested()),
                ),
                BlocProvider(create: (_) => getIt<TodaySessionCubit>()),
              ],
              child: const TodayPage(),
            ),
          ),
          GoRoute(
            path: sessions,
            builder: (context, state) => const SessionsPage(),
          ),
          GoRoute(
            path: progress,
            builder: (context, state) => const ProgressPage(),
          ),
        ],
      ),
      GoRoute(
        path: sessionActive,
        builder: (context, state) {
          final session = state.extra as PlannedSession?;
          return InSessionPage(session: session);
        },
      ),
      GoRoute(path: sessionRpe, builder: (context, state) => const RpePage()),
      GoRoute(
        path: sessionSummary,
        builder: (context, state) => const SessionSummaryPage(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(path: profile, builder: (context, state) => const ProfilePage()),
      GoRoute(path: privacy, builder: (context, state) => const PrivacyPage()),
    ],
  );

  static Future<String?> _redirect(
    BuildContext context,
    GoRouterState state,
  ) async {
    final userProfile = await getIt<AppDatabase>().userProfileDao.getProfile();
    final disclaimerAccepted = userProfile?.disclaimerAccepted ?? false;
    final onboardingComplete = userProfile?.onboardingCompleted ?? false;
    final location = state.matchedLocation;
    final goingToOnboarding = location == onboarding;
    final atRoot = location == '/';

    if (!disclaimerAccepted && !goingToOnboarding) return onboarding;
    if (disclaimerAccepted && !onboardingComplete && !goingToOnboarding) {
      return onboarding;
    }
    if (onboardingComplete && (goingToOnboarding || atRoot)) return today;
    return null; // no redirect
  }
}
