/// ExpTech status dashboard API — the Grafana `/ds/query` endpoint.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/features/status/domain/server_status.dart';

/// Fetches the live status snapshot from Grafana via a constant query.
///
/// The query body is fixed at compile time, so the URL pins the content — the
/// ETag interceptor caches it as an immutable tile (URL-keyed, unconditional
/// store). A revisit that still has network gets the current numbers; a revisit
/// without one could read the SQLite copy straight from the interceptor.
class ServerStatusApi {
  const ServerStatusApi(this._client);

  final ApiClient _client;

  static const String url = 'https://status.exptech.dev/api/ds/query';

  /// The query the More → 伺服器狀態 screen runs. "now-1m…now" is irrelevant
  /// for instant queries; each refId resolves to one scalar in
  /// `results.<refId>.frames[0].data.values[1][0]`.
  static const Map<String, Object> query = {
    'queries': [
      {
        'refId': 'status',
        'datasource': {'uid': 'PBFA97CFB590B2093'},
        'expr': 'count(up{job="nginx"} == 0) or vector(0)',
        'instant': true,
      },
      {
        'refId': 'error_rate_5xx',
        'datasource': {'uid': 'PBFA97CFB590B2093'},
        'expr':
            'topk(1, 100 * sum by (instance) '
            '(rate(nginx_http_responses_total{code="5xx"}[1m])) / '
            'clamp_min(sum by (instance) '
            '(rate(nginx_http_responses_total[1m])), 0.001))',
        'instant': true,
      },
      {
        'refId': 'avg_latency',
        'datasource': {'uid': 'PBFA97CFB590B2093'},
        'expr':
            'topk(1, 1000 * sum by (instance) '
            '(rate(nginx_http_request_duration_seconds_total[1m])) / '
            'clamp_min(sum by (instance) '
            '(rate(nginx_http_requests_total[1m])), 0.001))',
        'instant': true,
      },
    ],
    'from': 'now-1m',
    'to': 'now',
  };

  /// Fetches the snapshot. Returns the raw decoded JSON (a Map) for the
  /// repository to map; throws on transport failure so [guardResult] folds it.
  Future<dynamic> getStatus() => _client.postAbsolute(
    url,
    data: query,
    headers: const {'Content-Type': 'application/json'},
  );
}

/// Maps the raw Grafana reply into a [ServerStatus] — the three refIds each
/// carry a single scalar plus an optional `instance` label.
///
/// Layout, per refId: `results.<refId>.frames[0].data.values[1][0]` is the
/// value and `results.<refId>.frames[0].schema.fields[1].labels.instance` the
/// host. Exposed for tests.
ServerStatus parseStatus(Object? body, {DateTime? at}) {
  final results = (body is Map) ? body['results'] : null;
  if (results is! Map) {
    throw const FormatException('status dashboard: missing results');
  }
  num scalar(String refId) {
    final frame = _frame(results[refId]);
    final values = frame['data']?['values'];
    if (values is! List || values.length < 2) return 0;
    final row = values[1];
    if (row is! List || row.isEmpty) return 0;
    final raw = row[0];
    if (raw == null) return 0;
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw) ?? 0;
    return 0;
  }

  String? instance(String refId) {
    final frame = _frame(results[refId]);
    final fields = frame['schema']?['fields'];
    if (fields is! List || fields.length < 2) return null;
    final labels = fields[1]?['labels'];
    if (labels is! Map) return null;
    final name = labels['instance'];
    return name is String ? name : null;
  }

  return ServerStatus(
    recordedAt: at ?? DateTime.now(),
    down: StatusMetric(value: scalar('status')),
    errorRate: StatusMetric(
      value: scalar('error_rate_5xx'),
      // The curl one-liner multiplies by 100, so the rate is a percent.
      instance: instance('error_rate_5xx'),
    ),
    latency: StatusMetric(
      value: scalar('avg_latency'),
      instance: instance('avg_latency'),
    ),
  );
}

Map<String, dynamic> _frame(Object? entry) {
  if (entry is! Map) return const {};
  final frames = entry['frames'];
  if (frames is! List || frames.isEmpty) return const {};
  final frame = frames.first;
  return frame is Map ? Map<String, dynamic>.from(frame) : const {};
}
