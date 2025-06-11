import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/earthquake_notify_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsNotifyMonitorPage extends StatelessWidget {
  const SettingsNotifyMonitorPage({super.key});

  static const name = 'monitor';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, EarthquakeNotifyType>(
          selector: (context, model) => model.monitor,
          builder: (context, value, child) {
            return EarthquakeNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setMonitor(value),
            );
          },
        ),
        const ListSection(
          title: '音效測試',
          children: [
            SoundListTile(
              title: '強震監視器(一般)',
              subtitle: Text('偵測到晃動'),
              type: 'eq',
            ),
          ],
        ),
        const SettingsListTextSection(
          icon: Symbols.info_rounded,
          content: '音效測試為在裝置上執行的本地通知，僅用於確認裝置在接收通知時是否能正常播放音效。此測試不會向伺服器發送任何請求',
        ),
      ],
    );
  }
}
