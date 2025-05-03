import 'package:dpip/app/map/monitor/monitor.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/int.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class EewCard extends StatelessWidget {
  const EewCard({super.key});

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
                                context.i18n.emergency_earthquake_warning,
                                style: context.textTheme.labelLarge!.copyWith(
                                  color: context.colors.onError,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '第 2 報',
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
                        TextSpan(text: '04/25 06:10 左右 '),
                        TextSpan(text: '嘉義縣大埔鄉', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: ' 附近發生有感地震，預估規模 '),
                        TextSpan(text: '4.5', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: '、最大震度 '),
                        TextSpan(text: '4級', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                      context.i18n.location_estimate,
                                      style: context.textTheme.labelLarge!.copyWith(
                                        color: context.colors.onErrorContainer.withValues(alpha: 0.6),
                                      ),
                                    ),

                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 2.asIntensityDisplayLabel,
                                            style: context.textTheme.displayLarge!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onErrorContainer,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' 級',
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
                                      context.i18n.seismic_waves,
                                      style: context.textTheme.labelLarge!.copyWith(
                                        color: context.colors.onErrorContainer.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '8',
                                            style: context.textTheme.displayLarge!.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: context.colors.onErrorContainer,
                                            ),
                                          ),
                                          TextSpan(
                                            text: ' ${context.i18n.monitor_after_seconds}',
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
              onTap: () => context.push(MapMonitorPage.route),
              splashColor: context.colors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
