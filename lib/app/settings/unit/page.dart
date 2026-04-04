/// Settings page for configuring measurement units displayed throughout the app.
///
/// Unit preferences are persisted through [SettingsUserInterfaceModel] via
/// [Provider].
library;

import 'package:dpip/app/settings/_widgets/settings_header.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/ui.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/icon_container.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// A settings page for measurement unit preferences.
///
/// Renders controls for each supported unit option. Requires
/// [SettingsUserInterfaceModel] to be available in the widget tree:
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => SettingsUserInterfaceModel(),
///   child: const SettingsUnitPage(),
/// )
/// ```
class SettingsUnitPage extends StatelessWidget {
  /// Creates a [SettingsUnitPage].
  const SettingsUnitPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsUserInterfaceModel>(
      builder: (context, model, child) {
        return ListView(
          padding: .only(
            top: 16,
            bottom: 16 + context.padding.bottom,
          ),
          children: [
            SettingsHeader(
              icon: Symbols.straighten_rounded,
              title: Text('單位'.i18n),
              subtitle: Text('調整 DPIP 顯示數值時使用的單位'.i18n),
            ),
            const SizedBox(height: 16),
            SegmentedList(
              children: [
                Selector<SettingsUserInterfaceModel, bool>(
                  selector: (context, model) => model.useFahrenheit,
                  builder: (context, useFahrenheit, child) {
                    return SegmentedListTile(
                      isFirst: true,
                      isLast: true,
                      leading: ContainedIcon(
                        Symbols.thermostat_rounded,
                        color: Colors.amberAccent,
                      ),
                      title: Text('使用華氏度'.i18n),
                      subtitle: Text('切換溫度顯示單位為華氏度 (℉)'.i18n),
                      trailing: Switch(
                        value: useFahrenheit,
                        onChanged: (value) => model.setUseFahrenheit(value),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
