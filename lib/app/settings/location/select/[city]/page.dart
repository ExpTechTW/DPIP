import 'dart:collection';

import 'package:flutter/material.dart';

import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/toast.dart';
import 'package:dpip/widgets/list/list_item_tile.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';

class SettingsLocationSelectCityPage extends StatefulWidget {
  final String city;

  const SettingsLocationSelectCityPage({super.key, required this.city});

  static String route([String city = ':city']) =>
      '/settings/location/select/$city';

  @override
  State<SettingsLocationSelectCityPage> createState() =>
      _SettingsLocationSelectCityPageState();
}

class _SettingsLocationSelectCityPageState
    extends State<SettingsLocationSelectCityPage> {
  String? _loadingCode;

  @override
  Widget build(BuildContext context) {
    final towns = Global.location.entries
        .where((e) => e.value.cityWithLevel == widget.city)
        .toList();

    final length = towns.length;

    return ListView(
      padding: EdgeInsets.only(top: 8, bottom: 16 + context.padding.bottom),
      children: [
        Section(
          label: Text(widget.city),
          children: [
            for (final (index, MapEntry(key: code, value: town))
                in towns.indexed)
              Selector<SettingsLocationModel, UnmodifiableSetView<String>>(
                selector: (context, model) => model.favorited,
                builder: (context, favorited, child) {
                  final isFavorited = favorited.contains(code);
                  final isLoading = _loadingCode == code;

                  return SectionListTile(
                    isFirst: index == 0,
                    isLast: index == length - 1,
                    leading: isLoading ? const LoadingIcon() : null,
                    title: Text(town.cityTownWithLevel),
                    subtitle: Text(
                      '$code・${town.lng.toStringAsFixed(2)}°E・${town.lat.toStringAsFixed(2)}°N',
                    ),
                    trailing: isFavorited
                        ? const Icon(Symbols.star_rounded, fill: 1)
                        : null,
                    enabled: _loadingCode == null,
                    onTap: isFavorited
                        ? null
                        : () async {
                            final model = context.read<SettingsLocationModel>();

                            setState(() => _loadingCode = code);

                            try {
                              // 1. 加入收藏列表
                              model.favorite(code);

                              // 2. 更新伺服器位置
                              await ExpTech().updateDeviceLocation(
                                token: Preference.notifyToken,
                                coordinates: LatLng(town.lat, town.lng),
                              );

                              // 3. 設定為當前所在地 (會自動寫入 coordinates)
                              if (!context.mounted) return;
                              model.setCode(code);

                              // 4. 返回所在地設定頁面
                              if (!context.mounted) return;
                              context.popUntil(SettingsLocationPage.route);
                            } catch (e, s) {
                              if (!context.mounted) return;
                              TalkerManager.instance.error(
                                'Failed to set location',
                                e,
                                s,
                              );

                              setState(() => _loadingCode = null);

                              showToast(
                                context,
                                ToastWidget.text('設定所在地時發生錯誤，請稍候再試一次。'.i18n),
                              );
                            }
                          },
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
