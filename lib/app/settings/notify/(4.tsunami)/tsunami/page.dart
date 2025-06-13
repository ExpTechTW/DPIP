import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/_widgets/tsunami_notify_section.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';

class SettingsNotifyTsunamiPage extends StatelessWidget {
  const SettingsNotifyTsunamiPage({super.key});

  static const name = 'tsunami';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, TsunamiNotifyType>(
          selector: (context, model) => model.tsunami,
          builder: (context, value, child) {
            return TsunamiNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setTsunami(value),
            );
          },
        ),
        const ListSection(
          title: '音效測試',
          children: [
            SoundListTile(
              title: '重大',
              subtitle: Text('海嘯警報發布時\n沿海地區鄉鎮'),
              type: 'tsunami-important',
            ),
            SoundListTile(
              title: '一般',
              subtitle: Text('海嘯警報發布時\n上述除外地區'),
              type: 'tsunami-general',
            ),
            SoundListTile(
              title: '太平洋海嘯消息(無聲通知)',
              subtitle: Text('太平洋海嘯消息發布時'),
              type: 'tsunami-silent',
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
