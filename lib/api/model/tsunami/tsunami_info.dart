import 'package:dpip/api/model/tsunami/tsunami_actual.dart';
import 'package:dpip/api/model/tsunami/tsunami_estimate.dart';

class TsunamiInfo {
  /// - 海嘯資訊資料總類
  ///   - `estimate` —— 預估資料
  ///   - `actual` —— 實測資料
  final String type;

  /// - 海嘯資訊資料
  final List<dynamic> data;

  TsunamiInfo({required this.type, required this.data});

  factory TsunamiInfo.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    var data = [];

    if (type == 'estimate') {
      data =
          (json['data'] as List<dynamic>)
              .map((item) => TsunamiEstimate.fromJson(item as Map<String, dynamic>))
              .toList();
    } else if (type == 'actual') {
      data =
          (json['data'] as List<dynamic>).map((item) => TsunamiActual.fromJson(item as Map<String, dynamic>)).toList();
    }

    return TsunamiInfo(type: type, data: data);
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data':
          data.map((item) {
            if (type == 'estimate') {
              return (item as TsunamiEstimate).toJson();
            } else if (type == 'actual') {
              return (item as TsunamiActual).toJson();
            }
            return null;
          }).toList(),
    };
  }
}
