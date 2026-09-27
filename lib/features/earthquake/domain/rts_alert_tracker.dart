/// Turns a stream of RTS frames into what the monitor shows beyond the dots:
/// the areas the latest frame lights, and the minute-long township ranking.
///
/// One per monitor surface (the live map, a replay page), fed each frame the
/// surface receives. Shared domain logic because both surfaces must light the
/// same boxes and rank the same townships from the same frame — and neither may
/// import the other's presentation.
library;

import 'package:dpip/core/geo/town.dart';
import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_alert_areas.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/rts_town_peaks.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

class RtsAlertTracker {
  Map<String, SeismicStation> _stations = const {};
  RtsBoxGrid? _grid;
  Map<String, StationArea> _areas = const {};
  final RtsTownPeaks _peaks = RtsTownPeaks();
  Rts? _lastFrame;

  RtsAlertAreas _current = RtsAlertAreas.none;

  /// Whether the feed was live at the last [track].
  bool _live = false;
  Map<String, int> _ranked = const {};

  /// The areas the latest frame lights; [RtsAlertAreas.none] while calm.
  RtsAlertAreas get areas => _current;

  /// Whether the latest frame has any alerting station on the grid — the
  /// monitor's "a large event is under way" signal.
  bool get alerting => _current.boxes.isNotEmpty;

  /// The stations the frames are placed against.
  Map<String, SeismicStation> get stations => _stations;

  /// Sets the station directory (and, once loaded, the box grid) the frames
  /// are placed against. Recomputes each station's area only when either one
  /// actually changed.
  void place({Map<String, SeismicStation>? stations, RtsBoxGrid? grid}) {
    final nextStations = stations ?? _stations;
    final nextGrid = grid ?? _grid;
    if (identical(nextStations, _stations) && identical(nextGrid, _grid)) {
      return;
    }
    _stations = nextStations;
    _grid = nextGrid;
    _areas = stationAreas(
      _stations,
      nextGrid ?? const RtsBoxGrid(<int, List<List<double>>>{}),
    );
    // The frame already in hand now lights what it should have lit — and,
    // placed at last, counts toward the ranking it could not reach before.
    final frame = _lastFrame;
    if (frame != null && _live) {
      _current = rtsAlertAreas(frame.stations, _areas);
      _ranked = _peaks.update(_current.towns, frame.time);
    }
  }

  /// Takes the feed's latest [state]. Only a **live** feed lights anything: a
  /// stale or offline frame is not the ground's shaking now, and lighting
  /// boxes from it would present aged safety data as current. The ranking
  /// keeps what it holds until its window runs out, as TREM-Lite's does
  /// through a lost frame.
  void track(RealtimeState<Rts> state) {
    final frame = state.data;
    if (frame == null || state.status != RealtimeStatus.live) {
      _live = false;
      _current = RtsAlertAreas.none;
      return;
    }
    _live = true;
    // A status recompute re-notifies with the same frame; it must not count
    // it into the window twice. A frame that went stale and came back live is
    // lit again, though — going stale unlit it.
    if (identical(frame, _lastFrame)) {
      _current = rtsAlertAreas(frame.stations, _areas);
      return;
    }
    _lastFrame = frame;
    _current = rtsAlertAreas(frame.stations, _areas);
    // A calm frame still advances the window, or a township would hold its
    // peak forever once its stations stopped alerting.
    _ranked = _peaks.update(_current.towns, frame.time);
  }

  /// The 震度排行 rows, strongest first — empty when nothing has shaken in the
  /// last minute.
  List<RtsRankingRow> ranking(Town? Function(String code) townOf) =>
      rtsRanking(_ranked, townOf);

  /// Forgets the window — for a replay that jumps to another event.
  void reset() {
    _peaks.clear();
    _ranked = const {};
    _current = RtsAlertAreas.none;
    _lastFrame = null;
    _live = false;
  }
}
