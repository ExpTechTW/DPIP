/// Maps a server-sent event-type key to the icon a timeline row or home card
/// shows for it.
///
/// The switch is exhaustive only by virtue of its wildcard: add a new
/// `EventType` on the backend and forget to add its case here, and the row
/// renders a generic bell instead of the hazard-specific glyph — a silent
/// downgrade, not a compile error. Pinning every known key's icon here also
/// guards the two icons that come from the generated weather-icon font
/// ([thunderstorm], [rainyHeavy]): a hand-typed codepoint standing in for one
/// of those constants is how `rainy` once rendered as `Icons.severe_cold` — a
/// valid `IconData` that silently drew the wrong picture.
library;

import 'package:dpip/core/weather/weather_icons.dart';
import 'package:dpip/shared/widgets/event_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every known event key maps to its own icon', () {
    expect(eventTypeIcon('earthquake'), Icons.crisis_alert);
    expect(eventTypeIcon('report'), Icons.description_outlined);
    expect(eventTypeIcon('intensity'), Icons.graphic_eq);
    expect(eventTypeIcon('thunderstorm'), thunderstorm);
    expect(eventTypeIcon('heavy_rain'), rainyHeavy);
    expect(eventTypeIcon('weather_warning'), Icons.warning_amber_rounded);
    expect(eventTypeIcon('tsunami'), Icons.tsunami_outlined);
  });

  test('an unrecognized key falls back to the generic bell, not a crash', () {
    expect(
      eventTypeIcon('some_future_hazard_type'),
      Icons.notifications_outlined,
    );
    expect(eventTypeIcon(''), Icons.notifications_outlined);
  });
}
