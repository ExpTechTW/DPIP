/// A map-overlay legend that starts collapsed as a compact chip and expands
/// on tap — keeps the top-left clear until the user asks for the key.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';

/// Wraps a layer's [legend] body. Remount with a new [Key] (e.g. layer id) to
/// reset to the collapsed state when the active layer changes.
class CollapsibleMapLegend extends StatefulWidget {
  const CollapsibleMapLegend({super.key, required this.legend});

  /// The layer's full legend (typically a [MapLegendCard]).
  final Widget legend;

  @override
  State<CollapsibleMapLegend> createState() => _CollapsibleMapLegendState();
}

class _CollapsibleMapLegendState extends State<CollapsibleMapLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: Curves.easeOut,
      alignment: Alignment.topLeft,
      child: _expanded
          ? _Expanded(
              legend: widget.legend,
              onCollapse: () => setState(() => _expanded = false),
              collapseTooltip: l10n.mapLegendCollapse,
            )
          : _Chip(
              tooltip: l10n.mapLegendExpand,
              onTap: () => setState(() => _expanded = true),
            ),
    );
  }
}

/// Compact frosted control that reveals the legend.
class _Chip extends StatelessWidget {
  const _Chip({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface.withValues(alpha: 0.92),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        borderRadius: AppRadius.small,
        child: InkWell(
          borderRadius: AppRadius.small,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.legend_toggle,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  tooltip,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full legend with a collapse control tucked in the top-right corner.
class _Expanded extends StatelessWidget {
  const _Expanded({
    required this.legend,
    required this.onCollapse,
    required this.collapseTooltip,
  });

  final Widget legend;
  final VoidCallback onCollapse;
  final String collapseTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        legend,
        Positioned(
          top: -6,
          right: -6,
          child: Tooltip(
            message: collapseTooltip,
            child: Material(
              color: colors.surface,
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onCollapse,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.expand_less,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
