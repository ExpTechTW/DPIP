import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/utils/extensions/build_context.dart';

class LocationOutOfServiceCard extends StatelessWidget {
  const LocationOutOfServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        border: Border.all(color: context.colors.secondary, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: Row(
        spacing: 8,
        children: [
          Icon(Symbols.wrong_location_rounded, color: context.colors.onSecondaryContainer, weight: 500),
          Text(
            context.i18n.out_of_service_only_taiwan,
            style: context.textTheme.bodyMedium!.copyWith(color: context.colors.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
