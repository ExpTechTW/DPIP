import 'package:dpip/utils/geojson.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lightning.g.dart';

@JsonSerializable()
class Lightning {
  final int time;
  final int type;
  final Location loc;

  const Lightning({required this.time, required this.type, required this.loc});

  factory Lightning.fromJson(Map<String, dynamic> json) => _$LightningFromJson(json);

  Map<String, dynamic> toJson() => _$LightningToJson(this);

  GeoJsonFeatureBuilder<GeoJsonFeatureType> toFeatureBuilder(int currentTime) {
    final timeDiff = currentTime - time;
    int level;
    if (timeDiff < 5 * 60 * 1000) {
      level = 5;
    } else if (timeDiff < 10 * 60 * 1000) {
      level = 10;
    } else if (timeDiff < 30 * 60 * 1000) {
      level = 30;
    } else {
      level = 60;
    }

    return GeoJsonFeatureBuilder<GeoJsonFeatureType>(GeoJsonFeatureType.Point)
        .setGeometry([loc.lng, loc.lat])
        .setProperty('type', '${type}-$level');
  }
}

@JsonSerializable()
class Location {
  final double lat;
  final double lng;

  const Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
