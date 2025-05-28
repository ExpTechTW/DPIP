import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

abstract class MapLayerManager {
  final BuildContext context;
  final MapLibreMapController controller;

  bool didSetup = false;
  bool visible = false;

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

  /// 構建圖層的資訊顯示介面
  Widget build(BuildContext context) => const SizedBox.shrink();
}
