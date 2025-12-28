import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:dpip/app/home/home_display_mode.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';

class SettingsLayoutPage extends StatelessWidget {
  const SettingsLayoutPage({super.key});

  static const route = '/settings/layout';

  @override
  Widget build(BuildContext context) {
    return Section(
      label: Text('首頁樣式'.i18n),
      children: [
        Consumer<SettingsUserInterfaceModel>(
          builder: (context, model, child) {
            final tiles = [
              SectionListTile(
                title: Text('雷達回波'.i18n),
                trailing: Switch(
                  value: model.isEnabled(HomeDisplaySection.radar),
                  onChanged: (v) =>
                      model.toggleSection(HomeDisplaySection.radar, v),
                ),
              ),
              SectionListTile(
                title: Text('天氣預報(24h)'.i18n),
                trailing: Switch(
                  value: model.isEnabled(HomeDisplaySection.forecast),
                  onChanged: (v) =>
                      model.toggleSection(HomeDisplaySection.forecast, v),
                ),
              ),
              SectionListTile(
                title: Text('歷史事件'.i18n),
                trailing: Switch(
                  value: model.isEnabled(HomeDisplaySection.history),
                  onChanged: (v) =>
                      model.toggleSection(HomeDisplaySection.history, v),
                ),
              ),
            ];
            return Column(
              children: ListTile.divideTiles(
                context: context,
                tiles: tiles,
              ).toList(),
            );
          },
        ),
      ],
    );
  }
}
