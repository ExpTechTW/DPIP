import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/widgets/list/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/earthquake_notify_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsNotifyIntensityPage extends StatelessWidget {
  const SettingsNotifyIntensityPage({super.key});

  static const name = 'intensity';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, EarthquakeNotifyType>(
          selector: (context, model) => model.intensity,
          builder: (context, value, child) {
            return EarthquakeNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setIntensity(value),
            );
          },
        ),
        ListSection(
          title: context.i18n.notify_test,
          children: [
            SoundListTile(
              title: context.i18n.sound_int_report_minor,
              subtitle: Text(context.i18n.sound_int_report_minor_h2),
              type: 'int_report-general',
            ),
            SoundListTile(
              title: context.i18n.sound_int_report_silent,
              subtitle: Text(context.i18n.sound_int_report_silent_h2),
              type: 'int_report-silence',
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
