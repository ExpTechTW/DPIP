import 'package:json_annotation/json_annotation.dart';

part 'town.g.dart';

@JsonSerializable(includeIfNull: false)
class Town {
  final int code;
  final double lon;
  final double lat;
  final double? site;
  @JsonKey(name: "site_s")
  final double? siteS;
  @JsonKey(name: "site_d")
  final double? siteD;

  Town(
      {required this.code,
      required this.lon,
      required this.lat,
      this.site,
      this.siteS,
      this.siteD});

  factory Town.fromJson(Map<String, dynamic> json) => _$TownFromJson(json);

  Map<String, dynamic> toJson() => _$TownToJson(this);
}
