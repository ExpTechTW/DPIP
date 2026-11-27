import 'package:dpip/features/events/domain/event_hazard.dart';
import 'package:dpip/features/events/presentation/event_hazard_style.dart';
import 'package:flutter_test/flutter_test.dart';

/// The badge is the first thing read on every event row, so each hazard has a
/// picture of its own: a shared fallback glyph is how half the list once wore
/// the same bell.
void main() {
  test('every hazard has its own icon, bar the shared pictures', () {
    final byIcon = <Object, List<EventHazard>>{};
    for (final hazard in EventHazard.values) {
      (byIcon[hazard.icon] ??= []).add(hazard);
    }
    final shared = [
      for (final hazards in byIcon.values)
        if (hazards.length > 1) hazards.toSet(),
    ];
    // A storm surge is the sea over land, a flood; a debris flow, a rockfall
    // and a large landslide all come down a slope.
    expect(shared, [
      {EventHazard.flood, EventHazard.stormSurge},
      {
        EventHazard.debrisFlow,
        EventHazard.largeLandslide,
        EventHazard.rockfall,
      },
    ]);
  });
}
