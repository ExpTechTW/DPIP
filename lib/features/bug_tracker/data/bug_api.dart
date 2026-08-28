/// The Discord bug-tracker mirror API.
library;

import 'package:dpip/core/network/api_client.dart';

/// The forum tag that marks a thread as about THIS app. A routing marker, not
/// a category — it is filtered on, both by the server and again here, and
/// never rendered.
const String appBugTag = 'dpip';

/// Reads the reported-bug threads from the tracker host.
///
/// Absolute URL on purpose: `bamboo.exptech.dev` is a single host outside the
/// region system, and [ApiClient.getAbsolute] still runs the request through
/// the shared Dio stack — ETag revalidation, the SQLite body store, and
/// transparent gzip decoding when the server sends it.
class BugApi {
  const BugApi(this._client);

  final ApiClient _client;

  static const String _base = 'https://bamboo.exptech.dev/api/v1/dc/bug';

  /// Every thread in the index, capped at 50 so the payload stays bounded as
  /// the tracker grows. The query rides the URL, so the ETag store keys it as
  /// its own resource.
  ///
  /// `tag` asks the server for this app's threads only. It matters for the cap
  /// as much as for correctness: the tracker is shared with other products, so
  /// an unfiltered page of 50 spends some of its rows on threads this app then
  /// throws away — measured against the live index, 3 of 50.
  Future<dynamic> list() =>
      _client.getAbsolute(_base, query: const {'limit': 50, 'tag': appBugTag});

  /// One thread with its replies.
  Future<dynamic> thread(int id) => _client.getAbsolute('$_base/$id');

  /// Raw avatar bytes through the shared stack — ETag revalidation with the
  /// CDN's own tags, transparent gzip decoding, and the SQLite body store as
  /// the offline copy. Same semantics as every other cacheable GET.
  Future<BytePayload> avatar(String url) => _client.getBytesAbsolute(url);
}
