import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_coach/core/database/app_database.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/export_data_cubit.dart';
import 'package:pulse_coach/features/auth/presentation/pages/account_page.dart';
import 'package:pulse_coach/features/auth/presentation/pages/backup_page.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/features/subscription/presentation/pages/paywall_page.dart';
import 'package:pulse_coach/features/daily_plan/domain/entities/planned_session.dart';
import 'package:pulse_coach/features/daily_plan/presentation/bloc/daily_plan_bloc.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:pulse_coach/features/onboarding/presentation/pages/profile_page.dart';
import 'package:pulse_coach/features/progress/presentation/pages/progress_page.dart';
import 'package:pulse_coach/features/session/domain/entities/mini_summary_args.dart';
import 'package:pulse_coach/features/session/domain/entities/rpe_submit_args.dart';
import 'package:pulse_coach/features/session/domain/entities/session_start_args.dart';
import 'package:pulse_coach/features/session/presentation/pages/in_session_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/rpe_page.dart';
import 'package:pulse_coach/features/session/presentation/pages/session_summary_page.dart';
import 'package:pulse_coach/features/sessions_catalog/presentation/pages/sessions_page.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/ai_decision_log_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/bloc/device_settings_cubit.dart';
import 'package:pulse_coach/features/settings/presentation/pages/ai_decision_log_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/device_settings_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/privacy_page.dart';
import 'package:pulse_coach/features/settings/presentation/pages/settings_page.dart';
import 'package:pulse_coach/features/today/presentation/cubit/today_session_cubit.dart';
import 'package:pulse_coach/features/social/friends/presentation/pages/social_page.dart';
import 'package:pulse_coach/features/social/friends/presentation/pages/qr_code_screen.dart';
import 'package:pulse_coach/features/social/shared_session/domain/entities/shared_session_start_args.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_bloc.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_event.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/pages/shared_session_lobby_page.dart';
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
  static const String deviceSettings = '/device-settings';
  static const String aiDecisionLog = '/ai-decision-log';
  static const String account = '/account';
  static const String backup = '/account/backup';
  static const String paywall = '/paywall';
  static const String social = '/social';
  static const String socialQr = '/social/qr';
  static const String sharedSessionLobby = '/social/shared-session/lobby';

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
          GoRoute(
            path: social,
            builder: (context, state) => const SocialPage(),
          ),
        ],
      ),
      GoRoute(
        path: socialQr,
        builder: (context, state) => const QrCodeScreen(),
      ),
      GoRoute(
        path: sharedSessionLobby,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SharedSessionStartArgs) {
            return const SizedBox.shrink();
          }
          return BlocProvider(
            create: (_) => getIt<SharedSessionBloc>()
              ..add(SharedSessionJoined(
                sessionId: extra.sessionId,
                isHost: extra.isHost,
                userId: extra.userId,
                displayHandle: extra.displayHandle,
                steps: extra.steps,
                joinCode: extra.joinCode,
              )),
            child: const SharedSessionLobbyPage(),
          );
        },
      ),
      GoRoute(
        path: sessionActive,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is SessionStartArgs) {
            return InSessionPage(
              session: extra.session,
              planId: extra.planId,
              sessionIndex: extra.sessionIndex,
            );
          }
          return InSessionPage(session: extra as PlannedSession?);
        },
      ),
      GoRoute(
        path: sessionRpe,
        builder: (context, state) {
          final extra = state.extra;
          return RpePage(args: extra is RpeSubmitArgs ? extra : null);
        },
      ),
      GoRoute(
        path: sessionSummary,
        builder: (context, state) {
          final extra = state.extra;
          return MiniSummaryPage(args: extra is MiniSummaryArgs ? extra : null);
        },
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: deviceSettings,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DeviceSettingsCubit>()..load(),
          child: const DeviceSettingsPage(),
        ),
      ),
      GoRoute(
        path: aiDecisionLog,
        builder: (context, state) {
          if (!kDebugMode) return const SettingsPage();
          return BlocProvider(
            create: (_) => getIt<AiDecisionLogCubit>()..load(),
            child: const AiDecisionLogPage(),
          );
        },
      ),
      GoRoute(path: profile, builder: (context, state) => const ProfilePage()),
      GoRoute(path: privacy, builder: (context, state) => const PrivacyPage()),
      GoRoute(
        path: paywall,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<SubscriptionBloc>()),
          ],
          child: const PaywallPage(),
        ),
      ),
      GoRoute(
        path: account,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<AuthBloc>()),
            BlocProvider(create: (_) => getIt<ExportDataCubit>()),
          ],
          child: const AccountPage(),
        ),
        routes: [
          GoRoute(
            path: 'backup',
            builder: (context, state) => const BackupPage(),
          ),
        ],
      ),
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
