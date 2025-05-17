import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/basic_notify_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsNotifyAnnouncementPage extends StatelessWidget {
  const SettingsNotifyAnnouncementPage({super.key});

  static const name = 'announcement';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, BasicNotifyType>(
          selector: (context, model) => model.announcement,
          builder: (context, value, child) {
            return BasicNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setAnnouncement(value),
            );
          },
        ),
        SettingsListSection(
          title: context.i18n.notify_test,
          children: [
            SoundListTile(
              title: context.i18n.announcement,
              subtitle: Text(context.i18n.server_announcement_description_sound),
              type: 'announcement-general-v2',
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
