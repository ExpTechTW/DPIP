import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/announcement_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/earthquake_report_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/eew_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/meteor_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/ncdr_alert_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/rain_advisory_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/station_missing_detail.dart';
import 'package:dpip/features/events/presentation/detail/types/tsunami_detail.dart';

/// The family that draws a card of [type] on the detail page.
///
/// Types sharing a family share the shape of their `addition` (the server's
/// api.md §5). Anything else, including a type the server adds later, gets
/// [GenericEventDetail].
EventTypeDetail eventTypeDetailFor(String type) => switch (type) {
  'earthquake.eew' || 'earthquake.eew.alert' => const EewDetail(),
  // Where shaking was detected, not an estimate of an earthquake: no
  // epicentre, depth or intensity to show, so the plain detail.
  'earthquake.detection' => const GenericEventDetail(),
  'earthquake' ||
  'tsunami_note' ||
  'intensity' => const EarthquakeReportDetail(),
  'earthquake.station_missing' => const StationMissingDetail(),
  'tsunami.warning' || 'tsunami.info' => const TsunamiDetail(),
  'heavy-rain' ||
  'extremely-heavy-rain' ||
  'torrential-rain' ||
  'extremely-torrential-rain' => const RainAdvisoryDetail(),
  'heavy_rain.short' ||
  'heavy_rain.short_extreme' ||
  'wind.strong' ||
  'wind.damaging' ||
  'thunderstorm.lightning' ||
  'river_rise.watch' ||
  'river_rise.warning' ||
  'fog.visibility' => const MeteorDetail(),
  'thunderstorm' ||
  'seawave' ||
  'workSchlClos' ||
  'debrisFlowLandSlide' ||
  'roadClose' ||
  'floodSensor' ||
  'barrierLake' => const NcdrAlertDetail(),
  'announcement' => const AnnouncementDetail(),
  _ => const GenericEventDetail(),
};

/// Every type with a family, as the server's api.md lists them. The tests
/// check each one resolves to a family rather than the generic detail.
const List<String> eventTypesWithDetail = [
  'earthquake.eew',
  'earthquake.eew.alert',
  'earthquake',
  'tsunami_note',
  'intensity',
  'earthquake.station_missing',
  'tsunami.warning',
  'tsunami.info',
  'heavy-rain',
  'extremely-heavy-rain',
  'torrential-rain',
  'extremely-torrential-rain',
  'heavy_rain.short',
  'heavy_rain.short_extreme',
  'wind.strong',
  'wind.damaging',
  'thunderstorm.lightning',
  'river_rise.watch',
  'river_rise.warning',
  'fog.visibility',
  'thunderstorm',
  'seawave',
  'workSchlClos',
  'debrisFlowLandSlide',
  'roadClose',
  'floodSensor',
  'barrierLake',
  'announcement',
];
