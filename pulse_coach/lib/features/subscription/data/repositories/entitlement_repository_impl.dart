import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:injectable/injectable.dart';
import 'package:pulse_coach/core/cloud/entitlement_gate.dart';
import 'package:pulse_coach/core/error/failures.dart';
import 'package:pulse_coach/features/subscription/domain/entities/pro_offer.dart';
import 'package:pulse_coach/features/subscription/domain/entities/subscription_tier.dart';
import 'package:pulse_coach/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

@Injectable(as: EntitlementRepository)
class EntitlementRepositoryImpl implements EntitlementRepository {
  final EntitlementGate _gate;

  EntitlementRepositoryImpl(this._gate);

  @override
  Future<SubscriptionTier> currentTier() async {
    // The gate is the single source of truth: refresh() does one RevenueCat
    // fetch and resolves all three tiers from (auth session + pro entitlement).
    await _gate.refresh();
    return _gate.currentTier;
  }

  @override
  Future<void> invalidateCache() async {
    await _gate.refresh();
  }

  @override
  Future<Either<Failure, List<ProOffer>>> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      if (packages.isEmpty) {
        // No current offering / empty package list: surface an actionable
        // error instead of returning an empty list that renders a dead paywall.
        return const Left(
          SubscriptionFailure('Nessun abbonamento disponibile al momento.'),
        );
      }
      final offers = packages
          .map(
            (p) => ProOffer(
              packageId: p.identifier,
              priceString: p.storeProduct.priceString,
              period: _periodLabel(p.packageType),
            ),
          )
          .toList();
      return Right(offers);
    } on PlatformException catch (e) {
      return Left(
        SubscriptionFailure(e.message ?? 'Impossibile caricare gli abbonamenti.'),
      );
    } catch (_) {
      return const Left(
        SubscriptionFailure('Impossibile caricare gli abbonamenti.'),
      );
    }
  }

  @override
  Future<Either<Failure, SubscriptionTier>> purchasePro(
    String packageId,
  ) async {
    try {
      final offerings = await Purchases.getOfferings();
      Package? package;
      for (final p in offerings.current?.availablePackages ?? []) {
        if (p.identifier == packageId) {
          package = p;
          break;
        }
      }
      if (package == null) {
        return const Left(SubscriptionFailure('Pacchetto non trovato'));
      }
      await Purchases.purchase(PurchaseParams.package(package));
      await _gate.refresh();
      return Right(_gate.currentTier);
    } on PlatformException catch (e) {
      return Left(SubscriptionFailure(e.message ?? 'Acquisto non riuscito'));
    } catch (e) {
      return Left(SubscriptionFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SubscriptionTier>> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
      await _gate.refresh();
      return Right(_gate.currentTier);
    } on PlatformException catch (e) {
      return Left(SubscriptionFailure(e.message ?? 'Ripristino non riuscito.'));
    } catch (_) {
      return const Left(SubscriptionFailure('Ripristino non riuscito.'));
    }
  }

  String _periodLabel(PackageType type) {
    switch (type) {
      case PackageType.monthly:
        return 'mensile';
      case PackageType.annual:
        return 'annuale';
      case PackageType.weekly:
        return 'settimanale';
      default:
        return type.name;
    }
  }
}

