/// 伺服器狀態 — the live ExpTech dashboard plus what local health the app can
/// see from here.
///
/// Top block: a full-width link out to the web dashboard, then three Grafana
/// metrics fetched through the app's Dio stack, so the ETag store caches the
/// same constant query and a revisit without network can still show the last
/// good snapshot. Bottom block: the client's own reading of the multi-active
/// endpoints — which service × region actually answers — fed by [ApiClient] as
/// requests succeed or fail over.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/network/api_region.dart';
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/features/status/data/server_status_api.dart';
import 'package:dpip/features/status/data/server_status_repository_impl.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ServerStatusPage extends StatelessWidget {
  const ServerStatusPage({super.key, this.repository});

  /// Injectable for tests; defaults to the live Grafana-backed implementation.
  final ServerStatusRepository? repository;

  /// The web dashboard the status card used to jump to.
  static const String _webUrl = 'https://status.exptech.dev/status';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo =
        repository ??
        ServerStatusRepositoryImpl(ServerStatusApi(context.read<ApiClient>()));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreServerStatus)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          // The old jump target, kept as a full-width entry at the top: the
          // in-app snapshot is a summary, the web page has the history.
          _WebDashboardCard(url: _webUrl),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.serverStatusBody,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AsyncView<ServerStatus>(
            future: repo.status,
            builder: (context, status) => _StatusGrid(status: status),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.serverStatusLocal,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.serverStatusLocalBody,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // The client's own reading of the multi-active endpoints, fed by
          // ApiClient as requests succeed or fail over.
          const _ClientEndpoints(),
        ],
      ),
    );
  }
}

/// Full-width entry to the web status dashboard — the "old jump button".
class _WebDashboardCard extends StatelessWidget {
  const _WebDashboardCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Material(
      color: colors.secondaryContainer,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.secondary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.open_in_browser_outlined,
                  color: colors.onSecondaryContainer,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.serverStatusWeb,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                    Text(
                      l10n.serverStatusWebUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: colors.onSecondaryContainer.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = AppLocalizations.of(context).moreLinkOpenFailed;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw Exception('launchUrl returned false for $url');
    } catch (error, stackTrace) {
      Log.handle(error, stackTrace, 'open external link $url');
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}

/// Renders [EndpointHealthMonitor] as four tables — one per concrete tier,
/// two fixed region columns each, cells showing which services ran on that
/// region. This is the "本機狀態" block: server metrics come from Grafana, but
/// whether *this* client can actually reach each service × region is a question
/// only the client can answer.
class _ClientEndpoints extends StatelessWidget {
  const _ClientEndpoints();

  /// The four tables, each a tier + its two fixed regions.
  static const _tables = [
    (tier: ApiTier.lbApi, regions: ['TPE1', 'KHH1']),
    (tier: ApiTier.lbStatic, regions: ['TPE1', 'KHH1']),
    (tier: ApiTier.coreApi, regions: ['TYO1', 'TNN1']),
    (tier: ApiTier.coreStatic, regions: ['TYO1', 'TNN1']),
  ];

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<EndpointHealthMonitor>();
    final entries = monitor.entries;
    final summary = monitor.summary;
    final colors = context.colorScheme;

    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SummaryBanner(summary: summary),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: AppRadius.medium,
            ),
            child: Text(
              context.l10n.endpointHealthNone,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      );
    }

    // Rows: services in first-seen order.
    final services = <EndpointService>[];
    for (final h in entries) {
      if (!services.contains(h.service)) services.add(h.service);
    }

