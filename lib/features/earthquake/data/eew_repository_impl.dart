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
  const EewRepositoryImpl(this._api);

  final EarthquakeApi _api;

  @override
  Future<Result<List<Eew>>> activeEews() => guardResult(() async {
    final raw = await _api.getEewRealtime();
    return [for (final item in raw) Eew.fromJson(item as Map<String, dynamic>)];
  });
}
