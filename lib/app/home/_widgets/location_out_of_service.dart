import 'package:flutter/material.dart';

import 'package:material_symbols_icons/material_symbols_icons.dart';

import 'package:dpip/core/i18n.dart';
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
            '服務區域外，僅在臺灣各地可用'.i18n,
            style: context.textTheme.bodyMedium!.copyWith(color: context.colors.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
