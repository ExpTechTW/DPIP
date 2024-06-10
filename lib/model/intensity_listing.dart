import 'package:json_annotation/json_annotation.dart';

part 'intensity_listing.g.dart';

@JsonSerializable()
class IntensityListing {
  final String code;
  final String area;
  final String station;
  final int i;

  IntensityListing({required this.code, required this.area, required this.station, required this.i});

  factory IntensityListing.fromJson(dynamic json) => _$IntensityListingFromJson(json);

  Map<String, dynamic> toJson() => _$IntensityListingToJson(this);
}
