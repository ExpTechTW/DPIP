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
import 'package:dpip/core/network/endpoint_health.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';
import 'package:dpip/features/status/domain/cloudflare_status_repository.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';
import 'package:dpip/shared/widgets/async_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ServerStatusPage extends StatelessWidget {
  const ServerStatusPage({
    super.key,
    this.repository,
    this.cloudflareRepository,
  });

  /// Injectable for tests; defaults to the provider-registered implementation.
  final ServerStatusRepository? repository;

  /// Injectable for tests; defaults to the provider-registered implementation.
  final CloudflareStatusRepository? cloudflareRepository;

  /// The web dashboard the status card used to jump to.
  static const String _webUrl = 'https://status.exptech.dev/status';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = repository ?? context.read<ServerStatusRepository>();
    final cloudflareRepo =
        cloudflareRepository ?? context.read<CloudflareStatusRepository>();
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
          const SizedBox(height: AppSpacing.xl),

          // ── ExpTech Status ──────────────────────────────────────────────
          _SectionHeader(title: l10n.serverStatusExpTech),
          const SizedBox(height: AppSpacing.sm),
          AsyncView<ServerStatus>(
            future: repo.status,
            builder: (context, status) => _StatusGrid(status: status),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Cloudflare Status ───────────────────────────────────────────
          // The CDN every ExpTech host sits behind.
          _SectionHeader(title: l10n.serverStatusCloudflare),
          const SizedBox(height: AppSpacing.sm),
          AsyncView<CloudflareStatus>(
            future: cloudflareRepo.status,
            builder: (context, status) => _CloudflareGrid(status: status),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── 本機狀態 ────────────────────────────────────────────────────
          _SectionHeader(title: l10n.serverStatusLocal),
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

/// A small section header used to separate the status sources on the page.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
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

/// Renders [EndpointHealthMonitor] as four fixed tables — LB API / LB Static
/// / Core API / Core Static — one per user-facing category (as named in the
/// More → 伺服器狀態 screen). This is the "本機狀態" block: server metrics come
/// from Grafana, but whether *this* client can actually reach each service ×
/// region is a question only the client can answer.
///
/// Each table lists **all** the services and region columns its category can
/// ever carry (per api.md and who actually calls what). The probe is passive —
/// a cell shows that host's icon only when a request has actually touched it;
/// an untouched cell is an em-dash, not a hidden row.
///
/// The four categories are judged by host name: an `api.*` host is API, a
/// `static.*` host is Static; LB is the `lb-*` family, Core is the `core-*`
/// family plus the legacy `api-1` host. Exclusive TNN1 tiers land in the same
/// group as their sibling (`api.core-tnn1` → Core API, `static.core-tnn1` →
/// Core Static).
class _ClientEndpoints extends StatelessWidget {
  const _ClientEndpoints();

  /// The four fixed tables. `services` and `regions` are the full set the
  /// category can carry; `supported` is the api.md truth — which region serves
  /// which service. A supported-but-unprobed cell shows 未探測, an unsupported
  /// one shows 不支援 instead of pretending there is a host there to try.
  static const _groups = [
    _Group(
      titleKey: 'endpointTierLbApi',
      isStatic: false,
      isCore: false,
      regions: ['TPE1', 'KHH1'],
      services: [EndpointService.eew, EndpointService.rts],
      supported: {
        'TPE1': [EndpointService.eew, EndpointService.rts],
        'KHH1': [EndpointService.eew, EndpointService.rts],
      },
    ),
    _Group(
      titleKey: 'endpointTierLbStatic',
      isStatic: true,
      isCore: false,
      regions: ['TPE1', 'KHH1'],
      // Basemap/terrain tiles are fetched straight by MapLibre, never through
      // ApiClient, so these cells stay 未探測 — there is a host, the probe
      // just never goes through the client.
      services: [EndpointService.other],
      supported: {
        'TPE1': [EndpointService.other],
        'KHH1': [EndpointService.other],
      },
    ),
    _Group(
      titleKey: 'endpointTierCoreApi',
      isStatic: false,
      isCore: true,
      regions: ['TYO1', 'TNN1', 'API-1'],
      services: [
        // Historical replay + reports are multi-active across tyo1/tnn1; the
        // meteor family, location, notify and the TNN1-exclusive list endpoints
        // only answer on api.core-tnn1; trem-station/events/RTS history only
        // on the legacy api-1 host.
        EndpointService.eew,
        EndpointService.report,
        EndpointService.radar,
        EndpointService.satellite,
        EndpointService.qpesums,
        EndpointService.wind,
        EndpointService.weather,
        EndpointService.rain,
        EndpointService.lightning,
        EndpointService.typhoon,
        EndpointService.location,
        EndpointService.notify,
        EndpointService.tremStation,
        EndpointService.event,
        EndpointService.rts,
      ],
      supported: {
        'TYO1': [EndpointService.eew, EndpointService.report],
        // The exclusive api.core-tnn1 family (meteor, tiles lists, location,
        // notify) has no tyo1 sibling.
        'TNN1': [
          EndpointService.eew,
          EndpointService.report,
          EndpointService.radar,
          EndpointService.satellite,
          EndpointService.qpesums,
          EndpointService.wind,
          EndpointService.weather,
          EndpointService.rain,
          EndpointService.lightning,
          EndpointService.typhoon,
          EndpointService.location,
          EndpointService.notify,
        ],
        // The legacy api-1 host only carries the old strong-motion/event/history
        // endpoints.
        'API-1': [
          EndpointService.tremStation,
          EndpointService.event,
          EndpointService.rts,
        ],
      },
    ),
    _Group(
      titleKey: 'endpointTierCoreStatic',
      isStatic: true,
      isCore: true,
      regions: ['TYO1', 'TNN1'],
      services: [
        // Tile/static-snapshot side of each family.
        EndpointService.radar,
        EndpointService.satellite,
        EndpointService.qpesums,
        EndpointService.wind,
        EndpointService.dpm,
        EndpointService.weather,
        EndpointService.rain,
        EndpointService.lightning,
        EndpointService.typhoon,
      ],
      // api.md: every static host is core-tnn1. TYO1 has no static side at all,
      // so its whole column is 不支援 rather than an em-dash that implies a
      // host we simply have not probed yet.
      supported: {
        'TNN1': [
          EndpointService.radar,
          EndpointService.satellite,
          EndpointService.qpesums,
          EndpointService.wind,
          EndpointService.dpm,
          EndpointService.weather,
          EndpointService.rain,
          EndpointService.lightning,
          EndpointService.typhoon,
        ],
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final monitor = context.watch<EndpointHealthMonitor>();
    final entries = monitor.entries;
    final summary = monitor.summary;

    // Group the observations by the four fixed categories. A group with no
    // hits is still rendered — its cells are all em-dashes.
    final groupContents = <_Group, List<EndpointHealth>>{};
    for (final h in entries) {
      for (final g in _groups) {
        if (g.matches(h)) {
          groupContents.putIfAbsent(g, () => []).add(h);
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SummaryBanner(summary: summary),
        const SizedBox(height: AppSpacing.md),
        _Legend(),
        const SizedBox(height: AppSpacing.md),
        for (final g in _groups) ...[
          _ServiceTable(
            title: g.title(context),
            group: g,
            hits: groupContents[g] ?? const [],
          ),
          if (g != _groups.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// Legend explaining the four icon states a cell can carry.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = [
      (
        Icons.check_circle,
        Theme.of(context).colorScheme.primary,
        l10n.endpointStateOk,
      ),
      (
        Icons.error,
        Theme.of(context).colorScheme.error,
        l10n.endpointStateDown,
      ),
      (
        Icons.help_outline,
        Theme.of(context).colorScheme.outline,
        l10n.statusLegendUnprobed,
      ),
      (
        Icons.block,
        Theme.of(context).colorScheme.outlineVariant,
        l10n.statusLegendUnsupported,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          for (final (icon, color, label) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One of the four fixed tables: LB API / LB Static / Core API / Core Static.
class _Group {
  const _Group({
    required this.titleKey,
    required this.isStatic,
    required this.isCore,
    required this.regions,
    required this.services,
    required this.supported,
  });

  final String titleKey;

  /// Whether this group serves static assets (`static.*` hosts).
  final bool isStatic;

  /// Whether this group is the Core family (or its legacy `api-1` member).
  final bool isCore;

  /// The region columns this table always shows.
  final List<String> regions;

  /// Every service this category can carry, in display order.
  final List<EndpointService> services;

  /// Which region serves which service — the api.md support matrix. A key
  /// missing from [supported] means that region does not carry that service.
  final Map<String, List<EndpointService>> supported;

  /// Whether [region] actually runs [service] on this tier family.
  bool supports(EndpointService service, String region) =>
      supported[region]?.contains(service) ?? false;

  /// Whether [h] belongs in this group, judged by its host.
  bool matches(EndpointHealth h) {
    final host = h.host.toLowerCase();
    // The legacy host carries no lb/core/static marker in its name — it is
    // Core's API machine by definition (user-facing categorisation).
    if (host.startsWith('api-1.')) return isCore && !isStatic;
    final isStaticHost = host.startsWith('static.');
    if (isStaticHost != isStatic) return false;
    final isCoreHost = host.contains('.core-');
    return isCoreHost == isCore;
  }

  String title(BuildContext context) {
    final l10n = context.l10n;
    return switch (titleKey) {
      'endpointTierLbApi' => l10n.endpointTierLbApi,
      'endpointTierLbStatic' => l10n.endpointTierLbStatic,
      'endpointTierCoreApi' => l10n.endpointTierCoreApi,
      'endpointTierCoreStatic' => l10n.endpointTierCoreStatic,
      'endpointTierCoreExclusiveApi' => l10n.endpointTierCoreExclusiveApi,
      'endpointTierCoreStaticExclusive' => l10n.endpointTierCoreStaticExclusive,
      'endpointTierLegacyApi' => l10n.endpointTierLegacyApi,
      _ => titleKey,
    };
  }
}

class _ServiceTable extends StatelessWidget {
  const _ServiceTable({
    required this.title,
    required this.group,
    required this.hits,
  });

  final String title;

  /// The fixed category this table renders; [group.services] and
  /// [group.regions] are the full row/column set.
  final _Group group;

  /// The observed hosts that belong to this table (may be empty).
  final List<EndpointHealth> hits;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Cell content: service × region → health (first hit seen wins). A cell
    // with no hit is rendered as an em-dash, the honest "probe never touched
    // this combination" answer.
    final cell = <(EndpointService, String), EndpointHealth>{};
    for (final h in hits) {
      cell.putIfAbsent((h.service, h.regionCode), () => h);
    }

    final rows = <List<Widget>>[];

    // Header row: corner cell + region names.
    rows.add([
      _corner(context),
      for (final r in group.regions) _headerCell(context, r),
    ]);

    // A cell with no hit is one of two honest answers depending on whether the
    // region actually serves this service: 未探測 when it should (a host exists
    // the probe simply has not touched), 不支援 when it should not (api.md says
    // the region has no such host at all — e.g. every TYO1 static cell).
    for (final s in group.services) {
      rows.add([
        _serviceCell(context, s),
        for (final r in group.regions)
          group.supports(s, r)
              ? _probeCell(context, cell[(s, r)])
              : _unsupportedCell(context),
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

  /// One service × region cell: a status icon for that host, or a question-mark
  /// icon when the probe never touched this combination.
  Widget _probeCell(BuildContext context, EndpointHealth? h) {
    if (h == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Icon(
          Icons.help_outline,
          size: 16,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: _RegionChip(region: h.regionCode, state: h.state, host: h.host),
    );
  }

  /// A cell for a service × region combination api.md says the region cannot
  /// carry (e.g. every TYO1 static cell) — a blocked icon that stays visually
  /// distinct from 未探測's question mark.
  Widget _unsupportedCell(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Icon(
      Icons.block,
      size: 16,
      color: Theme.of(context).colorScheme.outlineVariant,
    ),
  );

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

/// One status cell inside a service × tier table: the state as an icon —
/// check for healthy, warning for a blip, error for down, question for
/// never-touched — coloured by the host's state.
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
    final icon = switch (state) {
      EndpointState.healthy => Icons.check_circle,
      EndpointState.degraded => Icons.warning_amber_rounded,
      EndpointState.down => Icons.error,
      EndpointState.unknown => Icons.help_outline,
    };
    return Tooltip(
      message: '$region · $host\n$label',
      child: SizedBox(height: 24, child: Icon(icon, size: 18, color: color)),
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

/// The Cloudflare Status block: one card per observed Taipei / Kaohsiung
/// component, each with its state as an icon and a coloured banner.
class _CloudflareGrid extends StatelessWidget {
  const _CloudflareGrid({required this.status});

  final CloudflareStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colorScheme;
    final (
      bannerColor,
      bannerFg,
      bannerLabel,
      bannerIcon,
    ) = switch (status.allOperational) {
      true => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        l10n.serverStatusCloudflareAllOperational,
        Icons.check_circle_outline,
      ),
      false => (
        colors.errorContainer,
        colors.onErrorContainer,
        l10n.serverStatusCloudflareOutage,
        Icons.error_outline,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: AppRadius.medium,
          ),
          child: Row(
            children: [
              Icon(bannerIcon, color: bannerFg, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                bannerLabel,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: bannerFg, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (status.components.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: AppRadius.medium,
            ),
            child: Text(
              l10n.serverStatusCloudflareNone,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          )
        else
          for (final component in status.components) ...[
            _CloudflareTile(component: component),
            if (component != status.components.last)
              const SizedBox(height: AppSpacing.xs),
          ],
      ],
    );
  }
}

class _CloudflareTile extends StatelessWidget {
  const _CloudflareTile({required this.component});

  final CloudflareComponent component;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colorScheme;
    final (color, label) = switch (component.state) {
      CloudflareComponentState.operational => (
        colors.primary,
        l10n.serverStatusCloudflareOperational,
      ),
      CloudflareComponentState.degradedPerformance => (
        colors.tertiary,
        l10n.serverStatusCloudflareDegraded,
      ),
      CloudflareComponentState.partialOutage => (
        colors.tertiary,
        l10n.serverStatusCloudflarePartial,
      ),
      CloudflareComponentState.majorOutage => (
        colors.error,
        l10n.serverStatusCloudflareMajor,
      ),
      CloudflareComponentState.unknown => (
        colors.outline,
        l10n.serverStatusCloudflareUnknown,
      ),
    };
    final icon = switch (component.state) {
      CloudflareComponentState.operational => Icons.check_circle,
      CloudflareComponentState.degradedPerformance ||
      CloudflareComponentState.partialOutage => Icons.warning_amber_rounded,
      CloudflareComponentState.majorOutage => Icons.error,
      CloudflareComponentState.unknown => Icons.help_outline,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: AppRadius.medium,
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _updatedLabel(context, l10n, component),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _updatedLabel(
    BuildContext context,
    AppLocalizations l10n,
    CloudflareComponent component,
  ) {
    final t = component.updatedAt.toLocal();
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '${l10n.serverStatusUpdated} $hh:$mm';
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
