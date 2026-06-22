// [17.4-WIDGET-001..006] PaywallPage widget tests
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pulse_coach/core/di/injection.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/core/theme/app_theme.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/paywall_cubit.dart';
import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
import 'package:pulse_coach/features/subscription/presentation/pages/paywall_page.dart';
import 'package:pulse_coach/l10n/app_localizations.dart';
import 'package:pulse_coach/shared/widgets/shimmer_placeholder.dart';

import 'paywall_page_test.mocks.dart';

@GenerateMocks([PaywallCubit, SubscriptionBloc])
void main() {
  const testOffers = [
    ProOffer(
      packageId: r'$rc_monthly',
      priceString: '€ 4,99',
      period: 'mensile',
    ),
    ProOffer(
      packageId: r'$rc_annual',
      priceString: '€ 39,99',
      period: 'annuale',
    ),
  ];

  late MockPaywallCubit mockPaywallCubit;
  late MockSubscriptionBloc mockSubscriptionBloc;

  setUp(() {
    provideDummy<SubscriptionState>(const SubscriptionState.initial());
    provideDummy<PaywallState>(const PaywallState.loading());

    mockPaywallCubit = MockPaywallCubit();
    mockSubscriptionBloc = MockSubscriptionBloc();

    when(mockPaywallCubit.stream).thenAnswer((_) => const Stream.empty());
    when(mockSubscriptionBloc.stream)
        .thenAnswer((_) => const Stream.empty());
    when(mockSubscriptionBloc.state)
        .thenReturn(const SubscriptionState.loaded(tier: SubscriptionTier.accountFree));

    getIt.registerFactory<PaywallCubit>(() => mockPaywallCubit);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpPaywallPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<SubscriptionBloc>.value(value: mockSubscriptionBloc),
          ],
          child: const PaywallPage(),
        ),
      ),
    );
  }

  group('PaywallPage —', () {
    testWidgets(
      '17.4-WIDGET-001: shows shimmer skeleton when PaywallCubit is loading',
      (tester) async {
        when(mockPaywallCubit.state).thenReturn(const PaywallState.loading());
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        await pumpPaywallPage(tester);
        await tester.pump();

        // Shimmer renders ListView with ShimmerPlaceholder skeletons
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(ShimmerPlaceholder), findsWidgets);
        // No plan card text in shimmer
        expect(find.text('Acquista'), findsNothing);
      },
    );

    testWidgets(
      '17.4-WIDGET-002: shows plan cards with price and period when loaded',
      (tester) async {
        when(mockPaywallCubit.state)
            .thenReturn(const PaywallState.loaded(offers: testOffers));
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        await pumpPaywallPage(tester);
        await tester.pump();

        expect(find.text('Pro mensile'), findsOneWidget);
        expect(find.text('€ 4,99'), findsOneWidget);
        expect(find.text('Pro annuale'), findsOneWidget);
        expect(find.text('€ 39,99'), findsOneWidget);
        expect(find.text('Acquista'), findsNWidgets(2));
        expect(find.text('Ripristina acquisti'), findsOneWidget);
      },
    );

    testWidgets(
      '17.4-WIDGET-003: tapping Acquista dispatches purchaseRequested to SubscriptionBloc',
      (tester) async {
        when(mockPaywallCubit.state)
            .thenReturn(const PaywallState.loaded(offers: testOffers));
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        await pumpPaywallPage(tester);
        await tester.pump();

        await tester.tap(find.text('Acquista').first);
        await tester.pump();

        verify(
          mockSubscriptionBloc.add(
            const SubscriptionEvent.purchaseRequested(
              packageId: r'$rc_monthly',
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '17.4-WIDGET-004: tapping Ripristina acquisti dispatches restoreRequested to SubscriptionBloc',
      (tester) async {
        when(mockPaywallCubit.state)
            .thenReturn(const PaywallState.loaded(offers: testOffers));
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        await pumpPaywallPage(tester);
        await tester.pump();

        await tester.tap(find.text('Ripristina acquisti'));
        await tester.pump();

        verify(
          mockSubscriptionBloc.add(const SubscriptionEvent.restoreRequested()),
        ).called(1);
      },
    );

    testWidgets(
      '17.4-WIDGET-005: BlocListener pops page when SubscriptionBloc emits loaded after loading',
      (tester) async {
        when(mockPaywallCubit.state)
            .thenReturn(const PaywallState.loaded(offers: testOffers));
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        // Simulate: loading → loaded transition
        final stateController = StreamController<SubscriptionState>.broadcast();
        when(mockSubscriptionBloc.stream)
            .thenAnswer((_) => stateController.stream);
        when(mockSubscriptionBloc.state)
            .thenReturn(const SubscriptionState.loading());

        bool popped = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<SubscriptionBloc>.value(
                  value: mockSubscriptionBloc,
                ),
              ],
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: TextButton(
                      onPressed: () {},
                      child: const Text('back'),
                    ),
                  ),
                ),
                // ignore: deprecated_member_use
                onPopPage: (route, result) {
                  popped = true;
                  return route.didPop(result);
                },
                pages: const [
                  MaterialPage(child: SizedBox()),
                  MaterialPage(child: PaywallPage()),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // Emit loading then loaded — triggers listenWhen (previous is _Loading, current is _Loaded)
        stateController.add(const SubscriptionState.loading());
        await tester.pump();
        stateController
            .add(const SubscriptionState.loaded(tier: SubscriptionTier.pro));
        await tester.pumpAndSettle();

        expect(popped, isTrue);
        await stateController.close();
      },
    );

    testWidgets(
      '17.4-WIDGET-006: BlocListener shows SnackBar when SubscriptionBloc emits error',
      (tester) async {
        when(mockPaywallCubit.state)
            .thenReturn(const PaywallState.loaded(offers: testOffers));
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        final stateController = StreamController<SubscriptionState>.broadcast();
        when(mockSubscriptionBloc.stream)
            .thenAnswer((_) => stateController.stream);
        when(mockSubscriptionBloc.state)
            .thenReturn(const SubscriptionState.loaded(tier: SubscriptionTier.accountFree));

        await pumpPaywallPage(tester);
        await tester.pump();

        stateController.add(
          const SubscriptionState.error(
            failure: SubscriptionFailure('Acquisto non riuscito'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Acquisto non riuscito'), findsOneWidget);
        await stateController.close();
      },
    );

    testWidgets(
      '17.4-WIDGET-007: loaded(non-pro) after loading shows a SnackBar and does NOT pop',
      (tester) async {
        when(mockPaywallCubit.state)
            .thenReturn(const PaywallState.loaded(offers: testOffers));
        when(mockPaywallCubit.loadOfferings()).thenAnswer((_) async {});

        final stateController = StreamController<SubscriptionState>.broadcast();
        when(mockSubscriptionBloc.stream)
            .thenAnswer((_) => stateController.stream);
        when(mockSubscriptionBloc.state)
            .thenReturn(const SubscriptionState.loading());

        bool popped = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<SubscriptionBloc>.value(
                  value: mockSubscriptionBloc,
                ),
              ],
              child: Navigator(
                // ignore: deprecated_member_use
                onPopPage: (route, result) {
                  popped = true;
                  return route.didPop(result);
                },
                pages: const [
                  MaterialPage(child: SizedBox()),
                  MaterialPage(child: PaywallPage()),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        // Restore/purchase resolved to a non-pro tier: feedback, no dismissal.
        stateController.add(const SubscriptionState.loading());
        await tester.pump();
        stateController.add(
          const SubscriptionState.loaded(tier: SubscriptionTier.signedInFree),
        );
        await tester.pumpAndSettle();

        expect(popped, isFalse);
        expect(
          find.text('Nessun abbonamento Pro attivo da sbloccare.'),
          findsOneWidget,
        );
        await stateController.close();
      },
    );
  });
}
