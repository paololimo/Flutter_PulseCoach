// [20.3-WIDGET-001..002] Join button small-viewport (E18R-1) tests
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/auth/domain/entities/auth_user.dart';
import 'package:pulse_coach/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_bloc.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_event.dart';
import 'package:pulse_coach/features/social/comparison/presentation/bloc/progress_comparison_state.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_bloc.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_event.dart';
import 'package:pulse_coach/features/social/feed/presentation/bloc/feed_state.dart';
import 'package:pulse_coach/features/social/friends/domain/entities/pending_requests.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/friends_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_bloc.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_event.dart';
import 'package:pulse_coach/features/social/friends/presentation/bloc/social_profile_state.dart';
import 'package:pulse_coach/features/social/friends/presentation/pages/social_page.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_creation_cubit.dart';
import 'package:pulse_coach/features/social/shared_session/presentation/bloc/shared_session_join_cubit.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';

Widget _buildSocialPage(_FakeSubscriptionBloc sub) => MaterialApp(
      locale: const Locale('it'),
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // SocialPage now gates its Pro content behind an authenticated AuthBloc.
      home: BlocProvider<AuthBloc>.value(
        value: _FakeAuthBloc(
          const AuthState.authenticated(
            user: AuthUser(
              id: 'test-uid',
              email: 'test@example.com',
              isEmailConfirmed: true,
            ),
          ),
        ),
        child: BlocProvider<SubscriptionBloc>.value(
          value: sub,
          child: const SocialPage(),
        ),
      ),
    );

void _registerFakeBlocs({
  SharedSessionJoinState joinState = const SharedSessionJoinState.initial(),
}) {
  getIt.registerFactory<FriendsBloc>(() => _FakeFriendsBloc(
        const FriendsState.loaded(
          friends: [],
          pendingRequests: PendingRequests(received: [], sent: []),
        ),
      ));
  getIt.registerFactory<SocialProfileBloc>(
      () => _FakeSocialProfileBloc(const SocialProfileState.initial()));
  getIt.registerFactory<FeedBloc>(
      () => _FakeFeedBloc(const FeedState.initial()));
  getIt.registerFactory<ProgressComparisonBloc>(
      () => _FakeProgressComparisonBloc(const ProgressComparisonState.initial()));
  getIt.registerFactory<SharedSessionCreationCubit>(
      () => _FakeSharedSessionCreationCubit());
  getIt.registerFactory<SharedSessionJoinCubit>(
      () => _FakeSharedSessionJoinCubit(joinState));
}

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    '20.3-WIDGET-001: 360×640 — joining state → join button shows CircularProgressIndicator, no overflow (E18R-1)',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      _registerFakeBlocs(joinState: const SharedSessionJoinState.joining());
      final sub = _FakeSubscriptionBloc(
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      );

      await tester.pumpWidget(_buildSocialPage(sub));
      await tester.pump();

      // Join button exists and shows spinner
      expect(find.text('Unisciti a una sessione'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      // No overflow exception
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    '20.3-WIDGET-002: 360×640 — initial state → join button shows label, no overflow (E18R-1)',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      _registerFakeBlocs();
      final sub = _FakeSubscriptionBloc(
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      );

      await tester.pumpWidget(_buildSocialPage(sub));
      await tester.pump();

      expect(find.text('Unisciti a una sessione'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

// ── Fake blocs ────────────────────────────────────────────────────────────────

class _FakeAuthBloc extends Fake implements AuthBloc {
  final AuthState _state;
  _FakeAuthBloc(this._state);

  @override
  AuthState get state => _state;
  @override
  Stream<AuthState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(AuthEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeSubscriptionBloc extends Fake implements SubscriptionBloc {
  final SubscriptionState _state;
  _FakeSubscriptionBloc(this._state);

  @override
  SubscriptionState get state => _state;
  @override
  Stream<SubscriptionState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(SubscriptionEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeFriendsBloc extends Fake implements FriendsBloc {
  final FriendsState _state;
  _FakeFriendsBloc(this._state);

  @override
  FriendsState get state => _state;
  @override
  Stream<FriendsState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(FriendsEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeSocialProfileBloc extends Fake implements SocialProfileBloc {
  final SocialProfileState _state;
  _FakeSocialProfileBloc(this._state);

  @override
  SocialProfileState get state => _state;
  @override
  Stream<SocialProfileState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(SocialProfileEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeFeedBloc extends Fake implements FeedBloc {
  final FeedState _state;
  _FakeFeedBloc(this._state);

  @override
  FeedState get state => _state;
  @override
  Stream<FeedState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(FeedEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeProgressComparisonBloc extends Fake
    implements ProgressComparisonBloc {
  final ProgressComparisonState _state;
  _FakeProgressComparisonBloc(this._state);

  @override
  ProgressComparisonState get state => _state;
  @override
  Stream<ProgressComparisonState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  void add(ProgressComparisonEvent event) {}
  @override
  Future<void> close() async {}
}

class _FakeSharedSessionCreationCubit extends Fake
    implements SharedSessionCreationCubit {
  _FakeSharedSessionCreationCubit();

  @override
  SharedSessionCreationState get state =>
      const SharedSessionCreationState.initial();
  @override
  Stream<SharedSessionCreationState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  Future<void> create({required String hostUserId}) async {}
  @override
  Future<void> close() async {}
}

class _FakeSharedSessionJoinCubit extends Fake
    implements SharedSessionJoinCubit {
  final SharedSessionJoinState _state;
  _FakeSharedSessionJoinCubit(this._state);

  @override
  SharedSessionJoinState get state => _state;
  @override
  Stream<SharedSessionJoinState> get stream => const Stream.empty();
  @override
  bool get isClosed => false;
  @override
  Future<void> join({required String joinCode, required String userId}) async {}
  @override
  void reset() {}
  @override
  Future<void> close() async {}
}
