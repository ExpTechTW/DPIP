import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

class DateTimelineItem extends StatelessWidget {
  final String date;

  const DateTimelineItem(
    this.date, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: Container(color: context.colors.outlineVariant),
                      ),
                      SizedBox(
                        width: 42,
                        child: Container(
                          height: 8,
                          width: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: context.colors.outlineVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: context.colors.secondaryContainer,
                    ),
                    child: Text(
                      date,
                      style: context.theme.textTheme.labelLarge?.copyWith(
                        height: 1,
                        color: context.colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
