import 'package:dpip/util/parser.dart';
import 'package:timezone/timezone.dart';

extension CommonContext on int {
  String get asIntensityLabel => ["0", "1", "2", "3", "4", "5-", "5+", "6-", "6+", "7"][this];
  String get asIntensityDisplayLabel => ["0", "1", "2", "3", "4", "5⁻", "5⁺", "6⁻", "6⁺", "7"][this];
  TZDateTime get asTZDateTime => parseDateTime(this);
}
