import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:dpip/app/map/_lib/managers/report.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/number.dart';
import 'package:dpip/utils/intensity_color.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class PositionedIntensityFilterButton extends StatelessWidget {
  final ReportMapLayerManager manager;

  const PositionedIntensityFilterButton({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 84,
      right: 24,
      child: SafeArea(
        child: BlurredIconButton(
          icon: const Icon(Symbols.filter_list_rounded),
          tooltip: '震度篩選',
          elevation: 2,
          onPressed: () => showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            useSafeArea: true,
            constraints: context.bottomSheetConstraints,
            builder: (context) {
              return IntensityFilterSheet(manager: manager);
            },
          ),
        ),
      ),
    );
  }
}

class IntensityFilterSheet extends StatelessWidget {
  final ReportMapLayerManager manager;

  const IntensityFilterSheet({required this.manager});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
              child: Row(
                children: [
                  const Icon(Symbols.filter_list_rounded, size: 28),
                  const SizedBox(width: 8),
                  Text('篩選', style: context.texts.titleLarge),
                  const Spacer(),
                  ValueListenableBuilder<Set<int>>(
                    valueListenable: manager.selectedIntensities,
                    builder: (context, selected, child) {
                      final visible = selected.isNotEmpty;
                      return AnimatedOpacity(
                        opacity: visible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: IgnorePointer(
                          ignoring: !visible,
                          child: TextButton(
                            onPressed: () => manager.resetIntensityFilter(),
                            child: const Text('重置'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: Text(
                '震度',
                style: context.texts.titleMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<Set<int>>(
              valueListenable: manager.selectedIntensities,
              builder: (context, selected, child) {
                return GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  children: [
                    for (int i = 1; i <= 9; i++)
                      _IntensityChip(
                        intensity: i,
                        isSelected: selected.contains(i),
                        onTap: () => manager.toggleIntensity(i),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _IntensityChip extends StatelessWidget {
  final int intensity;
  final bool isSelected;
  final VoidCallback onTap;

  const _IntensityChip({
    required this.intensity,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = IntensityColor.intensity(intensity);
    final onColor = IntensityColor.onIntensity(intensity);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: isSelected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: color,
              )
            : BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 3.0),
              ),
        child: Center(
          child: Text(
            intensity.asIntensityDisplayLabel,
            style: TextStyle(
              color: isSelected ? onColor : context.colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
