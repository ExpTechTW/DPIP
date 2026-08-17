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
    Log.reload([replayed]);
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

  test('loading the table does not log it again', () {
    // `logCustom` publishes to the stream, which the persister writes from,
    // and prints to the console — so loading the table reprinted it and wrote
    // every line back into the table it came from.
    var streamed = 0;
    final sub = Log.talker.stream.listen((_) => streamed++);
    addTearDown(sub.cancel);

    Log.reload([
      PersistedLog(
        StoredLog(
          time: DateTime.utc(2026, 8, 18),
          level: 'info',
          message: 'from the table',
        ),
      ),
    ]);

    expect(Log.talker.history.map((e) => e.message), ['from the table']);
    expect(streamed, 0, reason: 'nothing may write it back or print it');
  });

  test('the table replaces history, it is not merged into it', () {
    // Every line is persisted and the pre-database ones are copied in when it
    // opens, so memory holds nothing the table does not. Merging the two is
    // what produced every ordering and eviction fault this screen had.
    Log.talker.info('in memory');
    Log.reload([
      PersistedLog(
        StoredLog(
          time: DateTime.utc(2026, 8, 17, 2),
          level: 'info',
          message: 'newer',
        ),
      ),
      PersistedLog(
        StoredLog(
          time: DateTime.utc(2026, 8, 17, 1),
          level: 'info',
          message: 'older',
        ),
      ),
    ]);
    // Oldest first, and nothing of the merge left behind.
    expect(Log.talker.history.map((e) => e.message).toList(), [
      'older',
      'newer',
    ]);
  });
}
