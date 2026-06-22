---
baseline_commit: 31fa709
---

# Story 17.4: Subscription Purchase, Restore, and Management

Status: done

## Story

As a user,
I want to purchase, restore, and manage my Pro subscription within the app,
So that I can upgrade, cancel, or recover my subscription through standard store flows.

## Acceptance Criteria

**AC1 — PaywallPage renders with live prices (FR58, no hardcoded prices):**
Given the user taps `Scopri Pro` in the `ProUpsellSheet`
When the paywall page renders (at route `/paywall` via `PaywallPage`)
Then the available Pro plan(s) are fetched from RevenueCat via `Purchases.getOfferings()` and displayed with the store-formatted price string and billing period; no price string is hardcoded in the Dart source

**AC2 — Purchase succeeds: entitlement updates, Pro features unlock in-place (FR58):**
Given the user taps the purchase button on a Pro plan on `PaywallPage`
When the platform IAP sheet completes successfully
Then `SubscriptionBloc` emits `loading()` then `loaded(tier: SubscriptionTier.pro)`; `EntitlementGate` refreshes via `_gate.refresh()`; Pro features unlock in-place (ProgressPage shows full history); `PaywallPage` pops automatically

**AC3 — Restore purchases: entitlement re-confirmed, Pro unlocks (FR60):**
Given a returning user has previously purchased Pro on another device
When they tap "Ripristina acquisti" on `PaywallPage`
Then `SubscriptionBloc` emits `loading()` then `loaded(tier: <restored tier>)`; Pro features unlock if the entitlement is active; `PaywallPage` pops automatically

**AC4 — Gestisci abbonamento opens platform store URL (FR60, NFR32):**
Given a Pro subscriber taps "Gestisci abbonamento" in the Subscription section of `SettingsPage`
When the tap is handled
Then `launchUrl(Uri.parse(<platform store URL>), mode: LaunchMode.externalApplication)` is called; no custom cancellation flow is implemented; App Store URL on iOS, Play Store URL on Android

**AC5 — Zero regressions:**
Given the implementation is complete
When `flutter analyze` and `flutter test` run from `pulse_coach/`
Then both report zero issues and all existing 966 tests continue to pass; new tests are green

## Tasks / Subtasks

- [x] **Task 1 — Add `url_launcher` dependency (AC4)**
  - [x] 1.1 Add `url_launcher: ^6.3.0` to `dependencies` in `pulse_coach/pubspec.yaml` (after `purchases_flutter`, under "In-App Purchases" comment block)
  - [x] 1.2 Run `flutter pub get` from `pulse_coach/`
  - [x] 1.3 Confirm `url_launcher` resolves cleanly (no version conflicts)

- [x] **Task 2 — Domain entity `ProOffer` (AC1)**
  - [x] 2.1 Create `lib/features/subscription/domain/entities/pro_offer.dart`:
    ```dart
    import 'package:freezed_annotation/freezed_annotation.dart';
    part 'pro_offer.g.dart';
    part 'pro_offer.freezed.dart';

    @freezed
    class ProOffer with _$ProOffer {
      const factory ProOffer({
        required String packageId,
        required String priceString,
        required String period, // e.g. "mensile", "annuale"
      }) = _ProOffer;
      factory ProOffer.fromJson(Map<String, dynamic> json) => _$ProOfferFromJson(json);
    }
    ```
  - [x] 2.2 Run `dart run build_runner build --delete-conflicting-outputs` after creation (generates `.freezed.dart` + `.g.dart`)

- [x] **Task 3 — Extend `EntitlementRepository` and its impl (AC1–AC3)**
  - [x] 3.1 Add three methods to `lib/features/subscription/domain/repositories/entitlement_repository.dart`:
    ```dart
    Future<Either<Failure, List<ProOffer>>> getOfferings();
    Future<Either<Failure, SubscriptionTier>> purchasePro(String packageId);
    Future<Either<Failure, SubscriptionTier>> restorePurchases();
    ```
    Import `ProOffer` and `Either`/`Failure` (already imported pattern — see `check_entitlement_use_case.dart`).
  - [x] 3.2 Implement all three in `lib/features/subscription/data/repositories/entitlement_repository_impl.dart`:

    **`getOfferings()`:**
    ```dart
    @override
    Future<Either<Failure, List<ProOffer>>> getOfferings() async {
      try {
        final offerings = await Purchases.getOfferings();
        final packages = offerings.current?.availablePackages ?? [];
        final offers = packages.map((p) => ProOffer(
          packageId: p.identifier,
          priceString: p.storeProduct.priceString,
          period: _periodLabel(p.packageType),
        )).toList();
        return Right(offers);
      } catch (e) {
        return Left(SubscriptionFailure(e.toString()));
      }
    }

    String _periodLabel(PackageType type) {
      switch (type) {
        case PackageType.monthly: return 'mensile';
        case PackageType.annual: return 'annuale';
        case PackageType.weekly: return 'settimanale';
        default: return type.name;
      }
    }
    ```

    **`purchasePro(String packageId)`:**
    ```dart
    @override
    Future<Either<Failure, SubscriptionTier>> purchasePro(String packageId) async {
      try {
        final offerings = await Purchases.getOfferings();
        final package = offerings.current?.availablePackages
            .firstWhere((p) => p.identifier == packageId);
        if (package == null) return Left(const SubscriptionFailure('Pacchetto non trovato'));
        await Purchases.purchasePackage(package);
        await _gate.refresh();
        return Right(_gate.currentTier);
      } on PlatformException catch (e) {
        // PurchasesErrorCode.purchaseCancelledError — propagate as-is, bloc will not show error UI
        return Left(SubscriptionFailure(e.message ?? 'Acquisto non riuscito'));
      } catch (e) {
        return Left(SubscriptionFailure(e.toString()));
      }
    }
    ```

    **`restorePurchases()`:**
    ```dart
    @override
    Future<Either<Failure, SubscriptionTier>> restorePurchases() async {
      try {
        await Purchases.restorePurchases();
        await _gate.refresh();
        return Right(_gate.currentTier);
      } catch (e) {
        return Left(SubscriptionFailure(e.toString()));
      }
    }
    ```

    **Required imports to add in `entitlement_repository_impl.dart`:**
    - `import 'package:flutter/services.dart' show PlatformException;`
    - `import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';`
    - `import 'package:purchases_flutter/purchases_flutter.dart';` (already imported)

