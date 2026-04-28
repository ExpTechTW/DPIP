/// A card widget showing the nearest-station temperature and humidity summary.
library;

import 'package:dpip/app/new_home/_models/home_model.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:provider/provider.dart';

/// Displays temperature and humidity from the nearest CWA weather station.
///
/// The left column shows TREM network data (currently unavailable in this
/// context, displayed as "--"). The right column shows CWA nearest-station
/// readings from [HomeModel]. Rebuilds only when temperature or humidity change.
class AllObservationAverage extends StatelessWidget {
  /// Creates an [AllObservationAverage] widget.
  const AllObservationAverage({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<HomeModel, (double, double)?>(
      selector: (_, m) {
        final d = m.weather?.data;
        return d != null ? (d.temperature, d.humidity) : null;
      },
      builder: (context, data, _) {
        final tremLabel = '--° / --%';

        final cwaLabel = data != null
            ? '${data.$1.toStringAsFixed(1)}° / ${data.$2.round()}%'
            : '--° / --%';

        return Padding(
          padding: const .symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: .start,
            spacing: 4,
            children: [
              Padding(
                padding: const .symmetric(horizontal: 8),
                child: LabelText.large(
                  '所有測站平均',
                  color: Colors.white,
                  shadows: kElevationToShadow[1],
                ),
              ),
              Card(
                child: Padding(
                  padding: const .all(12),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            spacing: 8,
                            children: [
                              Icon(
                                Symbols.cell_tower_rounded,
                                fill: 1,
                                color: context.colors.onSurfaceVariant,
                              ),
                              Text(tremLabel, style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                        const VerticalDivider(width: 24),
                        Expanded(
                          child: Row(
                            spacing: 8,
                            children: [
                              Icon(
                                Symbols.globe_asia_rounded,
                                fill: 1,
                                color: context.colors.onSurfaceVariant,
                              ),
                              Text(cwaLabel, style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
