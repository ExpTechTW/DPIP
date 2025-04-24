import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_status.g.dart';

@JsonSerializable()
class ServerStatus {
  final int time;
  @JsonKey(name: 'status')
  final Map<String, ServiceStatus> services;

  ServerStatus({required this.time, required this.services});

  factory ServerStatus.fromJson(Map<String, dynamic> json) => _$ServerStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ServerStatusToJson(this);

  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }
}

@JsonSerializable()
class ServiceStatus {
  final int status;
  final int count;

  ServiceStatus({required this.status, required this.count});

  factory ServiceStatus.fromJson(Map<String, dynamic> json) => _$ServiceStatusFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceStatusToJson(this);
}
