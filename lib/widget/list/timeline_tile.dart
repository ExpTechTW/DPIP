import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeLineTile extends StatelessWidget {
  final DateTime time;
  final Widget icon;
  final Color color;
  final Widget child;
  final bool showDate;
  final double height;
  final bool first;
  final void Function()? onTap;

  const TimeLineTile({
    super.key,
    required this.time,
    required this.icon,
    required this.color,
    required this.child,
    this.showDate = false,
    this.height = 88,
    this.first = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              width: 84,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showDate)
                    Text(
                      DateFormat(context.i18n.date_format).format(time),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  Text(
                    DateFormat(context.i18n.time_format).format(time),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (first)
                  Padding(
                    padding: EdgeInsets.only(top: height / 2),
                    child: Container(
                      width: 2,
                      height: first ? height / 2 : height,
                      color: context.colors.outlineVariant, // Color of the vertical line
                    ),
                  )
                else
                  Container(
                    width: 2,
                    height: first ? height / 2 : height,
                    color: context.colors.outlineVariant, // Color of the vertical line
                  ),
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: icon,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
