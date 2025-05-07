import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class LocationNotSetCard extends StatelessWidget {
  const LocationNotSetCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        border: Border.all(color: context.colors.secondary, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.only(left: 12, top: 4, right: 4, bottom: 4),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(Symbols.not_listed_location_rounded, color: context.colors.onSecondaryContainer, weight: 500),
              Text(
                context.i18n.location_not_set,
                style: context.textTheme.bodyMedium!.copyWith(color: context.colors.onSecondaryContainer),
              ),
            ],
          ),
          TextButton(child: Text(context.i18n.settings), onPressed: () => context.push(SettingsLocationPage.route)),
        ],
      ),
    );
  }
}
