/// The bug-tracker wire → domain parsers, against payloads shaped like the
/// live tracker's updated contract (2026-08-24): a `users` directory keyed by
/// Discord snowflake plus `threads`/`msg` entries that reference it by id.
library;

import 'package:dpip/features/bug_tracker/data/bug_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

const _chenId = 1470269242916999282;
const _staffId = 879008115696230430;

Map<String, Object> _user(int id, String name) => {
  'name': name,
  'img': 'https://cdn.discordapp.com/avatars/$id/x.png',
};

void main() {
  test('the index parses into threads and resolves authors', () {
    final threads = parseBugThreads({
      'users': {_chenId: _user(_chenId, '陳')},
      'threads': [
        {
          'threads_id': 1541158207970349066,
          'title': 'ET-2026-0122 DPIP3.9過段時間，程式會重製',
          'tags': ['DPIP', '臭蟲 bug'],
          'body': '我的dpip放一段時間，在按進去它就會回到是否同意以上...',
          'author': _chenId,
          'created_at': 1787511150,
          'message_count': 2,
          'archived': false,
          'locked': false,
          'last_message_id': 1541358858713178132,
        },
      ],
    });

    expect(threads, hasLength(1));
    expect(threads.first.id, 1541158207970349066);
    // The routing marker is stripped; the bilingual label keeps its head.
    expect(threads.first.tags, ['臭蟲']);
    expect(threads.first.authorName, '陳');
    expect(
      threads.first.createdAt.toUtc(),
      DateTime.utc(2026, 8, 23, 18, 52, 30),
    );
  });

  test('threads without the DPIP routing tag are dropped', () {
    Map<String, Object> thread(int id, List<String> tags) => {
      'threads_id': id,
      'title': 't$id',
      'tags': tags,
      'body': 'b',
      'author': _chenId,
      'created_at': 1787511150,
      'last_message_id': id,
    };

    final threads = parseBugThreads({
      'users': {},
      'threads': [
        thread(1, ['DPIP']),
        thread(2, <String>[]),
        thread(3, ['OTHER']),
      ],
    });

    expect([for (final t in threads) t.id], [1]);
  });

  test('the index is ordered by last activity, not source order', () {
    Map<String, Object> thread(int id) => {
      'threads_id': id,
      'title': 't$id',
      'tags': ['DPIP'],
      'body': 'b',
      'author': _chenId,
      'created_at': 1787511150,
      'last_message_id': 1000000 + id,
    };

    // Arrives out of order; the newest conversation leads.
    final threads = parseBugThreads({
      'users': {},
      'threads': [thread(3), thread(1), thread(2)],
    });

    expect([for (final t in threads) t.id], [3, 2, 1]);
  });

  test('locked threads are hidden from the index', () {
    Map<String, Object> thread(int id, {required bool locked}) => {
      'threads_id': id,
      'title': 't$id',
      'tags': ['DPIP'],
      'body': 'b',
      'author': _chenId,
      'created_at': 1787511150,
      'locked': locked,
      'last_message_id': id,
    };

    final threads = parseBugThreads({
      'users': {},
      'threads': [thread(1, locked: false), thread(2, locked: true)],
    });

    expect([for (final t in threads) t.id], [1]);
  });

  test('a deleted opening post arrives as null and reads as empty', () {
    // Discord lets an author delete the OP while the thread survives; the
    // mirror then carries "body": null. One such thread must not kill the
    // whole index.
    final threads = parseBugThreads({
      'users': {},
      'threads': [
        {
          'threads_id': 9,
          'title': 't9',
          'tags': ['DPIP'],
          'body': null,
          'author': _chenId,
          'created_at': 1787511150,
          'locked': false,
          'last_message_id': 9,
        },
      ],
    });

    expect(threads, hasLength(1));
    expect(threads.first.body, isEmpty);
    expect(threads.first.title, 't9');
  });

  test('Discord custom-emote tokens are normalised to :name:', () {
    final staff = _staffId;
    final detail = parseBugThreadDetail({
      ..._threadShell(id: 1541158207970349066, author: staff),
      'msg': [
        {
          'id': 1541164231909576726,
          'author': _staffId,
          'msg':
              '建議提供設備型號 <:biliPleased:927265154171813958> 與 '
              '<a:shake:12345> 資訊',
          'time': 1787512586,
        },
      ],
    });

    expect(detail.messages, hasLength(1));
    expect(detail.messages.first.body, '建議提供設備型號 :biliPleased: 與 :shake: 資訊');
  });

  test('a reply without renderable text keeps a null body', () {
    final detail = parseBugThreadDetail({
      ..._threadShell(id: 1541158207970349066, author: staff0()),
      'msg': [
        {'id': 1, 'author': _staffId, 'msg': null, 'time': 1787512586},
      ],
    });

    expect(detail.messages.single.body, isNull);
  });
}

int staff0() => 879008115696230430;

Map<String, Object> _threadShell({required int id, required int author}) => {
  'threads_id': id,
  'title': 't$id',
  'tags': ['DPIP'],
  'body': 'b',
  'author': author,
  'created_at': 1787511150,
  'message_count': 1,
  'locked': false,
  'last_message_id': id,
  'users': {
    author: {'name': 'a', 'img': ''},
  },
};
