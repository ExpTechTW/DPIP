import 'package:flutter/material.dart';

import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/home/_widgets/eew_card.dart';
import 'package:dpip/app/home/_widgets/location_button.dart';
import 'package:dpip/app/home/_widgets/radar_card.dart';
import 'package:dpip/app/home/_widgets/weather_header.dart';
import 'package:dpip/app_old/page/history/widgets/date_timeline_item.dart';
import 'package:dpip/app_old/page/history/widgets/history_timeline_item.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/time_convert.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const route = '/home';

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            SizedBox(height: 48 + context.padding.top),

            // 天氣標頭
            Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: WeatherHeader()),

            // 即時資訊
            if (false) // TODO: 將監視器地圖的地震資訊移至 ChangeNotifier
              Padding(padding: const EdgeInsets.all(16), child: EewCard()),

            // 地圖
            Padding(padding: const EdgeInsets.all(16), child: RadarMapCard()),

            // 歷史資訊
            Selector<SettingsLocationModel, String?>(
              selector: (context, model) => model.code,
              builder: (context, code, child) {
                final location = Global.location[code];

                if (code == null || location == null) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder(
                  future: ExpTech().getHistoryRegion(code),
                  builder: (context, snapshot) {
                    final data = snapshot.data;

                    if (data == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (data.isEmpty) {
                      return Center(child: Text(context.i18n.home_safety));
                    }

                    final grouped = groupBy(
                      data,
                      (e) =>
                          DateFormat(context.i18n.full_date_format, context.locale.toLanguageTag()).format(e.time.send),
                    );

                    return Column(
                      children:
                          grouped.entries.mapIndexed((index, entry) {
                            final date = entry.key;
                            final historyGroup = entry.value;
                            return Column(
                              children: [
                                DateTimelineItem(date, first: index == 0),
                                ...historyGroup.map((history) {
                                  final int? expireTimestamp = history.time.expires['all'];
                                  final TZDateTime expireTimeUTC = convertToTZDateTime(expireTimestamp ?? 0);
                                  final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
                                  return HistoryTimelineItem(
                                    expired: isExpired,
                                    history: history,
                                    last: history == data.last,
                                  );
                                }),
                              ],
                            );
                          }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
        Positioned(top: 48, left: 0, right: 0, child: Align(alignment: Alignment.topCenter, child: LocationButton())),
      ],
    );
  }
}
