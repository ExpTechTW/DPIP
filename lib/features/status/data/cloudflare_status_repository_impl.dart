/// [CloudflareStatusRepository] backed by the Cloudflare status page API.
library;

import 'package:dpip/core/error/result.dart';
import 'package:dpip/core/network/api_exception.dart';
import 'package:dpip/features/status/data/cloudflare_status_api.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';
import 'package:dpip/features/status/domain/cloudflare_status_repository.dart';

class CloudflareStatusRepositoryImpl implements CloudflareStatusRepository {
  const CloudflareStatusRepositoryImpl(this._api);

  final CloudflareStatusApi _api;

  @override
  Future<Result<CloudflareStatus>> status() => guardResult(() async {
    final body = await _api.getComponents();
    return parseCloudflareStatus(body);
  });
}
