/// A layer-picker button positioned in the top-right corner of the map.
library;

import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle_sheet.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// A blurred icon button fixed at the top-right of the map that opens the
/// [LayerToggleSheet] when tapped.
///
/// Hidden when [isReplayMode] is `true`.
class PositionedLayerButton extends StatelessWidget {
  /// The currently active set of map layers.
  final Set<MapLayer> activeLayers;

  /// The currently selected base map style.
  final BaseMapType currentBaseMap;

  /// When `true`, hides this button entirely.
  final bool isReplayMode;

  /// Called when the user toggles a layer on or off.
  final void Function(MapLayer layer, bool show, Set<MapLayer> activeLayers) onLayerChanged;

  /// Called when the user selects a different base map.
  final void Function(BaseMapType baseMap) onBaseMapChanged;

  /// Creates a [PositionedLayerButton] with the required layer and base-map
  /// callbacks.
  const PositionedLayerButton({
    super.key,
    required this.activeLayers,
    required this.currentBaseMap,
    required this.isReplayMode,
    required this.onLayerChanged,
    required this.onBaseMapChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isReplayMode) return const SizedBox.shrink();
    return Positioned(
      top: 24,
      right: 24,
      child: SafeArea(
        child: BlurredIconButton(
          icon: const Icon(Symbols.layers_rounded),
          tooltip: '圖層',
          elevation: 2,
          onPressed: () => showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            useSafeArea: true,
            isScrollControlled: true,
            constraints: context.bottomSheetConstraints,
            builder: (context) {
              return LayerToggleSheet(
                activeLayers: activeLayers,
                currentBaseMap: currentBaseMap,
                onLayerChanged: onLayerChanged,
                onBaseMapChanged: onBaseMapChanged,
              );
            },
          ),
        ),
      ),
    );
  }
}
