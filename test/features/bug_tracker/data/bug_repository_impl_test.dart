/// The repository, not just the parser: a non-object where the tracker
/// promised an object has to fail the fetch, and avatar bytes have to survive
/// the trip. Swallowing a broken index would shorten the bug list with no
/// error.
library;

import 'dart:typed_data';

import 'package:dpip/core/error/failure.dart';
import 'package:dpip/core/network/api_client.dart';
import 'package:dpip/features/bug_tracker/data/bug_api.dart';
import 'package:dpip/features/bug_tracker/data/bug_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api implements BugApi {
  Object? index = {
    'users': {
      '1': {'name': '陳', 'img': 'https://cdn.example/a.png'},
    },
    'threads': [
      {
        'threads_id': 9,
        'title': 't',
        'tags': ['dpip', 'bug'],
        'body': 'hello <:wave:1>',
        'author': 1,
        'created_at': 1787511150,
        'locked': false,
        'last_message_id': 9,
      },
    ],
  };
  Object? detail = {
    'users': {
      '1': {'name': '陳', 'img': ''},
    },
    'threads_id': 9,
    'title': 't',
    'tags': ['dpip'],
    'body': 'b',
    'author': 1,
    'created_at': 1787511150,
    'locked': false,
    'last_message_id': 9,
    'msg': [
      {'id': 1, 'author': 1, 'msg': 'reply', 'time': 1787512586},
    ],
  };
  String? avatarUrl;

  @override
  Future<dynamic> list() async => index;

  @override
  Future<dynamic> thread(int id) async => detail;

  @override
  Future<BytePayload> avatar(String url) async {
    avatarUrl = url;
    return BytePayload(bytes: Uint8List.fromList([9, 8]));
  }
}

void main() {
  test('threads, a thread, and an avatar all come back decoded', () async {
    final api = _Api();
    final repo = BugRepositoryImpl(api);

    final threads = await repo.threads();
    final detail = await repo.thread(9);
    final bytes = await repo.avatar('https://cdn.example/a.png');

    expect(threads.valueOrNull!.single.authorName, '陳');
    expect(threads.valueOrNull!.single.body, contains(':wave:'));
    expect(detail.valueOrNull!.messages.single.body, 'reply');
    expect(api.avatarUrl, 'https://cdn.example/a.png');
    expect(bytes.valueOrNull, [9, 8]);
  });

  test('a thread entry that is not an object fails the index', () async {
    final api = _Api()
      ..index = {
        'threads': ['nope'],
      };
    final result = await BugRepositoryImpl(api).threads();
    expect(result.failureOrNull, isA<DecodeFailure>());
  });
}
