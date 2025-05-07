import 'package:json_annotation/json_annotation.dart';

import 'package:dpip/api/model/eew_info.dart';
import 'package:dpip/utils/parser.dart';

part 'eew.g.dart';

@JsonSerializable()
class Eew {
  final String type = 'eew';

  /// 地震速報來源機關
  final String author;

  /// 地震速報 ID
  final String id;

  /// 地震速報報號
  final int serial;

  /// 地震速報狀態
  final int status;

  /// 地震速報是否為最終報
  @JsonKey(name: 'final', fromJson: parseBoolishInt)
  final bool isFinal;

  /// 地震速報參數
  final EewInfo eq;

  const Eew({
    required this.author,
    required this.id,
    required this.serial,
    required this.status,
    required this.isFinal,
    required this.eq,
  });

  factory Eew.fromJson(Map<String, dynamic> json) => _$EewFromJson(json);

  Map<String, dynamic> toJson() => _$EewToJson(this);
}
