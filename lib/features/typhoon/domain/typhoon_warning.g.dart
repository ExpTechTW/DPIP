// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'typhoon_warning.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WarningFix _$WarningFixFromJson(Map<String, dynamic> json) => _WarningFix(
  time: (json['t'] as num).toInt(),
  latitude: (json['lat'] as num).toDouble(),
  longitude: (json['lon'] as num).toDouble(),
  wind: (json['wind'] as num?)?.toDouble(),
  gust: (json['gust'] as num?)?.toDouble(),
  pressure: (json['pres'] as num?)?.toDouble(),
  r15: (json['r15'] as num?)?.toDouble(),
  scale: (json['scale'] as List<dynamic>?)?.map((e) => e as String).toList(),
);

Map<String, dynamic> _$WarningFixToJson(_WarningFix instance) =>
    <String, dynamic>{
      't': instance.time,
      'lat': instance.latitude,
      'lon': instance.longitude,
      'wind': instance.wind,
      'gust': instance.gust,
      'pres': instance.pressure,
      'r15': instance.r15,
      'scale': instance.scale,
    };

_WarningTyphoon _$WarningTyphoonFromJson(Map<String, dynamic> json) =>
    _WarningTyphoon(
      no: json['no'] as String?,
      name: json['name'] as String,
      cwaName: json['cwaName'] as String?,
      reportNo: json['reportNo'] as String?,
      category: json['category'] as String?,
      analysis: WarningFix.fromJson(json['analysis'] as Map<String, dynamic>),
      prediction: json['prediction'] == null
          ? null
          : WarningFix.fromJson(json['prediction'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$WarningTyphoonToJson(_WarningTyphoon instance) =>
    <String, dynamic>{
      'no': instance.no,
      'name': instance.name,
      'cwaName': instance.cwaName,
      'reportNo': instance.reportNo,
      'category': instance.category,
      'analysis': instance.analysis.toJson(),
      'prediction': instance.prediction?.toJson(),
    };

_WarningSection _$WarningSectionFromJson(Map<String, dynamic> json) =>
    _WarningSection(
      title: json['title'] as String,
      text: json['text'] as String,
    );

Map<String, dynamic> _$WarningSectionToJson(_WarningSection instance) =>
    <String, dynamic>{'title': instance.title, 'text': instance.text};

_WarningArea _$WarningAreaFromJson(Map<String, dynamic> json) =>
    _WarningArea(name: json['name'] as String, code: json['code'] as String);

Map<String, dynamic> _$WarningAreaToJson(_WarningArea instance) =>
    <String, dynamic>{'name': instance.name, 'code': instance.code};

_TyphoonWarning _$TyphoonWarningFromJson(Map<String, dynamic> json) =>
    _TyphoonWarning(
      active: json['active'] as bool,
      id: json['id'] as String,
      sent: (json['sent'] as num).toInt(),
      status: json['status'] as String,
      msgType: json['msgType'] as String,
      scope: json['scope'] as String,
      event: json['event'] as String,
      urgency: json['urgency'] as String,
      severity: json['severity'] as String,
      certainty: json['certainty'] as String,
      effective: (json['effective'] as num).toInt(),
      onset: (json['onset'] as num).toInt(),
      expires: (json['expires'] as num).toInt(),
      headline: json['headline'] as String,
      senderName: json['senderName'] as String,
      typhoon: json['typhoon'] == null
          ? null
          : WarningTyphoon.fromJson(json['typhoon'] as Map<String, dynamic>),
      sections: (json['sections'] as List<dynamic>)
          .map((e) => WarningSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      areas: (json['areas'] as List<dynamic>)
          .map((e) => WarningArea.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TyphoonWarningToJson(_TyphoonWarning instance) =>
    <String, dynamic>{
      'active': instance.active,
      'id': instance.id,
      'sent': instance.sent,
      'status': instance.status,
      'msgType': instance.msgType,
      'scope': instance.scope,
      'event': instance.event,
      'urgency': instance.urgency,
      'severity': instance.severity,
      'certainty': instance.certainty,
      'effective': instance.effective,
      'onset': instance.onset,
      'expires': instance.expires,
      'headline': instance.headline,
      'senderName': instance.senderName,
      'typhoon': instance.typhoon?.toJson(),
      'sections': instance.sections.map((e) => e.toJson()).toList(),
      'areas': instance.areas.map((e) => e.toJson()).toList(),
    };
