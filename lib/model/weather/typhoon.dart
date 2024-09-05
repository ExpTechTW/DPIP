import "package:json_annotation/json_annotation.dart";

part "typhoon.g.dart";

@JsonSerializable()
class Typhoon {
  final String type = "typhoon";
  final TyphoonName name;
  final TyphoonNo no;
  final List<Analysis> analysis;
  final List<Forecast> forecast;

  const Typhoon({
    required this.name,
    required this.no,
    required this.analysis,
    required this.forecast,
  });

  factory Typhoon.fromJson(Map<String, dynamic> json) => _$TyphoonFromJson(json);

  Map<String, dynamic> toJson() => _$TyphoonToJson(this);
}

@JsonSerializable()
class TyphoonName {
  @JsonKey(defaultValue: "")
  final String en;
  @JsonKey(defaultValue: "")
  final String zh;

  const TyphoonName({
    this.en = "",
    this.zh = "",
  });

  factory TyphoonName.fromJson(Map<String, dynamic> json) => _$TyphoonNameFromJson(json);
  Map<String, dynamic> toJson() => _$TyphoonNameToJson(this);
}

@JsonSerializable()
class TyphoonNo {
  final int td;
  @JsonKey(fromJson: _tyFromJson)
  final int ty;

  const TyphoonNo({
    required this.td,
    required this.ty,
  });

  factory TyphoonNo.fromJson(Map<String, dynamic> json) => _$TyphoonNoFromJson(json);

  Map<String, dynamic> toJson() => _$TyphoonNoToJson(this);

  static int _tyFromJson(dynamic ty) => ty ?? -1;
}

@JsonSerializable()
class Analysis {
  final int time;
  final double lat;
  final double lng;
  final int pressure;
  final Wind wind;
  final Move move;
  final Map<String, int> circle;

  const Analysis({
    required this.time,
    required this.lat,
    required this.lng,
    required this.pressure,
    required this.wind,
    required this.move,
    required this.circle,
  });

  factory Analysis.fromJson(Map<String, dynamic> json) => _$AnalysisFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisToJson(this);
}

@JsonSerializable()
class Forecast {
  final int time;
  final int tau;
  final double lat;
  final double lng;
  final int pressure;
  final Wind wind;
  final Move move;
  final Map<String, int> circle;
  final int radius;

  const Forecast({
    required this.time,
    required this.tau,
    required this.lat,
    required this.lng,
    required this.pressure,
    required this.wind,
    required this.move,
    required this.circle,
    required this.radius,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) => _$ForecastFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastToJson(this);
}

@JsonSerializable()
class Wind {
  final int wind;
  final int gust;

  const Wind({
    required this.wind,
    required this.gust,
  });

  factory Wind.fromJson(Map<String, dynamic> json) => _$WindFromJson(json);

  Map<String, dynamic> toJson() => _$WindToJson(this);
}

@JsonSerializable()
class Move {
  final int speed;
  final String direction;

  const Move({
    required this.speed,
    required this.direction,
  });

  factory Move.fromJson(Map<String, dynamic> json) => _$MoveFromJson(json);

  Map<String, dynamic> toJson() => _$MoveToJson(this);
}
