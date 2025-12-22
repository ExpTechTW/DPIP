import 'dart:math';

import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/route/event_viewer/thunderstorm.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/color_scheme.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/responsive_constants.dart';
import 'package:flutter/material.dart';
import 'package:i18n_extension/i18n_extension.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:styled_text/styled_text.dart';

class ThunderstormCard extends StatelessWidget {
  final History history;

  const ThunderstormCard(this.history, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;

        final contentMaxWidth = maxWidth >= ResponsiveBreakpoints.tablet
            ? min(maxWidth * ResponsiveConstraints.contentPaddingMultiplier, ResponsiveConstraints.mapContentMaxWidth)
            : maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: contentMaxWidth
            ),
            child: Stack(
              children: [
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.theme.extendedColors.blueContainer,
                      border: Border.all(color: context.theme.extendedColors.blue, width: 2),
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
                                    color: context.theme.extendedColors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    spacing: 4,
                                    children: [
                                      Icon(
                                        Symbols.thunderstorm_rounded,
                                        color: context.theme.extendedColors.onBlue,
                                        weight: 700,
                                        size: 22,
                                      ),
                                      Text(
                                        '雷雨即時訊息'.i18n,
                                        style: context.texts.labelLarge!.copyWith(
                                          color: context.theme.extendedColors.onBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Icon(Symbols.chevron_right_rounded, color: context.colors.onErrorContainer, size: 24),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: StyledText(
                            text: '您所在區域附近有劇烈雷雨或降雨發生，請注意防範，持續至 <bold>{time}</bold> 。'.i18n.args({
                              'time': history.time.expiresAt.toSimpleDateTimeString(),
                            }),
                            style: context.texts.bodyLarge!.copyWith(color: context.theme.extendedColors.onBlueContainer),
                            tags: {'bold': StyledTextTag(style: const TextStyle(fontWeight: FontWeight.bold))},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => ThunderstormPage(item: history))),
                      splashColor: context.theme.extendedColors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
