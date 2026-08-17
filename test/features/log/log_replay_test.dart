/// A replayed line keeps the level it was written with.
///
/// The log screen colours a card and filters by `logLevel`; a line that comes
/// back without one is uncoloured and unfilterable, which is most of what the
/// screen is read with.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

import 'package:dpip/core/logging/log.dart';
import 'package:dpip/core/logging/log_store.dart';
import 'package:dpip/features/log/presentation/pages/log_page.dart';

void main() {
  test('every level Log persists is read back as itself', () {
    for (final level in LogLevel.values) {
      // The exact string `Log.persistTo` writes.
      final stored = StoredLog(
        time: DateTime.utc(2026, 8, 18),
        level: level.name,
        message: 'a line',
      );
      final replayed = PersistedLog(stored);
      expect(replayed.logLevel, level, reason: 'level ${level.name}');
    }
  });

  test('an unreadable level is shown, not dropped', () {
    final replayed = PersistedLog(
      StoredLog(
        time: DateTime.utc(2026, 8, 18),
        level: 'from-some-future-version',
        message: 'a line',
      ),
    );
    expect(replayed.logLevel, LogLevel.info);
    expect(replayed.generateTextMessage(), contains('a line'));
  });

  test('a replayed line lands in the filter chip for its level', () {
    // The screen groups the chips and their counts by `TalkerData.key`, and
    // colours a card by it too — not by the level and not by the title. A
    // line without one is uncounted and grouped under `undefined`.
    for (final level in LogLevel.values) {
      final replayed = PersistedLog(
        StoredLog(
          time: DateTime.utc(2026, 8, 18),
          level: level.name,
          message: 'a line',
        ),
      );
      expect(
        replayed.key,
        TalkerKey.fromLogLevel(level),
        reason: 'level ${level.name}',
      );
    }
  });

  test('replaying fills in the title and pen the logger would have', () {
    // `Log.replay` skips `_handleLogData`, which is where a live line gets
    // these from its key.
    final replayed = PersistedLog(
      StoredLog(
        time: DateTime.utc(2026, 8, 18),
        level: 'warning',
        message: 'a line',
      ),
    );
    Log.replay(replayed);
    expect(
      replayed.title,
      Log.talker.settings.getTitleByKey(TalkerKey.warning),
    );
    expect(replayed.title, isNot('log'));
  });

  test('a stored error is carried with its message', () {
    final replayed = PersistedLog(
      StoredLog(
        time: DateTime.utc(2026, 8, 18),
        level: 'error',
        message: 'the summary',
        error: 'the detail',
      ),
    );
    expect(replayed.generateTextMessage(), contains('the summary'));
    expect(replayed.generateTextMessage(), contains('the detail'));
  });

  test('a replayed line reaches history without being logged again', () {
    // `logCustom` publishes to the stream, which the persister writes from,
    // and prints to the console — so replaying the table reprinted it and
    // wrote every line back into the table it came from.
    var streamed = 0;
    final sub = Log.talker.stream.listen((_) => streamed++);
    addTearDown(sub.cancel);

    final before = Log.talker.history.length;
    Log.replay(
      PersistedLog(
        StoredLog(
          time: DateTime.utc(2026, 8, 18),
          level: 'info',
          message: 'replayed',
        ),
      ),
    );

    expect(Log.talker.history.length, before + 1);
    expect(streamed, 0, reason: 'nothing may write it back or print it');
  });

  group('replay never costs the running session', () {
    setUp(Log.talker.cleanHistory);

    PersistedLog stored(String message, DateTime at) =>
        PersistedLog(StoredLog(time: at, level: 'info', message: message));

    test('a live line survives a full replay', () {
      // The stored log is on disk and can be read again; the running session
      // cannot. Evicting it to make room for history is backwards.
      Log.talker.info('DPIP starting up');
      for (var i = 0; i < Log.historyLimit + 50; i++) {
        Log.replay(stored('old \$i', DateTime.utc(2026, 8, 17, 0, 0, i)));
      }
      final messages = Log.talker.history.map((e) => e.message).toList();
      expect(messages, contains('DPIP starting up'));
      expect(Log.talker.history.length, lessThanOrEqualTo(Log.historyLimit));
    });

    test('replayed lines read oldest first, in front of the live ones', () {
      Log.talker.info('live');
      // Newest first, as the query returns them.
      Log.replay(stored('newer', DateTime.utc(2026, 8, 17, 2)));
      Log.replay(stored('older', DateTime.utc(2026, 8, 17, 1)));
      expect(Log.talker.history.map((e) => e.message).toList(), [
        'older',
        'newer',
        'live',
      ]);
    });
  });
}
