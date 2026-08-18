/// Cloudflare status page API — the public `api/v2/components.json` feed.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/features/status/domain/cloudflare_status.dart';

/// Fetches the live Cloudflare component statuses.
///
/// A plain GET through [ApiClient.getAbsolute], so the ETag interceptor
/// revalidates against whatever validator Cloudflare serves and a revisit with
/// no network can read the last good copy from SQLite. The feed is global —
/// no region failover applies.
class CloudflareStatusApi {
  const CloudflareStatusApi(this._client);

  final ApiClient _client;

  static const String url =
      'https://www.cloudflarestatus.com/api/v2/components.json';

  /// Fetches the raw components JSON (a Map) for the repository to map;
  /// throws on transport failure so [guardResult] folds it.
  Future<dynamic> getComponents() => _client.getAbsolute(url);
}

/// Maps the raw Cloudflare reply into a [CloudflareStatus], keeping only the
/// Taipei / Kaohsiung ingress components the app depends on.
///
/// Layout: `{ page: {...}, components: [ { name, status, updated_at, ... } ] }`.
/// Exposed for tests.
CloudflareStatus parseCloudflareStatus(Object? body, {DateTime? at}) {
  final components = (body is Map) ? body['components'] : null;
  final list = switch (components) {
    final List<dynamic> list => list,
    _ => const <dynamic>[],
  };

  final kept = <CloudflareComponent>[];
  for (final raw in list) {
    if (raw is! Map) continue;
    final name = raw['name'];
    final nameStr = name is String ? name : '';
    final lower = nameStr.toLowerCase();
    if (!lower.contains('taipei') && !lower.contains('kaohsiung')) continue;
    final status = raw['status'];
    final updated = raw['updated_at'];
    kept.add(
      CloudflareComponent(
        name: nameStr,
        state: CloudflareComponentState.of(status is String ? status : ''),
        updatedAt: updated is String
            ? (DateTime.tryParse(updated) ??
                  DateTime.fromMillisecondsSinceEpoch(0))
            : DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
  }

  // The status page lists them in stable order; the app wants Taipei first.
  kept.sort((a, b) {
    final aTaipei = a.name.toLowerCase().contains('taipei');
    final bTaipei = b.name.toLowerCase().contains('taipei');
    if (aTaipei != bTaipei) return aTaipei ? -1 : 1;
    return a.name.compareTo(b.name);
  });

  return CloudflareStatus(components: kept, recordedAt: at ?? DateTime.now());
}
