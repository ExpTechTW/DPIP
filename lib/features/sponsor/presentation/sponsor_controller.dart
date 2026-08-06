/// Drives the sponsor page: loads the catalogue and tracks purchase state.
library;

import 'dart:async';

import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:flutter/widgets.dart';

/// Where the catalogue load stands.
enum SponsorStatus { loading, error, ready }

/// Holds the sponsor page's state: the product catalogue (split into
/// subscriptions and one-time tips) and the live purchase state, updated from
/// the repository's purchase stream.
class SponsorController extends ChangeNotifier with WidgetsBindingObserver {
  SponsorController(this._repository) {
    WidgetsBinding.instance.addObserver(this);
    _sub = _repository.purchases().listen(_onPurchase);
  }

  static const _purchaseLaunchTimeout = Duration(seconds: 8);
  static const _purchaseResumeGrace = Duration(milliseconds: 600);

  final SponsorRepository _repository;
  StreamSubscription<SponsorPurchase>? _sub;
  Timer? _purchaseWatchdog;

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
    try {
      final started = await _repository.buy(product);
      if (!started) _clearPurchase(product.id);
      if (started) _watchPurchaseLaunch(product.id);
    } catch (error) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          context: ErrorDescription('buy sponsor product'),
        ),
      );
      _clearPurchase(product.id);
    }
  }

  void _watchPurchaseLaunch(String productId) {
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = Timer(_purchaseLaunchTimeout, () {
      _clearPurchase(productId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final productId = purchasingId;
    if (productId == null) return;
    _purchaseWatchdog?.cancel();
    _purchaseWatchdog = Timer(_purchaseResumeGrace, () {
      _clearPurchase(productId);
    });
  }

  bool _clearPurchase(String productId) {
    if (purchasingId == productId) {
      _purchaseWatchdog?.cancel();
      _purchaseWatchdog = null;
      purchasingId = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Restores past purchases. Returns `false` if the store was unreachable, so
  /// the page can tell the user.
  Future<bool> restore() => _repository.restore();

  void _onPurchase(SponsorPurchase purchase) {
    var notified = false;
    if (purchase.isSuccess) purchasedIds.add(purchase.productId);
    // Clear the in-flight marker once this product settles (success, error, or
    // cancel) — a still-pending update keeps it busy.
    if (purchase.isSettled && purchasingId == purchase.productId) {
      notified = _clearPurchase(purchase.productId);
    } else if (purchase.status == SponsorPurchaseStatus.pending) {
      purchasingId = purchase.productId;
      notifyListeners();
      notified = true;
    }
    if (!notified && purchase.isSuccess) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseWatchdog?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
