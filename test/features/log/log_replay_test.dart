/// A replayed line keeps the level it was written with.
///
/// The log screen colours a card and filters by `logLevel`; a line that comes
/// back without one is uncoloured and unfilterable, which is most of what the
/// screen is read with.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
}
