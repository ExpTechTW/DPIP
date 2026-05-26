/// 風向卡。
library;

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/app/home/_widgets/wind_card.dart';
import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wind extends StatelessWidget {
  /// 繼承 [HomeModel]
  const Wind({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, RealtimeWeather?>(
      selector: (_, m) => m.weather,
      builder: (context, weather, _) {
        if (weather == null) return const SizedBox.shrink();
        return WindCard(weather);
      },
    );
  }
}
