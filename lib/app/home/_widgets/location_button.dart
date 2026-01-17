import 'package:dpip/api/model/location/location.dart';
import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/router.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

class LocationButton extends StatelessWidget {
  final String? temporaryCode;
  final ValueChanged<String?>? onLocationChanged;

  const LocationButton({
    super.key,
    this.temporaryCode,
    this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsLocationModel, (String?, Set<String>)>(
      selector: (context, model) => (model.code, model.favorited),
      builder: (context, data, child) {
        final (savedCode, favorited) = data;
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

    showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => _LocationMenuSheet(
        savedCode: savedCode,
        favorited: favorited,
        currentCode: currentCode,
        onLocationSelected: (code) {
          Navigator.of(sheetContext).pop();
          if (code == savedCode) {
            onLocationChanged?.call(null);
          } else {
            onLocationChanged?.call(code);
          }
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
  final VoidCallback onSettingsPressed;

  const _LocationMenuSheet({
    required this.savedCode,
    required this.favorited,
    required this.currentCode,
    required this.onLocationSelected,
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
    return Container(
      margin: const EdgeInsets.all(16),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          Flexible(
            child: _selectedCity == null
                ? _buildCityList(context)
                : _buildTownList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          if (_selectedCity != null)
            IconButton(
              onPressed: () => setState(() => _selectedCity = null),
              icon: const Icon(Symbols.arrow_back_rounded, size: 20),
              tooltip: '返回'.i18n,
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text(
              _selectedCity ?? '切換區域'.i18n,
              style: context.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: widget.onSettingsPressed,
            icon: const Icon(Symbols.settings_rounded, size: 20),
            tooltip: '位置設定'.i18n,
          ),
        ],
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

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        if (quickItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '快速切換'.i18n,
              style: context.theme.textTheme.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          for (final item in quickItems)
            ListTile(
              dense: true,
              leading: Icon(
                item.icon,
                size: 20,
                color: item.isSelected
                    ? context.colors.primary
                    : context.colors.onSurfaceVariant,
              ),
              title: Text(
                item.name,
                style: TextStyle(
                  color: item.isSelected
                      ? context.colors.primary
                      : context.colors.onSurface,
                  fontWeight: item.isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: item.isSelected
                  ? Icon(
                      Symbols.check_rounded,
                      size: 20,
                      color: context.colors.primary,
                    )
                  : null,
              onTap: () => widget.onLocationSelected(item.code),
            ),
          const Divider(height: 16),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            '選擇縣市'.i18n,
            style: context.theme.textTheme.labelMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        for (final city in cities)
          ListTile(
            dense: true,
            title: Text(city.cityWithLevel),
            subtitle: currentLocation?.cityWithLevel == city.cityWithLevel
                ? Text(
                    '目前選擇'.i18n,
                    style: TextStyle(
                      color: context.colors.primary,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: const Icon(Symbols.chevron_right_rounded, size: 20),
            onTap: () => setState(() => _selectedCity = city.cityWithLevel),
          ),
      ],
    );
  }

  Widget _buildTownList(BuildContext context) {
    final towns = _towns;

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: towns.length,
      itemBuilder: (context, index) {
        final entry = towns[index];
        final code = entry.key;
        final town = entry.value;
        final isSelected = widget.currentCode == code;
        final isSaved = widget.savedCode == code;
        final isFavorited = widget.favorited.contains(code);

        return ListTile(
          dense: true,
          leading: isSaved
              ? Icon(
                  Symbols.home_rounded,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                )
              : isFavorited
              ? Icon(
                  Symbols.star_rounded,
                  size: 20,
                  color: context.colors.onSurfaceVariant,
                )
              : const SizedBox(width: 20),
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
                  size: 20,
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
