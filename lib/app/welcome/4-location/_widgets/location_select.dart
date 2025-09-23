import 'package:collection/collection.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/layout.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class LocationSelect extends StatefulWidget {
  const LocationSelect({super.key});

  @override
  State<LocationSelect> createState() => _LocationSelectState();
}

class _LocationSelectState extends State<LocationSelect> {
  bool editCity = true;
  String? city;
  bool editTown = false;
  String? town;

  @override
  Widget build(BuildContext context) {
    final city = this.city;
    final town = this.town;

    final entries = Global.location.entries.toList();

    final cities = entries
        .whereIndexed(
          (index, e) =>
              index ==
              entries.indexWhere((v) => (v.value.city == e.value.city) && (v.value.cityLevel == e.value.cityLevel)),
        )
        .toList();

    final children = <Widget>[];

    if (editCity) {
      children.add(
        Layout.col.left.min[4](
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Text(
              '請選擇縣市'.i18n,
              style: context.textTheme.labelMedium?.copyWith(color: context.colors.onSecondaryContainer),
            ),
            Wrap(
              spacing: 4,
              children: [
                for (final MapEntry(key: _, value: location) in cities)
                  ChoiceChip(
                    backgroundColor: context.colors.onSecondaryFixed,
                    selectedColor: context.colors.onSecondaryFixedVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        width: 1.5,
                        color: city == location.cityWithLevel
                            ? context.colors.onSecondaryContainer
                            : context.colors.secondaryContainer,
                      ),
                    ),
                    label: Text(location.cityWithLevel),
                    showCheckmark: false,
                    selected: city == location.cityWithLevel,
                    onSelected: (value) {
                      setState(() {
                        this.city = location.cityWithLevel;
                        this.town = null;
                        editCity = false;
                        editTown = true;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    } else {
      children.add(
        ListTile(
          iconColor: context.colors.onSecondaryContainer,
          textColor: context.colors.onSecondaryContainer,
          title: Text('縣市'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(city!),
          trailing: const Icon(Symbols.edit_rounded),
          visualDensity: VisualDensity.compact,
          onTap: () {
            setState(() {
              editCity = true;
              editTown = false;
            });
          },
        ),
      );
    }

    if (editTown) {
      final towns = Global.location.entries.where((e) => e.value.cityWithLevel == city).toList();

      children.add(
        Layout.col.left.min[4](
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Text(
              '請選擇鄉鎮市區'.i18n,
              style: context.textTheme.labelMedium?.copyWith(color: context.colors.onSecondaryContainer),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final MapEntry(key: _, value: location) in towns)
                  ChoiceChip(
                    backgroundColor: context.colors.onSecondaryFixed,
                    selectedColor: context.colors.onSecondaryFixedVariant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        width: 1.5,
                        color: town == location.townWithLevel
                            ? context.colors.onSecondaryContainer
                            : context.colors.secondaryContainer,
                      ),
                    ),
                    label: Text(location.townWithLevel),
                    showCheckmark: false,
                    selected: town == location.townWithLevel,
                    onSelected: (value) {
                      setState(() {
                        this.town = location.townWithLevel;
                        editTown = false;
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
      );
    } else if (city != null && town != null) {
      children.add(
        ListTile(
          iconColor: context.colors.onSecondaryContainer,
          textColor: context.colors.onSecondaryContainer,
          title: Text('鄉鎮'.i18n, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(town),
          trailing: const Icon(Symbols.edit_rounded),
          visualDensity: VisualDensity.compact,
          onTap: () {
            setState(() {
              editCity = false;
              editTown = true;
            });
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Material(
        color: context.colors.secondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.colors.onSecondaryContainer),
        ),
        clipBehavior: Clip.antiAlias,
        child: Layout.col.left.min(children: children),
      ),
    );
  }
}
