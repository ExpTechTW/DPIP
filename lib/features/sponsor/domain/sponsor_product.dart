/// A purchasable way to support the app — a subscription or a one-time tip.
library;

/// One sponsor product, projected from the store's product details into a domain
/// value type so no `in_app_purchase` type leaks above the data layer.
///
/// [price] is the store's already-localized price string (currency + amount);
/// [rawPrice] is the numeric amount, used only to order cheapest-first.
/// [isSubscription] classifies it (recurring vs one-time) so the two render and
/// purchase differently.
class SponsorProduct {
  const SponsorProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.rawPrice,
    required this.isSubscription,
  });

  final String id;
  final String title;
  final String description;
  final String price;
  final double rawPrice;
  final bool isSubscription;
}
