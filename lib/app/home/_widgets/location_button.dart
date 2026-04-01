import 'package:dpip/app/home/_models/home_location.dart';
import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/list/segmented_list.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<HomeLocationModel, SettingsLocationModel>(
      builder: (context, homeLocation, settingsLocation, child) {
        final savedCode = settingsLocation.code;
        final favorited = settingsLocation.favorited;
        final temporaryCode = homeLocation.temporaryCode;
        final displayCode = temporaryCode ?? savedCode;
        final location = Global.location[displayCode];

        late String content;
        if (location == null) {
          content = '尚未設定'.i18n;
        } else {
          content = location.dynamicName;
        }

        return BlurredTextButton(
          onPressed: () => _showLocationMenu(
            context,
            savedCode: savedCode,
            temporaryCode: temporaryCode,
            favorited: favorited,
          ),
          text: content,
          textStyle: context.theme.textTheme.bodyLarge,
          elevation: 2,
        );
      },
    );
  }

  void _showLocationMenu(
    BuildContext context, {
    required String? savedCode,
    required String? temporaryCode,
    required Set<String> favorited,
  }) {
    final currentCode = temporaryCode ?? savedCode;
    final model = context.read<HomeLocationModel>();

    showModalBottomSheet<String?>(
      context: context,
      constraints: context.bottomSheetConstraints,
      isScrollControlled: true,
      builder: (sheetContext) => _LocationMenuSheet(
        savedCode: savedCode,
        favorited: favorited,
        currentCode: currentCode,
        onLocationSelected: (code) {
          Navigator.of(sheetContext).pop();
          if (code == savedCode) {
            model.setTemporaryCode(null);
          } else {
            model.setTemporaryCode(code);
          }
        },
        onAddLocationPressed: () {
          Navigator.of(sheetContext).pop();
          SettingsLocationSelectRoute().push(context);
        },
        onSettingsPressed: () {
          Navigator.of(sheetContext).pop();
          SettingsLocationRoute().push(context);
        },
      ),
    );
  }
}

class _LocationMenuSheet extends StatefulWidget {
  final String? savedCode;
  final Set<String> favorited;
  final String? currentCode;
  final ValueChanged<String> onLocationSelected;
  final VoidCallback onAddLocationPressed;
  final VoidCallback onSettingsPressed;

  const _LocationMenuSheet({
    required this.savedCode,
    required this.favorited,
    required this.currentCode,
    required this.onLocationSelected,
    required this.onAddLocationPressed,
    required this.onSettingsPressed,
  });

  @override
  State<_LocationMenuSheet> createState() => _LocationMenuSheetState();
}

class _LocationMenuSheetState extends State<_LocationMenuSheet> {
  String? _selectedCity;

  List<Location> get _cities {
    final Set<String> walked = {};
    return Global.location.entries
        .where((e) => walked.add(e.value.cityWithLevel))
        .map((e) => e.value)
        .toList();
  }

  List<MapEntry<String, Location>> get _towns {
    if (_selectedCity == null) return [];
    return Global.location.entries
        .where((e) => e.value.cityWithLevel == _selectedCity)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const .vertical(top: .circular(16)),
      clipBehavior: .antiAlias,
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: _selectedCity != null
                ? () => setState(() => _selectedCity = null)
                : null,
          ),
          title: Text('切換區域'.i18n),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Symbols.settings_rounded),
              onPressed: widget.onSettingsPressed,
              tooltip: '位置設定'.i18n,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: .only(bottom: context.padding.bottom + 16),
          child: _selectedCity == null
              ? _buildCityList(context)
              : _buildTownList(context),
        ),
      ),
    );
  }

  Widget _buildCityList(BuildContext context) {
    final cities = _cities;
    final savedLocation = Global.location[widget.savedCode];
    final currentLocation = Global.location[widget.currentCode];

    final quickItems = <_QuickItem>[];

    if (widget.savedCode != null && savedLocation != null) {
      quickItems.add(
        _QuickItem(
          code: widget.savedCode!,
          name: savedLocation.dynamicName,
          icon: Symbols.home_rounded,
          isSelected: widget.currentCode == widget.savedCode,
        ),
      );
    }

    for (final code in widget.favorited) {
      if (code == widget.savedCode) continue;
      final location = Global.location[code];
      if (location != null) {
        quickItems.add(
          _QuickItem(
            code: code,
            name: location.dynamicName,
            icon: Symbols.star_rounded,
            isSelected: widget.currentCode == code,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: .start,
      children: [
        SegmentedList(
          label: Text('快速切換'.i18n),
          children: [
            for (var i = 0; i < quickItems.length; i++)
              SegmentedListTile(
                isFirst: i == 0,
                tileColor: quickItems[i].isSelected
                    ? context.colors.secondaryContainer
                    : null,
                leading: Icon(
                  quickItems[i].icon,
                  fill: 1,
                  color: quickItems[i].isSelected
                      ? context.colors.primary
                      : context.colors.onSurfaceVariant,
                ),
                title: Text(
                  quickItems[i].name,
                  style: TextStyle(
                    color: quickItems[i].isSelected
                        ? context.colors.primary
                        : context.colors.onSurface,
                    fontWeight: quickItems[i].isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                trailing: quickItems[i].isSelected
                    ? Icon(
                        Symbols.check_rounded,
                        color: context.colors.primary,
                      )
                    : null,
                onTap: () => widget.onLocationSelected(quickItems[i].code),
              ),
            SegmentedListTile(
              isFirst: quickItems.isEmpty,
              isLast: true,
              leading: const Icon(Symbols.add_circle_rounded),
              title: Text('新增地點'.i18n),
              onTap: widget.onAddLocationPressed,
            ),
          ],
        ),

        SegmentedList.builder(
          label: Text('選擇縣市'.i18n),
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final city = cities[index];

            return SegmentedListTile(
              isFirst: index == 0,
              isLast: index == cities.length - 1,
              title: Text(city.cityWithLevel),
              subtitle: currentLocation?.cityWithLevel == city.cityWithLevel
                  ? Text('目前選擇'.i18n)
                  : null,
              trailing: const Icon(Symbols.chevron_right_rounded),
              onTap: () => setState(() => _selectedCity = city.cityWithLevel),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTownList(BuildContext context) {
    final towns = _towns;

    return SegmentedList.builder(
      label: Text(_selectedCity!),
      itemCount: towns.length,
      itemBuilder: (context, index) {
        final entry = towns[index];
        final code = entry.key;
        final town = entry.value;
        final isSelected = widget.currentCode == code;

        return SegmentedListTile(
          isFirst: index == 0,
          isLast: index == towns.length - 1,
          tileColor: isSelected ? context.colors.secondaryContainer : null,
          title: Text(
            town.townWithLevel,
            style: TextStyle(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          trailing: isSelected
              ? Icon(
                  Symbols.check_rounded,
                  color: context.colors.primary,
                )
              : null,
          onTap: () => widget.onLocationSelected(code),
        );
      },
    );
  }
}

class _QuickItem {
  final String code;
  final String name;
  final IconData icon;
  final bool isSelected;

  const _QuickItem({
    required this.code,
    required this.name,
    required this.icon,
    required this.isSelected,
  });
}
