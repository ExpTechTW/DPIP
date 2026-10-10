/// The lifecycle of a sponsor purchase, surfaced to the UI.
library;

/// The status of a purchase update from the store.
enum SponsorPurchaseStatus { pending, purchased, restored, error, canceled }

/// One purchase-flow update for a product, mapped from the store's raw update so
/// the presentation layer never depends on `in_app_purchase` types.
class SponsorPurchase {
  const SponsorPurchase({
    required this.productId,
    required this.status,
    required this.isSubscription,
  });

  final String productId;
  final SponsorPurchaseStatus status;

  /// Whether [productId] is a subscription rather than a one-time tip.
  ///
  /// Classified by the data layer, which knows the store's ids. Looking the id
  /// up in the loaded catalogue instead would depend on arrival order: the
  /// store's update stream outlives any one page, so an update can land before
  /// — or without — a successful catalogue load, and a subscription would then
  /// be mistaken for a tip.
  final bool isSubscription;

  /// Whether the store reported the product as bought — a fresh purchase or one
  /// replayed by a restore. A restored subscription may since have expired, so
  /// this is not a claim that one is still running.
  bool get isSuccess =>
      status == SponsorPurchaseStatus.purchased ||
      status == SponsorPurchaseStatus.restored;

  /// Whether the flow has finished (anything but still-pending).
  bool get isSettled => status != SponsorPurchaseStatus.pending;
}
