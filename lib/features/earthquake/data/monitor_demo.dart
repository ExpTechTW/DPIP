/// Debug-only demo feeds for the 強震監視器 (RTS monitor): a synthetic
/// ongoing earthquake whose parameters come from the **latest real report** in
/// the catalogue, so the EEW wavefronts and the detection boxes can be seen on
/// the map without waiting for a real event to happen live. With
/// `kMonitorDemoSevereEnabled`, a fixed severe preset (large magnitude,
/// shallow depth) is used instead, so the high-intensity end of the styling —
/// the EEW card's colour badge, the station dots' red/purple end of the scale
/// — doesn't depend on the newest catalogue row happening to be a big one.
///
/// Enabled at launch with `--dart-define=DPIP_DEMO_MONITOR=true` (debug builds
/// only — the flag is forced off outside `kDebugMode` by
/// `core/build/demo_flags.dart`). Nothing else in the app changes: the demo
/// sources are swapped in exactly where the real SSE sources would be, so every
/// consumer (map layer, monitor panel, home section) sees an ordinary live feed.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:dpip/core/build/demo_flags.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/core/realtime/realtime_source.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_estimator.dart';
import 'package:dpip/features/earthquake/domain/report_repository.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';
import 'package:dpip/features/earthquake/domain/trem_station_repository.dart';
import 'package:dpip/shared/seismic/intensity.dart';

/// The parameters of the demo event, read from the newest catalogue row.
/// Getters (not final fields) so a [load] update is picked up by the next
/// consumer instead of freezing the first-read fallback.
abstract final class MonitorDemo {
  /// Epicentre of the newest report (lng, lat), or Hualien offshore as a
  /// fallback if the catalogue cannot be read.
  static LatLng get epicenter => LatLng(_lat, _lng);

  /// Focal depth (km).
  static double get depth => _depth;

  /// Moment magnitude.
  static double get magnitude => _magnitude;

  /// Read the newest report and keep its epicentre/depth/magnitude — or, with
  /// [kMonitorDemoSevereEnabled], skip the catalogue entirely and use
  /// [_severeMagnitude]/[_severeDepth] at [_severeEpicenter] instead. When the
  /// catalogue is unreachable (and the severe preset isn't requested) the demo
  /// still works — a fixed Hualien offshore event stands in.
  static Future<void> load(ReportRepository repo) async {
    if (kMonitorDemoSevereEnabled) {
      _location = _severeLocation;
      _lng = _severeEpicenter.longitude;
      _lat = _severeEpicenter.latitude;
      _depth = _severeDepth;
      _magnitude = _severeMagnitude;
      _loaded = true;
      _origin = DateTime.now().toUtc();
      Log.debug(
        'monitor demo → severe preset: mag=$_magnitude depth=$_depth '
        '(${_lat.toStringAsFixed(2)}, ${_lng.toStringAsFixed(2)}) $_location',
      );
      return;
    }
    final result = await repo.list(limit: 1);
    final rows = result.valueOrNull;
    if (rows == null || rows.isEmpty) return;
    final report = rows.first;
    _location = report.shortLocation.isEmpty
        ? report.location
        : report.shortLocation;
    _lng = report.longitude;
    _lat = report.latitude;
    _depth = report.depth;
    _magnitude = report.magnitude;
    _loaded = true;
    _origin = DateTime.now().toUtc();
    Log.debug(
      'monitor demo → ${report.id}: mag=$_magnitude depth=$_depth '
      '(${_lat.toStringAsFixed(2)}, ${_lng.toStringAsFixed(2)}) $_location',
    );
  }

  static bool _loaded = false;
  static double _lng = 121.8;
  static double _lat = 23.8;
  static double _depth = 20;
  static double _magnitude = 6.5;
  static String _location = '花蓮縣';

  /// `kMonitorDemoSevereEnabled`'s fixed scenario — M7.5 at 10 km puts the
  /// epicentre itself at CWA discrete level 8 (6強), the practical ceiling of
  /// [EewEstimator]'s near-field model (its distance floor keeps a
  /// zero-distance observer from ever reaching level 9/7).
  static const LatLng _severeEpicenter = LatLng(23.9, 121.7);
  static const double _severeDepth = 10;
  static const double _severeMagnitude = 7.5;
  static const String _severeLocation = '臺東縣';

  /// The report's place name.
  static String get location => _location;

  /// Whether [load] already filled the parameters from a real report.
  static bool get loaded => _loaded;

  /// When the demo event "started" — the moment the app first built an alert.
  /// Re-anchored when [load] pulls the real report, so the synthetic wavefront
  /// looks freshly started rather than a few hundred milliseconds stale.
  static DateTime get origin => _origin ??= DateTime.now().toUtc();

  static DateTime? _origin;
}

/// A single, stable EEW inserted on debug startup for visual testing.
///
/// [RealtimeChannel] continues polling at its normal safety-critical cadence,
/// but every fetch returns this same immutable alert. Its collection equality
/// therefore suppresses every later poll and consumers observe exactly one
/// alert rather than a new serial every second.
class StartupEewDemoSource extends RealtimeSource<List<Eew>> {
  StartupEewDemoSource({DateTime Function()? clock})
    : _alerts = [
        Eew(
          agency: 'DEMO',
          id: 'startup-demo',
          serial: 1,
          status: 0,
          isFinal: false,
          info: EewInfo(
            time: (clock ?? DateTime.now)().toUtc().millisecondsSinceEpoch,
            longitude: 121.7,
            latitude: 23.9,
            depth: 10,
            magnitude: 6.5,
            location: '花蓮縣近海',
            max: 7,
          ),
        ),
      ];

