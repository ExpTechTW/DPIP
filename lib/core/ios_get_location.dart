import 'dart:async';
import 'dart:io';

import 'package:dpip/core/providers.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/map_utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

Completer<void>? _completer;

/// 更新位置信息 (iOS 使用 geolocator 前台获取,后台由 native 处理)
Future<void> updateSavedLocationIOS() async {
  // 只在 iOS 上执行
  if (!Platform.isIOS) return;

  final completer = _completer;

  if (completer != null && !completer.isCompleted) return completer.future;

  _completer = Completer();

  try {
    // 检查位置服务是否启用
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      TalkerManager.instance.debug('📍 [iOS GPS] Location services are disabled');
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
      _completer?.complete();
      return;
    }

    // 检查权限
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      TalkerManager.instance.debug('📍 [iOS GPS] Location permission denied');
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
      _completer?.complete();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      TalkerManager.instance.debug('📍 [iOS GPS] Location permission denied forever');
      GlobalProviders.location.setCode(null);
      GlobalProviders.location.setCoordinates(null);
      _completer?.complete();
      return;
    }

    // 获取最后已知位置 (快速,不消耗电量)
    Position? position = await Geolocator.getLastKnownPosition();

    // 如果没有最后位置,则获取当前位置
    if (position == null) {
      TalkerManager.instance.debug('📍 [iOS GPS] No last known position, getting current position');
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
    }

    final latitude = position.latitude;
    final longitude = position.longitude;

    final code = getTownCodeFromCoordinates(LatLng(latitude, longitude));
    TalkerManager.instance.debug('📍 [iOS GPS] Updated location: ($latitude, $longitude) → code: $code');

    GlobalProviders.location.setCode(code);
    GlobalProviders.location.setCoordinates(LatLng(latitude, longitude));
  } catch (e, s) {
    TalkerManager.instance.error('📍 [iOS GPS] Error getting location', e, s);
    // 发生错误时不清除位置,保留上次的位置
  } finally {
    _completer?.complete();
  }
}
