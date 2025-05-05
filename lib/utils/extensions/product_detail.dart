import 'package:in_app_purchase/in_app_purchase.dart';

extension ProductDetailExtension on ProductDetails {
  bool get isSubscription => id.startsWith('s_');
}
