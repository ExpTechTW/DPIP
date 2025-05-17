import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:provider/provider.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/eew_notify_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsNotifyEewPage extends StatelessWidget {
  const SettingsNotifyEewPage({super.key});

  static const name = 'eew';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, EewNotifyType>(
          selector: (context, model) => model.eew,
          builder: (context, value, child) {
            return EewNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setEew(value),
            );
          },
        ),
        SettingsListSection(
          title: context.i18n.notify_test,
          children: [
            SoundListTile(
              title: context.i18n.sound_eew_alert_major,
              subtitle: Text(context.i18n.eew_alert_description_sound),
              type: 'eew_alert-important-v2',
            ),
            SoundListTile(
              title: context.i18n.sound_eew_minor,
              subtitle: Text(context.i18n.eew_description_sound),
              type: 'eew_alert-general-v2',
            ),
            SoundListTile(
              title: context.i18n.sound_eew_silent,
              subtitle: Text(context.i18n.sound_eew_silent_h2),
              type: 'eew_alert-silent-v2',
            ),
            SoundListTile(
              title: context.i18n.sound_earthquake_eew_major,
              subtitle: Text(context.i18n.sound_earthquake_eew_major_h2),
              type: 'eew-important-v2',
            ),
            SoundListTile(
              title: context.i18n.sound_earthquake_eew_minor,
              subtitle: Text(context.i18n.sound_earthquake_eew_minor_h2),
              type: 'eew-general-v2',
            ),
            SoundListTile(
              title: context.i18n.sound_earthquake_eew_silent,
              subtitle: Text(context.i18n.sound_earthquake_eew_silent_h2),
              type: 'eew-silence-v2',
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
