import 'package:dpip/app/settings/notify/_widgets/basic_notify_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              onChanged: (value) => context
                  .read<SettingsNotificationModel>()
                  .setAnnouncement(value),
            );
          },
        ),
        Section(
          label: Text('音效測試'.i18n),
          children: [
            SoundListTile(
              title: '公告'.i18n,
              subtitle: Text('發送公告時'.i18n),
              type: 'announcement-general-v2',
            ),
          ],
        ),
        SectionText(
          child: Text(
            '音效測試為在裝置上執行的本地通知，僅用於確認裝置在接收通知時是否能正常播放音效。此測試不會向伺服器發送任何請求'.i18n,
          ),
        ),
      ],
    );
  }
}
