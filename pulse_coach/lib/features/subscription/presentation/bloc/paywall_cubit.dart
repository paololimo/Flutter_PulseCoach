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
