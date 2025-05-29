import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/_widgets/tsunami_notify_section.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

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
        ListSection(
          title: context.i18n.notify_test,
          children: [
            SoundListTile(
              title: context.i18n.sound_major,
              subtitle: Text(context.i18n.tsunami_alert_description_sound),
              type: 'tsunami-important',
            ),
            SoundListTile(
              title: context.i18n.me_general,
              subtitle: Text(context.i18n.tsunami_alert2_description_sound),
              type: 'tsunami-general',
            ),
            SoundListTile(
              title: context.i18n.sound_tsunami_silent,
              subtitle: Text(context.i18n.sound_tsunami_silent_h2),
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
