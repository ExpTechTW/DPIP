import 'dart:convert';

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/platform/widget_snapshot_writer.dart';
import 'package:dpip/features/weather/domain/current_weather_widget_snapshot.dart';

final class CurrentWeatherWidgetPublisher {
  const CurrentWeatherWidgetPublisher(this._writer);

  final WidgetSnapshotWriter _writer;

  Future<Result<void>> publish(CurrentWeatherWidgetSnapshot snapshot) {
    final json = jsonEncode(snapshot.toJson());

    return _writer.write(
      kind: WidgetSnapshotKind.currentWeather,
      json: json,
      sourceIdentifier: snapshot.sourceIdentifier,
    );
  }

  Future<Result<void>> clear() {
    return _writer.clear(kind: WidgetSnapshotKind.currentWeather);
  }
}
