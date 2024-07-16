import 'package:freezed_annotation/freezed_annotation.dart';

part 'tsunami_list.g.dart';

@JsonSerializable()
class TsunamiList {
  final String id;

  TsunamiList({required this.id});
  factory TsunamiList.fromJson(Map<String, dynamic> json) => _$TsunamiListFromJson(json);
  Map<String, dynamic> toJson() => _$TsunamiListToJson(this);
}
