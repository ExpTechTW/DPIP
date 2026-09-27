/// Turns a stream of RTS frames into what the monitor shows beyond the dots:
/// the areas the latest frame lights.
///
/// One per monitor surface (the live map, a replay page), fed each frame the
/// surface receives. Shared domain logic because both surfaces must light the
/// same boxes from the same frame — and neither may import the other's
/// presentation.
library;

import 'package:dpip/core/realtime/realtime_state.dart';
import 'package:dpip/features/earthquake/domain/rts.dart';
import 'package:dpip/features/earthquake/domain/rts_alert_areas.dart';
import 'package:dpip/features/earthquake/domain/rts_box_grid.dart';
import 'package:dpip/features/earthquake/domain/seismic_station.dart';

class RtsAlertTracker {
  Map<String, SeismicStation> _stations = const {};
  RtsBoxGrid? _grid;
  Map<String, StationArea> _areas = const {};
  Rts? _lastFrame;

  RtsAlertAreas _current = RtsAlertAreas.none;

  /// Whether the feed was live at the last [track].
  bool _live = false;

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
    // The frame already in hand now lights what it should have lit.
    final frame = _lastFrame;
    if (frame != null && _live) {
      _current = rtsAlertAreas(frame.stations, _areas);
    }
  }

  /// Takes the feed's latest [state]. Only a **live** feed lights anything: a
  /// stale or offline frame is not the ground's shaking now, and lighting
  /// boxes from it would present aged safety data as current.
  void track(RealtimeState<Rts> state) {
    final frame = state.data;
    if (frame == null || state.status != RealtimeStatus.live) {
      _live = false;
      _current = RtsAlertAreas.none;
      return;
    }
    _live = true;
    _lastFrame = frame;
    _current = rtsAlertAreas(frame.stations, _areas);
  }

  /// Forgets the frame in hand — for a replay that jumps to another event.
  void reset() {
    _current = RtsAlertAreas.none;
    _lastFrame = null;
    _live = false;
  }
}
