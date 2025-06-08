import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/widgets/map/map.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/_widgets/layer_toggle_sheet.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class PositionedLayerButton extends StatelessWidget {
  final MapLayer? currentLayer;
  final BaseMapType currentBaseMap;
  final void Function(MapLayer? layer) onChanged;
  final void Function(BaseMapType baseMap) onBaseMapChanged;

  const PositionedLayerButton({
    super.key,
    required this.currentLayer,
    required this.currentBaseMap,
    required this.onChanged,
    required this.onBaseMapChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 24,
      right: 24,
      child: SafeArea(
        child: BlurredIconButton(
          icon: const Icon(Symbols.layers_rounded),
          elevation: 2,
          onPressed:
              () => showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                useSafeArea: true,
                isScrollControlled: true,
                constraints: context.bottomSheetConstraints,
                builder:
                    (context) => LayerToggleSheet(
                      currentLayer: currentLayer,
                      currentBaseMap: currentBaseMap,
                      onChanged: onChanged,
                      onBaseMapChanged: onBaseMapChanged,
                    ),
              ),
        ),
      ),
    );
  }
}
