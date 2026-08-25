/// The 伺服器狀態 page — Grafana server metrics on top, the client's own
/// reading of the multi-active endpoints ("本機狀態") below.
library;

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';
import 'package:dpip/features/status/domain/cloudflare_status_repository.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';
import 'package:dpip/features/status/presentation/pages/server_status_page.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  Widget wrap(
    ServerStatusRepository repo, {
    EndpointHealthMonitor? health,
    CloudflareStatusRepository? cloudflare,
  }) {
    final cloudflareRepo =
        cloudflare ?? _FakeCloudflareRepository(Ok(_okCloudflare()));
    return MultiProvider(
      providers: [
        Provider<ServerStatusRepository>.value(value: repo),
        Provider<CloudflareStatusRepository>.value(value: cloudflareRepo),
        ChangeNotifierProvider.value(value: health ?? EndpointHealthMonitor()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ServerStatusPage(),
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
    // Updated time appears on the ExpTech banner and each Cloudflare tile.
    expect(find.textContaining(l10n.serverStatusUpdated), findsNWidgets(3));
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
    // 去尾零：0.9 不再顯示為 0.90（三位數字上限的新格式）。
    expect(find.text('0.9%'), findsOneWidget);
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

  testWidgets('endpoint health block renders tier tables per api.md', (
    tester,
  ) async {
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

    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(repo, health: health));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusLocal), findsOneWidget);
    // All four fixed tables render (the user-facing categorisation).
    for (final label in [
      l10n.endpointTierLbApi,
      l10n.endpointTierLbStatic,
      l10n.endpointTierCoreApi,
      l10n.endpointTierCoreStatic,
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'table $label');
    }
    // EEW row: LB API (TPE1/KHH1) and Core API (TNN1).
    expect(find.text(l10n.endpointServiceEew), findsNWidgets(2));
    // Region columns are fixed: LB TPE1/KHH1; Core TYO1/TNN1/API-1.
    expect(find.text('TPE1'), findsNWidgets(2)); // LB API + LB Static headers
    expect(find.text('KHH1'), findsNWidgets(2)); // LB API + LB Static headers
    expect(find.text('TYO1'), findsNWidgets(2)); // Core API + Core Static
    expect(find.text('TNN1'), findsNWidgets(2)); // Core API + Core Static
    expect(find.text('API-1'), findsOneWidget); // Core API header
    // lb-khh1 doubled-failed → down summary.
    expect(find.text(l10n.endpointHealthDown), findsOneWidget);
  });

  testWidgets('cloudflare block shows the observed regions and their state', (
    tester,
  ) async {
    final repo = _FakeRepository(Ok(okStatus()));
    final cloudflare = _FakeCloudflareRepository(
      Ok(
        CloudflareStatus(
          recordedAt: DateTime.utc(2026, 8, 18, 3, 0),
          components: [
            CloudflareComponent(
              name: 'Taipei - (TPE)',
              state: CloudflareComponentState.operational,
              updatedAt: DateTime.utc(2026, 8, 18, 3, 0),
            ),
            CloudflareComponent(
              name: 'Kaohsiung City - (KHH)',
              state: CloudflareComponentState.degradedPerformance,
              updatedAt: DateTime.utc(2026, 8, 18, 3, 0),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(wrap(repo, cloudflare: cloudflare));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusExpTech), findsOneWidget);
    expect(find.text(l10n.serverStatusCloudflare), findsOneWidget);
    expect(find.text('Taipei - (TPE)'), findsOneWidget);
    expect(find.text('Kaohsiung City - (KHH)'), findsOneWidget);
    expect(find.text(l10n.serverStatusCloudflareAllOperational), findsNothing);
    expect(find.text(l10n.serverStatusCloudflareOutage), findsOneWidget);
  });

  testWidgets('empty endpoint health shows the no-observations tables', (
    tester,
  ) async {
    final repo = _FakeRepository(Ok(okStatus()));
    await tester.pumpWidget(wrap(repo));
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    expect(find.text(l10n.serverStatusLocal), findsOneWidget);
    // Four fixed tables still render; every cell is an honest em-dash.
    expect(find.text(l10n.endpointTierLbApi), findsOneWidget);
    expect(find.text(l10n.endpointHealthUnknown), findsOneWidget);
  });

  testWidgets('local status legend spells out the four cell states', (
    tester,
  ) async {
    final repo = _FakeRepository(Ok(okStatus()));
    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(repo));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);
    // The passive probe note sits above the tables.
    expect(find.text(l10n.serverStatusLocalBody), findsWidgets);
    // Legend carries all four states.
    expect(find.text(l10n.endpointStateOk), findsWidgets);
    expect(find.text(l10n.endpointStateDown), findsWidgets);
    expect(find.text(l10n.statusLegendUnprobed), findsOneWidget);
    expect(find.text(l10n.statusLegendUnsupported), findsOneWidget);
  });

  testWidgets('core static tyo1 column is unsupported, not unprobed', (
    tester,
  ) async {
    final repo = _FakeRepository(Ok(okStatus()));
    final health = EndpointHealthMonitor();
    health.success(
      ApiTier.lbApi,
      'https://api.lb-tpe1.exptech.dev',
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
    health.success(
      ApiTier.coreApi,
      'https://api.core-tnn1.exptech.dev',
      '/api/v2/eq/eew',
    );

    tester.view.physicalSize = const Size(800, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(repo, health: health));
    await tester.pumpAndSettle();

    final l10n = l10nOf(tester);

    // Icon-based cells: a healthy check and a down error are both present.
    expect(find.byIcon(Icons.check_circle), findsWidgets);
    expect(find.byIcon(Icons.error), findsWidgets);
    // The Core Static table's TYO1 column is entirely 不支援 — no static host
    // exists for tyo1, so not even the radar row shows a probe state.
    expect(find.byIcon(Icons.block), findsWidgets);
    // The unprobed question-marks outnumber everything: the LB API rows and
    // Core API rows for every service/region the probe did not touch.
    expect(find.byIcon(Icons.help_outline), findsWidgets);
    // Radar rows exist in both Core tables; TYO1's radar cell is 不支援.
    expect(find.text(l10n.endpointServiceRadar), findsNWidgets(2));
  });
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(Scaffold)));

CloudflareStatus _okCloudflare() {
  final now = DateTime.utc(2026, 8, 18, 3, 0);
  return CloudflareStatus(
    recordedAt: now,
    components: [
      CloudflareComponent(
        name: 'Taipei - (TPE)',
        state: CloudflareComponentState.operational,
        updatedAt: now,
      ),
      CloudflareComponent(
        name: 'Kaohsiung City - (KHH)',
        state: CloudflareComponentState.operational,
        updatedAt: now,
      ),
    ],
  );
}

class _FakeCloudflareRepository implements CloudflareStatusRepository {
  _FakeCloudflareRepository(this.result);

  Result<CloudflareStatus> result;

  @override
  Future<Result<CloudflareStatus>> status() async => result;
}

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
