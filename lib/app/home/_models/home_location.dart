/// Model for temporarily overriding the home screen location.
library;

import 'package:flutter/material.dart';

/// Holds an optional temporary location code for the home screen.
///
/// When [temporaryCode] is non-null, the home page uses it instead of the
/// user's persisted location setting. Call [setTemporaryCode] to update and
/// notify listeners.
class HomeLocationModel extends ChangeNotifier {
  String? _temporaryCode;

  /// The current temporary location code, or `null` when none is set.
  String? get temporaryCode => _temporaryCode;

  /// Updates [temporaryCode] to [code] and notifies listeners.
  ///
  /// Does nothing if [code] equals the current value.
  void setTemporaryCode(String? code) {
    if (_temporaryCode == code) return;
    _temporaryCode = code;
    notifyListeners();
  }
}
