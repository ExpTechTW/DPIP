/// [ServerStatusRepository] backed by the Grafana dashboard API.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/status/data/server_status_api.dart';
import 'package:dpip/features/status/domain/server_status.dart';
import 'package:dpip/features/status/domain/server_status_repository.dart';

class ServerStatusRepositoryImpl implements ServerStatusRepository {
  const ServerStatusRepositoryImpl(this._api);

  final ServerStatusApi _api;

  @override
  Future<Result<ServerStatus>> status() => guardResult(() async {
    final body = await _api.getStatus();
    return parseStatus(body);
  });
}
