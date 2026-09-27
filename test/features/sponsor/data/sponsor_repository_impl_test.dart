/// [InAppPurchaseSponsorRepository] is the one repository in this coverage
/// slice that does **not** go through `guardResult`/`mapException`:
/// [InAppPurchaseSponsorRepository.products] wraps its whole body in a
/// hand-rolled try/catch that folds *everything* — a store-shaped
/// `DioException`, a `FormatException`, anything — into [UnexpectedFailure].
/// There is no [DecodeFailure] or [TimeoutFailure] path here at all, unlike
/// every other file in this slice; this file pins that on purpose, so a
/// future "let's make this consistent with the others" refactor is a
/// deliberate decision, not an accident.
///
/// [InAppPurchaseSponsorRepository.buy] and [InAppPurchaseSponsorRepository.restore]
/// don't return a [Result] at all — both collapse every failure mode (store
/// unavailable, product never staged by [InAppPurchaseSponsorRepository.products],
/// a synchronous store rejection) into a bare `false`, so this file pins what
/// each `false` actually means rather than treating them as interchangeable.
///
/// The store SDK's `InAppPurchase` has a private constructor
/// (`InAppPurchase._()`), so it can never be constructed directly in a test —
/// [_FakeIAP] is built with `implements` instead. Every member the repository
/// can reach is scripted below; the two it never calls (`countryCode`,
/// `getPlatformAddition`) throw rather than silently running real
/// platform-channel code.
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dpip/core/error/failure.dart';
import 'package:dpip/features/sponsor/data/sponsor_repository_impl.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
// ignore: depend_on_referenced_packages
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart'
    show InAppPurchasePlatformAddition;

/// A hand-scripted [InAppPurchase] double, since the real class cannot be
/// instantiated in a test. Records every call the repository makes and lets
/// [isAvailable] throw on demand (to prove the repository's own try/catch
/// swallows even a transport-shaped fault into [UnexpectedFailure]).
class _FakeIAP implements InAppPurchase {
  bool available = true;
  Object? isAvailableError;
  ProductDetailsResponse queryResponse = ProductDetailsResponse(
    productDetails: const [],
    notFoundIDs: const [],
  );
  bool buyConsumableResult = true;
  bool buyNonConsumableResult = true;

  final List<Set<String>> queriedIds = [];
  final List<PurchaseParam> consumableBuys = [];
  final List<PurchaseParam> nonConsumableBuys = [];
  final List<PurchaseDetails> completed = [];
  int restoreCalls = 0;

  final StreamController<List<PurchaseDetails>> _updates =
      StreamController<List<PurchaseDetails>>.broadcast();

  /// Pushes a fake store update to whatever subscribed to [purchaseStream].
  void emit(List<PurchaseDetails> updates) => _updates.add(updates);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async {
    if (isAvailableError != null) throw isAvailableError!;
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedIds.add(identifiers);
    return queryResponse;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async {
    consumableBuys.add(purchaseParam);
    return buyConsumableResult;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    nonConsumableBuys.add(purchaseParam);
    return buyNonConsumableResult;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed.add(purchase);
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls++;
  }

  @override
  Future<String> countryCode() => throw UnimplementedError();

  @override
  T getPlatformAddition<T extends InAppPurchasePlatformAddition?>() =>
      throw UnimplementedError();
}

ProductDetails _detail({
  required String id,
  String title = 'Product',
  String description = 'A product',
  String price = 'NT\$100',
  double rawPrice = 100,
}) => ProductDetails(
  id: id,
  title: title,
  description: description,
  price: price,
  rawPrice: rawPrice,
  currencyCode: 'TWD',
);

PurchaseDetails _purchase({
  required String productID,
  required PurchaseStatus status,
  bool pendingCompletePurchase = false,
}) {
  final purchase = PurchaseDetails(
    productID: productID,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'test',
    ),
    transactionDate: null,
    status: status,
  );
  purchase.pendingCompletePurchase = pendingCompletePurchase;
  return purchase;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('products() reports the store as unavailable as NetworkFailure, without '
      'ever querying the catalog', () async {
    final iap = _FakeIAP()..available = false;
    final repo = InAppPurchaseSponsorRepository(iap);

    final result = await repo.products();

    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(iap.queriedIds, isEmpty);
  });

  test(
    'products() queries exactly the sponsor catalog ids, nothing more or less',
    () async {
      final iap = _FakeIAP()
        ..queryResponse = ProductDetailsResponse(
          productDetails: [_detail(id: 'donation100')],
          notFoundIDs: const [],
        );
      final repo = InAppPurchaseSponsorRepository(iap);

      await repo.products();

      expect(iap.queriedIds.single, {
        's_donation75',
        'donation100',
        'donation300',
        'donation1000',
      });
    },
  );

