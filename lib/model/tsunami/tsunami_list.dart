import 'package:freezed_annotation/freezed_annotation.dart';

part 'tsunami_list.g.dart';

@JsonSerializable()
class TsunamiList {
  final String id;

  TsunamiList({required this.id});
}
