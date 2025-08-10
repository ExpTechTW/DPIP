import 'package:json_annotation/json_annotation.dart';

import 'package:dpip/api/model/rts/rts_intensity.dart';
import 'package:dpip/api/model/rts/rts_station.dart';
import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/extensions/latlng.dart';
import 'package:dpip/utils/geojson.dart';

part 'rts.g.dart';

@JsonSerializable()
class Rts {
  /// 測站地動資料
  final Map<String, RtsStation> station;

  /// 地動區塊
  final Map<String, int> box;

  ///資料時間
  final int time;

  /// 震度列表
  @JsonKey(name: 'int')
  final List<RtsIntensity> intensity;

  Rts({required this.station, required this.box, required this.time, required this.intensity});

  factory Rts.fromJson(Map<String, dynamic> json) => _$RtsFromJson(json);

  Map<String, dynamic> toJson() => _$RtsToJson(this);

  GeoJsonBuilder toGeoJsonBuilder() => GeoJsonBuilder().setFeatures(
    station.entries.map((e) {
      final MapEntry(key: id, value: s) = e;

      final latlng = GlobalProviders.data.station[id]?.info.last.latlng;

      if (latlng == null) {
        throw Exception('Station info for "$id" not found');
      }

      return GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
        ..setGeometry(latlng.asGeoJsonCooridnate)
        ..setProperty('id', id)
        ..setProperty('I', s.I)
        ..setProperty('i', s.i)
        ..setProperty('pga', s.pga)
        ..setProperty('pgv', s.pgv);
    }),
  );
}
