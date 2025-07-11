import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

abstract class MapLayerManager {
  final BuildContext context;
  final MapLibreMapController controller;

  bool didSetup = false;
  bool visible = false;

  /// 這個管理器是否允許頁面返回行為
  bool get shouldPop => true;

  MapLayerManager(this.context, this.controller);

  /// 初始化圖層，並將 [didSetup] 設為 `true`
  Future<void> setup();

  /// 更新圖層
  void tick() {}

  /// 隱藏圖層
  Future<void> hide();

  /// 顯示圖層
  Future<void> show();

  /// 將圖層從地圖移除
  Future<void> remove();

  /// 釋放資源
  void dispose() {}

  /// 當頁面返回時會呼叫這個方法
  void onPopInvoked() {}

  /// 構建圖層的資訊顯示介面
  Widget build(BuildContext context) => const SizedBox.shrink();
}
