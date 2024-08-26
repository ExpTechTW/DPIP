import "package:json_annotation/json_annotation.dart";

part "lightning.g.dart";

@JsonSerializable()
class Lightning {
  final int time;
  final int type;
  final Location loc;

  const Lightning({
    required this.time,
    required this.type,
    required this.loc,
  });

  factory Lightning.fromJson(Map<String, dynamic> json) => _$LightningFromJson(json);

  Map<String, dynamic> toJson() => _$LightningToJson(this);
}

@JsonSerializable()
class Location {
  final double lat;
  final double lng;

  const Location({
    required this.lat,
    required this.lng,
  });

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
