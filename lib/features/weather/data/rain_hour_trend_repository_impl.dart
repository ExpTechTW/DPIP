/// [RainHourTrendRepository] backed by [RainHourTrendApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/weather/data/rain_hour_trend_api.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend.dart';
import 'package:dpip/features/weather/domain/rain_hour_trend_repository.dart';

/// Maps the datasource's raw envelope to [RainHourTrend], converting
/// transport/decode errors to typed failures via [guardResult].
class RainHourTrendRepositoryImpl implements RainHourTrendRepository {
  const RainHourTrendRepositoryImpl(this._api);

  final RainHourTrendApi _api;

  @override
  Future<Result<RainHourTrend>> hourTrend(String code) => guardResult(
    () async => RainHourTrend.decode(await _api.getForecast(code)),
  );
}
