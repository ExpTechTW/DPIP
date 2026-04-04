/// Earthquake Early Warning (EEW) alert card for the home screen.
library;

import 'dart:async';

import 'package:dpip/api/model/eew.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/widgets/responsive/responsive_container.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';
import 'package:styled_text/styled_text.dart';

/// Displays an EEW alert for the given [data], including magnitude, location,
/// local intensity estimate, and a live countdown to S-wave arrival.
///
/// Tapping the card navigates to the monitor map view.
class EewCard extends StatefulWidget {
  /// The EEW event data to display.
  final Eew data;

  /// Creates an [EewCard] for the provided [data].
  const EewCard(this.data, {super.key});

  @override
  State<EewCard> createState() => _EewCardState();
}

class _EewCardState extends State<EewCard> {
  /// Estimated local seismic intensity, or `null` when location is unavailable.
  int? localIntensity;

  /// Expected S-wave arrival timestamp in milliseconds, or `null`.
  int? localArrivalTime;

  /// Current countdown in seconds until S-wave arrival.
  int countdown = 0;

  Timer? _timer;

  void _updateCountdown() {
    if (localArrivalTime == null) return;

    final remainingSeconds =
        ((localArrivalTime! - GlobalProviders.data.currentTime) / 1000)
            .floor();
    if (remainingSeconds < -1) return;

    setState(() => countdown = remainingSeconds);
  }

