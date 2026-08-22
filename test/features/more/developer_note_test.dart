import 'package:dpip/features/more/domain/developer_note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('known locales get their own note', () {
    for (final locale in const [
      'zh_TW',
      'zh_Hans',
      'yue',
      'en',
      'ja',
      'ko',
      'th',
      'vi',
      'id',
      'fil',
    ]) {
      final note = developerNoteFor(locale);
      expect(note.title, isNotEmpty);
      expect(note.body, isNotEmpty);
    }
  });

  test('an unknown locale falls back to the home locale note', () {
    final note = developerNoteFor('de');
    expect(note.title, developerNoteFor('zh_TW').title);
    expect(note.body, developerNoteFor('zh_TW').body);
  });
}
