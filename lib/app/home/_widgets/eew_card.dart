import 'dart:async';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/model/eew.dart';
// import 'package:dpip/app/map/monitor/monitor.dart';
import 'package:dpip/core/eew.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/int.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';

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

  void calculateEarthquakeInfo() {}

  void _updateCountdown() {
    final remainingSeconds = ((localArrivalTime - GlobalProviders.data.currentTime) / 1000).floor();

    setState(() => countdown = remainingSeconds);
  }

  @override
  void initState() {
    super.initState();

    final info = eewLocationInfo(
      widget.data.eq.magnitude,
      widget.data.eq.depth,
      widget.data.eq.latitude,
      widget.data.eq.longitude,
      GlobalProviders.location.coordinateNotifier.value.latitude,
      GlobalProviders.location.coordinateNotifier.value.longitude,
    );

    localIntensity = intensityFloatToInt(info.i);
    localArrivalTime = (widget.data.eq.time + sWaveTimeByDistance(widget.data.eq.depth, info.dist)).floor();

    _updateCountdown();
    Timer.periodic(const Duration(seconds: 1), (_) => _updateCountdown());
  }

  String intensityLabel(int count) {
    const map = {5: '5弱', 6: '5強', 7: '6弱', 8: '6強', 9: '7級'};
    return map[count] ?? '$count級';
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
                                '緊急地震速報',
                                style: context.textTheme.labelLarge!.copyWith(
                                  color: context.colors.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '第 ${widget.data.serial} 報',
                          style: context.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                        ),
                      ],
                    ),
                    Icon(Symbols.chevron_right_rounded, color: context.colors.onErrorContainer, size: 24),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(text: '${widget.data.eq.time.toSimpleDateTimeString(context)} 左右 '),
                        TextSpan(text: widget.data.eq.location, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' 附近發生有感地震，預估規模 '),
                        TextSpan(
                          text: widget.data.eq.magnitude.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(text: '、最大震度 '),
                        TextSpan(
                          text: intensityLabel(localIntensity),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      style: context.textTheme.bodyLarge!.copyWith(color: context.colors.onErrorContainer),
                    ),
                  ),
                ),
                Selector<SettingsLocationModel, String?>(
                  selector: (context, model) => model.code,
                  builder: (context, code, child) {
                    if (code == null) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
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
                                  spacing: 16,
                                  children: [
                                    Text(
                                      '所在地預估',
                                      style: context.textTheme.labelLarge!.copyWith(
                                        color: context.colors.onErrorContainer.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: intensityLabel(localIntensity)[0],
                                            style: context.textTheme.displayLarge!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onErrorContainer,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' ${intensityLabel(localIntensity)[1]}',
                                            style: context.textTheme.bodyLarge!.copyWith(
                                              color: context.colors.onErrorContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            VerticalDivider(
                              color: context.colors.onErrorContainer.withValues(alpha: 0.4),
                              indent: 8,
                              endIndent: 8,
                              width: 24,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  spacing: 16,
                                  children: [
                                    Text(
                                      '震波',
                                      style: context.textTheme.labelLarge!.copyWith(
                                        color: context.colors.onErrorContainer.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: countdown.toString(),
                                            style: context.textTheme.displayLarge!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onErrorContainer,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' 秒後抵達',
                                            style: context.textTheme.bodyLarge!.copyWith(
                                              color: context.colors.onErrorContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
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