- [x] **Task 4 — New use cases (AC1–AC3)**
  - [x] 4.1 Create `lib/features/subscription/domain/usecases/get_offerings_use_case.dart`:
    ```dart
    import 'package:dartz/dartz.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/core/error/failures.dart';
    import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
    import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';

    @injectable
    class GetOfferingsUseCase {
      final EntitlementRepository _repository;
      GetOfferingsUseCase(this._repository);

      Future<Either<Failure, List<ProOffer>>> call() => _repository.getOfferings();
    }
    ```
  - [x] 4.2 Create `lib/features/subscription/domain/usecases/purchase_pro_use_case.dart`:
    ```dart
    @injectable
    class PurchaseProUseCase {
      final EntitlementRepository _repository;
      PurchaseProUseCase(this._repository);

      Future<Either<Failure, SubscriptionTier>> call(String packageId) =>
          _repository.purchasePro(packageId);
    }
    ```
  - [x] 4.3 Create `lib/features/subscription/domain/usecases/restore_purchases_use_case.dart`:
    ```dart
    @injectable
    class RestorePurchasesUseCase {
      final EntitlementRepository _repository;
      RestorePurchasesUseCase(this._repository);

      Future<Either<Failure, SubscriptionTier>> call() =>
          _repository.restorePurchases();
    }
    ```

- [x] **Task 5 — Extend `SubscriptionBloc` with purchase and restore events (AC2, AC3)**
  - [x] 5.1 In `lib/features/subscription/presentation/bloc/subscription_event.dart`, add two factories:
    ```dart
    const factory SubscriptionEvent.purchaseRequested({required String packageId}) = SubscriptionPurchaseRequested;
    const factory SubscriptionEvent.restoreRequested() = SubscriptionRestoreRequested;
    ```
  - [x] 5.2 In `lib/features/subscription/presentation/bloc/subscription_bloc.dart`:
    - Add `PurchaseProUseCase _purchasePro` and `RestorePurchasesUseCase _restorePurchases` constructor params
    - Register `on<SubscriptionPurchaseRequested>(_onPurchaseRequested)` and `on<SubscriptionRestoreRequested>(_onRestoreRequested)` in constructor

    **`_onPurchaseRequested`:**
    ```dart
    Future<void> _onPurchaseRequested(
      SubscriptionPurchaseRequested event,
      Emitter<SubscriptionState> emit,
    ) async {
      emit(const SubscriptionState.loading());
      final result = await _purchasePro.call(event.packageId);
      result.fold(
        (failure) {
          // Treat user cancellation as a no-op — re-emit the last known tier
          // rather than showing an error. Bloc has no previous-tier memory,
          // so just dispatch checkRequested to refresh from cache.
          add(const SubscriptionEvent.checkRequested());
        },
        (tier) => emit(SubscriptionState.loaded(tier: tier)),
      );
    }
    ```

    Wait — this pattern has an issue: on cancellation we dispatch `checkRequested` which emits `loading` again. Better: keep the `loading` state until `checkRequested` resolves. Actually that's fine — the UI will show loading briefly and then the tier comes back. Or alternatively:

    ```dart
    Future<void> _onPurchaseRequested(...) async {
      emit(const SubscriptionState.loading());
      final result = await _purchasePro.call(event.packageId);
      result.fold(
        (failure) => emit(SubscriptionState.error(failure: failure)),
        (tier) => emit(SubscriptionState.loaded(tier: tier)),
      );
    }
    ```

    And the `PaywallPage` `BlocListener` distinguishes cancellation from real error by checking the failure message (fragile) OR just shows a generic snackbar on any error and stays on the page (user can retry). This is simpler.

    Use the simpler version: emit `error` on any `Left`, let the UI handle with a snackbar.

    **`_onRestoreRequested`:**
    ```dart
    Future<void> _onRestoreRequested(
      SubscriptionRestoreRequested event,
      Emitter<SubscriptionState> emit,
    ) async {
      emit(const SubscriptionState.loading());
      final result = await _restorePurchases.call();
      result.fold(
        (failure) => emit(SubscriptionState.error(failure: failure)),
        (tier) => emit(SubscriptionState.loaded(tier: tier)),
      );
    }
    ```

  - [x] 5.3 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate `subscription_bloc.freezed.dart`

