import 'package:dpip/core/preference.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _SettingsExperimentalModel extends ChangeNotifier {
  /// The underlying [ValueNotifier] for the "launch to monitor" experimental setting.
  ///
  /// Returns the stored preference value, defaulting to `false` if no preference has been set.
  final $experimental__launchToMonitor = ValueNotifier(
    Preference.experimental__launchToMonitor ?? false,
  );

  /// Whether the app launches directly into the monitor screen.
  ///
  /// Returns the current state of the "launch to monitor" experimental setting.
  /// Defaults to `false` if no preference has been set.
  bool get experimental__launchToMonitor => $experimental__launchToMonitor.value;

  /// Sets whether the app should launch directly into the monitor screen.
  ///
  /// Takes a [bool] value indicating if the app should open to the monitor screen on launch.
  ///
  /// Invoking this method will also update [$experimental__launchToMonitor] and notify all attached listeners.
  void set_experimental__launchToMonitor(bool value) {
    Preference.experimental__launchToMonitor = value;

    $experimental__launchToMonitor.value = value;

    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the EEW (Early Earthquake Warning) all-source experimental setting.
  ///
  /// Returns the stored preference value, defaulting to `false` if no preference has been set.
  final $experimental__eewAllSource = ValueNotifier(Preference.experimental__eewAllSource ?? false);

  /// Whether to enable the all-source EEW experimental feature.
  ///
  /// Returns the current state of the EEW all-source experimental setting.
  /// Defaults to `false` if no preference has been set.
  bool get experimental__eewAllSource => $experimental__eewAllSource.value;

  /// Sets whether the all-source EEW experimental feature is enabled.
  ///
  /// Takes a [bool] value indicating if the all-source EEW feature should be enabled.
  ///
  /// Invoking this method will also update [$experimental__eewAllSource] and notify all attached listeners.
  void set_experimental__eewAllSource(bool value) {
    Preference.experimental__eewAllSource = value;

    $experimental__eewAllSource.value = value;

    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the new home screen experimental setting.
  ///
  /// Returns the stored preference value, defaulting to `false` if no preference has been set.
  final $experimental__newHomeScreen = ValueNotifier(
    Preference.experimental__newHomeScreen ?? false,
  );

  /// Whether to enable the new home screen experimental feature.
  ///
  /// Returns the current state of the new home screen experimental setting.
  /// Defaults to `false` if no preference has been set.
  bool get experimental__newHomeScreen => $experimental__newHomeScreen.value;

  /// Sets whether the new home screen experimental feature is enabled.
  ///
  /// Takes a [bool] value indicating if the new home screen feature should be enabled.
  ///
  /// Invoking this method will also update [$experimental__newHomeScreen] and notify all attached listeners.
  void set_experimental__newHomeScreen(bool value) {
    Preference.experimental__newHomeScreen = value;

    $experimental__newHomeScreen.value = value;

    notifyListeners();
  }
}

class SettingsExperimentalModel extends _SettingsExperimentalModel {}

extension SettingsExperimentalModelExtension on BuildContext {
  SettingsExperimentalModel get useExperimental => watch<SettingsExperimentalModel>();
  SettingsExperimentalModel get experimental => read<SettingsExperimentalModel>();
}
