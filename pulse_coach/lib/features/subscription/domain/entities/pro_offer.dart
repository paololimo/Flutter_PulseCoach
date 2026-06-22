import 'package:freezed_annotation/freezed_annotation.dart';

part 'pro_offer.g.dart';
part 'pro_offer.freezed.dart';

@freezed
abstract class ProOffer with _$ProOffer {
  const factory ProOffer({
    required String packageId,
    required String priceString,
    required String period,
  }) = _ProOffer;

  factory ProOffer.fromJson(Map<String, dynamic> json) =>
      _$ProOfferFromJson(json);
}
