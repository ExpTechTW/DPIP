import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/widgets/list/list_tile.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsUnitPage extends StatelessWidget {
  const SettingsUnitPage({super.key});

  static const route = '/settings/unit';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        ListSection(
          title: '單位'.i18n,
          children: [
            Selector<SettingsUserInterfaceModel, bool>(
              selector: (context, model) => model.useFahrenheit,
              builder: (context, useFahrenheit, child) {
                return ListSectionTile(
                  icon: Symbols.thermostat_rounded,
                  title: '使用華氏度'.i18n,
                  subtitle: Text('切換溫度顯示單位為華氏度 (℉)'.i18n),
                  trailing: Switch(
                    value: useFahrenheit,
                    onChanged: (value) => context.read<SettingsUserInterfaceModel>().setUseFahrenheit(value),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
