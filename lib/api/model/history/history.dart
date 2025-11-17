import 'package:json_annotation/json_annotation.dart';
import 'package:timezone/timezone.dart';

import 'package:dpip/api/model/history/intensity_history.dart';
import 'package:dpip/api/model/history/report_history.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/serialization.dart';

part 'history.g.dart';

enum HistoryType {
  @JsonValue('earthquake')
  earthquake,

  @JsonValue('intensity')
  intensity,

  @JsonValue('thunderstorm')
  thunderstorm,

  @JsonValue('heavy-rain')
  heavyRain,

  @JsonValue('extremely-heavy-rain')
  extremelyHeavyRain,

  @JsonValue('torrential-rain')
  torrentialRain,

  @JsonValue('extremely-torrential-rain')
  extremelyTorrentialRain,

  @JsonValue('workSchlClos')
  workAndClassSuspension,

  @JsonValue('seawave')
  seawave,

  unknown,
}

@JsonSerializable()
class History {
  final String id;
  final int status;
  final HistoryType type;
  final String icon;
  final String author;
  final InfoTime time;
  final InfoText text;
  final List<int> area;

  History({
    required this.id,
    required this.status,
    required this.type,
    required this.icon,
    required this.author,
    required this.time,
    required this.text,
    required this.area,
  });

  bool get isExpired {
    final int? expireTimestamp = time.expires['all'];

    if (expireTimestamp == null) {
      return false;
    }

    final TZDateTime expireTimeUTC = expireTimestamp.asTZDateTime;
    final bool isExpired = TZDateTime.now(UTC).isAfter(expireTimeUTC.toUtc());
    return isExpired;
  }

  factory History.fromJson(Map<String, dynamic> json) {
    HistoryType type;
    try {
      type = $enumDecode(_$HistoryTypeEnumMap, json['type']);
    } catch (e) {
      // 處理未知類型
      type = HistoryType.unknown;
      json['type'] = 'unknown';
    }

    switch (type) {
      case HistoryType.earthquake:
        return ReportHistory.fromJson(json);
      case HistoryType.intensity:
        return IntensityHistory.fromJson(json);
      default:
        return _$HistoryFromJson(json);
    }
  }

  Map<String, dynamic> toJson() => _$HistoryToJson(this);
}

@JsonSerializable()
class InfoTime {
  @JsonKey(fromJson: parseDateTime, toJson: dateTimeToJson)
  final TZDateTime send;
  final Map<String, int> expires;

  InfoTime({required this.send, required this.expires});

  TZDateTime get expiresAt {
    final int expireTimestamp = expires['all']!;
    return expireTimestamp.asTZDateTime;
  }

  factory InfoTime.fromJson(Map<String, dynamic> json) => _$InfoTimeFromJson(json);

  Map<String, dynamic> toJson() => _$InfoTimeToJson(this);
}

@JsonSerializable()
class InfoText {
  final Map<String, InfoTextValue> content;
  final Map<String, String> description;

  InfoText({required this.content, required this.description});

  factory InfoText.fromJson(Map<String, dynamic> json) => _$InfoTextFromJson(json);

  Map<String, dynamic> toJson() => _$InfoTextToJson(this);
}

@JsonSerializable()
class InfoTextValue {
  final String title;
  final String subtitle;

  InfoTextValue({required this.title, required this.subtitle});

  factory InfoTextValue.fromJson(Map<String, dynamic> json) => _$InfoTextValueFromJson(json);

  Map<String, dynamic> toJson() => _$InfoTextValueToJson(this);
}
