import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/purchase_pro_use_case.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/restore_purchases_use_case.dart';

part 'subscription_bloc.freezed.dart';
part 'subscription_event.dart';
part 'subscription_state.dart';

@injectable
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final CheckEntitlementUseCase _checkEntitlement;
  final PurchaseProUseCase _purchasePro;
  final RestorePurchasesUseCase _restorePurchases;

  // Guards against concurrent purchase/restore: the default event transformer
  // runs handlers concurrently, so a rapid double-tap (before the loading state
  // disables the button) would otherwise re-invoke the store flow.
  bool _actionInFlight = false;

  SubscriptionBloc(
    this._checkEntitlement,
    this._purchasePro,
    this._restorePurchases,
  ) : super(const SubscriptionState.initial()) {
    on<SubscriptionCheckRequested>(_onCheckRequested);
    on<SubscriptionPurchaseRequested>(_onPurchaseRequested);
    on<SubscriptionRestoreRequested>(_onRestoreRequested);
    // Self-dispatch resolves from RevenueCat local cache before first frame (AC5).
    add(const SubscriptionEvent.checkRequested());
  }

  Future<void> _onCheckRequested(
    SubscriptionCheckRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionState.loading());
    final result = await _checkEntitlement.call();
    result.fold(
      (failure) => emit(SubscriptionState.error(failure: failure)),
      (tier) => emit(SubscriptionState.loaded(tier: tier)),
    );
  }

  Future<void> _onPurchaseRequested(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    emit(const SubscriptionState.loading());
    try {
      final result = await _purchasePro.call(event.packageId);
      result.fold(
        (failure) => emit(SubscriptionState.error(failure: failure)),
        (tier) => emit(SubscriptionState.loaded(tier: tier)),
      );
    } finally {
      _actionInFlight = false;
    }
  }

  Future<void> _onRestoreRequested(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionState> emit,
  ) async {
    if (_actionInFlight) return;
    _actionInFlight = true;
    emit(const SubscriptionState.loading());
    try {
      final result = await _restorePurchases.call();
      result.fold(
        (failure) => emit(SubscriptionState.error(failure: failure)),
        (tier) => emit(SubscriptionState.loaded(tier: tier)),
      );
    } finally {
      _actionInFlight = false;
    }
  }
}
