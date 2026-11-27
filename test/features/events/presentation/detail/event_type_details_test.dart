/// Every card type the server documents has a family on the detail page, and
/// anything else still renders through the generic one.
library;

import 'package:dpip/features/events/presentation/detail/event_type_detail.dart';
import 'package:dpip/features/events/presentation/detail/event_type_details.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'every documented type resolves to a family, not the generic detail',
    () {
      for (final type in eventTypesWithDetail) {
        expect(
          eventTypeDetailFor(type),
          isNot(isA<GenericEventDetail>()),
          reason: type,
        );
      }
    },
  );

  test('a detection is drawn with the plain detail', () {
    // Where shaking was detected, not an estimate: no epicentre, depth or
    // intensity to put in a summary.
    expect(
      eventTypeDetailFor('earthquake.detection'),
      isA<GenericEventDetail>(),
    );
  });

  test('an unknown or empty type falls back to the generic detail', () {
    for (final type in ['volcano.ash', 'tsunami', '', 'EARTHQUAKE']) {
      expect(eventTypeDetailFor(type), isA<GenericEventDetail>(), reason: type);
    }
  });

  test('types that share an addition shape share one family', () {
    expect(
      eventTypeDetailFor('earthquake.eew').runtimeType,
      eventTypeDetailFor('earthquake.eew.alert').runtimeType,
    );
    expect(
      eventTypeDetailFor('heavy_rain.short').runtimeType,
      eventTypeDetailFor('fog.visibility').runtimeType,
    );
    expect(
      eventTypeDetailFor('earthquake.eew').runtimeType,
      isNot(eventTypeDetailFor('earthquake').runtimeType),
    );
  });
}