  test(
    'a store query error surfaces its own message via UnexpectedFailure',
    () async {
      final iap = _FakeIAP()
        ..queryResponse = ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const [],
          error: IAPError(
            source: 'test',
            code: 'boom',
            message: 'store on fire',
          ),
        );
      final repo = InAppPurchaseSponsorRepository(iap);

      final result = await repo.products();

      expect(
        result.failureOrNull,
        isA<UnexpectedFailure>().having(
          (f) => f.message,
          'message',
          'store on fire',
        ),
      );
    },
  );

  test('no matching products is NoDataFailure, not an empty Ok list', () async {
    final iap = _FakeIAP();
    final repo = InAppPurchaseSponsorRepository(iap);

    final result = await repo.products();

    expect(result.failureOrNull, isA<NoDataFailure>());
  });

  test(
    'a thrown FormatException still folds into UnexpectedFailure — this '
    'repository has no guardResult, so there is no DecodeFailure path',
    () async {
      final iap = _FakeIAP()
        ..isAvailableError = const FormatException('bad shape');
      final repo = InAppPurchaseSponsorRepository(iap);

      final result = await repo.products();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull, isNot(isA<DecodeFailure>()));
    },
  );

  test(
    'even a DioException-shaped fault becomes UnexpectedFailure here — '
    'unlike the rest of this slice, nothing gives it its own Failure subtype',
    () async {
      final iap = _FakeIAP()
        ..isAvailableError = DioException(
          requestOptions: RequestOptions(path: '/unused'),
          type: DioExceptionType.connectionTimeout,
        );
      final repo = InAppPurchaseSponsorRepository(iap);

      final result = await repo.products();

      expect(result.failureOrNull, isA<UnexpectedFailure>());
      expect(result.failureOrNull, isNot(isA<TimeoutFailure>()));
    },
  );

  test(
    'products are sorted cheapest first regardless of query order',
    () async {
      final iap = _FakeIAP()
        ..queryResponse = ProductDetailsResponse(
          productDetails: [
            _detail(id: 'donation1000', rawPrice: 1000),
            _detail(id: 'donation100', rawPrice: 100),
            _detail(id: 'donation300', rawPrice: 300),
          ],
          notFoundIDs: const [],
        );
      final repo = InAppPurchaseSponsorRepository(iap);

      final result = await repo.products();

      expect(result.valueOrNull?.map((p) => p.id).toList(), [
        'donation100',
        'donation300',
        'donation1000',
      ]);
    },
  );

  test(
    'isSubscription comes from the id prefix, never the store title',
    () async {
      final iap = _FakeIAP()
        ..queryResponse = ProductDetailsResponse(
          productDetails: [
            _detail(id: 's_donation75', title: 'Monthly (DPIP)'),
            _detail(id: 'donation100', title: 'One-time (DPIP)'),
          ],
          notFoundIDs: const [],
        );
      final repo = InAppPurchaseSponsorRepository(iap);

      final result = await repo.products();

      final byId = {
        for (final p in result.valueOrNull ?? <SponsorProduct>[]) p.id: p,
      };
      expect(byId['s_donation75']!.isSubscription, isTrue);
      expect(byId['donation100']!.isSubscription, isFalse);
    },
  );

  test('a trailing "(DPIP)" suffix is trimmed from the title', () async {
    final iap = _FakeIAP()
      ..queryResponse = ProductDetailsResponse(
        productDetails: [_detail(id: 'donation100', title: 'Coffee (DPIP)')],
        notFoundIDs: const [],
      );
    final repo = InAppPurchaseSponsorRepository(iap);

    final result = await repo.products();

    expect(result.valueOrNull?.single.title, 'Coffee');
  });

  test(
    'a title that starts with "(" is left untouched, not trimmed to empty',
    () async {
      // The guard is `paren > 0`, not `paren >= 0`: indexOf('(') is 0 here,
      // so trimming is deliberately skipped rather than producing ''.
      final iap = _FakeIAP()
        ..queryResponse = ProductDetailsResponse(
          productDetails: [
            _detail(id: 'donation100', title: '(Limited) Coffee'),
          ],
          notFoundIDs: const [],
        );
      final repo = InAppPurchaseSponsorRepository(iap);

      final result = await repo.products();

      expect(result.valueOrNull?.single.title, '(Limited) Coffee');
    },
  );

  test(
    'buy() reports false for a product never staged by products()',
    () async {
      final iap = _FakeIAP();
      final repo = InAppPurchaseSponsorRepository(iap);
      const product = SponsorProduct(
        id: 'donation100',
        title: 'Coffee',
        description: 'd',
        price: 'NT\$100',
        rawPrice: 100,
        isSubscription: false,
      );

      final bought = await repo.buy(product);

      expect(bought, isFalse);
      expect(iap.consumableBuys, isEmpty);
      expect(iap.nonConsumableBuys, isEmpty);
    },
  );

  test('buy() on a subscription calls buyNonConsumable with its own ProductDetails', () async {
    final detail = _detail(id: 's_donation75', rawPrice: 75);
    final iap = _FakeIAP()
      ..queryResponse = ProductDetailsResponse(
        productDetails: [detail],
        notFoundIDs: const [],
      );
    final repo = InAppPurchaseSponsorRepository(iap);
    final products = (await repo.products()).valueOrNull!;

    final bought = await repo.buy(products.single);

    expect(bought, isTrue);
    expect(iap.nonConsumableBuys.single.productDetails, same(detail));
    expect(iap.consumableBuys, isEmpty);
  });

  test(
    'buy() on a one-time tip calls buyConsumable, not buyNonConsumable',
    () async {
      final detail = _detail(id: 'donation100', rawPrice: 100);
      final iap = _FakeIAP()
        ..queryResponse = ProductDetailsResponse(
          productDetails: [detail],
          notFoundIDs: const [],
        );
      final repo = InAppPurchaseSponsorRepository(iap);
      final products = (await repo.products()).valueOrNull!;

      final bought = await repo.buy(products.single);

      expect(bought, isTrue);
      expect(iap.consumableBuys.single.productDetails, same(detail));
      expect(iap.nonConsumableBuys, isEmpty);
    },
  );

  test(
    'restore() reports false without touching the store when unavailable',
    () async {
      final iap = _FakeIAP()..available = false;
      final repo = InAppPurchaseSponsorRepository(iap);

      final restored = await repo.restore();

      expect(restored, isFalse);
      expect(iap.restoreCalls, 0);
    },
  );

  test(
    'restore() calls restorePurchases and reports true when available',
    () async {
      final iap = _FakeIAP();
      final repo = InAppPurchaseSponsorRepository(iap);

      final restored = await repo.restore();

      expect(restored, isTrue);
      expect(iap.restoreCalls, 1);
    },
  );

  test('a settled, pending-completion purchase is both completed with the '
      'store and surfaced on purchases()', () async {
    final iap = _FakeIAP();
    final repo = InAppPurchaseSponsorRepository(iap);
    final events = <SponsorPurchase>[];
    repo.purchases().listen(events.add);

    iap.emit([
      _purchase(
        productID: 'donation100',
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    ]);
    await _settle();

    expect(iap.completed, hasLength(1));
    expect(iap.completed.single.productID, 'donation100');
    // SponsorPurchase has no `==` override, so compare fields rather than
    // whole-object equality against a fresh instance.
    expect(events, hasLength(1));
    expect(events.single.productId, 'donation100');
    expect(events.single.status, SponsorPurchaseStatus.purchased);
  });

  test('a still-pending purchase is never completed with the store, even when '
      'the store already flagged it pendingCompletePurchase', () async {
    final iap = _FakeIAP();
    // Constructing the repository is what subscribes to the store's
    // purchase stream; nothing else in this test needs the instance.
    InAppPurchaseSponsorRepository(iap);

    iap.emit([
      _purchase(
        productID: 'donation100',
        status: PurchaseStatus.pending,
        pendingCompletePurchase: true,
      ),
    ]);
    await _settle();

    expect(iap.completed, isEmpty);
  });

  test(
    'every store status maps to its own domain status, one to one',
    () async {
      final iap = _FakeIAP();
      final repo = InAppPurchaseSponsorRepository(iap);
      final events = <SponsorPurchase>[];
      repo.purchases().listen(events.add);

      for (final status in PurchaseStatus.values) {
        iap.emit([_purchase(productID: 'p-${status.name}', status: status)]);
        await _settle();
      }

      expect(events.map((e) => e.status).toList(), [
        SponsorPurchaseStatus.pending,
        SponsorPurchaseStatus.purchased,
        SponsorPurchaseStatus.error,
        SponsorPurchaseStatus.restored,
        SponsorPurchaseStatus.canceled,
      ]);
    },
  );

  test('dispose() cancels the store subscription before closing the update '
      'stream, so a late store update never reaches completePurchase again', () async {
    final iap = _FakeIAP();
    final repo = InAppPurchaseSponsorRepository(iap);
    var done = false;
    repo.purchases().listen((_) {}, onDone: () => done = true);

    repo.dispose();
    await _settle();
    expect(done, isTrue);

    iap.emit([
      _purchase(
        productID: 'donation100',
        status: PurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    ]);
    await _settle();

    expect(
      iap.completed,
      isEmpty,
      reason:
          'the store subscription must be cancelled, not just the sink closed',
    );
  });
}