  final List<Eew> _alerts;

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(_alerts);

  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Polls as an always-live EEW alert for [MonitorDemo]'s event, bumping the
/// serial every twelve seconds so the feed visibly updates while leaving even
/// the slower Google zh-TW voice enough time to finish. A two-second demo
/// cadence kept interrupting the phrase at its comma; six seconds still cut
/// the final word after accounting for that engine's startup latency.
class DemoEewSource extends RealtimeSource<List<Eew>> {
  DemoEewSource(this._reports) {
    _alerts = [_build(1)];
    _tick = Timer.periodic(const Duration(seconds: 12), (_) {
      _alerts = [_build(++_serial)];
    });
    unawaited(_loadReport());
  }

  final ReportRepository _reports;
  late List<Eew> _alerts;
  int _serial = 1;
  Timer? _tick;

  Future<void> _loadReport() async {
    await MonitorDemo.load(_reports);
    _alerts = [_build(_serial)];
  }

  Eew _build(int serial) {
    // Peak expected shaking, right at the epicentre (zero epicentral
    // distance) — the same math the map's felt-intensity fill and the EEW
    // cards' local-estimate tiles already trust, so a bigger [MonitorDemo]
    // magnitude visibly changes the card's colour badge instead of always
    // reading level 0.
    final peak = EewEstimator.locationInfo(
      mag: MonitorDemo.magnitude,
      depth: MonitorDemo.depth,
      epicenter: MonitorDemo.epicenter,
      user: MonitorDemo.epicenter,
    );
    return Eew(
      agency: 'DEMO',
      id: 'demo',
      serial: serial,
      status: 0,
      isFinal: false,
      info: EewInfo(
        time: MonitorDemo.origin.millisecondsSinceEpoch,
        longitude: MonitorDemo.epicenter.longitude,
        latitude: MonitorDemo.epicenter.latitude,
        depth: MonitorDemo.depth,
        magnitude: MonitorDemo.magnitude,
        location: MonitorDemo.location,
        max: Intensity.toScale(peak.i),
      ),
    );
  }

  @override
  Future<Result<List<Eew>>> fetch() async => Ok(_alerts);

  /// Fetch-freshness, like the real EEW feed.
  @override
  DateTime? timestampOf(List<Eew> value) => null;

  @override
  bool sameData(List<Eew>? a, List<Eew>? b) {
    if (a == null || b == null) return a == b;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].serial != b[i].serial) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _tick?.cancel();
    _tick = null;
  }
}

/// Polls a ~1 Hz synthetic RTS snapshot: every station shakes according to the
/// demo event's attenuation (with a little jitter so the dots move), and the
/// detection boxes nearest the epicentre light up.
class DemoRtsSource extends RealtimeSource<Rts> {
  DemoRtsSource({required this.stations, required this.grid}) {
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _update());
    _init();
  }

  final TremStationRepository stations;
  final Future<RtsBoxGrid> grid;

  Timer? _tick;
  bool _ready = false;
  Map<String, SeismicStation> _directory = const {};
  RtsBoxGrid? _boxes;
  Rts _latest = const Rts();

  Future<void> _init() async {
    final directory = (await stations.stations()).valueOrNull ?? const {};
    final boxes = await grid;
    _directory = directory;
    _boxes = boxes;
    _ready = true;
    _update();
  }

  void _update() {
    if (!_ready) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    final stations = <String, RtsStation>{};
    _directory.forEach((id, station) {
      final est = EewEstimator.locationInfo(
        mag: MonitorDemo.magnitude,
        depth: MonitorDemo.depth,
        epicenter: MonitorDemo.epicenter,
        user: LatLng(station.latitude, station.longitude),
      );
      final i = est.i + _jitter(id, now);
      stations[id] = RtsStation(
        pga: i,
        pgv: i,
        intensityRaw: i,
        intensity: i,
        alert: i >= 4,
      );
    });

    // Boxes within ~120 km of the epicentre, brighter the closer they are —
    // the same `Rts.box` shape a large event's feed carries, so the map's
    // box-grid overlay draws them.
    final box = <String, dynamic>{};
    _boxes?.rings.forEach((id, ring) {
      var lat = 0.0;
      var lng = 0.0;
      for (final point in ring.take(4)) {
        lat += point[1];
        lng += point[0];
      }
      lat /= 4;
      lng /= 4;
      final dist = MonitorDemo.epicenter.distanceTo(LatLng(lat, lng)) / 1000;
      if (dist < 120) {
        box['$id'] = (6 - dist / 30).clamp(1, 6).round();
      }
    });

    _latest = Rts(station: stations, box: box, time: now);
    Log.debug(
      'monitor demo rts → ${stations.length} stations, ${box.length} boxes, '
      'mag=${MonitorDemo.magnitude}',
    );
  }

  /// Deterministic per-station shimmer so the dots move between polls without
  /// anything global.
  double _jitter(String id, int nowMs) {
    final phase = nowMs ~/ 1000;
    return math.sin((id.hashCode ^ phase).toDouble()) * 0.3;
  }

  @override
  Future<Result<Rts>> fetch() async => Ok(_latest);

  /// Fetch-freshness; the real feed keys off event recency, but a poll source
  /// staying fresh is what matters here.
  @override
  DateTime? timestampOf(Rts value) => null;

  @override
  void dispose() {
    _tick?.cancel();
    _tick = null;
  }
}
