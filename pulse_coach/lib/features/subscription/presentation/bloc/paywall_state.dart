part of 'paywall_cubit.dart';

@freezed
sealed class PaywallState with _$PaywallState {
  const factory PaywallState.loading() = _Loading;
  const factory PaywallState.loaded({required List<ProOffer> offers}) = _Loaded;
  const factory PaywallState.error({required String message}) = _Error;
}
