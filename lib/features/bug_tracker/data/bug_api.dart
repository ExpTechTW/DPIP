/// The Discord bug-tracker mirror API.
library;

import 'package:dpip/core/network/api_client.dart';

/// Reads the reported-bug threads from the tracker host.
///
/// Absolute URL on purpose: `bamboo.exptech.dev` is a single host outside the
/// region system, and [ApiClient.getAbsolute] still runs the request through
/// the shared Dio stack — ETag revalidation, the SQLite body store, and
/// transparent gzip decoding when the server sends it.
class BugApi {
  const BugApi(this._client);

  final ApiClient _client;

  static const String _base = 'https://bamboo.exptech.dev/api/dc/bug';

  /// Every thread in the index, capped at 50 so the payload stays bounded as
  /// the tracker grows. The query rides the URL, so the ETag store keys it as
  /// its own resource.
  Future<dynamic> list() =>
      _client.getAbsolute(_base, query: const {'limit': 50});

  /// One thread with its replies.
  Future<dynamic> thread(int id) => _client.getAbsolute('$_base/$id');

  /// Raw avatar bytes through the shared stack — ETag revalidation with the
  /// CDN's own tags, transparent gzip decoding, and the SQLite body store as
  /// the offline copy. Same semantics as every other cacheable GET.
  Future<BytePayload> avatar(String url) => _client.getBytesAbsolute(url);
}
