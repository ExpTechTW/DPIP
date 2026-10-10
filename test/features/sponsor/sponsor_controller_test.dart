import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:dpip/features/sponsor/presentation/sponsor_controller.dart';
import 'package:flutter/widgets.dart';
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
  bool buyStarts = true;
  bool restoreAvailable = true;
  int restores = 0;
  Object? buyThrow;
  Completer<bool>? buyGate;
  final List<String> bought = [];
  final StreamController<SponsorPurchase> _updates =
      StreamController<SponsorPurchase>.broadcast();

  void emit(SponsorPurchase purchase) => _updates.add(purchase);

  @override
  Future<Result<List<SponsorProduct>>> products() async => result;

  @override
  Stream<SponsorPurchase> purchases() => _updates.stream;

  @override
  Future<bool> buy(SponsorProduct product) {
    bought.add(product.id);
    final gate = buyGate;
    if (gate != null) return gate.future;
    final error = buyThrow;
    if (error != null) return Future<bool>.error(error);
    return Future<bool>.value(buyStarts);
  }

  @override
  Future<bool> restore() async {
    restores++;
    return restoreAvailable;
  }

  @override
  void dispose() => _updates.close();
}

/// Lets the broadcast stream deliver a queued event to the controller.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('load splits products into subscriptions and one-time, ready', () async {
    final repo = _FakeSponsorRepository(const Ok([_sub, _oneTime]));
    final controller = SponsorController(repo);

    await controller.load();

    expect(controller.status, SponsorStatus.ready);
    expect(controller.subscriptions.map((p) => p.id), ['s_donation75']);
    expect(controller.oneTime.map((p) => p.id), ['donation100']);
    expect(repo.restores, 1);
  });

  test('load only restores active subscriptions once', () async {
    final repo = _FakeSponsorRepository(const Ok([_sub]));
    final controller = SponsorController(repo);

    await controller.load();
    repo.emit(
      const SponsorPurchase(
        productId: 's_donation75',
        status: SponsorPurchaseStatus.restored,
      ),
    );
    await _settle();
    await controller.load();

    expect(repo.restores, 1);
    expect(controller.purchasedIds, contains('s_donation75'));
    controller.dispose();
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

  test('a purchased subscription records ownership and clears the in-flight marker', () async {
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
  });

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
    controller.dispose();
  });

  test('a second buy and an already-owned subscription are ignored', () async {
    final repo = _FakeSponsorRepository(const Ok([_sub, _oneTime]))
      ..buyGate = Completer<bool>();
    final controller = SponsorController(repo);
    await controller.load();

    final first = controller.buy(_sub);
    await controller.buy(_oneTime);
    expect(repo.bought, ['s_donation75']);

    repo.buyGate!.complete(false);
    await first;
    expect(controller.purchasingId, isNull);

    controller.purchasedIds.add(_sub.id);
    await controller.buy(_sub);
    expect(repo.bought, ['s_donation75']);
    controller.dispose();
  });

  test('a store error clears the in-flight marker', () async {
    final repo = _FakeSponsorRepository(const Ok([_sub]))
      ..buyThrow = StateError('store');
    final controller = SponsorController(repo);
    await controller.load();
    FlutterErrorDetails? reported;
    final previous = FlutterError.onError;
    FlutterError.onError = (details) => reported = details;
    try {
      await controller.buy(_sub);
    } finally {
      FlutterError.onError = previous;
    }
    expect(reported?.exception, isA<StateError>());
    expect(controller.purchasingId, isNull);
    controller.dispose();
  });

  testWidgets(
    'the launch watchdog and a resume both give up on a stuck purchase',
    (tester) async {
      final repo = _FakeSponsorRepository(const Ok([_sub]));
      final controller = SponsorController(repo);
      await controller.load();
      controller.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await controller.buy(_sub);
      expect(controller.purchasingId, 's_donation75');

      await tester.pump(const Duration(seconds: 8));
      expect(controller.purchasingId, isNull);

      await controller.buy(_sub);
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.purchasingId, isNull);
      controller.dispose();
    },
  );

  test(
    'a subscription purchase that arrives separately still notifies',
    () async {
      final repo = _FakeSponsorRepository(const Ok([_sub, _oneTime]));
      final controller = SponsorController(repo);
      await controller.load();
      var notices = 0;
      controller.addListener(() => notices++);
      repo.emit(
        const SponsorPurchase(
          productId: 's_donation75',
          status: SponsorPurchaseStatus.purchased,
        ),
      );
      await _settle();
      expect(controller.purchasedIds, contains('s_donation75'));
      expect(notices, greaterThan(0));
      controller.dispose();
    },
  );
}
