/// A chip widget that displays the current location and supports temporary overrides.
library;

import 'package:collection/collection.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/app/home/_models/home_model.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/constants.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// Displays the effective location as a tappable chip.
///
/// Tapping opens a two-level city→district picker to set a temporary location
/// override. A close button appears when an override is active, reverting to
/// the persisted location on tap.
class LocationChip extends StatelessWidget {
  /// Creates a [LocationChip].
  const LocationChip({super.key});

  void _showLocationPicker(BuildContext context) {
    final homeModel = context.home;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: kEmphasizedAnimationStyle,
      constraints: context.bottomSheetConstraints,
      builder: (_) => _LocationPickerSheet(homeModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector2<HomeModel, SettingsLocationModel, (String?, String?)>(
      selector: (_, home, settings) => (home.temporaryCode, settings.code),
      builder: (context, data, _) {
        final (temporaryCode, settingsCode) = data;

        final code = temporaryCode ?? settingsCode;
        final hasOverride = code != settingsCode;

        final location = switch (code) {
          final code? => Global.location[code],
          _ => null,
        };

        final displayName = switch (location) {
          final location? => location.cityTownWithLevel,
          _ => '未設定',
        };

        return Padding(
          padding: .symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () => _showLocationPicker(context),
                icon: const Icon(Symbols.location_on_rounded, fill: 1),
                label: Text(displayName),
                style: FilledButton.styleFrom(
                  backgroundColor: hasOverride
                      ? context.colors.primaryContainer
                      : context.colors.surfaceContainerLow,
                  foregroundColor: hasOverride
                      ? context.colors.onPrimaryContainer
                      : context.colors.onSurface,
                ),
              ),
              if (hasOverride)
                IconButton(
                  onPressed: () => context.home.setTemporaryCode(null),
                  icon: const Icon(Symbols.close_rounded),
                  tooltip: '清除暫時位置',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final HomeModel homeModel;

  const _LocationPickerSheet(this.homeModel);

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String? _selectedCity;

  List<(String cityWithLevel, Location location)> get _cities {
    final seen = <String>{};
    return [
      for (final entry in Global.location.entries)
        if (seen.add(entry.value.cityWithLevel)) (entry.value.cityWithLevel, entry.value),
    ];
  }

  List<(String code, Location location)> get _towns {
    final city = _selectedCity;
    if (city == null) return [];
    return [
      for (final entry in Global.location.entries)
        if (entry.value.cityWithLevel == city) (entry.key, entry.value),
    ];
  }

  void dismissSheet() => Navigator.of(context).popUntil((route) {
    if (route.settings is Page) return true;
    return false;
  });

  void selectCode(String code) {
    widget.homeModel.setTemporaryCode(code);
    dismissSheet();
  }

  Widget _buildCityList() {
    final cities = _cities;

    return SegmentedList.builder(
      label: Text('縣市'.i18n),
      itemCount: cities.length,
      itemBuilder: (context, index) {
        final (cityName, _) = cities[index];

        return SegmentedListTile(
          isFirst: index == 0,
          isLast: index == cities.length - 1,
          title: Text(cityName),
          trailing: const Icon(Symbols.chevron_right_rounded),
          onTap: () => setState(() => _selectedCity = cityName),
        );
      },
    );
  }

  Widget _buildTownList() {
    final towns = _towns;
    final temporaryCode = widget.homeModel.temporaryCode;

    return SegmentedList.builder(
      label: Text(towns.first.$2.cityWithLevel),
      itemCount: towns.length,
      itemBuilder: (context, index) {
        final (code, location) = towns[index];

        final isCurrentCode = code == context.location.code;
        final isSelected = (temporaryCode == null && isCurrentCode) || code == temporaryCode;
        final isOverride = temporaryCode != null && !isCurrentCode;

        final lng = location.lng.toStringAsFixed(2);
        final lat = location.lat.toStringAsFixed(2);

        final backgroundColor = isSelected ? context.colors.secondaryContainer : null;
        final foregroundColor = isSelected ? context.colors.onSecondaryContainer : null;

        return SegmentedListTile(
          isFirst: index == 0,
          isLast: index == towns.length - 1,
          tileColor: backgroundColor,
          title: Text(location.cityTownWithLevel),
          subtitle: Text(
            '$code・$lng°E・$lat°N',
            style: TextStyle(color: foregroundColor),
          ),
          trailing: Icon(
            switch ((isSelected, isOverride)) {
              (true, true) => Symbols.check_rounded,
              (true, false) => Symbols.home_rounded,
              _ => null,
            },
            fill: 1,
            color: foregroundColor,
          ),
          onTap: () => selectCode(code),
        );
      },
    );
  }

  Widget _buildQuickLocations() {
    final temporaryCode = widget.homeModel.temporaryCode;

    return Selector<SettingsLocationModel, (String?, Set<String>)>(
      selector: (_, model) => (model.code, model.favorited),
      builder: (context, data, child) {
        final (currentCode, favorited) = data;

        final quickCodes = Set<String>();

        if (currentCode != null) quickCodes.add(currentCode);
        quickCodes.addAll(favorited);

        final quickLocations = quickCodes.mapIndexed((index, code) {
          final location = Global.location[code]!;

          final isCurrentCode = code == currentCode;
          final isSelected = (temporaryCode == null && isCurrentCode) || code == temporaryCode;
          final backgroundColor = isSelected ? context.colors.secondaryContainer : null;
          final foregroundColor = isSelected ? context.colors.onSecondaryContainer : null;

          return SegmentedListTile(
            isFirst: index == 0,
            tileColor: backgroundColor,
            leading: Icon(
              isCurrentCode ? Symbols.home_rounded : Symbols.star_rounded,
              fill: 1,
              color: foregroundColor,
            ),
            title: Text(
              location.cityTownWithLevel,
              style: TextStyle(color: foregroundColor),
            ),
            trailing: Icon(
              isSelected ? Symbols.check_rounded : null,
              color: foregroundColor,
            ),
            onTap: () => selectCode(code),
          );
        });

        return SegmentedList(
          label: Text('快速切換'.i18n),
          children: [
            ...quickLocations,
            SegmentedListTile(
              isLast: true,
              leading: Icon(Symbols.add_circle_rounded),
              title: Text('新增地點'.i18n),
              onTap: () => SettingsLocationSelectRoute().push(context),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(_selectedCity != null ? Symbols.arrow_back_rounded : Symbols.close_rounded),
          onPressed: () {
            if (_selectedCity != null) {
              setState(() => _selectedCity = null);
            } else {
              dismissSheet();
            }
          },
          tooltip: _selectedCity != null ? '返回' : '關閉',
        ),
        title: Text(_selectedCity ?? '選擇地區', style: context.texts.titleMedium),
        actions: [
          IconButton(
            onPressed: () {
              dismissSheet();
              SettingsLocationRoute().push(context);
            },
            icon: Icon(Symbols.settings_rounded, fill: 1),
            tooltip: '所在地設定',
          ),
        ],
        actionsPadding: .only(right: 4),
      ),
      body: ListView(
        children: (_selectedCity == null)
            ? ([
                _buildQuickLocations(),
                _buildCityList(),
              ])
            : [_buildTownList()],
      ),
    );
  }
}
