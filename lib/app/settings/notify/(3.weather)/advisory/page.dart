import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/settings/_widgets/list_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/_widgets/weather_notify_section.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class SettingsNotifyAdvisoryPage extends StatelessWidget {
  const SettingsNotifyAdvisoryPage({super.key});

  static const name = 'advisory';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, WeatherNotifyType>(
          selector: (context, model) => model.weatherAdvisory,
          builder: (context, value, child) {
            return WeatherNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setWeatherAdvisory(value),
            );
          },
        ),
        SettingsListSection(
          title: context.i18n.notify_test,
          children: [
            SoundListTile(
              title: context.i18n.sound_major,
              subtitle: Text(context.i18n.sound_weather_major_h2),
              type: 'weather_major-important',
            ),
            SoundListTile(
              title: '一般',
              subtitle: Text(context.i18n.sound_weather_minor_h2),
              type: 'weather_minor-general',
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
