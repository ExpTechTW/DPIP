import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/_widgets/weather_notify_section.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
              onChanged: (value) => context
                  .read<SettingsNotificationModel>()
                  .setWeatherAdvisory(value),
            );
          },
        ),
        SegmentedList(
          label: Text('音效測試'.i18n),
          children: [
            SoundListTile(
              title: '重大'.i18n,
              subtitle: Text('所在地(鄉鎮)發布紅色燈號之\n天氣警特報'.i18n),
              type: 'weather_major-important-v2',
              isFirst: true,
            ),
            SoundListTile(
              title: '一般'.i18n,
              subtitle: Text('所在地(鄉鎮)發布上述除外燈號之\n天氣警特報'.i18n),
              type: 'weather_minor-general-v2',
              isLast: true,
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
