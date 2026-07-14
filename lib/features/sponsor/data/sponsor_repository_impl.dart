/// [SponsorRepository] backed by the `in_app_purchase` plugin (StoreKit / Google
/// Play Billing).
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// The store product ids DPIP offers. Subscriptions are prefixed `s_`; the rest
/// are one-time (consumable) tips. Kept here (a store-config detail) rather than
/// in the domain.
const Set<String> _catalogIds = {
  's_donation75',
  'donation100',
  'donation300',
  'donation1000',
};

class InAppPurchaseSponsorRepository implements SponsorRepository {
  InAppPurchaseSponsorRepository(this._iap) {
    // Listen for the app's lifetime: purchases can complete after the page that
    // started them has closed, and each must still be finalised with the store.
    _sub = _iap.purchaseStream.listen(
      _onUpdates,
      onError: (Object error, StackTrace stackTrace) =>
          Log.handle(error, stackTrace, 'Sponsor purchase stream error'),
    );
  }

  final InAppPurchase _iap;
  final StreamController<SponsorPurchase> _updates =
      StreamController<SponsorPurchase>.broadcast();

  /// The last queried store details, kept so [buy] can look the product up by id
  /// (the store buy call needs the original `ProductDetails`).
  final Map<String, ProductDetails> _details = {};

  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  Stream<SponsorPurchase> purchases() => _updates.stream;

  @override
  Future<Result<List<SponsorProduct>>> products() async {
    try {
      if (!await _iap.isAvailable()) {
        return const Err(NetworkFailure('Store unavailable'));
      }
      final response = await _iap.queryProductDetails(_catalogIds);
      if (response.error != null) {
        return Err(UnexpectedFailure(response.error!.message));
      }
      if (response.productDetails.isEmpty) {
        return const Err(NoDataFailure('No sponsor products'));
      }
      _details
        ..clear()
        ..addEntries(response.productDetails.map((p) => MapEntry(p.id, p)));
      final products = response.productDetails.map(_toDomain).toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      return Ok(products);
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'Sponsor products query failed');
      return Err(UnexpectedFailure(error.toString()));
    }
  }

  @override
  Future<void> buy(SponsorProduct product) async {
    final details = _details[product.id];
    if (details == null) return;
    final param = PurchaseParam(productDetails: details);
    // Subscriptions and non-consumables buy the same way; one-time tips are
    // consumable so they can be given again.
    if (product.isSubscription) {
      await _iap.buyNonConsumable(purchaseParam: param);
    } else {
      await _iap.buyConsumable(purchaseParam: param);
    }
  }

  @override
  Future<bool> restore() async {
    if (!await _iap.isAvailable()) return false;
    await _iap.restorePurchases();
    return true;
  }

  void _onUpdates(List<PurchaseDetails> updates) {
    for (final purchase in updates) {
      // Acknowledge anything the store is waiting on, or it re-delivers the
      // purchase on the next launch.
      if (purchase.status != PurchaseStatus.pending &&
          purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
      _updates.add(
        SponsorPurchase(
          productId: purchase.productID,
          status: _mapStatus(purchase.status),
        ),
      );
    }
  }

  /// Trims a store title's trailing app-name suffix, e.g. `Monthly (DPIP)`.
  SponsorProduct _toDomain(ProductDetails p) {
    final paren = p.title.indexOf('(');
    final title = paren > 0 ? p.title.substring(0, paren).trim() : p.title;
    return SponsorProduct(
      id: p.id,
      title: title,
      description: p.description,
      price: p.price,
      rawPrice: p.rawPrice,
      isSubscription: p.id.startsWith('s_'),
    );
  }

  SponsorPurchaseStatus _mapStatus(PurchaseStatus status) => switch (status) {
    PurchaseStatus.pending => SponsorPurchaseStatus.pending,
    PurchaseStatus.purchased => SponsorPurchaseStatus.purchased,
    PurchaseStatus.restored => SponsorPurchaseStatus.restored,
    PurchaseStatus.error => SponsorPurchaseStatus.error,
    PurchaseStatus.canceled => SponsorPurchaseStatus.canceled,
  };

  @override
  void dispose() {
    _sub?.cancel();
    _updates.close();
  }
}
