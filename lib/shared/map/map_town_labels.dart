/// The base map's township-name toggle, shared by every layer's settings menu.
///
/// [MapTownLabelsRow] slots into an existing overlay menu so the map-level
/// toggle never needs its own chip; [MapTownLabelsMenu] is the standalone
/// dropdown for layers that have no other settings (the state still lives in
/// [MapScaffold], this just renders it).
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/map_style.dart';
import 'package:dpip/shared/widgets/map_chip_button.dart';
import 'package:dpip/shared/widgets/map_menu_toggle_row.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One checkbox row for the township-name setting — drops into any overlay
/// menu's children.
class MapTownLabelsRow extends StatelessWidget {
  const MapTownLabelsRow({
    super.key,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
  });

  /// Whether township-name labels are on (see [townLabelLayerId]).
  final ValueListenable<bool> showTownLabels;

  final ValueChanged<bool> onShowTownLabelsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: showTownLabels,
      builder: (context, _) => MapMenuToggleRow(
        selected: showTownLabels.value,
        icon: Icons.label_outlined,
        title: l10n.mapTownLabels,
        subtitle: l10n.mapTownLabelsHint,
        tooltip: l10n.mapTownLabelsHint,
        onTap: () => onShowTownLabelsChanged(!showTownLabels.value),
      ),
    );
  }
}

/// Standalone township-label dropdown for layers that ship no other chrome —
/// same chip affordance as the layer menus, so a map without a tune button
/// still exposes the map's one optional setting.
class MapTownLabelsMenu extends StatelessWidget {
  const MapTownLabelsMenu({
    super.key,
    required this.showTownLabels,
    required this.onShowTownLabelsChanged,
  });

  final ValueListenable<bool> showTownLabels;
  final ValueChanged<bool> onShowTownLabelsChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: showTownLabels,
      builder: (context, _) => MenuAnchor(
        alignmentOffset: const Offset(0, 4),
        style: MapChipButton.menuStyle(context),
        builder: (context, controller, _) => MapChipButton(
          icon: Icons.tune,
          tooltip: l10n.mapTownLabels,
          active: !showTownLabels.value,
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
        menuChildren: [
          MapMenuScrollView(
            children: [
              MapTownLabelsRow(
                showTownLabels: showTownLabels,
                onShowTownLabelsChanged: onShowTownLabelsChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
