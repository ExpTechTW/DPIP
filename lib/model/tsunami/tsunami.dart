import 'package:dpip/model/tsunami/tsunami_earthquake.dart';
import 'package:dpip/model/tsunami/tsunami_info.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tsunami.g.dart';

@JsonSerializable()
class Tsunami {
  /// - 資料種類
  ///
  /// 範例
  /// ```
  /// "tsunami"
  /// ```
  final String type;

  /// - 海嘯資訊編號
  ///
  /// 範例
  /// ```
  /// 113003
  /// ```
  final int id;

  /// - 海嘯資訊報號
  ///
  /// 範例
  /// ```
  /// 1
  /// ```
  final int serial;

  /// - 海嘯資訊發布狀態
  ///
  /// 範例
  /// ```
  /// 0
  /// ```
  final int status;

  /// - 海嘯資訊發布單位
  ///
  /// 範例
  /// ```
  /// "cwa"
  /// ```
  final String author;

  /// - 海嘯資訊報文
  ///
  /// 範例
  /// ```
  /// "１１３年０４月０３日０７時５８分（臺灣時間），臺灣東部海域發生規模７﹒３地震，震央位於東經１２１﹒６７度、北緯２３﹒７７度。該地震可能引發海嘯影響臺灣，特此發布海嘯警報，提醒沿海地區民眾提高警覺嚴加防範，注意海浪突然湧升所造成的危害。"
  /// ```
  final String content;

  /// - 發布時間
  final int time;

  /// - 海嘯實測地區編碼
  final TsunamiEarthquake eq;

  /// - 海嘯實測地區編碼
  final TsunamiInfo info;

  Tsunami({
    required this.type,
    required this.id,
    required this.serial,
    required this.status,
    required this.author,
    required this.content,
    required this.time,
    required this.eq,
    required this.info,
  });

  factory Tsunami.fromJson(Map<String, dynamic> json) => _$TsunamiFromJson(json);

  Map<String, dynamic> toJson() => _$TsunamiToJson(this);
}
