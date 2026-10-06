/// The selected bottom-nav icon is the filled twin of the outlined idle icon,
/// and every default layer has a short localised label.
library;

import 'package:dpip/core/settings/default_map_layer.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:dpip/shared/map/default_map_layer_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every layer has a distinct selected icon and a nav label', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final selected = <IconData>{};
    final labels = <String>{};
    for (final layer in DefaultMapLayer.values) {
      selected.add(layer.selectedIcon);
      expect(layer.icon.codePoint, isNonZero);
      labels.add(layer.label(l10n));
      expect(layer.label(l10n), isNotEmpty);
    }
    expect(selected, hasLength(DefaultMapLayer.values.length));
    expect(labels, hasLength(DefaultMapLayer.values.length));
  });
}
