import 'package:dpip/core/models/lat_lng.dart';
import 'package:dpip/features/typhoon/domain/cyclone_identity.dart';
import 'package:dpip/features/typhoon/domain/typhoon_cyclone.dart';
import 'package:dpip/features/typhoon/domain/typhoon_track.dart';
import 'package:dpip/features/typhoon/domain/typhoon_warning.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cycloneNamesMatch', () {
    test('case-insensitive', () {
      expect(cycloneNamesMatch('HAISHEN', 'haishen'), isTrue);
      expect(cycloneNamesMatch('海神', '海神'), isTrue);
      expect(cycloneNamesMatch('A', 'B'), isFalse);
      expect(cycloneNamesMatch(null, 'A'), isFalse);
    });
  });

  group('warningAppliesTo', () {
    TyphoonWarning warn({
      required String msgType,
      required bool active,
      String? name,
      String? cwaName,
    }) => TyphoonWarning(
      active: active,
      id: '1',
      sent: 1,
      status: 'Actual',
      msgType: msgType,
      scope: 'Public',
      event: 'Typhoon',
      urgency: 'Immediate',
      severity: 'Severe',
      certainty: 'Observed',
      effective: 1,
      onset: 1,
      expires: 2,
      headline: 'h',
      senderName: 'CWA',
      typhoon: name == null
          ? null
          : WarningTyphoon(
              name: name,
              cwaName: cwaName,
              analysis: const WarningFix(time: 1, latitude: 20, longitude: 120),
            ),
      sections: const [],
      areas: const [],
    );

    test('rejects Cancel / inactive / wrong name', () {
      expect(
        warningAppliesTo(
          warn(msgType: 'Cancel', active: true, name: 'OLD', cwaName: '舊颱'),
          name: 'NEW',
          cwaName: '新颱',
        ),
        isFalse,
      );
      expect(
        warningAppliesTo(
          warn(msgType: 'Alert', active: true, name: 'OLD', cwaName: '舊颱'),
          name: 'NEW',
          cwaName: '新颱',
        ),
        isFalse,
      );
      expect(
        warningAppliesTo(
          warn(msgType: 'Alert', active: true, name: 'NEW', cwaName: '新颱'),
          name: 'NEW',
          cwaName: '新颱',
        ),
        isTrue,
      );
      expect(
        warningAppliesTo(
          warn(msgType: 'Update', active: true, name: 'X', cwaName: '新颱'),
          name: 'NEW',
          cwaName: '新颱',
        ),
        isTrue,
      );
    });
  });

  group('indexOfNearestCyclone', () {
    test('picks the closer of two', () {
      const near = TyphoonCyclone(
        name: 'NEAR',
        year: 2026,
        time: 1,
        latitude: 24,
        longitude: 122,
      );
      const far = TyphoonCyclone(
        name: 'FAR',
        year: 2026,
        time: 1,
        latitude: 10,
        longitude: 140,
      );
      expect(
        indexOfNearestCyclone([far, near], origin: const LatLng(23.7, 121)),
        1,
      );
    });
  });

  // CWA sends `""` (not null) for a system with no name yet. Keying selection
  // on the international name alone yielded an empty key, which every lookup
  // rejected — blanking the storm circles and forecast callouts whenever an
  // unnamed depression was the system nearest Taiwan.
  group('unnamed tropical depression', () {
    const unnamed = TyphoonCyclone(
      name: '',
      cwaName: '',
      year: 2026,
      tdNo: '15',
      tyNo: '',
      time: 1785823200,
      latitude: 16.4,
      longitude: 118.4,
    );
    const named = TyphoonCyclone(
      name: 'DOLPHIN',
      cwaName: '白海豚',
      year: 2026,
      tdNo: '14',
      tyNo: '13',
      time: 1785823200,
      latitude: 25.3,
      longitude: 141.9,
    );

    test('uses TD number as stable key', () {
      expect(cycloneKey(unnamed), 'TD15');
      expect(cycloneKey(named), 'TD14');
    });

    test('resolves in the index and the track by that key', () {
      const index = CycloneIndex(updated: 1, cyclones: [named, unnamed]);
      expect(cycloneForKey(index, cycloneKey(unnamed)), unnamed);
      expect(cycloneForKey(index, cycloneKey(named)), named);

      const track = TyphoonTrack(
        name: '',
        cwaName: '',
        year: 2026,
        tdNo: '15',
        analysis: [],
        forecast: [],
      );
      const payload = TrackPayload(updated: 1, cyclones: [track]);
      expect(trackForKey(payload, cycloneKey(unnamed)), track);
      expect(trackForKey(payload, 'DOLPHIN'), isNull);
    });

    test('has no display name, so callers localize the fallback', () {
      expect(
        cycloneDisplayName(cwaName: unnamed.cwaName, name: unnamed.name),
        isNull,
      );
      expect(
        cycloneDisplayName(cwaName: named.cwaName, name: named.name),
        '白海豚',
      );
      expect(cycloneDisplayName(cwaName: '  ', name: 'DOLPHIN'), 'DOLPHIN');
    });

    test('an empty key still selects nothing', () {
      const index = CycloneIndex(updated: 1, cyclones: [named]);
      expect(cycloneForKey(index, ''), isNull);
      expect(cycloneForKey(index, null), isNull);
    });
  });
}
