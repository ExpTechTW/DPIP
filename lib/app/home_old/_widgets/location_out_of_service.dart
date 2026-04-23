/// Card shown when the user's GPS location is outside the service area.
library;

import 'package:dpip/core/i18n.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

/// Informs the user that their current location is outside the supported
/// service area (Taiwan).
class LocationOutOfServiceCard extends StatelessWidget {
  /// Creates a [LocationOutOfServiceCard].
  const LocationOutOfServiceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        border: Border.all(color: context.colors.secondary, width: 2),
        borderRadius: .circular(16),
      ),
      padding: const .all(12),
      clipBehavior: Clip.antiAlias,
      child: Row(
        spacing: 8,
        children: [
          Icon(
            Symbols.wrong_location_rounded,
            color: context.colors.onSecondaryContainer,
            weight: 500,
          ),
          Text(
            '服務區域外，僅在臺灣各地可用'.i18n,
            style: context.texts.bodyMedium!.copyWith(
              color: context.colors.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
