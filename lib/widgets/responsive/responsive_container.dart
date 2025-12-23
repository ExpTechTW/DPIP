import 'dart:math';

import 'package:flutter/cupertino.dart';

enum ResponsiveMode {
  content,
  panel,
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final ResponsiveMode mode;

  const ResponsiveContainer({
    required this.child,
    this.maxWidth,
    this.mode = ResponsiveMode.content,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isLargeTablet = width >= 800;

        double contentMaxWidth;
        Alignment alignment;

        switch (mode) {
          case ResponsiveMode.panel:
            contentMaxWidth = (maxWidth ?? constraints.maxWidth * 0.45);
            alignment = isLargeTablet
                ? Alignment.centerRight
                : Alignment.center;
            break;

          case ResponsiveMode.content:
          default:
            contentMaxWidth = width >= 600
                ? min(width * 0.9, maxWidth ?? 750)
                : width;
            alignment = Alignment.center;
        }

        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