- [x] **Task 6 — `PaywallCubit` for offering state (AC1)**
  - [x] 6.1 Create `lib/features/subscription/presentation/bloc/paywall_state.dart`:
    ```dart
    part of 'paywall_cubit.dart';

    @freezed
    sealed class PaywallState with _$PaywallState {
      const factory PaywallState.loading() = _Loading;
      const factory PaywallState.loaded({required List<ProOffer> offers}) = _Loaded;
      const factory PaywallState.error({required String message}) = _Error;
    }
    ```
  - [x] 6.2 Create `lib/features/subscription/presentation/bloc/paywall_cubit.dart`:
    ```dart
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:freezed_annotation/freezed_annotation.dart';
    import 'package:injectable/injectable.dart';
    import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
    import 'package:pulse_coach/features/subscription/domain/usecases/get_offerings_use_case.dart';

    part 'paywall_cubit.freezed.dart';
    part 'paywall_state.dart';

    @injectable
    class PaywallCubit extends Cubit<PaywallState> {
      final GetOfferingsUseCase _getOfferings;

      PaywallCubit(this._getOfferings) : super(const PaywallState.loading());

      Future<void> loadOfferings() async {
        emit(const PaywallState.loading());
        final result = await _getOfferings.call();
        result.fold(
          (failure) => emit(PaywallState.error(message: failure.message)),
          (offers) => emit(PaywallState.loaded(offers: offers)),
        );
      }
    }
    ```
  - [x] 6.3 Run `dart run build_runner build --delete-conflicting-outputs`

