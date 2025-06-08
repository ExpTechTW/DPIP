import 'package:dpip/app/map/_lib/utils.dart';
import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/models/settings/map.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:dpip/widgets/map/map.dart';

class SettingsMapPage extends StatelessWidget {
  const SettingsMapPage({super.key});

  static const route = '/settings/map';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '地圖',
          children: [
            Selector<SettingsMapModel, BaseMapType>(
              selector: (context, model) => model.baseMap,
              builder: (context, baseMapType, child) {
                return ListSectionTile(
                  icon: Symbols.layers_rounded,
                  title: '地圖底圖',
                  subtitle: Text(baseMapType.name),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                );
              },
            ),
            Selector<SettingsMapModel, MapLayer>(
              selector: (context, model) => model.layer,
              builder: (context, layer, child) {
                return ListSectionTile(
                  icon: Symbols.layers_rounded,
                  title: '初始圖層',
                  subtitle: Text(layer.name),
                  trailing: const Icon(Symbols.chevron_right_rounded),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
