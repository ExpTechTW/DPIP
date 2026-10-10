/// The sponsor page's user-visible half of an in-app purchase: catalogue state,
/// grouping, one purchase at a time, settlement, and restore feedback.
///
/// The store SDK stays behind [SponsorRepository]. That leaves one dangerous UI
/// failure: a purchase can start and never clear, permanently disabling every
/// other product. Tests therefore drive the same pending → settled stream the
/// store does, rather than only checking that a price rendered.
library;

import 'dart:async';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/sponsor/domain/sponsor_product.dart';
import 'package:dpip/features/sponsor/domain/sponsor_purchase.dart';
import 'package:dpip/features/sponsor/domain/sponsor_repository.dart';
import 'package:dpip/features/sponsor/presentation/pages/sponsor_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/error_view.dart';
import 'package:dpip/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _monthly = SponsorProduct(
  id: 'monthly',
  title: 'Monthly support',
  description: 'Keeps the service running',
  price: r'$2.99',
  rawPrice: 2.99,
  isSubscription: true,
);

const _coffee = SponsorProduct(
  id: 'coffee',
  title: 'Coffee',
  description: 'A one-time tip',
  price: r'$0.99',
  rawPrice: 0.99,
  isSubscription: false,
);

class _SponsorRepository implements SponsorRepository {
  final StreamController<SponsorPurchase> updates =
      StreamController<SponsorPurchase>.broadcast();
  Result<List<SponsorProduct>> next = const Ok([_monthly, _coffee]);
  bool buyStarted = true;
  bool restoreStarted = true;
  SponsorPurchase? restoredPurchase;
  int loads = 0;
  int restores = 0;
  final List<String> bought = [];

  @override
  Future<Result<List<SponsorProduct>>> products() async {
    loads++;
    return next;
  }

  @override
  Stream<SponsorPurchase> purchases() => updates.stream;

  @override
  Future<bool> buy(SponsorProduct product) async {
    bought.add(product.id);
    return buyStarted;
  }

  @override
  Future<bool> restore() async {
    restores++;
    final restored = restoredPurchase;
    if (restored != null) updates.add(restored);
    return restoreStarted;
  }

  @override
  void dispose() => updates.close();
}

Future<void> _pump(WidgetTester tester, _SponsorRepository repository) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(repository.dispose);

  await tester.pumpWidget(
    Provider<SponsorRepository>.value(
      value: repository,
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SponsorPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('store failure is an error with a working retry', (tester) async {
    final repository = _SponsorRepository()
      ..next = const Err(NetworkFailure('store unavailable'));
    await _pump(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(LoadingView), findsNothing);

    repository.next = const Ok([_coffee]);
    await tester.tap(find.widgetWithText(FilledButton, l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(find.text('Coffee'), findsOneWidget);
    expect(repository.loads, 2);
  });

  testWidgets('subscriptions and one-time tips stay in separate sections', (
    tester,
  ) async {
    final repository = _SponsorRepository();
    await _pump(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.sponsorSubscriptions), findsOneWidget);
    expect(find.text(l10n.sponsorOneTime), findsOneWidget);
    expect(find.text(l10n.sponsorRecommended), findsOneWidget);
    expect(find.text('Monthly support'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text(l10n.sponsorPerMonth(r'$2.99')), findsOneWidget);
    expect(find.text(r'$0.99'), findsOneWidget);
  });

  testWidgets('an active subscription replaces its price with a checkmark', (
    tester,
  ) async {
    final repository = _SponsorRepository()
      ..restoredPurchase = const SponsorPurchase(
        productId: 'monthly',
        status: SponsorPurchaseStatus.restored,
      );
    await _pump(tester, repository);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(repository.restores, 1);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text(l10n.sponsorPerMonth(r'$2.99')), findsNothing);

    await tester.tap(find.text('Monthly support'));
    await tester.pump();
    expect(repository.bought, isEmpty);
  });

  testWidgets('a purchase disables its siblings until it settles', (
    tester,
  ) async {
    final repository = _SponsorRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Monthly support'));
    await tester.pump();

    expect(repository.bought, ['monthly']);
    expect(find.byType(InlineLoading), findsOneWidget);

    // The coffee row is visible, but a second tap while a purchase is in flight
    // must not launch another store sheet.
    await tester.tap(find.text('Coffee'));
    await tester.pump();
    expect(repository.bought, ['monthly']);

    repository.updates.add(
      const SponsorPurchase(
        productId: 'monthly',
        status: SponsorPurchaseStatus.purchased,
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byType(InlineLoading), findsNothing);
  });

  testWidgets('a completed one-time tip remains available to buy again', (
    tester,
  ) async {
    final repository = _SponsorRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Coffee'));
    await tester.pump();
    repository.updates.add(
      const SponsorPurchase(
        productId: 'coffee',
        status: SponsorPurchaseStatus.purchased,
      ),
    );
    await tester.pump();

    expect(find.byType(InlineLoading), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text(r'$0.99'), findsOneWidget);

    await tester.tap(find.text('Coffee'));
    await tester.pump();
    expect(repository.bought, ['coffee', 'coffee']);
  });

  testWidgets('a store that refuses to start clears the busy state', (
    tester,
  ) async {
    final repository = _SponsorRepository()..buyStarted = false;
    await _pump(tester, repository);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text('Monthly support'));
    await tester.pumpAndSettle();

    expect(repository.bought, ['monthly']);
    expect(find.byType(InlineLoading), findsNothing);
    expect(find.text(l10n.sponsorPerMonth(r'$2.99')), findsOneWidget);
  });

  testWidgets('an error settlement clears the spinner without marking owned', (
    tester,
  ) async {
    final repository = _SponsorRepository();
    await _pump(tester, repository);

    await tester.tap(find.text('Coffee'));
    await tester.pump();
    repository.updates.add(
      const SponsorPurchase(
        productId: 'coffee',
        status: SponsorPurchaseStatus.error,
      ),
    );
    await tester.pump();

    expect(find.byType(InlineLoading), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.text(r'$0.99'), findsOneWidget);
  });

  testWidgets('restore says whether the store accepted the request', (
    tester,
  ) async {
    final repository = _SponsorRepository()..restoreStarted = false;
    await _pump(tester, repository);
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.text(l10n.sponsorRestore));
    await tester.pumpAndSettle();
    expect(find.text(l10n.sponsorRestoreUnavailable), findsOneWidget);

    // Let the first snackbar leave; a new snackbar is queued behind an active
    // one, so asserting immediately would test ScaffoldMessenger timing rather
    // than restore feedback.
    await tester.pump(const Duration(seconds: 5));
    repository.restoreStarted = true;
    await tester.tap(find.text(l10n.sponsorRestore));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(l10n.sponsorRestoring), findsOneWidget);
  });
}
