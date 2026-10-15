/// Route parameters read the way a link from outside the app has to be read:
/// as untrusted text that may be missing, empty or not a number.
///
/// A route builder is not a place to throw. Every route here can be reached by
/// a deep link, a notification payload or a URL typed by hand, and a builder
/// that `int.parse`s a query parameter turns a malformed one into a red error
/// screen (or, in release, a grey one) with no way back but the system back
/// gesture. So each parameterised route validates in a route-level `redirect`
/// — which sends a link that cannot be honoured to the nearest page that can
/// — and its builder reads the same parameter through the same non-throwing
/// parser, so it stays total even when called directly.
library;

import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// [raw] as a positive integer, or null when it is missing, blank, not an
/// integer, or zero / negative. Surrounding whitespace is ignored.
int? positiveIntParam(String? raw) {
  final value = int.tryParse(raw?.trim() ?? '');
  return value != null && value > 0 ? value : null;
}

/// [raw] when it holds something other than whitespace, else null.
String? nonBlankParam(String? raw) =>
    raw == null || raw.trim().isEmpty ? null : raw;

/// The replay start instant (`?t=`, Unix ms) of an
/// [AppRoutes.earthquakeReplay] location, or null when it cannot be replayed.
int? replayTimestampOf(GoRouterState state) =>
    positiveIntParam(state.uri.queryParameters['t']);

/// The tracker thread id (`:id`) of an [AppRoutes.bugThread] location.
int? bugThreadIdOf(GoRouterState state) =>
    positiveIntParam(state.pathParameters['id']);

/// A replay without a usable start instant opens the report it hangs off
/// instead — the page that has the 重播 chip, so the user is one tap from a
/// working replay rather than on a crash screen.
String? replayRedirect(BuildContext context, GoRouterState state) {
  if (replayTimestampOf(state) != null) return null;
  final id = nonBlankParam(state.pathParameters['id']);
  return id == null
      ? state.namedLocation(AppRoutes.earthquake)
      : state.namedLocation(
          AppRoutes.earthquakeReport,
          pathParameters: {'id': id},
        );
}

/// A report link without an id opens the catalogue.
String? reportRedirect(BuildContext context, GoRouterState state) =>
    nonBlankParam(state.pathParameters['id']) == null
    ? state.namedLocation(AppRoutes.earthquake)
    : null;

/// A thread link whose id is not a thread number opens the tracker's list,
/// rather than asking the server for thread 0.
String? bugThreadRedirect(BuildContext context, GoRouterState state) =>
    bugThreadIdOf(state) == null
    ? state.namedLocation(AppRoutes.bugTracker)
    : null;

/// A city link without a city opens the city list, keeping the picker's own
/// query parameters (`replace`, `returnToMore`) so the flow it was part of
/// still completes.
String? regionCityRedirect(BuildContext context, GoRouterState state) =>
    nonBlankParam(state.pathParameters['city']) == null
    ? state.namedLocation(
        AppRoutes.regionSelect,
        queryParameters: state.uri.queryParameters,
      )
    : null;
