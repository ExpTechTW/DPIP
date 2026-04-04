/// City-level district selection page for location settings.
library;

import 'dart:collection';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/core/preference.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/log.dart';
import 'package:dpip/utils/toast.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:dpip/widgets/ui/loading_icon.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// A page listing all districts within a given [city] for location selection.
///
/// Tap a district to save it as the user's location and navigate back to the
/// location settings page:
///
/// ```dart
/// SettingsLocationSelectCityPage(city: '台北市')
/// ```
class SettingsLocationSelectCityPage extends StatefulWidget {
  /// The city name used to filter available districts.
  final String city;

  /// Creates a [SettingsLocationSelectCityPage] for the given [city].
  const SettingsLocationSelectCityPage({super.key, required this.city});

  @override
  State<SettingsLocationSelectCityPage> createState() => _SettingsLocationSelectCityPageState();
}

class _SettingsLocationSelectCityPageState extends State<SettingsLocationSelectCityPage> {
  String? _loadingCode;

  @override
  Widget build(BuildContext context) {
    final towns = Global.location.entries
        .where((e) => e.value.cityWithLevel == widget.city)
        .toList();

    final length = towns.length;

    return CustomScrollView(
      slivers: [
        SliverSegmentedList(
          label: Text(widget.city),
          children: [
            for (final (index, MapEntry(key: code, value: town)) in towns.indexed)
              Selector<SettingsLocationModel, bool>(
                selector: (context, model) => model.isFavorited(code),
                builder: (context, isFavorited, child) {
                  final isLoading = _loadingCode == code;

                  return SegmentedListTile(
                    isFirst: index == 0,
                    isLast: index == length - 1,
                    title: Text(town.cityTownWithLevel),
                    subtitle: Text(
                      '$code・${town.lng.toStringAsFixed(2)}°E・${town.lat.toStringAsFixed(2)}°N',
                    ),
                    trailing: isLoading
                        ? const LoadingIcon()
                        : isFavorited
                        ? const Icon(Symbols.star_rounded, fill: 1)
                        : null,
                    enabled: _loadingCode == null,
                    onTap: isFavorited
                        ? null
                        : () async {
                            setState(() => _loadingCode = code);

                            try {
                              context.location.favorite(code);

                              await ExpTech().updateDeviceLocation(
                                token: Preference.notifyToken,
                                coordinates: LatLng(town.lat, town.lng),
                              );
                              if (!context.mounted) return;

                              context.location.setCode(code);
                              if (!context.mounted) return;

                              context.popUntil(
                                SettingsLocationRoute().location,
                              );
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
                                ToastWidget.text(
                                  '設定所在地時發生錯誤，請稍候再試一次。'.i18n,
                                ),
                              );
                            }
                          },
                  );
                },
              ),
          ],
        ),
        SliverPadding(padding: .only(bottom: context.padding.bottom + 16)),
      ],
    );
  }
}
