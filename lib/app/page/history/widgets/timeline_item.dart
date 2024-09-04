import 'package:dpip/util/extension/build_context.dart';
import 'package:flutter/material.dart';

class TimelineItem extends StatelessWidget {
  final Widget child;

  const TimelineItem({
    super.key,
    required this.child,
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 8, 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
