import 'package:dpip/models/settings/notify.dart';

class NotifySettings {
  final EewNotifyType eew;
  final EarthquakeNotifyType monitor;
  final EarthquakeNotifyType report;
  final EarthquakeNotifyType intensity;
  final WeatherNotifyType thunderstorm;
  final WeatherNotifyType weatherAdvisory;
  final WeatherNotifyType evacuation;
  final TsunamiNotifyType tsunami;
  final BasicNotifyType announcement;

  NotifySettings({
    required this.eew,
    required this.monitor,
    required this.report,
    required this.intensity,
    required this.thunderstorm,
    required this.weatherAdvisory,
    required this.evacuation,
    required this.tsunami,
    required this.announcement,
  });

  factory NotifySettings.fromJson(List<int> json) {
    return NotifySettings(
      eew: EewNotifyType.values[json[NotifyChannel.eew.index]],
      monitor: EarthquakeNotifyType.values[json[NotifyChannel.monitor.index]],
      report: EarthquakeNotifyType.values[json[NotifyChannel.report.index]],
      intensity: EarthquakeNotifyType.values[json[NotifyChannel.intensity.index]],
      thunderstorm: WeatherNotifyType.values[json[NotifyChannel.thunderstorm.index]],
      weatherAdvisory: WeatherNotifyType.values[json[NotifyChannel.weatherAdvisory.index]],
      evacuation: WeatherNotifyType.values[json[NotifyChannel.evacuation.index]],
      tsunami: TsunamiNotifyType.values[json[NotifyChannel.tsunami.index]],
      announcement: BasicNotifyType.values[json[NotifyChannel.announcement.index]],
    );
  }

  List<int> toJson() {
    return [
      eew.index,
      monitor.index,
      report.index,
      intensity.index,
      thunderstorm.index,
      weatherAdvisory.index,
      evacuation.index,
      tsunami.index,
      announcement.index,
    ];
  }
}
