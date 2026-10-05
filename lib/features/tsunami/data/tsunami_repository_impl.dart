/// [TsunamiRepository] backed by the CWA tsunami API.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/tsunami/data/tsunami_api.dart';
import 'package:dpip/features/tsunami/domain/tsunami_report.dart';
import 'package:dpip/features/tsunami/domain/tsunami_repository.dart';

/// Maps the index rows to [TsunamiBulletin]s and the detail payload to a
/// [TsunamiReport], converting transport/decode errors to typed failures via
/// [guardResult].
class TsunamiRepositoryImpl implements TsunamiRepository {
  const TsunamiRepositoryImpl(this._api);

  final TsunamiApi _api;

  @override
  Future<Result<List<TsunamiBulletin>>> bulletins() => guardResult(() async {
    final index = await _api.getReports();
    return TsunamiBulletin.newestEvent((index['reports'] as List?) ?? const []);
  });

  @override
  Future<Result<TsunamiReport>> report(String id) =>
      guardResult(() async => TsunamiReport.decode(await _api.getReport(id)));
}
