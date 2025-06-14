import 'package:i18n_extension/i18n_extension.dart';

extension AppLocalizations on String {
  static final _t = Translations.byFile('zh-TW', dir: 'assets/translations');
  static Future<void> load() => _t.load();
  String get i18n => localize(this, _t);
}
