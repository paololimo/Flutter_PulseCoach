import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/usecases/check_entitlement_use_case.dart';

part 'subscription_bloc.freezed.dart';
part 'subscription_event.dart';
part 'subscription_state.dart';

@injectable
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final CheckEntitlementUseCase _checkEntitlement;

  SubscriptionBloc(this._checkEntitlement) : super(const SubscriptionState.initial()) {
    on<SubscriptionCheckRequested>(_onCheckRequested);
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
}
