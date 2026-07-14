/// Drives the sponsor page: loads the catalogue and tracks purchase state.
library;

import 'dart:async';

import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:flutter/foundation.dart';

/// Where the catalogue load stands.
enum SponsorStatus { loading, error, ready }

/// Holds the sponsor page's state: the product catalogue (split into
/// subscriptions and one-time tips) and the live purchase state, updated from
/// the repository's purchase stream.
class SponsorController extends ChangeNotifier {
  SponsorController(this._repository) {
    _sub = _repository.purchases().listen(_onPurchase);
  }

  final SponsorRepository _repository;
  StreamSubscription<SponsorPurchase>? _sub;

  SponsorStatus status = SponsorStatus.loading;
  List<SponsorProduct> subscriptions = const [];
  List<SponsorProduct> oneTime = const [];

  /// The product whose purchase is currently in flight, if any.
  String? purchasingId;

  /// Products owned this session (a bought subscription / restored purchase).
  final Set<String> purchasedIds = {};

  /// Whether any purchase is mid-flight — the whole grid disables while one is.
  bool get isBusy => purchasingId != null;

  /// (Re)loads the catalogue from the store.
  Future<void> load() async {
    status = SponsorStatus.loading;
    notifyListeners();
    final result = await _repository.products();
    result.when(
      ok: (products) {
        subscriptions = products.where((p) => p.isSubscription).toList();
        oneTime = products.where((p) => !p.isSubscription).toList();
        status = SponsorStatus.ready;
      },
      err: (_) => status = SponsorStatus.error,
    );
    notifyListeners();
  }

  /// Starts buying [product]; the purchase stream drives the rest.
  Future<void> buy(SponsorProduct product) async {
    if (isBusy || purchasedIds.contains(product.id)) return;
    purchasingId = product.id;
    notifyListeners();
    await _repository.buy(product);
  }

  /// Restores past purchases. Returns `false` if the store was unreachable, so
  /// the page can tell the user.
  Future<bool> restore() => _repository.restore();

  void _onPurchase(SponsorPurchase purchase) {
    if (purchase.isSuccess) purchasedIds.add(purchase.productId);
    // Clear the in-flight marker once this product settles (success, error, or
    // cancel) — a still-pending update keeps it busy.
    if (purchase.isSettled && purchasingId == purchase.productId) {
      purchasingId = null;
    } else if (purchase.status == SponsorPurchaseStatus.pending) {
      purchasingId = purchase.productId;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
