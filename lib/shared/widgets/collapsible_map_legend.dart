/// A map-overlay legend that starts collapsed as a compact chip and expands
/// on tap — keeps the top-left clear until the user asks for the key.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_radius.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/frosted_surface.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
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
///
/// Literally the shared [MapChipButton]: on the replay page this chip sits in
/// the same top row as that page's back button and the base-map chip, and a
/// legend of its own chrome was 4px shorter than the chips beside it — a
/// difference small enough to look like a mistake rather than a choice. One
/// widget means the row cannot drift apart again.
class _Chip extends StatelessWidget {
  const _Chip({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MapChipButton(
      icon: Icons.legend_toggle,
      label: tooltip,
      tooltip: tooltip,
      active: false,
      onTap: onTap,
    );
  }
}

/// Full legend with a collapse control in its own row — never overlays content.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Tooltip(
            message: collapseTooltip,
            child: FrostedSurface(
              borderRadius: AppRadius.small,
              shadow: false,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: AppRadius.small,
                  onTap: onCollapse,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
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
        ),
        const SizedBox(height: AppSpacing.xs),
        legend,
      ],
    );
  }
}
