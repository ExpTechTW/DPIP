/// Opening the log screen's own Actions sheet used to write one ERROR per row
/// into the log that sheet belongs to — a debug assert from talker_flutter,
/// which paints that sheet as a coloured box with bare `ListTile`s inside it.
/// Nothing this app can fix, and nothing a user is affected by, but it filled
/// the terminal, the log page and the 4000-character dump budget.
///
/// The tests here pin the two halves of the compromise: it is said once, so it
/// is on the record, and it is said only once, so it cannot flood. A real error
/// arriving in between must still come through untouched.
library;

import 'package:dpip/core/logging/log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// The exact summary Flutter raises. Copied from
/// `packages/flutter/lib/src/material/list_tile.dart`.
const String _summary =
    'ListTile background color or ink splashes may be invisible.';

FlutterErrorDetails _details(String summary) => FlutterErrorDetails(
  exception: FlutterError.fromParts([ErrorSummary(summary)]),
  library: 'widgets library',
);

void main() {
  setUp(() {
    Log.resetErrorRepeats();
    Log.talker.cleanHistory();
  });

  test('the known assert is logged once and then dropped', () {
    Log.installErrorHandlers();

    // Six rows in the sheet — six reports, from one tap.
    for (var i = 0; i < 6; i++) {
      FlutterError.onError!(_details(_summary));
    }

    final said = Log.talker.history
        .where((e) => e.displayMessage.contains('ink splashes'))
        .toList();
    expect(said, hasLength(1));
    // Warning, not error: it is a real defect, just not one anybody here can
    // act on — and the level is what the log page filters by.
    expect(said.single.title, 'WARN');
    // The line has to carry the reason, or the next person spends the evening
    // hunting a widget that is not in this repository.
    expect(said.single.displayMessage, contains('talker_flutter'));
  });

  test('a second session says it again', () {
    Log.installErrorHandlers();
    FlutterError.onError!(_details(_summary));
    Log.resetErrorRepeats();
    Log.talker.cleanHistory();

    FlutterError.onError!(_details(_summary));

    expect(
      Log.talker.history.where(
        (e) => e.displayMessage.contains('ink splashes'),
      ),
      hasLength(1),
    );
  });

  test('an unrelated error is not swallowed by the match', () {
    Log.installErrorHandlers();

    FlutterError.onError!(_details('A RenderFlex overflowed by 42 pixels.'));

    expect(
      Log.talker.history.where((e) => e.displayMessage.contains('RenderFlex')),
      isNotEmpty,
    );
  });
}
