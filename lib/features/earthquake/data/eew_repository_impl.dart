import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/earthquake/data/earthquake_api.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';

/// [EewRepository] backed by the region-aware [EarthquakeApi].
///
/// Owns the JSON→model mapping and converts transport/decode errors into typed
/// [Failure]s via [guardResult], so nothing above the data layer touches raw
/// JSON or `dio`.
class EewRepositoryImpl implements EewRepository {
  /// [cwaOnly] is read fresh on every [activeEews] call (a closure, not a
  /// captured bool) so toggling `EewCwaOnlySettings` takes effect immediately.
  const EewRepositoryImpl(this._api, {required this.cwaOnly});

  final EarthquakeApi _api;
  final bool Function() cwaOnly;

  @override
  Future<Result<List<Eew>>> activeEews() => guardResult(() async {
    final raw = await _api.getEewRealtime();
    final all = [
      for (final item in raw) Eew.fromJson(item as Map<String, dynamic>),
    ];
    final onlyCwa = cwaOnly();
    return [
      for (final e in all)
        if (!e.isJma && (!onlyCwa || e.isCwa)) e,
    ];
  });
}
