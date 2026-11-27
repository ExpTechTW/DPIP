import 'package:dpip/core/geo/location_service.dart';
import 'package:dpip/core/geo/town_boundaries.dart';
import 'package:dpip/core/geo/town_directory.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server places a device by the coordinates it reports, so a township
/// set by hand has to be reported from a point the boundaries put inside it —
/// against the real township directory and boundaries the app ships.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every township set by hand is reported from inside it', () async {
    final directory = await TownDirectory.load();
    final boundaries = await TownBoundaries.load();
    final service = LocationService(
      directory,
      boundaries: Future.value(boundaries),
    );

    final misplaced = <String>[];
    for (final town in directory.all) {
      final fix = await service.manualFix(town);
      if (boundaries.codeAt(fix.lat, fix.lng) != town.code) {
        misplaced.add('${town.code} ${town.fullName}');
      }
    }
    expect(misplaced, isEmpty);

    // Why the directory point is not simply reported: 屏東縣瑪家鄉's lies in
    // a neighbouring township.
    final majia = directory.byCode('903')!;
    expect(boundaries.codeAt(majia.lat, majia.lng), isNot('903'));
  });
}
