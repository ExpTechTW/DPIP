import 'package:in_app_purchase/in_app_purchase.dart';

/// Extension on [ProductDetails] that provides convenient utilities for product type identification.
///
/// This extension adds helpful getters to simplify identifying product types, particularly distinguishing between
/// subscription and one-time purchase products.
extension ProductDetailExtension on ProductDetails {
  /// Checks whether this product is a subscription.
  ///
  /// Returns `true` if the product ID starts with 's_', indicating it is a subscription product. Returns `false` for
  /// one-time purchase products.
  ///
  /// This is useful for filtering and displaying products differently based on their type, as subscriptions and
  /// one-time purchases often require different UI and purchase flows.
  ///
  /// Example:
  /// ```dart
  /// final products = await InAppPurchase.instance.queryProductDetails(productIds);
  /// final subscriptions = products.productDetails.where((p) => p.isSubscription).toList();
  /// final oneTimePurchases = products.productDetails.where((p) => !p.isSubscription).toList();
  /// ```
  bool get isSubscription => id.startsWith('s_');
}
