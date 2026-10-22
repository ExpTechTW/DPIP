/// What the AI chat's failures and tool calls are called on screen.
library;

import 'package:dpip/features/ai_chat/domain/ai_connection.dart';
import 'package:dpip/features/ai_chat/domain/ai_failure.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';

String aiFailureText(AppLocalizations l10n, AiException failure) =>
    switch (failure.kind) {
      AiFailureKind.unauthorized => l10n.aiErrorUnauthorized,
      AiFailureKind.notFound => l10n.aiErrorNotFound,
      AiFailureKind.rateLimited => l10n.aiErrorRateLimited,
      AiFailureKind.rejected => l10n.aiErrorRejected,
      AiFailureKind.server => l10n.aiErrorServer,
      AiFailureKind.network => l10n.aiErrorNetwork,
      AiFailureKind.timeout => l10n.aiErrorTimeout,
      AiFailureKind.badResponse => l10n.aiErrorBadResponse,
      AiFailureKind.toolsUnavailable => l10n.aiErrorToolsUnavailable,
      AiFailureKind.tooManySteps => l10n.aiErrorTooManySteps,
    };

/// Whether the fix for [failure] is in the settings page.
bool aiFailureNeedsSettings(AiException failure) =>
    failure.kind == AiFailureKind.unauthorized ||
    failure.kind == AiFailureKind.notFound ||
    failure.kind == AiFailureKind.badResponse;

String? baseUrlProblemText(AppLocalizations l10n, BaseUrlProblem? problem) =>
    switch (problem) {
      null => null,
      BaseUrlProblem.empty => l10n.aiSettingsUrlEmpty,
      BaseUrlProblem.invalid => l10n.aiSettingsUrlInvalid,
      BaseUrlProblem.insecure => l10n.aiSettingsUrlInsecure,
    };

/// The kind of data a DPIP tool looks up, for "looking up …" lines.
///
/// By the tool's name rather than one string per tool: the server can add
/// tools without the app shipping new translations, and a new tool still
/// reads sensibly ("data") until someone names its kind here.
String toolSubject(AppLocalizations l10n, String tool) {
  bool has(String part) => tool.contains(part);
  if (has('earthquake') || tool == 'eew' || tool == 'rts') {
    return l10n.aiToolEarthquake;
  }
  if (has('tsunami')) return l10n.aiToolTsunami;
  if (has('typhoon')) return l10n.aiToolTyphoon;
  if (has('event')) return l10n.aiToolNotices;
  if (has('township') || has('lookup')) return l10n.aiToolPlaces;
  if (has('timeline')) return l10n.aiToolTimeline;
  if (has('weather') || has('meteor') || has('rain') || has('lightning')) {
    return l10n.aiToolWeather;
  }
  return l10n.aiToolOther;
}
