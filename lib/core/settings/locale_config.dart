/// The app's locale configuration — its home locale and supported set.
library;

import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The app's home locale: Traditional Chinese for Taiwan (`zh`, the generic
/// Chinese ARB, which carries the Taiwan wording). Used as the ultimate
/// fallback when the device language matches nothing else supported — DPIP is a
/// Taiwan-first disaster app, so an unrecognised device language defaults here
/// rather than to the English template.
const Locale kHomeLocale = Locale('zh');

/// Every locale the app ships, with [kHomeLocale] first so it is the fallback
/// (`supportedLocales.first`). The rest is the generated set — dropping an ARB
/// into `lib/l10n/` adds a language here automatically; nothing to edit.
List<Locale> get appSupportedLocales => [
  kHomeLocale,
  ...AppLocalizations.supportedLocales.where((l) => l != kHomeLocale),
];
