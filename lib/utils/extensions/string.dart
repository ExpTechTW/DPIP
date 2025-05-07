import 'dart:ui';

extension LocaleString on String {
  Locale get asLocale {
    final a = split('-');
    return Locale(a[0], a.elementAtOrNull(1));
  }

  Uri get asUri => Uri.parse(this);
}
