import 'package:dpip/util/extension/build_context.dart';
import 'package:dpip/util/extension/color_scheme.dart';
import 'package:flutter/material.dart';

class RankingList<T> extends StatelessWidget {
  final List<T> data;
  final Widget? Function(BuildContext context, T item, int rank) contentBuilder;
  const RankingList({
    super.key,
    required this.data,
    required this.contentBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.only(top: 4, bottom: context.padding.bottom + 4),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final content = contentBuilder(context, data[index], index + 1);
        if (content == null) return content;

        final color = index == 0
            ? context.theme.extendedColors.amberContainer
            : index == 1
                ? context.theme.extendedColors.greyContainer
                : index == 2
                    ? context.theme.extendedColors.brownContainer
                    : index < 10
                        ? context.colors.surfaceContainerHigh
                        : context.colors.surfaceContainer;

        final contentColor = index == 0
            ? context.theme.extendedColors.onAmberContainer
            : index == 1
                ? context.theme.extendedColors.onGreyContainer
                : index == 2
                    ? context.theme.extendedColors.onBrownContainer
                    : index < 10
                        ? context.colors.onSurface
                        : context.colors.onSurfaceVariant;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color,
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: contentColor),
            child: IconTheme(
              data: IconThemeData(color: contentColor),
              child: content,
            ),
          ),
        );
      },
    );
  }
}
