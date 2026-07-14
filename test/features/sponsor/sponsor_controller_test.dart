import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:dpip/features/sponsor/presentation/sponsor_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _sub = SponsorProduct(
  id: 's_donation75',
  title: 'Monthly',
  description: 'A monthly subscription',
  price: 'NT\$75',
  rawPrice: 75,
  isSubscription: true,
);
const _oneTime = SponsorProduct(
  id: 'donation100',
  title: 'Coffee',
  description: 'A one-time tip',
  price: 'NT\$100',
  rawPrice: 100,
  isSubscription: false,
);

/// A [SponsorRepository] whose product result is fixed and whose purchase stream
/// the test drives by hand.
class _FakeSponsorRepository implements SponsorRepository {
  _FakeSponsorRepository(this.result);

  Result<List<SponsorProduct>> result;
  bool restoreAvailable = true;
  final List<String> bought = [];
  final StreamController<SponsorPurchase> _updates =
      StreamController<SponsorPurchase>.broadcast();

  void emit(SponsorPurchase purchase) => _updates.add(purchase);

  @override
  Future<Result<List<SponsorProduct>>> products() async => result;

  @override
  Stream<SponsorPurchase> purchases() => _updates.stream;

  @override
  Future<void> buy(SponsorProduct product) async => bought.add(product.id);

  @override
  Future<bool> restore() async => restoreAvailable;

  @override
  void dispose() => _updates.close();
}

/// Lets the broadcast stream deliver a queued event to the controller.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('load splits products into subscriptions and one-time, ready', () async {
    final repo = _FakeSponsorRepository(const Ok([_sub, _oneTime]));
    final controller = SponsorController(repo);

    await controller.load();

    expect(controller.status, SponsorStatus.ready);
    expect(controller.subscriptions.map((p) => p.id), ['s_donation75']);
    expect(controller.oneTime.map((p) => p.id), ['donation100']);
  });

  test('load surfaces a failure as the error status', () async {
    final repo = _FakeSponsorRepository(const Err(NetworkFailure('offline')));
    final controller = SponsorController(repo);

    await controller.load();

    expect(controller.status, SponsorStatus.error);
  });

  test(
    'buy marks the product in-flight and forwards to the repository',
    () async {
      final repo = _FakeSponsorRepository(const Ok([_sub]));
      final controller = SponsorController(repo)..load();
      await _settle();

      await controller.buy(_sub);

      expect(controller.purchasingId, 's_donation75');
      expect(controller.isBusy, isTrue);
      expect(repo.bought, ['s_donation75']);
    },
  );

  test(
    'a purchased update records ownership and clears the in-flight marker',
    () async {
      final repo = _FakeSponsorRepository(const Ok([_sub]));
      final controller = SponsorController(repo);
      await controller.load();
      await controller.buy(_sub);

      repo.emit(
        const SponsorPurchase(
          productId: 's_donation75',
          status: SponsorPurchaseStatus.pending,
        ),
      );
      await _settle();
      expect(controller.isBusy, isTrue);

      repo.emit(
        const SponsorPurchase(
          productId: 's_donation75',
          status: SponsorPurchaseStatus.purchased,
        ),
      );
      await _settle();

      expect(controller.purchasedIds, contains('s_donation75'));
      expect(controller.purchasingId, isNull);
    },
  );

  test('a canceled update just clears the in-flight marker', () async {
    final repo = _FakeSponsorRepository(const Ok([_sub]));
    final controller = SponsorController(repo);
    await controller.load();
    await controller.buy(_sub);

    repo.emit(
      const SponsorPurchase(
        productId: 's_donation75',
        status: SponsorPurchaseStatus.canceled,
      ),
    );
    await _settle();

    expect(controller.purchasingId, isNull);
    expect(controller.purchasedIds, isEmpty);
  });

  test('restore relays store availability', () async {
    final repo = _FakeSponsorRepository(const Ok([]))..restoreAvailable = false;
    final controller = SponsorController(repo);

    expect(await controller.restore(), isFalse);
  });
}
