/// Uploads a diagnostics dump to ExpTech's paste service.
library;

import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/core/diagnostics/dump_uploader.dart';

/// Posts a dump and returns the URL to read it at.
///
/// A paste rather than an attachment because of where these end up: a bug
/// report in Discord or an issue, where tens of thousands of characters of log
/// pasted inline buries everything around it and an attached file is not read
/// at all.
class HasteApi implements DumpUploader {
  const HasteApi(this._client);

  final ApiClient _client;

  static const String _endpoint = 'https://haste.exptech.dev/api/pastes';

  /// `https://haste.exptech.dev/<key>`, or null when the reply carried no key.
  ///
  /// Absolute URL and no tier: this is not one of the app's regional APIs, so
  /// it has no failover and no ETag revalidation to take part in.
  @override
  Future<String?> upload(String content) async {
    final body = await _client.postAbsolute(
      _endpoint,
      data: {'content': content, 'language': 'log'},
      headers: const {'Content-Type': 'application/json'},
    );
    if (body is! Map) return null;
    // Built from `key` rather than taken from `url`, because the service
    // answers with `http://` — and a plain-HTTP link is the wrong thing to
    // hand somebody along with a diagnostics dump.
    final key = body['key'];
    if (key is String && key.isNotEmpty) {
      return 'https://haste.exptech.dev/$key';
    }
    final url = body['url'];
    return url is String && url.isNotEmpty
        ? url.replaceFirst(RegExp('^http://'), 'https://')
        : null;
  }
}
