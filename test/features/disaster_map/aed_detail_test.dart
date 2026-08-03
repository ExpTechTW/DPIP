import 'package:dpip/features/disaster_map/domain/aed_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AedDetail.fromJson', () {
    test('round-trips the detail payload', () {
      const json = {
        'id': 1,
        'aed_id': '625',
        'name': '淡水某場所',
        'city': '新北市',
        'district': '淡水區',
        'category': '政府機關',
        'type': '行政機關',
        'place': '一樓大廳',
        'lat': 25.178,
        'lng': 121.43,
        'address': '新北市淡水區某某路 1 號',
        'description': '備註',
        'place_desc': '入口右側',
        'weekday_start': '09:00:00',
        'weekday_end': '17:00:00',
        'saturday_start': '',
        'saturday_end': '',
        'sunday_start': '',
        'sunday_end': '',
        'open_remark': '國定假日休',
        'emergency_phone': '02-12345678',
        'place_id': '10361',
      };

      final detail = AedDetail.fromJson(json);
      expect(detail.id, 1);
      expect(detail.aedId, '625');
      expect(detail.name, '淡水某場所');
      expect(detail.lat, 25.178);
      expect(detail.lng, 121.43);
      expect(detail.placeDesc, '入口右側');
      expect(detail.weekdayStart, '09:00:00');
      expect(detail.emergencyPhone, '02-12345678');
      expect(detail.toJson(), json);
    });
  });
}
