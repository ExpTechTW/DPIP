import 'dart:typed_data';

import 'package:dpip/core/network/api_client.dart';
import 'package:provider/provider.dart';
import 'package:dpip/features/earthquake/domain/earthquake_report.dart';
import 'package:dpip/features/earthquake/presentation/widgets/earthquake_share_icon.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/core/realtime/app_time.dart';
import 'package:intl/intl.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/shared/seismic/intensity.dart';
import 'package:dpip/shared/seismic/intensity_colors.dart';
import 'package:dpip/shared/widgets/intensity_badge.dart';

enum ShareCardFormat { post, story }

/// The fixed 4:5 report artwork, with an optional official-image layout.
class EarthquakeShareCard extends StatelessWidget {
  const EarthquakeShareCard({
    super.key,
    required this.report,
    this.format = ShareCardFormat.post,
  });

  static const canvas = Size(360, 450);
  static const brandImage = EarthquakeShareIcon.image;

  final EarthquakeReport report;
  final ShareCardFormat format;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final creditStyle = Theme.of(context).textTheme.bodySmall;
    final originTime = DateFormat('yyyy/MM/dd HH:mm:ss')
        .format(AppTime.taipei(report.originTimeUtc));
    final intensity = Intensity.displayForReport(
      report.maxIntensity,
      report.originTimeUtc,
    );

    final content = <Widget>[
      Row(
        children: [
          EarthquakeShareIcon(
            size: 44,
            // The dialog checks the same provider before enabling export.
            errorBuilder: (_, _, _) => const SizedBox.square(dimension: 44),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DPIP',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  l10n.moreTagline,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            constraints: const BoxConstraints(maxWidth: 120),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.reportDetailTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      const Divider(height: 1),
      const SizedBox(height: AppSpacing.lg),

      Text(
        l10n.reportDetailOriginTime,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: colors.onSurfaceVariant),
      ),
      const SizedBox(height: AppSpacing.xs),
      Text(
        originTime,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: AppSpacing.lg),
      Text(
        report.shortLocation,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      if (report.location.trim() != report.shortLocation) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          report.location,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
      const SizedBox(height: AppSpacing.xl),

      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ShareMetric(
                label: l10n.reportDetailMagnitude,
                value: report.magnitude.toStringAsFixed(1),
                caption: l10n.reportDetailShareRichterScale,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ShareMetric(
                label: l10n.reportDetailMaximumIntensityLabel,
                value: '',
                caption: l10n.reportDetailShareObservedIntensity,
                badge: IntensityBadge(
                  label: intensity.label,
                  color: IntensityColors.discrete(intensity.colorLevel),
                  size: 36,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ShareMetric(
                label: l10n.reportDetailDepth,
                value: report.depth.toStringAsFixed(1),
                caption: l10n.reportDetailShareKilometers,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];

    // The preview shows the typography of the fixed-size artwork. The share
    // dialog offers the same report as responsive text at the system size.
    return MediaQuery.withNoTextScaling(
      child: AspectRatio(
        aspectRatio: format == ShareCardFormat.post ? 4 / 5 : 9 / 16,
        child: ColoredBox(
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Allow the optional official image to take the space
                // left below the artwork's text.
                if (format == ShareCardFormat.story) ...[
                  ...content,
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.medium,
                        child: ColoredBox(
                          color: colors.surfaceContainer,
                          child: _ReportImagePreview(
                            url: report.reportImageUrl.toString(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, viewport) => FittedBox(
                        alignment: AlignmentDirectional.topStart,
                        // Some translations wrap the metric labels and the
                        // location. Fit the complete content when it uses up the
                        // space above the credits.
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: viewport.maxWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: content,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Data source must always be visible.
                Text(l10n.reportDetailShareSource, style: creditStyle),
                Text(l10n.reportDetailSharePreparedBy, style: creditStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareMetric extends StatelessWidget {
  const _ShareMetric({
    required this.label,
    required this.value,
    required this.caption,
    this.badge,
  });

  final String label;
  final String value;
  final String caption;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 40,
            child: Align(
              alignment: Alignment.centerLeft,
              child:
                  badge ??
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            caption,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportImagePreview extends StatefulWidget {
  const _ReportImagePreview({required this.url});

  final String url;

  @override
  State<_ReportImagePreview> createState() => _ReportImagePreviewState();
}

class _ReportImagePreviewState extends State<_ReportImagePreview> {
  late Future<Uint8List> _imageFuture;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  void _loadImage() {
    _imageFuture = context
        .read<ApiClient>()
        .getBytesAbsolute(widget.url)
        .then((response) => response.bytes);
  }

  @override
  void didUpdateWidget(covariant _ReportImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      _loadImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder<Uint8List>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(l10n.reportDetailImageUnavailable));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Center(
          child: Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => Text(l10n.reportDetailShareImageInvalid),
          ),
        );
      },
    );
  }
}
