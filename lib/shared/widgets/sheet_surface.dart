/// The frosted, rounded panel every draggable detail sheet slides in on —
/// rounded + shadowed mid-height, full-bleed under the status bar when flush.
library;

import 'package:dpip/app/theme/app_radius.dart';
import 'package:flutter/material.dart';

class SheetSurface extends StatelessWidget {
  const SheetSurface({super.key, required this.child, this.flushTop = false});

  final Widget child;

  /// Full-bleed under the status bar — drop top radius / shadow so it reads as
  /// one panel with the safe-area band, not a floating card.
  final bool flushTop;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = flushTop ? BorderRadius.zero : AppRadius.topSheet;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        boxShadow: flushTop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
      ),
      child: ClipRRect(borderRadius: radius, child: child),
    );
  }
}
