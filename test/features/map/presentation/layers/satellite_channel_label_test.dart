/// Every satellite channel has a distinct localised picker name, including the
/// named products that are not a raw band number.
library;

import 'package:dpip/features/map/presentation/layers/satellite_layer.dart';
import 'package:dpip/features/weather/domain/satellite_channel.dart';
import 'package:dpip/l10n/gen/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each channel maps to its own localised label', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final labels = [
      for (final channel in SatelliteChannel.values)
        satelliteChannelLabel(channel, l10n),
    ];
    expect(labels, hasLength(SatelliteChannel.values.length));
    expect(labels.toSet(), hasLength(labels.length));
    expect(labels.every((label) => label.isNotEmpty), isTrue);
  });
}
