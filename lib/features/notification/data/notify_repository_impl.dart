/// [NotifyRepository] backed by the region-aware [NotifyApi].
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/notification/data/notify_api.dart';
import 'package:dpip/features/notification/domain/notify_repository.dart';
import 'package:dpip/features/notification/domain/notify_settings.dart';

/// Owns the wire-list → [NotifySettings] mapping and converts transport/decode
/// errors into typed [Failure]s via [guardResult], so presentation never sees a
/// raw `DioException` or a malformed list.
class NotifyRepositoryImpl implements NotifyRepository {
  const NotifyRepositoryImpl(this._api);

  final NotifyApi _api;

  @override
  Future<Result<NotifySettings>> fetch(String token) =>
      guardResult(() async => _map(await _api.getNotify(token)));

  @override
  Future<Result<NotifySettings>> setChannel(
    String token,
    NotifyChannel channel,
    int optionIndex,
  ) => guardResult(
    () async => _map(await _api.setNotify(token, channel.index, optionIndex)),
  );

  NotifySettings _map(List<dynamic> raw) =>
      NotifySettings.fromWire(raw.cast<int>());
}
