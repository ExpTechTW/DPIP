/// Tsunami notification settings page.
library;

import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/_widgets/tsunami_notify_section.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A page for configuring tsunami notification settings and testing tsunami
/// notification sounds.
class SettingsNotifyTsunamiPage extends StatelessWidget {
  /// Creates a [SettingsNotifyTsunamiPage].
  const SettingsNotifyTsunamiPage({super.key});

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
        SegmentedList(
          label: Text('音效測試'.i18n),
          children: [
            SoundListTile(
              title: '重大'.i18n,
              subtitle: Text('海嘯警報發布時'.i18n),
              type: 'tsunami-important-v2',
              isFirst: true,
            ),
            SoundListTile(
              title: '一般'.i18n,
              subtitle: Text('海嘯消息發布時'.i18n),
              type: 'tsunami-general-v2',
            ),
            SoundListTile(
              title: '太平洋海嘯消息(無聲通知)'.i18n,
              subtitle: Text('太平洋海嘯消息發布時'.i18n),
              type: 'tsunami-silent-v2',
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
