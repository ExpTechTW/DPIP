import 'package:dpip/api/redundant_api.dart';
import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/earthquake/domain/eew.dart';
import 'package:dpip/features/earthquake/domain/eew_repository.dart';

/// [EewRepository] backed by the region-aware [RedundantApi].
///
/// Owns the JSON→model mapping and converts transport/decode errors into typed
/// [Failure]s via [mapException], so nothing above the data layer touches raw
/// JSON or `dio`.
class EewRepositoryImpl implements EewRepository {
  const EewRepositoryImpl(this._api);

  final RedundantApi _api;

  @override
  Future<Result<List<Eew>>> activeEews() async {
    try {
      final raw = await _api.getEewRealtime();
      return Ok([
        for (final item in raw) Eew.fromJson(item as Map<String, dynamic>),
      ]);
    } catch (error) {
      return Err(mapException(error));
    }
  }
}
