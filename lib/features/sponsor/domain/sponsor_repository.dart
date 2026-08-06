/// The support / in-app-purchase surface, behind a data-layer implementation.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';

/// Reads the sponsor catalogue and drives purchases, so the presentation layer
/// never touches the store SDK directly.
///
/// [products] is one-shot; [purchases] is the live update stream the flow drives
/// (pending → settled). The implementation owns finalising completed purchases
/// with the store, so callers only react to the domain [SponsorPurchase] events.
abstract interface class SponsorRepository {
  /// The available sponsor products (subscriptions + one-time), cheapest first.
  /// `Err` when the store is unreachable or has no matching products.
  Future<Result<List<SponsorProduct>>> products();

  /// Purchase-flow updates as they arrive from the store. A broadcast stream, so
  /// it can be listened to from wherever the flow is shown.
  Stream<SponsorPurchase> purchases();

  /// 開始購買 [product]
  ///
  /// 當商店不開始購買流程時返回 `false`
  /// 已開始的流程仍然通過 [purchases] 報告最終結果
  Future<bool> buy(SponsorProduct product);

  /// Restores previously bought subscriptions / non-consumables. Returns `false`
  /// when the store is unreachable (nothing was initiated).
  Future<bool> restore();

  /// Cancels the underlying store subscription; call once when done.
  void dispose();
}
