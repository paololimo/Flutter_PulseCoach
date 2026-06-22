part of 'subscription_bloc.dart';

@freezed
sealed class SubscriptionEvent with _$SubscriptionEvent {
  const factory SubscriptionEvent.checkRequested() = SubscriptionCheckRequested;
  const factory SubscriptionEvent.purchaseRequested({
    required String packageId,
  }) = SubscriptionPurchaseRequested;
  const factory SubscriptionEvent.restoreRequested() =
      SubscriptionRestoreRequested;
}
