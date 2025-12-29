import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:dpip/api/model/weather_schema.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';

/// 指北針精確度閾值（度）
/// https://developer.apple.com/documentation/corelocation/clheading/headingaccuracy
/// 負值表示無效/需要校準
/// 0-15 表示高精確度
/// 15-25 表示中等精確度
/// >25 表示精度下降（警告）
/// >45 表示不可靠（危險）
const double _kCompassAccuracyWarning = 25.0;
const double _kCompassAccuracyDanger = 45.0;

class WindCard extends StatefulWidget {
  final RealtimeWeather weather;

  const WindCard(this.weather, {super.key});

  @override
  State<WindCard> createState() => _WindCardState();
}

class _WindCardState extends State<WindCard> {
  StreamSubscription<CompassEvent>? _compassSubscription;
  double _deviceHeading = 0.0;
  double _compassAccuracy = 0.0; // 方向精確度（度），負值表示無效
  bool _hasCompass = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
  }

  Future<void> _initCompass() async {
    // 檢查裝置是否支援羅盤
    final isSupported = await FlutterCompass.events != null;
    if (!isSupported) return;

    setState(() => _hasCompass = true);

    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (event.heading != null && mounted) {
        setState(() {
          _deviceHeading = event.heading!;
          // accuracy: 方向誤差角度（度），負值表示無效/需要校準
          if (event.accuracy != null) {
            _compassAccuracy = event.accuracy!;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }

  double _getWindDirectionAngle(String direction) {
    const directions = {
      '北': 0.0,
      '北北東': 22.5,
      '東北': 45.0,
      '東北東': 67.5,
      '東': 90.0,
      '東南東': 112.5,
      '東南': 135.0,
      '南南東': 157.5,
      '南': 180.0,
      '南南西': 202.5,
      '西南': 225.0,
      '西南西': 247.5,
      '西': 270.0,
      '西北西': 292.5,
      '西北': 315.0,
      '北北西': 337.5,
    };
    return directions[direction.trim()] ?? 0.0;
  }

  String _getWindDirectionName(String direction) {
    return direction.trim();
  }

  /// 獲取蒲福風級描述
  String _getBeaufortDescription(int beaufort) {
    const descriptions = [
      '無風',
      '軟風',
      '輕風',
      '微風',
      '和風',
      '清風',
      '強風',
      '疾風',
      '大風',
      '烈風',
      '狂風',
      '暴風',
      '颶風',
    ];
    if (beaufort >= 0 && beaufort < descriptions.length) {
      return descriptions[beaufort];
    }
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    final wind = widget.weather.data.wind;
    final gust = widget.weather.data.gust;
    final hasValidDirection =
        wind.direction.isNotEmpty && wind.direction != '-';
    final windAngle = hasValidDirection
        ? _getWindDirectionAngle(wind.direction)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 左側：指北針
            SizedBox(
              width: 80,
              height: 80,
              child: _buildCompass(context, windAngle, hasValidDirection),
            ),
            const SizedBox(width: 12),
            // 中間：風速資訊
            Expanded(
              child: _buildCompactWindInfo(
                context,
                wind,
                gust,
                hasValidDirection,
              ),
            ),
            // 右側：磁場資訊
            if (_hasCompass) _buildMagneticInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass(
    BuildContext context,
    double windAngle,
    bool hasValidDirection,
  ) {
    // 將裝置朝向轉換為弧度（逆向旋轉以補償裝置旋轉）
    final deviceRotation = -_deviceHeading * math.pi / 180;

    return Stack(
      alignment: Alignment.center,
      children: [
        // 外圈（固定不動）
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colors.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            border: Border.all(
              color: context.colors.outline.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
        ),
        // 羅盤內容（根據裝置朝向旋轉）
        Transform.rotate(
          angle: deviceRotation,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 方位標記
              ...['N', 'E', 'S', 'W'].asMap().entries.map((entry) {
                final index = entry.key;
                final label = entry.value;
                final angle = index * 90.0;
                final isNorth = label == 'N';

                return Transform.rotate(
                  angle: angle * math.pi / 180,
                  child: Align(
                    alignment: const Alignment(0, -0.78),
                    child: Transform.rotate(
                      angle: -angle * math.pi / 180 - deviceRotation,
                      child: Text(
                        label,
                        style: context.texts.labelMedium?.copyWith(
                          color: isNorth
                              ? Colors.red
                              : context.colors.onSurfaceVariant,
                          fontWeight: isNorth
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: isNorth ? 14 : 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
              // 內圈刻度
              CustomPaint(
                size: const Size.square(100),
                painter: _CompassTicksPainter(
                  color: context.colors.outline.withValues(alpha: 0.3),
                ),
              ),
              // 風向指針（箭頭指向風的來向，尾巴指向風吹去的方向）
              // windAngle 是風來的方向
              if (hasValidDirection)
                Transform.rotate(
                  angle: windAngle * math.pi / 180,
                  child: CustomPaint(
                    size: const Size.square(80),
                    painter: _WindArrowPainter(
                      color: Colors.teal,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // 中心點（固定不動）
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasValidDirection ? Colors.teal : context.colors.outline,
            boxShadow: [
              BoxShadow(
                color:
                    (hasValidDirection ? Colors.teal : context.colors.outline)
                        .withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        // 無資料提示
        if (!hasValidDirection)
          Positioned(
            bottom: 8,
            child: Text(
              '無資料'.i18n,
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompactWindInfo(
    BuildContext context,
    RealtimeWeatherWind wind,
    RealtimeWeatherGust gust,
    bool hasValidDirection,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 風向 + 風速
        Row(
          children: [
            Icon(Symbols.air_rounded, size: 16, color: Colors.teal),
            const SizedBox(width: 6),
            Text(
              hasValidDirection ? _getWindDirectionName(wind.direction) : '-',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              wind.speed >= 0 ? '${wind.speed} m/s' : '-',
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // 風級
        Row(
          children: [
            Text(
              wind.beaufort >= 0
                  ? '${wind.beaufort}級 ${_getBeaufortDescription(wind.beaufort)}'
                        .i18n
                  : '-',
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (gust.speed > 0) ...[
              Text(
                ' · ',
                style: context.texts.bodySmall?.copyWith(
                  color: context.colors.outline,
                ),
              ),
              Text(
                '陣風 ${gust.speed} m/s'.i18n,
                style: context.texts.bodySmall?.copyWith(
                  color: Colors.purple,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMagneticInfo(BuildContext context) {
    // 使用 compass accuracy（方向誤差角度）
    // 負值表示無效，0-15 高精度，15-25 中等，>25 警告，>45 危險
    final hasDanger =
        _compassAccuracy < 0 || _compassAccuracy >= _kCompassAccuracyDanger;
    final hasWarning =
        _compassAccuracy >= _kCompassAccuracyWarning &&
        _compassAccuracy < _kCompassAccuracyDanger;
    final statusText = _compassAccuracy < 0
        ? '–'
        : '±${_compassAccuracy.round()}°';

    final Color statusColor;
    if (hasDanger) {
      statusColor = Colors.red;
    } else if (hasWarning) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return GestureDetector(
      onTap: () => _showMagneticFieldInfo(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: (hasWarning || hasDanger)
              ? Border.all(color: statusColor.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasDanger || hasWarning
                  ? Symbols.warning_rounded
                  : Symbols.explore_rounded,
              size: 16,
              color: statusColor,
            ),
            const SizedBox(height: 2),
            Text(
              '${_deviceHeading.round()}°',
              style: context.texts.labelSmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              statusText,
              style: context.texts.labelSmall?.copyWith(
                color: statusColor.withValues(alpha: 0.8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMagneticFieldInfo(BuildContext context) {
    final hasDanger =
        _compassAccuracy < 0 || _compassAccuracy >= _kCompassAccuracyDanger;
    final hasWarning =
        _compassAccuracy >= _kCompassAccuracyWarning &&
        _compassAccuracy < _kCompassAccuracyDanger;
    final valueText = _compassAccuracy < 0
        ? '無法測量'.i18n
        : '±${_compassAccuracy.toStringAsFixed(1)}°';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          hasDanger
              ? Symbols.error_rounded
              : hasWarning
              ? Symbols.warning_rounded
              : Symbols.check_circle_rounded,
          color: hasDanger
              ? Colors.red
              : hasWarning
              ? Colors.orange
              : Colors.green,
          size: 48,
        ),
        title: Text(
          hasDanger
              ? '指北針不可靠'.i18n
              : hasWarning
              ? '指北針精度下降'.i18n
              : '指北針正常'.i18n,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '方向精確度'.i18n,
              style: context.texts.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              valueText,
              style: context.texts.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: hasDanger
                    ? Colors.red
                    : hasWarning
                    ? Colors.orange
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '正常範圍：±0-15°'.i18n,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            if (hasWarning || hasDanger) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (hasDanger ? Colors.red : Colors.orange).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hasDanger
                      ? '附近有強磁場干擾，指北針方向可能完全不準確。請遠離磁鐵、電子設備或金屬物品。'.i18n
                      : '附近可能有磁場干擾，指北針方向可能有偏差。'.i18n,
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('確定'.i18n),
          ),
        ],
      ),
    );
  }
}

/// 指北針刻度繪製器
class _CompassTicksPainter extends CustomPainter {
  final Color color;

  _CompassTicksPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (int i = 0; i < 36; i++) {
      final angle = i * 10 * math.pi / 180;
      final isMainTick = i % 9 == 0;
      final startRadius = radius - (isMainTick ? 12 : 6);
      final endRadius = radius - 2;

      final start = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );

      paint.strokeWidth = isMainTick ? 2 : 1;
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 風向指針繪製器 (箭頭指向風來向，尾翼朝向圓心)
class _WindArrowPainter extends CustomPainter {
  final Color color;

  _WindArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 陰影
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // === 1. 連桿 (細，從箭頭到尾翼起點，不超過尾翼) ===
    final shaftPath = Path()
      ..moveTo(center.dx - 1, center.dy - radius * 0.25) // 箭頭底部
      ..lineTo(center.dx - 1, center.dy + radius * 0.45) // 尾翼起點
      ..lineTo(center.dx + 1, center.dy + radius * 0.45)
      ..lineTo(center.dx + 1, center.dy - radius * 0.25)
      ..close();

    canvas.drawPath(shaftPath.shift(const Offset(0.5, 0.5)), shadowPaint);
    canvas.drawPath(shaftPath, Paint()..color = color.withValues(alpha: 0.6));

    // === 2. 尾翼 (小型，遠離圓心) ===
    final tailStartY = center.dy + radius * 0.45; // 尾翼起點
    final tailEndY = center.dy + radius * 0.72; // 尾翼終點

    // 左尾翼
    final leftTailPath = Path()
      ..moveTo(center.dx, tailStartY)
      ..lineTo(center.dx - 10, tailEndY)
      ..lineTo(center.dx, tailEndY - radius * 0.06)
      ..close();

    // 右尾翼
    final rightTailPath = Path()
      ..moveTo(center.dx, tailStartY)
      ..lineTo(center.dx + 10, tailEndY)
      ..lineTo(center.dx, tailEndY - radius * 0.06)
      ..close();

    canvas.drawPath(leftTailPath.shift(const Offset(0.5, 0.5)), shadowPaint);
    canvas.drawPath(rightTailPath.shift(const Offset(0.5, 0.5)), shadowPaint);
    canvas.drawPath(leftTailPath, Paint()..color = color);
    canvas.drawPath(rightTailPath, Paint()..color = color);

    // === 3. 箭頭 (靠近圓心) ===
    final arrowTip = Offset(center.dx, center.dy - radius * 0.42);
    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(center.dx - 5, center.dy - radius * 0.22)
      ..lineTo(center.dx, center.dy - radius * 0.25)
      ..lineTo(center.dx + 5, center.dy - radius * 0.22)
      ..close();

    canvas.drawPath(arrowPath.shift(const Offset(0.5, 0.5)), shadowPaint);
    canvas.drawPath(arrowPath, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
