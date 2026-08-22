/// The pasted half of a dump. Precise location needs consent; support lookup
/// identifiers and push tokens remain useful and cannot be acted on by a user.
library;

import 'package:dpip/core/diagnostics/diagnostics_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only precise location is redacted', () {
    final text = diagnosticsText([
      (
        title: 'Device',
        fields: [
          (label: 'Model', value: 'iPhone17,1'),
          (label: 'Identifier', value: 'D4E7-PRIVATE'),
        ],
      ),
      (title: 'Push', fields: [(label: 'APNs token', value: 'SECRET-TOKEN')]),
      (
        title: 'Location',
        fields: [(label: 'Centred on', value: '25.0478, 121.5319')],
      ),
    ], redacted: diagnosticsSensitiveLabels);

    expect(text, contains('iPhone17,1'));
    expect(text, contains('D4E7-PRIVATE'));
    expect(text, contains('SECRET-TOKEN'));
    expect(text, isNot(contains('25.0478')));
    expect(text, isNot(contains('Centred on')));
  });

  test('a section left with nothing to say is dropped whole', () {
    final text = diagnosticsText([
      (
        title: 'Location',
        fields: [(label: 'Centred on', value: '25.0478, 121.5319')],
      ),
    ], redacted: diagnosticsSensitiveLabels);

    expect(text, isNot(contains('[Location]')));
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

  test('sensitive fields can remain visible with null values', () {
    final text = diagnosticsText([
      (
        title: 'Private',
        fields: [
          (label: 'Identifier', value: 'PRIVATE-ID'),
          (label: 'Centred on', value: '25.0478, 121.5319'),
        ],
      ),
    ], nulled: diagnosticsSensitiveLabels);

    expect(text, contains('Identifier: PRIVATE-ID'));
    expect(text, contains('Centred on: null'));
    expect(text, isNot(contains('25.0478')));
  });
}
