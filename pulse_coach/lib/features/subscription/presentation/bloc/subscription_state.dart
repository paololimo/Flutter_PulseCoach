part of 'subscription_bloc.dart';

@freezed
sealed class SubscriptionState with _$SubscriptionState {
  const factory SubscriptionState.initial() = _Initial;
  const factory SubscriptionState.loading() = _Loading;
  const factory SubscriptionState.loaded({required SubscriptionTier tier}) =
      _Loaded;
  const factory SubscriptionState.error({required Failure failure}) = _Error;
}
