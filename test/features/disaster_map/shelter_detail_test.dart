import 'package:dpip/features/disaster_map/domain/shelter_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ShelterDetail.fromJson', () {
    test('round-trips the detail payload', () {
      const json = {
        'id': 1,
        'name': '金門縣烈嶼鄉林湖村辦公處',
        'capacity': 30,
        'category': ['水災', '震災', '土石流', '海嘯'],
        'indoor': true,
        'outdoor': false,
        'vulnerable_ok': true,
        'lat': 24.428328,
        'lng': 118.248571,
        'address': '金門縣烈嶼鄉東林24號',
      };

      final detail = ShelterDetail.fromJson(json);
      expect(detail.id, 1);
      expect(detail.name, '金門縣烈嶼鄉林湖村辦公處');
      expect(detail.capacity, 30);
      expect(detail.category, ['水災', '震災', '土石流', '海嘯']);
      expect(detail.indoor, isTrue);
      expect(detail.outdoor, isFalse);
      expect(detail.vulnerableOk, isTrue);
      expect(detail.lat, 24.428328);
      expect(detail.lng, 118.248571);
      expect(detail.address, '金門縣烈嶼鄉東林24號');
      expect(detail.toJson(), json);
    });
  });
}
