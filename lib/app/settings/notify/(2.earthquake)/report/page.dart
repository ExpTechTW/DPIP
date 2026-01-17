import 'package:dpip/app/settings/notify/_widgets/earthquake_notify_section.dart';
import 'package:dpip/app/settings/notify/_widgets/sound_list_tile.dart';
import 'package:dpip/app/settings/notify/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/models/settings/notify.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsNotifyReportPage extends StatelessWidget {
  const SettingsNotifyReportPage({super.key});

  static const name = 'report';
  static const route = '/settings/${SettingsNotifyPage.name}/$name';

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Selector<SettingsNotificationModel, EarthquakeNotifyType>(
          selector: (context, model) => model.report,
          builder: (context, value, child) {
            return EarthquakeNotifySection(
              value: value,
              onChanged: (value) =>
                  context.read<SettingsNotificationModel>().setReport(value),
            );
          },
        ),
        SegmentedList(
          label: Text('音效測試'.i18n),
          children: [
            SoundListTile(
              title: '地震報告(一般)'.i18n,
              subtitle: Text('所在地(縣市)實測震度 3 以上'.i18n),
              type: 'report-general-v2',
              isFirst: true,
            ),
            SoundListTile(
              title: '地震報告(無聲通知)'.i18n,
              subtitle: Text('所在地(縣市)實測震度 1 以上'.i18n),
              type: 'report-silence-v2',
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
