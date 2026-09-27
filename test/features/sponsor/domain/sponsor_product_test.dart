/// A store product, normalised from platform `ProductDetails`.
/// [isSubscription] is the one field the repository derives itself (from the
/// `s_` id prefix, in `SponsorRepositoryImpl._toDomain`) rather than reading
/// off the store, and it drives which purchase call `buy()` makes:
/// non-consumable for a subscription, consumable for a one-time tip so it can
/// be bought again. Flip that flag and a subscription is bought as a
/// consumable — the wrong purchase API for that product on the store.
/// [price] is the store's localised display string; [rawPrice] is the numeric
/// amount kept alongside it for sorting/analytics — the two are independent
/// fields and neither is derived from the other.
library;

import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a subscription product exposes every field as constructed', () {
    const product = SponsorProduct(
      id: 's_donation75',
      title: 'Monthly',
      description: 'A monthly subscription',
      price: 'NT\$75',
      rawPrice: 75,
      isSubscription: true,
    );

    expect(product.id, 's_donation75');
    expect(product.title, 'Monthly');
    expect(product.description, 'A monthly subscription');
    expect(product.price, 'NT\$75');
    expect(product.rawPrice, 75);
    expect(product.isSubscription, isTrue);
  });

  test('a one-time tip is not flagged as a subscription', () {
    const product = SponsorProduct(
      id: 'donation100',
      title: 'Coffee',
      description: 'A one-time tip',
      price: 'NT\$100',
      rawPrice: 100,
      isSubscription: false,
    );

    expect(product.isSubscription, isFalse);
    expect(product.price, 'NT\$100');
    expect(product.rawPrice, 100);
  });
}
