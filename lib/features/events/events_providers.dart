/// Events feature providers — the DPIP disaster-event card repository.
library;

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:dpip/core/di/shared_deps.dart';
import 'package:dpip/core/settings/locale_config.dart';
import 'package:dpip/core/settings/locale_controller.dart';
import 'package:dpip/features/events/data/event_api.dart';
import 'package:dpip/features/events/data/event_repository_impl.dart';
import 'package:dpip/features/events/domain/event_repository.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Exposes the [EventRepository] so the events timeline can consume it without
/// importing the feature's `data/`.
List<SingleChildWidget> eventsProviders(SharedDeps deps) => [
  Provider<EventRepository>.value(
    value: EventRepositoryImpl(
      EventApi(deps.apiClient),
      locale: () => _appLocale(deps.locale),
    ),
  ),
];

/// The locale the app's UI is in: the language chosen in settings, or else the
/// device's languages, resolved against the supported set by
/// [resolveAppLocale] — the same inputs and callback `MaterialApp` is given in
/// `app.dart`, so a card's language follows the UI's.
Locale _appLocale(LocaleController controller) {
  final chosen = controller.locale;
  return resolveAppLocale(
    chosen != null ? [chosen] : PlatformDispatcher.instance.locales,
    appSupportedLocales,
  );
}
