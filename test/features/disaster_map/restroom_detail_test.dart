import 'package:dpip/features/disaster_map/domain/restroom_detail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RestroomDetail.fromJson', () {
    test('round-trips the detail payload', () {
      const json = {
        'name': '四城火車站-無障礙廁所',
        'address': '宜蘭縣礁溪鄉吳沙村站前路24號',
        'latitude': 24.78654801,
        'longitude': 121.76269501,
        'type': 4,
        'type2': 1,
        'typegrade': 3,
      };

      final detail = RestroomDetail.fromJson(json);
      expect(detail.name, '四城火車站-無障礙廁所');
      expect(detail.address, '宜蘭縣礁溪鄉吳沙村站前路24號');
      expect(detail.latitude, 24.78654801);
      expect(detail.longitude, 121.76269501);
      expect(detail.type, 4);
      expect(detail.type2, 1);
      expect(detail.typegrade, 3);
      expect(detail.toJson(), json);
    });
  });
}
