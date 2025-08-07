import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';

class _SettingsLocationModel extends ChangeNotifier {
  /// The underlying [ValueNotifier] for the current location represented as a postal code.
  ///
  /// Returns the stored location code from preferences.
  /// Returns `null` if no location code has been set.
  final $code = ValueNotifier(Preference.locationCode);

  /// The current location represented as a postal code.
  ///
  /// Returns the stored location code from preferences.
  /// Returns `null` if no location code has been set.
  String? get code => $code.value;

  /// Sets the current location using a postal code.
  ///
  /// [value] The postal code to set as the current location.
  ///
  /// Invoking this method will also update [$code] and notify all attached listeners.
  ///
  /// If [value] matches the current code, no changes are made.
  /// When [auto] is false, also updates the stored latitude and longitude based on the
  /// location data associated with the postal code.
  void setCode(String? value) {
    if (code == value) return;

    final location = Global.location[value];

    // Check if the location is invalid
    if (location == null) {
      Preference.locationCode = null;
      $code.value = null;

      if (!auto) {
        Preference.locationLatitude = null;
        Preference.locationLongitude = null;

        $coordinates.value = null;
      }

      notifyListeners();
      return;
    }

    Preference.locationCode = value;
    $code.value = value;

    if (!auto) {
      Preference.locationLatitude = location.lat;
      Preference.locationLongitude = location.lng;

      $coordinates.value = LatLng(location.lat, location.lng);
    }

    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the current location represented as a [LatLng] coordinate.
  ///
  /// Returns a [LatLng] object containing the stored coordinates for the current [code].
  /// Returns `null` if either latitude or longitude is not set.
  ///
  /// This is used to display the precise location of the user on the map.
  ///
  /// Depends on [code].
  final $coordinates = ValueNotifier(
    Preference.locationLatitude != null && Preference.locationLongitude != null
        ? LatLng(Preference.locationLatitude!, Preference.locationLongitude!)
        : null,
  );

  /// The current location represented as a LatLng coordinate.
  ///
  /// Returns a [LatLng] object containing the stored coordinates for the current [code].
  /// Returns `null` if either latitude or longitude is not set.
  ///
  /// This is used to display the precise location of the user on the map.
  ///
  /// Depends on [code].
  LatLng? get coordinates => $coordinates.value;

  /// Sets the current location using a LatLng coordinate.
  ///
  /// Takes a [LatLng] value containing latitude and longitude coordinates and updates
  /// the stored location preferences. If value is `null`, both latitude and longitude
  /// will be set to `null`.
  ///
  /// Invoking this method will also update [$coordinates] and notify all attached listeners.
  ///
  /// This method should be called aside with [setCode] if automatic location update is enabled.
  ///
  /// Use [setCode] instead when automatic location update is disabled.
  void setCoordinates(LatLng? value) {
    Preference.locationLatitude = value?.latitude;
    Preference.locationLongitude = value?.longitude;

    $coordinates.value = value;

    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the current state of automatic location update.
  ///
  /// Returns a [bool] indicating if automatic location update is enabled.
  /// When enabled, the app will use GPS to automatically update
  /// the current location. When disabled, the location must be set manually either by [setCode] or [setCoordinates].
  ///
  /// Defaults to `false` if no preference has been set.
  final $auto = ValueNotifier(Preference.locationAuto ?? false);

  /// The current state of automatic location update.
  ///
  /// Returns a [bool] indicating if automatic location update is enabled.
  /// When enabled, the app will use GPS to automatically update
  /// the current location. When disabled, the location must be set manually either by [setCode] or [setCoordinates].
  ///
  /// Defaults to `false` if no preference has been set.
  bool get auto => $auto.value;

  /// Sets whether location should be automatically determined using GPS.
  ///
  /// Takes a [bool] value indicating if automatic location detection should be enabled.
  /// When enabled, the app will use GPS to automatically determine and update the current location.
  /// When disabled, the location must be set manually.
  void setAuto(bool value) {
    Preference.locationAuto = value;

    $auto.value = value;

    notifyListeners();
  }

  /// The underlying [ValueNotifier] for the list of favorited locations.
  ///
  /// Returns a [List] of [String] containing the postal codes of the favorited locations.
  ///
  /// Defaults to an empty list if no favorited locations have been set.
  final $favorited = ValueNotifier(Preference.locationFavorited);

  /// The list of favorited locations.
  ///
  /// Returns a [List<String>] containing the postal codes of the favorited locations.
  ///
  /// Defaults to an empty list if no favorited locations have been set.
  UnmodifiableListView<String> get favorited => UnmodifiableListView($favorited.value);

  /// Adds a location to the list of favorited locations.
  ///
  /// Takes a [String] value representing the postal code of the location to add to the list.
  ///
  /// If the location is already favorited, this method will do nothing.
  void favorite(String code) {
    Preference.locationFavorited.add(code);

    notifyListeners();
  }

  /// Removes a location from the list of favorited locations.
  ///
  /// Takes a [String] value representing the postal code of the location to remove from the list.
  ///
  /// If the location is not favorited, this method will do nothing.
  void unfavorite(String code) {
    Preference.locationFavorited.remove(code);

    notifyListeners();
  }
}

class SettingsLocationModel extends _SettingsLocationModel {}
