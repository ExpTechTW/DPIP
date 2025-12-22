import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:dpip/utils/responsive_constants.dart';

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
        final contentMaxWidth = width >= ResponsiveBreakpoints.tablet
            ? min(width * 0.9, maxWidth ?? ResponsiveConstraints.homeContentMaxWidth)
            : width;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: child,
          ),
        );
      },
    );
  }
}
