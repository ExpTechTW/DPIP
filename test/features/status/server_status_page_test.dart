/// The 伺服器狀態 page — Grafana server metrics on top, the client's own
/// reading of the multi-active endpoints ("本機狀態") below.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';
import 'package:dpip/features/status/presentation/pages/server_status_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget wrap(ServerStatusRepository repo, {EndpointHealthMonitor? health}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: health ?? EndpointHealthMonitor()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ServerStatusPage(repository: repo),
      ),
    );
  }

  ServerStatus okStatus({double errorRate = 0.02, double latency = 12}) =>
      ServerStatus(
        recordedAt: DateTime.utc(2026, 8, 1, 12, 30),
        down: const StatusMetric(value: 0),
        errorRate: StatusMetric(value: errorRate, instance: 'lb-tpe1'),
        latency: StatusMetric(value: latency, instance: 'lb-tnn1'),
      );

  testWidgets('an ok dashboard shows the three metrics and a healthy banner', (
    tester,
  ) async {
    final repo = _FakeRepository(Ok(okStatus()));
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusAllUp), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('0.02%'), findsOneWidget);
    expect(find.text('12ms'), findsOneWidget);
    // The instance labels render under the values.
    expect(find.text('lb-tpe1'), findsOneWidget);
    expect(find.text('lb-tnn1'), findsOneWidget);
    // Updated time is the localised 12:30.
    expect(find.textContaining(l10n.serverStatusUpdated), findsOneWidget);
  });

  testWidgets('a down node shows the error banner', (tester) async {
    final status = ServerStatus(
      recordedAt: DateTime.utc(2026, 8, 1, 12, 30),
      down: const StatusMetric(value: 2),
      errorRate: const StatusMetric(value: 0.9, instance: 'lb-tpe1'),
      latency: const StatusMetric(value: 800, instance: 'lb-tnn1'),
    );
    final repo = _FakeRepository(Ok(status));
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusDown), findsWidgets);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('0.90%'), findsOneWidget);
    expect(find.text('800ms'), findsOneWidget);
  });

  testWidgets('a failure shows the retry surface, and retry re-runs the repo', (
    tester,
  ) async {
    var calls = 0;
    final repo = _FakeRepository(
      Err(const NetworkFailure('no connection')),
      onStatus: () => calls++,
    );
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.commonFetchFailed), findsOneWidget);
    // Failed repo → error view, not a blank screen.
    expect(find.text('0'), findsNothing);

    // Retry (still failing) re-invokes the repository.
    repo.next = Ok(okStatus());
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text(l10n.serverStatusAllUp), findsOneWidget);
  });

  testWidgets('endpoint health block renders four tier tables', (tester) async {
    final repo = _FakeRepository(Ok(okStatus()));
    final health = EndpointHealthMonitor();
    health.success(
      ApiTier.lbApi,
      'https://api.lb-tpe1.exptech.dev',
      '/api/v2/eq/eew',
    );
    health.success(
      ApiTier.coreApi,
      'https://api.core-tnn1.exptech.dev',
      '/api/v2/eq/eew',
    );
    health.failure(
      ApiTier.lbApi,
      'https://api.lb-khh1.exptech.dev',
      '/api/v2/eq/eew',
    );
    health.failure(
      ApiTier.lbApi,
      'https://api.lb-khh1.exptech.dev',
      '/api/v2/eq/eew',
    );

    await tester.pumpWidget(wrap(repo, health: health));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusLocal), findsOneWidget);
    // Four tier titles, each a table header.
    for (final label in [
      l10n.endpointTierLbApi,
      l10n.endpointTierLbStatic,
      l10n.endpointTierCoreApi,
      l10n.endpointTierCoreStatic,
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'table $label');
    }
    // Service rows appear in all four tables.
    expect(find.text(l10n.endpointServiceEew), findsNWidgets(4));
    // Region codes head the columns: LB tables share TPE1/KHH1, Core share
    // TYO1/TNN1. Each also appears once as a chip where EEW was observed.
    expect(find.text('TPE1'), findsNWidgets(3)); // 2 headers + 1 chip
    expect(find.text('KHH1'), findsNWidgets(3)); // 2 headers + 1 chip
    expect(find.text('TYO1'), findsNWidgets(2)); // 2 headers, unobserved
    expect(find.text('TNN1'), findsNWidgets(3)); // 2 headers + 1 chip
    // lb-khh1 doubled-failed → down summary.
    expect(find.text(l10n.endpointHealthDown), findsOneWidget);
  });

  testWidgets('empty endpoint health shows the no-observations placeholder', (
    tester,
  ) async {
    final repo = _FakeRepository(Ok(okStatus()));
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusLocal), findsOneWidget);
    expect(find.text(l10n.endpointHealthUnknown), findsOneWidget);
    expect(find.text(l10n.endpointHealthNone), findsOneWidget);
  });
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold)));

class _FakeRepository implements ServerStatusRepository {
  _FakeRepository(this.result, {this.onStatus});

  Result<ServerStatus> result;
  final void Function()? onStatus;

  set next(Result<ServerStatus> value) => result = value;

  @override
  Future<Result<ServerStatus>> status() async {
    onStatus?.call();
    return result;
  }
}
