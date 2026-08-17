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
}
