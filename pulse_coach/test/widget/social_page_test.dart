// [18.2-WIDGET-NEW-001..002] SocialPage Pro gate widget tests.
// [E18R-2] Amici error localization regression test.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
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

Widget _wrapWithSub(_FakeSubscriptionBloc sub, {Widget child = const SocialPage()}) =>
    MaterialApp(
      locale: const Locale('it'),
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SubscriptionBloc>.value(value: sub, child: child),
    );

void main() {
  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    '18.2-WIDGET-NEW-001: non-Pro → locked banner visible, no tab bar',
    (tester) async {
      final sub = _FakeSubscriptionBloc(
        const SubscriptionState.loaded(tier: SubscriptionTier.accountFree),
      );

      await tester.pumpWidget(_wrapWithSub(sub));
      await tester.pump();

      expect(
        find.text('Amici e social sono funzionalità Pro.'),
        findsOneWidget,
      );
      expect(find.text('Scopri Pro'), findsOneWidget);
      expect(find.text('Cerca per @handle'), findsNothing);
    },
  );

  testWidgets(
    '18.2-WIDGET-NEW-002: Pro → friends tab shows search field and QR button',
    (tester) async {
      final fakeFriends = _FakeFriendsBloc(
        const FriendsState.loaded(
          friends: [],
          pendingRequests: PendingRequests(received: [], sent: []),
        ),
      );
      final fakeSocial = _FakeSocialProfileBloc(
        const SocialProfileState.initial(),
      );
      final fakeFeed = _FakeFeedBloc(const FeedState.initial());
      final fakeComparison = _FakeProgressComparisonBloc(
        const ProgressComparisonState.initial(),
      );

      getIt.registerFactory<FriendsBloc>(() => fakeFriends);
      getIt.registerFactory<SocialProfileBloc>(() => fakeSocial);
      getIt.registerFactory<FeedBloc>(() => fakeFeed);
      getIt.registerFactory<ProgressComparisonBloc>(() => fakeComparison);
      getIt.registerFactory<SharedSessionCreationCubit>(
          () => _FakeSharedSessionCreationCubit());
      getIt.registerFactory<SharedSessionJoinCubit>(
          () => _FakeSharedSessionJoinCubit());

      final sub = _FakeSubscriptionBloc(
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      );

      await tester.pumpWidget(_wrapWithSub(sub));
      await tester.pump();

      expect(find.text('Cerca per @handle'), findsOneWidget);
      expect(find.text('Mostra il mio QR'), findsOneWidget);
      expect(
        find.text('Amici e social sono funzionalità Pro.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    '20.1-WIDGET-004: SocialPage friends tab "creating" state — no overflow '
    '360×640 (E18R-1)',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fakeFriends = _FakeFriendsBloc(
        const FriendsState.loaded(
          friends: [],
          pendingRequests: PendingRequests(received: [], sent: []),
        ),
      );
      final fakeSocial = _FakeSocialProfileBloc(
        const SocialProfileState.initial(),
      );
      final fakeFeed = _FakeFeedBloc(const FeedState.initial());
      final fakeComparison = _FakeProgressComparisonBloc(
        const ProgressComparisonState.initial(),
      );

      getIt.registerFactory<FriendsBloc>(() => fakeFriends);
      getIt.registerFactory<SocialProfileBloc>(() => fakeSocial);
      getIt.registerFactory<FeedBloc>(() => fakeFeed);
      getIt.registerFactory<ProgressComparisonBloc>(() => fakeComparison);
      getIt.registerFactory<SharedSessionCreationCubit>(
        () => _FakeSharedSessionCreationCubit(
          const SharedSessionCreationState.creating(),
        ),
      );
      getIt.registerFactory<SharedSessionJoinCubit>(
          () => _FakeSharedSessionJoinCubit());

      final sub = _FakeSubscriptionBloc(
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      );

      await tester.pumpWidget(_wrapWithSub(sub));
      await tester.pump();

      // The creating affordance is an inline spinner inside the
      // "Sessione condivisa" button; the friends list must not overflow.
      expect(find.text('Sessione condivisa'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'E18R-2: Amici error shows localized generic message, never the raw '
    'failure.message',
    (tester) async {
      final controller = StreamController<FriendsState>.broadcast();
      addTearDown(controller.close);

      final fakeFriends = _FakeFriendsBloc(
        const FriendsState.loading(),
        stream: controller.stream,
      );
      final fakeSocial = _FakeSocialProfileBloc(
        const SocialProfileState.initial(),
      );
      final fakeFeed = _FakeFeedBloc(const FeedState.initial());
      final fakeComparison = _FakeProgressComparisonBloc(
        const ProgressComparisonState.initial(),
      );

      getIt.registerFactory<FriendsBloc>(() => fakeFriends);
      getIt.registerFactory<SocialProfileBloc>(() => fakeSocial);
      getIt.registerFactory<FeedBloc>(() => fakeFeed);
      getIt.registerFactory<ProgressComparisonBloc>(() => fakeComparison);
      getIt.registerFactory<SharedSessionCreationCubit>(
          () => _FakeSharedSessionCreationCubit());
      getIt.registerFactory<SharedSessionJoinCubit>(
          () => _FakeSharedSessionJoinCubit());

      final sub = _FakeSubscriptionBloc(
        const SubscriptionState.loaded(tier: SubscriptionTier.pro),
      );

      await tester.pumpWidget(_wrapWithSub(sub));
      await tester.pump();

      const rawMessage = 'Failed to fetch friends: Bad state: '
          'No authenticated session';
      controller.add(
        const FriendsState.error(failure: ServerFailure(rawMessage)),
      );
      await tester.pump(); // process stream emission + show SnackBar

      expect(find.text('Qualcosa è andato storto. Riprova.'), findsOneWidget);
      expect(find.text(rawMessage), findsNothing);
    },
  );
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
  final Stream<FriendsState> _stream;
  _FakeFriendsBloc(this._state, {Stream<FriendsState>? stream})
      : _stream = stream ?? const Stream.empty();

  @override
  FriendsState get state => _state;

  @override
  Stream<FriendsState> get stream => _stream;

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
  final SharedSessionCreationState _state;
  _FakeSharedSessionCreationCubit([
    this._state = const SharedSessionCreationState.initial(),
  ]);

  @override
  SharedSessionCreationState get state => _state;

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
  @override
  SharedSessionJoinState get state => const SharedSessionJoinState.initial();

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
