import 'package:dpip/utils/geojson.dart';
import 'package:json_annotation/json_annotation.dart';

part 'typhoon.g.dart';

@JsonSerializable()
class Typhoon {
  final int time;
  final int type;
  final Location loc;

  const Typhoon({required this.time, required this.type, required this.loc});

  factory Typhoon.fromJson(Map<String, dynamic> json) => _$TyphoonFromJson(json);

  Map<String, dynamic> toJson() => _$TyphoonToJson(this);

}

@JsonSerializable()
class Location {
  final double lat;
  final double lng;

  const Location({required this.lat, required this.lng});

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