  @override
  void initState() {
    super.initState();

    if (GlobalProviders.location.coordinates != null) {
      final info = eewLocationInfo(
        widget.data.info.magnitude,
        widget.data.info.depth,
        widget.data.info.latitude,
        widget.data.info.longitude,
        GlobalProviders.location.coordinates!.latitude,
        GlobalProviders.location.coordinates!.longitude,
      );

      localIntensity = intensityFloatToInt(info.i);
      localArrivalTime =
          (widget.data.info.time +
                  sWaveTimeByDistance(widget.data.info.depth, info.dist))
              .floor();
    }

    _updateCountdown();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 720,
      child: Stack(
        children: [
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                border: Border.all(color: context.colors.error, width: 2),
                borderRadius: .circular(16),
              ),
              padding: const .all(12),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  Row(
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: context.colors.error,
                              borderRadius: .circular(8),
                            ),
                            padding: const .fromLTRB(8, 6, 12, 6),
                            child: Row(
                              mainAxisSize: .min,
                              spacing: 4,
                              children: [
                                Icon(
                                  Symbols.crisis_alert_rounded,
                                  color: context.colors.onError,
                                  weight: 700,
                                  size: 22,
                                ),
                                Text(
                                  'EEW'.i18n,
                                  style: context.texts.labelLarge!.copyWith(
                                    color: context.colors.onError,
                                    fontWeight: .bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '第 {serial} 報'.i18n.args({
                              'serial': widget.data.serial,
                            }),
                            style: context.texts.bodyLarge!.copyWith(
                              color: context.colors.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Symbols.chevron_right_rounded,
                        color: context.colors.onErrorContainer,
                        size: 24,
                      ),
                    ],
                  ),
                  Padding(
                    padding: const .only(top: 8),
                    child: StyledText(
                      text: localIntensity != null
                          ? '{time} 左右，<bold>{location}</bold>附近發生有感地震，預估規模 <bold>M{magnitude}</bold>、所在地最大震度<bold>{intensity}</bold>。'
                                .i18n
                                .args({
                                  'time': widget.data.info.time
                                      .toSimpleDateTimeString(),
                                  'location': widget.data.info.location,
                                  'magnitude': widget.data.info.magnitude
                                      .toStringAsFixed(1),
                                  'intensity':
                                      localIntensity!.asIntensityLabel,
                                })
                          : '{time} 左右，<bold>{location}</bold>附近發生有感地震，預估規模 <bold>M{magnitude}</bold>、深度<bold>{depth}</bold>公里。'
                                .i18n
                                .args({
                                  'time': widget.data.info.time
                                      .toSimpleDateTimeString(),
                                  'location': widget.data.info.location,
                                  'magnitude': widget.data.info.magnitude
                                      .toStringAsFixed(1),
                                  'depth': widget.data.info.depth
                                      .toStringAsFixed(1),
                                }),
                      style: context.texts.bodyLarge!.copyWith(
                        color: context.colors.onErrorContainer,
                      ),
                      tags: {
                        'bold': StyledTextTag(
                          style: const TextStyle(fontWeight: .bold),
                        ),
                      },
                    ),
                  ),
                  Selector<SettingsLocationModel, String?>(
                    selector: (context, model) => model.code,
                    builder: (context, code, child) {
                      if (code == null || localIntensity == null) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const .only(top: 8, bottom: 4),
                        child: IntrinsicHeight(
                          child: Row(
                            mainAxisSize: .min,
                            crossAxisAlignment: .start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const .all(4),
                                  child: Column(
                                    mainAxisSize: .min,
                                    crossAxisAlignment: .stretch,
                                    children: [
                                      Text(
                                        '所在地預估'.i18n,
                                        style: context.texts.labelLarge!
                                            .copyWith(
                                              color: context
                                                  .colors
                                                  .onErrorContainer
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                      Padding(
                                        padding: const .only(
                                          top: 12,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          localIntensity!.asIntensityLabel,
                                          style: context.texts.displayMedium!
                                              .copyWith(
                                                fontWeight: .bold,
                                                color: context
                                                    .colors
                                                    .onErrorContainer,
                                                height: 1,
                                                leadingDistribution:
                                                    TextLeadingDistribution
                                                        .even,
                                              ),
                                          textAlign: .center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              VerticalDivider(
                                color: context.colors.onErrorContainer
                                    .withValues(alpha: 0.4),
                                width: 24,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const .all(4),
                                  child: Column(
                                    mainAxisSize: .min,
                                    crossAxisAlignment: .stretch,
                                    children: [
                                      Text(
                                        '震波'.i18n,
                                        style: context.texts.labelLarge!
                                            .copyWith(
                                              color: context
                                                  .colors
                                                  .onErrorContainer
                                                  .withValues(alpha: 0.6),
                                            ),
                                      ),
                                      Padding(
                                        padding: const .only(
                                          top: 12,
                                          bottom: 8,
                                        ),
                                        child: (countdown > 0)
                                            ? RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: countdown
                                                          .toString(),
                                                      style: TextStyle(
                                                        fontSize:
                                                            context
                                                                .texts
                                                                .displayMedium!
                                                                .fontSize! *
                                                            1.15,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: ' 秒'.i18n,
                                                      style: TextStyle(
                                                        fontSize: context
                                                            .texts
                                                            .labelLarge!
                                                            .fontSize,
                                                      ),
                                                    ),
                                                  ],
                                                  style: context
                                                      .texts
                                                      .displayMedium!
                                                      .copyWith(
                                                        fontWeight: .bold,
                                                        color: context
                                                            .colors
                                                            .onErrorContainer,
                                                        height: 1,
                                                        leadingDistribution:
                                                            TextLeadingDistribution
                                                                .even,
                                                      ),
                                                ),
                                                textAlign: .center,
                                              )
                                            : Text(
                                                '抵達'.i18n,
                                                style: context
                                                    .texts
                                                    .displayMedium!
                                                    .copyWith(
                                                      fontSize:
                                                          context
                                                              .texts
                                                              .displayMedium!
                                                              .fontSize! *
                                                          0.92,
                                                      fontWeight: .bold,
                                                      color: context
                                                          .colors
                                                          .onErrorContainer,
                                                      height: 1,
                                                      leadingDistribution:
                                                          TextLeadingDistribution
                                                              .even,
                                                    ),
                                                textAlign: .center,
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => MapRoute(layers: 'monitor').push(context),
                splashColor: context.colors.error.withValues(alpha: 0.2),
                borderRadius: .circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
