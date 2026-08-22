import 'package:dpip/core/settings/language_options.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the language options include Cantonese under its own name', () async {
    final options = await loadLanguageOptions();
    final names = options.map((o) => o.name).toList();
    expect(names, contains('粵語'));
    expect(
      options.firstWhere((o) => o.name == '粵語').locale,
      const Locale('yue'),
    );
  });
}