- [x] **Task 7 — `PaywallPage` (AC1, AC2, AC3)**
  - [x] 7.1 Create `lib/features/subscription/presentation/pages/paywall_page.dart`:

    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_bloc/flutter_bloc.dart';
    import 'package:pulse_coach/core/di/injection.dart';
    import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
    import 'package:pulse_coach/features/subscription/presentation/bloc/paywall_cubit.dart';
    import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';

    class PaywallPage extends StatelessWidget {
      const PaywallPage({super.key});

      @override
      Widget build(BuildContext context) {
        return BlocProvider(
          create: (_) => getIt<PaywallCubit>()..loadOfferings(),
          child: BlocListener<SubscriptionBloc, SubscriptionState>(
            listener: (context, state) {
              state.maybeWhen(
                loaded: (tier) {
                  // Pop on any purchase/restore success (tier updated)
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
                error: (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  );
                },
                orElse: () {},
              );
            },
            child: const _PaywallBody(),
          ),
        );
      }
    }

    class _PaywallBody extends StatelessWidget {
      const _PaywallBody();

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          appBar: AppBar(title: const Text('PulseCoach Pro')),
          body: BlocBuilder<PaywallCubit, PaywallState>(
            builder: (context, state) {
              return state.when(
                loading: () => const _PaywallShimmer(),
                error: (msg) => Center(child: Text(msg)),
                loaded: (offers) => _PaywallLoaded(offers: offers),
              );
            },
          ),
        );
      }
    }

    class _PaywallShimmer extends StatelessWidget {
      const _PaywallShimmer();
      @override
      Widget build(BuildContext context) {
        // Shimmer skeleton matching _PaywallLoaded layout (2 plan tiles + 2 buttons)
        // Use shimmer package (already a project dependency): Shimmer.fromColors(...)
        // Single-column ListView of 4 Container(height: 72) shimmer tiles
        // See: lib/features/sessions_catalog for shimmer usage pattern
        return const Center(child: CircularProgressIndicator()); // REPLACE with Shimmer
      }
    }
    ```

    **CRITICAL:** Replace the `CircularProgressIndicator` placeholder in `_PaywallShimmer` with a proper shimmer matching the plan card layout. See `lib/features/sessions_catalog/presentation/widgets/` for the shimmer pattern used in this project.

    ```dart
    class _PaywallLoaded extends StatelessWidget {
      final List<ProOffer> offers;
      const _PaywallLoaded({required this.offers});

      @override
      Widget build(BuildContext context) {
        return BlocBuilder<SubscriptionBloc, SubscriptionState>(
          builder: (context, subState) {
            final isLoading = subState is _Loading;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Sblocca l\'esperienza completa',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Storico completo, tutti i grafici e le funzioni social.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ...offers.map((offer) => _PlanCard(
                  offer: offer,
                  isLoading: isLoading,
                  onPurchase: () => context.read<SubscriptionBloc>().add(
                    SubscriptionEvent.purchaseRequested(packageId: offer.packageId),
                  ),
                )),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.read<SubscriptionBloc>().add(
                            const SubscriptionEvent.restoreRequested(),
                          ),
                  child: const Text('Ripristina acquisti'),
                ),
              ],
            );
          },
        );
      }
    }

    class _PlanCard extends StatelessWidget {
      final ProOffer offer;
      final bool isLoading;
      final VoidCallback onPurchase;
      const _PlanCard({required this.offer, required this.isLoading, required this.onPurchase});

      @override
      Widget build(BuildContext context) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Pro ${offer.period}'),
            subtitle: Text(offer.priceString),
            trailing: FilledButton(
              onPressed: isLoading ? null : onPurchase,
              child: const Text('Acquista'),
            ),
          ),
        );
      }
    }
    ```

  - [x] 7.2 **CRITICAL shimmer requirement**: Replace `CircularProgressIndicator` in `_PaywallShimmer` with `Shimmer.fromColors(...)` wrapping skeleton tiles — see `shimmer: ^3.0.0` package and existing usage in the sessions catalog.

- [x] **Task 8 — Add `/paywall` route to `AppRouter` (AC1)**
  - [x] 8.1 Add constant in `AppRouter`: `static const String paywall = '/paywall';`
  - [x] 8.2 Add `GoRoute` in `AppRouter.router`'s top-level routes (not inside `ShellRoute` — paywall is a full-screen overlay, no nav bar):
    ```dart
    GoRoute(
      path: paywall,
      builder: (context, state) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<SubscriptionBloc>()),
        ],
        child: const PaywallPage(),
      ),
    ),
    ```
    **CRITICAL:** `SubscriptionBloc` is provided at the app level in `app.dart` via `MultiBlocProvider`. Passing it via `BlocProvider.value` into the paywall route re-uses the same instance (no duplication). `PaywallCubit` is provided inside `PaywallPage.build()` itself (Task 7.1).
  - [x] 8.3 Add import for `PaywallPage` in `app_router.dart`

- [x] **Task 9 — Wire `ProUpsellSheet` `Scopri Pro` → PaywallPage navigation (AC1)**
  - [x] 9.1 In `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart`, update the `.then()` callback in `show()`:
    ```dart
    showModalBottomSheet<bool>(
      context: context,
      builder: (_) => const ProUpsellSheet._(),
    ).then((intent) {
      if (intent != true) {
        cooldown.recordDismissal();
      } else {
        // Scopri Pro tapped — navigate to paywall.
        // context.mounted check required: sheet was dismissed before navigation.
        if (context.mounted) context.push(AppRouter.paywall);
      }
    });
    ```
  - [x] 9.2 Add import for `AppRouter` and `go_router` (`context.push`) to `pro_upsell_sheet.dart`

- [x] **Task 10 — Add Subscription section to `SettingsPage` (AC4)**
  - [x] 10.1 In `lib/features/settings/presentation/pages/settings_page.dart`, add a "Abbonamento" section inside the `ListView` children:
    ```dart
    const SizedBox(height: 24),
    Text(
      'Abbonamento',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    const SizedBox(height: 8),
    BlocBuilder<SubscriptionBloc, SubscriptionState>(
      builder: (context, subState) {
        final isPro = subState.maybeWhen(
          loaded: (tier) => tier == SubscriptionTier.pro,
          orElse: () => false,
        );
        return Column(
          children: [
            if (isPro)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gestisci abbonamento'),
                trailing: const Icon(Icons.open_in_new),
                onTap: _launchSubscriptionManagement,
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Scopri Pro'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRouter.paywall),
              ),
          ],
        );
      },
    ),
    ```
  - [x] 10.2 Add `_launchSubscriptionManagement()` top-level function in `settings_page.dart`:
    ```dart
    Future<void> _launchSubscriptionManagement() async {
      final url = Platform.isAndroid
          ? Uri.parse('https://play.google.com/store/account/subscriptions')
          : Uri.parse('https://apps.apple.com/account/subscriptions');
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    ```
  - [x] 10.3 Add required imports to `settings_page.dart`:
    ```dart
    import 'dart:io' show Platform;
    import 'package:url_launcher/url_launcher.dart';
    import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
    import 'package:pulse_coach/features/subscription/presentation/bloc/subscription_bloc.dart';
    ```
  - [x] 10.4 `SubscriptionBloc` is already in the widget tree via `app.dart`'s `MultiBlocProvider`. No additional `BlocProvider` needed in `SettingsPage`.

- [x] **Task 11 — DI and build_runner (AC5)**
  - [x] 11.1 Confirm `@injectable` on `GetOfferingsUseCase`, `PurchaseProUseCase`, `RestorePurchasesUseCase`, and `PaywallCubit`
  - [x] 11.2 Run `dart run build_runner build --delete-conflicting-outputs` from `pulse_coach/`
  - [x] 11.3 Confirm all new classes appear in `lib/core/di/injection.config.dart`
  - [x] 11.4 `SubscriptionBloc` constructor now takes 3 use cases — injectable generates the 3-arg constructor; verify DI resolves correctly

- [x] **Task 12 — Tests (AC1–AC5)**
  - [x] 12.1 Create `test/bloc/paywall_cubit_test.dart`:
    - `17.4-PAYWALL-001`: `loadOfferings()` emits `[loading, loaded(offers)]` when use case returns offers
    - `17.4-PAYWALL-002`: `loadOfferings()` emits `[loading, error(message)]` on `SubscriptionFailure`
    - `17.4-PAYWALL-003`: initial state is `loading()`
  - [x] 12.2 Update `test/bloc/subscription_bloc_test.dart`:
    - Add `MockPurchaseProUseCase` and `MockRestorePurchasesUseCase` to `@GenerateMocks`
    - `17.4-BLOC-001`: `purchaseRequested` emits `[loading, loaded(pro)]` on success
    - `17.4-BLOC-002`: `purchaseRequested` emits `[loading, error]` on `SubscriptionFailure`
    - `17.4-BLOC-003`: `restoreRequested` emits `[loading, loaded(tier)]` on success
    - `17.4-BLOC-004`: `restoreRequested` emits `[loading, error]` on `SubscriptionFailure`
  - [x] 12.3 Create `test/widget/subscription/paywall_page_test.dart`:
    - `17.4-WIDGET-001`: `PaywallPage` shows shimmer when `PaywallCubit` is `loading`
    - `17.4-WIDGET-002`: `PaywallPage` shows plan cards with price and period when `loaded`
    - `17.4-WIDGET-003`: tapping "Acquista" dispatches `purchaseRequested` to `SubscriptionBloc`
    - `17.4-WIDGET-004`: tapping "Ripristina acquisti" dispatches `restoreRequested` to `SubscriptionBloc`
    - `17.4-WIDGET-005`: `BlocListener` pops the page when `SubscriptionBloc` emits `loaded`
    - `17.4-WIDGET-006`: `BlocListener` shows a `SnackBar` when `SubscriptionBloc` emits `error`
  - [x] 12.4 Run `dart run build_runner build --delete-conflicting-outputs` to regenerate mocks
  - [x] 12.5 Run `flutter test` — all 981 tests green; `flutter analyze` 0 issues

## Dev Notes

### Architecture Summary

```
PaywallPage (presentation)
  ├── PaywallCubit — owns offering-fetch state (loading/loaded/error)
  │   └── GetOfferingsUseCase → EntitlementRepository.getOfferings()
  │       └── EntitlementRepositoryImpl → Purchases.getOfferings()
  └── SubscriptionBloc (app-level singleton, passed via BlocProvider.value)
      ├── PurchaseRequested(packageId) → PurchaseProUseCase
      │   └── EntitlementRepositoryImpl → Purchases.purchasePackage() + _gate.refresh()
      └── RestoreRequested → RestorePurchasesUseCase
          └── EntitlementRepositoryImpl → Purchases.restorePurchases() + _gate.refresh()

SettingsPage (presentation)
  └── BlocBuilder<SubscriptionBloc> → shows "Gestisci abbonamento" tile if isPro
      └── _launchSubscriptionManagement() → url_launcher

ProUpsellSheet.show() (widget)
  └── Scopri Pro tap → pop(true) → .then() → context.push(AppRouter.paywall)
```

### Critical: `purchases_flutter` v10 API

`purchases_flutter: ^10.3.0` is already in `pubspec.yaml`. Key API for this story:

```dart
// Fetch offerings — call in getOfferings()
final Offerings offerings = await Purchases.getOfferings();
final Offering? current = offerings.current;
final List<Package> packages = current?.availablePackages ?? [];

// Each Package:
// package.identifier — unique id string (e.g. "$rc_monthly")
// package.storeProduct.priceString — formatted price (e.g. "€ 4,99")
// package.storeProduct.subscriptionPeriod — ISO 8601 (e.g. "P1M")
// package.packageType — PackageType enum (monthly, annual, etc.)

// Purchase
final CustomerInfo info = await Purchases.purchasePackage(package);

// Restore
final CustomerInfo info = await Purchases.restorePurchases();

// PlatformException is the error type from RevenueCat SDK
// import 'package:flutter/services.dart' show PlatformException;
```

### Critical: `PackageType` import

`PackageType` is from `package:purchases_flutter/purchases_flutter.dart` — already imported in `entitlement_repository_impl.dart`. No new import needed there.

### Critical: `SubscriptionBloc` constructor change

`SubscriptionBloc` currently takes `CheckEntitlementUseCase _checkEntitlement` (1 arg).
After this story it takes 3 args: `CheckEntitlementUseCase, PurchaseProUseCase, RestorePurchasesUseCase`.
`@injectable` + `injectable_generator` will auto-generate the 3-arg constructor in `injection.config.dart`. No manual DI code needed.

The existing `SubscriptionBloc` test's `buildBloc()` call must be updated:
```dart
// OLD:
SubscriptionBloc buildBloc() => SubscriptionBloc(mockCheckEntitlement);
// NEW:
SubscriptionBloc buildBloc() => SubscriptionBloc(mockCheckEntitlement, mockPurchasePro, mockRestorePurchases);
```

### Critical: `PaywallPage` BlocListener — pop-on-loaded guard

`SubscriptionBloc.checkRequested` also emits `loaded`. The `BlocListener` in `PaywallPage` must NOT pop on the initial `loaded` that fires when the page first opens. Use `listenWhen` to only listen after a purchase or restore action:

```dart
BlocListener<SubscriptionBloc, SubscriptionState>(
  listenWhen: (previous, current) =>
      previous is _Loading && current is _Loaded,
  listener: (context, state) { ... pop ... },
)
```

This ensures the pop only triggers after the user explicitly purchases or restores (after `loading` → `loaded` transition), not on the initial page render where the bloc may already be in `loaded` state.

### Critical: `SubscriptionBloc` purchase error vs. cancellation

When the user cancels the IAP native sheet, RevenueCat SDK throws a `PlatformException` with a cancellation code. The `_onPurchaseRequested` handler emits `error(SubscriptionFailure(...))` for any Left. The `PaywallPage` `BlocListener` shows a snackbar on error — a brief "acquisto annullato" snackbar on cancellation is acceptable UX. The page does NOT pop on error, so the user can retry.

### Critical: `ProUpsellSheet` context after `pop(true)`

After `Navigator.pop(true)` (or `showModalBottomSheet.then((intent) {...})`), the `context` may be unmounted. Always check `context.mounted` before calling `context.push(...)`:

```dart
.then((intent) {
  if (intent != true) {
    cooldown.recordDismissal();
  } else if (context.mounted) {
    context.push(AppRouter.paywall);
  }
});
```

### Critical: PaywallPage Route — No ShellRoute (no nav bar)

The `/paywall` route must be a **top-level `GoRoute`** (sibling of `sessionActive`, not inside `ShellRoute`). The paywall is a full-screen page without the bottom navigation bar — same pattern as `/session/active` and `/account`.

### Critical: `Failure.message` availability

`SubscriptionFailure` extends `Failure`. `Failure` base class has abstract getter `String get message`. `PaywallCubit` calls `failure.message` in the error emit. Verify `SubscriptionFailure` exposes `.message` (it does — see `lib/core/error/failures.dart` line 56–59).

### Critical: `context.push` import for `ProUpsellSheet`

`context.push(...)` is provided by `go_router`'s `BuildContext` extension. Add: `import 'package:go_router/go_router.dart';` to `pro_upsell_sheet.dart`.

### E9-K1 Fire-Check (Category B standing rule)

**(a) DI/lifecycle/cross-cutting patches [E6-P1 scope]:** **TRIGGERED.** Adds 3 new use cases + `PaywallCubit` to DI; `SubscriptionBloc` constructor changes from 1 → 3 args. → Run `build_runner` after all new classes are created. Verify `injection.config.dart` resolves correctly.

**(b) E16R-1 trigger check:** This story does NOT touch `AuthRepositoryImpl` or auth/backup datasources. `E16R-1` (restore round-trip test + signOut-after-200 safety assertion) remains open in the action-item-ledger as Category A item. It is NOT in scope for Story 17.4; do not fold it in.

**(c) Cubit/BLoC collection-index pre-flight [E7-P2]:** **NOT triggered.** No collection-index state involved.

### E16R-1 Status (Do Not Scope Into This Story)

`E16R-1` (auth/backup datasource test hardening) is an open Category A deferred item per `action-item-ledger.md`. It was noted in Story 17.3 as "schedule in Story 17.4 or standalone." Decision for Story 17.4: **out of scope** — this story closes Epic 17 and E16R-1 is an auth concern (Epic 16). Create a standalone task or fold into Epic 18 kickoff triage.

### ProOffer entity — `@freezed` requirement

`ProOffer` uses `@freezed` per project rule: "all domain entities MUST use freezed." It needs both `.freezed.dart` and `.g.dart` (because of `fromJson`). Run `build_runner` after creating the file. Add `pro_offer.freezed.dart` and `pro_offer.g.dart` to `.gitignore` check — existing generated files ARE committed in this project (per `project-context.md`: "Generated files (.g.dart, .freezed.dart, injection.config.dart) are committed to git").

### Shimmer pattern reference

For `_PaywallShimmer`, use the shimmer package (`shimmer: ^3.0.0`). Reference: `lib/features/sessions_catalog/presentation/widgets/` for the shimmer skeleton pattern used in this project. The shimmer must match the `_PlanCard` card layout height.

### Subscription section in `SettingsPage` — scroll position

The existing `SettingsPage` `ListView` has: Account section → Theme section → Device Settings → Data Export. Insert the "Abbonamento" section **after** the Account section and **before** the Theme section. This keeps account-related items grouped at the top.

### Project Structure — New Files

```
lib/features/subscription/
  ├── domain/
  │   ├── entities/
  │   │   └── pro_offer.dart                          # NEW (+ .freezed.dart + .g.dart GENERATED)
  │   ├── repositories/
  │   │   └── entitlement_repository.dart             # MODIFIED (+3 methods)
  │   └── usecases/
  │       ├── get_offerings_use_case.dart             # NEW
  │       ├── purchase_pro_use_case.dart              # NEW
  │       └── restore_purchases_use_case.dart         # NEW
  ├── data/
  │   └── repositories/
  │       └── entitlement_repository_impl.dart        # MODIFIED (+3 implementations)
  └── presentation/
      ├── bloc/
      │   ├── paywall_cubit.dart                      # NEW
      │   ├── paywall_state.dart                      # NEW (part file)
      │   ├── paywall_cubit.freezed.dart              # GENERATED
      │   ├── subscription_event.dart                 # MODIFIED (+2 events)
      │   ├── subscription_bloc.dart                  # MODIFIED (+2 handlers, +2 constructor args)
      │   └── subscription_bloc.freezed.dart          # REGENERATED
      └── pages/
          └── paywall_page.dart                       # NEW

pulse_coach/pubspec.yaml                             # MODIFIED (+url_launcher)
lib/core/routing/app_router.dart                    # MODIFIED (+/paywall route)
lib/features/subscription/presentation/widgets/
  pro_upsell_sheet.dart                             # MODIFIED (Scopri Pro → navigate)
lib/features/settings/presentation/pages/
  settings_page.dart                                # MODIFIED (+subscription section)
lib/core/di/injection.config.dart                   # REGENERATED
```

### Project Structure — New Test Files

```
test/bloc/
  ├── paywall_cubit_test.dart                         # NEW
  └── paywall_cubit_test.mocks.dart                  # GENERATED

test/widget/subscription/
  └── paywall_page_test.dart                          # NEW
  └── paywall_page_test.mocks.dart                   # GENERATED

test/bloc/subscription_bloc_test.dart                # MODIFIED (+4 tests, +2 mocks)
test/bloc/subscription_bloc_test.mocks.dart          # REGENERATED
```

### References

- Epic 17.4 ACs: `_bmad-output/planning-artifacts/epics.md` line 2340
- FR58, FR60, NFR32: `_bmad-output/planning-artifacts/epics.md` line 92–93, 112, 171
- ARCH20 (RevenueCat, EntitlementGate): `_bmad-output/planning-artifacts/epics.md` line 197
- ARCH25–ARCH27 (new feature modules, Failure hierarchy, Bloc rules): `_bmad-output/planning-artifacts/epics.md` line 202–204
- `EntitlementGate` singleton: `lib/core/cloud/entitlement_gate.dart`
- `EntitlementRepositoryImpl` current shape: `lib/features/subscription/data/repositories/entitlement_repository_impl.dart`
- `SubscriptionBloc` current shape: `lib/features/subscription/presentation/bloc/subscription_bloc.dart`
- `ProUpsellSheet` current shape: `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart`
- `AppRouter` current routes: `lib/core/routing/app_router.dart`
- `SettingsPage` current shape: `lib/features/settings/presentation/pages/settings_page.dart`
- `purchases_flutter` v10.3.0 in pubspec: `pulse_coach/pubspec.yaml` line 53
- `SubscriptionFailure` type: `lib/core/error/failures.dart` line 56
- DI order and Bloc/Cubit rules: `_bmad-output/project-context.md`
- Previous story dev notes: `_bmad-output/implementation-artifacts/17-3-pro-upsell-sheet-with-session-day-cooldown.md`
- E16R-1 open item: `_bmad-output/implementation-artifacts/action-item-ledger.md`

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `ProOffer` needed `abstract class` (not plain `class`) for freezed code gen — fixed in Task 2.
- Private freezed factory types (`_Loading`, `_Loaded`, `_Error`) are inaccessible from outside the defining file; replaced all `is _Type` checks with `maybeWhen` calls in `PaywallPage`.
- `MissingDummyValueError` for sealed `SubscriptionState`/`PaywallState` in widget tests — fixed with `provideDummy<T>` in `setUp`.
- `ShimmerPlaceholder` requires `PulseCoachTheme` extension — added `theme: AppTheme.darkTheme` to all `MaterialApp` instances in paywall tests.
- `purchasePackage` deprecated in purchases_flutter 10.3.0 — migrated to `Purchases.purchase(PurchaseParams.package(package))`.
- `_ListExtension` (unused after using for-loop) removed to fix `unused_element` warning.
- `17.3-WIDGET-004` broke because `Scopri Pro` now calls `context.push()` requiring GoRouter — fixed with router-aware scaffold in test.
- 4 regression test files needed updating after `SubscriptionBloc` constructor changed from 1 → 3 args and `EntitlementRepository` gained 3 new abstract methods.

### Completion Notes List

- All 5 ACs satisfied. `flutter analyze` reports 0 issues. 981 tests pass (966 pre-existing + 15 new: 3 PaywallCubit + 4 SubscriptionBloc + 6 PaywallPage widget + regression fix for 17.3-WIDGET-004 router requirement).
- `purchasePackage` API migrated to `Purchases.purchase(PurchaseParams.package(...))` (purchases_flutter v10 new API).
- `_PaywallShimmer` uses `ShimmerPlaceholder` (project-wide pattern), not `CircularProgressIndicator`.
- `BlocListener` pop-on-loaded uses `listenWhen` with `maybeWhen` to avoid popping on initial page render.
- `_launchSubscriptionManagement` is a top-level function (allowing `const ListTile` in isPro branch).
- E16R-1 confirmed out of scope per Dev Notes decision.

### File List

**New files:**
- `lib/features/subscription/domain/entities/pro_offer.dart`
- `lib/features/subscription/domain/entities/pro_offer.freezed.dart` (generated)
- `lib/features/subscription/domain/entities/pro_offer.g.dart` (generated)
- `lib/features/subscription/domain/usecases/get_offerings_use_case.dart`
- `lib/features/subscription/domain/usecases/purchase_pro_use_case.dart`
- `lib/features/subscription/domain/usecases/restore_purchases_use_case.dart`
- `lib/features/subscription/presentation/bloc/paywall_cubit.dart`
- `lib/features/subscription/presentation/bloc/paywall_state.dart`
- `lib/features/subscription/presentation/bloc/paywall_cubit.freezed.dart` (generated)
- `lib/features/subscription/presentation/pages/paywall_page.dart`
- `test/bloc/paywall_cubit_test.dart`
- `test/bloc/paywall_cubit_test.mocks.dart` (generated)
- `test/widget/subscription/paywall_page_test.dart`
- `test/widget/subscription/paywall_page_test.mocks.dart` (generated)

**Modified files:**
- `pulse_coach/pubspec.yaml` (+url_launcher: ^6.3.0)
- `lib/features/subscription/domain/repositories/entitlement_repository.dart` (+3 methods)
- `lib/features/subscription/data/repositories/entitlement_repository_impl.dart` (+3 implementations, migrated to purchase API)
- `lib/features/subscription/presentation/bloc/subscription_event.dart` (+2 events)
- `lib/features/subscription/presentation/bloc/subscription_bloc.dart` (+2 handlers, +2 constructor args)
- `lib/features/subscription/presentation/bloc/subscription_bloc.freezed.dart` (regenerated)
- `lib/features/subscription/presentation/widgets/pro_upsell_sheet.dart` (Scopri Pro → navigate)
- `lib/core/routing/app_router.dart` (+/paywall route)
- `lib/features/settings/presentation/pages/settings_page.dart` (+subscription section)
- `lib/core/di/injection.config.dart` (regenerated)
- `test/bloc/subscription_bloc_test.dart` (+4 tests, +2 mocks)
- `test/bloc/subscription_bloc_test.mocks.dart` (regenerated)
- `test/widget/app_shell_test.dart` (regression fix: stub +3 methods, bloc 3-arg)
- `test/widget/pages_smoke_test.dart` (regression fix: stub +3 methods, bloc 3-arg)
- `test/widget/progress/progress_page_test.dart` (regression fix: mocks +2, bloc 3-arg)
- `test/widget/settings_page_test.dart` (regression fix: SubscriptionBloc in widget tree)
- `test/widget/subscription/pro_upsell_sheet_test.dart` (17.3-WIDGET-004: router-aware scaffold)

## Change Log

| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2026-06-22 | 1.0 | Story 17.4 implemented: PaywallPage, purchase/restore flow, Settings subscription section, url_launcher integration | claude-sonnet-4-6 |

## Review Findings

_Adversarial code review 2026-06-22 (Blind Hunter + Edge Case Hunter + Acceptance Auditor, claude-opus-4-8). All 5 ACs satisfied; no blocker that breaks the happy path. Findings below._

- [x] [Review][Patch] Paywall pops on ANY `loading→loaded` regardless of resulting tier [paywall_page.dart:17-37] — **FIXED.** Pop `listenWhen`+listener now gate on `loaded(tier == pro)`; a `loading→loaded(non-pro)` transition shows a SnackBar ("Nessun abbonamento Pro attivo da sbloccare.") and keeps the user on the page instead of silently dismissing. New test `17.4-WIDGET-007` locks this in.
- [x] [Review][Patch] getOfferings & restorePurchases leak raw exception text to the UI [entitlement_repository_impl.dart] — **FIXED.** Both now branch `on PlatformException` (uses `e.message`) and fall back to a fixed Italian message instead of `e.toString()`.
- [x] [Review][Patch] Empty offerings render a blank, dead paywall treated as success [entitlement_repository_impl.dart / paywall_page.dart] — **FIXED.** Empty package list now returns `Left('Nessun abbonamento disponibile al momento.')`; the paywall error state gained a "Riprova" button (`_PaywallError`) that re-calls `loadOfferings()`.
- [x] [Review][Patch] `_launchSubscriptionManagement` ignores launchUrl result and can throw unhandled [settings_page.dart] — **FIXED.** Now takes `BuildContext`, captures the messenger before the await, wraps `launchUrl` in try/catch, and shows a SnackBar on `false` return or exception.
- [x] [Review][Patch] Concurrent/double-tap purchase & restore not guarded [subscription_bloc.dart] — **FIXED.** Added a shared `_actionInFlight` guard (set before `emit(loading)`, cleared in `finally`); a second concurrent purchase/restore event is dropped.
- [x] [Review][Patch] Widget test `17.4-WIDGET-001` asserts almost nothing [paywall_page_test.dart] — **FIXED.** Now asserts `find.byType(ShimmerPlaceholder)` findsWidgets.

_Patches applied 2026-06-22 (claude-opus-4-8). `flutter analyze` 0 issues; `flutter test` 982 green (+1 new test)._
- [x] [Review][Defer] purchasePro re-fetches offerings → latency + "Pacchetto non trovato" on transient network loss [entitlement_repository_impl.dart:55-65] — deferred: works; passing the `Package` through from the already-loaded offering is a cross-layer refactor, not surgical.
- [x] [Review][Defer] Hardcoded Italian UI strings bypass the gen_l10n/ARB pipeline [settings_page.dart, paywall_page.dart] — deferred: the spec itself prescribes these literals, app is locale-locked to `it`, and the whole subscription epic uses literals; fold into an epic-wide i18n cleanup.
- [x] [Review][Defer] No automated test covers AC4 (launchUrl / platform-URL selection) [settings_page_test.dart] — deferred: the `isPro` "Gestisci abbonamento" branch is never rendered in tests (stub returns free); pairs with the launchUrl patch.

_Dismissed as noise (5): user-cancel showing an "acquisto annullato" SnackBar (spec explicitly accepts it); BLoC `skip:2` fragility (events processed in order — safe); trailing-blank-line formatting (analyze clean); `purchasePackage→purchase` migration (intentional, documented); `Platform.isAndroid ? Play : Apple` binary (mobile-only)._