    // Cell content: service × tier × region → health.
    final cell = <(EndpointService, ApiTier, String), EndpointHealth>{};
    for (final h in entries) {
      cell[(h.service, h.tier, h.regionCode)] = h;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryBanner(summary: summary),
        const SizedBox(height: AppSpacing.md),
        for (final t in _tables) ...[
          _ServiceTable(
            title: _tierShortLabel(context, t.tier),
            services: services,
            tier: t.tier,
            regions: t.regions,
            cell: cell,
          ),
          if (t != _tables.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  String _tierShortLabel(BuildContext context, ApiTier tier) {
    final l10n = context.l10n;
    return switch (tier) {
      ApiTier.lbApi => l10n.endpointTierLbApi,
      ApiTier.lbStatic => l10n.endpointTierLbStatic,
      ApiTier.coreApi => l10n.endpointTierCoreApi,
      ApiTier.coreStatic => l10n.endpointTierCoreStatic,
      ApiTier.coreExclusiveApi => l10n.endpointTierCoreExclusiveApi,
      ApiTier.coreStaticExclusive => l10n.endpointTierCoreStaticExclusive,
      ApiTier.legacyApi => l10n.endpointTierLegacyApi,
    };
  }
}

class _ServiceTable extends StatelessWidget {
  const _ServiceTable({
    required this.title,
    required this.services,
    required this.tier,
    required this.regions,
    required this.cell,
  });

  final String title;
  final List<EndpointService> services;
  final ApiTier tier;
  final List<String> regions;
  final Map<(EndpointService, ApiTier, String), EndpointHealth> cell;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // Header + services rows + tier footer.
    final rows = <List<Widget>>[];

    // Header row: corner cell + region names.
    rows.add([
      _corner(context),
      for (final r in regions) _headerCell(context, r),
    ]);

    for (final s in services) {
      rows.add([
        _serviceCell(context, s),
        for (final r in regions) _regionCell(context, s, r),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: AppRadius.medium,
          ),
          child: Column(
            children: [
              for (final row in rows)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < row.length; i++)
                      Expanded(child: row[i]),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _corner(BuildContext context) => const SizedBox(height: 8);

  Widget _headerCell(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _serviceCell(BuildContext context, EndpointService s) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xs,
      vertical: AppSpacing.sm,
    ),
    child: Text(
      _serviceLabel(context, s),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  /// One service × region cell: a status chip for that host, or an em-dash
  /// when the service was never seen on this tier × region.
  Widget _regionCell(BuildContext context, EndpointService s, String region) {
    final h = cell[(s, tier, region)];
    if (h == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Text(
          '—',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: _RegionChip(region: h.regionCode, state: h.state, host: h.host),
    );
  }

  String _serviceLabel(BuildContext context, EndpointService s) {
    final l10n = context.l10n;
    return switch (s) {
      EndpointService.eew => l10n.endpointServiceEew,
      EndpointService.rts => l10n.endpointServiceRts,
      EndpointService.radar => l10n.endpointServiceRadar,
      EndpointService.satellite => l10n.endpointServiceSatellite,
      EndpointService.qpesums => l10n.endpointServiceQpesums,
      EndpointService.wind => l10n.endpointServiceWind,
      EndpointService.dpm => l10n.endpointServiceDpm,
      EndpointService.weather => l10n.endpointServiceWeather,
      EndpointService.rain => l10n.endpointServiceRain,
      EndpointService.lightning => l10n.endpointServiceLightning,
      EndpointService.typhoon => l10n.endpointServiceTyphoon,
      EndpointService.report => l10n.endpointServiceReport,
      EndpointService.tremStation => l10n.endpointServiceTremStation,
      EndpointService.event => l10n.endpointServiceEvent,
      EndpointService.location => l10n.endpointServiceLocation,
      EndpointService.notify => l10n.endpointServiceNotify,
      EndpointService.other => l10n.endpointServiceOther,
    };
  }
}

/// One region chip inside a service × tier cell: the region code (`TPE1`,
/// `KHH1`…), coloured by the host's state.
class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.region,
    required this.state,
    required this.host,
  });

  final String region;
  final EndpointState state;
  final String host;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _stateColor(context, state);
    return Tooltip(
      message: '$host\n$label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: color.withValues(alpha: 0.14),
        ),
        child: Text(
          region,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

(Color, String) _stateColor(BuildContext context, EndpointState state) {
  final colors = Theme.of(context).colorScheme;
  return switch (state) {
    EndpointState.down => (colors.error, context.l10n.endpointStateDown),
    EndpointState.degraded => (
      colors.tertiary,
      context.l10n.endpointStateDegraded,
    ),
    EndpointState.healthy => (colors.primary, context.l10n.endpointStateOk),
    EndpointState.unknown => (
      colors.outline,
      context.l10n.endpointStateUnknown,
    ),
  };
}

extension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _SummaryBanner extends StatelessWidget {
  const _SummaryBanner({required this.summary});

  final EndpointState summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colorScheme;
    final (color, fg, label, icon) = switch (summary) {
      EndpointState.down => (
        colors.errorContainer,
        colors.onErrorContainer,
        l10n.endpointHealthDown,
        Icons.error_outline,
      ),
      EndpointState.degraded => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        l10n.endpointHealthDegraded,
        Icons.warning_amber_outlined,
      ),
      EndpointState.healthy => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        l10n.endpointHealthOk,
        Icons.check_circle_outline,
      ),
      EndpointState.unknown => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
        l10n.endpointHealthUnknown,
        Icons.help_outline,
      ),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.medium),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusGrid extends StatelessWidget {
  const _StatusGrid({required this.status});

  final ServerStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _healthBanner(context),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                context,
                title: l10n.serverStatusDown,
                value: '${status.down.value}',
                subtitle: _maybeInstance(status.down.instance),
                color: status.allUp
                    ? context.colorScheme.primary
                    : context.colorScheme.error,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _metricCard(
                context,
                title: l10n.serverStatusErrorRate,
                value: '${status.errorRate.value.toStringAsFixed(2)}%',
                subtitle: _maybeInstance(status.errorRate.instance),
                color: _threeTone(context, status.errorRate.value, 0.1, 0.3),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _metricCard(
                context,
                title: l10n.serverStatusLatency,
                value: '${status.latency.value.toStringAsFixed(0)}ms',
                subtitle: _maybeInstance(status.latency.instance),
                color: _threeTone(context, status.latency.value, 10, 50),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _maybeInstance(String? instance) =>
      (instance?.isEmpty ?? true) ? '—' : instance!;

  Widget _healthBanner(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colorScheme;
    final (color, fg, label, icon) = switch (status.health) {
      StatusHealth.ok => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        l10n.serverStatusAllUp,
        Icons.check_circle_outline,
      ),
      StatusHealth.degraded => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
        l10n.serverStatusDegraded,
        Icons.warning_amber_outlined,
      ),
      StatusHealth.down => (
        colors.errorContainer,
        colors.onErrorContainer,
        l10n.serverStatusDown,
        Icons.error_outline,
      ),
    };
    final t = status.recordedAt.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.medium),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: fg, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            '${l10n.serverStatusUpdated} $hh:$mm',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    final colors = context.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

extension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => theme.colorScheme;
}

Color _threeTone(BuildContext context, num value, double warn, double bad) {
  final colors = context.colorScheme;
  if (value >= bad) return colors.error;
  if (value >= warn) return colors.tertiary;
  return colors.primary;
}
