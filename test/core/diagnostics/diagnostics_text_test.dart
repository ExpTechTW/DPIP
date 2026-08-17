/// The pasted half of a dump. Two things here are worth a test rather than a
/// reading: that the redaction list is actually applied (a push token in a
/// pasted dump lets anyone notify that device), and that a section whose every
/// field was redacted does not leave its heading behind — an empty `[Push]`
/// block reads as "this device has no token", which is a different bug report.
library;

import 'package:dpip/core/diagnostics/diagnostics_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('redacted labels do not appear, by label or by value', () {
    final text = diagnosticsText([
      (
        title: 'Device',
        fields: [
          (label: 'Model', value: 'iPhone17,1'),
          (label: 'Identifier', value: 'D4E7-PRIVATE'),
        ],
      ),
      (title: 'Push', fields: [(label: 'APNs token', value: 'SECRET-TOKEN')]),
    ], redacted: diagnosticsRedactedLabels);

    expect(text, contains('iPhone17,1'));
    expect(text, isNot(contains('D4E7-PRIVATE')));
    expect(text, isNot(contains('SECRET-TOKEN')));
    expect(text, isNot(contains('Identifier')));
  });

  test('a section left with nothing to say is dropped whole', () {
    final text = diagnosticsText([
      (title: 'Push', fields: [(label: 'FCM token', value: 'SECRET')]),
    ], redacted: diagnosticsRedactedLabels);

    expect(text, isNot(contains('[Push]')));
  });

  test('a field the platform could not answer reads as a dash, not blank', () {
    final text = diagnosticsText([
      (title: 'Platform', fields: [(label: 'OS version', value: null)]),
    ]);

    // A blank after the colon looks like a formatting bug; the dash says the
    // field was asked for and came back empty.
    expect(text, contains('OS version: —'));
  });

  test('nothing redacted by default', () {
    final text = diagnosticsText([
      (title: 'Device', fields: [(label: 'Identifier', value: 'VISIBLE')]),
    ]);

    // The redaction is the caller's decision: the Developer page shows these
    // rows on screen and only strips them on the way out.
    expect(text, contains('VISIBLE'));
  });
}
