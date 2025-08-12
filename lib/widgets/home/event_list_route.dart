import 'package:dpip/api/model/history/intensity_history.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:dpip/api/model/history/history.dart';
import 'package:dpip/api/model/history/report_history.dart';
import 'package:dpip/app/map/_lib/utils.dart';
import 'package:dpip/app/map/page.dart';
import 'package:dpip/route/event_viewer/intensity.dart';
import 'package:dpip/route/event_viewer/thunderstorm.dart';

bool shouldShowArrow(History item) {
  return [
    HistoryType.thunderstorm,
    HistoryType.heavyRain,
    HistoryType.extremelyHeavyRain,
    HistoryType.torrentialRain,
    HistoryType.extremelyTorrentialRain,
    HistoryType.earthquake,
    HistoryType.intensity,
  ].contains(item.type);
}

void handleEventList(BuildContext context, History history) {
  Widget? page;

  switch (history.type) {
    case HistoryType.thunderstorm:
      page = ThunderstormPage(item: history);

    case HistoryType.heavyRain:
      page = ThunderstormPage(item: history);

    case HistoryType.extremelyHeavyRain:
      page = ThunderstormPage(item: history);

    case HistoryType.torrentialRain:
      page = ThunderstormPage(item: history);

    case HistoryType.extremelyTorrentialRain:
      page = ThunderstormPage(item: history);

    case HistoryType.workSchlClos:
      page = ThunderstormPage(item: history);

    case HistoryType.earthquake:
      context.push(
        MapPage.route(
          options: MapPageOptions(initialLayers: {MapLayer.report}, reportId: (history as ReportHistory).addition.id),
        ),
      );

    case HistoryType.intensity:
      page = IntensityPage(item: history as IntensityHistory);
  }

  if (page == null) return;

  Navigator.push(context, MaterialPageRoute(builder: (context) => page!));
}
