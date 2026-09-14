/// The map's top-left control row: uniform corner buttons, and the single panel
/// they open dropping into the row underneath.
///
/// Every button here is a [MapChipButton], the same chrome and size as the
/// top-right layer switcher, so the two corners read as one class of control.
/// Only one panel is ever open — they all land in the same slot under the row,
/// and two at once would either stack the corner full or fight over the spot.
///
/// Opening a panel never moves the row: the buttons keep their place while the
/// card grows downwards, so the button stays under the finger that opened it.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/app/theme/app_spacing.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:flutter/material.dart';

/// What a [MapCornerPanel] has to show right now: the open [card], and an
/// optional [badge] the collapsed button carries so a live reading is visible
/// without opening anything.
typedef MapCornerPanelContent = ({Widget card, Widget? badge});

/// A layer-specific panel offered beside the legend — a button in the row and a
/// card in the slot below it.
///
/// The monitor's 震度排行榜 is the only one so far. The panel declares its
/// button and how to build its contents; [MapCornerControls] owns whether it is
/// open, so it and the legend cannot both take the slot.
@immutable
class MapCornerPanel {
  const MapCornerPanel({
    required this.icon,
    required this.tooltip,
    required this.listenable,
    required this.build,
  });

  /// Glyph for the button (outlined variant by convention). The button carries
  /// no label: it shares the row with the legend and the card names itself.
  final IconData icon;

  /// Names the button, and what its tap does.
  final String tooltip;

  /// Rebuilds the button and the card together — a feed, typically, so a tick
  /// can take the whole panel off the map.
  final Listenable listenable;

  /// This frame's contents, or **null** when there is nothing to show at all:
  /// the button goes away with it, and an open panel closes itself rather than
  /// leaving an empty card behind. A feed that has gone stale returns null —
  /// a reading must never outlive the freshness of the data it came from.
  final MapCornerPanelContent? Function(BuildContext context) build;
}

/// The row itself. Remount with a new [Key] (e.g. the layer id) to close
/// whatever was open when the active layer changes.
class MapCornerControls extends StatefulWidget {
  const MapCornerControls({
    super.key,
    required this.legend,
    this.leading,
    this.panel,
  });

  /// The layer's full legend (typically a `MapLegendCard`), shown in the slot
  /// when its button is on.
  final Widget legend;

  /// Optional button before the legend's — the replay page's back arrow, which
  /// belongs on this row rather than in a bar of its own.
  final Widget? leading;

  /// Optional second panel; null for layers that have only a legend.
  final MapCornerPanel? panel;

  @override
  State<MapCornerControls> createState() => _MapCornerControlsState();
}

enum _Slot { legend, panel }

class _MapCornerControlsState extends State<MapCornerControls> {
  /// Which panel holds the slot, or null for none.
  _Slot? _open;

  @override
  Widget build(BuildContext context) {
    final panel = widget.panel;
    if (panel == null) return _row(context, null);
    return ListenableBuilder(
      listenable: panel.listenable,
      builder: (context, _) => _row(context, panel.build(context)),
    );
  }

  Widget _row(BuildContext context, MapCornerPanelContent? content) {
    final l10n = AppLocalizations.of(context);
    final panel = widget.panel;
    // Resolved from what is actually on the row: a feed dropping out takes its
    // button away, and the slot must not keep showing the card it opened.
    final open = content == null && _open == _Slot.panel ? null : _open;

    void toggle(_Slot which) =>
        setState(() => _open = _open == which ? null : which);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.leading case final leading?) ...[
              leading,
              const SizedBox(width: AppSpacing.sm),
            ],
            MapChipButton(
              icon: Icons.legend_toggle,
              tooltip: open == _Slot.legend
                  ? l10n.mapLegendCollapse
                  : l10n.mapLegendExpand,
              active: open == _Slot.legend,
              onTap: () => toggle(_Slot.legend),
            ),
            if (panel != null && content != null) ...[
              const SizedBox(width: AppSpacing.sm),
              MapChipButton(
                icon: panel.icon,
                tooltip: panel.tooltip,
                active: open == _Slot.panel,
                onTap: () => toggle(_Slot.panel),
                trailing: content.badge,
              ),
            ],
          ],
        ),
        AnimatedSize(
          duration: AppMotion.medium,
          curve: Curves.easeOut,
          alignment: Alignment.topLeft,
          child: switch (open) {
            null => const SizedBox.shrink(),
            _Slot.legend => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: widget.legend,
            ),
            _Slot.panel => Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: content!.card,
            ),
          },
        ),
      ],
    );
  }
}
