/// Tracks whether the first-launch onboarding flow has been completed.
library;

import 'package:dpip/core/settings/preference_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists a single "onboarding done" flag so the intro / terms / permissions
/// flow is shown once, on first launch. The router redirects to onboarding
/// until [isComplete], and gates the app's permission requests on it (they
/// belong in onboarding, not a cold-start prompt).
class OnboardingStore extends ChangeNotifier {
  OnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  /// Whether onboarding has been finished.
  bool get isComplete =>
      _prefs.getBool(PreferenceKeys.onboardingComplete) ?? false;

  /// Marks onboarding finished (idempotent).
  Future<void> complete() async {
    if (isComplete) return;
    await _prefs.setBool(PreferenceKeys.onboardingComplete, true);
    notifyListeners();
  }
}
