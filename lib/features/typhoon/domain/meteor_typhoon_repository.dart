/// Access to v5 meteor typhoon data (four CWA datasets + history + overlays).
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_kind.dart';
import 'package:dpip/features/typhoon/domain/typhoon_potential.dart';
import 'package:dpip/features/typhoon/domain/typhoon_probability.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';

/// Typhoon data from the v5 meteor API. Every fetch returns a [Result] so a
/// failed fetch/decode is explicit (never a silently blank typhoon view); the
/// impl in `data/` maps transport/decode errors to a typed `Failure`.
abstract interface class MeteorTyphoonRepository {
  /// The in-progress cyclone index (`cyclones` empty when none are active).
  Future<Result<CycloneIndex>> cyclones();

  /// The latest track dataset (past/present/forecast fixes + storm circles).
  Future<Result<TrackPayload>> track();

  /// The latest track-potential dataset (paths, cone, forecast points).
  Future<Result<TyphoonPotential>> potential();

  /// The latest strike-probability contours.
  Future<Result<TyphoonProbability>> probability();

  /// The latest warning bulletin.
  Future<Result<TyphoonWarning>> warning();

  /// Available history snapshot times for [kind] (Unix seconds, ascending);
  /// `Ok([])` when none.
  Future<Result<List<int>>> history(TyphoonKind kind);

  /// The historical track snapshot at [second].
  Future<Result<TrackPayload>> trackAt(int second);

  /// The historical potential snapshot at [second].
  Future<Result<TyphoonPotential>> potentialAt(int second);

  /// The historical probability snapshot at [second].
  Future<Result<TyphoonProbability>> probabilityAt(int second);

  /// The historical warning bulletin sent at [second].
  Future<Result<TyphoonWarning>> warningAt(int second);

  /// The overlay GeoJSON `FeatureCollection` (potential + probability), for
  /// direct map rendering.
  Future<Result<Map<String, dynamic>>> geojson();

  /// Available track-image times (Unix seconds); `Ok([])` when none.
  Future<Result<List<int>>> images();

  /// The concrete URL of the track-image PNG at [second] — fetched directly
  /// (e.g. by an image widget), not a decoded model.
  String imageUrl(int second);
}
