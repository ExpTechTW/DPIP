/// The lifecycle of a sponsor purchase, surfaced to the UI.
library;

/// The status of a purchase update from the store.
enum SponsorPurchaseStatus { pending, purchased, restored, error, canceled }

/// One purchase-flow update for a product, mapped from the store's raw update so
/// the presentation layer never depends on `in_app_purchase` types.
class SponsorPurchase {
  const SponsorPurchase({required this.productId, required this.status});

  final String productId;
  final SponsorPurchaseStatus status;

  /// Whether the product is now owned (a fresh buy or a restore).
  bool get isSuccess =>
      status == SponsorPurchaseStatus.purchased ||
      status == SponsorPurchaseStatus.restored;

  /// Whether the flow has finished (anything but still-pending).
  bool get isSettled => status != SponsorPurchaseStatus.pending;
}
