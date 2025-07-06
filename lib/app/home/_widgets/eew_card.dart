import 'dart:async';

import 'package:dpip/core/i18n.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/model/eew.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/int.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:styled_text/styled_text.dart';

class EewCard extends StatefulWidget {
  final Eew data;

  const EewCard(this.data, {super.key});

  @override
  State<EewCard> createState() => _EewCardState();
}

class _EewCardState extends State<EewCard> {
  late int localIntensity;
  late int localArrivalTime;
  int countdown = 0;

  Timer? _timer;

  void _updateCountdown() {
    final remainingSeconds = ((localArrivalTime - GlobalProviders.data.currentTime) / 1000).floor();
    if (remainingSeconds < -1) return;

    setState(() => countdown = remainingSeconds);
  }

  @override
  void initState() {
    super.initState();

    final info = eewLocationInfo(
      widget.data.info.magnitude,
      widget.data.info.depth,
      widget.data.info.latitude,
      widget.data.info.longitude,
      GlobalProviders.location.coordinateNotifier.value.latitude,
      GlobalProviders.location.coordinateNotifier.value.longitude,
    );

    localIntensity = intensityFloatToInt(info.i);
    localArrivalTime = (widget.data.info.time + sWaveTimeByDistance(widget.data.info.depth, info.dist)).floor();

    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.errorContainer,
              border: Border.all(color: context.colors.error, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: context.colors.error,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4,
                            children: [
                              Icon(Symbols.crisis_alert_rounded, color: context.colors.onError, weight: 700, size: 22),
                              Text(
                                '緊急地震速報'.i18n,
                                style: context.textTheme.labelLarge!.copyWith(
                                  color: context.colors.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '第 {serial} 報'.i18n.args({'serial': widget.data.serial}),
                          style: context.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                        ),
                      ],
                    ),
                    Icon(Symbols.chevron_right_rounded, color: context.colors.onErrorContainer, size: 24),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: StyledText(
                    text:
                        '{time} 左右，<bold>{location}</bold>附近發生有感地震，預估規模 <bold>M{magnitude}</bold>、所在地最大震度<bold>{intensity}</bold>。'
                            .i18n
                            .args({
                              'time': widget.data.info.time.toSimpleDateTimeString(context),
                              'location': widget.data.info.location,
                              'magnitude': widget.data.info.magnitude.toStringAsFixed(1),
                              'intensity': localIntensity.asIntensityLabel,
                            }),
                    style: context.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                    tags: {'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.bold))},
                  ),
                ),
                Selector<SettingsLocationModel, String?>(
                  selector: (context, model) => model.code,
                  builder: (context, code, child) {
                    if (code == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 4),
                      child: IntrinsicHeight(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      '所在地預估'.i18n,
                                      style: context.textTheme.labelLarge!.copyWith(
                                        color: context.colors.onErrorContainer.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                                      child: Text(
                                        localIntensity.asIntensityLabel,
                                        style: context.textTheme.displayMedium!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: context.colors.onErrorContainer,
                                          height: 1,
                                          leadingDistribution: TextLeadingDistribution.even,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            VerticalDivider(color: context.colors.onErrorContainer.withValues(alpha: 0.4), width: 24),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      '震波',
                                      style: context.textTheme.labelLarge!.copyWith(
                                        color: context.colors.onErrorContainer.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                                      child:
                                          (countdown >= 0)
                                              ? RichText(
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: countdown.toString(),
                                                      style: TextStyle(
                                                        fontSize: context.textTheme.displayMedium!.fontSize! * 1.15,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: ' 秒',
                                                      style: TextStyle(
                                                        fontSize: context.textTheme.labelLarge!.fontSize,
                                                      ),
                                                    ),
                                                  ],
                                                  style: context.textTheme.displayMedium!.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: context.colors.onErrorContainer,
                                                    height: 1,
                                                    leadingDistribution: TextLeadingDistribution.even,
                                                  ),
                                                ),
                                                textAlign: TextAlign.center,
                                              )
                                              : Text(
                                                '抵達'.i18n,
                                                style: context.textTheme.displayMedium!.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: context.colors.onErrorContainer,
                                                  height: 1,
                                                  leadingDistribution: TextLeadingDistribution.even,
                                                ),
                                                textAlign: TextAlign.center,
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
              onTap: () => context.push(MapPage.route(layer: MapLayer.monitor)),
              splashColor: context.colors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
