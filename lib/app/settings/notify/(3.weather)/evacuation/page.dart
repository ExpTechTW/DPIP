import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/_widgets/weather_notify_section.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/list_section.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

class SettingsNotifyEvacuationPage extends StatelessWidget {
  const SettingsNotifyEvacuationPage({super.key});

  static const name = 'evacuation';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, WeatherNotifyType>(
          selector: (context, model) => model.evacuation,
          builder: (context, value, child) {
            return WeatherNotifySection(
              value: value,
              onChanged: (value) => context.read<SettingsNotificationModel>().setEvacuation(value),
            );
          },
        ),
        ListSection(
          title: '音效測試'.i18n,
          children: [
            SoundListTile(
              title: '重大'.i18n,
              subtitle: Text('所在地(鄉鎮)發布防災警訊時'.i18n),
              type: 'evacuation_major-important-v2',
            ),
            SoundListTile(title: '一般'.i18n, subtitle: Text('所在地(鄉鎮)發布防災資訊時'.i18n), type: 'evacuation_minor-general-v2'),
          ],
        ),
        SettingsListTextSection(
          icon: Symbols.info_rounded,
          content: '音效測試為在裝置上執行的本地通知，僅用於確認裝置在接收通知時是否能正常播放音效。此測試不會向伺服器發送任何請求'.i18n,
        ),
      ],
    );
  }
}
